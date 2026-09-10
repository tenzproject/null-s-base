let pendingMailInit = false;
let currentMails = [];
let currentDomain = '';

function initializeMail() {
    console.log('Attempting to initialize mail...');
    const container = document.getElementById('mail-container');
    if (!container) {
        console.log('Mail container not found, setting pending init');
        pendingMailInit = true;
        return;
    }

    console.log('Mail container found, initializing');
    pendingMailInit = false;
    container.innerHTML = '';

    // Mettre à jour le domaine affiché
    const domainElement = document.getElementById('mail-domain');
    if (domainElement) {
        domainElement.textContent = currentDomain;
    }

    // Créer les éléments pour chaque mail
    currentMails.forEach(mail => {
        const div = document.createElement('div');
        div.className = 'mail-item';
        div.innerHTML = `
            <div class="mail-header">
                <span class="mail-from">${mail.from}</span>
                <span class="mail-date">${new Date(mail.date).toLocaleDateString('fr-FR')}</span>
            </div>
            <div class="mail-subject">${mail.subject}</div>
            <div class="mail-content">${mail.content}</div>
        `;
        container.appendChild(div);
    });
}

function checkPendingMailInit() {
    if (pendingMailInit) {
        console.log('Checking pending mail init...');
        initializeMail();
    }
}

// Vérifier périodiquement s'il y a une initialisation en attente
setInterval(checkPendingMailInit, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Mail: Received show event');
        
        // Réinitialiser les données
        currentMails = event.data.mails || [];
        currentDomain = event.data.mailDomain || '';
        pendingMailInit = false;
        
        // Attendre que le bureau soit initialisé
        window.addEventListener('desktopInitialized', () => {
            console.log('Mail: Desktop initialized, initializing mail');
            setTimeout(initializeMail, 0);
        }, { once: true });
    }
});
