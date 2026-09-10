// Variables globales pour la gestion du laboratoire
let currentLabData = null;
let pendingRefreshLabManagement = false;

// Constantes pour les calculs
const MONTHLY_BASE_COSTS = {
    //"weed": 500,
    //"meth": 800,
    //"cocaine": 1000,
    //"coke": 1000, // Alias pour cocaine
    "weapon": 1200,
    "money": 1500,
    "default": 0
};

// Fonction pour formater les prix
function formatLabPrice(price) {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'USD' }).format(price);
}

// Fonction pour formater les dates
function formatLabDate(timestamp) {
    if (!timestamp) return "Jamais";
    
    const date = new Date(timestamp * 1000);
    return date.toLocaleDateString('fr-FR', { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Fonction pour calculer le prix estimé du laboratoire
function calculateLabEstimatedValue() {
    if (!currentLabData) return 0;
    
    // Prix de base selon le type depuis laboratoryTypes
    let basePrice = 0; // Valeur par défaut
    
    if (currentLabData.type && laboratoryTypes[currentLabData.type]) {
        basePrice = laboratoryTypes[currentLabData.type].price;
    }
    console.log("basePrice", basePrice);
    // Valeur des employés (nombre * 1000)
    const employeesValue = Object.keys(currentLabData.employees || {}).length * 1000;
    
    // Valeur des upgrades
    let upgradesValue = 0;
    if (currentLabData.upgrades) {
        for (const [upgrade, active] of Object.entries(currentLabData.upgrades)) {
            if (active && laboratoryUpgrades[upgrade] && laboratoryUpgrades[upgrade].prices && laboratoryUpgrades[upgrade].prices.oneTime) {
                upgradesValue += laboratoryUpgrades[upgrade].prices.oneTime;
                console.log("Upgrade found:", upgrade, laboratoryUpgrades[upgrade].prices.oneTime);
            }
        }
    }
    
    // Valeur des membres (nombre * 1000)
    const membersValue = Object.keys(currentLabData.members || {}).length * 1000;
    console.log("membersValue", membersValue);
    return basePrice + employeesValue + upgradesValue + membersValue;
}

// Fonction pour calculer les dépenses journalières
function calculateDailyExpenses() {
    if (!currentLabData) return 0;
    
    // Coût des employés (120$ par jour par employé)
    const employeesCost = Object.keys(currentLabData.employees || {}).length * 120;
    
    return employeesCost;
}

// Fonction pour calculer les dépenses mensuelles
function calculateMonthlyExpenses() {
    if (!currentLabData) return 0;
    
    // Coût de base selon le type
    const baseCost = MONTHLY_BASE_COSTS[currentLabData.type] || MONTHLY_BASE_COSTS.default;
    
    // Coût des upgrades basé sur leur consommation
    let upgradesCost = 0;
    let upgradeCosts = {};
    
    if (currentLabData.upgrades) {
        for (const [upgrade, active] of Object.entries(currentLabData.upgrades)) {
            if (active && laboratoryUpgrades[upgrade] && laboratoryUpgrades[upgrade].prices && laboratoryUpgrades[upgrade].prices.consommation) {
                for (const [resource, cost] of Object.entries(laboratoryUpgrades[upgrade].prices.consommation)) {
                    if (!upgradeCosts[resource]) {
                        upgradeCosts[resource] = 0;
                    }
                    upgradeCosts[resource] += cost;
                    upgradesCost += cost;
                }
            }
        }
    }
    
    return {
        baseCost: baseCost,
        upgradeCosts: upgradeCosts,
        totalCost: baseCost + upgradesCost
    };
}

function refreshLabManagement() {
    console.log('Attempting to refresh lab management...');
    const infoContainer = document.getElementById('lab-management-info');
    const expensesContainer = document.getElementById('lab-management-expenses');
    const transferContainer = document.getElementById('lab-management-transfer');
    const billingContainer = document.getElementById('lab-management-billing');
    
    if (!infoContainer || !expensesContainer || !transferContainer || !billingContainer) {
        console.log('Containers not found, setting pending refresh');
        pendingRefreshLabManagement = true;
        return;
    }
    
    console.log('Containers found, refreshing lab management');
    pendingRefreshLabManagement = false;
    
    if (!currentLabData) {
        infoContainer.innerHTML = '<div class="no-lab-data">Aucune donnée de laboratoire disponible.</div>';
        expensesContainer.innerHTML = '<div class="no-lab-data">Aucune donnée de laboratoire disponible.</div>';
        transferContainer.innerHTML = '<div class="no-lab-data">Aucune donnée de laboratoire disponible.</div>';
        billingContainer.innerHTML = '<div class="no-lab-data">Aucune donnée de laboratoire disponible.</div>';
        return;
    }
    
    // Afficher les informations du laboratoire
    const labImage = `assets/images/labo_${currentLabData.type || 'default'}.png`;
    const estimatedValue = calculateLabEstimatedValue();
    const employeesCount = Object.keys(currentLabData.employees || {}).length;
    const membersCount = Object.keys(currentLabData.members || {}).length;
    
    infoContainer.innerHTML = `
        <div class="lab-info-header">
            <div class="lab-info-image">
                <img src="${labImage}" alt="Laboratoire">
            </div>
            <div class="lab-info-details">
                <h2>${currentLabData.name || 'Laboratoire'}</h2>
                <div class="lab-info-row">
                    <span>Type:</span>
                    <span>${currentLabData.type ? currentLabData.type.charAt(0).toUpperCase() + currentLabData.type.slice(1) : 'Standard'}</span>
                </div>
                <div class="lab-info-row">
                    <span>Propriétaire:</span>
                    <span>${currentLabData.owner || 'Inconnu'}</span>
                </div>
                <div class="lab-info-row">
                    <span>Valeur estimée:</span>
                    <span>${formatLabPrice(estimatedValue)}</span>
                </div>
                <div class="lab-info-row">
                    <span>Employés:</span>
                    <span>${employeesCount}</span>
                </div>
                <div class="lab-info-row">
                    <span>Membres:</span>
                    <span>${membersCount}</span>
                </div>
                <div class="lab-info-row">
                    <span>Date de création:</span>
                    <span>${formatLabDate(currentLabData.createdAt)}</span>
                </div>
            </div>
        </div>
    `;
    
    // Afficher les dépenses
    const dailyExpenses = calculateDailyExpenses();
    const monthlyExpenses = calculateMonthlyExpenses();
    const totalMonthlyExpenses = dailyExpenses * 30 + monthlyExpenses.totalCost;
    
    expensesContainer.innerHTML = `
        <div class="lab-expenses-header">
            <h2>Dépenses</h2>
        </div>
        <div class="lab-expenses-content">
            <div class="lab-expenses-section">
                <h3>Dépenses journalières</h3>
                <div class="lab-expenses-row">
                    <span>Salaires des employés:</span>
                    <span>${formatLabPrice(dailyExpenses)}</span>
                </div>
                <div class="lab-expenses-row total">
                    <span>Total par jour:</span>
                    <span>${formatLabPrice(dailyExpenses)}</span>
                </div>
            </div>
            
            <div class="lab-expenses-section">
                <h3>Dépenses mensuelles</h3>
                <div class="lab-expenses-row">
                    <span>Frais de base:</span>
                    <span>${formatLabPrice(monthlyExpenses.baseCost)}</span>
                </div>
                ${Object.entries(monthlyExpenses.upgradeCosts).map(([resource, cost]) => `
                    <div class="lab-expenses-row">
                        <span>${resource}:</span>
                        <span>${formatLabPrice(cost)}</span>
                    </div>
                `).join('')}
                <div class="lab-expenses-row total">
                    <span>Total mensuel:</span>
                    <span>${formatLabPrice(totalMonthlyExpenses)}</span>
                </div>
            </div>
        </div>
    `;
    
    // Afficher les informations de facturation
    loadBillingInfo();
    
    const isOwner = currentLabData.isOwner || false;
    
    transferContainer.innerHTML = `
        <div class="lab-transfer-header">
            <h2>Transfert de propriété</h2>
        </div>
        ${isOwner ? `
            <div class="lab-transfer-content">
                <p>Vous êtes le propriétaire de ce laboratoire. Vous pouvez transférer la propriété à un autre joueur.</p>
                <div class="lab-transfer-form">
                    <input type="text" id="transfer-id" placeholder="ID unique du joueur" />
                    <button class="lab-button transfer" onclick="transferLabOwnership()">Transférer</button>
                </div>
            </div>
        ` : `
            <div class="lab-transfer-content">
                <p>Vous ne pouvez pas transférer la propriété de ce laboratoire pour l'instant.</p>
            </div>
        `}
    `;
}

function transferLabOwnership() {
    const idInput = document.getElementById('transfer-id');
    const newOwnerId = parseInt(idInput.value.trim());
    
    if (isNaN(newOwnerId) || newOwnerId < 0) {
        MessageBox("error", "Erreur", "Veuillez entrer un ID valide (nombre positif).");
        return;
    }
    
    if (!confirm(`Êtes-vous sûr de vouloir transférer la propriété de ce laboratoire à l'ID ${newOwnerId}? Cette action est irréversible.`)) {
        return;
    }
    
    const loader = document.getElementById('lab-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/transferLabOwnership`, {
        method: 'POST',
        body: JSON.stringify({
            newOwnerId: newOwnerId,
            laboratoryId: currentLabData.id
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            MessageBox("info", "Succès", "La propriété du laboratoire a été transférée avec succès!");
            // Mettre à jour les données locales
            currentLabData.isOwner = false;
            currentLabData.owner = newOwnerId;
            currentLabData.ownerName = data.newOwnerName || 'Nouveau propriétaire';
            refreshLabManagement();
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de transférer la propriété.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors du transfert de propriété.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

function checkPendingRefreshLabManagement() {
    if (pendingRefreshLabManagement) {
        console.log('Checking pending refresh for lab management...');
        refreshLabManagement();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefreshLabManagement, 100);

function loadBillingInfo() {
    const billingContainer = document.getElementById('lab-management-billing');
    if (!billingContainer || !currentLabData) return;
    
    fetch(`https://${GetParentResourceName()}/getBillingInfo`, {
        method: 'POST',
        body: JSON.stringify({
            laboratoryId: currentLabData.id
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data) {
            const hasBill = data.currentBill && data.currentBill > 0;
            const deadline = data.billDeadline ? new Date(data.billDeadline * 1000) : null;
            const nextBill = data.nextBillDate ? new Date(data.nextBillDate * 1000) : null;
            const timeLeft = deadline ? Math.max(0, Math.floor((deadline - new Date()) / 1000)) : 0;
            const daysLeft = Math.floor(timeLeft / 86400);
            const hoursLeft = Math.floor((timeLeft % 86400) / 3600);
            
            billingContainer.innerHTML = `
                <div class="lab-billing-header">
                    <h2>Facturation</h2>
                </div>
                <div class="lab-billing-content">
                    ${hasBill ? `
                        <div class="lab-billing-current">
                            <h3>Facture en cours</h3>
                            <div class="lab-billing-amount">
                                <span class="billing-label">Montant:</span>
                                <span class="billing-value">${formatLabPrice(data.currentBill)}</span>
                            </div>
                            <div class="lab-billing-deadline ${daysLeft < 1 ? 'urgent' : ''}">
                                <span class="billing-label">Échéance:</span>
                                <span class="billing-value">${daysLeft}j ${hoursLeft}h restant(s)</span>
                            </div>
                            <button class="lab-button pay-bill" onclick="payLabBill()">Payer par virement bancaire</button>
                        </div>
                    ` : `
                        <div class="lab-billing-no-bill">
                            <p>Aucune facture en attente</p>
                        </div>
                    `}
                    <div class="lab-billing-estimate">
                        <h3>Estimation mensuelle</h3>
                        <div class="lab-billing-row">
                            <span>Prochaine facture estimée:</span>
                            <span>${formatLabPrice(data.monthlyEstimate || 0)}</span>
                        </div>
                        ${nextBill ? `
                            <div class="lab-billing-row">
                                <span>Date de la prochaine facture:</span>
                                <span>${nextBill.toLocaleDateString('fr-FR')}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `;
        }
    })
    .catch(error => {
        console.error('Error loading billing info:', error);
        billingContainer.innerHTML = '<div class="no-lab-data">Erreur lors du chargement des informations de facturation.</div>';
    });
}

function payLabBill() {
    if (!currentLabData) return;
    
    if (!confirm('Êtes-vous sûr de vouloir payer cette facture par virement bancaire?')) {
        return;
    }
    
    const loader = document.getElementById('lab-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/payLabBill`, {
        method: 'POST',
        body: JSON.stringify({
            laboratoryId: currentLabData.id
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            MessageBox("info", "Succès", "Facture payée avec succès!");
            loadBillingInfo();
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de payer la facture.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors du paiement.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Lab Management: Received show event:', event.data);
        
        if (event.data.laboratory) {
            console.log('Lab Management: Laboratory data:', event.data.laboratory);
            currentLabData = event.data.laboratory;
            
            // Attendre que le bureau soit initialisé avant de rafraîchir
            window.addEventListener('desktopInitialized', () => {
                console.log('Lab Management: Desktop initialized, refreshing lab management');
                setTimeout(refreshLabManagement, 0);
            }, { once: true });
        }
    }
});
