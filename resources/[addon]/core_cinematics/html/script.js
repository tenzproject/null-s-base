/* ═══════════════════════════════════════════════════════════════════════════
   CORE CINEMATICS — script.js
════════════════════════════════════════════════════════════════════════════ */
'use strict';

// ── STATE ─────────────────────────────────────────────────────────────────────
const State = {
    keyframes:      [],
    selectedKfId:   null,
    fps:            30,
    durationSec:    30,
    currentFrame:   0,
    isPlaying:      false,
    isPositionMode: false,
    zoom:           2.0,
    shakeTypes:     [],
    colorFilters:   [],
    fovMin:         5,
    fovMax:         120,
    defaultFov:     50,
    draggingKfId:   null,
    dragStartX:     0,
    dragStartFrame: 0,
    nextId:         1,
    // World & Scenery settings
    worldSettings: { time: 12.0, freezeTime: false, weather: 'CLEAR', weatherOverride: true, rainEnabled: false, rainLevel: 0.0, windSpeed: 0, cityLights: false },
    fonts: [],
    // Interpolation settings
    interpSettings: { mode: 'eased', tension: 0.0, spring: 0.0 },
    // Vehicle recording (null when none loaded)
    vehicleRecording:  null,  // { duration, totalFrames, count }
    vehicleRecStart:   0,     // timeline frame where block starts
    vehicleRecEnd:     0,     // timeline frame where block ends
    vehicleRecTrimIn:  0,     // frames INTO the recording where playback starts (front trim)
    vehicleRecSelected: false, // whether the recording block is selected
    draggingVehRec:    null,  // { type, startX, origStart, origEnd, origTrimIn }
    // Live camera position (updated by Lua every 150ms + every frame in position mode)
    currentCamPos:  { x: 0, y: 0, z: 0 },
    currentCamRot:  { x: 0, y: 0, z: 0 },
    currentCamFov:  50,
    // Saved position before entering position mode (for ESC cancel)
    savedCamPos:    null,
    savedCamRot:    null,
    savedCamFov:    null,
    // 3D Text
    textObjects:      [],   // [{ id, text, font, color, shadow, animation, animIn, animOut, size, coords }]
    textClips:        [],   // [{ id, textId, startFrame, endFrame }]
    nextTextId:       1,
    nextTextClipId:   1,
    selectedClipId:   null,
    editingClipId:    null, // clip being edited in the text panel
    draggingClip:     null, // { clipId, type:'move'|'resizeL'|'resizeR', startX, origStart, origEnd }
    isTextPlacing:    false,
    shadowEnabled:    false,
    glowEnabled:      false,
    outlineEnabled:   false,
    colorShiftEnabled:false,
    colorShiftAdvanced:false,
    // Scene Editor
    sceneEntities:    [],   // [{ id, type:'ped'|'vehicle', model, pos, heading, anim, weapon, followPlayer, followDist, followSpeed, driveStyle }]
    nextSceneId:      1,
    selectedSceneId:  null,
    isScenePlacing:   false,
    predefinedAnims:  [],
    commonWeapons:    [],
    recEntityList:    [],   // [{ type:'vehicle'|'ped', idx, model, isPlayer }] from Lua
    pathSharingEnabled: true,
    // Overlay layers (solo-vehicle recordings, session-only)
    overlayLayers:     [],   // [{ id, name, model, duration, totalFrames, startFrame, endFrame, trimInFrame }]
    selectedOverlayId: null, // id of selected overlay layer
    draggingOverlay:   null, // { layerIdx, type:'move'|'resizeL'|'resizeR', startX, origStart, origEnd, origTrimIn }
    recLoading:        false, // true while recording data is arriving via latent event
    // Project system
    currentProject:      null,  // { slug, name, createdAt, updatedAt }
    projectList:         [],
    autoSaveTimer:       null,
    autoSaveDirty:       false,
};

// ── NUI POST ──────────────────────────────────────────────────────────────────
function post(event, data = {}) {
    fetch(`https://core_cinematics/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

async function postAwait(event, data = {}) {
    try {
        const res = await fetch(`https://core_cinematics/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        });
        return await res.json();
    } catch { return null; }
}

// ── LOCALE / TRANSLATION HELPER ───────────────────────────────────────────────
// Populated from Lua via the `show` NUI message (see onShow below).
// Usage: t('editor.save_project') or t('notifications.project_saved', { name: 'Intro' })
let _localeData = {};
function t(key, params) {
    const parts = String(key).split('.');
    let val = _localeData;
    for (const p of parts) {
        if (val && typeof val === 'object') val = val[p];
        else return key;
    }
    if (typeof val !== 'string') return key;
    if (params) {
        val = val.replace(/\{(\w+)\}/g, (_, k) =>
            params[k] !== undefined ? String(params[k]) : `{${k}}`);
    }
    return val;
}

// ── INIT / NUI MESSAGE HANDLER ────────────────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    switch (d.type) {
        case 'show':             onShow(d);                   break;
        case 'hide':             onHide();                    break;
        case 'coordsUpdate':     onCoordsUpdate(d);           break;
        case 'frameUpdate':      onFrameUpdate(d.frame);      break;
        case 'positionModeOn':   onPositionModeOn();          break;
        case 'positionSaved':    onPositionSaved(d);          break;
        case 'positionCancelled':onPositionCancelled();       break;
        case 'playbackStarted':  onPlaybackStarted();         break;
        case 'playbackStopped':  onPlaybackStopped(d);        break;
        case 'playbackError':           showToast(d.msg, 'error');        break;
        case 'vehicleRecordingLoaded':  onVehicleRecordingLoaded(d);     break;
        case 'overlayLayersLoaded':     onOverlayLayersLoaded(d);        break;
        case 'textPlacementActive':     onTextPlacementOverlay(d.active); break;
        case 'textPlacementDone':       onTextPlacementDone(d);           break;
        case 'sceneEntitySpawned':      onSceneEntitySpawned(d);          break;
        case 'sceneEntityDeleted':      onSceneEntityDeleted(d);          break;
        case 'sceneCombatState':        onSceneCombatState(d);            break;
        case 'sceneSpawnError':         showToast(d.msg, 'error');        break;
        case 'scenePlacementActive':    onScenePlacementOverlay(d.active); break;
        case 'scenePlacementDone':      onScenePlacementDone(d);          break;
        case 'replayEntityClicked':     onReplayEntityClicked(d);         break;
        case 'modelSwapDone':           onModelSwapDone(d);               break;
        case 'modelSwapError':          showToast(d.msg, 'error');        break;
        case 'fxUpdate':                onFxUpdate(d);                    break;
        case 'fxClear':                 onFxClear();                      break;
        case 'recordingCountdown':      onRecordingCountdown();           break;
        case 'recordingStarted':        onRecordingStarted();             break;
        case 'toast':                   showToast(d.msg, d.level || 'info'); break;
        case 'recordingStopped':        onRecordingStopped();             break;
        case 'recordingFinished':       onRecordingFinished();            break;
        case 'recLoading':              State.recLoading = true;  renderTimeline(); break;
        case 'recLoaded':               State.recLoading = false; renderTimeline(); break;
        case 'tutorialAdderPos':        State._tutCarPos = d.pos;         break;
        case 'recordingTick':           onRecordingTick(d.elapsed);       break;
        case 'projectList':             onProjectList(d.projects);        break;
        case 'projectLoaded':           onProjectLoaded(d.data);          break;
        case 'projectSaved':            onProjectSaved(d.slug);           break;
        case 'projectDeleted':          onProjectDeleted(d.slug);         break;
        case 'projectLoadError':        showToast(d.msg, 'error');        break;
    }
});

// Walks the DOM and applies current locale to [data-i18n] / [data-i18n-attr] elements.
// Safe to call repeatedly. Elements tagged with `data-i18n-html` use innerHTML so
// markup inside the translated string (e.g. <strong>) is preserved.
function applyStaticI18n(root) {
    const scope = root || document;
    scope.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const val = t(key);
        if (val === key) return;
        if (el.hasAttribute('data-i18n-html')) el.innerHTML = val;
        else el.textContent = val;
    });
    scope.querySelectorAll('[data-i18n-attr]').forEach(el => {
        const spec = el.getAttribute('data-i18n-attr');
        spec.split(';').forEach(pair => {
            const [attr, key] = pair.split(':').map(s => s && s.trim());
            if (!attr || !key) return;
            const val = t(key);
            if (val !== key) el.setAttribute(attr, val);
        });
    });
}

function onShow(d) {
    if (d.locale && typeof d.locale === 'object') {
        _localeData = d.locale;
        applyStaticI18n();
    }
    State.fps          = d.fps        || 30;
    State.shakeTypes   = d.shakes     || [];
    State.colorFilters = d.filters    || [];
    State.fonts        = d.fonts      || [];
    State.fovMin       = d.fovMin     || 5;
    State.fovMax       = d.fovMax     || 120;
    State.defaultFov   = d.defaultFov || 50;

    // Restore persisted duration from Lua; fall back to current State value (default 30)
    if (d.totalFrames && d.totalFrames > 0) {
        State.durationSec = d.totalFrames / State.fps;
    }

    State.predefinedAnims = d.predefinedAnims || [];
    State.commonWeapons  = d.commonWeapons  || [];
    State.tutorialDefault = d.tutorialDefault !== false;
    State.weatherConflicts = Array.isArray(d.weatherConflicts) ? d.weatherConflicts : [];
    State.autosaveInterval = d.autosaveInterval || 30000;
    State.defaultInterp    = d.defaultInterp || 'eased';
    State.defaultEasing    = d.defaultEasing || 'ease';
    // Apply the configured default interp mode to the editor state if no project-specific setting has kicked in yet
    if (State.interpSettings && !State.currentProject) {
        State.interpSettings.mode = State.defaultInterp;
    }
    updateWeatherConflictWarning();

    populateShakeDropdown();
    populateFilterDropdown();
    populateFontDropdown();
    populateSceneDropdowns();
    injectFontLinks(State.fonts);
    initCustomDropdowns();

    document.getElementById('app').classList.remove('hidden');
    document.getElementById('duration-input').value = State.durationSec;
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.onUIShown();

    // Show project overlay or timeline depending on whether a project is active
    if (State.currentProject) {
        hideProjectOverlay();
        document.getElementById('tb-project-name').textContent = State.currentProject.name || State.currentProject.slug;
        startAutoSave();
    } else {
        showProjectOverlay();
    }

    // Init share button state
    document.getElementById('tb-share-btn').classList.toggle('active', State.pathSharingEnabled);

    renderTimeline();
    updateTimecodeDisplay();
}

function onHide() {
    document.getElementById('app').classList.add('hidden');
    // Final auto-save before closing, then stop the timer
    if (State.currentProject) autoSaveProject();
    if (State.autoSaveTimer) { clearInterval(State.autoSaveTimer); State.autoSaveTimer = null; }
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.onUIHidden();
}

function onVehicleRecordingLoaded(d) {
    const vc = d.count    || 0;
    const pc = d.pedCount || 0;
    const isNew = !State.vehicleRecording ||
                  State.vehicleRecording.totalFrames !== d.totalFrames ||
                  State.vehicleRecording.count       !== vc ||
                  State.vehicleRecording.pedCount    !== pc;

    State.vehicleRecording = { duration: d.duration, totalFrames: d.totalFrames, count: vc, pedCount: pc };
    State.recEntityList    = d.entities || [];

    // Lua always sends current timing — use it to restore exact block position
    State.vehicleRecStart  = d.startFrame  !== undefined ? d.startFrame  : 0;
    State.vehicleRecEnd    = d.endFrame    !== undefined ? d.endFrame    : d.totalFrames;
    State.vehicleRecTrimIn = d.trimInFrame !== undefined ? d.trimInFrame : 0;

    // Auto-extend timeline if recording is longer than the current duration
    const recEndSec = Math.ceil(State.vehicleRecEnd / State.fps);
    if (recEndSec > State.durationSec) {
        State.durationSec = recEndSec;
        document.getElementById('duration-input').value = recEndSec;
        syncKeyframesToLua(); // persist the new totalFrames to Lua
    }

    renderTimeline();
    if (isNew) {
        let key;
        if (vc > 0 && pc > 0)      key = 'toasts.recording_loaded_mixed';
        else if (vc > 0)           key = vc > 1 ? 'toasts.vehicles_loaded' : 'toasts.vehicle_loaded';
        else                       key = pc > 1 ? 'toasts.peds_loaded'     : 'toasts.ped_loaded';
        showToast(t(key, { count: vc + pc, vehicles: vc, peds: pc, duration: d.duration.toFixed(1), frames: d.totalFrames }));
    }
}

function onCoordsUpdate(d) {
    if (!d.pos || !d.rot) return;
    State.currentCamPos = d.pos;
    State.currentCamRot = d.rot;
    State.currentCamFov = d.fov || State.defaultFov;

    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.onCoords(d.pos);

    // Update HUD
    document.getElementById('hud-pos').textContent =
        `X: ${d.pos.x.toFixed(2)} · Y: ${d.pos.y.toFixed(2)} · Z: ${d.pos.z.toFixed(2)}`;
    document.getElementById('hud-rot').textContent =
        `P: ${d.rot.x.toFixed(1)} · R: ${d.rot.y.toFixed(1)} · Y: ${d.rot.z.toFixed(1)}`;
    document.getElementById('hud-fov').textContent =
        `FOV: ${(d.fov || State.defaultFov).toFixed(1)}`;

    // If in position mode, update the side panel inputs live
    if (State.isPositionMode && State.selectedKfId !== null) {
        document.getElementById('sp-pos-x').value = d.pos.x.toFixed(4);
        document.getElementById('sp-pos-y').value = d.pos.y.toFixed(4);
        document.getElementById('sp-pos-z').value = d.pos.z.toFixed(4);
        document.getElementById('sp-rot-x').value = d.rot.x.toFixed(2);
        document.getElementById('sp-rot-y').value = d.rot.y.toFixed(2);
        document.getElementById('sp-rot-z').value = d.rot.z.toFixed(2);
        document.getElementById('sp-fov-slider').value = d.fov;
        document.getElementById('sp-fov-num').value    = (d.fov || State.defaultFov).toFixed(1);
    }

    // Feed live data to placement guide
    PlacementGuide.update(d.pos, d.rot, d.fov || State.defaultFov);
}

function onFrameUpdate(frame) {
    State.currentFrame = frame;
    updatePlayheadPosition();
    updateTimecodeDisplay();
    document.getElementById('frame-input').value = frame;
}

function onPositionModeOn() {
    State.isPositionMode = true;
    PlacementGuide.show('camera');
    document.getElementById('side-panel').classList.add('dimmed');
    document.getElementById('sp-pos-btn').disabled = true;
}

function onPositionSaved(d) {
    State.isPositionMode = false;
    PlacementGuide.hide();
    document.getElementById('side-panel').classList.remove('dimmed');
    document.getElementById('sp-pos-btn').disabled = false;

    if (State.selectedKfId === null) return;
    const kf = State.keyframes.find(k => k.id === State.selectedKfId);
    if (!kf) return;

    // Update the keyframe with the saved camera position
    kf.pos = { x: d.pos.x, y: d.pos.y, z: d.pos.z };
    kf.rot = { x: d.rot.x, y: d.rot.y, z: d.rot.z };
    kf.fov = d.fov;

    // Refresh side panel
    populateSidePanel(kf);
    syncKeyframesToLua();
    renderTimeline();
    showToast(t('toasts.camera_position_saved'));
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) {
        Tutorial.fire('tut:positionSaved');
    }
}

function onPositionCancelled() {
    State.isPositionMode = false;
    PlacementGuide.hide();
    document.getElementById('side-panel').classList.remove('dimmed');
    document.getElementById('sp-pos-btn').disabled = false;

    // Restore camera to keyframe's saved position
    if (State.selectedKfId !== null) {
        const kf = State.keyframes.find(k => k.id === State.selectedKfId);
        if (kf) post('previewKeyframe', { keyframe: kf });
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLACEMENT GUIDE — Premiere Pro style viewfinder, controls bar, live data
// ═══════════════════════════════════════════════════════════════════════════════
const PlacementGuide = (function() {
    let _mode  = null;   // 'camera' | 'text' | 'scene'
    let _built = false;

    const MODE_CONFIG = {
        camera: {
            icon: 'fa-video',     get title() { return t('ui.pg_position_camera_title'); }, get label() { return t('ui.pg_camera_label'); },
            confirmKey: 'Backspace', get confirmLabel() { return t('ui.pg_save'); },
            showFov: true, showQE: false, showVert: false,
            get scrollLabel() { return t('ui.pg_fov'); },
        },
        text: {
            icon: 'fa-font',      get title() { return t('ui.pg_place_text_title'); },      get label() { return t('ui.pg_text_label'); },
            confirmKey: 'Enter',   get confirmLabel() { return t('ui.pg_confirm'); },
            showFov: false, showQE: true, showVert: true,
            get scrollLabel() { return t('ui.pg_distance'); },
        },
        scene: {
            icon: 'fa-arrows-up-down-left-right', get title() { return t('ui.pg_place_entity_title'); }, get label() { return t('ui.pg_entity_label'); },
            confirmKey: 'Enter',   get confirmLabel() { return t('ui.pg_confirm'); },
            showFov: false, showQE: true, showVert: true,
            get scrollLabel() { return t('ui.pg_distance'); },
        },
    };

    function buildRingTicks() {
        const g = document.getElementById('pg-ring-ticks');
        if (!g || g.childElementCount > 0) return;
        for (let deg = 0; deg < 360; deg += 5) {
            const isMajor = deg % 30 === 0;
            const r1 = isMajor ? 82 : 86;
            const r2 = 92;
            const rad = (deg - 90) * Math.PI / 180;
            const l = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            l.setAttribute('x1', 100 + r1 * Math.cos(rad));
            l.setAttribute('y1', 100 + r1 * Math.sin(rad));
            l.setAttribute('x2', 100 + r2 * Math.cos(rad));
            l.setAttribute('y2', 100 + r2 * Math.sin(rad));
            if (isMajor) l.classList.add('pg-tick-major');
            g.appendChild(l);
        }
        _built = true;
    }

    function updateFovArc(fov) {
        const path = document.getElementById('pg-fov-path');
        const label = document.getElementById('pg-fov-label');
        if (!path) return;
        // Map FOV (5–120) to arc half-angle (10°–80°)
        const halfAngle = 10 + ((fov - 5) / 115) * 70;
        const cx = 60, cy = 46, r = 38;
        const a1 = (270 - halfAngle) * Math.PI / 180;
        const a2 = (270 + halfAngle) * Math.PI / 180;
        const x1 = cx + r * Math.cos(a1);
        const y1 = cy + r * Math.sin(a1);
        const x2 = cx + r * Math.cos(a2);
        const y2 = cy + r * Math.sin(a2);
        const large = halfAngle > 90 ? 1 : 0;
        path.setAttribute('d', `M${x1},${y1} A${r},${r} 0 ${large} 1 ${x2},${y2}`);
        if (label) label.textContent = fov.toFixed(1);
    }

    function updateRing(yaw) {
        const needle = document.getElementById('pg-ring-needle');
        const degLabel = document.getElementById('pg-ring-deg');
        if (!needle) return;
        // Normalize yaw to 0-360
        let deg = ((yaw % 360) + 360) % 360;
        needle.setAttribute('transform', `rotate(${deg} 100 100)`);
        if (degLabel) degLabel.textContent = deg.toFixed(1) + '°';
    }

    function updatePitch(pitch) {
        const bar = document.getElementById('pg-pitch-bar');
        const label = document.getElementById('pg-pitch-label');
        if (!bar) return;
        // Pitch ranges -89 to 89, map to 0% (top) to 100% (bottom)
        const pct = 50 - (pitch / 89) * 50;
        bar.style.setProperty('--pg-pitch', pct + '%');
        if (label) label.textContent = pitch.toFixed(1) + '°';
    }

    return {
        show(mode) {
            _mode = mode;
            const cfg = MODE_CONFIG[mode];
            const el = document.getElementById('placement-guide');
            if (!el) return;

            // Build ticks on first show
            if (!_built) buildRingTicks();

            // Mode class
            el.className = 'mode-' + mode;

            // Configure controls
            document.querySelector('.pg-ctrl-icon i').className = 'fa-solid ' + cfg.icon;
            document.getElementById('pg-mode-title').textContent = cfg.title;
            document.getElementById('pg-mode-label').textContent = cfg.label;
            document.getElementById('pg-confirm-key').textContent = cfg.confirmKey;
            document.querySelector('#pg-ctrl-confirm span').textContent = cfg.confirmLabel;

            // Scroll label
            document.querySelector('#pg-ctrl-scroll span').textContent = cfg.scrollLabel;

            // Show/hide Q/E and Vert controls
            document.getElementById('pg-ctrl-qe').classList.toggle('hidden', !cfg.showQE);
            document.getElementById('pg-ctrl-sep-qe').classList.toggle('hidden', !cfg.showQE);
            document.getElementById('pg-ctrl-vert').classList.toggle('hidden', !cfg.showVert);
            document.getElementById('pg-ctrl-sep-vert').classList.toggle('hidden', !cfg.showVert);

            // FOV arc visibility
            document.getElementById('pg-fov-wrap').style.opacity = cfg.showFov ? '1' : '0.3';

            // Initial values from current state
            this.update(State.currentCamPos, State.currentCamRot, State.currentCamFov);

            el.classList.remove('hidden');
            document.getElementById('coords-hud').classList.add('hidden');
        },

        hide() {
            _mode = null;
            const el = document.getElementById('placement-guide');
            if (el) el.classList.add('hidden');
            document.getElementById('coords-hud').classList.remove('hidden');
        },

        update(pos, rot, fov) {
            if (!_mode) return;
            // Data bar
            const dx = document.getElementById('pg-dx');
            if (dx) {
                dx.textContent = pos.x.toFixed(2);
                document.getElementById('pg-dy').textContent = pos.y.toFixed(2);
                document.getElementById('pg-dz').textContent = pos.z.toFixed(2);
                document.getElementById('pg-dp').textContent = rot.x.toFixed(1);
                document.getElementById('pg-dr').textContent = rot.y.toFixed(1);
                document.getElementById('pg-dyaw').textContent = rot.z.toFixed(1);
                document.getElementById('pg-dfov').textContent = (fov || State.defaultFov).toFixed(1);
            }
            // Viewfinder elements
            updateRing(rot.z);
            updateFovArc(fov || State.defaultFov);
            updatePitch(rot.x);
        },

        isActive() { return _mode !== null; },
    };
})();

function onPlaybackStarted() {
    State.isPlaying = true;
    document.getElementById('play-btn').innerHTML = '<i class="fa-solid fa-pause"></i>';
    document.getElementById('timeline-panel').classList.add('playback-active');
    document.getElementById('side-panel').classList.add('playback-active');
    document.getElementById('coords-hud').classList.add('hidden');
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) {
        document.getElementById('tut-root').classList.add('hidden');
    }
}

function onPlaybackStopped(d) {
    State.isPlaying = false;
    document.getElementById('play-btn').innerHTML = '<i class="fa-solid fa-play"></i>';
    document.getElementById('timeline-panel').classList.remove('playback-active');
    document.getElementById('side-panel').classList.remove('playback-active');
    document.getElementById('coords-hud').classList.remove('hidden');
    if (d && d.frame !== undefined) {
        State.currentFrame = d.frame;
        updatePlayheadPosition();
        updateTimecodeDisplay();
        document.getElementById('frame-input').value = d.frame;
    }
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) {
        document.getElementById('tut-root').classList.remove('hidden');
        Tutorial.fire('tut:playbackFinished');
    }
}

// ── DROPDOWNS ─────────────────────────────────────────────────────────────────
function populateShakeDropdown() {
    const el = document.getElementById('sp-shake-type');
    el.innerHTML = '<option value="none">None</option>';
    State.shakeTypes.forEach(s => {
        const o = document.createElement('option');
        o.value = s.id; o.textContent = s.label;
        el.appendChild(o);
    });
}

function populateFilterDropdown() {
    const el = document.getElementById('sp-filter-id');
    el.innerHTML = '<option value="none">None</option>';
    State.colorFilters.forEach(f => {
        const o = document.createElement('option');
        o.value = f.id; o.textContent = f.label;
        el.appendChild(o);
    });
}

function populateFontDropdown() {
    const el = document.getElementById('tv-font');
    el.innerHTML = '';
    State.fonts.forEach(f => {
        const o = document.createElement('option');
        o.value         = f.family;
        o.textContent   = f.label;
        o.style.fontFamily = f.family;
        el.appendChild(o);
    });
    const syncSelectFont = () => {
        const opt = el.options[el.selectedIndex];
        el.style.fontFamily = opt ? opt.style.fontFamily : '';
    };
    syncSelectFont();
    el.addEventListener('change', syncSelectFont);
}

function injectFontLinks(fonts) {
    fonts.forEach(f => {
        if (!f.url) return;
        if (document.querySelector(`link[data-font="${f.family}"]`)) return;
        const link = document.createElement('link');
        link.rel              = 'stylesheet';
        link.href             = f.url;
        link.dataset.font     = f.family;
        document.head.appendChild(link);
    });
}

// ── KEYFRAME MANAGEMENT ───────────────────────────────────────────────────────
function makeKeyframe(frame, pos, rot, fov) {
    return {
        id:     State.nextId++,
        frame:  frame,
        pos:    pos || { x: 0, y: 0, z: 0 },
        rot:    rot || { x: 0, y: 0, z: 0 },
        fov:    fov || State.defaultFov,
        easing: State.defaultEasing || 'ease',
        time:   { enabled: false, value: 12.0 },
        effects: {
            shake:      { type: 'none', amplitude: 0 },
            dof:        { enabled: false, near: 3.0, far: 50, fNumber: 1.2, strength: 1 },
            motionBlur: 0,
            filter:     { id: 'none', strength: 1 },
        },
    };
}

function sortKeyframes() {
    State.keyframes.sort((a, b) => a.frame - b.frame);
}

function syncKeyframesToLua() {
    post('setKeyframes', {
        keyframes:   State.keyframes,
        totalFrames: totalFrames(),
    });
}

function totalFrames() {
    return State.durationSec * State.fps;
}

// ── CC PUBLIC API ─────────────────────────────────────────────────────────────
const CC = window.CC = {};

CC.openWorldSettings = function() {
    hideAllViews();
    document.getElementById('sp-world-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('ui.title_world_scenery');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
};

CC.openInterpSettings = function() {
    hideAllViews();
    document.getElementById('sp-interp-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('ui.title_interpolation');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
    // Sync controls to current state
    document.getElementById('is-mode').value        = State.interpSettings.mode;
    document.getElementById('is-tension').value     = State.interpSettings.tension;
    document.getElementById('is-tension-num').value = State.interpSettings.tension.toFixed(2);
    document.getElementById('is-spring').value      = State.interpSettings.spring;
    document.getElementById('is-spring-num').value  = State.interpSettings.spring.toFixed(2);
    CC._updateInterpHint(State.interpSettings.mode);
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.fire('tut:interpOpened');
};

CC._updateInterpHint = function(mode) {
    const hints = {
        native: t('ui.interp_hint_native'),
        eased:  t('ui.interp_hint_eased'),
        spline: t('ui.interp_hint_spline'),
    };
    document.getElementById('is-mode-hint').textContent = hints[mode] || hints.native;
    const splineOnly = mode === 'spline';
    for (const id of ['is-tension-section', 'is-spring-section']) {
        const el = document.getElementById(id);
        el.style.opacity       = splineOnly ? '1'    : '0.35';
        el.style.pointerEvents = splineOnly ? 'auto' : 'none';
    }
};

CC.applyInterpSettings = function() {
    const mode    = document.getElementById('is-mode').value;
    const tension = parseFloat(document.getElementById('is-tension').value) || 0;
    const spring  = parseFloat(document.getElementById('is-spring').value)  || 0;
    const prevMode = State.interpSettings.mode;
    State.interpSettings.mode    = mode;
    State.interpSettings.tension = tension;
    State.interpSettings.spring  = spring;
    CC._updateInterpHint(mode);
    post('setInterpSettings', State.interpSettings);
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive() && mode !== prevMode) Tutorial.fire('tut:interpChanged');
};

CC.openRecordingSettings = function() {
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.fire('tut:openedRecordings');
    hideAllViews();
    document.getElementById('sp-record-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('ui.title_recording');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
};

CC.startVehicleRecord = async function() {
    // Recordings are stored against a project slug. Without an active project
    // the captured frames have nowhere to go and would silently overwrite the
    // last project's recording when the user later opens it.
    if (!State.currentProject) {
        showToast(t('errors.no_project_for_recording') || 'Open or create a project first', 'error');
        return;
    }
    const vehicles = document.getElementById('rec-vehicles').checked;
    const peds     = document.getElementById('rec-peds').checked;
    if (!vehicles && !peds) {
        showToast(t('errors.select_recording_target'), 'error');
        return;
    }
    const tutActive = typeof Tutorial !== 'undefined' && Tutorial.isActive();
    if (tutActive) {
        // Block until Adder is spawned + player is warped in, THEN start the real record.
        await postAwait('tutorialSpawnAdder');
        post('startVehicleRecord', { vehicles, peds });
        Tutorial.fire('tut:recordingStarted');
        return;
    }
    post('startVehicleRecord', { vehicles, peds });
};

CC.setVehicleMotionBlur = function(enabled) {
    post('setVehicleMotionBlur', { enabled: !!enabled });
};

CC.backToMenu = function() {
    // If viewing scene entity props, go back to scene list (not main menu)
    if (!document.getElementById('sp-scene-props-view').classList.contains('hidden')) {
        CC.backFromSceneProps();
        return;
    }
    hideAllViews();
    document.getElementById('sp-menu-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('ui.title_no_keyframe_selected');
    State.editingClipId = null;
    State.selectedSceneId = null;
    deselectClip();
    post('unfocusEntity');
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.fire('tut:backToMenu');
};

CC.open3DTextPanel = function() {
    State.editingClipId = null;
    hideAllViews();
    document.getElementById('sp-text-view').classList.remove('hidden');
    document.getElementById('tv-create-mode').classList.remove('hidden');
    document.getElementById('tv-edit-mode').classList.add('hidden');
    document.getElementById('sp-title').textContent = t('text3d.title');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');

    // Reset form to defaults so previous edit values don't leak
    document.getElementById('tv-text').value    = '';
    document.getElementById('tv-font').value    = 'Arial';
    document.getElementById('tv-color').value   = '#ffffff';
    document.getElementById('tv-size').value     = 4;
    document.getElementById('tv-anim').value     = 'fadeSlide';
    document.getElementById('tv-anim-in').value  = 15;
    document.getElementById('tv-anim-out').value = 15;
    State.shadowEnabled = false;
    const sBtn = document.getElementById('tv-shadow-btn');
    sBtn.textContent = t('ui.off'); sBtn.classList.remove('active');
    State.glowEnabled = false;
    const gBtn = document.getElementById('tv-glow-btn');
    gBtn.textContent = t('ui.off'); gBtn.classList.remove('active');
    State.outlineEnabled = false;
    const oBtn = document.getElementById('tv-outline-btn');
    if (oBtn) { oBtn.textContent = t('ui.off'); oBtn.classList.remove('active'); }
    const ocl = document.getElementById('tv-outline-color');  if (ocl) ocl.value = '#000000';
    const owd = document.getElementById('tv-outline-width');  if (owd) owd.value = 2;
    State.colorShiftEnabled = false;
    const cBtn = document.getElementById('tv-chroma-btn');
    if (cBtn) { cBtn.textContent = t('ui.off'); cBtn.classList.remove('active'); }
    State.colorShiftAdvanced = false;
    const cAdv = document.getElementById('tv-chroma-adv-btn');
    if (cAdv) { cAdv.textContent = t('ui.off'); cAdv.classList.remove('active'); }
    const advRow = document.getElementById('tv-chroma-adv-row');
    if (advRow) advRow.classList.add('hidden');
    const colIn = document.getElementById('tv-chroma-colors');
    if (colIn) colIn.value = '';
};

CC.toggleShadow = function() {
    State.shadowEnabled = !State.shadowEnabled;
    const btn = document.getElementById('tv-shadow-btn');
    btn.textContent = State.shadowEnabled ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', State.shadowEnabled);
};

CC.toggleGlow = function() {
    State.glowEnabled = !State.glowEnabled;
    const btn = document.getElementById('tv-glow-btn');
    btn.textContent = State.glowEnabled ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', State.glowEnabled);
};

CC.toggleOutline = function() {
    State.outlineEnabled = !State.outlineEnabled;
    const btn = document.getElementById('tv-outline-btn');
    btn.textContent = State.outlineEnabled ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', State.outlineEnabled);
};

CC.toggleColorShift = function() {
    State.colorShiftEnabled = !State.colorShiftEnabled;
    const btn = document.getElementById('tv-chroma-btn');
    btn.textContent = State.colorShiftEnabled ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', State.colorShiftEnabled);
};

CC.toggleColorShiftAdvanced = function() {
    State.colorShiftAdvanced = !State.colorShiftAdvanced;
    const btn = document.getElementById('tv-chroma-adv-btn');
    btn.textContent = State.colorShiftAdvanced ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', State.colorShiftAdvanced);
    document.getElementById('tv-chroma-adv-row').classList.toggle('hidden', !State.colorShiftAdvanced);
};

CC.startTextPlacement = function() {
    const text = document.getElementById('tv-text').value.trim();
    if (!text) { showToast(t('errors.enter_text_content'), 'error'); return; }
    const fontName  = document.getElementById('tv-font').value;
    const fontEntry = State.fonts.find(f => f.family === fontName);
    const config = {
        text:    text,
        font:    fontName,
        fontUrl: fontEntry ? (fontEntry.url || '') : '',
        color:   document.getElementById('tv-color').value,
        size:    parseFloat(document.getElementById('tv-size').value) || 4.0,
        shadow:  State.shadowEnabled,
        glow:    State.glowEnabled,
        outline:          State.outlineEnabled,
        outlineColor:     document.getElementById('tv-outline-color').value || '#000000',
        outlineWidth:     parseInt(document.getElementById('tv-outline-width').value) || 2,
        colorShift:       State.colorShiftEnabled,
        colorShiftColors: State.colorShiftAdvanced ? (document.getElementById('tv-chroma-colors').value || '') : '',
        colorShiftSpeed:  parseInt(document.getElementById('tv-chroma-speed').value) || 60,
        camPos:  { x: State.currentCamPos.x, y: State.currentCamPos.y, z: State.currentCamPos.z },
        camRot:  { x: State.currentCamRot.x, y: State.currentCamRot.y, z: State.currentCamRot.z },
    };

    // When re-placing an existing text, start the camera near the text's current position
    if (State.editingClipId !== null) {
        const clip = State.textClips.find(c => c.id === State.editingClipId);
        const obj  = clip ? State.textObjects.find(o => o.id === clip.textId) : null;
        if (obj && obj.coords) {
            config.existingCoords = { x: obj.coords.x, y: obj.coords.y, z: obj.coords.z, heading: obj.coords.heading || 0 };
        }
    }

    post('startTextPlacement', config);
};

CC.saveClipEdit = function() {
    if (State.editingClipId === null) return;
    const clip = State.textClips.find(c => c.id === State.editingClipId);
    if (!clip) return;
    const obj = State.textObjects.find(o => o.id === clip.textId);
    if (!obj) return;
    obj.text      = document.getElementById('tv-text').value.trim() || obj.text;
    obj.font      = document.getElementById('tv-font').value;
    obj.color     = document.getElementById('tv-color').value;
    obj.size      = parseFloat(document.getElementById('tv-size').value) || 4.0;
    obj.shadow    = State.shadowEnabled;
    obj.glow      = State.glowEnabled;
    obj.outline          = State.outlineEnabled;
    obj.outlineColor     = document.getElementById('tv-outline-color').value || '#000000';
    obj.outlineWidth     = parseInt(document.getElementById('tv-outline-width').value) || 2;
    obj.colorShift         = State.colorShiftEnabled;
    obj.colorShiftAdvanced = State.colorShiftAdvanced;
    obj.colorShiftColors   = State.colorShiftAdvanced ? (document.getElementById('tv-chroma-colors').value || '') : '';
    obj.colorShiftSpeed    = parseInt(document.getElementById('tv-chroma-speed').value) || 60;
    obj.animation = document.getElementById('tv-anim').value;
    obj.animIn    = parseInt(document.getElementById('tv-anim-in').value)  || 15;
    obj.animOut   = parseInt(document.getElementById('tv-anim-out').value) || 15;
    const start = parseInt(document.getElementById('tc-start').value) || 0;
    const end   = parseInt(document.getElementById('tc-end').value)   || (start + 60);
    clip.startFrame = Math.max(0, start);
    clip.endFrame   = Math.max(clip.startFrame + 1, end);
    syncTextToLua();
    renderTimeline();
    showToast(t('toasts.text_clip_saved'));
};

CC.updateClipTiming = function() {
    if (State.editingClipId === null) return;
    const clip = State.textClips.find(c => c.id === State.editingClipId);
    if (!clip) return;
    const start = parseInt(document.getElementById('tc-start').value) || 0;
    const end   = parseInt(document.getElementById('tc-end').value) || (start + 60);
    clip.startFrame = Math.max(0, start);
    clip.endFrame   = Math.max(clip.startFrame + 1, end);
    syncTextToLua();
    renderTextTrack(getTimelineWidth());
};

CC.deleteSelectedClip = function() {
    if (State.editingClipId === null) return;
    pushUndo();
    const clip = State.textClips.find(c => c.id === State.editingClipId);
    if (clip) {
        State.textClips   = State.textClips.filter(c => c.id !== clip.id);
        State.textObjects = State.textObjects.filter(o => o.id !== clip.textId);
    }
    State.editingClipId = null;
    deselectClip();
    syncTextToLua();
    renderTimeline();
    CC.backToMenu();
};

CC.applyWorldSettings = function() {
    State.worldSettings.time            = parseFloat(document.getElementById('ws-time-num').value) || 12.0;
    State.worldSettings.freezeTime      = document.getElementById('ws-freeze').checked;
    State.worldSettings.weather         = document.getElementById('ws-weather').value;
    State.worldSettings.weatherOverride = document.getElementById('ws-weather-override').checked;
    State.worldSettings.rainEnabled     = document.getElementById('ws-rain-enabled').checked;
    State.worldSettings.rainLevel       = parseFloat(document.getElementById('ws-rain-num').value) || 0.0;
    State.worldSettings.cityLights      = document.getElementById('ws-citylights').checked;
    post('setWorldSettings', State.worldSettings);
};

// Add keyframe at current playhead using CURRENT CAMERA POSITION
CC.addKeyframe = function() {
    pushUndo();
    const kf = makeKeyframe(
        State.currentFrame,
        { ...State.currentCamPos },
        { ...State.currentCamRot },
        State.currentCamFov
    );
    State.keyframes.push(kf);
    sortKeyframes();
    syncKeyframesToLua();
    renderTimeline();
    selectKeyframe(kf.id);
    showToast(t('toasts.keyframe_added', { id: kf.id, frame: kf.frame }));
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) Tutorial.fire('tut:keyframeAdded');
};

CC.deleteSelectedKeyframe = function() {
    if (State.selectedKfId === null) return;
    pushUndo();
    State.keyframes = State.keyframes.filter(k => k.id !== State.selectedKfId);
    State.selectedKfId = null;
    syncKeyframesToLua();
    renderTimeline();
    hideSidePanel();
};

CC.clearAll = function() {
    if (State.keyframes.length === 0) return;
    State.keyframes = [];
    State.selectedKfId = null;
    syncKeyframesToLua();
    renderTimeline();
    hideSidePanel();
};

// Enter position mode for selected keyframe
CC.positionCamera = function() {
    if (State.selectedKfId === null) {
        showToast(t('errors.select_keyframe_first'), 'error');
        return;
    }
    post('startPositionMode', {});
};

// Auto-save all panel values to the selected keyframe on every change (debounced)
let _autoSaveDebounce = null;
CC.autoSavePanel = function() {
    clearTimeout(_autoSaveDebounce);
    _autoSaveDebounce = setTimeout(() => {
        if (State.selectedKfId === null) return;
        const kf = State.keyframes.find(k => k.id === State.selectedKfId);
        if (!kf) return;

        kf.frame  = parseInt(document.getElementById('sp-frame').value)  || kf.frame;
        kf.easing = document.getElementById('sp-easing').value;
        const timeChecked = document.getElementById('sp-time-enabled').checked;
        kf.time = {
            enabled: timeChecked,
            // When disabled, preserve the old stored value (don't overwrite with world settings display)
            value: timeChecked
                ? (parseFloat(document.getElementById('sp-time-num').value) || 12.0)
                : (kf.time ? kf.time.value : 12.0),
        };
        kf.pos = {
            x: parseFloat(document.getElementById('sp-pos-x').value) || 0,
            y: parseFloat(document.getElementById('sp-pos-y').value) || 0,
            z: parseFloat(document.getElementById('sp-pos-z').value) || 0,
        };
        kf.rot = {
            x: parseFloat(document.getElementById('sp-rot-x').value) || 0,
            y: parseFloat(document.getElementById('sp-rot-y').value) || 0,
            z: parseFloat(document.getElementById('sp-rot-z').value) || 0,
        };
        kf.fov = parseFloat(document.getElementById('sp-fov-num').value) || State.defaultFov;
        kf.effects = {
            shake: {
                type:      document.getElementById('sp-shake-type').value,
                amplitude: parseFloat(document.getElementById('sp-shake-amp-num').value) || 0,
            },
            dof: {
                enabled:  document.getElementById('sp-dof-enabled').checked,
                near:     parseFloat(document.getElementById('sp-dof-near').value)        || 3.0,
                far:      parseFloat(document.getElementById('sp-dof-far').value)         || 50,
                fNumber:  parseFloat(document.getElementById('sp-dof-fnum-num').value)    || 1.2,
                strength: parseFloat(document.getElementById('sp-dof-str-num').value)     || 1,
            },
            motionBlur: parseFloat(document.getElementById('sp-blur-num').value) || 0,
            timeScale:  parseFloat(document.getElementById('sp-timescale-num').value) || 1.0,
            filter: {
                id:       document.getElementById('sp-filter-id').value,
                strength: parseFloat(document.getElementById('sp-filter-str-num').value) || 1,
            },
            fade: {
                type:   document.getElementById('sp-fade-type').value || 'none',
                amount: parseFloat(document.getElementById('sp-fade-amount-num').value) || 0,
            },
            letterbox:  parseFloat(document.getElementById('sp-letterbox-ratio').value) || 0,
            vignette:   parseFloat(document.getElementById('sp-vignette-num').value) || 0,
            grain:      parseFloat(document.getElementById('sp-grain-num').value) || 0,
        };

        sortKeyframes();
        syncKeyframesToLua();
        renderTimeline();
        const idx = State.keyframes.indexOf(kf) + 1;
        document.getElementById('sp-title').textContent = t('ui.title_keyframe', { idx: idx, frame: kf.frame });
        post('previewKeyframe', { keyframe: kf });
    }, 60);
};

CC.close = function() { post('close', {}); };

CC.togglePathSharing = function() {
    State.pathSharingEnabled = !State.pathSharingEnabled;
    const btn = document.getElementById('tb-share-btn');
    btn.classList.toggle('active', State.pathSharingEnabled);
    post('setPathSharing', { enabled: State.pathSharingEnabled });
    showToast(State.pathSharingEnabled ? t('toasts.path_sharing_on') : t('toasts.path_sharing_off'));
};

CC.newTimeline = async function() {
    if (State.keyframes.length > 0 || State.textClips.length > 0 || State.sceneEntities.length > 0) {
        if (!await nuiConfirm(t('ui.confirm_new_timeline_title'), t('ui.confirm_new_timeline_message'))) return;
    }
    State.keyframes    = []; State.selectedKfId = null; State.currentFrame = 0;
    State.textObjects  = []; State.textClips = [];
    State.nextTextId   = 1;  State.nextTextClipId = 1;
    State.nextId       = 1;
    // Clear scene entities
    State.sceneEntities.forEach(ent => post('deleteSceneEntity', { entityId: ent.id }));
    State.sceneEntities = []; State.nextSceneId = 1; State.selectedSceneId = null;
    State.durationSec  = 30;
    // Detach from current project
    State.currentProject = null;
    if (State.autoSaveTimer) { clearInterval(State.autoSaveTimer); State.autoSaveTimer = null; }
    document.getElementById('tb-project-name').textContent = t('project.untitled');
    document.getElementById('tb-autosave-status').textContent = '';
    document.getElementById('duration-input').value = 30;
    document.getElementById('frame-input').value    = 0;
    syncKeyframesToLua(); syncTextToLua();
    renderTimeline(); updateTimecodeDisplay(); hideSidePanel(); CC.backToMenu();
    showProjectOverlay();
};

CC.exportTimeline = function() {
    const data = {
        version:     1,
        fps:         State.fps,
        duration:    State.durationSec,
        keyframes:   State.keyframes,
        textObjects: State.textObjects,
        textClips:   State.textClips,
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url  = URL.createObjectURL(blob);
    const a    = Object.assign(document.createElement('a'), { href: url, download: `timeline_${Date.now()}.json` });
    a.click(); URL.revokeObjectURL(url);
    showToast(t('toasts.timeline_exported'));
};

CC.importTimeline = function() { document.getElementById('import-file-input').click(); };

document.getElementById('import-file-input').addEventListener('change', (e) => {
    const file = e.target.files[0]; if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
        try {
            const data = JSON.parse(ev.target.result);
            if (!data.keyframes) throw new Error(t('errors.invalid_format'));
            State.keyframes = data.keyframes;
            State.durationSec = data.duration || 30;
            State.fps = data.fps || 30;
            State.nextId = 1;
            State.keyframes.forEach(kf => { kf.id = State.nextId++; });

            // Restore 3D text data
            State.textObjects    = data.textObjects  || [];
            State.textClips      = data.textClips    || [];
            State.nextTextId     = State.textObjects.reduce((m, o) => Math.max(m, o.id + 1), 1);
            State.nextTextClipId = State.textClips.reduce((m, c) => Math.max(m, c.id + 1), 1);

            document.getElementById('duration-input').value = State.durationSec;
            sortKeyframes();
            syncKeyframesToLua();
            syncTextToLua();
            renderTimeline();
            renderTextObjectsList();
            showToast(t('toasts.import_success', { keyframes: State.keyframes.length, textObjects: State.textObjects.length }));
        } catch (err) { showToast(t('errors.import_failed', { error: err.message }), 'error'); }
    };
    reader.readAsText(file);
    e.target.value = '';
});

// ── SIDE PANEL ────────────────────────────────────────────────────────────────
function selectKeyframe(kfId) {
    // Cancel any pending auto-save from the previous keyframe so it doesn't
    // fire against the newly selected one
    clearTimeout(_autoSaveDebounce);

    State.selectedKfId = kfId;
    if (State.vehicleRecSelected) deselectVehicleRec();

    const kf = State.keyframes.find(k => k.id === kfId);
    if (!kf) return;

    // Move playhead to the keyframe's frame
    State.currentFrame = kf.frame;
    document.getElementById('frame-input').value = kf.frame;
    updatePlayheadPosition();
    updateTimecodeDisplay();

    renderTimeline();
    populateSidePanel(kf);
    showSidePanel(kf);

    // Instantly jump camera to this keyframe's position
    post('previewKeyframe', { keyframe: kf });
}

function populateSidePanel(kf) {
    const fx    = kf.effects || {};
    const shake = fx.shake  || { type: 'none', amplitude: 0 };
    const dof   = fx.dof    || { enabled: false, near: 0.5, far: 50, strength: 1 };
    const filter= fx.filter || { id: 'none', strength: 1 };
    const time  = kf.time   || { enabled: false, value: 12.0 };

    document.getElementById('sp-frame').value  = kf.frame;
    document.getElementById('sp-easing').value = kf.easing || 'ease';

    const timeEnabled  = !!time.enabled;
    const timeDisplay  = timeEnabled ? (time.value || 12) : State.worldSettings.time;
    document.getElementById('sp-time-enabled').checked  = timeEnabled;
    document.getElementById('sp-time-slider').value     = timeDisplay;
    document.getElementById('sp-time-slider').disabled  = !timeEnabled;
    document.getElementById('sp-time-num').value        = timeDisplay.toFixed(1);
    document.getElementById('sp-time-num').disabled     = !timeEnabled;

    document.getElementById('sp-pos-x').value = kf.pos.x.toFixed(4);
    document.getElementById('sp-pos-y').value = kf.pos.y.toFixed(4);
    document.getElementById('sp-pos-z').value = kf.pos.z.toFixed(4);
    document.getElementById('sp-rot-x').value = kf.rot.x.toFixed(4);
    document.getElementById('sp-rot-y').value = kf.rot.y.toFixed(4);
    document.getElementById('sp-rot-z').value = kf.rot.z.toFixed(4);

    const fov = kf.fov || State.defaultFov;
    document.getElementById('sp-fov-slider').value = fov;
    document.getElementById('sp-fov-num').value    = fov;

    document.getElementById('sp-shake-type').value    = shake.type || 'none';
    document.getElementById('sp-shake-amp').value     = shake.amplitude || 0;
    document.getElementById('sp-shake-amp-num').value = (shake.amplitude || 0).toFixed(2);

    document.getElementById('sp-dof-enabled').checked  = !!dof.enabled;
    document.getElementById('sp-dof-near').value        = dof.near    || 3.0;
    document.getElementById('sp-dof-far').value         = dof.far     || 50;
    document.getElementById('sp-dof-fnum').value        = dof.fNumber || 1.2;
    document.getElementById('sp-dof-fnum-num').value    = (dof.fNumber || 1.2).toFixed(1);
    document.getElementById('sp-dof-str').value         = dof.strength || 1;
    document.getElementById('sp-dof-str-num').value     = (dof.strength || 1).toFixed(2);

    document.getElementById('sp-blur').value     = fx.motionBlur || 0;
    document.getElementById('sp-blur-num').value = (fx.motionBlur || 0).toFixed(2);

    document.getElementById('sp-timescale').value     = fx.timeScale || 1.0;
    document.getElementById('sp-timescale-num').value = (fx.timeScale || 1.0).toFixed(2);

    document.getElementById('sp-filter-id').value       = filter.id || 'none';
    document.getElementById('sp-filter-str').value      = filter.strength || 1;
    document.getElementById('sp-filter-str-num').value  = (filter.strength || 1).toFixed(2);

    // Cinematic effects
    const fade = fx.fade || {};
    document.getElementById('sp-fade-type').value           = fade.type || 'none';
    document.getElementById('sp-fade-amount').value         = fade.amount || 0;
    document.getElementById('sp-fade-amount-num').value     = (fade.amount || 0).toFixed(2);
    document.getElementById('sp-letterbox-ratio').value     = fx.letterbox || 0;
    document.getElementById('sp-vignette').value            = fx.vignette || 0;
    document.getElementById('sp-vignette-num').value        = (fx.vignette || 0).toFixed(2);
    document.getElementById('sp-grain').value               = fx.grain || 0;
    document.getElementById('sp-grain-num').value           = (fx.grain || 0).toFixed(2);
}

// Hide ALL side panel views at once — call before showing any specific view
function hideAllViews() {
    document.getElementById('sp-menu-view').classList.add('hidden');
    document.getElementById('sp-world-view').classList.add('hidden');
    document.getElementById('sp-interp-view').classList.add('hidden');
    document.getElementById('sp-record-view').classList.add('hidden');
    document.getElementById('sp-rec-props-view').classList.add('hidden');
    document.getElementById('sp-text-view').classList.add('hidden');
    document.getElementById('sp-scene-view').classList.add('hidden');
    document.getElementById('sp-scene-props-view').classList.add('hidden');
    document.getElementById('sp-props').classList.add('hidden');
    document.getElementById('sp-footer').classList.add('hidden');
    document.getElementById('sp-back-btn').classList.add('hidden');
    document.getElementById('sp-delete-btn').classList.add('hidden');
    document.getElementById('sp-delete-clip-btn').classList.add('hidden');
    document.getElementById('sp-pos-btn').classList.add('hidden');
}

function showSidePanel(kf) {
    hideAllViews();
    const idx = State.keyframes.indexOf(kf) + 1;
    document.getElementById('sp-title').textContent = t('ui.title_keyframe', { idx: idx, frame: kf.frame });
    document.getElementById('sp-props').classList.remove('hidden');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
    document.getElementById('sp-delete-btn').classList.remove('hidden');
    document.getElementById('sp-pos-btn').classList.remove('hidden');
    document.getElementById('sp-pos-btn').disabled = false;
}

function hideSidePanel() {
    State.selectedKfId = null;
    State.editingClipId = null;
    State.selectedSceneId = null;
    if (State.vehicleRecSelected) deselectVehicleRec();
    deselectClip();
    hideAllViews();
    document.getElementById('sp-title').textContent = t('ui.title_no_keyframe_selected');
    document.getElementById('sp-menu-view').classList.remove('hidden');
}

// ── TIMELINE RENDERING ────────────────────────────────────────────────────────
// CAMERA track holds all keyframes; position/rotation/fov merged into single CAMERA track.
const TRACKS = ['camera', 'fx'];

function frameToPixel(f) { return f * State.zoom; }
function pixelToFrame(px) { return Math.round(px / State.zoom); }
function getTimelineWidth() {
    const wrap = document.getElementById('timeline-scroll-wrap');
    return Math.max(frameToPixel(totalFrames()) + 200, wrap ? wrap.clientWidth : 800);
}

function renderTimeline() {
    const width = getTimelineWidth();

    // Ruler
    const canvas = document.getElementById('ruler-canvas');
    canvas.width = width;
    drawRuler(canvas.getContext('2d'), width);

    // Track widths
    document.getElementById('tracks-container').style.width = width + 'px';

    TRACKS.forEach(trackId => {
        const track = document.getElementById(`track-${trackId}`);
        track.style.width = width + 'px';
        track.querySelectorAll('.keyframe-marker, .kf-connector').forEach(el => el.remove());

        const kfs = State.keyframes;

        // Connectors
        for (let i = 0; i < kfs.length - 1; i++) {
            const x1 = frameToPixel(kfs[i].frame);
            const x2 = frameToPixel(kfs[i+1].frame);
            const line = document.createElement('div');
            line.className = 'kf-connector';
            line.style.left  = x1 + 'px';
            line.style.width = (x2 - x1) + 'px';
            track.appendChild(line);
        }

        // Diamonds
        kfs.forEach(kf => {
            const m = document.createElement('div');
            m.className   = 'keyframe-marker' + (kf.id === State.selectedKfId ? ' selected' : '');
            m.style.left  = frameToPixel(kf.frame) + 'px';
            m.dataset.kfId = kf.id;

            m.addEventListener('click',     (e) => { e.stopPropagation(); selectKeyframe(kf.id); });
            m.addEventListener('mousedown', (e) => { e.stopPropagation(); startDrag(e, kf.id); });
            track.appendChild(m);
        });
    });

    // In/Out point markers
    const tc = document.getElementById('tracks-container');
    tc.querySelectorAll('.io-marker, .io-shade').forEach(el => el.remove());
    if (State.inPoint != null || State.outPoint != null) {
        const inX  = State.inPoint  != null ? frameToPixel(State.inPoint)  : 0;
        const outX = State.outPoint != null ? frameToPixel(State.outPoint) : width;
        // Shaded regions outside in/out
        if (State.inPoint != null && inX > 0) {
            const s = document.createElement('div'); s.className = 'io-shade';
            s.style.cssText = `left:0;width:${inX}px`; tc.appendChild(s);
        }
        if (State.outPoint != null && outX < width) {
            const s = document.createElement('div'); s.className = 'io-shade';
            s.style.cssText = `left:${outX}px;width:${width - outX}px`; tc.appendChild(s);
        }
        // Marker lines
        if (State.inPoint != null) {
            const m = document.createElement('div'); m.className = 'io-marker io-in';
            m.style.left = inX + 'px'; tc.appendChild(m);
        }
        if (State.outPoint != null) {
            const m = document.createElement('div'); m.className = 'io-marker io-out';
            m.style.left = outX + 'px'; tc.appendChild(m);
        }
    }

    updatePlayheadPosition();
    renderTextTrack(width);
    renderVehicleTrack(width);
    renderOverlayTracks(width);
    updateZoomBar();
}

function renderVehicleTrack(width) {
    const track = document.getElementById('track-vehicle');
    if (!track) return;
    track.style.width = width + 'px';
    track.querySelectorAll('.veh-rec-bar, .veh-rec-label, .veh-rec-loading').forEach(el => el.remove());

    // Show loading placeholder while recording data is arriving. vehicleRecStart
    // and vehicleRecEnd are restored from project meta before the latent event
    // carrying the frame payload arrives, so we can size the loader to the same
    // footprint the finished bar will occupy instead of spanning the whole track.
    if (State.recLoading && !State.vehicleRecording) {
        const loader = document.createElement('div');
        loader.className = 'veh-rec-loading';
        const start    = State.vehicleRecStart || 0;
        const end      = State.vehicleRecEnd   || 0;
        const barWidth = Math.max(8, frameToPixel(end - start));
        loader.style.left  = frameToPixel(start) + 'px';
        loader.style.right = 'auto';
        loader.style.width = barWidth + 'px';
        loader.innerHTML = '<span class="veh-rec-loading-label">Loading recording...</span>';
        track.appendChild(loader);
        return;
    }

    if (!State.vehicleRecording) return;

    const x        = frameToPixel(State.vehicleRecStart);
    const barWidth = Math.max(8, frameToPixel(State.vehicleRecEnd - State.vehicleRecStart));

    const bar = document.createElement('div');
    bar.className = 'veh-rec-bar' + (State.vehicleRecSelected ? ' selected' : '');
    bar.style.left  = x + 'px';
    bar.style.width = barWidth + 'px';

    // Left resize handle
    const hl = document.createElement('div');
    hl.className = 'veh-rec-handle-l';
    hl.addEventListener('mousedown', (e) => { e.stopPropagation(); startVehicleRecDrag(e, 'resizeL'); });
    bar.appendChild(hl);

    // Label
    const label = document.createElement('span');
    label.className = 'veh-rec-label';
    const vc = State.vehicleRecording.count    || 0;
    const pc = State.vehicleRecording.pedCount || 0;
    const shownDur = ((State.vehicleRecEnd - State.vehicleRecStart) / State.fps).toFixed(1);
    let labelKey;
    if (vc > 0 && pc > 0) labelKey = 'ui.veh_ped_rec_label';
    else if (vc > 0)      labelKey = 'ui.veh_rec_label';
    else                  labelKey = 'ui.ped_rec_label';
    label.textContent = t(labelKey, { count: vc || pc, vehicles: vc, peds: pc, duration: shownDur });
    bar.appendChild(label);

    // Right resize handle
    const hr = document.createElement('div');
    hr.className = 'veh-rec-handle-r';
    hr.addEventListener('mousedown', (e) => { e.stopPropagation(); startVehicleRecDrag(e, 'resizeR'); });
    bar.appendChild(hr);

    bar.addEventListener('mousedown', (e) => {
        if (e.target === hl || e.target === hr) return;
        e.stopPropagation();
        selectVehicleRec();
        startVehicleRecDrag(e, 'move');
    });

    track.appendChild(bar);
}

function selectVehicleRec() {
    // Deselect any keyframe or text clip first
    if (State.selectedKfId !== null || State.selectedClipId !== null) {
        State.selectedKfId   = null;
        State.selectedClipId = null;
        State.editingClipId  = null;
    }
    State.vehicleRecSelected = true;

    // Show recording properties panel
    hideAllViews();
    document.getElementById('sp-rec-props-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('ui.title_recording');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');

    // Populate info
    if (State.vehicleRecording) {
        document.getElementById('rp-duration').textContent = State.vehicleRecording.duration.toFixed(1) + 's';
    }
    const vehCount = State.recEntityList ? State.recEntityList.filter(e => e.type === 'vehicle').length : 0;
    const pedCount = State.recEntityList ? State.recEntityList.filter(e => e.type === 'ped').length : 0;
    document.getElementById('rp-veh-count').textContent = vehCount;
    document.getElementById('rp-ped-count').textContent = pedCount;
    document.getElementById('rp-motionblur').checked = false;

    renderRecEntityList();
    renderVehicleTrack(getTimelineWidth());
    renderTimeline();
}

function deselectVehicleRec() {
    if (!State.vehicleRecSelected) return;
    State.vehicleRecSelected = false;
    renderVehicleTrack(getTimelineWidth());
}

function startVehicleRecDrag(e, type) {
    if (!State.vehicleRecording) return;
    e.preventDefault();

    State.draggingVehRec = {
        type,
        startX:      e.clientX,
        origStart:   State.vehicleRecStart,
        origEnd:     State.vehicleRecEnd,
        origTrimIn:  State.vehicleRecTrimIn,
    };

    const totalRec = State.vehicleRecording.totalFrames; // max frames in the recording

    const onMove = (ev) => {
        const dv = State.draggingVehRec;
        if (!dv) return;

        const dx = ev.clientX - dv.startX;
        const df = Math.round(dx / State.zoom);
        const total = totalFrames();

        if (dv.type === 'move') {
            // Shift entire block — trimIn stays the same (same portion of recording)
            const dur      = dv.origEnd - dv.origStart;
            const newStart = Math.max(0, Math.min(total - dur, dv.origStart + df));
            State.vehicleRecStart  = newStart;
            State.vehicleRecEnd    = newStart + dur;
            State.vehicleRecTrimIn = dv.origTrimIn; // unchanged
        } else if (dv.type === 'resizeL') {
            // Trim front: start + trimIn both advance by the same delta.
            // Min delta: -origTrimIn          (can't go before recording start)
            // Max delta: origEnd-origStart-1  (must keep at least 1 frame visible)
            //            also capped so trimIn never exceeds totalRec-1
            const maxDf = Math.min(
                dv.origEnd - dv.origStart - 1,   // keep ≥1 frame
                totalRec - 1 - dv.origTrimIn      // can't push trimIn past recording end
            );
            const clampedDf = Math.max(-dv.origTrimIn, Math.min(maxDf, df));
            State.vehicleRecStart  = Math.max(0, dv.origStart + clampedDf);
            State.vehicleRecTrimIn = Math.max(0, dv.origTrimIn + clampedDf);
        } else if (dv.type === 'resizeR') {
            // Trim end: end moves left — trimIn stays the same, duration shrinks
            // Constraint: can't expand past (totalRec - trimIn) frames, must keep at least 1 frame
            const maxEnd = dv.origStart + (totalRec - dv.origTrimIn);
            const newEnd = Math.max(dv.origStart + 1, Math.min(Math.min(total, maxEnd), dv.origEnd + df));
            State.vehicleRecEnd    = newEnd;
            State.vehicleRecTrimIn = dv.origTrimIn; // unchanged
        }

        renderVehicleTrack(getTimelineWidth());
    };

    const onUp = () => {
        State.draggingVehRec = null;
        post('setVehicleRecTiming', {
            startFrame:  State.vehicleRecStart,
            endFrame:    State.vehicleRecEnd,
            trimInFrame: State.vehicleRecTrimIn,
        });
        renderVehicleTrack(getTimelineWidth());
        window.removeEventListener('mousemove', onMove);
        window.removeEventListener('mouseup', onUp);
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
}

// ── OVERLAY LAYERS ───────────────────────────────────────────────────────────

function onOverlayLayersLoaded(d) {
    State.overlayLayers = (d.layers || []).map(l => ({
        id:          l.id,
        name:        l.name,
        model:       l.model,
        duration:    l.duration,
        totalFrames: l.totalFrames,
        startFrame:  l.startFrame  !== undefined ? l.startFrame  : 0,
        endFrame:    l.endFrame    !== undefined ? l.endFrame    : l.totalFrames,
        trimInFrame: l.trimInFrame !== undefined ? l.trimInFrame : 0,
    }));

    // Auto-extend timeline if any overlay goes past current duration
    for (const ol of State.overlayLayers) {
        const endSec = Math.ceil(ol.endFrame / State.fps);
        if (endSec > State.durationSec) {
            State.durationSec = endSec;
            document.getElementById('duration-input').value = endSec;
            syncKeyframesToLua();
        }
    }

    renderTimeline();
    if (State.overlayLayers.length > 0) {
        showToast(`${State.overlayLayers.length} overlay layer(s) loaded`);
    }
}

CC.startSoloRecord = function() {
    post('startSoloRecord');
};

CC.deleteOverlayLayer = function(layerIdx) {
    post('deleteOverlayLayer', { layerIdx });
    State.overlayLayers.splice(layerIdx - 1, 1);
    // Re-index
    State.overlayLayers.forEach((l, i) => { l.id = i + 1; });
    State.selectedOverlayId = null;
    renderTimeline();
};

function renderOverlayTracks(width) {
    // Remove old overlay tracks and labels
    document.querySelectorAll('.track-overlay').forEach(el => el.remove());
    document.querySelectorAll('.track-label-overlay').forEach(el => el.remove());

    if (State.overlayLayers.length === 0) return;

    const tracksContainer = document.getElementById('tracks-container');
    const labelsContainer = document.getElementById('track-labels');

    State.overlayLayers.forEach((layer, idx) => {
        const layerIdx = idx + 1; // 1-based to match Lua

        // Add track label
        const label = document.createElement('div');
        label.className = 'track-label track-label-overlay';
        label.innerHTML = `<span style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${layer.name}</span>` +
            `<span class="overlay-delete-btn" onclick="CC.deleteOverlayLayer(${layerIdx})" title="Delete layer">&times;</span>`;
        labelsContainer.appendChild(label);

        // Add track
        const track = document.createElement('div');
        track.className = 'track track-overlay';
        track.style.width = width + 'px';
        tracksContainer.appendChild(track);

        // Loading placeholder — same striped animation used on the main vehicle track.
        if (layer.loading) {
            const loader = document.createElement('div');
            loader.className = 'veh-rec-loading';
            loader.style.left  = frameToPixel(layer.startFrame) + 'px';
            loader.style.right = 'auto';
            loader.style.width = Math.max(8, frameToPixel((layer.endFrame || layer.startFrame + State.fps) - layer.startFrame)) + 'px';
            loader.innerHTML = '<span class="veh-rec-loading-label">Loading layer...</span>';
            track.appendChild(loader);
            return;
        }

        // Render the block
        const x        = frameToPixel(layer.startFrame);
        const barWidth = Math.max(8, frameToPixel(layer.endFrame - layer.startFrame));

        const bar = document.createElement('div');
        bar.className = 'overlay-rec-bar' + (State.selectedOverlayId === layer.id ? ' selected' : '');
        bar.style.left  = x + 'px';
        bar.style.width = barWidth + 'px';

        // Left resize handle
        const hl = document.createElement('div');
        hl.className = 'overlay-rec-handle-l';
        hl.addEventListener('mousedown', (e) => { e.stopPropagation(); startOverlayDrag(e, layerIdx, 'resizeL'); });
        bar.appendChild(hl);

        // Label
        const lbl = document.createElement('span');
        lbl.className = 'overlay-rec-label';
        const shownDur = ((layer.endFrame - layer.startFrame) / State.fps).toFixed(1);
        lbl.textContent = `${layer.model} · ${shownDur}s`;
        bar.appendChild(lbl);

        // Right resize handle
        const hr = document.createElement('div');
        hr.className = 'overlay-rec-handle-r';
        hr.addEventListener('mousedown', (e) => { e.stopPropagation(); startOverlayDrag(e, layerIdx, 'resizeR'); });
        bar.appendChild(hr);

        bar.addEventListener('mousedown', (e) => {
            if (e.target === hl || e.target === hr) return;
            e.stopPropagation();
            State.selectedOverlayId = layer.id;
            renderTimeline();
            startOverlayDrag(e, layerIdx, 'move');
        });

        track.appendChild(bar);
    });
}

function startOverlayDrag(e, layerIdx, type) {
    const layer = State.overlayLayers[layerIdx - 1];
    if (!layer) return;
    e.preventDefault();

    State.draggingOverlay = {
        layerIdx,
        type,
        startX:     e.clientX,
        origStart:  layer.startFrame,
        origEnd:    layer.endFrame,
        origTrimIn: layer.trimInFrame,
    };

    const totalRec = layer.totalFrames;

    const onMove = (ev) => {
        const dv = State.draggingOverlay;
        if (!dv) return;
        const dx = ev.clientX - dv.startX;
        const df = Math.round(dx / State.zoom);
        const total = totalFrames();

        if (dv.type === 'move') {
            const dur      = dv.origEnd - dv.origStart;
            const newStart = Math.max(0, Math.min(total - dur, dv.origStart + df));
            layer.startFrame  = newStart;
            layer.endFrame    = newStart + dur;
            layer.trimInFrame = dv.origTrimIn;
        } else if (dv.type === 'resizeL') {
            const maxDf = Math.min(dv.origEnd - dv.origStart - 1, totalRec - 1 - dv.origTrimIn);
            const clampedDf = Math.max(-dv.origTrimIn, Math.min(maxDf, df));
            layer.startFrame  = Math.max(0, dv.origStart + clampedDf);
            layer.trimInFrame = Math.max(0, dv.origTrimIn + clampedDf);
        } else if (dv.type === 'resizeR') {
            const maxEnd = dv.origStart + (totalRec - dv.origTrimIn);
            const newEnd = Math.max(dv.origStart + 1, Math.min(Math.min(total, maxEnd), dv.origEnd + df));
            layer.endFrame    = newEnd;
            layer.trimInFrame = dv.origTrimIn;
        }

        renderTimeline();
    };

    const onUp = () => {
        State.draggingOverlay = null;
        post('setOverlayTiming', {
            layerIdx:    layerIdx,
            startFrame:  layer.startFrame,
            endFrame:    layer.endFrame,
            trimInFrame: layer.trimInFrame,
        });
        autoSaveProject();
        renderTimeline();
        window.removeEventListener('mousemove', onMove);
        window.removeEventListener('mouseup', onUp);
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
}

function renderTextTrack(width) {
    const track = document.getElementById('track-text');
    if (!track) return;
    track.style.width = width + 'px';
    track.querySelectorAll('.text-clip').forEach(el => el.remove());

    State.textClips.forEach(clip => {
        const textObj  = State.textObjects.find(o => o.id === clip.textId);
        const label    = textObj ? textObj.text : t('text3d.default_label', { id: clip.textId });
        const x        = frameToPixel(clip.startFrame);
        const clipWidth = Math.max(8, frameToPixel(clip.endFrame - clip.startFrame));

        const el = document.createElement('div');
        el.className = 'text-clip' + (clip.id === State.selectedClipId ? ' selected' : '');
        el.style.left  = x + 'px';
        el.style.width = clipWidth + 'px';
        el.dataset.clipId = clip.id;

        // Left resize handle
        const hl = document.createElement('div');
        hl.className = 'text-clip-handle-l';
        hl.addEventListener('mousedown', (e) => { e.stopPropagation(); startClipDrag(e, clip.id, 'resizeL'); });
        el.appendChild(hl);

        // Label
        const lbl = document.createElement('span');
        lbl.className = 'text-clip-label';
        lbl.textContent = label;
        el.appendChild(lbl);

        // Right resize handle
        const hr = document.createElement('div');
        hr.className = 'text-clip-handle-r';
        hr.addEventListener('mousedown', (e) => { e.stopPropagation(); startClipDrag(e, clip.id, 'resizeR'); });
        el.appendChild(hr);

        el.addEventListener('mousedown', (e) => {
            if (e.target === hl || e.target === hr) return;
            e.stopPropagation();
            selectClip(clip.id);
            startClipDrag(e, clip.id, 'move');
        });

        track.appendChild(el);
    });
}

function startClipDrag(e, clipId, type) {
    const clip = State.textClips.find(c => c.id === clipId);
    if (!clip) return;
    e.preventDefault();

    State.draggingClip = {
        clipId,
        type,
        startX:    e.clientX,
        origStart: clip.startFrame,
        origEnd:   clip.endFrame,
    };

    const onMove = (ev) => {
        const dc = State.draggingClip;
        if (!dc) return;
        const c = State.textClips.find(c => c.id === dc.clipId);
        if (!c) return;

        const dx = ev.clientX - dc.startX;
        const df = Math.round(dx / State.zoom);
        const total = totalFrames();

        if (dc.type === 'move') {
            const dur = dc.origEnd - dc.origStart;
            const newStart = Math.max(0, Math.min(total - dur, dc.origStart + df));
            c.startFrame = newStart;
            c.endFrame   = newStart + dur;
        } else if (dc.type === 'resizeL') {
            c.startFrame = Math.max(0, Math.min(dc.origEnd - 1, dc.origStart + df));
        } else if (dc.type === 'resizeR') {
            c.endFrame = Math.max(dc.origStart + 1, Math.min(total, dc.origEnd + df));
        }
        renderTextTrack(getTimelineWidth());
    };

    const onUp = () => {
        State.draggingClip = null;
        syncTextToLua();
        renderTextTrack(getTimelineWidth());
        window.removeEventListener('mousemove', onMove);
        window.removeEventListener('mouseup', onUp);
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
}

function selectClip(clipId) {
    if (State.selectedKfId !== null) { State.selectedKfId = null; renderTimeline(); }
    if (State.vehicleRecSelected) deselectVehicleRec();
    State.selectedClipId = clipId;
    State.editingClipId  = clipId;
    const clip    = State.textClips.find(c => c.id === clipId);
    const textObj = clip ? State.textObjects.find(o => o.id === clip.textId) : null;

    // Show text panel in edit mode
    document.getElementById('sp-menu-view').classList.add('hidden');
    document.getElementById('sp-world-view').classList.add('hidden');
    document.getElementById('sp-interp-view').classList.add('hidden');
    document.getElementById('sp-record-view').classList.add('hidden');
    document.getElementById('sp-props').classList.add('hidden');
    document.getElementById('sp-text-view').classList.remove('hidden');
    document.getElementById('tv-create-mode').classList.add('hidden');
    document.getElementById('tv-edit-mode').classList.remove('hidden');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
    document.getElementById('sp-delete-btn').classList.add('hidden');
    document.getElementById('sp-delete-clip-btn').classList.remove('hidden');
    document.getElementById('sp-pos-btn').classList.add('hidden');
    document.getElementById('sp-title').textContent = t('text3d.title_edit');

    // Populate form from textObj
    if (textObj) {
        document.getElementById('tv-text').value      = textObj.text || '';
        document.getElementById('tv-font').value      = textObj.font || 'Arial';
        document.getElementById('tv-color').value     = textObj.color || '#ffffff';
        document.getElementById('tv-size').value      = textObj.size || 4;
        document.getElementById('tv-anim').value      = textObj.animation || 'fadeSlide';
        document.getElementById('tv-anim-in').value   = textObj.animIn  || 15;
        document.getElementById('tv-anim-out').value  = textObj.animOut || 15;
        State.shadowEnabled = !!textObj.shadow;
        const sBtn = document.getElementById('tv-shadow-btn');
        sBtn.textContent = State.shadowEnabled ? t('ui.on') : t('ui.off');
        sBtn.classList.toggle('active', State.shadowEnabled);
        State.glowEnabled = !!textObj.glow;
        const gBtn = document.getElementById('tv-glow-btn');
        gBtn.textContent = State.glowEnabled ? t('ui.on') : t('ui.off');
        gBtn.classList.toggle('active', State.glowEnabled);

        State.outlineEnabled = !!textObj.outline;
        const oBtn = document.getElementById('tv-outline-btn');
        if (oBtn) {
            oBtn.textContent = State.outlineEnabled ? t('ui.on') : t('ui.off');
            oBtn.classList.toggle('active', State.outlineEnabled);
        }
        document.getElementById('tv-outline-color').value = textObj.outlineColor || '#000000';
        document.getElementById('tv-outline-width').value = textObj.outlineWidth || 2;

        State.colorShiftEnabled = !!textObj.colorShift;
        const cBtn = document.getElementById('tv-chroma-btn');
        if (cBtn) {
            cBtn.textContent = State.colorShiftEnabled ? t('ui.on') : t('ui.off');
            cBtn.classList.toggle('active', State.colorShiftEnabled);
        }
        State.colorShiftAdvanced = !!textObj.colorShiftAdvanced;
        const cAdv = document.getElementById('tv-chroma-adv-btn');
        if (cAdv) {
            cAdv.textContent = State.colorShiftAdvanced ? t('ui.on') : t('ui.off');
            cAdv.classList.toggle('active', State.colorShiftAdvanced);
        }
        document.getElementById('tv-chroma-adv-row').classList.toggle('hidden', !State.colorShiftAdvanced);
        document.getElementById('tv-chroma-colors').value = textObj.colorShiftColors || '';
        document.getElementById('tv-chroma-speed').value  = textObj.colorShiftSpeed  || 60;
    }
    if (clip) {
        document.getElementById('tc-start').value = clip.startFrame;
        document.getElementById('tc-end').value   = clip.endFrame;
    }
    renderTextTrack(getTimelineWidth());
}

function deselectClip() {
    State.selectedClipId = null;
    document.getElementById('sp-delete-clip-btn').classList.add('hidden');
    renderTextTrack(getTimelineWidth());
}

function syncTextToLua() {
    post('setTextData', {
        textObjects: State.textObjects,
        textClips:   State.textClips,
    });
}

// Text objects are visible as clips on the 3D TEXT track — no separate list panel needed
function renderTextObjectsList() {}

// ── TEXT PLACEMENT HANDLERS ───────────────────────────────────────────────────
function onTextPlacementOverlay(active) {
    State.isTextPlacing = active;
    if (active) {
        PlacementGuide.show('text');
        document.getElementById('side-panel').classList.add('dimmed');
    } else {
        PlacementGuide.hide();
        document.getElementById('side-panel').classList.remove('dimmed');
    }
}

function onTextPlacementDone(d) {
    onTextPlacementOverlay(false);
    if (!d || !d.coords) {
        // Cancelled — if editing an existing clip, just update its coords to nothing (keep clip)
        return;
    }

    const text    = document.getElementById('tv-text').value.trim() || t('text3d.default_text');
    const font    = document.getElementById('tv-font').value;
    const color   = document.getElementById('tv-color').value;
    const size    = parseFloat(document.getElementById('tv-size').value) || 4.0;
    const anim    = document.getElementById('tv-anim').value;
    const animIn  = parseInt(document.getElementById('tv-anim-in').value)  || 15;
    const animOut = parseInt(document.getElementById('tv-anim-out').value) || 15;

    if (State.editingClipId !== null) {
        // Re-placing an existing clip — update its textObject's coords
        const clip = State.textClips.find(c => c.id === State.editingClipId);
        const obj  = clip ? State.textObjects.find(o => o.id === clip.textId) : null;
        if (obj) { obj.coords = d.coords; syncTextToLua(); showToast(t('toasts.position_updated')); }
        return;
    }

    // New placement — create textObject + clip together
    const objId = State.nextTextId++;
    const obj = { id: objId, text, font, color, size, shadow: State.shadowEnabled, glow: State.glowEnabled,
                  outline:          State.outlineEnabled,
                  outlineColor:     document.getElementById('tv-outline-color').value || '#000000',
                  outlineWidth:     parseInt(document.getElementById('tv-outline-width').value) || 2,
                  colorShift:         State.colorShiftEnabled,
                  colorShiftAdvanced: State.colorShiftAdvanced,
                  colorShiftColors:   State.colorShiftAdvanced ? (document.getElementById('tv-chroma-colors').value || '') : '',
                  colorShiftSpeed:    parseInt(document.getElementById('tv-chroma-speed').value) || 60,
                  animation: anim, animIn, animOut, coords: d.coords };
    const clip = { id: State.nextTextClipId++, textId: objId,
                   startFrame: State.currentFrame,
                   endFrame:   Math.min(totalFrames(), State.currentFrame + 60) };
    State.textObjects.push(obj);
    State.textClips.push(clip);
    syncTextToLua();
    renderTimeline();
    showToast(t('toasts.text_added_to_timeline', { text: text.substring(0,20) }));
}

function deleteTextObject(textId) {
    State.textObjects = State.textObjects.filter(o => o.id !== textId);
    State.textClips   = State.textClips.filter(c => c.textId !== textId);
    if (State.selectedClipId !== null) {
        const stillExists = State.textClips.find(c => c.id === State.selectedClipId);
        if (!stillExists) { deselectClip(); CC.backToMenu(); }
    }
    syncTextToLua();
    renderTextObjectsList();
    renderTimeline();
    showToast(t('toasts.text_object_deleted'));
}

function drawRuler(ctx, width) {
    const h   = 22;
    ctx.clearRect(0, 0, width, h);
    ctx.fillStyle = 'rgba(48,48,48,0.98)';
    ctx.fillRect(0, 0, width, h);

    const fps   = State.fps;
    const total = totalFrames();

    // Pick a major interval (in frames) so labels are at least 65px apart
    const minLabelPx = 65;
    // Candidate step sizes in seconds, from fine to coarse
    const stepsSec = [0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300];
    const stepSec  = stepsSec.find(s => s * State.zoom * fps >= minLabelPx) || 300;
    const majorInterval = Math.round(stepSec * fps);
    const minorInterval = Math.max(1, Math.round(majorInterval / 5));

    ctx.font      = '9px Segoe UI, sans-serif';
    ctx.textAlign = 'center';

    for (let f = 0; f <= total + majorInterval; f += minorInterval) {
        const x = frameToPixel(f);
        if (x > width) break;
        const isMajor = (f % majorInterval === 0);
        ctx.beginPath();
        ctx.strokeStyle = isMajor ? 'rgba(150,150,150,0.6)' : 'rgba(70,70,70,0.5)';
        ctx.moveTo(x, isMajor ? 0 : 12);
        ctx.lineTo(x, h);
        ctx.stroke();
        if (isMajor) {
            const sec = f / fps;
            const mm  = Math.floor(sec / 60);
            const ss  = Math.floor(sec % 60);
            ctx.fillStyle = '#999';
            ctx.fillText(
                `${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`,
                x, 9
            );
        }
    }
}

function updatePlayheadPosition() {
    const x    = frameToPixel(State.currentFrame);
    const ph   = document.getElementById('playhead');
    const wrap = document.getElementById('timeline-scroll-wrap');
    ph.style.left = x + 'px';
    // Auto-scroll
    if (wrap) {
        const pw = wrap.clientWidth;
        if (x < wrap.scrollLeft + 40 || x > wrap.scrollLeft + pw - 40) {
            wrap.scrollLeft = Math.max(0, x - pw / 2);
        }
    }
}

// Ruler click → move playhead
document.getElementById('ruler-canvas').addEventListener('mousedown', (e) => {
    seekTo(e);
    const onMove = (ev) => seekTo(ev);
    const onUp   = () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
});

function seekTo(e) {
    const rect = document.getElementById('ruler-canvas').getBoundingClientRect();
    const px   = e.clientX - rect.left;
    const frame = Math.max(0, Math.min(totalFrames(), pixelToFrame(px)));
    State.currentFrame = frame;
    document.getElementById('frame-input').value = frame;
    updatePlayheadPosition();
    updateTimecodeDisplay();
    post('jumpToFrame', { frame });
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive() && frame > 15) Tutorial.fire('tut:scrubbed');
}

// Scroll wheel zoom on timeline
document.getElementById('timeline-scroll-wrap').addEventListener('wheel', (e) => {
    if (e.ctrlKey || e.altKey) {
        e.preventDefault();
        State.zoom = Math.max(0.3, Math.min(20, State.zoom * (e.deltaY > 0 ? 0.87 : 1.15)));
        renderTimeline();
    }
}, { passive: false });

// Keep zoom bar in sync when user drags the native-less scroll
document.getElementById('timeline-scroll-wrap').addEventListener('scroll', updateZoomBar);

// ── PREMIERE-STYLE ZOOM / SCROLL BAR ─────────────────────────────────────────
function updateZoomBar() {
    const wrap  = document.getElementById('timeline-scroll-wrap');
    const bar   = document.getElementById('timeline-zoom-bar');
    const thumb = document.getElementById('tzb-thumb');
    if (!wrap || !bar || !thumb) return;

    const barW   = bar.clientWidth;
    const total  = totalFrames();
    const zoom   = State.zoom;
    if (total <= 0 || barW <= 0) return;

    const leftFrame  = wrap.scrollLeft / zoom;
    const rightFrame = (wrap.scrollLeft + wrap.clientWidth) / zoom;

    const tl = Math.max(0, (leftFrame  / total) * barW);
    const tr = Math.min(barW, (rightFrame / total) * barW);
    const tw = Math.max(24, tr - tl);

    thumb.style.left  = tl + 'px';
    thumb.style.width = tw + 'px';
}

(function initZoomBar() {
    const bar    = document.getElementById('timeline-zoom-bar');
    const thumb  = document.getElementById('tzb-thumb');
    const handleL = document.getElementById('tzb-handle-l');
    const handleR = document.getElementById('tzb-handle-r');

    const MIN_ZOOM           = 0.15;
    const MAX_ZOOM           = 20;
    const MIN_VISIBLE_FRAMES = 10;

    bar.addEventListener('mousedown', (e) => {
        e.preventDefault();
        const wrap  = document.getElementById('timeline-scroll-wrap');
        const barW  = bar.clientWidth;
        const total = totalFrames();

        const origScrollL  = wrap.scrollLeft;
        const origZoom     = State.zoom;
        const origLeftF    = origScrollL / origZoom;
        const origRightF   = (origScrollL + wrap.clientWidth) / origZoom;

        let type;
        if (e.target === handleL)                           type = 'zoomL';
        else if (e.target === handleR)                      type = 'zoomR';
        else if (e.target === thumb || thumb.contains(e.target)) type = 'pan';
        else {
            // Click on empty bar area — center view on that position
            const frac        = (e.clientX - bar.getBoundingClientRect().left) / barW;
            const targetFrame = frac * total;
            wrap.scrollLeft   = Math.max(0, targetFrame * State.zoom - wrap.clientWidth / 2);
            updateZoomBar();
            return;
        }

        const startX = e.clientX;

        const onMove = (ev) => {
            const dx    = ev.clientX - startX;
            const dFrac = dx / barW;           // fraction of total timeline moved
            const dFrame = dFrac * total;      // equivalent frame delta

            if (type === 'pan') {
                // Map zoom-bar pixels → scroll-wrap pixels proportionally
                const timelineW = total * origZoom;
                wrap.scrollLeft = Math.max(0, origScrollL + dx * (timelineW / barW));
                updateZoomBar();

            } else if (type === 'zoomL') {
                // Left handle: right frame is anchored, left frame moves
                const newLeftF     = origLeftF + dFrame;
                const newVisibleF  = Math.max(MIN_VISIBLE_FRAMES, origRightF - newLeftF);
                const newZoom      = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, wrap.clientWidth / newVisibleF));
                State.zoom         = newZoom;
                // Anchor right frame: scroll so origRightF stays at the right edge
                wrap.scrollLeft    = Math.max(0, origRightF * newZoom - wrap.clientWidth);
                renderTimeline();

            } else if (type === 'zoomR') {
                // Right handle: left frame is anchored, right frame moves
                const newRightF    = origRightF + dFrame;
                const newVisibleF  = Math.max(MIN_VISIBLE_FRAMES, newRightF - origLeftF);
                const newZoom      = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, wrap.clientWidth / newVisibleF));
                State.zoom         = newZoom;
                // Anchor left frame: scroll so origLeftF stays at the left edge
                wrap.scrollLeft    = Math.max(0, origLeftF * newZoom);
                renderTimeline();
            }
        };

        const onUp = () => {
            window.removeEventListener('mousemove', onMove);
            window.removeEventListener('mouseup', onUp);
        };

        window.addEventListener('mousemove', onMove);
        window.addEventListener('mouseup', onUp);
    });

    // Double-click zoom bar to fit entire timeline in view
    bar.addEventListener('dblclick', () => {
        const wrap  = document.getElementById('timeline-scroll-wrap');
        const total = totalFrames();
        if (total <= 0) return;
        State.zoom  = Math.max(0.15, (wrap.clientWidth - 20) / total);
        wrap.scrollLeft = 0;
        renderTimeline();
        showToast(t('toasts.timeline_fit_to_view'));
    });
})();

// ── CLICK EMPTY TRACK → DESELECT ─────────────────────────────────────────────
document.getElementById('tracks-container').addEventListener('mousedown', (e) => {
    if (e.target === e.currentTarget || e.target.classList.contains('track')) {
        if (State.selectedKfId !== null || State.vehicleRecSelected || State.selectedClipId !== null) {
            State.selectedKfId      = null;
            State.vehicleRecSelected = false;
            State.selectedClipId    = null;
            State.editingClipId     = null;
            hideSidePanel();
            renderTimeline();
        }
    }
});

// ── RULER HOVER TOOLTIP ───────────────────────────────────────────────────────
(function initRulerTooltip() {
    const tip = document.createElement('div');
    Object.assign(tip.style, {
        position: 'fixed', display: 'none',
        background: 'rgba(20,20,20,0.92)', color: '#aaa',
        fontSize: '10px', fontFamily: "'Consolas', monospace",
        padding: '3px 8px', borderRadius: '3px',
        border: '1px solid #444', pointerEvents: 'none', zIndex: '999',
    });
    document.body.appendChild(tip);
    const ruler = document.getElementById('ruler-canvas');
    ruler.addEventListener('mousemove', (e) => {
        const rect = ruler.getBoundingClientRect();
        const f    = Math.max(0, Math.min(totalFrames(), pixelToFrame(e.clientX - rect.left)));
        const sec  = Math.floor(f / State.fps);
        tip.textContent = `${pad(Math.floor(sec/60))}:${pad(sec%60)}:${pad(f%State.fps)}  f${f}`;
        tip.style.display = 'block';
        tip.style.left = (e.clientX + 14) + 'px';
        tip.style.top  = (e.clientY + 16) + 'px';
    });
    ruler.addEventListener('mouseleave', () => { tip.style.display = 'none'; });
})();

// ── DRAG ─────────────────────────────────────────────────────────────────────
const DRAG_THRESHOLD = 5; // pixels of movement before it counts as a drag

function startDrag(e, kfId) {
    pushUndo();
    const startX = e.clientX;
    const kf     = State.keyframes.find(k => k.id === kfId);
    State.dragStartFrame = kf ? kf.frame : 0;
    State.draggingKfId   = kfId;
    let isDragging = false;

    const onMove = (ev) => {
        const dx = ev.clientX - startX;
        if (!isDragging && Math.abs(dx) < DRAG_THRESHOLD) return;
        isDragging = true;
        const df = Math.round(dx / State.zoom);
        let newFrame = Math.max(0, Math.min(totalFrames(), State.dragStartFrame + df));

        // Shift: snap to nearest other keyframe
        if (ev.shiftKey) {
            const others = State.keyframes.filter(k => k.id !== State.draggingKfId).map(k => k.frame);
            const snapR  = Math.max(3, Math.round(8 / State.zoom));
            if (others.length > 0) {
                const near = others.reduce((b, f) => Math.abs(f - newFrame) < Math.abs(b - newFrame) ? f : b);
                if (Math.abs(near - newFrame) <= snapR) newFrame = near;
            }
        }

        const kf = State.keyframes.find(k => k.id === State.draggingKfId);
        if (kf) {
            kf.frame = newFrame;
            renderTimeline();
        }
    };

    const onUp = () => {
        // Only re-render if we actually dragged — otherwise let the click event fire normally
        if (isDragging) {
            sortKeyframes();
            syncKeyframesToLua();
            renderTimeline();
        }
        State.draggingKfId = null;
        window.removeEventListener('mousemove', onMove);
        window.removeEventListener('mouseup', onUp);
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
}

// ── TRANSPORT ─────────────────────────────────────────────────────────────────
function setFrame(f) {
    f = Math.max(0, Math.min(totalFrames(), f));
    if (State.selectedSceneId !== null && State._entityFocused) {
        post('unfocusEntity');
        State._entityFocused = false;
    }
    State.currentFrame = f;
    document.getElementById('frame-input').value = f;
    updatePlayheadPosition();
    updateTimecodeDisplay();
    post('jumpToFrame', { frame: f });
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive() && f > 15) Tutorial.fire('tut:scrubbed');
}

CC.gotoStart   = () => setFrame(0);
CC.gotoEnd     = () => setFrame(totalFrames());
CC.stepBack    = () => setFrame(State.currentFrame - 1);
CC.stepForward = () => setFrame(State.currentFrame + 1);

CC.togglePlay = function() {
    if (State.isPlaying) {
        CC.stopPlayback();
    } else {
        post('startPlayback', { fromFrame: State.currentFrame, totalFrames: totalFrames() });
    }
};

CC.stopPlayback = function() { post('stopPlayback', {}); };

CC.jumpToFrame = function(f) { setFrame(f); };

CC.setDuration = function(sec) {
    sec = Math.max(1, Math.min(600, sec || 30));
    State.durationSec = sec;
    document.getElementById('duration-input').value = sec;
    renderTimeline();
    syncKeyframesToLua();
};

// ── TIMECODE ──────────────────────────────────────────────────────────────────
function updateTimecodeDisplay() {
    const f   = State.currentFrame;
    const fps = State.fps;
    const sec = Math.floor(f / fps);
    const hh  = Math.floor(sec / 3600);
    const mm  = Math.floor((sec % 3600) / 60);
    const ss  = sec % 60;
    const ff  = f % fps;
    document.getElementById('timecode-display').textContent =
        `${pad(hh)}:${pad(mm)}:${pad(ss)}:${pad(ff)}`;
}
function pad(n) { return String(n).padStart(2, '0'); }

// ── UNDO / REDO ──────────────────────────────────────────────────────────────
State.undoStack = [];
State.redoStack = [];
State.clipboard = null;
State.inPoint   = null;
State.outPoint  = null;

function pushUndo() {
    State.undoStack.push({
        keyframes:   JSON.parse(JSON.stringify(State.keyframes)),
        textObjects: JSON.parse(JSON.stringify(State.textObjects)),
        textClips:   JSON.parse(JSON.stringify(State.textClips)),
    });
    if (State.undoStack.length > 50) State.undoStack.shift();
    State.redoStack = [];
}

CC.undo = function() {
    if (!State.undoStack.length) return;
    State.redoStack.push({
        keyframes:   JSON.parse(JSON.stringify(State.keyframes)),
        textObjects: JSON.parse(JSON.stringify(State.textObjects)),
        textClips:   JSON.parse(JSON.stringify(State.textClips)),
    });
    const snap = State.undoStack.pop();
    State.keyframes   = snap.keyframes;
    State.textObjects = snap.textObjects;
    State.textClips   = snap.textClips;
    State.selectedKfId = null; State.editingClipId = null;
    syncKeyframesToLua(); syncTextToLua(); renderTimeline(); hideSidePanel();
    showToast(t('toasts.undo'));
};

CC.redo = function() {
    if (!State.redoStack.length) return;
    State.undoStack.push({
        keyframes:   JSON.parse(JSON.stringify(State.keyframes)),
        textObjects: JSON.parse(JSON.stringify(State.textObjects)),
        textClips:   JSON.parse(JSON.stringify(State.textClips)),
    });
    const snap = State.redoStack.pop();
    State.keyframes   = snap.keyframes;
    State.textObjects = snap.textObjects;
    State.textClips   = snap.textClips;
    State.selectedKfId = null; State.editingClipId = null;
    syncKeyframesToLua(); syncTextToLua(); renderTimeline(); hideSidePanel();
    showToast(t('toasts.redo'));
};

// ── COPY / PASTE / DUPLICATE ─────────────────────────────────────────────────
CC.copyKeyframe = function() {
    if (State.selectedKfId !== null) {
        const kf = State.keyframes.find(k => k.id === State.selectedKfId);
        if (!kf) return;
        State.clipboard = { type: 'keyframe', data: JSON.parse(JSON.stringify(kf)) };
        showToast(t('toasts.keyframe_copied'));
    } else if (State.editingClipId !== null) {
        const clip = State.textClips.find(c => c.id === State.editingClipId);
        const obj  = clip ? State.textObjects.find(o => o.id === clip.textId) : null;
        if (!clip || !obj) return;
        State.clipboard = {
            type: 'textClip',
            clip: JSON.parse(JSON.stringify(clip)),
            obj:  JSON.parse(JSON.stringify(obj)),
        };
        showToast(t('toasts.text_clip_copied'));
    }
};

CC.pasteKeyframe = function() {
    if (!State.clipboard) { showToast(t('errors.nothing_to_paste'), 'error'); return; }
    pushUndo();
    if (State.clipboard.type === 'keyframe') {
        const kf  = JSON.parse(JSON.stringify(State.clipboard.data));
        kf.id     = State.nextId++;
        kf.frame  = State.currentFrame;
        State.keyframes.push(kf);
        sortKeyframes(); syncKeyframesToLua(); renderTimeline();
        selectKeyframe(kf.id);
        showToast(t('toasts.pasted_at_frame', { frame: kf.frame }));
    } else if (State.clipboard.type === 'textClip') {
        const obj = JSON.parse(JSON.stringify(State.clipboard.obj));
        obj.id    = State.nextTextId++;
        State.textObjects.push(obj);
        const dur  = State.clipboard.clip.endFrame - State.clipboard.clip.startFrame;
        const clip = {
            id:         State.nextTextClipId++,
            textId:     obj.id,
            startFrame: State.currentFrame,
            endFrame:   State.currentFrame + dur,
        };
        State.textClips.push(clip);
        syncTextToLua(); renderTimeline(); renderTextObjectsList();
        selectClip(clip.id);
        showToast(t('toasts.text_pasted_at_frame', { frame: clip.startFrame }));
    }
};

CC.duplicateKeyframe = function() {
    if (State.selectedKfId !== null) {
        const src = State.keyframes.find(k => k.id === State.selectedKfId);
        if (!src) return;
        pushUndo();
        const kf  = JSON.parse(JSON.stringify(src));
        kf.id     = State.nextId++;
        kf.frame  = Math.min(src.frame + 30, totalFrames());
        State.keyframes.push(kf);
        sortKeyframes(); syncKeyframesToLua(); renderTimeline();
        selectKeyframe(kf.id);
        showToast(t('toasts.duplicated_to_frame', { frame: kf.frame }));
    } else if (State.editingClipId !== null) {
        const clip = State.textClips.find(c => c.id === State.editingClipId);
        const obj  = clip ? State.textObjects.find(o => o.id === clip.textId) : null;
        if (!clip || !obj) return;
        pushUndo();
        const newObj = JSON.parse(JSON.stringify(obj));
        newObj.id    = State.nextTextId++;
        State.textObjects.push(newObj);
        const dur     = clip.endFrame - clip.startFrame;
        const newClip = {
            id:         State.nextTextClipId++,
            textId:     newObj.id,
            startFrame: clip.endFrame,
            endFrame:   clip.endFrame + dur,
        };
        State.textClips.push(newClip);
        syncTextToLua(); renderTimeline(); renderTextObjectsList();
        selectClip(newClip.id);
        showToast(t('toasts.text_duplicated'));
    }
};

// ── NUDGE KEYFRAME ───────────────────────────────────────────────────────────
CC.nudgeKeyframe = function(dir) {
    if (State.selectedKfId === null) return;
    const kf = State.keyframes.find(k => k.id === State.selectedKfId);
    if (!kf) return;
    pushUndo();
    kf.frame = Math.max(0, Math.min(totalFrames(), kf.frame + dir));
    sortKeyframes(); syncKeyframesToLua(); renderTimeline();
    setFrame(kf.frame);
};

// ── IN / OUT POINTS ──────────────────────────────────────────────────────────
CC.setInPoint = function() {
    State.inPoint = State.currentFrame;
    renderTimeline();
    showToast(t('toasts.in_point_set', { frame: State.inPoint }));
};

CC.setOutPoint = function() {
    State.outPoint = State.currentFrame;
    renderTimeline();
    showToast(t('toasts.out_point_set', { frame: State.outPoint }));
};

CC.clearInOut = function() {
    State.inPoint = null; State.outPoint = null;
    renderTimeline();
    showToast(t('toasts.in_out_cleared'));
};

// ── KEYBOARD SHORTCUTS ────────────────────────────────────────────────────────
document.addEventListener('keydown', (e) => {
    if (['INPUT','SELECT','TEXTAREA'].includes(e.target.tagName)) return;

    // Ctrl combos
    if (e.ctrlKey || e.metaKey) {
        switch (e.key) {
            case 'z': case 'Z':
                e.preventDefault();
                if (e.shiftKey) CC.redo(); else CC.undo();
                return;
            case 'y': case 'Y': e.preventDefault(); CC.redo();             return;
            case 'c': case 'C': e.preventDefault(); CC.copyKeyframe();     return;
            case 'v': case 'V': e.preventDefault(); CC.pasteKeyframe();    return;
            case 'd': case 'D': e.preventDefault(); CC.duplicateKeyframe();return;
        }
    }

    switch (e.key) {
        case ' ':          e.preventDefault(); CC.togglePlay();    break;
        case 'Home':       CC.gotoStart();                         break;
        case 'End':        CC.gotoEnd();                           break;
        case 'ArrowLeft':
            e.preventDefault();
            if (e.shiftKey) setFrame(Math.max(0, State.currentFrame - 10));
            else CC.stepBack();
            break;
        case 'ArrowRight':
            e.preventDefault();
            if (e.shiftKey) setFrame(Math.min(totalFrames(), State.currentFrame + 10));
            else CC.stepForward();
            break;
        case 'Delete':     CC.deleteSelectedKeyframe();            break;
        case 'Escape':     CC.close();                             break;
        case '+': case '=': State.zoom = Math.min(20, State.zoom*1.2); renderTimeline(); break;
        case '-':           State.zoom = Math.max(0.3, State.zoom/1.2); renderTimeline(); break;
        // J/K/L — Premiere Pro shuttle keys
        case 'j': case 'J': e.preventDefault(); setFrame(Math.max(0, State.currentFrame - 10)); break;
        case 'k': case 'K': e.preventDefault(); if (State.isPlaying) CC.stopPlayback();         break;
        case 'l': case 'L': e.preventDefault(); if (!State.isPlaying) CC.togglePlay();          break;
        // [ / ] — nudge selected keyframe
        case '[': CC.nudgeKeyframe(-1); break;
        case ']': CC.nudgeKeyframe(1);  break;
        // I / O — in/out points
        case 'i': case 'I': CC.setInPoint();  break;
        case 'o': case 'O': CC.setOutPoint(); break;
    }
});

// ── TOAST ─────────────────────────────────────────────────────────────────────
function showToast(msg, type = 'info') {
    const t = document.createElement('div');
    t.textContent = msg;
    Object.assign(t.style, {
        position:   'fixed',
        bottom:     '220px',
        left:       '50%',
        transform:  'translateX(-50%)',
        background: type === 'error' ? '#c62828' : 'rgba(28,28,28,0.95)',
        border:     `1px solid ${type === 'error' ? '#e53935' : 'rgba(74,144,217,0.4)'}`,
        color:      type === 'error' ? '#fff' : '#c8c8c8',
        fontFamily: "'Segoe UI',sans-serif",
        fontSize:   '12px',
        padding:    '7px 16px',
        borderRadius: '4px',
        zIndex:     '9999',
        pointerEvents: 'none',
        animation:  'fadeOut 2.5s forwards',
    });
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 2500);
}

// ── PANEL INPUT WIRING ────────────────────────────────────────────────────────
// All inputs auto-save (and preview) the moment they change — no Apply needed.
(function initPanelInputs() {
    // Continuous inputs: save on every keystroke / slider tick (debounced via autoSavePanel)
    ['sp-pos-x','sp-pos-y','sp-pos-z','sp-rot-x','sp-rot-y','sp-rot-z',
     'sp-fov-num','sp-fov-slider',
     'sp-time-slider','sp-time-num',
     'sp-shake-amp','sp-shake-amp-num',
     'sp-dof-near','sp-dof-far','sp-dof-fnum','sp-dof-fnum-num','sp-dof-str','sp-dof-str-num',
     'sp-blur','sp-blur-num','sp-filter-str','sp-filter-str-num',
     'sp-timescale','sp-timescale-num',
     'sp-fade-amount','sp-fade-amount-num',
     'sp-vignette','sp-vignette-num',
     'sp-grain','sp-grain-num'].forEach(id => {
        document.getElementById(id).addEventListener('input', CC.autoSavePanel);
    });

    // Committed inputs: save when selection/value is finalised
    ['sp-frame','sp-easing','sp-time-enabled','sp-shake-type','sp-dof-enabled','sp-filter-id',
     'sp-fade-type','sp-letterbox-ratio'].forEach(id => {
        document.getElementById(id).addEventListener('change', CC.autoSavePanel);
    });
})();

// ── TIME ENABLE TOGGLE — immediate UI update ───────────────────────────────────
// Fires before the debounced autoSavePanel so the disabled state is instant
document.getElementById('sp-time-enabled').addEventListener('change', function() {
    const enabled = this.checked;
    const slider  = document.getElementById('sp-time-slider');
    const num     = document.getElementById('sp-time-num');
    slider.disabled = !enabled;
    num.disabled    = !enabled;
    if (!enabled) {
        // Show world settings time as a preview reference
        slider.value = State.worldSettings.time;
        num.value    = State.worldSettings.time.toFixed(1);
    } else {
        // Restore the keyframe's stored time value (not the world display)
        const kf  = State.keyframes.find(k => k.id === State.selectedKfId);
        const val = kf && kf.time && kf.time.value || State.worldSettings.time;
        slider.value = val;
        num.value    = val.toFixed(1);
    }
});

// ═══════════════════════════════════════════════════════════════════════════════
// NUI-SAFE PROMPT / CONFIRM (replaces browser prompt() and confirm())
// ═══════════════════════════════════════════════════════════════════════════════

function nuiPrompt(title, message, defaultValue) {
    return new Promise((resolve) => {
        const modal   = document.getElementById('prompt-modal');
        const input   = document.getElementById('pm-input');
        const confirm = document.getElementById('pm-confirm');
        const cancel  = document.getElementById('pm-cancel');

        document.getElementById('pm-title').textContent   = title;
        document.getElementById('pm-message').textContent  = message || '';
        document.getElementById('pm-message').style.display = message ? 'block' : 'none';
        input.value = defaultValue || '';
        input.style.display = 'block';
        confirm.textContent = t('ui.ok');
        modal.classList.remove('hidden');
        setTimeout(() => input.focus(), 50);

        function cleanup() {
            modal.classList.add('hidden');
            confirm.removeEventListener('click', onOk);
            cancel.removeEventListener('click', onCancel);
            input.removeEventListener('keydown', onKey);
            document.getElementById('pm-backdrop').removeEventListener('click', onCancel);
        }
        function onOk()     { cleanup(); resolve(input.value.trim() || null); }
        function onCancel() { cleanup(); resolve(null); }
        function onKey(e)   { if (e.key === 'Enter') onOk(); if (e.key === 'Escape') onCancel(); }

        confirm.addEventListener('click', onOk);
        cancel.addEventListener('click', onCancel);
        input.addEventListener('keydown', onKey);
        document.getElementById('pm-backdrop').addEventListener('click', onCancel);
    });
}

function nuiConfirm(title, message) {
    return new Promise((resolve) => {
        const modal   = document.getElementById('prompt-modal');
        const input   = document.getElementById('pm-input');
        const confirm = document.getElementById('pm-confirm');
        const cancel  = document.getElementById('pm-cancel');

        document.getElementById('pm-title').textContent   = title;
        document.getElementById('pm-message').textContent  = message || '';
        document.getElementById('pm-message').style.display = message ? 'block' : 'none';
        input.style.display = 'none';
        confirm.textContent = t('ui.confirm');
        modal.classList.remove('hidden');

        function cleanup() {
            modal.classList.add('hidden');
            confirm.removeEventListener('click', onOk);
            cancel.removeEventListener('click', onCancel);
            document.getElementById('pm-backdrop').removeEventListener('click', onCancel);
        }
        function onOk()     { cleanup(); resolve(true); }
        function onCancel() { cleanup(); resolve(false); }

        confirm.addEventListener('click', onOk);
        cancel.addEventListener('click', onCancel);
        document.getElementById('pm-backdrop').addEventListener('click', onCancel);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCENE EDITOR
// ═══════════════════════════════════════════════════════════════════════════════

function populateSceneDropdowns() {
    const animSel = document.getElementById('se-anim-preset');
    animSel.innerHTML = `<option value="">${t('ui.select_placeholder')}</option>`;
    State.predefinedAnims.forEach((a, i) => {
        const opt = document.createElement('option');
        opt.value = i;
        opt.textContent = a.label;
        animSel.appendChild(opt);
    });

    const weapSel = document.getElementById('se-weapon-preset');
    weapSel.innerHTML = `<option value="">${t('ui.select_placeholder')}</option>`;
    State.commonWeapons.forEach((w, i) => {
        const opt = document.createElement('option');
        opt.value = i;
        opt.textContent = w.label;
        weapSel.appendChild(opt);
    });
}

// ── Panel navigation ─────────────────────────────────────────────────────────
CC.openSceneEditor = function() {
    hideAllViews();
    document.getElementById('sp-scene-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('scene.title');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');
    State.selectedSceneId = null;
    renderSceneEntityList();
    renderRelGroupList();
};

// ── Entity list rendering ────────────────────────────────────────────────────
function renderSceneEntityList() {
    const list = document.getElementById('se-entity-list');
    if (State.sceneEntities.length === 0) {
        list.innerHTML = `<div class="sp-hint" style="padding:4px 0">${t('scene.no_entities_yet')}</div>`;
        return;
    }
    list.innerHTML = '';
    State.sceneEntities.forEach(ent => {
        const card = document.createElement('div');
        card.className = 'se-entity-card' + (ent.id === State.selectedSceneId ? ' selected' : '');
        const icon = ent.type === 'ped' ? 'fa-person' : ent.type === 'vehicle' ? 'fa-car' : 'fa-cube';
        // Color icon by relationship group
        const group = ent.group ? State.relGroups.find(g => g.name === ent.group) : null;
        const iconStyle = group ? `background:${group.color}20;color:${group.color}` : '';
        card.innerHTML = `
            <div class="se-entity-icon ${ent.type}" ${iconStyle ? `style="${iconStyle}"` : ''}><i class="fa-solid ${icon}"></i></div>
            <span class="se-entity-name">${ent.model}</span>
            <span class="se-entity-type">${ent.group || ent.type}</span>
        `;
        card.addEventListener('click', () => openSceneEntityProps(ent.id));
        list.appendChild(card);
    });
}

// ── Open entity properties (separate view) ───────────────────────────────────
function openSceneEntityProps(id) {
    State.selectedSceneId = id;
    const ent = State.sceneEntities.find(e => e.id === id);
    if (!ent) return;

    // Switch to props view
    hideAllViews();
    document.getElementById('sp-scene-props-view').classList.remove('hidden');
    document.getElementById('sp-footer').classList.remove('hidden');
    document.getElementById('sp-back-btn').classList.remove('hidden');

    const typeLabel = ent.type === 'ped' ? t('scene.type_ped') : ent.type === 'vehicle' ? t('scene.type_vehicle') : t('scene.type_prop');
    document.getElementById('sp-title').textContent = t('scene.title_entity', { type: typeLabel, model: ent.model });

    // Show correct property panel
    document.getElementById('se-ped-props').classList.toggle('hidden', ent.type !== 'ped');
    document.getElementById('se-veh-props').classList.toggle('hidden', ent.type !== 'vehicle');
    document.getElementById('se-prop-props').classList.toggle('hidden', ent.type !== 'prop');

    // Populate position
    if (ent.pos) {
        document.getElementById('se-pos-x').value = (ent.pos.x || 0).toFixed(1);
        document.getElementById('se-pos-y').value = (ent.pos.y || 0).toFixed(1);
        document.getElementById('se-pos-z').value = (ent.pos.z || 0).toFixed(1);
    }
    document.getElementById('se-heading').value = Math.round(ent.heading || 0);

    // ── Ped state ──
    if (ent.type === 'ped') {
        const fb = document.getElementById('se-ped-follow-btn');
        fb.textContent = ent.followPlayer ? t('ui.on') : t('ui.off');
        fb.classList.toggle('active', !!ent.followPlayer);
        // Follow settings — always populate from this entity so previous values don't leak
        document.getElementById('se-follow-dist').value  = ent.followDist  ?? 5;
        const pSpdSel = document.getElementById('se-follow-speed');
        pSpdSel.value = String(ent.followSpeed ?? 1.0);
        pSpdSel.dispatchEvent(new Event('change', { bubbles: false }));
        // Group + Combat
        populatePedGroupDropdown();
        document.getElementById('se-ped-group').value = ent.group || '';
        document.getElementById('se-ped-combat-ability').value = ent.combatAbility ?? 1;
        document.getElementById('se-ped-combat-movement').value = ent.combatMovement ?? 2;
        document.getElementById('se-ped-combat-range').value = ent.combatRange ?? 1;
        document.getElementById('se-ped-accuracy').value = ent.accuracy ?? 50;
        document.getElementById('se-ped-accuracy-val').textContent = ent.accuracy ?? 50;
        // Health
        document.getElementById('se-ped-health').value = ent.health || 200;
        document.getElementById('se-ped-health-val').value = ent.health || 200;
        document.getElementById('se-ped-armor').value = ent.armor || 0;
        document.getElementById('se-ped-armor-val').value = ent.armor || 0;
        const setToggle = (id, val) => { const b = document.getElementById(id); b.textContent = val ? t('ui.on') : t('ui.off'); b.classList.toggle('active', val); };
        setToggle('se-ped-invincible-btn', ent.invincible !== false);
        setToggle('se-ped-ragdoll-btn', ent.ragdoll !== false);
        setToggle('se-ped-flee-btn', ent.flee === true);
    }

    // ── Vehicle state ──
    if (ent.type === 'vehicle') {
        const fb = document.getElementById('se-veh-follow-btn');
        fb.textContent = ent.followPlayer ? t('ui.on') : t('ui.off');
        fb.classList.toggle('active', !!ent.followPlayer);
        // Follow settings — always populate from this entity so previous values don't leak
        document.getElementById('se-veh-follow-dist').value  = ent.followDist  ?? 10;
        const spdSel = document.getElementById('se-veh-follow-speed');
        spdSel.value = String(ent.followSpeed ?? 25);
        spdSel.dispatchEvent(new Event('change', { bubbles: false }));
        const dsSel = document.getElementById('se-veh-drive-style');
        dsSel.value = String(ent.driveStyle ?? 786603);
        dsSel.dispatchEvent(new Event('change', { bubbles: false }));
        const setToggle = (id, val) => { const b = document.getElementById(id); b.textContent = val ? t('ui.on') : t('ui.off'); b.classList.toggle('active', val); };
        setToggle('se-veh-engine-btn', ent.engine);
        setToggle('se-veh-siren-btn', ent.siren);
        setToggle('se-veh-neon-btn', ent.neon);
        // Doors
        document.querySelectorAll('#se-veh-props .se-grid-btn').forEach((b, i) => {
            if (i < 6) b.classList.toggle('active', ent.doors && ent.doors[i]);
        });
        // Indicators
        document.getElementById('se-veh-ind-left').classList.toggle('active', ent.indicators && ent.indicators.left);
        document.getElementById('se-veh-ind-right').classList.toggle('active', ent.indicators && ent.indicators.right);
        document.getElementById('se-veh-ind-hazard').classList.toggle('active', ent.indicators && ent.indicators.left && ent.indicators.right);
        // Appearance — always set (not conditionally) so previous entity values don't leak
        document.getElementById('se-veh-color1').value = ent.color1 || '#000000';
        document.getElementById('se-veh-color2').value = ent.color2 || '#000000';
        document.getElementById('se-veh-dirt').value = ent.dirtLevel || 0;
        document.getElementById('se-veh-dirt-val').textContent = ent.dirtLevel || 0;
        document.getElementById('se-veh-plate').value = ent.plateText || '';
        document.getElementById('se-veh-neon-color').value = ent.neonColor || '#0000ff';
    }

    // ── Prop state ──
    if (ent.type === 'prop') {
        const setToggle = (id, val) => { const b = document.getElementById(id); b.textContent = val ? t('ui.on') : t('ui.off'); b.classList.toggle('active', val); };
        setToggle('se-prop-freeze-btn', ent.frozen !== false);
        setToggle('se-prop-visible-btn', ent.visible !== false);
        setToggle('se-prop-fire-btn', ent.onFire === true);
    }

    renderSceneEntityList();
    initCustomDropdowns();

    // Focus camera on entity
    const focusDist = ent.type === 'vehicle' ? 6.0 : ent.type === 'prop' ? 4.0 : 3.0;
    post('focusEntity', { entityId: ent.id, dist: focusDist, zOff: ent.type === 'vehicle' ? 1.5 : 0.8 });
    State._entityFocused = true;
}

// ── Back from entity props to scene list ─────────────────────────────────────
CC.backFromSceneProps = function() {
    State.selectedSceneId = null;
    document.getElementById('sp-scene-props-view').classList.add('hidden');
    document.getElementById('sp-scene-view').classList.remove('hidden');
    document.getElementById('sp-title').textContent = t('scene.title');
    renderSceneEntityList();
    // Return camera to timeline position
    post('unfocusEntity');
    State._entityFocused = false;
};

// ── Spawn ped ────────────────────────────────────────────────────────────────
CC.spawnScenePed = function() {
    const model = document.getElementById('se-ped-model').value.trim();
    if (!model) { showToast(t('errors.enter_ped_model'), 'error'); return; }
    const id  = State.nextSceneId++;
    const pos = { x: State.currentCamPos.x, y: State.currentCamPos.y, z: State.currentCamPos.z - 1.0 };
    const heading = (State.currentCamRot.z + 180) % 360;
    const ent = {
        id, type: 'ped', model, pos, heading,
        anim: null, weapon: null, followPlayer: false, followDist: 5, followSpeed: 1.0,
        _needsPlacement: true,
    };
    State.sceneEntities.push(ent);
    State.selectedSceneId = id;
    post('spawnScenePed', { id, model, pos, heading });
    renderSceneEntityList();
    document.getElementById('se-ped-model').value = '';
};

// ── Spawn vehicle ────────────────────────────────────────────────────────────
CC.spawnSceneVehicle = function() {
    const model = document.getElementById('se-veh-model').value.trim();
    if (!model) { showToast(t('errors.enter_vehicle_model'), 'error'); return; }
    const id  = State.nextSceneId++;
    const pos = { x: State.currentCamPos.x, y: State.currentCamPos.y, z: State.currentCamPos.z - 1.0 };
    const heading = (State.currentCamRot.z + 180) % 360;
    const ent = {
        id, type: 'vehicle', model, pos, heading,
        followPlayer: false, followDist: 10, followSpeed: 25, driveStyle: 786603,
        _needsPlacement: true,
    };
    State.sceneEntities.push(ent);
    State.selectedSceneId = id;
    post('spawnSceneVehicle', { id, model, pos, heading });
    renderSceneEntityList();
    document.getElementById('se-veh-model').value = '';
};

// ── Spawn callbacks ──────────────────────────────────────────────────────────
function onSceneEntitySpawned(d) {
    const ent = State.sceneEntities.find(e => e.id === d.id);
    if (ent && d.pos) {
        ent.pos = d.pos;
    }
    // Auto-enter placement mode for newly spawned entities
    if (ent && ent._needsPlacement) {
        delete ent._needsPlacement;
        State.selectedSceneId = ent.id;
        post('startScenePlacement', { entityId: ent.id, isNewSpawn: true });
    }
}

function onSceneEntityDeleted(d) {
    if (!d || d.entityId == null) return;
    State.sceneEntities = State.sceneEntities.filter(e => e.id !== d.entityId);
    if (State.selectedSceneId === d.entityId) State.selectedSceneId = null;
    renderSceneEntityList();
}

// ── Delete entity ────────────────────────────────────────────────────────────
CC.deleteSceneEntity = function() {
    if (State.selectedSceneId === null) return;
    const id = State.selectedSceneId;
    State.sceneEntities = State.sceneEntities.filter(e => e.id !== id);
    post('deleteSceneEntity', { entityId: id });
    CC.backFromSceneProps();
    showToast(t('toasts.entity_deleted'));
};

// ── Animations ───────────────────────────────────────────────────────────────
CC.playPresetAnim = function() {
    if (State.selectedSceneId === null) return;
    const idx = parseInt(document.getElementById('se-anim-preset').value);
    if (isNaN(idx) || !State.predefinedAnims[idx]) { showToast(t('errors.select_anim_preset'), 'error'); return; }
    const a = State.predefinedAnims[idx];
    const loop = document.getElementById('se-anim-loop').checked;
    post('scenePlayAnim', { entityId: State.selectedSceneId, dict: a.dict, name: a.anim, loop });
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (ent) ent.anim = { dict: a.dict, name: a.anim, loop };
};

CC.playCustomAnim = function() {
    if (State.selectedSceneId === null) return;
    const dict = document.getElementById('se-anim-dict').value.trim();
    const name = document.getElementById('se-anim-name').value.trim();
    if (!dict || !name) { showToast(t('errors.enter_anim_dict_name'), 'error'); return; }
    const loop = document.getElementById('se-anim-loop').checked;
    post('scenePlayAnim', { entityId: State.selectedSceneId, dict, name, loop });
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (ent) ent.anim = { dict, name, loop };
};

// ── Weapons ──────────────────────────────────────────────────────────────────
CC.giveSceneWeapon = function() {
    if (State.selectedSceneId === null) return;
    const idx = parseInt(document.getElementById('se-weapon-preset').value);
    if (isNaN(idx) || !State.commonWeapons[idx]) { showToast(t('errors.select_weapon'), 'error'); return; }
    const w = State.commonWeapons[idx];
    post('sceneGiveWeapon', { entityId: State.selectedSceneId, weaponHash: w.hash });
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (ent) ent.weapon = w.hash;
};

// ── Follow ───────────────────────────────────────────────────────────────────
CC.togglePedFollow = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent.followPlayer = !ent.followPlayer;
    ent.followDist   = parseFloat(document.getElementById('se-follow-dist').value) || 5;
    ent.followSpeed  = parseFloat(document.getElementById('se-follow-speed').value) || 1.0;
    const btn = document.getElementById('se-ped-follow-btn');
    btn.textContent = ent.followPlayer ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent.followPlayer);
    post('sceneSetFollow', { entityId: ent.id, follow: ent.followPlayer, dist: ent.followDist, speed: ent.followSpeed });
};

CC.toggleVehicleSceneFollow = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent.followPlayer = !ent.followPlayer;
    ent.followDist   = parseFloat(document.getElementById('se-veh-follow-dist').value) || 10;
    ent.followSpeed  = parseFloat(document.getElementById('se-veh-follow-speed').value) || 25;
    ent.driveStyle   = parseInt(document.getElementById('se-veh-drive-style').value) || 786603;
    const btn = document.getElementById('se-veh-follow-btn');
    btn.textContent = ent.followPlayer ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent.followPlayer);
    post('sceneSetVehicleFollow', { entityId: ent.id, follow: ent.followPlayer, dist: ent.followDist, speed: ent.followSpeed, driveStyle: ent.driveStyle });
};

// Live-push vehicle follow settings when dropdowns/inputs change
CC.syncVehicleFollowSettings = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent || !ent.followPlayer) return;
    ent.followDist  = parseFloat(document.getElementById('se-veh-follow-dist').value) || 10;
    ent.followSpeed = parseFloat(document.getElementById('se-veh-follow-speed').value) || 25;
    ent.driveStyle  = parseInt(document.getElementById('se-veh-drive-style').value) || 786603;
    post('sceneUpdateVehicleFollowSettings', { entityId: ent.id, dist: ent.followDist, speed: ent.followSpeed, driveStyle: ent.driveStyle });
};

// Live-push ped follow settings when inputs change
CC.syncPedFollowSettings = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent || !ent.followPlayer) return;
    ent.followDist  = parseFloat(document.getElementById('se-follow-dist').value) || 5;
    ent.followSpeed = parseFloat(document.getElementById('se-follow-speed').value) || 1.0;
    post('sceneUpdatePedFollowSettings', { entityId: ent.id, dist: ent.followDist, speed: ent.followSpeed });
};

// ── Prop spawn ───────────────────────────────────────────────────────────────
CC.spawnSceneProp = function() {
    const model = document.getElementById('se-prop-model').value.trim();
    if (!model) { showToast(t('errors.enter_prop_model'), 'error'); return; }
    const id  = State.nextSceneId++;
    const pos = { x: State.currentCamPos.x, y: State.currentCamPos.y, z: State.currentCamPos.z - 1.0 };
    const heading = (State.currentCamRot.z + 180) % 360;
    const ent = {
        id, type: 'prop', model, pos, heading,
        frozen: true, visible: true, onFire: false,
        _needsPlacement: true,
    };
    State.sceneEntities.push(ent);
    State.selectedSceneId = id;
    post('spawnSceneProp', { id, model, pos, heading });
    renderSceneEntityList();
    document.getElementById('se-prop-model').value = '';
};

// ── Prop settings ────────────────────────────────────────────────────────────
CC.togglePropSetting = function(key) {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent[key] = !ent[key];
    const btnMap = { frozen: 'se-prop-freeze-btn', visible: 'se-prop-visible-btn', onFire: 'se-prop-fire-btn' };
    const btn = document.getElementById(btnMap[key]);
    btn.textContent = ent[key] ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent[key]);
    post('scenePropSetting', { entityId: ent.id, key, value: ent[key] });
};

// ── Vehicle controls ─────────────────────────────────────────────────────────
function getSelectedVeh() {
    if (State.selectedSceneId === null) return null;
    return State.sceneEntities.find(e => e.id === State.selectedSceneId && e.type === 'vehicle');
}

CC.toggleVehEngine = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.engine = !ent.engine;
    const btn = document.getElementById('se-veh-engine-btn');
    btn.textContent = ent.engine ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent.engine);
    post('sceneVehEngine', { entityId: ent.id, on: ent.engine });
};

CC.toggleVehSiren = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.siren = !ent.siren;
    const btn = document.getElementById('se-veh-siren-btn');
    btn.textContent = ent.siren ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent.siren);
    post('sceneVehSiren', { entityId: ent.id, on: ent.siren });
};

CC.setVehLights = function(mode) {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.lightMode = mode;
    document.querySelectorAll('.se-sm-btn').forEach((b, i) => {
        if (b.closest('.sp-section')?.querySelector('.sp-section-title')?.textContent?.includes('ENGINE')) {
            // only target light buttons in the engine section
        }
    });
    // Simple: update via parent
    const btns = document.querySelectorAll('#se-veh-props .sp-section:first-child .se-sm-btn');
    btns.forEach(b => b.classList.remove('active'));
    if (btns[mode]) btns[mode].classList.add('active');
    post('sceneVehLights', { entityId: ent.id, mode });
};

CC.toggleVehDoor = function(door) {
    const ent = getSelectedVeh(); if (!ent) return;
    if (!ent.doors) ent.doors = [false,false,false,false,false,false];
    ent.doors[door] = !ent.doors[door];
    const btns = document.querySelectorAll('#se-veh-props .se-grid-btn');
    if (btns[door]) btns[door].classList.toggle('active', ent.doors[door]);
    post('sceneVehDoor', { entityId: ent.id, door, open: ent.doors[door] });
};

CC.smashVehWindow = function(win) {
    const ent = getSelectedVeh(); if (!ent) return;
    if (!ent.windows) ent.windows = [false,false,false,false];
    ent.windows[win] = true;
    const section = document.querySelector('#se-veh-props .sp-section:nth-child(3)');
    const btns = section ? section.querySelectorAll('.se-grid-btn') : [];
    if (btns[win]) btns[win].classList.add('active');
    post('sceneVehWindow', { entityId: ent.id, window: win });
};

CC.toggleVehIndicator = function(dir) {
    const ent = getSelectedVeh(); if (!ent) return;
    if (!ent.indicators) ent.indicators = { left: false, right: false };
    if (dir === 'hazard') {
        const on = !(ent.indicators.left && ent.indicators.right);
        ent.indicators.left = on; ent.indicators.right = on;
    } else {
        ent.indicators[dir] = !ent.indicators[dir];
    }
    document.getElementById('se-veh-ind-left').classList.toggle('active', ent.indicators.left);
    document.getElementById('se-veh-ind-right').classList.toggle('active', ent.indicators.right);
    document.getElementById('se-veh-ind-hazard').classList.toggle('active', ent.indicators.left && ent.indicators.right);
    post('sceneVehIndicator', { entityId: ent.id, left: ent.indicators.left, right: ent.indicators.right });
};

function hexToRgb(hex) {
    const r = parseInt(hex.slice(1,3), 16), g = parseInt(hex.slice(3,5), 16), b = parseInt(hex.slice(5,7), 16);
    return { r, g, b };
}

CC.setVehColor = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    const c1 = hexToRgb(document.getElementById('se-veh-color1').value);
    const c2 = hexToRgb(document.getElementById('se-veh-color2').value);
    ent.color1 = document.getElementById('se-veh-color1').value;
    ent.color2 = document.getElementById('se-veh-color2').value;
    post('sceneVehColor', { entityId: ent.id, r1: c1.r, g1: c1.g, b1: c1.b, r2: c2.r, g2: c2.g, b2: c2.b });
};

CC.setVehDirt = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.dirtLevel = parseFloat(document.getElementById('se-veh-dirt').value);
    post('sceneVehDirt', { entityId: ent.id, level: ent.dirtLevel });
};

CC.setVehPlate = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.plateText = document.getElementById('se-veh-plate').value;
    post('sceneVehPlate', { entityId: ent.id, text: ent.plateText });
};

CC.toggleVehNeon = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    ent.neon = !ent.neon;
    const btn = document.getElementById('se-veh-neon-btn');
    btn.textContent = ent.neon ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent.neon);
    post('sceneVehNeon', { entityId: ent.id, on: ent.neon });
};

CC.setVehNeonColor = function() {
    const ent = getSelectedVeh(); if (!ent) return;
    const c = hexToRgb(document.getElementById('se-veh-neon-color').value);
    ent.neonColor = document.getElementById('se-veh-neon-color').value;
    post('sceneVehNeonColor', { entityId: ent.id, r: c.r, g: c.g, b: c.b });
};

// ═══════════════════════════════════════════════════════════════════════════════
// RELATIONSHIP GROUPS
// ═══════════════════════════════════════════════════════════════════════════════

const GROUP_COLORS = ['#4a9df0','#e06060','#5cb85c','#e0a030','#c060e0','#60c0c0','#e06090','#90e060'];
const REL_CYCLE = ['neutral', 'friendly', 'hostile'];

// State.relGroups = [{ name, color }]   — "Director" always at index 0
// State.relMatrix = { "GroupA->GroupB": "neutral"|"friendly"|"hostile" }
if (!State.relGroups) State.relGroups = [{ name: 'Director', color: '#4a9df0' }];
// Lua's JSON encoder serializes empty tables as [] (array). Coerce back to plain object
// so "A->B" property writes don't get dropped by JSON.stringify.
if (!State.relMatrix || Array.isArray(State.relMatrix)) State.relMatrix = {};

function getRelKey(a, b) { return a + '->' + b; }
function ensureMatrix() {
    if (!State.relMatrix || Array.isArray(State.relMatrix)) State.relMatrix = {};
}
function getRelation(a, b) { ensureMatrix(); return State.relMatrix[getRelKey(a, b)] || 'neutral'; }
function setRelation(a, b, rel) {
    ensureMatrix();
    State.relMatrix[getRelKey(a, b)] = rel;
    State.relMatrix[getRelKey(b, a)] = rel; // symmetric
}

CC.createRelGroup = async function() {
    const name = document.getElementById('se-group-name').value.trim();
    if (!name) { showToast(t('errors.enter_group_name'), 'error'); return; }
    if (State.relGroups.find(g => g.name.toLowerCase() === name.toLowerCase())) {
        showToast(t('errors.group_already_exists'), 'error'); return;
    }
    const color = GROUP_COLORS[State.relGroups.length % GROUP_COLORS.length];
    State.relGroups.push({ name, color });
    document.getElementById('se-group-name').value = '';
    renderRelGroupList();
    syncRelGroupsToLua();
    autoSaveProject();
    showToast(t('toasts.group_created', { name: name }));
};

CC.deleteRelGroup = async function(name) {
    if (name === 'Director') { showToast(t('errors.cannot_delete_director'), 'error'); return; }
    if (!await nuiConfirm(t('ui.confirm_delete_group_title'), t('ui.confirm_delete_group_message', { name: name }))) return;
    State.relGroups = State.relGroups.filter(g => g.name !== name);
    // Clean matrix entries
    for (const key of Object.keys(State.relMatrix)) {
        if (key.includes(name + '->') || key.includes('->' + name)) delete State.relMatrix[key];
    }
    // Unassign peds
    State.sceneEntities.filter(e => e.group === name).forEach(e => e.group = '');
    renderRelGroupList();
    syncRelGroupsToLua();
    autoSaveProject();
};

CC.openRelMatrix = function() {
    document.getElementById('rel-matrix-modal').classList.remove('hidden');
    renderRelMatrix();
};

CC.closeRelMatrix = function() {
    document.getElementById('rel-matrix-modal').classList.add('hidden');
};

function renderRelGroupList() {
    const list = document.getElementById('se-group-list');
    list.innerHTML = '';
    State.relGroups.forEach(g => {
        const item = document.createElement('div');
        item.className = 'se-group-item';
        const isDel = g.name !== 'Director';
        item.innerHTML = `
            <div class="se-group-color" style="background:${g.color}"></div>
            <span class="se-group-name">${g.name}</span>
            <div class="se-group-actions">
                <button onclick="CC.openRelMatrix()" title="Edit relationships"><i class="fa-solid fa-arrows-left-right"></i></button>
                ${isDel ? `<button onclick="CC.deleteRelGroup('${g.name}')" title="Delete"><i class="fa-solid fa-trash"></i></button>` : ''}
            </div>
        `;
        list.appendChild(item);
    });
    // Update ped group dropdowns
    populatePedGroupDropdown();
}

function populatePedGroupDropdown() {
    const sel = document.getElementById('se-ped-group');
    if (!sel) return;
    const current = sel.value;
    sel.innerHTML = `<option value="">${t('ui.none_placeholder')}</option>`;
    State.relGroups.forEach(g => {
        const opt = document.createElement('option');
        opt.value = g.name;
        opt.textContent = g.name;
        sel.appendChild(opt);
    });
    sel.value = current;
    initCustomDropdowns();
}

function renderRelMatrix() {
    const grid = document.getElementById('rmm-grid');
    const groups = State.relGroups;
    const n = groups.length;
    grid.style.gridTemplateColumns = `80px repeat(${n}, 1fr)`;
    grid.innerHTML = '';

    // Top-left empty corner
    grid.appendChild(Object.assign(document.createElement('div'), { className: 'rmm-cell header', textContent: '' }));
    // Column headers
    groups.forEach(g => {
        const cell = document.createElement('div');
        cell.className = 'rmm-cell header';
        cell.textContent = g.name;
        cell.style.color = g.color;
        grid.appendChild(cell);
    });

    // Rows
    groups.forEach((rowG, ri) => {
        // Row header
        const rh = document.createElement('div');
        rh.className = 'rmm-cell header';
        rh.textContent = rowG.name;
        rh.style.color = rowG.color;
        rh.style.textAlign = 'right';
        rh.style.paddingRight = '8px';
        grid.appendChild(rh);

        groups.forEach((colG, ci) => {
            const cell = document.createElement('div');
            if (ri === ci) {
                cell.className = 'rmm-cell self';
                cell.textContent = '—';
            } else {
                const rel = getRelation(rowG.name, colG.name);
                cell.className = 'rmm-cell ' + rel;
                cell.textContent = rel.substring(0, 4);
                cell.addEventListener('click', () => {
                    const cur = getRelation(rowG.name, colG.name);
                    const next = REL_CYCLE[(REL_CYCLE.indexOf(cur) + 1) % REL_CYCLE.length];
                    setRelation(rowG.name, colG.name, next);
                    syncRelGroupsToLua();
                    autoSaveProject();
                    renderRelMatrix();
                });
            }
            grid.appendChild(cell);
        });
    });
}

function syncRelGroupsToLua() {
    post('sceneSetRelGroups', {
        groups: State.relGroups,
        matrix: State.relMatrix,
    });
}

State.sceneCombatActive = false;

function renderCombatToggle() {
    const btn = document.getElementById('se-combat-toggle');
    if (!btn) return;
    const active = !!State.sceneCombatActive;
    btn.classList.toggle('danger', active);
    btn.innerHTML = active
        ? '<i class="fa-solid fa-stop"></i>&nbsp;<span>' + t('html.buttons.combat_stop') + '</span>'
        : '<i class="fa-solid fa-play"></i>&nbsp;<span>' + t('html.buttons.combat_start') + '</span>';
}

CC.toggleSceneCombat = function() {
    // Resync groups/matrix so Lua's relationship state is fresh before tasking combat.
    post('sceneSetRelGroups', { groups: State.relGroups, matrix: State.relMatrix });
    post('sceneToggleCombat', {});
};

function onSceneCombatState(d) {
    State.sceneCombatActive = !!(d && d.active);
    renderCombatToggle();
}

CC.resetScene = function() {
    post('sceneResetPositions', {});
    showToast(t('toasts.scene_reset'));
};

// ── Ped combat & health ──────────────────────────────────────────────────────
CC.applyPedCombat = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent.group = document.getElementById('se-ped-group').value;
    ent.combatAbility = parseInt(document.getElementById('se-ped-combat-ability').value);
    ent.combatMovement = parseInt(document.getElementById('se-ped-combat-movement').value);
    ent.combatRange = parseInt(document.getElementById('se-ped-combat-range').value);
    ent.accuracy = parseInt(document.getElementById('se-ped-accuracy').value);
    post('scenePedCombat', {
        entityId: ent.id, group: ent.group,
        ability: ent.combatAbility, movement: ent.combatMovement,
        range: ent.combatRange, accuracy: ent.accuracy,
    });
    showToast(t('toasts.combat_applied'));
};

CC.togglePedState = function(key) {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    const btnMap = { invincible: 'se-ped-invincible-btn', ragdoll: 'se-ped-ragdoll-btn', flee: 'se-ped-flee-btn' };
    if (ent[key] === undefined) ent[key] = key === 'flee' ? false : true;
    ent[key] = !ent[key];
    const btn = document.getElementById(btnMap[key]);
    btn.textContent = ent[key] ? t('ui.on') : t('ui.off');
    btn.classList.toggle('active', ent[key]);
};

CC.applyPedHealth = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent.health = parseInt(document.getElementById('se-ped-health-val').value) || 200;
    ent.armor = parseInt(document.getElementById('se-ped-armor-val').value) || 0;
    post('scenePedHealth', {
        entityId: ent.id, health: ent.health, armor: ent.armor,
        invincible: ent.invincible !== false, canRagdoll: ent.ragdoll !== false, flee: ent.flee === true,
    });
    showToast(t('toasts.health_applied'));
};

CC.playPedScenario = function() {
    if (State.selectedSceneId === null) return;
    const scenario = document.getElementById('se-ped-scenario').value;
    if (!scenario) { showToast(t('errors.select_scenario'), 'error'); return; }
    post('scenePedScenario', { entityId: State.selectedSceneId, scenario });
};

CC.stopPedScenario = function() {
    if (State.selectedSceneId === null) return;
    post('scenePedStopScenario', { entityId: State.selectedSceneId });
};

// ── Position update from inputs ──────────────────────────────────────────────
CC.updateSceneEntityPos = function() {
    if (State.selectedSceneId === null) return;
    const ent = State.sceneEntities.find(e => e.id === State.selectedSceneId);
    if (!ent) return;
    ent.pos = {
        x: parseFloat(document.getElementById('se-pos-x').value) || 0,
        y: parseFloat(document.getElementById('se-pos-y').value) || 0,
        z: parseFloat(document.getElementById('se-pos-z').value) || 0,
    };
    ent.heading = parseFloat(document.getElementById('se-heading').value) || 0;
    post('sceneUpdatePos', { entityId: ent.id, pos: ent.pos, heading: ent.heading });
};

// ── Placement mode ───────────────────────────────────────────────────────────
CC.startScenePlacement = function() {
    if (State.selectedSceneId === null) return;
    post('startScenePlacement', { entityId: State.selectedSceneId });
};

function onScenePlacementOverlay(active) {
    State.isScenePlacing = active;
    if (active) {
        PlacementGuide.show('scene');
        document.getElementById('side-panel').classList.add('dimmed');
    } else {
        PlacementGuide.hide();
        document.getElementById('side-panel').classList.remove('dimmed');
        // If cancelled, open scene editor list
        if (State.selectedSceneId !== null) {
            CC.openSceneEditor();
        }
    }
}

function onScenePlacementDone(d) {
    onScenePlacementOverlay(false);
    if (!d || !d.pos) return;
    const ent = State.sceneEntities.find(e => e.id === d.entityId);
    if (ent) {
        ent.pos     = d.pos;
        ent.heading = d.heading || ent.heading;
    }
    showToast(t('toasts.entity_placed'));
    // Open entity properties after placement
    if (ent) openSceneEntityProps(ent.id);
}

// ═══════════════════════════════════════════════════════════════════════════════
// CINEMATIC EFFECTS OVERLAY (rendered during playback via NUI messages from Lua)
// ═══════════════════════════════════════════════════════════════════════════════

function onFxUpdate(d) {
    const overlay = document.getElementById('fx-overlay');
    overlay.style.display = 'block';

    // Fade
    const fade = document.getElementById('fx-fade');
    const fadeType   = d.fadeType   || 'none';
    const fadeAmount = d.fadeAmount || 0;
    if (fadeType !== 'none' && fadeAmount > 0) {
        fade.style.background = fadeType === 'white' ? 'white' : 'black';
        fade.style.opacity = fadeAmount;
    } else {
        fade.style.opacity = 0;
    }

    // Vignette
    const vig = document.getElementById('fx-vignette');
    const vigAmount = d.vignette || 0;
    if (vigAmount > 0) {
        const spread = Math.round(120 - vigAmount * 80);
        const blur   = Math.round(60 + vigAmount * 80);
        vig.style.boxShadow = `inset 0 0 ${blur}px ${spread}px rgba(0,0,0,${vigAmount * 0.9})`;
        vig.style.opacity = 1;
    } else {
        vig.style.opacity = 0;
    }

    // Letterbox
    const lbTop    = document.getElementById('fx-letterbox-top');
    const lbBottom = document.getElementById('fx-letterbox-bottom');
    const ratio    = d.letterbox || 0;
    if (ratio > 0) {
        const screenRatio = window.innerWidth / window.innerHeight;
        if (ratio < screenRatio) {
            const targetH = window.innerWidth / ratio;
            const barH = Math.max(0, (window.innerHeight - targetH) / 2);
            lbTop.style.height    = barH + 'px';
            lbBottom.style.height = barH + 'px';
        } else {
            lbTop.style.height    = '0';
            lbBottom.style.height = '0';
        }
    } else {
        lbTop.style.height    = '0';
        lbBottom.style.height = '0';
    }

    // Grain
    const grain = document.getElementById('fx-grain');
    grain.style.opacity = d.grain || 0;
}

function onFxClear() {
    const overlay = document.getElementById('fx-overlay');
    overlay.style.display = 'none';
    document.getElementById('fx-fade').style.opacity = 0;
    document.getElementById('fx-vignette').style.opacity = 0;
    document.getElementById('fx-letterbox-top').style.height = '0';
    document.getElementById('fx-letterbox-bottom').style.height = '0';
    document.getElementById('fx-grain').style.opacity = 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECORDING COUNTDOWN + INDICATOR
// ═══════════════════════════════════════════════════════════════════════════════

function onRecordingCountdown() {
    const overlay   = document.getElementById('rec-overlay');
    const countdown = document.getElementById('rec-countdown');
    const indicator = document.getElementById('rec-indicator');
    const stopHint  = document.getElementById('rec-stop-hint');

    overlay.classList.remove('hidden', 'recording');
    indicator.classList.add('hidden');
    stopHint.classList.add('hidden');

    const nums = [3, 2, 1];
    let i = 0;

    function showNext() {
        if (i >= nums.length) {
            countdown.textContent = '';
            countdown.classList.remove('active');
            // Countdown done — tell Lua to actually start recording
            post('recordingCountdownDone');
            return;
        }
        countdown.textContent = nums[i];
        countdown.classList.remove('active');
        // Force reflow to restart animation
        void countdown.offsetWidth;
        countdown.classList.add('active');
        i++;
        setTimeout(showNext, 900);
    }
    showNext();
}

function onRecordingStarted() {
    const overlay   = document.getElementById('rec-overlay');
    const countdown = document.getElementById('rec-countdown');
    const indicator = document.getElementById('rec-indicator');
    const stopHint  = document.getElementById('rec-stop-hint');

    overlay.classList.remove('hidden');
    overlay.classList.add('recording');
    countdown.textContent = '';
    countdown.classList.remove('active');
    indicator.classList.remove('hidden');
    stopHint.classList.remove('hidden');
    stopHint.style.opacity = '1';
    document.getElementById('rec-timer').textContent = '00:00';

    // Fade out the stop hint after 4 seconds
    setTimeout(() => {
        stopHint.style.transition = 'opacity 1.5s';
        stopHint.style.opacity = '0';
    }, 4000);
}

function onRecordingTick(elapsed) {
    const mins = Math.floor(elapsed / 60);
    const secs = Math.floor(elapsed % 60);
    document.getElementById('rec-timer').textContent =
        String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
}

function onRecordingStopped() {
    const overlay = document.getElementById('rec-overlay');
    overlay.classList.add('hidden');
    overlay.classList.remove('recording');
    document.getElementById('rec-indicator').classList.add('hidden');
    document.getElementById('rec-stop-hint').classList.add('hidden');
    document.getElementById('rec-countdown').textContent = '';
    if (typeof Tutorial !== 'undefined' && Tutorial.isActive()) {
        post('tutorialDespawnAdder');
        post('tutorialReopenUI');
        // Fire the advance after the UI reopens so the next step's target element exists
        setTimeout(() => Tutorial.fire('tut:recordingStopped'), 500);
    }
}

// ── Recording save (once, when recording finishes) ──────────────────────────
function onRecordingFinished() {
    if (!State.currentProject) return;
    // Save recording data to server via latent event (only when a recording actually finishes)
    post('saveProjectWithRecordings', getProjectData());
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL SWAP (click replay entity → swap model)
// ═══════════════════════════════════════════════════════════════════════════════

State.modelSwapTarget = null; // { entityType:'vehicle'|'ped', recordingIdx, currentModel }

// ── Recording entity list ────────────────────────────────────────────────────
function renderRecEntityList() {
    const list = document.getElementById('rp-entity-list');
    if (!State.recEntityList || State.recEntityList.length === 0) {
        list.innerHTML = `<div class="sp-hint" style="padding:4px 0">${t('scene.no_recorded_entities')}</div>`;
        return;
    }
    list.innerHTML = '';
    State.recEntityList.forEach(ent => {
        const card = document.createElement('div');
        card.className = 'se-entity-card';
        const icon = ent.type === 'vehicle' ? 'fa-car' : 'fa-person';
        const badge = ent.isPlayer ? ` <span style="color:var(--accent);font-size:9px">${t('ui.you_badge')}</span>` : '';
        card.innerHTML = `
            <div class="se-entity-icon ${ent.type}"><i class="fa-solid ${icon}"></i></div>
            <span class="se-entity-name">${ent.model}${badge}</span>
            <span class="se-entity-type">${ent.type}</span>
        `;
        card.addEventListener('dblclick', () => {
            State.modelSwapTarget = {
                entityType:   ent.type,
                recordingIdx: ent.idx,
                currentModel: ent.model,
            };
            document.getElementById('msm-type').textContent    = ent.type === 'vehicle' ? t('scene.type_vehicle') : t('scene.type_ped');
            document.getElementById('msm-current').textContent = ent.model;
            document.getElementById('msm-new-model').value     = '';
            document.getElementById('model-swap-modal').classList.remove('hidden');
            setTimeout(() => document.getElementById('msm-new-model').focus(), 50);
        });
        list.appendChild(card);
    });
}

CC.deleteRecording = async function() {
    if (!State.vehicleRecording) return;
    if (!await nuiConfirm(t('ui.confirm_delete_recording_title'), t('ui.confirm_delete_recording_message'))) return;
    post('deleteRecording');
    State.vehicleRecording  = null;
    State.vehicleRecStart   = 0;
    State.vehicleRecEnd     = 0;
    State.vehicleRecTrimIn  = 0;
    State.vehicleRecSelected = false;
    State.recEntityList     = [];
    hideSidePanel();
    renderTimeline();
    showToast(t('toasts.recording_deleted'));
};

function onReplayEntityClicked(d) {
    State.modelSwapTarget = {
        entityType:   d.entityType,
        recordingIdx: d.recordingIdx,
        currentModel: d.currentModel,
    };
    const modal = document.getElementById('model-swap-modal');
    document.getElementById('msm-type').textContent    = d.entityType === 'vehicle' ? t('scene.type_vehicle') : t('scene.type_ped');
    document.getElementById('msm-current').textContent = d.currentModel;
    document.getElementById('msm-new-model').value     = '';
    modal.classList.remove('hidden');
    setTimeout(() => document.getElementById('msm-new-model').focus(), 50);
}

CC.closeModelSwap = function() {
    document.getElementById('model-swap-modal').classList.add('hidden');
    State.modelSwapTarget = null;
};

CC.applyModelSwap = function() {
    if (!State.modelSwapTarget) return;
    const newModel = document.getElementById('msm-new-model').value.trim();
    if (!newModel) { showToast(t('errors.enter_model_name'), 'error'); return; }
    post('swapReplayModel', {
        entityType:   State.modelSwapTarget.entityType,
        recordingIdx: State.modelSwapTarget.recordingIdx,
        newModel:     newModel,
    });
};

function onModelSwapDone(d) {
    document.getElementById('model-swap-modal').classList.add('hidden');
    showToast(t('toasts.model_swapped', { model: d.newModel }));
    State.modelSwapTarget = null;
    // Update entity list with new model name
    if (d.entityType && d.recordingIdx != null && State.recEntityList) {
        const ent = State.recEntityList.find(e => e.type === d.entityType && e.idx === d.recordingIdx);
        if (ent) ent.model = d.newModel;
        renderRecEntityList();
    }
}

// Enter key in the model swap input
document.getElementById('msm-new-model').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); CC.applyModelSwap(); }
    if (e.key === 'Escape') { e.preventDefault(); CC.closeModelSwap(); }
});

// Click backdrop to close
document.getElementById('msm-backdrop').addEventListener('click', () => CC.closeModelSwap());

// ── Click-through to detect replay entities ──────────────────────────────────
// Double-click the viewport area to select a replay entity for model swap
document.getElementById('viewport-click-zone').addEventListener('dblclick', (e) => {
    if (State.isPlaying || State.isPositionMode || State.isTextPlacing || State.isScenePlacing) return;
    const mouseX = e.clientX / window.innerWidth;
    const mouseY = e.clientY / window.innerHeight;
    post('clickReplayEntity', { mouseX, mouseY });
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROJECT SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════

function showProjectOverlay() {
    document.getElementById('project-overlay').classList.remove('hidden');
    document.getElementById('tb-no-project').style.display = '';
    document.getElementById('tb-project-controls').style.display = 'none';
    // Dim timeline controls
    document.getElementById('top-bar-center').style.opacity = '0.3';
    document.getElementById('top-bar-center').style.pointerEvents = 'none';
    document.getElementById('top-bar-right').style.opacity = '0.3';
    document.getElementById('top-bar-right').style.pointerEvents = 'none';
    post('listProjects');
}

function hideProjectOverlay() {
    document.getElementById('project-overlay').classList.add('hidden');
    document.getElementById('tb-no-project').style.display = 'none';
    document.getElementById('tb-project-controls').style.display = 'flex';
    // Enable timeline controls
    document.getElementById('top-bar-center').style.opacity = '';
    document.getElementById('top-bar-center').style.pointerEvents = '';
    document.getElementById('top-bar-right').style.opacity = '';
    document.getElementById('top-bar-right').style.pointerEvents = '';
}

// Kept for backwards compat with onShow
CC.openProjectBrowser = function() { showProjectOverlay(); };
CC.closeProjectBrowser = function() { hideProjectOverlay(); };

function onProjectList(projects) {
    State.projectList = projects || [];
    renderProjectList();
}

function renderProjectList() {
    const list = document.getElementById('po-list');
    list.classList.toggle('empty', State.projectList.length === 0);
    if (State.projectList.length === 0) {
        list.innerHTML = `
            <div class="po-empty">
                <div class="po-empty-icon"><i class="fa-solid fa-film"></i></div>
                <div class="po-empty-title">${t('project.no_projects_yet')}</div>
                <div class="po-empty-sub">${t('project.no_projects_sub')}</div>
            </div>`;
        return;
    }
    list.innerHTML = '';
    const sorted = [...State.projectList].sort((a, b) => (b.updatedAt || 0) - (a.updatedAt || 0));
    sorted.forEach(proj => {
        const card = document.createElement('div');
        card.className = 'po-card';

        const date = proj.updatedAt ? new Date(proj.updatedAt * 1000) : null;
        const dateStr = date ? date.toLocaleDateString(undefined, {month:'short', day:'numeric', hour:'2-digit', minute:'2-digit'}) : '';

        card.innerHTML = `
            <div class="po-card-icon"><i class="fa-solid fa-film"></i></div>
            <div class="po-card-info">
                <div class="po-card-name">${proj.name || proj.slug}</div>
                <div class="po-card-meta">${dateStr}</div>
            </div>
        `;


        const delBtn = document.createElement('button');
        delBtn.className = 'po-card-delete';
        delBtn.innerHTML = '<i class="fa-solid fa-trash"></i>';
        delBtn.addEventListener('click', async (e) => {
            e.stopPropagation();
            if (!await nuiConfirm(t('project.confirm_delete_title'), t('project.confirm_delete_message', { name: proj.name }))) return;
            post('deleteProject', { slug: proj.slug });
        });
        card.appendChild(delBtn);

        card.addEventListener('click', () => {
            loadProjectBySlug(proj.slug);
        });
        list.appendChild(card);
    });
}

// Wipe everything tied to the currently-loaded project in JS State AND tell
// Lua to drop its cached recordings / overlays / spawns. Called when the user
// leaves one project for another (different slug), creates a fresh one, or
// deletes the active one. Safe to call when no project is loaded.
function wipeProjectStateFull() {
    // Timeline / content
    State.keyframes = []; State.selectedKfId = null; State.currentFrame = 0;
    State.textObjects = []; State.textClips = [];
    State.nextId = 1; State.nextTextId = 1; State.nextTextClipId = 1;
    State.selectedClipId = null; State.editingClipId = null;

    // Recording block + loading state
    State.vehicleRecording   = null;
    State.vehicleRecStart    = 0;
    State.vehicleRecEnd      = 0;
    State.vehicleRecTrimIn   = 0;
    State.vehicleRecSelected = false;
    State.recLoading         = false;
    State.recEntityList      = [];

    // Overlay layers
    State.overlayLayers     = [];
    State.selectedOverlayId = null;

    // Scene entities — tell Lua to despawn each one individually, then clear
    (State.sceneEntities || []).forEach(ent => post('deleteSceneEntity', { entityId: ent.id }));
    State.sceneEntities = []; State.nextSceneId = 1; State.selectedSceneId = null;
    State.relGroups = [{ name: 'Director', color: '#4a9df0' }]; State.relMatrix = {};

    // Project meta + autosave
    State.currentProject = null;
    if (State.autoSaveTimer) { clearInterval(State.autoSaveTimer); State.autoSaveTimer = null; }
    State.autoSaveDirty = false;

    // Reset duration / UI inputs
    State.durationSec = 30;
    const durInput = document.getElementById('duration-input');
    const frmInput = document.getElementById('frame-input');
    if (durInput) durInput.value = 30;
    if (frmInput) frmInput.value = 0;

    // Tell Lua to drop its cached state too (overlays, recordings, spawns, bucket)
    post('resetProjectState');

    syncKeyframesToLua(); syncTextToLua();
}

// Every project-list click goes through this. State is wiped and the project
// is always fetched fresh — no in-memory caching across project switches.
function loadProjectBySlug(slug) {
    wipeProjectStateFull();
    post('loadProject', { slug });
}

CC.createProject = async function() {
    document.getElementById('pm-tut-row').classList.remove('hidden');
    document.getElementById('pm-tut-checkbox').checked = State.tutorialDefault !== false;
    const name = await nuiPrompt(t('project.new_project_title'), t('project.new_project_prompt'));
    const tutorialEnabled = document.getElementById('pm-tut-checkbox').checked;
    document.getElementById('pm-tut-row').classList.add('hidden');
    if (!name) return;
    const slug = name.toLowerCase().replace(/[^a-z0-9\-_ ]/g, '').replace(/\s+/g, '_').substring(0, 64);
    if (!slug) return;

    // If a project was cached from a previous session (closeProject kept it),
    // auto-save it before we throw it away, then full-wipe so the new project
    // starts completely fresh (no overlay / recording / scene leakage).
    if (State.currentProject) autoSaveProject();
    wipeProjectStateFull();

    State.currentProject = { slug, name, createdAt: Math.floor(Date.now()/1000), updatedAt: Math.floor(Date.now()/1000), tutorialEnabled };
    document.getElementById('tb-project-name').textContent = name;

    syncKeyframesToLua(); syncTextToLua();
    renderTimeline(); updateTimecodeDisplay(); hideSidePanel();
    hideProjectOverlay();

    // Save immediately
    autoSaveProject();
    startAutoSave();
    showToast(t('project.created', { name: name }));

    if (tutorialEnabled) setTimeout(() => Tutorial.start(), 600);
};

CC.saveProject = function() {
    if (!State.currentProject) return;
    autoSaveProject();
    showToast(t('project.saved'));
};

CC.closeProject = async function() {
    if (State.currentProject) autoSaveProject();
    // Full wipe — no caching across project exits. State drops to blank; Lua
    // drops its recordings, overlays, scene entities, spawns, drift smoke,
    // cinematic bucket, and teleports the ped back to uiOriginPos.
    wipeProjectStateFull();
    hideSidePanel();
    showProjectOverlay();
};

function onProjectLoaded(raw) {
    try {
        const data = typeof raw === 'string' ? JSON.parse(raw) : raw;
        if (!data.slug) throw new Error(t('errors.invalid_project'));

        State.currentProject = { slug: data.slug, name: data.name, createdAt: data.createdAt, updatedAt: data.updatedAt, tutorialEnabled: !!data.tutorialEnabled };

        // Restore timeline data
        State.keyframes    = data.keyframes || [];
        State.durationSec  = data.duration  || 30;
        State.fps          = data.fps       || 30;
        State.nextId       = 1;
        State.keyframes.forEach(kf => { kf.id = State.nextId++; });

        State.textObjects    = data.textObjects || [];
        State.textClips      = data.textClips   || [];
        State.nextTextId     = State.textObjects.reduce((m, o) => Math.max(m, o.id + 1), 1);
        State.nextTextClipId = State.textClips.reduce((m, c) => Math.max(m, c.id + 1), 1);

        // Restore world settings if present and push to Lua
        if (data.worldSettings) {
            State.worldSettings = { ...State.worldSettings, ...data.worldSettings };
            post('setWorldSettings', State.worldSettings);
        }
        if (data.interpSettings) {
            State.interpSettings = { ...State.interpSettings, ...data.interpSettings };
            post('setInterpSettings', State.interpSettings);
            const isMode    = document.getElementById('is-mode');
            const isTension = document.getElementById('is-tension');
            const isTensNum = document.getElementById('is-tension-num');
            const isSpring  = document.getElementById('is-spring');
            const isSprNum  = document.getElementById('is-spring-num');
            if (isMode)    isMode.value    = State.interpSettings.mode;
            if (isTension) isTension.value = State.interpSettings.tension;
            if (isTensNum) isTensNum.value = State.interpSettings.tension.toFixed(2);
            if (isSpring)  isSpring.value  = State.interpSettings.spring;
            if (isSprNum)  isSprNum.value  = State.interpSettings.spring.toFixed(2);
            if (CC._updateInterpHint) CC._updateInterpHint(State.interpSettings.mode);
        }

        // Restore recording block timing (frame data restored by Lua)
        State.vehicleRecStart  = data.vehicleRecStart  || 0;
        State.vehicleRecEnd    = data.vehicleRecEnd    || 0;
        State.vehicleRecTrimIn = data.vehicleRecTrimIn || 0;

        // Overlay layer loading placeholders — show the striped loading bar on each
        // overlay track immediately using the saved timings from the project JSON.
        // Real layers replace these when overlayLayersLoaded arrives.
        const olTimings = Array.isArray(data.overlayLayerTimings) ? data.overlayLayerTimings : [];
        if (olTimings.length > 0) {
            State.overlayLayers = olTimings.map(t => ({
                id:          t.id,
                name:        t.name || 'Layer ' + t.id,
                model:       '',
                loading:     true,
                duration:    0,
                totalFrames: 0,
                startFrame:  Math.floor((t.startSec || 0) * State.fps),
                endFrame:    t.endSec ? Math.floor(t.endSec * State.fps) : Math.floor((t.startSec || 0) * State.fps) + 1,
                trimInFrame: Math.floor((t.trimInSec || 0) * State.fps),
            }));
        } else {
            State.overlayLayers = [];
        }

        document.getElementById('duration-input').value = State.durationSec;
        document.getElementById('tb-project-name').textContent = data.name || data.slug;

        // Restore relationship groups — coerce stray object payloads back to array
        State.relGroups = Array.isArray(data.relGroups) ? data.relGroups : [{ name: 'Director', color: '#4a9df0' }];
        if (data.relMatrix && !Array.isArray(data.relMatrix)) {
            State.relMatrix = data.relMatrix;
        } else {
            State.relMatrix = {};
        }

        // Restore scene entities with ALL their settings
        if (data.sceneEntities && data.sceneEntities.length > 0) {
            State.sceneEntities.forEach(ent => post('deleteSceneEntity', { entityId: ent.id }));
            State.sceneEntities = data.sceneEntities;
            State.nextSceneId   = data.nextSceneId || State.sceneEntities.reduce((m, e) => Math.max(m, e.id + 1), 1);
            // Send full entity data to Lua for spawn + restore
            post('sceneRestoreAll', {
                entities: State.sceneEntities,
                relGroups: State.relGroups,
                relMatrix: State.relMatrix,
            });
        }

        syncKeyframesToLua(); syncTextToLua();
        renderTimeline(); updateTimecodeDisplay(); hideSidePanel();
        hideProjectOverlay();
        document.getElementById('tb-project-name').textContent = data.name || data.slug;
        startAutoSave();
        showToast(t('project.loaded', { name: (data.name || data.slug) }));
        if (State.currentProject.tutorialEnabled) setTimeout(() => Tutorial.start(), 800);
    } catch (err) {
        showToast(t('errors.load_failed', { error: err.message }), 'error');
    }
}

function onProjectSaved(slug) {
    document.getElementById('tb-autosave-status').textContent = t('project.autosave_saved');
    setTimeout(() => {
        document.getElementById('tb-autosave-status').textContent = '';
    }, 2000);
}

function onProjectDeleted(slug) {
    State.projectList = State.projectList.filter(p => p.slug !== slug);
    renderProjectList();
    if (State.currentProject && State.currentProject.slug === slug) {
        // Deleted project was active — full wipe and fall back to list
        wipeProjectStateFull();
        renderTimeline(); updateTimecodeDisplay(); hideSidePanel();
        showProjectOverlay();
    }
    showToast(t('project.deleted'));
}

function getProjectData() {
    if (!State.currentProject) return null;
    return {
        slug:            State.currentProject.slug,
        name:            State.currentProject.name,
        createdAt:       State.currentProject.createdAt,
        updatedAt:       Math.floor(Date.now() / 1000),
        version:         1,
        fps:             State.fps,
        duration:        State.durationSec,
        keyframes:       State.keyframes,
        textObjects:     State.textObjects,
        textClips:       State.textClips,
        worldSettings:   State.worldSettings,
        interpSettings:  State.interpSettings,
        vehicleRecStart:  State.vehicleRecStart,
        vehicleRecEnd:    State.vehicleRecEnd,
        vehicleRecTrimIn: State.vehicleRecTrimIn,
        sceneEntities:    State.sceneEntities,
        nextSceneId:      State.nextSceneId,
        relGroups:        State.relGroups,
        relMatrix:        State.relMatrix,
        tutorialEnabled:  !!State.currentProject.tutorialEnabled,
    };
}

function autoSaveProject() {
    if (!State.currentProject) return;
    const data = getProjectData();
    if (!data) return;
    document.getElementById('tb-autosave-status').textContent = t('project.autosave_saving');
    // Autosave only saves metadata (keyframes, text, settings, trim values).
    // Recording data is saved once when a recording finishes — not on every autosave.
    post('saveProjectMetadata', data);
}

function startAutoSave() {
    if (State.autoSaveTimer) clearInterval(State.autoSaveTimer);
    State.autoSaveTimer = setInterval(() => {
        if (State.currentProject) autoSaveProject();
    }, State.autosaveInterval || 30000); // auto-save interval from Config
}

// Mark dirty on any keyframe/text change so auto-save catches it
const _origSyncKf   = typeof syncKeyframesToLua === 'function' ? syncKeyframesToLua : null;
const _origSyncText = typeof syncTextToLua === 'function' ? syncTextToLua : null;

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL BROWSER (visual ped/vehicle selector with images from FiveM docs)
// ═══════════════════════════════════════════════════════════════════════════════

const MODEL_DATA = {
    ped: {
        'Ambient Male': ['a_m_m_afriamer_01','a_m_m_beach_01','a_m_m_beach_02','a_m_m_bevhills_01','a_m_m_bevhills_02','a_m_m_business_01','a_m_m_eastsa_01','a_m_m_eastsa_02','a_m_m_farmer_01','a_m_m_fatlatin_01','a_m_m_genfat_01','a_m_m_genfat_02','a_m_m_golfer_01','a_m_m_hasjew_01','a_m_m_hillbilly_01','a_m_m_hillbilly_02','a_m_m_indian_01','a_m_m_ktown_01','a_m_m_malibu_01','a_m_m_mexcntry_01','a_m_m_mexlabor_01','a_m_m_og_boss_01','a_m_m_paparazzi_01','a_m_m_polynesian_01','a_m_m_prolhost_01','a_m_m_rurmeth_01','a_m_m_salton_01','a_m_m_salton_02','a_m_m_salton_03','a_m_m_salton_04','a_m_m_skater_01','a_m_m_skidrow_01','a_m_m_socenlat_01','a_m_m_soucent_01','a_m_m_soucent_02','a_m_m_soucent_03','a_m_m_soucent_04','a_m_m_stlat_02','a_m_m_tennis_01','a_m_m_tourist_01','a_m_m_tramp_01','a_m_m_trampbeac_01','a_m_m_tranvest_01','a_m_m_tranvest_02'],
        'Ambient Female': ['a_f_m_beach_01','a_f_m_bevhills_01','a_f_m_bevhills_02','a_f_m_bodybuild_01','a_f_m_business_02','a_f_m_downtown_01','a_f_m_eastsa_01','a_f_m_eastsa_02','a_f_m_fatbla_01','a_f_m_fatcult_01','a_f_m_fatwhite_01','a_f_m_ktown_01','a_f_m_ktown_02','a_f_m_prolhost_01','a_f_m_salton_01','a_f_m_skidrow_01','a_f_m_soucent_01','a_f_m_soucent_02','a_f_m_soucentmc_01','a_f_m_tourist_01','a_f_m_tramp_01','a_f_m_trampbeac_01'],
        'Ambient Young Male': ['a_m_y_beach_01','a_m_y_beach_02','a_m_y_beach_03','a_m_y_beachvesp_01','a_m_y_beachvesp_02','a_m_y_bevhills_01','a_m_y_bevhills_02','a_m_y_breakdance_01','a_m_y_busicas_01','a_m_y_business_01','a_m_y_business_02','a_m_y_business_03','a_m_y_cyclist_01','a_m_y_dhill_01','a_m_y_downtown_01','a_m_y_eastsa_01','a_m_y_eastsa_02','a_m_y_epsilon_01','a_m_y_epsilon_02','a_m_y_gay_01','a_m_y_gay_02','a_m_y_genstreet_01','a_m_y_genstreet_02','a_m_y_golfer_01','a_m_y_hasjew_01','a_m_y_hippy_01','a_m_y_hipster_01','a_m_y_hipster_02','a_m_y_hipster_03','a_m_y_indian_01','a_m_y_jetski_01','a_m_y_juggalo_01','a_m_y_ktown_01','a_m_y_ktown_02','a_m_y_latino_01','a_m_y_methhead_01','a_m_y_mexthug_01','a_m_y_motox_01','a_m_y_motox_02','a_m_y_musclbeac_01','a_m_y_musclbeac_02','a_m_y_polynesian_01','a_m_y_roadcyc_01','a_m_y_runner_01','a_m_y_runner_02','a_m_y_salton_01','a_m_y_skater_01','a_m_y_skater_02','a_m_y_soucent_01','a_m_y_soucent_02','a_m_y_soucent_03','a_m_y_soucent_04','a_m_y_stbla_01','a_m_y_stbla_02','a_m_y_stlat_01','a_m_y_stwhi_01','a_m_y_stwhi_02','a_m_y_sunbathe_01','a_m_y_surfer_01','a_m_y_vindouche_01','a_m_y_vinewood_01','a_m_y_vinewood_02','a_m_y_vinewood_03','a_m_y_vinewood_04','a_m_y_yoga_01'],
        'Ambient Young Female': ['a_f_y_beach_01','a_f_y_bevhills_01','a_f_y_bevhills_02','a_f_y_bevhills_03','a_f_y_bevhills_04','a_f_y_business_01','a_f_y_business_02','a_f_y_business_03','a_f_y_business_04','a_f_y_eastsa_01','a_f_y_eastsa_02','a_f_y_eastsa_03','a_f_y_epsilon_01','a_f_y_fitness_01','a_f_y_fitness_02','a_f_y_genhot_01','a_f_y_golfer_01','a_f_y_hiker_01','a_f_y_hippie_01','a_f_y_hipster_01','a_f_y_hipster_02','a_f_y_hipster_03','a_f_y_hipster_04','a_f_y_indian_01','a_f_y_juggalo_01','a_f_y_runner_01','a_f_y_rurmeth_01','a_f_y_scdressy_01','a_f_y_skater_01','a_f_y_soucent_01','a_f_y_soucent_02','a_f_y_soucent_03','a_f_y_tennis_01','a_f_y_topless_01','a_f_y_tourist_01','a_f_y_tourist_02','a_f_y_vinewood_01','a_f_y_vinewood_02','a_f_y_vinewood_03','a_f_y_vinewood_04','a_f_y_yoga_01'],
        'Law Enforcement': ['s_m_y_cop_01','s_f_y_cop_01','s_m_y_sheriff_01','s_f_y_sheriff_01','s_m_y_hwaycop_01','s_m_m_ciasec_01','s_m_y_ranger_01','s_f_y_ranger_01','s_m_y_swat_01','s_m_y_marine_01','s_m_y_marine_02','s_m_y_marine_03','s_m_m_marine_01','s_m_m_marine_02','s_m_y_pilot_01','s_m_m_prisguard_01','s_m_y_prisguard_01','csb_cop','s_m_y_uscg_01'],
        'Emergency': ['s_m_y_fireman_01','s_m_m_paramedic_01','s_m_y_paramedic_01','s_m_m_doctor_01','s_m_y_autopsy_01','s_f_y_scrubs_01'],
        'Service Workers': ['s_m_m_bouncer_01','s_m_y_doorman_01','s_m_y_valet_01','s_m_y_waiter_01','s_f_y_bartender_01','s_m_m_janitor','s_m_y_garbage','s_m_y_busboy_01','s_m_y_chef_01','s_f_m_maid_01','s_m_y_airworker','s_m_y_construct_01','s_m_y_construct_02','s_m_m_lifeinvad_01','s_m_m_linecook','s_m_m_cntrybar_01'],
        'Gang Members': ['g_m_y_famca_01','g_m_y_famdnf_01','g_m_y_famfor_01','g_m_y_lost_01','g_m_y_lost_02','g_m_y_lost_03','g_f_y_lost_01','g_m_y_mexgang_01','g_m_y_mexgoon_01','g_m_y_mexgoon_02','g_m_y_mexgoon_03','g_m_y_pologoon_01','g_m_y_pologoon_02','g_m_y_salvaboss_01','g_m_y_salvagoon_01','g_m_y_salvagoon_02','g_m_y_salvagoon_03','g_m_y_strpunk_01','g_m_y_strpunk_02','g_m_y_ballaeast_01','g_m_y_ballaorig_01','g_m_y_ballasout_01','g_f_y_ballas_01','g_m_y_korean_01','g_m_y_korean_02','g_m_y_korlieut_01','g_m_m_armboss_01','g_m_m_armgoon_01','g_m_m_armlieut_01','g_m_m_chemwork_01','g_m_m_chiboss_01','g_m_m_chicold_01','g_m_m_chigoon_01','g_m_m_chigoon_02','g_m_m_korboss_01','g_m_m_mexboss_01','g_m_m_mexboss_02'],
        'Story Characters': ['player_zero','player_one','player_two','ig_abigail','ig_amandatownley','ig_andreas','ig_ashley','ig_ballasog','ig_bankman','ig_barry','ig_bestmen','ig_beverly','ig_brad','ig_bride','ig_car3guy1','ig_casey','ig_chef','ig_clay','ig_claypain','ig_cletus','ig_dale','ig_davenorton','ig_denise','ig_devin','ig_dom','ig_dreyfuss','ig_drfriedlander','ig_fabien','ig_fbisuit_01','ig_floyd','ig_groom','ig_hao','ig_hunter','ig_janet','ig_jay_norris','ig_jewelass','ig_jimmyboston','ig_jimmydisanto','ig_joeminuteman','ig_johnnyklebitz','ig_josef','ig_josh','ig_lamardavis','ig_lazlow','ig_lestercrest','ig_lifeinvad_01','ig_lifeinvad_02','ig_magenta','ig_manuel','ig_marnie','ig_maryann','ig_maude','ig_michelle','ig_milton','ig_molly','ig_mrk','ig_mrs_thornhill','ig_natalia','ig_nervousron','ig_nigel','ig_old_man1a','ig_old_man2','ig_omega','ig_oneil','ig_ortega','ig_paper','ig_patricia','ig_priest','ig_prolsec_02','ig_ramp_gang','ig_ramp_hic','ig_ramp_hipster','ig_ramp_mex','ig_roccopelosi','ig_russiandrunk','ig_screen_writer','ig_siemonyetarian','ig_solomon','ig_stevehains','ig_stretch','ig_talina','ig_tanisha','ig_taocheng','ig_taostranslator','ig_tenniscoach','ig_terry','ig_tomepsilon','ig_tonya','ig_tracydisanto','ig_tylerdix','ig_wade','ig_zimbor'],
    },
    vehicle: {
        'Super': ['adder','autarch','banshee2','bullet','cheetah','cyclone','deveste','emerus','entityxf','entity2','fmj','furia','gp1','italigtb','italigtb2','krieger','le7b','nero','nero2','osiris','penetrator','pfister811','prototipo','reaper','s80','sc1','scramjet','sheava','sultanrs','t20','taipan','tempesta','tezeract','thrax','turismor','tyrant','tyrus','vacca','vagner','visione','voltic','xa21','zentorno','zorrusso'],
        'Sports': ['alpha','banshee','bestia','buffalo','buffalo2','buffalo3','carbonizzare','comet2','comet3','comet4','comet5','coquette','drafter','elegy','elegy2','feltzer2','flashgt','furoregt','fusilade','futo','gb200','hotring','imorgon','issi7','italigto','jester','jester2','jogger','khamelion','komoda','kuruma','kuruma2','locust','lynx','massacro','massacro2','neo','neon','ninef','ninef2','omnis','paragon','paragon2','pariah','penumbra','penumbra2','raiden','rapidgt','rapidgt2','raptor','revolter','ruston','schafter2','schafter3','schafter4','schafter5','schafter6','schlagen','schwarzer','sentinel3','seven70','specter','specter2','sultan','sultan2','surano','swinger','tropos','verlierer2','vstr','zr380','zr3802','zr3803'],
        'Muscle': ['blade','buccaneer','buccaneer2','chino','chino2','clique','coquette3','deviant','dominator','dominator2','dominator3','dominator4','dominator5','dominator6','dukes','dukes2','ellie','faction','faction2','faction3','gauntlet','gauntlet2','gauntlet3','gauntlet4','hermes','hotknife','hustler','impaler','impaler2','impaler3','impaler4','imperator','imperator2','imperator3','lurcher','moonbeam','moonbeam2','nightshade','peyote','peyote2','phoenix','picador','ratloader','ratloader2','ruiner','ruiner2','ruiner3','sabregt','sabregt2','slamvan','slamvan2','slamvan3','stalion','stalion2','tampa','tampa3','tulip','vamos','vigero','virgo','virgo2','virgo3','voodoo','voodoo2','yosemite','yosemite2'],
        'Sports Classics': ['ardent','btype','btype2','btype3','casco','cheburek','cheetah2','coquette2','deluxo','dynasty','fagaloa','feltzer3','gt500','infernus2','jb700','jb7002','mamba','manana','manana2','michelli','monroe','nebula','peyote3','pigalle','rapidgt3','retinue','retinue2','savestra','stinger','stingergt','stromberg','swinger','torero','tornado','tornado2','tornado3','tornado4','tornado5','tornado6','turismo2','viseris','z190','ztype'],
        'Sedan': ['asea','asea2','asterope','cog55','cog552','cognoscenti','cognoscenti2','emperor','emperor2','emperor3','fugitive','glendale','glendale2','ingot','intruder','limo2','premier','primo','primo2','regina','schafter2','stafford','stanier','stratum','stretch','surge','tailgater','warrener','washington'],
        'SUV': ['baller','baller2','baller3','baller4','baller5','baller6','bjxl','cavalcade','cavalcade2','contender','dubsta','dubsta2','fq2','granger','gresley','habanero','huntley','landstalker','landstalker2','mesa','mesa2','mesa3','novak','patriot','patriot2','radi','rebla','rocoto','seminole','seminole2','serrano','squaddie','toros','xls','xls2'],
        'Pickup': ['bison','bobcatxl','bodhi2','dubsta3','kamacho','mesa3','sandking','sandking2','yosemite','yosemite2'],
        'Emergency': ['ambulance','fbi','fbi2','firetruk','lguard','pbus','police','police2','police3','police4','policeb','policeold1','policeold2','policet','polmav','pranger','predator','riot','riot2','sheriff','sheriff2'],
        'Military': ['apc','barrage','chernobog','crusader','halftrack','khanjali','minitank','rhino','scarab','scarab2','scarab3','thruster','trailersmall2'],
        'Motorcycle': ['akuma','avarus','bagger','bati','bati2','bf400','carbonrs','chimera','cliffhanger','daemon','daemon2','defiler','deathbike','deathbike2','deathbike3','diablous','diablous2','double','enduro','esskey','faggio','faggio2','faggio3','fcr','fcr2','gargoyle','hakuchou','hakuchou2','hexer','innovation','lectro','manchez','nemesis','nightblade','oppressor','oppressor2','pcj','ratbike','ruffian','sanchez','sanchez2','sanctus','shotaro','sovereign','thrust','vader','vindicator','vortex','wolfsbane','zombiea','zombieb'],
        'Helicopter': ['akula','annihilator','buzzard','buzzard2','cargobob','cargobob2','cargobob3','cargobob4','frogger','frogger2','havok','hunter','maverick','savage','seasparrow','skylift','supervolito','supervolito2','swift','swift2','valkyrie','valkyrie2','volatus'],
        'Plane': ['alphaz1','avenger','avenger2','besra','bombushka','cuban800','dodo','duster','howard','hydra','lazer','luxor','luxor2','mammatus','microlight','miljet','mogul','molotok','nimbus','nokota','pyro','rogue','seabreeze','shamal','starling','strikeforce','titan','tula','ultralight','velum','velum2','vestra','volatol'],
        'Boat': ['avisa','dinghy','dinghy2','dinghy3','dinghy4','jetmax','kosatka','marquis','predator','seashark','seashark2','seashark3','speeder','speeder2','squalo','submersible','submersible2','suntrap','toro','toro2','tropic','tropic2','tug'],
    }
};

State.modelBrowserMode = null; // 'ped' | 'vehicle'

CC.openModelBrowser = function(mode) {
    State.modelBrowserMode = mode;
    document.getElementById('model-browser').classList.remove('hidden');
    document.getElementById('mb-title').textContent = mode === 'ped' ? t('scene.select_ped_model') : t('scene.select_vehicle_model');
    document.getElementById('mb-search').value = '';
    renderModelBrowser();
};

CC.closeModelBrowser = function() {
    document.getElementById('model-browser').classList.add('hidden');
    State.modelBrowserMode = null;
};

function renderModelBrowser(filter) {
    const mode = State.modelBrowserMode;
    const data = MODEL_DATA[mode];
    if (!data) return;

    const cats    = document.getElementById('mb-categories');
    const search  = (filter || '').toLowerCase();

    // Build category list
    cats.innerHTML = '';
    const catNames = Object.keys(data);
    const validCats = [];
    catNames.forEach(catName => {
        let models = data[catName];
        if (search) models = models.filter(m => m.includes(search));
        if (models.length === 0) return;
        validCats.push({ name: catName, models });

        const catBtn = document.createElement('div');
        catBtn.className = 'mb-cat';
        const _catKey = 'scene.model_cat_' + catName.toLowerCase().replace(/[^a-z0-9]+/g, '_');
        const _catTr = t(_catKey);
        catBtn.textContent = (_catTr === _catKey ? catName : _catTr) + ' (' + models.length + ')';
        catBtn.addEventListener('click', () => {
            cats.querySelectorAll('.mb-cat').forEach(c => c.classList.remove('active'));
            catBtn.classList.add('active');
            renderModelCategory(mode, models);
        });
        cats.appendChild(catBtn);
    });

    // Auto-select first category
    if (validCats.length > 0) {
        cats.querySelector('.mb-cat').classList.add('active');
        renderModelCategory(mode, validCats[0].models);
    } else {
        document.getElementById('mb-grid').innerHTML = `<div style="grid-column:1/-1;text-align:center;color:#555;padding:40px">${t('scene.no_models_found')}</div>`;
    }
}

function renderModelCategory(mode, models) {
    const grid    = document.getElementById('mb-grid');
    const wrap    = document.getElementById('mb-grid-wrap');
    const imgBase = mode === 'ped' ? 'https://docs.fivem.net/peds/' : 'https://docs.fivem.net/vehicles/';
    const imgExt  = '.webp';

    grid.innerHTML = '';
    wrap.scrollTop = 0;

    const frag = document.createDocumentFragment();
    models.forEach(model => {
        const card = document.createElement('div');
        card.className = 'mb-card';
        card.innerHTML = `<div class="mb-card-img-wrap"><img class="mb-card-img${mode === 'vehicle' ? ' vehicle-img' : ''}" data-src="${imgBase}${model}${imgExt}" alt="${model}" onerror="this.style.display='none'"></div><div class="mb-card-name">${model}</div>`;
        card.addEventListener('click', () => {
            document.getElementById(mode === 'ped' ? 'se-ped-model' : 'se-veh-model').value = model;
            CC.closeModelBrowser();
        });
        frag.appendChild(card);
    });
    grid.appendChild(frag);

    // Lazy load images
    if (window._mbObserver) window._mbObserver.disconnect();
    window._mbObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                if (img.dataset.src && !img.src) img.src = img.dataset.src;
                window._mbObserver.unobserve(img);
            }
        });
    }, { root: wrap, rootMargin: '300px' });
    grid.querySelectorAll('img[data-src]').forEach(img => window._mbObserver.observe(img));
}

// Search handler — searches across ALL categories, renders results directly
document.getElementById('mb-search').addEventListener('input', (e) => {
    const search = e.target.value.trim().toLowerCase();
    if (!search) {
        renderModelBrowser(); // no search = back to category view
        return;
    }
    // Search across all categories
    const mode = State.modelBrowserMode;
    const data = MODEL_DATA[mode];
    if (!data) return;
    const results = [];
    for (const models of Object.values(data)) {
        models.forEach(m => { if (m.includes(search)) results.push(m); });
    }
    // Clear category active state
    document.querySelectorAll('#mb-categories .mb-cat').forEach(c => c.classList.remove('active'));
    renderModelCategory(mode, results);
});

// ESC to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && State.modelBrowserMode) {
        CC.closeModelBrowser();
    }
});

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM DROPDOWN (replaces native <select class="sp-select">)
// ═══════════════════════════════════════════════════════════════════════════════

function initCustomDropdowns() {
    document.querySelectorAll('select.sp-select').forEach(sel => {
        if (sel.dataset.ccInit) return; // already initialized
        sel.dataset.ccInit = '1';

        const wrapper = document.createElement('div');
        wrapper.className = 'cc-dropdown';

        const trigger = document.createElement('div');
        trigger.className = 'cc-dropdown-trigger';
        trigger.innerHTML = `<span class="cc-dropdown-label"></span><i class="fa-solid fa-chevron-down cc-dropdown-arrow"></i>`;

        const menu = document.createElement('div');
        menu.className = 'cc-dropdown-menu';

        sel.parentNode.insertBefore(wrapper, sel);
        wrapper.appendChild(trigger);
        wrapper.appendChild(menu);
        wrapper.appendChild(sel); // keep select inside for value access

        function buildOptions() {
            menu.innerHTML = '';
            Array.from(sel.options).forEach((opt, i) => {
                const item = document.createElement('div');
                item.className = 'cc-dropdown-option' + (i === sel.selectedIndex ? ' selected' : '');
                item.textContent = opt.textContent;
                item.dataset.value = opt.value;
                if (opt.style.fontFamily) item.style.fontFamily = opt.style.fontFamily;
                item.addEventListener('click', (e) => {
                    e.stopPropagation();
                    sel.value = opt.value;
                    sel.dispatchEvent(new Event('change'));
                    updateLabel();
                    wrapper.classList.remove('open');
                });
                menu.appendChild(item);
            });
        }

        function updateLabel() {
            const lbl = trigger.querySelector('.cc-dropdown-label');
            const opt = sel.options[sel.selectedIndex];
            lbl.textContent = opt ? opt.textContent : '';
            lbl.style.fontFamily = opt && opt.style.fontFamily ? opt.style.fontFamily : '';
            // Update selected class
            menu.querySelectorAll('.cc-dropdown-option').forEach((el, i) => {
                el.classList.toggle('selected', i === sel.selectedIndex);
            });
        }

        trigger.addEventListener('click', (e) => {
            e.stopPropagation();
            // Close all other dropdowns
            document.querySelectorAll('.cc-dropdown.open').forEach(d => {
                if (d !== wrapper) d.classList.remove('open');
            });
            buildOptions();
            // Position menu using fixed coords from trigger rect
            const rect = trigger.getBoundingClientRect();
            menu.style.left  = rect.left + 'px';
            menu.style.width = rect.width + 'px';
            // Check if menu would overflow bottom of screen
            const spaceBelow = window.innerHeight - rect.bottom - 8;
            if (spaceBelow < 180) {
                // Open upward
                menu.style.top    = '';
                menu.style.bottom = (window.innerHeight - rect.top + 4) + 'px';
            } else {
                // Open downward
                menu.style.top    = (rect.bottom + 4) + 'px';
                menu.style.bottom = '';
            }
            wrapper.classList.toggle('open');
        });

        buildOptions();
        updateLabel();

        // Observe select for programmatic value changes (DOM mutations + child option updates)
        const observer = new MutationObserver(() => { buildOptions(); updateLabel(); });
        observer.observe(sel, { childList: true, subtree: true, attributes: true });

        // Sync label when value changes externally (e.g. from user-triggered change events)
        sel.addEventListener('change', () => updateLabel());

        // Patch the .value property setter so programmatic assignments like
        // `select.value = 'foo'` also refresh the custom dropdown label
        // (the built-in setter doesn't fire a mutation or change event).
        const proto    = Object.getPrototypeOf(sel);
        const origDesc = Object.getOwnPropertyDescriptor(proto, 'value');
        if (origDesc && !sel.__ccValuePatched) {
            sel.__ccValuePatched = true;
            Object.defineProperty(sel, 'value', {
                configurable: true,
                get() { return origDesc.get.call(this); },
                set(v) { origDesc.set.call(this, v); updateLabel(); },
            });
        }
    });
}

// Close dropdowns when clicking anywhere
document.addEventListener('click', () => {
    document.querySelectorAll('.cc-dropdown.open').forEach(d => d.classList.remove('open'));
});

// ── TUTORIAL ──────────────────────────────────────────────────────────────────
const Tutorial = (function() {
    const root       = () => document.getElementById('tut-root');
    const highlight  = () => document.getElementById('tut-highlight');
    const tooltip    = () => document.getElementById('tut-tooltip');
    const titleEl    = () => document.getElementById('tut-tip-title');
    const bodyEl     = () => document.getElementById('tut-tip-body');
    const stepEl     = () => document.getElementById('tut-tip-step');
    const hintEl     = () => document.getElementById('tut-tip-hint');

    let active = false, stepIdx = -1, interval = null, startFrame = 0, startKfCount = 0, camStart = null;

    const steps = [
        {
            get title() { return t('tutorial.s1_title'); },
            get body()  { return t('tutorial.s1_body'); },
            target: '[data-tut="recordings-menu"]',
            advanceEvent: 'tut:openedRecordings',
            get hint() { return t('tutorial.s1_hint'); },
        },
        {
            get title() { return t('tutorial.s2_title'); },
            get body()  { return t('tutorial.s2_body'); },
            target: '[data-tut="start-record"]',
            advanceEvent: 'tut:recordingStarted',
            get hint() { return t('tutorial.s2_hint'); },
            beforeClick: () => { post('tutorialSpawnAdder'); },
        },
        {
            get title() { return t('tutorial.s3_title'); },
            get body()  { return t('tutorial.s3_body'); },
            target: null,
            advanceEvent: 'tut:recordingStopped',
            get hint() { return t('tutorial.s3_hint'); },
            showWhenUIClosed: true,
        },
        {
            get title() { return t('tutorial.s4_title'); },
            get body()  { return t('tutorial.s4_body'); },
            target: '[data-tut="add-keyframe"]',
            advanceEvent: 'tut:keyframeAdded',
            get hint() { return t('tutorial.s4_hint'); },
        },
        {
            get title() { return t('tutorial.s5_title'); },
            get body()  { return t('tutorial.s5_body'); },
            target: '#sp-pos-btn',
            advanceEvent: 'tut:positionSaved',
            get hint() { return t('tutorial.s5_hint'); },
        },
        {
            get title() { return t('tutorial.s6_title'); },
            get body()  { return t('tutorial.s6_body'); },
            target: '#timeline-scroll-wrap',
            advanceEvent: 'tut:scrubbed',
            tooltipPlacement: 'above',
            get hint() { return t('tutorial.s6_hint'); },
            onEnter: () => { startFrame = State.currentFrame; },
        },
        {
            get title() { return t('tutorial.s7_title'); },
            get body()  { return t('tutorial.s7_body'); },
            target: '[data-tut="add-keyframe"]',
            advanceEvent: 'tut:keyframeAdded',
            get hint() { return t('tutorial.s7_hint'); },
        },
        {
            get title() { return t('tutorial.s8_title'); },
            get body()  { return t('tutorial.s8_body'); },
            target: '#sp-pos-btn',
            advanceEvent: 'tut:positionSaved',
            get hint() { return t('tutorial.s8_hint'); },
        },
        {
            get title() { return t('tutorial.s9_title'); },
            get body()  { return t('tutorial.s9_body'); },
            target: '#timeline-scroll-wrap',
            advanceEvent: 'tut:scrubbed',
            tooltipPlacement: 'above',
            get hint() { return t('tutorial.s9_hint'); },
            onEnter: () => { startFrame = State.currentFrame; },
        },
        {
            get title() { return t('tutorial.s10_title'); },
            get body()  { return t('tutorial.s10_body'); },
            target: '[data-tut="add-keyframe"]',
            advanceEvent: 'tut:keyframeAdded',
            get hint() { return t('tutorial.s10_hint'); },
        },
        {
            get title() { return t('tutorial.s11_title'); },
            get body()  { return t('tutorial.s11_body'); },
            target: '#sp-pos-btn',
            advanceEvent: 'tut:positionSaved',
            get hint() { return t('tutorial.s11_hint'); },
        },
        {
            get title() { return t('tutorial.s12_title'); },
            get body()  { return t('tutorial.s12_body'); },
            target: '#sp-back-btn',
            advanceEvent: 'tut:backToMenu',
            get hint() { return t('tutorial.s12_hint'); },
        },
        {
            get title() { return t('tutorial.s13_title'); },
            get body()  { return t('tutorial.s13_body'); },
            target: '[data-tut="interp-menu"]',
            advanceEvent: 'tut:interpOpened',
            get hint() { return t('tutorial.s13_hint'); },
        },
        {
            get title() { return t('tutorial.s14_title'); },
            get body()  { return t('tutorial.s14_body'); },
            target: () => document.querySelector('#is-mode')?.closest('.cc-dropdown') || document.getElementById('is-mode'),
            advanceEvent: 'tut:interpChanged',
            get hint() { return t('tutorial.s14_hint'); },
        },
        {
            get title() { return t('tutorial.s15_title'); },
            get body()  { return t('tutorial.s15_body'); },
            target: '#play-btn',
            advanceEvent: 'tut:playbackFinished',
            get hint() { return t('tutorial.s15_hint'); },
        },
        {
            get title() { return t('tutorial.s16_title'); },
            get body()  { return t('tutorial.s16_body'); },
            target: null,
            advanceEvent: null,
            get hint() { return t('tutorial.s16_hint'); },
            finalStep: true,
        },
    ];

    function findTarget(sel) {
        if (!sel) return null;
        let el;
        if (typeof sel === 'function') { try { el = sel(); } catch { el = null; } }
        else el = document.querySelector(sel);
        if (!el) return null;
        const r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) return null;
        return el;
    }

    function positionOverlay(el) {
        const hl = highlight();
        const tp = tooltip();
        if (el) {
            const r = el.getBoundingClientRect();
            const pad = 6;
            hl.style.display = '';
            hl.style.left   = (r.left - pad) + 'px';
            hl.style.top    = (r.top  - pad) + 'px';
            hl.style.width  = (r.width  + pad*2) + 'px';
            hl.style.height = (r.height + pad*2) + 'px';
            hl.classList.add('pulse');

            const tw = 320, th = 170;
            const step = steps[stepIdx];
            let left, top;
            if (step && step.tooltipPlacement === 'above') {
                left = Math.max(20, Math.min(window.innerWidth - tw - 20, r.left + r.width/2 - tw/2));
                top  = Math.max(20, r.top - th - 14);
            } else {
                left = r.right + 14;
                top  = r.top;
                if (left + tw > window.innerWidth - 20) left = Math.max(20, r.left - tw - 14);
                if (top  + th > window.innerHeight - 20) top  = Math.max(20, window.innerHeight - th - 20);
            }
            tp.style.left = left + 'px';
            tp.style.top  = top  + 'px';
        } else {
            hl.style.display = 'none';
            hl.classList.remove('pulse');
            tp.style.left = '50%';
            tp.style.top  = '50%';
            tp.style.transform = 'translate(-50%, -50%)';
            return;
        }
        tp.style.transform = '';
    }

    function render() {
        const step = steps[stepIdx];
        if (!step) return end();
        stepEl().textContent = t('tutorial.step_count', { current: stepIdx + 1, total: steps.length });
        titleEl().textContent = step.title;
        bodyEl().innerHTML    = step.body;
        hintEl().textContent  = step.hint || '';
        document.getElementById('tut-skip').textContent = step.finalStep ? t('tutorial.finish') : t('tutorial.skip');

        camStart = step.trackCameraMove && State.currentCamPos
            ? { ...State.currentCamPos } : null;

        const el = findTarget(step.target);
        positionOverlay(el);

        // Re-position on every frame while animating (menu opens can change layout)
        if (interval) clearInterval(interval);
        interval = setInterval(() => {
            const e = findTarget(step.target);
            positionOverlay(e);
        }, 150);

        // "beforeClick" hook: intercept the target click once
        if (step.beforeClick && el) {
            const handler = (ev) => {
                el.removeEventListener('click', handler, true);
                try { step.beforeClick(); } catch(e) {}
            };
            el.addEventListener('click', handler, true);
        }

        // Wire up the advance event
        if (step.advanceEvent) {
            const listener = () => {
                document.removeEventListener(step.advanceEvent, listener);
                next();
            };
            document.addEventListener(step.advanceEvent, listener);
        }
    }

    function next() {
        stepIdx++;
        if (stepIdx >= steps.length) return end();
        render();
    }

    function start() {
        if (active) return;
        active = true;
        stepIdx = -1;
        root().classList.remove('hidden');
        next();
    }

    function end() {
        active = false;
        if (interval) { clearInterval(interval); interval = null; }
        root().classList.add('hidden');
        if (State.currentProject) {
            State.currentProject.tutorialEnabled = false;
            autoSaveProject();
        }
    }

    // Event fanout — call from UI code
    function fire(name) { document.dispatchEvent(new Event(name)); }

    function onUIHidden() {
        const step = steps[stepIdx];
        if (!active) return;
        if (!step || !step.showWhenUIClosed) root().classList.add('hidden');
    }
    function onUIShown() {
        if (!active) return;
        root().classList.remove('hidden');
    }

    function onCoords(pos) {
        if (!active || !camStart || !pos) return;
        const dx = pos.x - camStart.x, dy = pos.y - camStart.y, dz = pos.z - camStart.z;
        if (dx*dx + dy*dy + dz*dz > 9) { // > 3 meters
            camStart = null;
            fire('tut:cameraMoved');
        }
    }


    return { start, end, fire, onCoords, onUIHidden, onUIShown, isActive: () => active };
})();

CC.tutorialSkip = () => Tutorial.end();

function updateWeatherConflictWarning() {
    const warn = document.getElementById('ws-conflict-warn');
    const names = document.getElementById('ws-conflict-names');
    if (!warn || !names) return;
    const list = State.weatherConflicts || [];
    if (list.length === 0) { warn.classList.add('hidden'); return; }
    names.innerHTML = list.map(n => `<b>${n}</b>`).join(', ');
    warn.classList.remove('hidden');
}

// Project list: vertical wheel → horizontal scroll
(() => {
    const list = document.getElementById('po-list');
    if (!list) return;
    list.addEventListener('wheel', (e) => {
        if (list.classList.contains('empty')) return;
        if (e.deltaY === 0) return;
        e.preventDefault();
        list.scrollLeft += e.deltaY;
    }, { passive: false });
})();

// ── INIT ──────────────────────────────────────────────────────────────────────
initCustomDropdowns();
updateTimecodeDisplay();
