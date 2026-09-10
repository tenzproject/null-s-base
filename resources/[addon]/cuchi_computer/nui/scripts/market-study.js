/**
 * Market Study Application
 * Analyse du marché pour les laboratoires
 */

let marketData = {};
let marketChart = null;
let currentDrug = '';
let currentPeriod = 7; // Période par défaut: 7 jours

/**
 * Formate un timestamp en date lisible
 * @param {number} timestamp - Timestamp UNIX en secondes
 * @returns {string} Date formatée
 */
function formatDate(timestamp) {
    // Vérifier si le timestamp est valide
    if (!timestamp || timestamp === 0) {
        return 'N/A';
    }
    
    // Si le timestamp est en millisecondes, le convertir en secondes
    const ts = timestamp > 10000000000 ? timestamp / 1000 : timestamp;
    
    const date = new Date(ts * 1000);
    
    // Vérifier si la date est valide
    if (isNaN(date.getTime())) {
        return 'N/A';
    }
    
    return date.toLocaleDateString('fr-FR', { 
        day: '2-digit', 
        month: '2-digit',
        year: '2-digit'
    });
}

/**
 * Formate un prix avec séparateur de milliers
 */
function formatPrice(price) {
    return new Intl.NumberFormat('fr-FR').format(Math.round(price)) + '$';
}

/**
 * Met à jour le sélecteur de produits
 */
function updateDrugSelector() {
    const select = document.getElementById('market-study-drug-select');
    if (!select) return;
    
    select.innerHTML = '<option value="">Sélectionner un produit</option>';
    
    // Récupérer toutes les drogues disponibles
    const drugs = new Set();
    Object.values(marketData).forEach(entry => {
        if (entry.drugs) {
            Object.keys(entry.drugs).forEach(drug => {
                if (!entry.drugs[drug].hide) {
                    drugs.add(drug);
                }
            });
        }
    });

    // Ajouter les options
    drugs.forEach(drug => {
        const option = document.createElement('option');
        option.value = drug;
        const firstEntry = Object.values(marketData)[0];
        option.textContent = firstEntry?.drugs[drug]?.label || drug;
        select.appendChild(option);
    });

    // Sélectionner automatiquement le premier produit si disponible
    if (drugs.size > 0 && !currentDrug) {
        currentDrug = Array.from(drugs)[0];
        select.value = currentDrug;
        updateStats();
        createChart();
    }
}

/**
 * Met à jour les statistiques affichées
 */
function updateStats() {
    if (!currentDrug || !marketData || Object.keys(marketData).length === 0) {
        document.getElementById('market-study-current-price').textContent = '--$';
        document.getElementById('market-study-avg-price').textContent = '--$';
        document.getElementById('market-study-trend').textContent = '--';
        return;
    }

    // Obtenir les données triées par date
    const sortedData = Object.entries(marketData)
        .filter(([time, data]) => data.drugs && data.drugs[currentDrug])
        .sort(([a], [b]) => parseInt(b) - parseInt(a)) // Du plus récent au plus ancien
        .slice(0, currentPeriod);

    if (sortedData.length === 0) {
        document.getElementById('market-study-current-price').textContent = '--$';
        document.getElementById('market-study-avg-price').textContent = '--$';
        document.getElementById('market-study-trend').textContent = '--';
        return;
    }

    // Prix actuel (le plus récent)
    const currentPrice = sortedData[0][1].drugs[currentDrug].price;
    document.getElementById('market-study-current-price').textContent = formatPrice(currentPrice);

    // Prix moyen sur la période
    const avgPrice = sortedData.reduce((sum, [, data]) => sum + data.drugs[currentDrug].price, 0) / sortedData.length;
    document.getElementById('market-study-avg-price').textContent = formatPrice(avgPrice);

    // Tendance (comparaison entre le prix actuel et le prix moyen)
    const trendElement = document.getElementById('market-study-trend');
    const trendPercent = ((currentPrice - avgPrice) / avgPrice * 100).toFixed(1);
    
    if (trendPercent > 0) {
        trendElement.textContent = `+${trendPercent}%`;
        trendElement.classList.remove('negative');
    } else {
        trendElement.textContent = `${trendPercent}%`;
        trendElement.classList.add('negative');
    }
}

/**
 * Crée ou met à jour le graphique
 */
function createChart() {
    const canvas = document.getElementById('market-study-chart');
    if (!canvas) {
        console.log('Canvas not found');
        return;
    }

    if (!currentDrug || !marketData || Object.keys(marketData).length === 0) {
        if (marketChart) {
            marketChart.destroy();
            marketChart = null;
        }
        return;
    }

    // Filtrer et trier les données
    const sortedData = Object.entries(marketData)
        .filter(([time, data]) => data.drugs && data.drugs[currentDrug])
        .sort(([a], [b]) => parseInt(a) - parseInt(b)) // Du plus ancien au plus récent pour le graphique
        .slice(-currentPeriod); // Prendre seulement les X derniers jours

    if (sortedData.length === 0) {
        if (marketChart) {
            marketChart.destroy();
            marketChart = null;
        }
        return;
    }

    const labels = sortedData.map(([time]) => formatDate(parseInt(time)));
    const prices = sortedData.map(([, data]) => data.drugs[currentDrug].price);
    const requests = sortedData.map(([, data]) => data.drugs[currentDrug].request || 0);

    // Détruire l'ancien graphique si existe
    if (marketChart) {
        marketChart.destroy();
    }

    // Créer le nouveau graphique
    marketChart = new Chart(canvas, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Prix Unitaire',
                    data: prices,
                    borderColor: '#4CAF50',
                    backgroundColor: 'rgba(76, 175, 80, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    yAxisID: 'y',
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    pointBackgroundColor: '#4CAF50',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                },
                {
                    label: 'Demande',
                    data: requests,
                    borderColor: '#2196F3',
                    backgroundColor: 'rgba(33, 150, 243, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    yAxisID: 'y1',
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    pointBackgroundColor: '#2196F3',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                    labels: {
                        color: 'rgba(255, 255, 255, 0.8)',
                        font: {
                            size: 13,
                            family: 'Ubuntu'
                        },
                        padding: 15,
                        usePointStyle: true,
                        pointStyle: 'circle'
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    titleColor: '#fff',
                    bodyColor: '#fff',
                    borderColor: 'rgba(255, 255, 255, 0.1)',
                    borderWidth: 1,
                    padding: 12,
                    displayColors: true,
                    callbacks: {
                        label: function(context) {
                            let label = context.dataset.label || '';
                            if (label) {
                                label += ': ';
                            }
                            if (context.parsed.y !== null) {
                                if (context.datasetIndex === 0) {
                                    label += formatPrice(context.parsed.y);
                                } else {
                                    label += Math.round(context.parsed.y);
                                }
                            }
                            return label;
                        }
                    }
                }
            },
            scales: {
                y: {
                    type: 'linear',
                    display: true,
                    position: 'left',
                    title: {
                        display: true,
                        text: 'Prix ($)',
                        color: 'rgba(255, 255, 255, 0.7)',
                        font: {
                            size: 13,
                            family: 'Ubuntu'
                        }
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.6)',
                        font: {
                            size: 11
                        },
                        callback: function(value) {
                            return formatPrice(value);
                        }
                    },
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    }
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    title: {
                        display: true,
                        text: 'Demande',
                        color: 'rgba(255, 255, 255, 0.7)',
                        font: {
                            size: 13,
                            family: 'Ubuntu'
                        }
                    },
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.6)',
                        font: {
                            size: 11
                        }
                    },
                    grid: {
                        drawOnChartArea: false,
                        drawBorder: false
                    }
                },
                x: {
                    ticks: {
                        color: 'rgba(255, 255, 255, 0.6)',
                        font: {
                            size: 11
                        },
                        maxRotation: 45,
                        minRotation: 0
                    },
                    grid: {
                        color: 'rgba(255, 255, 255, 0.05)',
                        drawBorder: false
                    }
                }
            }
        }
    });
}

/**
 * Initialise les événements
 */
function initializeEvents() {
    // Sélecteur de produit
    const drugSelect = document.getElementById('market-study-drug-select');
    if (drugSelect) {
        drugSelect.addEventListener('change', (e) => {
            currentDrug = e.target.value;
            updateStats();
            createChart();
        });
    }

    // Boutons de période
    const periodButtons = document.querySelectorAll('.period-btn');
    periodButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            // Retirer la classe active de tous les boutons
            periodButtons.forEach(b => b.classList.remove('active'));
            // Ajouter la classe active au bouton cliqué
            btn.classList.add('active');
            // Mettre à jour la période
            currentPeriod = parseInt(btn.dataset.period);
            // Mettre à jour le graphique et les stats
            updateStats();
            createChart();
        });
    });
}

/**
 * Initialisation lors de l'ouverture de l'application
 */
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        // Réinitialiser les données
        marketData = {};
        currentDrug = '';
        currentPeriod = 7;
        
        // Si des données de marché sont fournies
        if (event.data.marketStudy && Object.keys(event.data.marketStudy).length > 0) {
            marketData = event.data.marketStudy;
            
            // Attendre que le bureau soit initialisé
            window.addEventListener('desktopInitialized', () => {
                setTimeout(() => {
                    initializeEvents();
                    updateDrugSelector();
                    updateStats();
                    createChart();
                }, 100);
            }, { once: true });
        }
    }
});
