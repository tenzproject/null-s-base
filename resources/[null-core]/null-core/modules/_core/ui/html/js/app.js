/**
 * Null UI - Application principale
 * Point d'entrée et initialisation de tous les modules
 */

const NullUI = {
    // Version
    version: '1.0.0',
    
    // Modules chargés
    modules: {},
    
    // État d'initialisation
    initialized: false,

    /**
     * Initialiser l'application
     */
    init() {
        if (this.initialized) {
            console.warn('[NullUI] Already initialized');
            return;
        }

        // Initialiser le système d'événements en premier
        NullEvents.init();
        
        // Initialiser les bridges
        // NullRageUIBridge.init(); // Désactivé: Menu maintenant intégré dans interactions
        NullUIBridge.init();
        NullInteractionsBridge.init();
        
        // Initialiser le state manager
        NullState.init();
        
        // Initialiser les modules
        this._initModules();
        
        // Enregistrer les handlers globaux
        this._registerGlobalHandlers();
        
        this.initialized = true;

        // Notifier le client Lua que l'UI est prête
        NullEvents.post('ui_ready', { version: this.version });
    },

    /**
     * Initialiser tous les modules
     */
    _initModules() {
        // HUD
        if (typeof NullHUD !== 'undefined') {
            NullHUD.init();
            this.modules.hud = NullHUD;
        }

        // Notifications
        if (typeof NullNotifications !== 'undefined') {
            NullNotifications.init();
            this.modules.notifications = NullNotifications;
        }

        // Sound
        if (typeof NullSound !== 'undefined') {
            NullSound.init();
            this.modules.sound = NullSound;
        }

        // Clipboard
        if (typeof NullClipboard !== 'undefined') {
            NullClipboard.init();
            this.modules.clipboard = NullClipboard;
        }

        // RageUI Bridge - Désactivé: Menu maintenant intégré dans interactions
        // if (typeof NullRageUIBridge !== 'undefined') {
        //     this.modules.rageui = NullRageUIBridge;
        // }

        // Unified UI Bridge (déjà initialisé plus haut, juste l'enregistrer)
        if (typeof NullUIBridge !== 'undefined') {
            this.modules.ui = NullUIBridge;
        }
        
        // Interactions Bridge (gère maintenant aussi le menu RageUI)
        if (typeof NullInteractionsBridge !== 'undefined') {
            this.modules.interactions = NullInteractionsBridge;
        }
    },

    /**
     * Enregistrer les handlers globaux
     */
    _registerGlobalHandlers() {
        // Fermeture avec ESC (sauf pour le context menu qui gère sa propre fermeture)
        NullEvents.on('escape', () => {
            // Ne pas fermer si le context menu est ouvert (il gère sa propre fermeture par clic extérieur)
            // Le context menu est dans l'iframe interactions
            const interactionsIframe = document.getElementById('core-nui');
            if (interactionsIframe && interactionsIframe.style.pointerEvents === 'auto') {
                console.log('[NullUI] Context menu is open, ignoring ESC');
                return;
            }
            this.closeAllMenus();
        });

        // Mise à jour de position du joueur
        NullEvents.on('position', (data) => {
            NullState.updatePlayerPosition(data.x, data.y, data.z);
        });

        // Afficher/Masquer l'UI globale
        NullEvents.on('hideComponent', (data) => {
            const element = document.getElementById(data.component);
            if (element) {
                element.style.display = data.value ? 'none' : 'block';
            }
        });

        // Mise à jour des statuts (barres de vie, faim, soif, etc.)
        NullEvents.on('updateStatus', (data) => {
            this._updateStatusBars(data.status);
        });

        NullEvents.on('setStatuts', (data) => {
            this._updateStatusBars(data.statuts);
        });
    },

    /**
     * Mettre à jour les barres de statut
     * @param {Array} statuts - Liste des statuts
     */
    _updateStatusBars(statuts) {
        if (!Array.isArray(statuts)) return;

        statuts.forEach(status => {
            const bar = document.querySelector(`.progress-${status.name}`);
            if (bar) {
                bar.style.width = `${status.percent || status.value}%`;
            }
        });
    },

    /**
     * Fermer tous les menus ouverts
     */
    closeAllMenus() {
        // Émettre un événement pour que les menus se ferment
        NullEvents.emit('menu:closeAll', {});
        
        // Notifier le client Lua
        NullEvents.post('closeMenu', {});
    },

    /**
     * Obtenir un module
     * @param {string} name - Nom du module
     * @returns {Object|null}
     */
    getModule(name) {
        return this.modules[name] || null;
    },

    /**
     * Enregistrer un nouveau module
     * @param {string} name - Nom du module
     * @param {Object} module - Instance du module
     */
    registerModule(name, module) {
        if (this.modules[name]) {
            console.warn(`[NullUI] Module "${name}" already registered`);
            return;
        }
        
        this.modules[name] = module;
        
        if (typeof module.init === 'function') {
            module.init();
        }
        
    }
};

// Alias pour compatibilité ESX
const ESX = {
    HUDElements: [],
    
    setHUDDisplay(opacity) {
        NullHUD.setDisplay(opacity);
    },
    
    insertHUDElement(name, index, priority, html, data) {
        NullHUD.insert(name, index, priority, html, data);
    },
    
    updateHUDElement(name, data) {
        NullHUD.update(name, data);
    },
    
    deleteHUDElement(name) {
        NullHUD.delete(name);
    },
    
    refreshHUD() {
        NullHUD._render();
    },
    
    inventoryNotification(add, label, count) {
        NullNotifications.inventory(add, label, count);
    }
};

// Initialiser au chargement de la page
window.addEventListener('load', () => {
    NullUI.init();
});

// Export global
window.NullUI = NullUI;
window.ESX = ESX;
