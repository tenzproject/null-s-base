const employeesList = {
    "production_1": {
        name: "Mario Smith",
        specialization: "Production",
        labType: "weed",
        description: "Expert en culture de plantes. S'occupe de l'arrosage, fertilisation, plantation et récolte.",
        image: "assets/images/labo_employee1.png",
        prices: {
            oneTime: 2500,
            daily: 150
        }
    },
    "production_2": {
        name: "Carlos Rodriguez",
        specialization: "Production",
        labType: "weed",
        description: "Spécialiste en agriculture. Maîtrise toutes les étapes de la culture.",
        image: "assets/images/labo_employee1.png",
        prices: {
            oneTime: 3500,
            daily: 200
        }
    },
    "production_3": {
        name: "Jake Wilson",
        specialization: "Production",
        labType: "weed",
        description: "Expert en horticulture. Le meilleur pour gérer vos plantations.",
        image: "assets/images/labo_employee1.png",
        prices: {
            oneTime: 5000,
            daily: 280
        }
    },
    "drying_1": {
        name: "Edwin Newman",
        specialization: "Séchage",
        labType: "weed",
        description: "Spécialiste du séchage et de la logistique. Gère le processus de séchage.",
        image: "assets/images/labo_employee2.png",
        prices: {
            oneTime: 1500,
            daily: 100
        }
    },
    "drying_2": {
        name: "Marcus Johnson",
        specialization: "Séchage",
        labType: "weed",
        description: "Expert en logistique. Optimise le flux de séchage et stockage.",
        image: "assets/images/labo_employee2.png",
        prices: {
            oneTime: 2100,
            daily: 140
        }
    },
    "treatment_1": {
        name: "Paul Ward",
        specialization: "Traitement",
        labType: "weed",
        description: "Expert en traitement et conditionnement. Transforme la weed séchée en produit fini.",
        image: "assets/images/labo_employee3.png",
        prices: {
            oneTime: 2000,
            daily: 120
        }
    },
    "treatment_2": {
        name: "David Chen",
        specialization: "Traitement",
        labType: "weed",
        description: "Spécialiste en conditionnement. Maîtrise parfaitement le processus de traitement.",
        image: "assets/images/labo_employee3.png",
        prices: {
            oneTime: 2800,
            daily: 170
        }
    },
    "chimiste_1": {
        name: "Viktor Kozlov",
        specialization: "Chimie",
        labType: "meth",
        description: "Chimiste expérimenté en synthèse de méthamphétamine. Gère les cuves, fours et le stockage.",
        image: "assets/images/labo_employee3.png",
        prices: {
            oneTime: 5000,
            daily: 350
        }
    },
    "chimiste_2": {
        name: "Hector Salamanca",
        specialization: "Chimie",
        labType: "meth",
        description: "Maître chimiste, spécialiste en cristallisation haute pureté. Plus efficace et moins fatigable.",
        image: "assets/images/labo_employee3.png",
        prices: {
            oneTime: 8000,
            daily: 500
        }
    }
};

// Utiliser des noms de variables uniques pour éviter les conflits
let currentEmployeesHired = {};
let currentEmployeesLabId = null;
let currentEmployeesLabType = null;
let pendingRefreshEmployees = false;

// Mapping pour compatibilité avec les anciens IDs
const employeeIdMapping = {
    'employee1': 'production_1',
    'employee2': 'drying_1',
    'employee3': 'treatment_1'
};

// Fonction pour normaliser les données d'employés
function normalizeEmployeesData(employees) {
    if (!employees) return {};
    
    const normalized = {};
    for (const [oldId, data] of Object.entries(employees)) {
        const newId = employeeIdMapping[oldId] || oldId;
        normalized[newId] = data;
    }
    return normalized;
}

function formatPrice(price) {
    return new Intl.NumberFormat('fr-FR').format(price) + '$';
}

function formatTimeSince(timestamp) {
    if (!timestamp) return "Jamais payé";
    
    const now = Math.floor(Date.now() / 1000);
    const secondsAgo = now - timestamp;
    
    if (secondsAgo < 60) {
        return "À l'instant";
    } else if (secondsAgo < 3600) {
        const minutes = Math.floor(secondsAgo / 60);
        return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
    } else if (secondsAgo < 86400) {
        const hours = Math.floor(secondsAgo / 3600);
        return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
    } else {
        const days = Math.floor(secondsAgo / 86400);
        return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
    }
}

function needsPayment(timestamp) {
    if (!timestamp) return true;
    
    const now = Math.floor(Date.now() / 1000);
    const secondsAgo = now - timestamp;
    
    // 24 heures = 86400 secondes
    return secondsAgo >= 86400;
}

function createEmployeeElement(id, employee, hired) {
    const div = document.createElement('div');
    div.className = `employee-card${hired ? ' hired' : ''}`;
    div.dataset.specialization = employee.specialization.toLowerCase();
    
    const imgSrc = employee.image || "assets/images/labo_dealer.png";
    const lastPay = hired && currentEmployeesHired[id] && currentEmployeesHired[id].lastPay ? currentEmployeesHired[id].lastPay : null;
    const requiresPayment = hired && needsPayment(lastPay);
    
    // Calculer la fatigue si employé embauché
    const fatigue = hired && currentEmployeesHired[id] && currentEmployeesHired[id].fatigue ? currentEmployeesHired[id].fatigue : 0;
    const fatigueColor = fatigue > 75 ? '#e74c3c' : fatigue > 50 ? '#f39c12' : '#2ecc71';
    
    // Badge de spécialisation avec couleur
    const specializationColors = {
        'production': '#4CAF50',
        'séchage': '#2196F3',
        'traitement': '#9C27B0',
        'chimie': '#FF9800'
    };
    const specColor = specializationColors[employee.specialization.toLowerCase()] || '#666';
    
    div.innerHTML = `
        <div class="employee-card-header">
            <div class="employee-avatar">
                <img src="${imgSrc}" alt="${employee.name}">
                ${hired ? '<div class="employee-hired-badge">✓</div>' : ''}
            </div>
            <div class="employee-info">
                <h3 class="employee-name">${employee.name}</h3>
                <span class="employee-spec-badge" style="background: ${specColor}">
                    ${employee.specialization}
                </span>
            </div>
        </div>
        
        <div class="employee-card-body">
            <p class="employee-desc">${employee.description}</p>
            
            ${hired ? `
                <div class="employee-stats">
                    <div class="stat-item">
                        <div class="stat-label">
                            <span>Fatigue</span>
                            <span class="stat-value">${fatigue}%</span>
                        </div>
                        <div class="stat-bar">
                            <div class="stat-fill" style="width: ${fatigue}%; background: ${fatigueColor}"></div>
                        </div>
                    </div>
                </div>
            ` : ''}
            
            <div class="employee-pricing">
                <div class="price-row">
                    <span class="price-label">Embauche</span>
                    <span class="price-value">${formatPrice(employee.prices.oneTime)}</span>
                </div>
                <div class="price-row">
                    <span class="price-label">Salaire/jour</span>
                    <span class="price-value">${formatPrice(employee.prices.daily)}</span>
                </div>
                ${hired ? `
                    <div class="price-row ${requiresPayment ? 'payment-warning' : ''}">
                        <span class="price-label">Dernier paiement</span>
                        <span class="price-value">${formatTimeSince(lastPay)}</span>
                    </div>
                ` : ''}
            </div>
        </div>
        
        <div class="employee-card-footer">
            ${!hired ? 
                `<button class="btn-primary btn-hire" onclick="hireEmployee('${id}')">
                    <span>Embaucher</span>
                </button>` : 
                `<div class="employee-actions-group">
                    <button class="btn-danger btn-fire" onclick="fireEmployee('${id}')">
                        <span>Licencier</span>
                    </button>
                    ${requiresPayment ? 
                        `<button class="btn-success btn-pay" onclick="payEmployee('${id}')">
                            <span>Payer ${formatPrice(employee.prices.daily)}</span>
                        </button>` : 
                        `<button class="btn-secondary" disabled>
                            <span>✓ Payé</span>
                        </button>`
                    }
                </div>`
            }
        </div>
    `;
    
    console.log(`[createEmployeeElement] HTML generated for ${id}, innerHTML length:`, div.innerHTML.length);
    console.log(`[createEmployeeElement] Card classes:`, div.className);
    
    return div;
}

let currentFilter = 'all';

function setFilter(filter) {
    currentFilter = filter;
    
    // Update active tab
    document.querySelectorAll('.filter-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`[data-filter="${filter}"]`)?.classList.add('active');
    
    // Filter employees
    const cards = document.querySelectorAll('.employee-card');
    cards.forEach(card => {
        const spec = card.dataset.specialization;
        if (filter === 'all' || spec === filter) {
            card.style.display = 'flex';
        } else {
            card.style.display = 'none';
        }
    });
}

function getFilteredEmployees() {
    const filtered = {};
    for (const [id, employee] of Object.entries(employeesList)) {
        if (!currentEmployeesLabType || employee.labType === currentEmployeesLabType) {
            filtered[id] = employee;
        }
    }
    return filtered;
}

function getFilterTabs() {
    const filtered = getFilteredEmployees();
    const specs = new Set();
    for (const employee of Object.values(filtered)) {
        specs.add(employee.specialization);
    }
    
    const tabConfig = {
        'Production': { label: 'Production' },
        'Séchage': { label: 'Séchage' },
        'Traitement': { label: 'Traitement' },
        'Chimie': { label: 'Chimie' }
    };
    
    const tabs = [];
    for (const spec of specs) {
        const config = tabConfig[spec] || { label: spec };
        const count = Object.values(filtered).filter(e => e.specialization === spec).length;
        tabs.push({ key: spec.toLowerCase(), label: config.label, count });
    }
    return tabs;
}

function refreshEmployees() {
    console.log('Attempting to refresh employees...');
    const wrapper = document.getElementById('employees-management-wrapper');
    
    if (!wrapper) {
        console.log('Wrapper not found, setting pending refresh');
        pendingRefreshEmployees = true;
        return;
    }
    
    console.log('Wrapper found, refreshing employees');
    pendingRefreshEmployees = false;
    
    const filtered = getFilteredEmployees();
    const filterTabs = getFilterTabs();
    
    // Count hired employees
    let hiredCount = 0;
    for (const [id, employee] of Object.entries(filtered)) {
        const hired = currentEmployeesHired && currentEmployeesHired[id] !== undefined && currentEmployeesHired[id] !== false;
        if (hired) hiredCount++;
    }
    
    // Build filter tabs HTML
    let filterTabsHtml = `
        <button class="filter-tab active" data-filter="all" onclick="setFilter('all')">
            <span class="tab-label">Tous</span>
            <span class="tab-count">${Object.keys(filtered).length}</span>
        </button>`;
    
    for (const tab of filterTabs) {
        filterTabsHtml += `
            <button class="filter-tab" data-filter="${tab.key}" onclick="setFilter('${tab.key}')">
                <span class="tab-label">${tab.label}</span>
                <span class="tab-count">${tab.count}</span>
            </button>`;
    }
    
    // Create modern header with filters
    wrapper.innerHTML = `
        <div class="employees-header">
            <div class="employees-title-section">
                <h1>Gestion des Employés</h1>
                <p class="employees-subtitle">Embauchez des spécialistes pour automatiser votre laboratoire</p>
            </div>
            
            <div class="employees-stats-bar">
                <div class="stat-badge">
                    <span class="stat-number">${hiredCount}</span>
                    <span class="stat-text">Employés actifs</span>
                </div>
            </div>
        </div>
        
        <div class="filter-tabs">
            ${filterTabsHtml}
        </div>
        
        <div id="employees-management-list" class="employees-grid"></div>
    `;
    
    const container = document.getElementById('employees-management-list');
    
    for (const [id, employee] of Object.entries(filtered)) {
        const hired = currentEmployeesHired && currentEmployeesHired[id] !== undefined && currentEmployeesHired[id] !== false;
        console.log('Employee:', id, 'hired:', hired, 'data:', currentEmployeesHired[id]);
        container.appendChild(createEmployeeElement(id, employee, hired));
    }
    
    // Apply current filter
    setFilter(currentFilter);
}

function checkPendingRefreshEmployees() {
    if (pendingRefreshEmployees) {
        console.log('Checking pending refresh for employees...');
        refreshEmployees();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefreshEmployees, 100);

function hireEmployee(id) {
    const loader = document.getElementById('employees-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/hireEmployee`, {
        method: 'POST',
        body: JSON.stringify({
            employee: id,
            laboratory: currentEmployeesLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Initialiser l'employé avec un timestamp de paiement actuel
            currentEmployeesHired[id] = {
                lastPay: Math.floor(Date.now() / 1000) // Timestamp actuel en secondes
            };
            refreshEmployees();
            MessageBox("info", "Succès", "Employé embauché avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible d'embaucher cet employé.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors de l'embauche.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

function fireEmployee(id) {
    const loader = document.getElementById('employees-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/fireEmployee`, {
        method: 'POST',
        body: JSON.stringify({
            employee: id,
            laboratory: currentEmployeesLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            currentEmployeesHired[id] = false;
            refreshEmployees();
            MessageBox("info", "Succès", "Employé licencié avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de licencier cet employé.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors du licenciement.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

function payEmployee(id) {
    const loader = document.getElementById('employees-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/payEmployee`, {
        method: 'POST',
        body: JSON.stringify({
            employee: id,
            laboratory: currentEmployeesLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            if (!currentEmployeesHired[id]) {
                currentEmployeesHired[id] = {};
            }
            currentEmployeesHired[id].lastPay = Math.floor(Date.now() / 1000);
            refreshEmployees();
            MessageBox("info", "Succès", "Employé payé avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de payer cet employé.");
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
        console.log('Employees Management: Received show event:', event.data);
        
        if (event.data.laboratory && event.data.laboratory.id) {
            console.log('Employees Management: Laboratory data:', JSON.stringify(event.data.laboratory));
            currentEmployeesHired = normalizeEmployeesData(event.data.laboratory.employees);
            console.log('Normalized employees:', currentEmployeesHired);
            currentEmployeesLabId = event.data.laboratory.id;
            currentEmployeesLabType = event.data.laboratory.type || null;
            console.log('Lab type:', currentEmployeesLabType);
            window.addEventListener('desktopInitialized', () => {
                console.log('Employees Management: Desktop initialized, refreshing employees');
                setTimeout(refreshEmployees, 0);
            }, { once: true });
        }
    }
});
