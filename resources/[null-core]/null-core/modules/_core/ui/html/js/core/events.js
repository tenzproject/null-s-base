/**
 * Null UI - Système d'événements
 * Gestion centralisée des événements NUI et internes
 */

const NullEvents = {
    // Handlers enregistrés par action
    _handlers: {},
    
    // Callbacks NUI enregistrés
    _nuiCallbacks: {},

    /**
     * Enregistrer un handler pour une action
     * @param {string} action - Nom de l'action
     * @param {Function} handler - Fonction handler
     */
    on(action, handler) {
        if (!this._handlers[action]) {
            this._handlers[action] = [];
        }
        this._handlers[action].push(handler);
    },

    /**
     * Supprimer un handler
     * @param {string} action - Nom de l'action
     * @param {Function} handler - Fonction handler à supprimer
     */
    off(action, handler) {
        if (!this._handlers[action]) return;
        
        const index = this._handlers[action].indexOf(handler);
        if (index > -1) {
            this._handlers[action].splice(index, 1);
        }
    },

    /**
     * Émettre un événement interne
     * @param {string} action - Nom de l'action
     * @param {*} data - Données à passer
     */
    emit(action, data) {
        if (!this._handlers[action]) return;
        
        this._handlers[action].forEach(handler => {
            try {
                handler(data);
            } catch (e) {
                console.error(`[NullUI] Error in handler for "${action}":`, e);
            }
        });
    },

    /**
     * Envoyer un message au client Lua
     * @param {string} endpoint - Endpoint NUI callback
     * @param {Object} data - Données à envoyer
     * @returns {Promise} - Promesse de la réponse
     */
    async post(endpoint, data = {}) {
        try {
            const response = await fetch(`https://null-core/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (e) {
            console.error(`[NullUI] Error posting to "${endpoint}":`, e);
            return null;
        }
    },

    /**
     * Enregistrer un callback NUI (pour réponses du client)
     * @param {string} name - Nom du callback
     * @param {Function} callback - Fonction callback
     */
    registerCallback(name, callback) {
        this._nuiCallbacks[name] = callback;
    },

    /**
     * Traiter un message entrant du client Lua
     * @param {Object} data - Données reçues
     */
    handleMessage(data) {
        // Vérifier si c'est un callback NUI
        if (data.callback && this._nuiCallbacks[data.callback]) {
            this._nuiCallbacks[data.callback](data);
            return;
        }

        // Traiter comme action normale
        const action = data.action || data.type || data.status;
        if (action) {
            this.emit(action, data);
        }
    },

    /**
     * Initialiser l'écoute des messages NUI
     */
    init() {
        window.addEventListener('message', (event) => {
            this.handleMessage(event.data);
        });

        // Écoute des touches clavier globales
        document.addEventListener('keydown', (event) => {
            this.emit('keydown', { key: event.key, keyCode: event.keyCode, event });
            
            // ESC pour fermer les menus
            if (event.keyCode === 27) {
                this.emit('escape', {});
            }
        });
    }
};

// Export global
window.NullEvents = NullEvents;
