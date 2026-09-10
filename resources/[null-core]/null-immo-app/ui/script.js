// ================================================================
// Null Immo — UI script (lb-phone embedded app)
// ----------------------------------------------------------------
// - Carte GTA pannable / zoomable
// - Pins positionnés depuis les coordonnées world (door.x / door.y)
// - Click sur un pin -> popup; click flèche -> vue détail
// ================================================================

const RESOURCE = 'null-immo-app';

// GTA V world bounds calibrés sur la map satellite (idem realtor tablet)
const MAP_BOUNDS = {
  worldMinX: -5662, worldMaxX: 6695,
  worldMinY: -4040, worldMaxY: 8447,
};
function worldToMap(x, y) {
  const u = (x - MAP_BOUNDS.worldMinX) / (MAP_BOUNDS.worldMaxX - MAP_BOUNDS.worldMinX);
  const v = (MAP_BOUNDS.worldMaxY - y) / (MAP_BOUNDS.worldMaxY - MAP_BOUNDS.worldMinY);
  return {
    u: Math.max(0, Math.min(1, u)),
    v: Math.max(0, Math.min(1, v)),
  };
}

// ---------- helpers ---------------------------------------------------------
function fetchNui(route, body = {}) {
  return fetch(`https://${RESOURCE}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
    .then(r => r.json().catch(() => ({})))
    .catch(() => ({}));
}

function fmt(n) {
  return Math.round(n || 0).toLocaleString('fr-FR');
}
function modeLabel(m) {
  return m === 'sell' ? 'Vente' : m === 'rent' ? 'Location' : '—';
}
function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
}
function interiorMeta(key) {
  if (!key) return { icon: '🏠', isWarehouse: false, label: 'Bien' };
  if (key.startsWith && key.startsWith('Entrepot')) {
    return { icon: '🏭', isWarehouse: true, label: 'Entrepôt' };
  }
  if (key === 'High')   return { icon: '🏙️', isWarehouse: false, label: 'Penthouse' };
  if (key === 'Middle') return { icon: '🏘️', isWarehouse: false, label: 'Standing' };
  if (key === 'Low')    return { icon: '🏠', isWarehouse: false, label: 'Maison' };
  return { icon: '🏠', isWarehouse: false, label: key };
}

// ---------- state -----------------------------------------------------------
let allListings = [];
let currentTab  = 'all';
let selectedId  = null;

// ---------- DOM -------------------------------------------------------------
const $mapView   = document.getElementById('view-map');
const $detailView= document.getElementById('view-detail');
const $wrap      = document.getElementById('map-wrap');
const $stage     = document.getElementById('map-stage');
const $img       = document.getElementById('map-img');
const $pins      = document.getElementById('map-pins');
const $popup     = document.getElementById('map-popup');
const $empty     = document.getElementById('map-empty');
const $detail    = document.getElementById('vi-detail');
const $dTitle    = document.getElementById('d-title');

// ---------- map pan / zoom --------------------------------------------------
let scale     = 1;
let tx        = 0;
let ty        = 0;
let imgW      = 0;
let imgH      = 0;
let minScale  = 1;   // = scale "cover" -> dézoom interdit en-dessous
const MAX_SCALE = 6;

function applyTransform() {
  $stage.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`;
}

// Clamp translation so the map doesn't fly off-screen.
// Bottom-align when the image is smaller than the wrap (image bottom
// touches wrap bottom). Otherwise keep drag in bounds.
function clampTransform() {
  if (!imgW || !imgH) return;
  const wrapW = $wrap.clientWidth;
  const wrapH = $wrap.clientHeight;
  const scaledW = imgW * scale;
  const scaledH = imgH * scale;

  // Horizontal : centré (comme avant)
  if (scaledW <= wrapW) tx = (wrapW - scaledW) / 2;
  else                  tx = Math.max(wrapW - scaledW, Math.min(0, tx));

  // Vertical : aligné en BAS (image bottom = wrap bottom)
  if (scaledH <= wrapH) ty = wrapH - scaledH;
  else                  ty = Math.max(wrapH - scaledH, Math.min(0, ty));
}

function fitMap() {
  const wrapW = $wrap.clientWidth;
  const wrapH = $wrap.clientHeight;
  if (!wrapW || !wrapH || !imgW || !imgH) return;
  // "Cover" : on remplit toute la zone, jamais de bandes noires.
  // Ce niveau de zoom devient le minimum -> impossible de sortir.
  minScale = Math.max(wrapW / imgW, wrapH / imgH);
  scale = minScale;
  // Centré horizontalement, aligné en bas (Los Santos est au sud
  // de la carte GTA -> le joueur voit la ville par défaut).
  tx = (wrapW - imgW * scale) / 2;
  ty = wrapH - imgH * scale;
  applyTransform();
}

// Init when image loads (or immediately if cached)
function onImageReady() {
  imgW = $img.naturalWidth;
  imgH = $img.naturalHeight;
  if (!imgW || !imgH) return;
  $stage.style.width  = imgW + 'px';
  $stage.style.height = imgH + 'px';
  fitMap();
  renderPins();
}
$img.addEventListener('load', onImageReady);
if ($img.complete && $img.naturalWidth) onImageReady();

// Drag (pointer events for both touch & mouse)
let dragging = false;
let pointers = new Map();
let startTx = 0, startTy = 0;
let startX = 0, startY = 0;
let startDist = 0, startScale = 1;
let didMove = false;

// NB: on n'utilise PAS setPointerCapture — sinon le pointerup
// est redirigé sur $wrap et le `click` synthétique ne fire jamais
// sur les pins. Du coup on écoute pointermove/up sur `document` pour
// pouvoir continuer à drag même quand le curseur sort du wrap.
$wrap.addEventListener('pointerdown', (e) => {
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
  didMove = false;

  if (pointers.size === 1) {
    dragging = true;
    startX = e.clientX; startY = e.clientY;
    startTx = tx; startTy = ty;
  } else if (pointers.size === 2) {
    dragging = false;
    const pts = Array.from(pointers.values());
    startDist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
    startScale = scale;
  }
});

document.addEventListener('pointermove', (e) => {
  if (!pointers.has(e.pointerId)) return;
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

  if (pointers.size === 1 && dragging) {
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;
    if (Math.abs(dx) > 4 || Math.abs(dy) > 4) didMove = true;
    if (didMove) {
      tx = startTx + dx;
      ty = startTy + dy;
      clampTransform();
      applyTransform();
    }
  } else if (pointers.size === 2) {
    const pts = Array.from(pointers.values());
    const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
    if (startDist > 0) {
      const next = Math.max(minScale, Math.min(MAX_SCALE, startScale * (dist / startDist)));
      didMove = true;
      zoomAt(next, (pts[0].x + pts[1].x) / 2, (pts[0].y + pts[1].y) / 2);
    }
  }
});

function endPointer(e) {
  pointers.delete(e.pointerId);
  if (pointers.size === 0) dragging = false;
}
document.addEventListener('pointerup', endPointer);
document.addEventListener('pointercancel', endPointer);

// Wheel zoom (desktop only)
$wrap.addEventListener('wheel', (e) => {
  e.preventDefault();
  const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15;
  const next = Math.max(minScale, Math.min(MAX_SCALE, scale * factor));
  zoomAt(next, e.clientX, e.clientY);
}, { passive: false });

function zoomAt(nextScale, clientX, clientY) {
  const rect = $wrap.getBoundingClientRect();
  const mx = clientX - rect.left;
  const my = clientY - rect.top;
  // Keep the point under the cursor stable
  const ratio = nextScale / scale;
  tx = mx - (mx - tx) * ratio;
  ty = my - (my - ty) * ratio;
  scale = nextScale;
  clampTransform();
  applyTransform();
}

// Zoom buttons
document.getElementById('z-in').addEventListener('click', () => {
  const r = $wrap.getBoundingClientRect();
  zoomAt(Math.min(MAX_SCALE, scale * 1.3), r.left + r.width / 2, r.top + r.height / 2);
});
document.getElementById('z-out').addEventListener('click', () => {
  const r = $wrap.getBoundingClientRect();
  zoomAt(Math.max(minScale, scale / 1.3), r.left + r.width / 2, r.top + r.height / 2);
});
document.getElementById('z-reset').addEventListener('click', () => {
  fitMap();
  hidePopup();
});

window.addEventListener('resize', () => {
  if (imgW && imgH && scale === 1 && tx === 0 && ty === 0) {
    fitMap(); // first init after wrap got real dimensions
  } else {
    clampTransform();
  }
  applyTransform();
});

// ---------- pins -----------------------------------------------------------
function getFiltered() {
  if (currentTab === 'sell') return allListings.filter(l => l.listingMode === 'sell');
  if (currentTab === 'rent') return allListings.filter(l => l.listingMode === 'rent');
  return allListings;
}

function renderPins() {
  $pins.innerHTML = '';
  const items = getFiltered().filter(l => l.door && typeof l.door.x === 'number');

  if ($empty) $empty.hidden = !!items.length;
  if (!items.length) return;

  items.forEach(l => {
    const meta  = interiorMeta(l.interiorKey);
    const cls   = meta.isWarehouse ? 'warehouse' : (l.listingMode === 'rent' ? 'rent' : 'sell');
    const { u, v } = worldToMap(l.door.x, l.door.y);

    const btn = document.createElement('button');
    btn.className = 'vi-pin ' + cls;
    btn.style.left = (u * 100) + '%';
    btn.style.top  = (v * 100) + '%';
    btn.dataset.id = l.id;
    btn.innerHTML = `
      <svg class="vi-pin-marker" viewBox="0 0 24 32">
        <path d="M12 0 C5 0 0 5 0 12 c0 8 12 20 12 20 s12 -12 12 -20 C24 5 19 0 12 0 z"
              stroke-width="1.5"/>
        <circle cx="12" cy="12" r="4" fill="#fff"/>
      </svg>
    `;
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (didMove) { didMove = false; return; }
      selectListing(l.id);
    });
    $pins.appendChild(btn);
  });
}

// Tap empty area => close popup
$wrap.addEventListener('click', (e) => {
  if (didMove) { didMove = false; return; }
  if (e.target.closest('.vi-pin') || e.target.closest('.vi-popup') || e.target.closest('.vi-zoom')) return;
  hidePopup();
});

// ---------- popup ----------------------------------------------------------
function hidePopup() {
  selectedId = null;
  $popup.hidden = true;
  document.querySelectorAll('.vi-pin.active').forEach(p => p.classList.remove('active'));
}

function selectListing(id) {
  const l = allListings.find(x => x.id === id);
  if (!l) return;
  selectedId = id;

  document.querySelectorAll('.vi-pin').forEach(p => {
    p.classList.toggle('active', p.dataset.id === id);
  });

  const meta   = interiorMeta(l.interiorKey);
  const isRent = l.listingMode === 'rent';
  const iconCls= meta.isWarehouse ? 'warehouse' : (isRent ? 'rent' : 'sell');
  const price  = isRent ? `${fmt(l.rentPrice)}$ /j` : `${fmt(l.salePrice)}$`;

  document.getElementById('pop-icon').textContent  = meta.icon;
  document.getElementById('pop-icon').className    = 'vi-popup-icon ' + iconCls;
  document.getElementById('pop-title').textContent = l.interiorLabel || meta.label;
  document.getElementById('pop-sub').textContent   = l.neighborhoodLabel || '—';
  const $badge = document.getElementById('pop-badge');
  $badge.textContent = modeLabel(l.listingMode);
  $badge.className   = 'badge ' + (isRent ? 'rent' : 'sell');
  document.getElementById('pop-price').textContent = price;

  $popup.hidden = false;
}

document.getElementById('pop-go').addEventListener('click', () => {
  if (!selectedId) return;
  const l = allListings.find(x => x.id === selectedId);
  if (l) openDetail(l);
});

// ---------- detail view -----------------------------------------------------
function openDetail(l) {
  const meta   = interiorMeta(l.interiorKey);
  const isRent = l.listingMode === 'rent';
  const heroCls= meta.isWarehouse ? 'warehouse' : (isRent ? 'rent' : '');

  $dTitle.textContent = l.interiorLabel || meta.label;

  $detail.innerHTML = `
    <div class="vi-hero ${heroCls}">
      <span class="vi-hero-icon">${meta.icon}</span>
      <span class="vi-hero-badge ${isRent ? 'rent' : 'sell'}">${modeLabel(l.listingMode)}</span>
    </div>

    <div>
      <div class="vi-d-title">${escapeHtml(l.interiorLabel || meta.label)}</div>
      <div class="vi-d-subtitle">${escapeHtml(l.neighborhoodLabel || '—')}</div>
    </div>

    <div class="vi-d-price-card">
      <div>
        <div class="label">${isRent ? 'Loyer journalier' : 'Prix d\'achat'}</div>
        <div class="price ${isRent ? 'rent' : ''}">${isRent ? fmt(l.rentPrice) : fmt(l.salePrice)}<small>${isRent ? '$/jour' : '$'}</small></div>
      </div>
    </div>

    <div class="vi-d-info">
      <div class="vi-d-info-item">
        <div class="lbl">Type</div>
        <div class="val">${escapeHtml(meta.label)}</div>
      </div>
      <div class="vi-d-info-item">
        <div class="lbl">Quartier</div>
        <div class="val">${escapeHtml(l.neighborhoodLabel || '—')}</div>
      </div>
      <div class="vi-d-info-item">
        <div class="lbl">Statut</div>
        <div class="val">${modeLabel(l.listingMode)}</div>
      </div>
      <div class="vi-d-info-item">
        <div class="lbl">Catégorie</div>
        <div class="val">${meta.isWarehouse ? 'Entrepôt' : 'Résidentiel'}</div>
      </div>
    </div>

    <div class="vi-d-actions">
      <button class="vi-d-btn" id="btn-gps">
        <svg viewBox="0 0 24 24" width="14" height="14" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
          <circle cx="12" cy="12" r="3"/>
        </svg>
        GPS sur le bien
      </button>
    </div>
  `;

  const $gps = document.getElementById('btn-gps');
  if ($gps) {
    $gps.addEventListener('click', () => {
      if (l.door) fetchNui('setWaypoint', { x: l.door.x, y: l.door.y });
    });
  }
  showView($detailView);
}

// ---------- view switching --------------------------------------------------
function showView(target) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('view-active'));
  target.classList.add('view-active');
}

// ---------- counters --------------------------------------------------------
function updateCounters() {
  const total = allListings.length;
  const sell  = allListings.filter(l => l.listingMode === 'sell').length;
  const rent  = allListings.filter(l => l.listingMode === 'rent').length;
  document.getElementById('cnt-all').textContent  = total;
  document.getElementById('cnt-sell').textContent = sell;
  document.getElementById('cnt-rent').textContent = rent;
}

// ---------- data load -------------------------------------------------------
async function loadListings() {
  const res = await fetchNui('getListings', {});
  allListings = (res && res.ok && Array.isArray(res.listings)) ? res.listings : [];
  updateCounters();
  hidePopup();
  renderPins();
}

// ---------- events ---------------------------------------------------------
document.querySelectorAll('.vi-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.vi-tab').forEach(t => t.classList.remove('vi-tab-active'));
    tab.classList.add('vi-tab-active');
    currentTab = tab.dataset.mode;
    hidePopup();
    renderPins();
  });
});

document.getElementById('btn-refresh').addEventListener('click', loadListings);
document.getElementById('btn-back').addEventListener('click', () => showView($mapView));

// LB-Phone : on lifecycle messages, reload data
window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'open' || data.type === 'open' || data.action === 'load') {
    loadListings();
  }
});

// Initial load
loadListings();
