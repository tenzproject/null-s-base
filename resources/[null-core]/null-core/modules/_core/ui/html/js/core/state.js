/**
 * Null UI - State Manager
 * Gestion centralisée de l'état de l'UI
 */

const NullState = {
    // État global
    _state: {
        // Position du joueur (pour les sons 3D)
        playerPosition: [0, 0, 0],
        
        // Configuration serveur
        serverConfig: {
            name: 'Null',
            color: '#9b59b6',
            icon: '',
            discord: ''
        },
        
        // État de l'UI
        ui: {
            visible: true,
            hudOpacity: 1.0,
            focusActive: false
        },
        
        // Langue
        lang: {}
    },

    // Observers pour les changements d'état
    _observers: {},

    /**
     * Obtenir une valeur de l'état
     * @param {string} path - Chemin de la propriété (ex: "ui.visible")
     * @returns {*} - Valeur
     */
    get(path) {
        const keys = path.split('.');
        let value = this._state;
        
        for (const key of keys) {
            if (value === undefined) return undefined;
            value = value[key];
        }
        
        return value;
    },

    /**
     * Définir une valeur dans l'état
     * @param {string} path - Chemin de la propriété
     * @param {*} value - Nouvelle valeur
     */
    set(path, value) {
        const keys = path.split('.');
        let obj = this._state;
        
        for (let i = 0; i < keys.length - 1; i++) {
            const key = keys[i];
            if (!obj[key]) obj[key] = {};
            obj = obj[key];
        }
        
        const lastKey = keys[keys.length - 1];
        const oldValue = obj[lastKey];
        obj[lastKey] = value;
        
        // Notifier les observers
        this._notifyObservers(path, value, oldValue);
    },

    /**
     * Observer les changements d'une propriété
     * @param {string} path - Chemin de la propriété
     * @param {Function} callback - Fonction appelée lors des changements
     * @returns {Function} - Fonction pour se désabonner
     */
    observe(path, callback) {
        if (!this._observers[path]) {
            this._observers[path] = [];
        }
        this._observers[path].push(callback);
        
        // Retourner une fonction pour se désabonner
        return () => {
            const index = this._observers[path].indexOf(callback);
            if (index > -1) {
                this._observers[path].splice(index, 1);
            }
        };
    },

    /**
     * Notifier les observers d'un changement
     * @param {string} path - Chemin modifié
     * @param {*} newValue - Nouvelle valeur
     * @param {*} oldValue - Ancienne valeur
     */
    _notifyObservers(path, newValue, oldValue) {
        // Notifier les observers exacts
        if (this._observers[path]) {
            this._observers[path].forEach(cb => cb(newValue, oldValue, path));
        }
        
        // Notifier les observers parents (ex: "ui" quand "ui.visible" change)
        const parts = path.split('.');
        for (let i = parts.length - 1; i > 0; i--) {
            const parentPath = parts.slice(0, i).join('.');
            if (this._observers[parentPath]) {
                this._observers[parentPath].forEach(cb => cb(this.get(parentPath), null, parentPath));
            }
        }
    },

    /**
     * Mettre à jour la position du joueur
     * @param {number} x 
     * @param {number} y 
     * @param {number} z 
     */
    updatePlayerPosition(x, y, z) {
        this._state.playerPosition = [x, y, z];
    },

    /**
     * Obtenir la position du joueur
     * @returns {Array} - [x, y, z]
     */
    getPlayerPosition() {
        return this._state.playerPosition;
    },

    /**
     * Initialiser avec les événements
     */
    init() {
        // Écouter les mises à jour de position
        NullEvents.on('position', (data) => {
            this.updatePlayerPosition(data.x, data.y, data.z);
        });

        // Écouter la configuration serveur
        NullEvents.on('setConfig', (data) => {
            if (data.serverName) this.set('serverConfig.name', data.serverName);
            if (data.serverColor) this.set('serverConfig.color', data.serverColor);
            if (data.serverIcon) this.set('serverConfig.icon', data.serverIcon);
            if (data.serverDiscord) this.set('serverConfig.discord', data.serverDiscord);
        });

        // Écouter les changements de langue
        NullEvents.on('setLang', (data) => {
            this.set('lang', data.lang || {});
        });
    }
};

// Export global
window.NullState = NullState;
