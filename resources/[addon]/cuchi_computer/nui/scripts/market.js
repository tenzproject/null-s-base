let pendingMarketInit = false;
let currentMarket = [];

function initializeMarket() {
    console.log('Attempting to initialize market...');
    const container = document.getElementById('market-container');
    if (!container) {
        console.log('Market container not found, setting pending init');
        pendingMarketInit = true;
        return;
    }

    console.log('Market container found, initializing');
    pendingMarketInit = false;
    container.innerHTML = '';

    // Créer les éléments pour chaque item du marché
    currentMarket.forEach(item => {
        const div = document.createElement('div');
        div.className = 'market-item';
        div.innerHTML = `
            <div class="market-item-header">
                <span class="market-item-name">${item.name}</span>
                <span class="market-item-price">${item.price}$</span>
            </div>
            <div class="market-item-description">${item.description}</div>
            <div class="market-item-actions">
                <button onclick="purchaseMarketItem('${item.id}')">Acheter</button>
            </div>
        `;
        container.appendChild(div);
    });
}

function checkPendingMarketInit() {
    if (pendingMarketInit) {
        console.log('Checking pending market init...');
        initializeMarket();
    }
}

// Vérifier périodiquement s'il y a une initialisation en attente
setInterval(checkPendingMarketInit, 100);

function purchaseMarketItem(id) {
    fetch(`https://${GetParentResourceName()}/purchaseMarketItem`, {
        method: 'POST',
        body: JSON.stringify({
            itemId: id
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            MessageBox("info", "Succès", "Item acheté avec succès!");
            initializeMarket(); // Rafraîchir le marché
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible d'acheter cet item.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors de l'achat.");
        console.error(error);
    });
}

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Market: Received show event');
        
        // Réinitialiser les données
        currentMarket = event.data.market || [];
        pendingMarketInit = false;
        
        // Attendre que le bureau soit initialisé
        window.addEventListener('desktopInitialized', () => {
            console.log('Market: Desktop initialized, initializing market');
            setTimeout(initializeMarket, 0);
        }, { once: true });
    }
});
