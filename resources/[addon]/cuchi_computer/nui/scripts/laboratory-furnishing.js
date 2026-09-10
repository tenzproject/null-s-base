const laboratoryTypes = {
    "weed": {
        label: "Weed",
        description: "Un laboratoire de production de cannabis.",
        image: "assets/images/labo_weed.png",
        price: 315
    },
    "coke": {
        label: "Coke",
        description: "Un laboratoire de production de cocaïne.",
        image: "assets/images/labo_coke.png",
        price: 12000
    },
    "meth": {
        label: "Meth",
        description: "Un laboratoire de production de méthamphétamine.",
        image: "assets/images/labo_meth.png",
        price: 45000
    },
    "weapon": {
        label: "Createur d'armes",
        description: "Un atelier de fabrication d'armes.",
        image: "assets/images/labo_weapon.png",
        price: 95000
    },
    "money": {
        label: "Blanchisseur",
        description: "Un laboratoire de blanchiment d'argent.",
        image: "assets/images/labo_money.png",
        price: 115000
    }
};

let currentLabType = null;
let currentLabId = null;
let pendingRefreshLab = false;

function formatPrice(price) {
    return new Intl.NumberFormat('fr-FR').format(price) + '$';
}

function createLabTypeElement(id, labType) {
    const div = document.createElement('div');
    div.className = 'lab-type-item';
    
    // Create image banner
    const img = document.createElement('img');
    img.src = labType.image;
    img.alt = labType.label;
    img.className = 'lab-type-image';
    
    div.innerHTML = `
        <div class="lab-type-image-container">
            ${img.outerHTML}
        </div>
        <div class="lab-type-content">
            <div class="lab-type-header">
                <span class="lab-type-title">${labType.label}</span>
            </div>
            <div class="lab-type-description">${labType.description}</div>
            <div class="lab-type-price">
                <span>Prix:</span>
                <span>${formatPrice(labType.price)}</span>
            </div>
            <div class="lab-type-actions">
                <button class="lab-type-button" onclick="purchaseLabType('${id}')">Acheter</button>
            </div>
        </div>
    `;
    
    return div;
}

function refreshLabTypes() {
    console.log('Attempting to refresh lab types...');
    const container = document.getElementById('laboratory-furnishing-types');
    
    if (!container) {
        console.log('Container not found, setting pending refresh');
        pendingRefreshLab = true;
        return;
    }
    
    console.log('Container found, refreshing lab types');
    pendingRefreshLab = false;
    container.innerHTML = '';
    
    for (const [id, labType] of Object.entries(laboratoryTypes)) {
        container.appendChild(createLabTypeElement(id, labType));
    }
}

function checkPendingRefreshLab() {
    if (pendingRefreshLab) {
        console.log('Checking pending refresh for lab types...');
        refreshLabTypes();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefreshLab, 100);

function purchaseLabType(id) {
    const loader = document.getElementById('laboratory-furnishing-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/purchaseLabType`, {
        method: 'POST',
        body: JSON.stringify({
            labType: id,
            laboratory: currentLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            currentLabType = id;
            refreshLabTypes();
            MessageBox("info", "Succès", "Type de laboratoire acheté avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible d'acheter ce type de laboratoire.");
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

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Lab Furnishing: Received show event:', event.data);
        
        // Réinitialiser les données
        currentLabType = null;
        currentLabId = null;
        pendingRefreshLab = false;
        
        if (event.data.laboratory && event.data.laboratory.id) {
            console.log('Lab Furnishing: Laboratory data:', event.data.laboratory);
            currentLabType = event.data.laboratory.labType || null;
            currentLabId = event.data.laboratory.id;
            
            // Attendre que le bureau soit initialisé avant de rafraîchir
            window.addEventListener('desktopInitialized', () => {
                console.log('Lab Furnishing: Desktop initialized, refreshing lab types');
                setTimeout(refreshLabTypes, 0);
            }, { once: true });
        }
    }
});
