/**
 * Null UI - Unified UI Bridge
 * Pont de communication entre l'UI principale et le module UI React unifié
 */

const NullUIBridge = {
    iframe: null,
    isVisible: false,
    initialized: false,
    
    /**
     * Initialiser le pont
     */
    init() {
        if (this.initialized) {
            console.warn('[UI Bridge] Already initialized, skipping');
            return;
        }
        
        this.iframe = document.getElementById('ui-nui');
        
        if (!this.iframe) {
            console.error('[UI Bridge] Iframe not found');
            return;
        }

        // Écouter les messages du client Lua
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            // Filtrer uniquement les actions UI
            if (data && data.action) {
                this.handleNUIMessage(data);
            }
        });
        
        this.initialized = true;
    },
    
    /**
     * Gérer les messages NUI
     */
    handleNUIMessage(data) {
        const action = data.action;
        // Actions qui concernent l'UI unifiée
        const uiActions = [
            'openUI',
            'closeUI',
            'updateUIData'
        ];
        
        if (uiActions.includes(action)) {
            // Gérer la visibilité de l'iframe AVANT d'envoyer le message
            if (action === 'openUI') {
                this.show();
            } else if (action === 'closeUI') {
                this.hide();
            }
            
            // Transférer le message à l'iframe (après show pour éviter le lag visuel)
            this.sendToIframe(data);
        }
    },
    
    /**
     * Envoyer un message à l'iframe
     */
    sendToIframe(data) {
        if (this.iframe && this.iframe.contentWindow) {
            this.iframe.contentWindow.postMessage(data, '*');
        }
    },
    
    /**
     * Afficher l'iframe
     */
    show() {
        if (this.iframe && !this.isVisible) {
            this.iframe.style.display = 'block';
            this.iframe.style.pointerEvents = 'auto';
            this.isVisible = true;
        }
    },
    
    /**
     * Masquer l'iframe
     */
    hide() {
        if (this.iframe) {
            this.iframe.style.display = 'none';
            this.iframe.style.pointerEvents = 'none';
            this.isVisible = false;
        }
    }
};

// Export global
window.NullUIBridge = NullUIBridge;
