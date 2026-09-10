(function () {
    const root = document.getElementById('root');
    const clipEl = document.getElementById('clip');
    const magEl = document.getElementById('mag');
    const footerEl = document.getElementById('footer');

    function setVisible(v) {
        if (v) root.classList.remove('hidden');
        else root.classList.add('hidden');
    }

    function setState(clip, mag, mags) {
        clipEl.textContent = clip;
        magEl.textContent = mag;
        const pct = mag > 0 ? (clip / mag) * 100 : 0;

        root.classList.remove('low', 'empty');
        if (clip === 0) {
            root.classList.add('empty');
        } else if (pct <= 33) {
            root.classList.add('low');
        }

        if (typeof mags === 'number') {
            footerEl.textContent = 'MAGS ' + mags;
        }
    }

    function setPackMode(mode) {
        root.classList.remove('mode-basic', 'mode-realistic');
        root.classList.add('mode-' + (mode === 'realistic' ? 'realistic' : 'basic'));
    }

    window.addEventListener('message', function (ev) {
        const data = ev.data || {};
        if (typeof data.display === 'boolean') setVisible(data.display);
        if (typeof data.packMode === 'string') setPackMode(data.packMode);
        if (typeof data.clip === 'number' || typeof data.mag === 'number') {
            setState(
                data.clip || 0,
                data.mag || 0,
                typeof data.mags === 'number' ? data.mags : undefined,
                data.label
            );
        }
    });

    // Signal ready to client
    if (window.invokeNative) {
        // Running in FiveM DUI
        fetch('https://null-core/ammoHologramReady', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({}),
        }).catch(function () {});
    }
})();
