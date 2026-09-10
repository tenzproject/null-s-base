const laboratoryUpgrades = {
    "uv-light": {
        label: "Lampes UV",
        description: "Les lampes UV permettent de faire pousser les plantes plus rapidement et donner plus de grammes.",
        image: "assets/images/labo_weed_update.png",
        type: "weed",
        prices: {
            oneTime: 7510,
            consommation: {
                "Electricite": 550
            }
        }
    },
    "meth-upgrade": {
        label: "Amélioration des machines",
        description: "Améliorer les machines pour produire en plus grande quantité et de meilleure qualité.",
        image: "assets/images/labo_meth_update.png",
        type: "meth",
        prices: {
            oneTime: 18500
        }
    },
    // "sprinklers": {
    //     label: "Arrosage Automatique",
    //     description: "L'arrosage automatique permet de donner de l'eau en continu aux plantes.",
    //     prices: {
    //         oneTime: 9910,
    //         consommation: {
    //             "Electricite": 25,
    //             "Eau": 1050,
    //         }
    //     }
    // },
    "coffre": {
        label: "Coffre Privé",
        description: "Un coffre permettant de stocker des affaires de manière sécurisée.",
        image: "assets/images/labo_coffre.png",
        type: "all",
        prices: {
            oneTime: 500
        }
    },
    "ventilateurs": {
        label: "Ventilateurs",
        description: "Des ventilateurs permettant d'aérer les plantations.",
        image: "assets/images/labo_ventilateurs.png",
        type: "weed",
        prices: {
            oneTime: 200,
            consommation: {
                "Electricite": 35,
            }
        }
    },
    "security": {
        label: "Sécurité",
        description: "Une meilleur porte et de nouvelles cameras.",
        image: "assets/images/labo_security.png",
        type: "all",
        prices: {
            oneTime: 1500
        }
    },
    "treatment-equipment": {
        label: "Equipement de Traitement",
        description: "Un equipement permettant de traiter les drogues.",
        image: "assets/images/labo_treatment-equipment.png",
        type: "weed",
        prices: {
            oneTime: 500,
        }
    },
    "dealer": {
        label: "Dealer",
        description: "Une personne qui vous achète de la drogue et la revend à votre place.",
        image: "assets/images/labo_dealer.png",
        type: "all",
        prices: {
            oneTime: 2500,
            consommation: {
                "Salaire": 1200,
            }
        }
    },
    "market-study": {
        label: "Etude de Marché",
        description: "Outils qui vous permettent de faire des recherches sur les marchés.",
        image: "assets/images/labo_market.png",
        type: "all",
        prices: {
            oneTime: 3500,
            consommation: {
                "Abonement": 600,
            }
        }
    }
};

let currentUpgrades = {};
let CurrentLaboratory = null;
let pendingRefresh = false;

function formatPrice(price) {
    return new Intl.NumberFormat('fr-FR').format(price) + '$';
}

function createUpgradeElement(id, upgrade, installed) {
    const div = document.createElement('div');
    div.className = `upgrade-item${installed ? ' installed' : ''}`;
    
    let pricesHtml = `<div class="upgrade-price">
        <span>Prix d'achat:</span>
        <span>${formatPrice(upgrade.prices.oneTime)}</span>
    </div>`;
    
    if (upgrade.prices.consommation) {
        pricesHtml += '<div class="upgrade-price"><span>Consommation mensuelle:</span></div>';
        for (const [resource, cost] of Object.entries(upgrade.prices.consommation)) {
            pricesHtml += `<div class="upgrade-price">
                <span>${resource}:</span>
                <span>${formatPrice(cost)}</span>
            </div>`;
        }
    }
    
    div.innerHTML = `
        <div class="upgrade-header">
            <span class="upgrade-title">${upgrade.label}</span>
            ${installed ? '<span class="upgrade-status">✓ Installé</span>' : ''}
        </div>
        <div class="upgrade-image">
            <img src="${upgrade.image}" alt="${upgrade.label}">
        </div>
        <div class="upgrade-description">${upgrade.description}</div>
        <div class="upgrade-prices">
            ${pricesHtml}
        </div>
        <div class="upgrade-actions">
            ${!installed ? `<button class="upgrade-button" onclick="purchaseUpgrade('${id}')">Acheter</button>` : ''}
        </div>
    `;
    
    return div;
}

function refreshUpgrades() {
    console.log('Attempting to refresh upgrades...');
    const container = document.getElementById('laboratory-upgrades-upgrades');
    
    if (!container) {
        console.log('Container not found, setting pending refresh');
        pendingRefresh = true;
        return;
    }
    
    console.log('Container found, refreshing upgrades');
    pendingRefresh = false;
    container.innerHTML = '';
    
    for (const [id, upgrade] of Object.entries(laboratoryUpgrades)) {
        // Vérifier si l'amélioration est compatible avec le type de laboratoire
        const laboType = CurrentLaboData && CurrentLaboData.type ? CurrentLaboData.type : null;
        
        // Afficher l'amélioration si:
        // 1. Le type d'amélioration est "all" (compatible avec tous les types)
        // 2. Le type d'amélioration correspond au type de laboratoire
        // 3. Aucun type de laboratoire n'est défini (pour la compatibilité avec les anciens systèmes)
        if (upgrade.type === "all" || upgrade.type === laboType || !laboType) {
            const installed = currentUpgrades[id] === true;
            container.appendChild(createUpgradeElement(id, upgrade, installed));
        } else {
            console.log(`Amélioration ${id} non compatible avec le type de laboratoire ${laboType}`);
        }
    }
}

function checkPendingRefresh() {
    if (pendingRefresh) {
        console.log('Checking pending refresh...');
        refreshUpgrades();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefresh, 100);

function purchaseUpgrade(id) {
    const loader = document.getElementById('laboratory-upgrades-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/purchaseUpgrade`, {
        method: 'POST',
        body: JSON.stringify({
            upgrade: id,
            laboratory: CurrentLaboratory
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            currentUpgrades[id] = true;
            refreshUpgrades();
            MessageBox("info", "Succès", "Amélioration achetée avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible d'acheter cette amélioration.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors de l'achat.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

// Initialisation des améliorations quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Received show event:', event.data);
        
        // Réinitialiser les données
        currentUpgrades = {};
        CurrentLaboratory = null;
        CurrentLaboData = null;
        pendingRefresh = false;
        
        if (event.data.laboratory && event.data.laboratory.id) {
            console.log('Laboratory data:', event.data.laboratory);
            currentUpgrades = event.data.laboratory.upgrades || {};
            CurrentLaboratory = event.data.laboratory.id;
            CurrentLaboData = event.data.laboratory;
            
            // Attendre que le bureau soit initialisé avant de rafraîchir
            window.addEventListener('desktopInitialized', () => {
                console.log('Desktop initialized, refreshing upgrades');
                setTimeout(refreshUpgrades, 0);
            }, { once: true });
        }
    }
});
