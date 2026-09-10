let marketData = {};
let marketChart = null;
let pendingChartUpdate = false;
let currentDrug = '';

function formatDate(timestamp) {
    const date = new Date(timestamp * 1000);
    return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
}

function updateDrugSelector() {
    const select = document.getElementById('market-study-drug-select');
    select.innerHTML = '<option value="">Sélectionner une drogue</option>';
    
    // Récupérer toutes les drogues disponibles
    const drugs = new Set();
    Object.values(marketData).forEach(entry => {
        Object.keys(entry.drugs || {}).forEach(drug => {
            if (!entry.drugs[drug].hide) {
                drugs.add(drug);
            }
        });
    });

    // Ajouter les options
    drugs.forEach(drug => {
        const option = document.createElement('option');
        option.value = drug;
        option.textContent = marketData[Object.keys(marketData)[0]]?.drugs[drug]?.label || drug;
        select.appendChild(option);
    });

    // Écouter les changements de sélection
    select.addEventListener('change', (e) => {
        currentDrug = e.target.value;
        updateTodayPrice();
        createChart();
    });
}

function createChart() {
    console.log('Attempting to create chart...');
    const ctx = document.getElementById('market-study-chart');
    if (!ctx) {
        console.log('Chart canvas not found, setting pending update');
        pendingChartUpdate = true;
        return;
    }

    if (!currentDrug) {
        if (marketChart) {
            marketChart.destroy();
            marketChart = null;
        }
        return;
    }

    console.log('Chart canvas found, creating chart');
    pendingChartUpdate = false;

    // Ajuster la taille du canvas pour le DPI de l'écran
    const dpr = window.devicePixelRatio || 1;
    const rect = ctx.parentNode.getBoundingClientRect();
    ctx.width = rect.width * dpr;
    ctx.height = rect.height * dpr;
    const ctx2d = ctx.getContext('2d');
    ctx2d.scale(dpr, dpr);
    
    const sortedData = Object.entries(marketData)
        .sort(([a], [b]) => parseInt(a) - parseInt(b))
        .map(([time, data]) => ({
            time: parseInt(time),
            ...data.drugs[currentDrug]
        }));

    const labels = sortedData.map(data => formatDate(data.time));
    const prices = sortedData.map(data => data.price);
    const requests = sortedData.map(data => data.request);

    if (marketChart) {
        marketChart.destroy();
    }

    marketChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Prix Unitaire ($)',
                    data: prices,
                    borderColor: 'rgb(0, 255, 60)',
                    borderWidth: 2,
                    tension: 0.1,
                    yAxisID: 'y'
                },
                {
                    label: 'Demande',
                    data: requests,
                    borderColor: 'rgb(255, 99, 132)',
                    borderWidth: 2,
                    tension: 0.1,
                    yAxisID: 'y1'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            devicePixelRatio: dpr,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            stacked: false,
            plugins: {
                legend: {
                    labels: {
                        font: {
                            size: 14
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
                        font: {
                            size: 14
                        }
                    },
                    ticks: {
                        font: {
                            size: 12
                        }
                    }
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    title: {
                        display: true,
                        text: 'Quantité',
                        font: {
                            size: 14
                        }
                    },
                    ticks: {
                        font: {
                            size: 12
                        }
                    },
                    grid: {
                        drawOnChartArea: false
                    }
                },
                x: {
                    ticks: {
                        font: {
                            size: 12
                        }
                    }
                }
            }
        }
    });
}

function checkPendingChartUpdate() {
    if (pendingChartUpdate) {
        console.log('Checking pending chart update...');
        createChart();
    }
}

// Vérifier périodiquement s'il y a une mise à jour du graphique en attente
setInterval(checkPendingChartUpdate, 100);

function updateTodayPrice() {
    const priceElement = document.getElementById('market-study-today-price');
    if (!priceElement) return;

    if (currentDrug && marketData) {
        const latestTime = Math.max(...Object.keys(marketData).map(Number));
        const today = marketData[latestTime];
        if (today && today.drugs && today.drugs[currentDrug]) {
            priceElement.textContent = today.drugs[currentDrug].price + '$';
            return;
        }
    }
    priceElement.textContent = '--$';
}

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Market Study: Received show event', event.data);
        
        // Réinitialiser les données
        marketData = {};
        pendingChartUpdate = false;
        currentDrug = '';
        
        // Si des données de marché sont fournies
        if (event.data.marketStudy) {
            console.log('Market Study: Data received', event.data.marketStudy);
            marketData = event.data.marketStudy;
            
            // Attendre que le bureau soit initialisé avant de créer le graphique
            window.addEventListener('desktopInitialized', () => {
                console.log('Market Study: Desktop initialized, creating chart');
                setTimeout(() => {
                    updateDrugSelector();
                    updateTodayPrice();
                    createChart();
                }, 0);
            }, { once: true });
        }
    }
});
