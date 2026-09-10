// ================================================================
// Null Taxi — UI script (lb-phone embedded app)
// Uber-inspired: minimal, status-driven, live driver tracking.
// ================================================================

const RESOURCE = 'null-taxi-app';

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

function fetchNui(route, body = {}) {
  return fetch(`https://${RESOURCE}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
    .then(r => r.json().catch(() => ({})))
    .catch(() => ({}));
}
function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
}

// ---------- DOM ----------
const $home    = document.getElementById('view-home');
const $active  = document.getElementById('view-active');
const $ride    = document.getElementById('view-ride');
const $cntDrv  = document.getElementById('cnt-drivers');
const $cntIdle = document.getElementById('cnt-idle');
const $list    = document.getElementById('driver-list');
const $sectionMeta = document.getElementById('section-meta');
const $btnReq  = document.getElementById('btn-request');
const $btnCancel = document.getElementById('btn-cancel');
const $btnRefresh = document.getElementById('btn-refresh');

const $statusPill  = document.getElementById('status-pill');
const $statusLabel = document.getElementById('status-label');
const $activeTitle = document.getElementById('active-title');
const $activeSub   = document.getElementById('active-sub');
const $statusSub   = document.getElementById('status-sub');

const $driverCard  = document.getElementById('driver-card');
const $driverName  = document.getElementById('driver-name');
const $driverInit  = document.getElementById('driver-initial');
const $driverEtaWrap  = document.getElementById('driver-eta-wrap');
const $driverEta   = document.getElementById('driver-eta');
const $miniWrap    = document.getElementById('mini-map-wrap');
const $miniPins    = document.getElementById('mini-map-pins');

// ---------- state ----------
let myRequest      = null;
let myDriverCoords = null;
let myCoords       = null;

// ---------- view switching ----------
function showView(target) {
  document.querySelectorAll('.view').forEach(v => v.classList.remove('view-active'));
  target.classList.add('view-active');
}

// ---------- drivers ----------
function renderDrivers(payload) {
  const list = (payload && payload.drivers) || [];
  const idle = list.filter(d => !d.busy).length;
  $cntDrv.textContent  = list.length;
  $cntIdle.textContent = idle;

  if (!list.length) {
    $sectionMeta.textContent = 'En attente';
    $list.innerHTML = `
      <div class="ut-empty">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="8" x2="12" y2="12"/>
          <line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
        <p>Aucun chauffeur en service</p>
      </div>`;
    return;
  }
  $sectionMeta.textContent = list.length + (list.length > 1 ? ' actifs' : ' actif');
  $list.innerHTML = list.map(d => `
    <div class="ut-driver-row ${d.busy ? 'busy' : 'idle'}">
      <div class="ut-driver-row-avatar">
        ${escapeHtml((d.name || '?').slice(0, 1).toUpperCase())}
      </div>
      <div class="ut-driver-row-info">
        <span class="ut-driver-row-name">${escapeHtml(d.name)}</span>
        <span class="ut-driver-row-status">
          <span class="dot ${d.busy ? 'busy' : 'idle'}"></span>
          ${d.busy ? 'En course' : 'Disponible'}
        </span>
      </div>
      <span class="ut-driver-row-pill">${d.busy ? 'Occupé' : 'Libre'}</span>
    </div>
  `).join('');
}

async function loadDrivers() {
  const res = await fetchNui('listDrivers', {});
  renderDrivers(res);
}

// ---------- ETA helper (very rough, ~40 km/h average) ----------
function computeEtaMinutes(citCoords, drvCoords) {
  if (!citCoords || !drvCoords) return null;
  const dx = drvCoords.x - citCoords.x;
  const dy = drvCoords.y - citCoords.y;
  const meters = Math.hypot(dx, dy);
  const minutes = Math.max(1, Math.round(meters / 11.0 / 60));
  return minutes;
}

// ---------- my request ----------
function renderActive(state) {
  if (!state || !state.active) {
    myRequest = null;
    showView($home);
    return;
  }
  myRequest = state.request || null;
  showView($active);

  if (state.accepted) {
    $statusPill.className = 'ut-status-pill accepted';
    $statusLabel.textContent = 'Accepté';
    $activeTitle.textContent = 'Votre taxi arrive';
    $activeSub.textContent   = 'Suivez sa progression sur la carte';

    $driverCard.hidden = false;
    const name = state.driverName || 'Chauffeur';
    $driverName.textContent = name;
    $driverInit.textContent = name.slice(0, 1).toUpperCase();
    $statusSub.textContent  = 'En route vers vous';

    if (state.driverCoords) myDriverCoords = state.driverCoords;

    const eta = computeEtaMinutes(myCoords, myDriverCoords);
    if (eta != null) {
      $driverEtaWrap.hidden = false;
      $driverEta.textContent = String(eta);
    } else {
      $driverEtaWrap.hidden = true;
    }

    drawMiniMap();
  } else {
    $statusPill.className = 'ut-status-pill searching';
    $statusLabel.textContent = 'Recherche';
    $activeTitle.textContent = 'Recherche d\'un taxi';
    $activeSub.textContent   = 'Notification envoyée à tous les taxis en service';
    $driverCard.hidden = true;
    $driverEtaWrap.hidden = true;
  }
}

async function refreshMyRequest() {
  const res = await fetchNui('getMyRequest', {});
  if (!res || !res.ok) return;
  if (res.driverCoords) myDriverCoords = res.driverCoords;
  if (res.request && res.request.coords) myCoords = res.request.coords;
  renderActive(res);
}

// ---------- mini-map ----------
function drawMiniMap() {
  $miniPins.innerHTML = '';
  if (!myCoords) return;

  const me = worldToMap(myCoords.x, myCoords.y);
  $miniPins.appendChild(makePin(me.u, me.v, 'me', 'Vous'));

  if (myDriverCoords) {
    const drv = worldToMap(myDriverCoords.x, myDriverCoords.y);
    $miniPins.appendChild(makePin(drv.u, drv.v, 'driver', 'Taxi'));
  }
}
function makePin(u, v, cls, title) {
  const p = document.createElement('div');
  p.className = 'ut-map-pin ' + cls;
  p.style.left = (u * 100) + '%';
  p.style.top  = (v * 100) + '%';
  p.title = title;
  return p;
}

// ---------- actions ----------
$btnReq.addEventListener('click', async () => {
  $btnReq.disabled = true;
  const res = await fetchNui('requestRide', {});
  $btnReq.disabled = false;
  if (res && res.ok) {
    refreshMyRequest();
  } else {
    // soft inline feedback rather than alert
    $btnReq.textContent = 'Impossible — réessayer';
    setTimeout(() => {
      $btnReq.innerHTML = `
        <span>Demander un taxi</span>
        <svg viewBox="0 0 24 24" width="16" height="16" fill="none"
             stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <line x1="5" y1="12" x2="19" y2="12"/>
          <polyline points="12 5 19 12 12 19"/>
        </svg>`;
    }, 1800);
  }
});

$btnCancel.addEventListener('click', async () => {
  $btnCancel.disabled = true;
  await fetchNui('cancelRequest', {});
  $btnCancel.disabled = false;
  myRequest = null;
  myDriverCoords = null;
  myCoords = null;
  showView($home);
  loadDrivers();
});

$btnRefresh.addEventListener('click', () => {
  loadDrivers();
  refreshMyRequest();
});

// ---------- ride meter ----------
let rideSummaryTimer = null;

function openRideView(role, person) {
  document.getElementById('ride-role-label').textContent =
    role === 'driver' ? 'Course en cours' : 'Vous êtes en course';
  document.getElementById('ride-person-label').textContent = person || '';
  document.getElementById('ride-foot').textContent =
    role === 'driver'
      ? 'La course se clôture lorsque le client descend.'
      : "Le tarif s'arrête lorsque vous descendez du taxi.";
  document.getElementById('ride-summary').hidden = true;
  document.getElementById('ride-km').textContent = '0.00 km';
  document.getElementById('ride-fare').textContent = '$0';
  showView($ride);
}

function updateRide(meters, price) {
  document.getElementById('ride-km').textContent = (meters / 1000).toFixed(2) + ' km';
  document.getElementById('ride-fare').textContent = '$' + price;
}

function closeRideView(summary) {
  const el = document.getElementById('ride-summary');
  el.hidden = false;
  document.getElementById('sum-price').textContent = '$' + (summary.price || 0);
  document.getElementById('sum-paid').textContent  = '$' + (summary.paid  || 0);
  if (rideSummaryTimer) clearTimeout(rideSummaryTimer);
  rideSummaryTimer = setTimeout(() => {
    showView($home);
    loadDrivers();
  }, 6000);
}

document.getElementById('btn-ride-done').addEventListener('click', () => {
  if (rideSummaryTimer) clearTimeout(rideSummaryTimer);
  showView($home);
  loadDrivers();
});

// ---------- live updates from client.lua ----------
window.addEventListener('message', (e) => {
  const data = e.data || {};
  switch (data.action) {
    case 'taxi:accepted':
      refreshMyRequest();
      break;
    case 'taxi:driverPos':
      if (data.data) {
        myDriverCoords = data.data;
        drawMiniMap();
        const eta = computeEtaMinutes(myCoords, myDriverCoords);
        if (eta != null && !$driverCard.hidden) {
          $driverEtaWrap.hidden = false;
          $driverEta.textContent = String(eta);
        }
      }
      break;
    case 'taxi:ended':
      myRequest = null;
      myDriverCoords = null;
      myCoords = null;
      if (!$ride.classList.contains('view-active')) {
        showView($home);
        loadDrivers();
      }
      break;
    case 'taxiRide:start': {
      const d = data.data || {};
      const role   = d.role || 'passenger';
      const person = role === 'driver'
        ? (d.citizen    ? 'Client : '    + d.citizen    : 'Client à bord')
        : (d.driverName ? 'Chauffeur : ' + d.driverName : 'En course');
      openRideView(role, person);
      break;
    }
    case 'taxiRide:update': {
      const d = data.data || {};
      updateRide(d.meters || 0, d.price || 0);
      break;
    }
    case 'taxiRide:end':
      closeRideView(data.data || {});
      break;
    case 'open':
    case 'load':
      loadDrivers();
      refreshMyRequest();
      break;
  }
});

// ---------- polling ----------
let pollHandle = null;
function startPolling() {
  if (pollHandle) return;
  pollHandle = setInterval(() => {
    if ($active.classList.contains('view-active')) {
      refreshMyRequest();
    } else {
      loadDrivers();
    }
  }, 5000);
}
startPolling();

loadDrivers();
refreshMyRequest();
