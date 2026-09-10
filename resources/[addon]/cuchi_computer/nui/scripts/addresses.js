let pendingAddressesInit = false;
let currentAddresses = [];

function initializeAddresses() {
    console.log('Attempting to initialize addresses...');
    const container = document.getElementById('addresses-container');
    if (!container) {
        console.log('Addresses container not found, setting pending init');
        pendingAddressesInit = true;
        return;
    }

    console.log('Addresses container found, initializing');
    pendingAddressesInit = false;
    container.innerHTML = '';

    // Créer les éléments pour chaque adresse
    currentAddresses.forEach(address => {
        const div = document.createElement('div');
        div.className = 'address-item';
        div.innerHTML = `
            <span class="address-name">${address.name}</span>
            <span class="address-ip">${address.ip}</span>
        `;
        div.onclick = () => {
            // Logique pour ouvrir l'adresse
            if (typeof OpenApp === 'function') {
                OpenApp('addresses-content');
            }
        };
        container.appendChild(div);
    });
}

function checkPendingAddressesInit() {
    if (pendingAddressesInit) {
        console.log('Checking pending addresses init...');
        initializeAddresses();
    }
}

// Vérifier périodiquement s'il y a une initialisation en attente
setInterval(checkPendingAddressesInit, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Addresses: Received show event');
        
        // Réinitialiser les données
        currentAddresses = event.data.addresses || [];
        pendingAddressesInit = false;
        
        if (event.data.idunique) {
            IdUnique = event.data.idunique;
        }

        // Attendre que le bureau soit initialisé
        window.addEventListener('desktopInitialized', () => {
            console.log('Addresses: Desktop initialized, initializing addresses');
            setTimeout(initializeAddresses, 0);
        }, { once: true });
    }
});
