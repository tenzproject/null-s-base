let pendingConsoleInit = false;

function initializeConsole() {
    console.log('Attempting to initialize console...');
    const consoleText = document.getElementById('console-text');
    if (!consoleText) {
        console.log('Console text element not found, setting pending init');
        pendingConsoleInit = true;
        return;
    }

    console.log('Console text element found, initializing');
    pendingConsoleInit = false;
    consoleText.innerHTML = '';
}

function checkPendingConsoleInit() {
    if (pendingConsoleInit) {
        console.log('Checking pending console init...');
        initializeConsole();
    }
}

// Vérifier périodiquement s'il y a une initialisation en attente
setInterval(checkPendingConsoleInit, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Console: Received show event');
        
        // Attendre que le bureau soit initialisé
        window.addEventListener('desktopInitialized', () => {
            console.log('Console: Desktop initialized, initializing console');
            setTimeout(initializeConsole, 0);
        }, { once: true });
    }
});
