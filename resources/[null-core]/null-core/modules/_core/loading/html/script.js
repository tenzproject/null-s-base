// Config (from config.js, with safe fallback)
const CFG = window.LOADING_CONFIG || {};

// Playlist (from config)
const musicList = (CFG.music && CFG.music.length) ? CFG.music : [
    { label: 'AMIRI JEANS X NEW JAZZ (remix)', author: 'Püsshi', src: 'audio/amiri.mp3' },
    { label: 'LIFE X AFTER THE STORM (remix)', author: 'Püsshi', src: 'audio/life.mp3' },
    { label: 'TNF X OVER (remix)', author: 'Püsshi', src: 'audio/tnf.mp3' },
    { label: 'Macarena Remix', author: 'JRK19', src: 'audio/JRK19Macarena.mp3' },
];

// Apply accent + identity from config (overridable later via INIT_CORE convars)
function applyAccent(hex) {
    if (!hex) return;
    document.documentElement.style.setProperty('--primary', hex);
}
applyAccent(CFG.accent);

let audio = new Audio();
let currentSong = 0;
let isPlaying = false;
let userInteracted = false;
let devMode = false;

// DOM Elements
const loadingPhase = document.getElementById('loading-phase');
const enterPhase = document.getElementById('enter-phase');
const blurProposal = document.getElementById('blur-proposal');
const statusText = document.getElementById('status-text');
const progressBar = document.getElementById('progress-fill');
const progressText = document.getElementById('progress-text');
const serverNameEl = document.getElementById('server-name');
const serverLogoEl = document.getElementById('server-logo');

// Music Elements
const playBtn = document.getElementById('play-btn');
const prevBtn = document.getElementById('prev-btn');
const nextBtn = document.getElementById('next-btn');
const trackName = document.getElementById('track-name');
const trackArtist = document.getElementById('track-artist');
const volumeControl = document.getElementById('volume-control');

// Initialize
function init() {
    // Apply config-driven content
    applyConfigContent();

    // Random start song
    currentSong = Math.floor(Math.random() * musicList.length);
    loadTrack(currentSong);

    // Auto-play immediately
    audio.volume = 0.15; // Set direct volume

    audio.play().then(() => {
        isPlaying = true;
        playBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    }).catch(() => { });

    // Keyboard controls for music player
    document.addEventListener('keydown', handleMusicKeys);

    // See More panel
    initSeeMorePanel();
}

function applyConfigContent() {
    // Server name / logo / subtitle
    if (CFG.serverName) serverNameEl.innerText = CFG.serverName;
    if (CFG.serverLogo) serverLogoEl.src = CFG.serverLogo;
    if (CFG.serverSubtitle) {
        const sub = document.querySelector('.server-info .subtitle');
        if (sub) sub.innerText = CFG.serverSubtitle;
    }
    // Inject server name into the enter screen title
    const enterName = document.getElementById('enter-server-name');
    if (enterName && CFG.serverName) {
        // Use only first word to keep "BIENVENUE SUR <NAME>" punchy
        enterName.innerText = String(CFG.serverName).split(' ')[0];
    }
    // Tip
    if (CFG.tip) {
        const tip = document.querySelector('#loading-phase .tips-container p');
        if (tip) tip.innerHTML = '<i class="fa-solid fa-circle-info"></i> ' + CFG.tip;
    }
    // Socials
    if (Array.isArray(CFG.socials) && CFG.socials.length) {
        const wrap = document.querySelector('.socials');
        if (wrap) {
            wrap.innerHTML = CFG.socials.map(s =>
                `<div class="social-item"><i class="${s.icon}"></i><span>${s.label}</span></div>`
            ).join('');
        }
    }
}

// Track Loading
function loadTrack(index) {
    const track = musicList[index];
    audio.src = track.src;
    audio.load();
    trackName.innerText = track.label;
    trackArtist.innerText = track.author;
}

// Play/Pause
function togglePlay() {
    if (isPlaying) {
        audio.pause();
        playBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
    } else {
        audio.play().catch(e => console.log("Autoplay blocked", e));
        playBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    }
    isPlaying = !isPlaying;
}

function nextTrack() {
    currentSong = (currentSong + 1) % musicList.length;
    loadTrack(currentSong);
    if (isPlaying) audio.play();
}

function prevTrack() {
    currentSong = (currentSong - 1 + musicList.length) % musicList.length;
    loadTrack(currentSong);
    if (isPlaying) audio.play();
}

// Event Listeners
playBtn.addEventListener('click', togglePlay);
nextBtn.addEventListener('click', nextTrack);
prevBtn.addEventListener('click', prevTrack);

volumeControl.addEventListener('input', (e) => {
    audio.volume = e.target.value / 100;
});

// Auto next track
audio.addEventListener('ended', nextTrack);

// Keyboard controls for music player (only during loading phase)
function handleMusicKeys(e) {
    // Only work during loading phase
    if (!loadingPhase.classList.contains('active')) return;

    if (e.key === ' ' || e.key === 'Spacebar') {
        e.preventDefault();
        togglePlay();
    } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        nextTrack();
    } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        prevTrack();
    } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        changeVolume(5); // Augmenter de 5%
    } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        changeVolume(-5); // Diminuer de 5%
    }
}

// Change volume function
function changeVolume(delta) {
    let newVolume = parseInt(volumeControl.value) + delta;
    newVolume = Math.max(0, Math.min(100, newVolume)); // Clamp entre 0 et 100
    volumeControl.value = newVolume;
    audio.volume = newVolume / 100;
}

// Loading Progress Logic
let nativeProgress = 0;  // 0-100 from FiveM loadProgress events
let fakeProgress = 0;     // 0-100 from Lua UPDATE_PROGRESS messages
let combinedProgress = 0; // Final combined progress
let audioPlayed = false;

function updateProgress(val) {
    const p = Math.min(100, Math.max(0, val));
    progressBar.style.width = `${p}%`;
    // progressText.innerText = `${Math.floor(p)}%`;
}

function calculateCombinedProgress() {
    // 70% from native FiveM loading, 30% from fake Lua progress
    const nativeContribution = Math.floor(nativeProgress * 0.7);
    const fakeContribution = Math.floor(fakeProgress * 0.3);
    combinedProgress = nativeContribution + fakeContribution;
    updateProgress(combinedProgress);
}

// NUI Messages
window.addEventListener('message', function (event) {
    const data = event.data;

    // Convars setup
    if (data.type === 'INIT_CORE') {
        if (data.serverName) {
            serverNameEl.innerText = data.serverName;
            const enterName = document.getElementById('enter-server-name');
            if (enterName) enterName.innerText = String(data.serverName).split(' ')[0];
        }
        if (data.serverCHAR) serverLogoEl.src = data.serverCHAR;
        if (data.hexcolor) applyAccent(data.hexcolor);
    }

    // Native FiveM Progress (70% du total)
    if (data.eventName === 'loadProgress') {
        nativeProgress = Math.min(data.loadFraction * 100, 100);
        calculateCombinedProgress();
    }

    // Fake Lua Progress (30% du total)
    if (data.type === 'UPDATE_PROGRESS') {
        fakeProgress = Math.min(data.progress || 0, 100);
        if (data.message) statusText.innerText = data.message;
        calculateCombinedProgress();
    }

    // Log lines
    if (data.eventName === 'onLogLine') {
        statusText.innerText = data.message;
    }

    // Switch to Enter Screen
    if (data.type === 'SHOW_ENTER_SCREEN') {
        showEnterScreen(data.playerData);
        bindEnterAction();
    }

    // Show Blur Proposal (between loading and enter phase)
    if (data.type === 'SHOW_BLUR_PROPOSAL') {
        showBlurProposal();
    }

    // Blur proposal done -> proceed to enter screen
    if (data.type === 'BLUR_PROPOSAL_DONE') {
        blurProposalDone(data.playerData);
    }

    // Handle Trigger Enter (from Lua)
    if (data.type === 'TRIGGER_ENTER') {
        triggerEnter();
    }

    // Handle Fade Out
    if (data.type === 'FADE_OUT') {
        fadeOut();
    }
});

// Safety fallback timer for triggerEnter (see triggerEnter() below).
let _triggerEnterFallbackTimer = null;

function showBlurProposal() {
    document.body.classList.remove('shutters-hidden');
    document.body.classList.add('shutters-covering');

    setTimeout(() => {
        loadingPhase.classList.add('hidden');
        loadingPhase.classList.remove('active');

        const bgImg = document.querySelector('.bg-image');
        if (bgImg) bgImg.style.opacity = '0';

        if (blurProposal) {
            blurProposal.classList.remove('hidden');
            setTimeout(() => {
                blurProposal.classList.add('active');
            }, 50);
        }

        document.body.classList.remove('shutters-covering');
        document.body.classList.add('shutters-hidden');
    }, 1300);
}

function blurProposalDone(playerData) {
    document.body.classList.remove('shutters-hidden');
    document.body.classList.add('shutters-covering');

    setTimeout(() => {
        if (blurProposal) {
            blurProposal.classList.add('hidden');
            blurProposal.classList.remove('active');
        }
        showEnterScreen(playerData);
        bindEnterAction();
    }, 1300);
}

function showEnterScreen(playerData) {
    // Update player info if provided
    if (playerData) {
        updatePlayerInfo(playerData);
    }

    if (devMode) {
        updatePlayerInfo({
            firstname: "",
            lastname: "",
            sex: "",
            vip: {
                isVip: true,
                type: "Basic",
                time: {
                    days: 39,
                    hours: 0,
                    minutes: 0,
                    remaining: 232800
                },
            },
            accounts: {
                cash: 100,
                dirtycash: 100,
                bank: 100,
            },
            playtime: 120,

        });
    }

    // Step 1: Shutters couvrent l'écran (noir complet)
    document.body.classList.remove('shutters-hidden');
    document.body.classList.add('shutters-covering');

    setTimeout(() => {
        // Step 2: Hide loading phase
        loadingPhase.classList.add('hidden');
        loadingPhase.classList.remove('active');

        // Disable blur effects for FiveM game view compatibility
        document.body.classList.add('no-blur');

        // Fade out background image to show game camera
        const bgImg = document.querySelector('.bg-image');
        if (bgImg) {
            bgImg.style.opacity = '0';
        }

        // Step 3: Show enter phase
        enterPhase.classList.remove('hidden');
        setTimeout(() => {
            enterPhase.classList.add('active');
        }, 50);

        // Step 4: Shutters deviennent visibles (bordures)
        setTimeout(() => {
            document.body.classList.remove('shutters-covering');
            document.body.classList.add('shutters-visible');
        }, 100);

        // Step 5: Bring header to front
        setTimeout(() => {
            const header = document.querySelector('.header');
            if (header) header.style.zIndex = '1000';
        }, 600);

    }, 1200); // Wait for shutters to cover
}

function updatePlayerInfo(data) {
    document.querySelector('.music-player').style.opacity = '0';
    document.querySelector('.socials').style.opacity = '0';

    setTimeout(() => {
        document.querySelector('.footer').style.zIndex = '1000';
    }, 2000);

    // Show player info sections
    const headerInfo = document.querySelector('.player-info-header');
    const footerInfo = document.querySelector('.player-info-footer');
    if (headerInfo) headerInfo.style.display = 'flex';
    if (footerInfo) footerInfo.style.display = 'flex';

    // Identity
    if (data.firstname && data.lastname) {
        document.getElementById('player-name').textContent = `${data.firstname} ${data.lastname}`;
    }

    // Gender
    if (data.sex) {
        if (data.sex === 0)
            data.sex = "0";
        else if (data.sex === 1)
            data.sex = "1";
        else if (data.sex === "m")
            data.sex = "0";
        else if (data.sex === "f")
            data.sex = "1";
        else if (data.sex === "male")
            data.sex = "0";
        else if (data.sex === "female")
            data.sex = "1";

        document.getElementById('player-gender').textContent = data.sex === "0" ? 'Homme' : 'Femme';
    }

    // VIP
    const vipItem = document.getElementById('vip-item');
    if (data.vip && data.vip.isVip) {
        vipItem.style.display = 'flex';
        document.getElementById('player-vip').textContent = data.vip.type || 'Premium';
        if (data.vip.time !== undefined) {
            document.getElementById('vip-days').textContent = `${data.vip.time.days} jour${data.vip.time.days > 1 ? 's' : ''} restant${data.vip.time.days > 1 ? 's' : ''}`;
        }
    } else {
        vipItem.style.display = 'none';
    }

    // Money
    if (data.accounts) {
        if (data.accounts.cash !== undefined) {
            document.getElementById('player-cash').textContent = formatMoney(data.accounts.cash);
        }
        if (data.accounts.dirtycash !== undefined) {
            document.getElementById('player-dirty').textContent = formatMoney(data.accounts.dirtycash);
        }
        if (data.accounts.bank !== undefined) {
            document.getElementById('player-bank').textContent = formatMoney(data.accounts.bank);
        }
    }

    // Playtime
    if (data.playtime !== undefined) {
        const hours = Math.floor(data.playtime / 60);
        const minutes = data.playtime % 60;
        document.getElementById('player-playtime').textContent = `${hours}h ${minutes}m`;
    }
}

function formatMoney(amount) {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'USD' }).format(amount).replace('$US', '$');
}

function triggerEnter() {
    document.body.classList.remove('shutters-visible');
    document.body.classList.add('shutters-covering');
    document.body.classList.add('hide-ui');

    // Cacher l'enter phase une fois que les shutters couvrent (transition CSS ~600ms).
    setTimeout(() => {
        if (enterPhase) {
            enterPhase.classList.add('hidden');
            enterPhase.classList.remove('active');
        }
    }, 600);

    // Fallback de sécurité : si Lua n'envoie pas FADE_OUT dans les 10s,
    // forcer la réouverture localement pour éviter de rester bloqué visuellement.
    if (_triggerEnterFallbackTimer) clearTimeout(_triggerEnterFallbackTimer);
    _triggerEnterFallbackTimer = setTimeout(() => {
        if (document.body.classList.contains('shutters-covering')) {
            console.warn('[null-loading] FADE_OUT not received after 10s, forcing fadeOut()');
            fadeOut();
        }
    }, 10000);
}

function fadeOut() {
    if (_triggerEnterFallbackTimer) {
        clearTimeout(_triggerEnterFallbackTimer);
        _triggerEnterFallbackTimer = null;
    }

    // Fade out music
    if (audio) {
        const fadeAudio = setInterval(() => {
            if (audio.volume > 0.05) {
                audio.volume -= 0.05;
            } else {
                audio.pause();
                clearInterval(fadeAudio);
            }
        }, 50);
    }

    // Réouverture des shutters (CSS transition 1.2s).
    document.body.classList.remove('shutters-covering');
    document.body.classList.remove('shutters-visible');
    document.body.classList.add('shutters-hidden');

    // Fade out de l'UI loading (plus rapide qu'avant : 0.3s au lieu de 0.5s).
    const wrapper = document.querySelector('.content-wrapper');
    if (wrapper) {
        wrapper.style.transition = 'opacity 0.3s ease';
        wrapper.style.opacity = '0';
    }

    // Nettoyage final aligné sur la fin de la transition shutters (1.2s).
    setTimeout(() => {
        const app = document.getElementById('app');
        if (app) app.style.display = 'none';
    }, 1200);
}

// Default Handlers for FiveM
const handlers = {
    startInitFunctionOrder(data) {
        statusText.innerText = `Initialisation...`;
    },
    initFunctionInvoking(data) {
        let loadingName = data.name;
        if (data.name.startsWith('resource.')) {
            loadingName = "de " + data.name.split('.')[1];
        } else if (data.name.startsWith('dlc')) {
            loadingName = "des DLCs";
        } else if (data.name.startsWith('dlc')) {
            loadingName = "des DLCs";
        } else {
            statusText.innerText = `Chargement ${loadingName}...`;
        }
        statusText.innerText = `Chargement des fonctions...`;
    },
    startDataFileEntries(data) {
        statusText.innerText = `Chargement des données...`;
    },
    performMapLoadFunction(data) {
        statusText.innerText = `Chargement de la carte...`;
    }
};

window.addEventListener('message', function (e) {
    (handlers[e.data.eventName] || function () { })(e.data);
});

/* ==========================================================================
   See More Panel (Patch notes / Team / Gallery)
   ========================================================================== */
let galleryRAF = null;

function initSeeMorePanel() {
    const panelCfg = (CFG.panel && CFG.panel.enabled !== false) ? CFG.panel : null;
    const btn = document.getElementById('see-more-btn');
    const panel = document.getElementById('see-more-panel');
    if (!btn || !panel) return;

    if (!panelCfg) {
        btn.style.display = 'none';
        return;
    }

    // Title / subtitle
    if (panelCfg.title) {
        const t = document.getElementById('sm-panel-title');
        if (t) t.textContent = panelCfg.title;
    }
    if (panelCfg.subtitle) {
        const s = document.getElementById('sm-panel-subtitle');
        if (s) s.textContent = panelCfg.subtitle;
    }

    renderPatchNotes(panelCfg.patchnotes || []);
    renderTeam(panelCfg.team || []);
    renderGallery(panelCfg.gallery || [], panelCfg.galleryAutoScrollSpeed);

    btn.addEventListener('click', () => openSeeMore());
    document.getElementById('sm-panel-close').addEventListener('click', () => closeSeeMore());
    panel.querySelector('.sm-panel-backdrop').addEventListener('click', () => closeSeeMore());

    panel.querySelectorAll('.sm-tab').forEach(tab => {
        tab.addEventListener('click', () => activateTab(tab.dataset.tab));
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !panel.classList.contains('hidden')) closeSeeMore();
    });
}

function openSeeMore() {
    const panel = document.getElementById('see-more-panel');
    if (!panel) return;
    panel.classList.remove('hidden');
    panel.setAttribute('aria-hidden', 'false');
    startGalleryAutoScroll();
}

function closeSeeMore() {
    const panel = document.getElementById('see-more-panel');
    if (!panel) return;
    panel.classList.add('hidden');
    panel.setAttribute('aria-hidden', 'true');
    stopGalleryAutoScroll();
}

function activateTab(tabName) {
    document.querySelectorAll('.sm-tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tabName));
    document.querySelectorAll('.sm-tab-pane').forEach(p => p.classList.toggle('active', p.dataset.pane === tabName));
    if (tabName === 'gallery') startGalleryAutoScroll();
}

function renderPatchNotes(list) {
    const pane = document.getElementById('sm-pane-patchnotes');
    if (!pane) return;
    if (!list.length) {
        pane.innerHTML = '<div class="sm-empty">Aucun patch note disponible.</div>';
        return;
    }
    pane.innerHTML = list.map(entry => {
        const changes = (entry.changes || []).map(c => `
            <li class="sm-pn-change">
                <span class="sm-pn-change-tag ${escapeAttr(c.type || 'changed')}">${escapeHtml((c.type || 'changed'))}</span>
                <span>${escapeHtml(c.text || '')}</span>
            </li>`).join('');
        return `
            <div class="sm-pn-entry">
                <div class="sm-pn-head">
                    <span class="sm-pn-version">v${escapeHtml(entry.version || '?')}</span>
                    ${entry.tag ? `<span class="sm-pn-tag">${escapeHtml(entry.tag)}</span>` : ''}
                    ${entry.date ? `<span class="sm-pn-date">${escapeHtml(entry.date)}</span>` : ''}
                </div>
                ${entry.title ? `<div class="sm-pn-title">${escapeHtml(entry.title)}</div>` : ''}
                <ul class="sm-pn-changes">${changes}</ul>
            </div>`;
    }).join('');
}

function renderTeam(list) {
    const pane = document.getElementById('sm-pane-team');
    if (!pane) return;
    if (!list.length) {
        pane.innerHTML = '<div class="sm-empty">Aucun membre listé.</div>';
        return;
    }
    pane.innerHTML = `<div class="sm-team-grid">${list.map(m => `
        <div class="sm-team-card">
            <img class="sm-team-avatar" src="${escapeAttr(m.avatar || 'img/logo.png')}" alt="" onerror="this.src='img/logo.png'">
            <div class="sm-team-info">
                ${m.badge ? `<div class="sm-team-badge">${escapeHtml(m.badge)}</div>` : ''}
                ${m.role ? `<div class="sm-team-role">${escapeHtml(m.role)}</div>` : ''}
                <h4 class="sm-team-name">${escapeHtml(m.name || '')}</h4>
                ${m.description ? `<div class="sm-team-desc">${escapeHtml(m.description)}</div>` : ''}
            </div>
        </div>`).join('')}</div>`;
}

/* ----- Gallery slideshow (full-bleed, auto-advance every 2s, dot indicators) ----- */
let galleryTimer = null;
let galleryIndex = 0;
let galleryCount = 0;
const GALLERY_INTERVAL_MS = 2000;

function renderGallery(list /*, speed (legacy, ignored) */) {
    const pane = document.getElementById('sm-pane-gallery');
    if (!pane) return;
    galleryIndex = 0;
    galleryCount = list.length;
    if (!galleryCount) {
        pane.innerHTML = '<div class="sm-empty">Aucune image dans la galerie.</div>';
        return;
    }
    const slides = list.map((p, i) => `
        <div class="sm-gallery-slide${i === 0 ? ' active' : ''}" data-index="${i}">
            <img src="${escapeAttr(p.src)}" alt="" onerror="this.style.opacity=0.2">
            ${p.caption ? `<div class="sm-gallery-caption">${escapeHtml(p.caption)}</div>` : ''}
        </div>`).join('');
    const dots = list.map((_, i) =>
        `<button class="sm-gallery-dot${i === 0 ? ' active' : ''}" data-index="${i}" type="button" aria-label="Image ${i + 1}"></button>`
    ).join('');
    pane.innerHTML = `
        <div class="sm-gallery-viewport">
            ${slides}
            <div class="sm-gallery-dots">${dots}</div>
        </div>`;

    // Click on dots to jump
    pane.querySelectorAll('.sm-gallery-dot').forEach(dot => {
        dot.addEventListener('click', () => {
            galleryGoTo(parseInt(dot.dataset.index, 10));
            startGalleryAutoScroll(); // restart timer after manual jump
        });
    });
}

function galleryGoTo(index) {
    if (galleryCount <= 0) return;
    galleryIndex = ((index % galleryCount) + galleryCount) % galleryCount;
    document.querySelectorAll('#sm-pane-gallery .sm-gallery-slide').forEach(el => {
        el.classList.toggle('active', parseInt(el.dataset.index, 10) === galleryIndex);
    });
    document.querySelectorAll('#sm-pane-gallery .sm-gallery-dot').forEach(el => {
        el.classList.toggle('active', parseInt(el.dataset.index, 10) === galleryIndex);
    });
}

function startGalleryAutoScroll() {
    stopGalleryAutoScroll();
    if (galleryCount <= 1) return;
    galleryTimer = setInterval(() => {
        galleryGoTo(galleryIndex + 1);
    }, GALLERY_INTERVAL_MS);
}

function stopGalleryAutoScroll() {
    if (galleryTimer) { clearInterval(galleryTimer); galleryTimer = null; }
}

function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
function escapeAttr(s) { return escapeHtml(s); }

/* ==========================================================================
   Enter action bridge
   --------------------------------------------------------------------------
   The Enter button on the spawn screen calls back into Lua via NUI fetch.
   Keyboard input is intentionally NOT listened to — only the click counts.
   ========================================================================== */
let enterTriggered = false;
let enterArmed = false;

// On a loadscreen NUI page, GetParentResourceName() returns "loadingScreen"
// (the special host the loadscreen runs under), NOT our resource name. So we
// MUST hardcode the target resource name for the NUI callback to be routed
// to the right RegisterNUICallback handler in client.lua.
const TARGET_RESOURCE = 'null-core';

function sendEnterCallback() {
    if (enterTriggered) return;
    enterTriggered = true;

    const btn = document.querySelector('#enter-phase .enter-key-btn');
    if (btn) {
        btn.disabled = true;
        btn.style.pointerEvents = 'none';
        btn.style.opacity = '0.6';
        const label = btn.querySelector('.enter-key-btn-label');
        if (label) label.innerText = 'Chargement...';
    }

    console.log('[null-loading] sending fetch to loadingEnter');
    const url = `https://${TARGET_RESOURCE}/loadingEnter`;
    fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    })
        .then(r => console.log('[null-loading] fetch status', r.status))
        .catch(err => {
            console.error('[null-loading] fetch error:', err);
            enterTriggered = false;
            if (btn) {
                btn.disabled = false;
                btn.style.pointerEvents = '';
                btn.style.opacity = '';
                const label = btn.querySelector('.enter-key-btn-label');
                if (label) label.innerText = 'Entrer en jeu';
            }
        });
}

function bindEnterAction() {
    if (enterArmed) return;
    enterArmed = true;
    enterTriggered = false;

    const btn = document.querySelector('#enter-phase .enter-key-btn');
    if (!btn) {
        console.error('[null-loading] enter-key-btn NOT found in DOM');
        return;
    }
    btn.style.cursor = 'pointer';

    btn.addEventListener('click', () => {
        sendEnterCallback();
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            sendEnterCallback();
        }
    });
}

// Start blur addon (geometry-based: scans DOM for backdrop-filter/blur elements,
// neutralizes CEF black rendering, sends geometry to ReShade addon)
if (window.NullBlur) {
    window.NullBlur.start({ port: 39474 });

    var blurObserver = new MutationObserver(function (mutations) {
        mutations.forEach(function (m) {
            if (m.attributeName === 'data-null-blur-addon') {
                var active = document.documentElement.getAttribute('data-null-blur-addon') === 'active';
                var url = `https://${TARGET_RESOURCE}/blurStateUpdate`;
                fetch(url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ active: active })
                }).catch(function () { });
            }
        });
    });
    blurObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-null-blur-addon'] });
}

// Bind blur proposal buttons
const bpInstallBtn = document.getElementById('bp-install-btn');
const bpSkipBtn = document.getElementById('bp-skip-btn');

document.querySelectorAll('.bp-link').forEach(function (link) {
    link.addEventListener('click', function (e) {
        e.preventDefault();
        var href = link.getAttribute('href');
        if (!href) return;
        fetch(`https://${TARGET_RESOURCE}/blurOpenUrl`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ url: href })
        }).catch(function (err) {
            console.error('[null-loading] blurOpenUrl error:', err);
        });
    });
});

if (bpInstallBtn) {
    bpInstallBtn.addEventListener('click', () => {
        sendBlurCallback('install');
    });
}
if (bpSkipBtn) {
    bpSkipBtn.addEventListener('click', () => {
        sendBlurCallback('skip');
    });
}

const enterBackBtn = document.getElementById('enter-back-btn');
if (enterBackBtn) {
    enterBackBtn.addEventListener('click', () => {
        document.body.classList.remove('shutters-visible');
        document.body.classList.add('shutters-covering');

        setTimeout(() => {
            enterPhase.classList.add('hidden');
            enterPhase.classList.remove('active');

            if (blurProposal) {
                blurProposal.classList.remove('hidden');
                setTimeout(() => {
                    blurProposal.classList.add('active');
                }, 50);
            }

            document.body.classList.remove('shutters-covering');
            document.body.classList.add('shutters-hidden');
        }, 1200);
    });
}

function sendBlurCallback(action) {
    const url = `https://${TARGET_RESOURCE}/blurProposalAction`;
    fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ action: action })
    }).catch(err => {
        console.error('[null-loading] blurProposalAction error:', err);
    });
}

// Run Init
init();
