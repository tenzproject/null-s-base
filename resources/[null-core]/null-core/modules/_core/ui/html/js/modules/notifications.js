/**
 * Null UI - Module Notifications
 * Système de notifications et alertes
 */

const NullNotifications = {
    // Container DOM
    _container: null,
    _inventoryContainer: null,
    
    // Stack des notifications inventaire (pour regrouper les mêmes items)
    _inventoryStack: {},
    _inventoryElements: {},
    _inventoryTimeouts: {},
    
    // Configuration
    _config: {
        duration: 5000,
        maxNotifications: 5,
        soundEnabled: true,
        soundFile: 'sounds/notification.ogg',
        soundVolume: 0.1
    },

    /**
     * Initialiser le module
     */
    init() {
        this._container = document.getElementById('notifications');
        this._inventoryContainer = document.getElementById('inventory-notifications');
        
        if (!this._container) {
            console.error('[NullNotifications] Container #notifications not found');
        }

        // Enregistrer les handlers d'événements
        NullEvents.on('notify', (data) => this.show(data.text, data.type, data.duration));
        NullEvents.on('Notify', (data) => this.show(data.text, 'info', data.duration));
        // Inventory notifications are now rendered by the React HUD module (ui/web InventoryNotifications).
        // Legacy handler removed to avoid duplicate UI.
    },

    /**
     * Configurer le module
     * @param {Object} config - Configuration
     */
    configure(config) {
        this._config = { ...this._config, ...config };
    },

    /**
     * Afficher une notification
     * @param {string} text - Texte de la notification
     * @param {string} type - Type (info, success, warning, error)
     * @param {number} duration - Durée en ms (optionnel)
     */
    show(text, type = 'info', duration = null) {
        if (!this._container) return;

        const id = NullUtils.generateId('notif');
        const notifDuration = duration || this._config.duration;

        // Créer l'élément
        const notif = document.createElement('div');
        notif.id = id;
        notif.className = `notification notification-${type}`;
        notif.innerHTML = `
            <div class="notification-icon">
                <i class="fa ${this._getIcon(type)}"></i>
            </div>
            <div class="notification-content">
                <span class="notification-text">${text}</span>
            </div>
            <div class="notification-progress">
                <div class="notification-progress-bar" style="animation-duration: ${notifDuration}ms"></div>
            </div>
        `;

        // Limiter le nombre de notifications
        while (this._container.children.length >= this._config.maxNotifications) {
            this._container.removeChild(this._container.firstChild);
        }

        // Ajouter au container
        this._container.appendChild(notif);

        // Jouer le son
        if (this._config.soundEnabled) {
            this._playSound();
        }

        // Animation d'entrée
        requestAnimationFrame(() => {
            notif.classList.add('notification-show');
        });

        // Supprimer après la durée
        setTimeout(() => {
            this._remove(notif);
        }, notifDuration);

        return id;
    },

    /**
     * Notification d'inventaire (ajout/retrait d'item)
     * Système de stacking : cumule les quantités pour le même item
     * @param {boolean} add - Ajout (true) ou retrait (false)
     * @param {string} label - Label de l'item
     * @param {number} count - Quantité
     */
    inventory(add, label, count = 1) {
        if (!this._inventoryContainer) return;

        // Clé unique pour cet item (type + label)
        const key = `${add ? 'add' : 'remove'}_${label}`;
        
        // Si une notification existe déjà pour cet item, on cumule
        if (this._inventoryStack[key] !== undefined) {
            this._inventoryStack[key] += count;
            this._updateInventoryNotification(key, add, label);
            this._resetInventoryTimeout(key, add, label);
            return;
        }

        // Nouvelle notification
        this._inventoryStack[key] = count;
        this._createInventoryNotification(key, add, label);
        this._resetInventoryTimeout(key, add, label);
    },

    /**
     * Créer une nouvelle notification d'inventaire
     */
    _createInventoryNotification(key, add, label) {
        const count = this._inventoryStack[key];
        const sign = add ? '+' : '-';
        const text = `${sign}${count} ${label}`;

        const notif = document.createElement('div');
        notif.className = `inventory-notification ${add ? 'add' : 'remove'}`;
        notif.setAttribute('data-key', key);
        
        // Structure simple : juste le texte
        notif.innerHTML = `<span class="inv-text">${text}</span>`;

        this._inventoryContainer.appendChild(notif);
        this._inventoryElements[key] = notif;

        // Animation d'entrée
        requestAnimationFrame(() => {
            notif.classList.add('show');
        });
    },

    /**
     * Mettre à jour une notification existante (stacking)
     */
    _updateInventoryNotification(key, add, label) {
        const notif = this._inventoryElements[key];
        if (!notif) return;

        const count = this._inventoryStack[key];
        const sign = add ? '+' : '-';
        const text = `${sign}${count} ${label}`;

        const textEl = notif.querySelector('.inv-text');
        if (textEl) {
            textEl.textContent = text;
        }

        // Animation de "bump" pour indiquer le cumul
        notif.classList.remove('bump');
        void notif.offsetWidth; // Force reflow
        notif.classList.add('bump');
    },

    /**
     * Reset le timeout de suppression d'une notification
     */
    _resetInventoryTimeout(key, add, label) {
        // Annuler le timeout précédent
        if (this._inventoryTimeouts[key]) {
            clearTimeout(this._inventoryTimeouts[key]);
        }

        // Nouveau timeout
        this._inventoryTimeouts[key] = setTimeout(() => {
            this._removeInventoryNotification(key);
        }, 3000);
    },

    /**
     * Supprimer une notification d'inventaire
     */
    _removeInventoryNotification(key) {
        const notif = this._inventoryElements[key];
        if (!notif) return;

        notif.classList.add('fade-out');
        notif.classList.remove('show');

        setTimeout(() => {
            if (notif.parentNode) {
                notif.parentNode.removeChild(notif);
            }
            delete this._inventoryStack[key];
            delete this._inventoryElements[key];
            delete this._inventoryTimeouts[key];
        }, 300);
    },

    /**
     * Notification de succès
     * @param {string} text - Texte
     * @param {number} duration - Durée
     */
    success(text, duration) {
        return this.show(text, 'success', duration);
    },

    /**
     * Notification d'erreur
     * @param {string} text - Texte
     * @param {number} duration - Durée
     */
    error(text, duration) {
        return this.show(text, 'error', duration);
    },

    /**
     * Notification d'avertissement
     * @param {string} text - Texte
     * @param {number} duration - Durée
     */
    warning(text, duration) {
        return this.show(text, 'warning', duration);
    },

    /**
     * Notification d'information
     * @param {string} text - Texte
     * @param {number} duration - Durée
     */
    info(text, duration) {
        return this.show(text, 'info', duration);
    },

    /**
     * Supprimer une notification
     * @param {HTMLElement|string} notif - Élément ou ID
     */
    _remove(notif) {
        if (typeof notif === 'string') {
            notif = document.getElementById(notif);
        }
        if (!notif) return;

        notif.classList.add('notification-hide');
        setTimeout(() => {
            if (notif.parentNode) {
                notif.parentNode.removeChild(notif);
            }
        }, 300);
    },

    /**
     * Obtenir l'icône selon le type
     * @param {string} type - Type de notification
     * @returns {string} - Classe Font Awesome
     */
    _getIcon(type) {
        const icons = {
            info: 'fa-info-circle',
            success: 'fa-check-circle',
            warning: 'fa-exclamation-triangle',
            error: 'fa-times-circle'
        };
        return icons[type] || icons.info;
    },

    /**
     * Jouer le son de notification
     */
    _playSound() {
        try {
            const audio = new Audio(this._config.soundFile);
            audio.volume = this._config.soundVolume;
            audio.play().catch(() => {}); // Ignorer les erreurs autoplay
        } catch (e) {
            // Ignorer les erreurs audio
        }
    },

    /**
     * Vider toutes les notifications
     */
    clear() {
        if (this._container) {
            this._container.innerHTML = '';
        }
        if (this._inventoryContainer) {
            this._inventoryContainer.innerHTML = '';
        }
    }
};

// Export global
window.NullNotifications = NullNotifications;
