/**
 * Null UI - Module HUD
 * Système de HUD dynamique compatible ESX
 */

const NullHUD = {
    // Éléments HUD enregistrés
    _elements: [],
    
    // Container DOM
    _container: null,

    /**
     * Initialiser le module HUD
     */
    init() {
        this._container = document.getElementById('hud');
        if (!this._container) {
            console.error('[NullHUD] Container #hud not found');
            return;
        }

        // Enregistrer les handlers d'événements
        NullEvents.on('setHUDDisplay', (data) => this.setDisplay(data.opacity));
        NullEvents.on('insertHUDElement', (data) => this.insert(data.name, data.index, data.priority, data.html, data.data));
        NullEvents.on('updateHUDElement', (data) => this.update(data.name, data.data));
        NullEvents.on('deleteHUDElement', (data) => this.delete(data.name));
        NullEvents.on('hideUi', (data) => this.setVisibility(!data.value));
        NullEvents.on('fadeUi', (data) => this.fade(!data.value));
    },

    /**
     * Définir l'opacité du HUD
     * @param {number} opacity - Opacité (0-1)
     */
    setDisplay(opacity) {
        if (this._container) {
            this._container.style.opacity = NullUtils.clamp(opacity, 0, 1);
        }
        NullState.set('ui.hudOpacity', opacity);
    },

    /**
     * Définir la visibilité du HUD
     * @param {boolean} visible - Visible ou non
     */
    setVisibility(visible) {
        if (this._container) {
            this._container.style.display = visible ? 'block' : 'none';
        }
        NullState.set('ui.visible', visible);
    },

    /**
     * Fade in/out du HUD
     * @param {boolean} visible - Visible ou non
     * @param {number} duration - Durée en ms
     */
    fade(visible, duration = 500) {
        if (!this._container) return;
        
        this._container.style.transition = `opacity ${duration}ms ease`;
        this._container.style.opacity = visible ? 1 : 0;
        
        if (!visible) {
            setTimeout(() => {
                this._container.style.display = 'none';
            }, duration);
        } else {
            this._container.style.display = 'block';
        }
        
        NullState.set('ui.visible', visible);
    },

    /**
     * Insérer un élément HUD
     * @param {string} name - Nom unique de l'élément
     * @param {number} index - Index de tri
     * @param {number} priority - Priorité (plus haut = plus prioritaire)
     * @param {string} html - Template HTML (Mustache)
     * @param {Object} data - Données pour le template
     */
    insert(name, index, priority, html, data) {
        // Supprimer si existe déjà
        this._elements = this._elements.filter(el => el.name !== name);
        
        // Ajouter le nouvel élément
        this._elements.push({
            name,
            index: index || 0,
            priority: priority || 0,
            html,
            data: data || {}
        });

        // Trier par index puis par priorité
        this._elements.sort((a, b) => {
            return a.index - b.index || b.priority - a.priority;
        });

        this._render();
    },

    /**
     * Mettre à jour les données d'un élément HUD
     * @param {string} name - Nom de l'élément
     * @param {Object} data - Nouvelles données
     */
    update(name, data) {
        const element = this._elements.find(el => el.name === name);
        if (element) {
            element.data = { ...element.data, ...data };
            this._render();
        }
    },

    /**
     * Supprimer un élément HUD
     * @param {string} name - Nom de l'élément
     */
    delete(name) {
        this._elements = this._elements.filter(el => el.name !== name);
        this._render();
    },

    /**
     * Obtenir un élément HUD par son nom
     * @param {string} name - Nom de l'élément
     * @returns {Object|null} - Élément ou null
     */
    get(name) {
        return this._elements.find(el => el.name === name) || null;
    },

    /**
     * Obtenir tous les éléments HUD
     * @returns {Array} - Liste des éléments
     */
    getAll() {
        return [...this._elements];
    },

    /**
     * Vider tous les éléments HUD
     */
    clear() {
        this._elements = [];
        this._render();
    },

    /**
     * Rendre le HUD
     */
    _render() {
        if (!this._container) return;

        let html = '';
        for (const element of this._elements) {
            try {
                html += Mustache.render(element.html, element.data);
            } catch (e) {
                console.error(`[NullHUD] Error rendering element "${element.name}":`, e);
            }
        }
        
        this._container.innerHTML = html;
    }
};

// Export global
window.NullHUD = NullHUD;
