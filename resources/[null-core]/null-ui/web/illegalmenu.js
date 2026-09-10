const illegalBossManager = {
    currentGang: null,
    currentCategory: null,
    gangList: null,
    myData: null,

    init() {
        // Gestionnaire de catégories
        $('.illegal-boss-categories .category').on('click', (e) => {
            const cat = $(e.currentTarget);
            $('.illegal-boss-categories .category').removeClass('active');
            cat.addClass('active');
            this.currentCategory = cat.data('category');
            this.loadCategory(this.currentCategory);
        });

        // Gestionnaire de fermeture
        $('.close-illegal-boss').on('click', () => {
            this.hide();
            fetch(`https://null-ui/illegal:close`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        });

        // Gestionnaire de recherche
        $('.recruitment-search input').on('input', function() {
            const searchTerm = $(this).val().toLowerCase();
            $('.player-card').each(function() {
                const playerName = $(this).find('.player-name').text().toLowerCase();
                $(this).toggle(playerName.includes(searchTerm));
            });
        });
    },

    loadCategory(category) {
        const container = $('.illegal-boss-content');
        container.html('<div class="loading">Chargement...</div>');
        
        switch(category) {
            case 'home':
                this.loadHome();
                break;
            case 'members':
                this.loadMembers();
                break;
            case 'grades':
                this.loadGrades();
                break;
            case 'salary':
                this.loadSalaries();
                break;
        }
    },

    hasPermissionForCategory(category) {
        if (!this.currentGang || !this.myData) return false;
        
        const grade = this.myData.grade.toString();
        
        switch(category) {
            case 'members':
                return this.currentGang.perms_gestionmembre[grade];
            case 'recruitment':
                return this.currentGang.perms_recruter[grade];
            case 'grades':
                return this.currentGang.perms_promouvoir[grade];
            case 'salary':
                return this.currentGang.perms_gestionmembre[grade];
            default:
                return false;
        }
    },

    show(data) {
        this.currentGang = data.myGang;
        this.gangList = data.gangList;
        this.myData = data.myData;
        this.currentCategory = 'home';
        
        // Mise à jour des infos utilisateur
        if (this.currentGang && this.currentGang.GradeList && this.myData) {
            const grade = this.currentGang.GradeList[this.myData.grade.toString()];
            if (grade) {
                $('.illegal-boss-user-info .grades').text(grade.label);
            }
            $('.illegal-boss-user-info .idunique').text(this.myData.idunique);
        }
        
        // Afficher/Cacher les catégories selon les permissions
        $(`.illegal-boss-categories .category`).each((_, el) => {
            const category = $(el).data('category');
            if (category === 'home') return; // Toujours afficher l'accueil
            $(el).toggle(this.hasPermissionForCategory(category));
        });
        
        // Charger la page d'accueil par défaut
        this.loadCategory('home');
        
        // Afficher l'interface
        $('.illegal-boss-container').fadeIn(300);
    },

    hide() {
        $('.illegal-boss-container').fadeOut(300);
    },

    updateUserInfo(data) {
        if (data.idunique) {
            $('.illegal-boss-user-info .idunique').text(data.idunique);
        }
        
        if (data.grade_name && this.currentGang && this.currentGang.GradeList) {
            const grade = this.currentGang.GradeList[data.grade];
            if (grade) {
                $('.illegal-boss-user-info .grades').text(grade.label);
            }
        }
    },

    loadMembers() {
        const container = $('.illegal-boss-content');
        container.empty();

        container.append($(`
            <div class="members-list"></div>
        `));

        const membersList = $('.members-list');
        
        if (!this.currentGang || !this.currentGang.PlyList) {
            console.error('Aucune donnée de gang ou liste de joueurs disponible');
            return;
        }

        Object.entries(this.currentGang.PlyList).forEach(([_, member]) => {
            const grade = this.currentGang.GradeList[member.job2_grade.toString()];
            const memberCard = $(`
                <div class="member-card">
                    <div class="member-info">
                        <div class="member-name">${member.firstname || member.name} ${member.lastname || ''} (${member.idunique})</div>
                        <div class="member-grade">${grade ? grade.label : 'Inconnu'}</div>
                    </div>
                    <div class="member-actions">
                        <button class="member-action-btn promote" data-id="${member.identifier}">
                            <i class="fas fa-arrow-up"></i>
                        </button>
                        <button class="member-action-btn demote" data-id="${member.identifier}">
                            <i class="fas fa-arrow-down"></i>
                        </button>
                        <button class="member-action-btn fire" data-id="${member.identifier}">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            `);

            memberCard.find('.promote').on('click', () => this.promoteMember(member.identifier));
            memberCard.find('.demote').on('click', () => this.demoteMember(member.identifier));
            memberCard.find('.fire').on('click', () => this.fireMember(member.identifier));

            membersList.append(memberCard);
        });
    },

    loadGrades() {
        const container = $('.illegal-boss-content');
        container.empty();

        container.append($(`
            <div class="grades-list"></div>
        `));

        const gradesList = $('.grades-list');
        gradesList.empty();

        if (!this.currentGang || !this.currentGang.GradeList) {
            console.error('Aucune donnée de grades disponible');
            return;
        }
        Object.entries(this.currentGang.GradeList).forEach(([gradeId, grade]) => {
            const gradeItem = $(`
                <div class="grade-item">
                    <div class="grade-name">${grade.label}</div>
                    <div class="grade-level">Niveau ${grade.grade}</div>
                </div>
            `);
            gradesList.append(gradeItem);
        });
    },

    loadSalaries() {
        const container = $('.illegal-boss-content');
        container.empty();

        container.append($(`
            <div class="salary-list"></div>
        `));

        const salaryList = $('.salary-list');
        salaryList.empty();

        if (!this.currentGang || !this.currentGang.GradeList) {
            console.error('Aucune donnée de salaires disponible');
            return;
        }

        console.log('Liste des salaires:', JSON.stringify(this.currentGang.GradeList, null, 2));
        Object.entries(this.currentGang.GradeList).forEach(([gradeId, grade]) => {
            const salaryItem = $(`
                <div class="salary-item">
                    <div class="salary-grade">${grade.label}</div>
                    <div class="salary-amount">
                        <input type="number" class="salary-input" value="${grade.salary || 0}" min="0">
                        <button class="save-salary" data-grade="${gradeId}">
                            <i class="fas fa-save"></i>
                        </button>
                    </div>
                </div>
            `);

            salaryItem.find('.save-salary').on('click', () => {
                const newSalary = parseInt(salaryItem.find('.salary-input').val());
                this.updateSalary(gradeId, newSalary);
            });

            salaryList.append(salaryItem);
        });
    },

    loadHome() {
        if (!this.currentGang) {
            console.error('Aucune donnée de gang disponible');
            return;
        }

        const memberCount = Object.keys(this.currentGang.PlyList || {}).length;
        const gradeCount = Object.keys(this.currentGang.GradeList || {}).length;
        const hasWeapons = this.currentGang.KitArme ? true : false;

        const container = $('.illegal-boss-content');
        container.html(`
            <div class="home-container">
                <div class="gang-info-section">
                    <div class="gang-header">
                        <i class="fas fa-users gang-icon"></i>
                        <div class="gang-name">${this.currentGang.label || 'Gang'}</div>
                    </div>
                    
                    <div class="gang-stats">
                        <div class="stat-card">
                            <div class="stat-value">${memberCount}</div>
                            <div class="stat-label">Membres</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${gradeCount}</div>
                            <div class="stat-label">Grades</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">0</div>
                            <div class="stat-label">Territoires</div>
                        </div>
                    </div>

                    <div class="weapons-access">
                        <i class="fas fa-${hasWeapons ? 'check' : 'times'} weapons-icon" style="color: ${hasWeapons ? '#4CAF50' : '#f44336'}"></i>
                        <div class="weapons-text">
                            ${hasWeapons ? 'Accès aux armes autorisé' : 'Accès aux armes non autorisé'}
                        </div>
                    </div>
                </div>

                <div class="territories-section">
                    <div class="territories-header">Territoires</div>
                    <div class="territories-content">
                        Aucun territoire contrôlé pour le moment
                    </div>
                </div>
            </div>
        `);
    },

    promoteMember(identifier) {
        $.post('https://null-ui/illegal:promote', JSON.stringify({ identifier: identifier }));
    },

    demoteMember(identifier) {
        $.post('https://null-ui/illegal:demote', JSON.stringify({ identifier: identifier }));
    },

    fireMember(identifier) {
        $.post('https://null-ui/illegal:fire', JSON.stringify({ identifier: identifier }));
    },

    updateSalary(gradeId, salary) {
        $.post('https://null-ui/illegal:updateSalary', JSON.stringify({ 
            gradeId: gradeId, 
            salary: salary 
        }));
    }
};

// Initialisation
$(document).ready(() => {
    illegalBossManager.init();
});

window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.type) {
        case 'illegal:show':
            illegalBossManager.show(data);
            break;
        case 'illegal:hide':
            illegalBossManager.hide();
            break;
        case 'illegal:updateMembers':
            illegalBossManager.loadMembers();
            break;
        case 'illegal:updateUserInfo':
            illegalBossManager.updateUserInfo(data);
            break;
    }
});