/**
 * Null UI - Module Clipboard
 * Gestion du presse-papiers et ouverture d'URLs
 */

const NullClipboard = {
    /**
     * Initialiser le module
     */
    init() {
        // Enregistrer les handlers d'événements
        NullEvents.on('copy', (data) => this.copy(data.text || data.tool || data.coords));
        NullEvents.on('openUrl', (data) => this.openUrl(data.link || data.url));
    },

    /**
     * Copier du texte dans le presse-papiers
     * @param {string} text - Texte à copier
     * @returns {boolean} - Succès
     */
    copy(text) {
        if (!text) return false;

        try {
            // Méthode moderne (Clipboard API)
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(() => {
                    NullEvents.emit('clipboard:copied', { text });
                }).catch(() => {
                    this._fallbackCopy(text);
                });
                return true;
            }
            
            // Fallback pour les anciens navigateurs
            return this._fallbackCopy(text);
        } catch (e) {
            console.error('[NullClipboard] Error copying:', e);
            return false;
        }
    },

    /**
     * Méthode de copie fallback
     * @param {string} text - Texte à copier
     * @returns {boolean} - Succès
     */
    _fallbackCopy(text) {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-9999px';
        textarea.style.top = '-9999px';
        
        document.body.appendChild(textarea);
        textarea.select();
        
        try {
            const success = document.execCommand('copy');
            if (success) {
                NullEvents.emit('clipboard:copied', { text });
            }
            return success;
        } catch (e) {
            console.error('[NullClipboard] Fallback copy failed:', e);
            return false;
        } finally {
            document.body.removeChild(textarea);
        }
    },

    /**
     * Ouvrir une URL externe
     * @param {string} url - URL à ouvrir
     */
    openUrl(url) {
        if (!url) return;

        try {
            // Utiliser l'API native FiveM si disponible
            if (window.invokeNative) {
                window.invokeNative('openUrl', url);
            } else {
                // Fallback: ouvrir dans un nouvel onglet (ne fonctionnera pas en NUI)
                window.open(url, '_blank');
            }
            
            NullEvents.emit('url:opened', { url });
        } catch (e) {
            console.error('[NullClipboard] Error opening URL:', e);
        }
    }
};

// Export global
window.NullClipboard = NullClipboard;
