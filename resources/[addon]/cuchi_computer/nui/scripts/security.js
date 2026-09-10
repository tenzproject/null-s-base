let pendingSecurityInit = false;
let currentHistory = {
    enter: [],
    exit: [],
    treatment: []
};
let currentTab = 'enter';
let currentPage = 1;
const itemsPerPage = 5;
let searchTerm = '';
let sortOrder = 'time-desc';

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleString('fr-FR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

function sortData(data) {
    return [...data].sort((a, b) => {
        switch (sortOrder) {
            case 'time-desc':
                return new Date(b.time) - new Date(a.time);
            case 'time-asc':
                return new Date(a.time) - new Date(b.time);
            case 'name-asc':
                return `${a.firstname} ${a.lastname}`.localeCompare(`${b.firstname} ${b.lastname}`);
            case 'name-desc':
                return `${b.firstname} ${b.lastname}`.localeCompare(`${a.firstname} ${a.lastname}`);
            default:
                return 0;
        }
    });
}

function filterData(data) {
    if (!searchTerm) return data;
    
    const term = searchTerm.toLowerCase();
    return data.filter(item => 
        item.name.toLowerCase().includes(term) ||
        item.firstname.toLowerCase().includes(term) ||
        item.lastname.toLowerCase().includes(term) ||
        item.idunique.toString().includes(term)
    );
}

function updateContent() {
    console.log('Updating content with:', { currentTab, currentHistory });
    const container = document.getElementById('security-content');
    if (!container) return;

    const data = currentHistory[currentTab] || [];
    const filteredData = filterData(sortData(data));
    const totalPages = Math.ceil(filteredData.length / itemsPerPage);
    const start = (currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    const pageData = filteredData.slice(start, end);

    container.innerHTML = pageData.map(item => `
        <div class="security-item">
            <div class="security-item-header">
                <span class="security-item-name">${item.firstname} ${item.lastname}</span>
                <span class="security-item-time">${formatDate(item.time)}</span>
            </div>
            <div class="security-item-details">
                ID: ${item.idunique}
            </div>
        </div>
    `).join('');

    // Mettre à jour la pagination
    const pageInfo = document.getElementById('security-page-info');
    if (pageInfo) {
        pageInfo.textContent = `Page ${currentPage} sur ${totalPages || 1}`;
    }

    const prevBtn = document.getElementById('security-prev-page');
    const nextBtn = document.getElementById('security-next-page');
    if (prevBtn) prevBtn.disabled = currentPage <= 1;
    if (nextBtn) nextBtn.disabled = currentPage >= totalPages;
}

function initializeSecurity() {
    console.log('Attempting to initialize security...');
    const container = document.getElementById('security-content');
    if (!container) {
        console.log('Security container not found, setting pending init');
        pendingSecurityInit = true;
        return;
    }

    console.log('Security container found, initializing');
    pendingSecurityInit = false;

    // Configurer les événements
    const tabs = document.querySelectorAll('.security-tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            currentTab = tab.dataset.tab;
            currentPage = 1;
            updateContent();
        });
    });

    const searchInput = document.getElementById('security-search');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            searchTerm = e.target.value;
            currentPage = 1;
            updateContent();
        });
    }

    const sortSelect = document.getElementById('security-sort');
    if (sortSelect) {
        sortSelect.addEventListener('change', (e) => {
            sortOrder = e.target.value;
            updateContent();
        });
    }

    const prevBtn = document.getElementById('security-prev-page');
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            if (currentPage > 1) {
                currentPage--;
                updateContent();
            }
        });
    }

    const nextBtn = document.getElementById('security-next-page');
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            const filteredData = filterData(currentHistory[currentTab] || []);
            const totalPages = Math.ceil(filteredData.length / itemsPerPage);
            if (currentPage < totalPages) {
                currentPage++;
                updateContent();
            }
        });
    }

    updateContent();
}

function checkPendingSecurityInit() {
    if (pendingSecurityInit) {
        console.log('Checking pending security init...');
        initializeSecurity();
    }
}

// Vérifier périodiquement s'il y a une initialisation en attente
setInterval(checkPendingSecurityInit, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Security: Received show event', event.data);
        
        // Réinitialiser les données
        if (event.data.history) {
            console.log('Security: Received history data:', event.data.history);
            currentHistory = {
                enter: event.data.history.enter || [],
                exit: event.data.history.exit || [],
                treatment: event.data.history.treatment || []
            };
        } else {
            console.log('Security: No history data received');
            currentHistory = { enter: [], exit: [], treatment: [] };
        }
        
        currentPage = 1;
        searchTerm = '';
        sortOrder = 'time-desc';
        pendingSecurityInit = false;
        
        // Attendre que le bureau soit initialisé
        window.addEventListener('desktopInitialized', () => {
            console.log('Security: Desktop initialized, initializing security');
            setTimeout(initializeSecurity, 0);
        }, { once: true });
    }
});
