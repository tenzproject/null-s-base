/**
 * Null UI - Utilitaires
 * Fonctions utilitaires partagées par tous les modules
 */

const NullUtils = {
    /**
     * Extraire l'ID d'une URL YouTube
     * @param {string} url - URL YouTube
     * @returns {string} - ID de la vidéo ou chaîne vide
     */
    getYoutubeId(url) {
        if (!url) return '';
        
        // Format: youtube.com/watch?v=ID
        if (url.includes('youtube.com')) {
            const match = url.match(/[?&]v=([^&]+)/);
            return match ? match[1].substring(0, 11) : '';
        }
        
        // Format: youtu.be/ID
        if (url.includes('youtu.be')) {
            const parts = url.replace('//', '').split('/');
            return parts[1] ? parts[1].substring(0, 11) : '';
        }
        
        return '';
    },

    /**
     * Calculer la distance entre deux points 3D
     * @param {Array} pos1 - [x, y, z]
     * @param {Array} pos2 - [x, y, z]
     * @returns {number} - Distance
     */
    distance3D(pos1, pos2) {
        const dx = pos1[0] - pos2[0];
        const dy = pos1[1] - pos2[1];
        const dz = pos1[2] - pos2[2];
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    },

    /**
     * Générer un ID unique
     * @param {string} prefix - Préfixe optionnel
     * @returns {string} - ID unique
     */
    generateId(prefix = 'null') {
        return `${prefix}_${Math.random().toString(36).substr(2, 9)}`;
    },

    /**
     * Formater un nombre en devise
     * @param {number} amount - Montant
     * @param {string} currency - Symbole de devise
     * @returns {string} - Montant formaté
     */
    formatCurrency(amount, currency = '$') {
        return `${currency}${amount.toFixed(2)}`;
    },

    /**
     * Debounce une fonction
     * @param {Function} func - Fonction à debounce
     * @param {number} wait - Délai en ms
     * @returns {Function} - Fonction debounced
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    /**
     * Throttle une fonction
     * @param {Function} func - Fonction à throttle
     * @param {number} limit - Limite en ms
     * @returns {Function} - Fonction throttled
     */
    throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },

    /**
     * Clamp une valeur entre min et max
     * @param {number} value - Valeur
     * @param {number} min - Minimum
     * @param {number} max - Maximum
     * @returns {number} - Valeur clampée
     */
    clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    },

    /**
     * Interpolation linéaire
     * @param {number} start - Valeur de départ
     * @param {number} end - Valeur de fin
     * @param {number} t - Facteur (0-1)
     * @returns {number} - Valeur interpolée
     */
    lerp(start, end, t) {
        return start + (end - start) * t;
    }
};

// Export global
window.NullUtils = NullUtils;
