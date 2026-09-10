/* =============================================================================
 *  null-blur.js — script drop-in (mode GÉOMÉTRIE)
 * -----------------------------------------------------------------------------
 *  À inclure une fois dans n'importe quelle ressource NUI. Il détecte les
 *  éléments à flouter et envoie leur GÉOMÉTRIE (rect + forme) à l'addon ReShade
 *  via le canal HTTP local. L'addon écrit alors le flou du jeu SOUS la NUI.
 *
 *  -> AUCUNE contrainte sur le contenu : opacité de texte libre, bordures,
 *     glows, rgba… tout se mélange à du vrai jeu flouté. Pas de couleur clé.
 *
 *  Un élément est flouté s'il a, au choix :
 *    - la classe `.null-blur` (RECOMMANDÉ), OU
 *    - l'attribut `data-null-blur`, OU
 *    - du CSS `backdrop-filter: blur(Npx)`  /!\ DÉCONSEILLÉ : CEF (FiveM) rend la
 *      couche backdrop-filter EN NOIR sur fond transparent. N'utilise PAS de
 *      backdrop-filter en CSS — le flou est fourni par l'addon. La détection
 *      via backdrop-filter reste supportée pour compat, mais évite-le côté CSS.
 *  La forme est déduite du `border-radius` (>=50% + carré => cercle).
 *
 *  OPTIMISATION :
 *    - le scan DOM coûteux (getComputedStyle) n'a lieu qu'aux MUTATIONS, pas
 *      à chaque frame ;
 *    - chaque tick ne fait qu'un getBoundingClientRect sur les éléments CONNUS ;
 *    - on n'envoie en HTTP que lorsque la géométrie CHANGE (diff), + heartbeat.
 *
 *  API : window.NullBlur.start({ port })   // défaut 39474
 *        window.NullBlur.refresh()         // force un re-scan
 *        window.NullBlur.stop()
 * ========================================================================== */
(function () {
  'use strict';

  var opts = { port: 39474, scanHz: 30, heartbeatMs: 1000, debug: false };

  var tracked = [];          // [{ el, br }] — éléments connus + leur border-radius
  var lastPayload = null;
  var lastSent = 0;
  var rafId = 0;
  var running = false;
  var rebuildQueued = false;

  // --- (ré)indexation du DOM : coûteux, donc seulement sur mutation/resize ----
  function isBlurEl(el, cs) {
    if (el.hasAttribute('data-vbpx')) return true;   // déjà réclamé (CEF neutralisé)
    if (el.classList && (el.classList.contains('null-blur') ||
      el.hasAttribute('data-null-blur'))) return true;
    var bf = cs.backdropFilter || cs.webkitBackdropFilter || '';
    return bf.indexOf('blur(') !== -1;
  }

  // Rayon de flou (px), façon CSS `blur(Npx)`. Lu une fois puis mémorisé sur
  // l'élément (data-vbpx), car on va neutraliser le backdrop-filter juste après.
  function readBlurPx(el, cs) {
    if (el.dataset.vbpx !== undefined && el.dataset.vbpx !== '')
      return parseFloat(el.dataset.vbpx) || 0;
    var px;
    var bf = cs.backdropFilter || cs.webkitBackdropFilter || '';
    var m = /blur\(\s*([\d.]+)px/.exec(bf);
    if (m) px = parseFloat(m[1]);
    else if (el.hasAttribute('data-null-blur')) px = parseFloat(el.getAttribute('data-null-blur')) || 16;
    else px = 16;
    el.dataset.vbpx = px;
    return px;
  }

  // CEF (FiveM) rend la couche `backdrop-filter` EN NOIR sur fond transparent.
  // On la retire : le flou est fourni par l'addon, le CSS ne sert que de marqueur.
  function neutralizeCEF(el, cs) {
    var bf = cs.backdropFilter || cs.webkitBackdropFilter || '';
    if (bf.indexOf('blur(') !== -1) {
      el.style.backdropFilter = 'none';
      el.style.webkitBackdropFilter = 'none';
    }
  }

  // Alpha du fond de l'élément : transmis à l'addon pour composer correctement
  // le flou SOUS un fond semi-transparent (sinon décalage de couleur / traînées).
  function bgAlpha(cs) {
    var m = /rgba?\(([^)]+)\)/.exec(cs.backgroundColor || '');
    if (!m) return 0;
    var p = m[1].split(',');
    return p.length >= 4 ? Math.max(0, Math.min(1, parseFloat(p[3]) || 0)) : 1;
  }

  // Couleur du fond (0..255) : permet à l'addon de prédire le "verre attendu" et
  // de ne PAS flouter ce qui est dessiné par-dessus (texte opaque, menus...).
  function bgRGB(cs) {
    var m = /rgba?\(([^)]+)\)/.exec(cs.backgroundColor || '');
    if (!m) return [0, 0, 0];
    var p = m[1].split(',');
    return [parseInt(p[0]) || 0, parseInt(p[1]) || 0, parseInt(p[2]) || 0];
  }

  function rebuild() {
    rebuildQueued = false;
    var next = [];
    var all = document.body ? document.body.getElementsByTagName('*') : [];
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var cs = getComputedStyle(el);
      if (isBlurEl(el, cs)) {
        var px = readBlurPx(el, cs);   // lit le rayon AVANT de neutraliser CEF
        neutralizeCEF(el, cs);
        var mm = (el.getAttribute('data-null-blur-mode') || '').toLowerCase();
        var mode = mm === 'radial' ? 2 : (mm === 'linear' ? 1 : 0);
        var angle = parseFloat(el.getAttribute('data-null-blur-angle')) || 0;
        // rotation CSS (transform: rotate/matrix) + taille NON-tournée (offset*)
        var rot = 0;
        var tr = cs.transform || 'none';
        if (tr !== 'none') {
          var mt = /matrix\(([^)]+)\)/.exec(tr);
          if (mt) { var v = mt[1].split(','); rot = Math.atan2(parseFloat(v[1]), parseFloat(v[0])) * 180 / Math.PI; }
        }
        next.push({
          el: el, br: cs.borderTopLeftRadius || '0', a: bgAlpha(cs), px: px,
          tint: bgRGB(cs), mode: mode, angle: angle,
          rot: rot, uw: el.offsetWidth, uh: el.offsetHeight
        });
      }
    }
    tracked = next;
    lastPayload = null;        // force un envoi au prochain tick
  }

  function queueRebuild() {
    if (rebuildQueued) return;
    rebuildQueued = true;
    // debounce léger : on regroupe les mutations d'un même cycle
    setTimeout(rebuild, 16);
  }

  // Visibilité réelle : gère display:none, visibility:hidden, opacity:0 — y
  // compris quand c'est un PARENT qui est caché (menu fermé en fondu, etc.).
  function isVisible(el) {
    if (el.checkVisibility) {
      return el.checkVisibility({
        checkOpacity: true, checkVisibilityCSS: true,           // Chrome récent
        opacityProperty: true, visibilityProperty: true,        // Chrome ancien
        contentVisibilityAuto: true
      });
    }
    // fallback : remonte la chaîne des ancêtres
    var node = el;
    while (node && node.nodeType === 1) {
      var s = getComputedStyle(node);
      if (s.display === 'none' || s.visibility === 'hidden' || parseFloat(s.opacity) === 0) return false;
      node = node.parentElement;
    }
    return true;
  }

  // --- mesure par tick ---------------------------------------------------------
  function region(t) {
    if (!t.el.isConnected || !isVisible(t.el)) return null;   // élément retiré ou caché
    var r = t.el.getBoundingClientRect();
    if (r.width <= 0 || r.height <= 0) return null;
    var dpr = window.devicePixelRatio || 1;

    var circle = 0, radiusPx = 0;
    if (t.br.indexOf('%') !== -1) {
      var pct = parseFloat(t.br);
      if (pct >= 50 && Math.abs(r.width - r.height) <= 2) circle = 1;
      else radiusPx = (pct / 100) * Math.min(r.width, r.height);
    } else {
      radiusPx = parseFloat(t.br) || 0;
    }

    var tint = t.tint || [0, 0, 0];
    return Math.round(r.left * dpr) + ',' + Math.round(r.top * dpr) + ',' +
      Math.round(r.width * dpr) + ',' + Math.round(r.height * dpr) + ',' +
      Math.round(radiusPx * dpr) + ',' + circle + ',' + (t.a).toFixed(2) + ',' +
      Math.round((t.px || 16) * dpr) + ',' + tint[0] + ',' + tint[1] + ',' + tint[2] + ',' +
      (t.mode || 0) + ',' + (t.angle || 0) + ',' +
      Math.round((t.uw || r.width) * dpr) + ',' + Math.round((t.uh || r.height) * dpr) + ',' +
      (t.rot || 0).toFixed(2);
  }

  function buildPayload() {
    var parts = [];
    for (var i = 0; i < tracked.length; i++) {
      var s = region(tracked[i]);
      if (s) parts.push(s);
    }
    return parts.join(';');
  }

  function send(payload) {
    var url = 'http://127.0.0.1:' + opts.port + '/null-blur/regions?d=' + encodeURIComponent(payload);
    if (opts.debug) console.log('[null-blur] ->', payload === '' ? '(vide)' : payload);
    fetch(url, { method: 'GET', cache: 'no-store' })
      .then(function () { document.documentElement.setAttribute('data-null-blur-addon', 'active'); })
      .catch(function (e) {
        document.documentElement.setAttribute('data-null-blur-addon', 'inactive');
        if (opts.debug) console.warn('[null-blur] fetch KO', e && e.message);
      });
  }

  function tick(now) {
    if (!running) return;
    if (now - lastSent >= 1000 / opts.scanHz) {
      var payload = buildPayload();
      if (payload !== lastPayload || (now - lastSent) >= opts.heartbeatMs) {
        lastPayload = payload;
        lastSent = now;
        send(payload);
      }
    }
    rafId = requestAnimationFrame(tick);
  }

  var observer = null;
  function startObserver() {
    if (observer || typeof MutationObserver === 'undefined' || !document.body) return;
    observer = new MutationObserver(queueRebuild);
    observer.observe(document.body, {
      childList: true, subtree: true,
      // PAS 'style' : on modifie style.backdropFilter nous-mêmes (anti-boucle).
      attributes: true, attributeFilter: ['class', 'data-null-blur']
    });
  }

  window.NullBlur = {
    start: function (o) {
      if (o) for (var k in o) if (o.hasOwnProperty(k)) opts[k] = o[k];
      if (running) return this;
      running = true;
      lastPayload = null; lastSent = 0;
      rebuild();
      startObserver();
      window.addEventListener('resize', queueRebuild);
      rafId = requestAnimationFrame(tick);
      return this;
    },
    refresh: queueRebuild,
    stop: function () {
      running = false;
      if (rafId) cancelAnimationFrame(rafId);
      rafId = 0;
      if (observer) { observer.disconnect(); observer = null; }
      send(''); // efface les zones côté addon
    }
  };

  // si le DOM n'est pas prêt, on diffère le 1er rebuild
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { if (running) rebuild(); });
  }
})();
