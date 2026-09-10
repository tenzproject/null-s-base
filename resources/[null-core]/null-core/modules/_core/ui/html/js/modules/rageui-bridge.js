/**
 * Null UI - RageUI-NUI Bridge
 * Pont de communication entre l'UI principale et le RageUI-NUI React
 */

const NullRageUIBridge = {
    iframe: null,
    isVisible: false,
    initialized: false,
    
    /**
     * Initialiser le pont
     */
    init() {
        if (this.initialized) {
            console.warn('[RageUI Bridge] Already initialized, skipping');
            return;
        }
        
        this.iframe = document.getElementById('rageui-nui');
        
        if (!this.iframe) {
           // console.error('[RageUI Bridge] Iframe not found');
            return;
        }
        
        // Écouter les messages du client Lua
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            // Filtrer uniquement les actions RageUI
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
        
        // Actions qui concernent le RageUI
        const rageUIActions = [
            'openMenu',
            'closeMenu',
            'setItems',
            'updateTitle',
            'updateSubtitle',
            'navigate',
            'select',
            'setCursor'
        ];
        
        if (rageUIActions.includes(action)) {
            this.sendToIframe(data);
            
            if (action === 'openMenu') {
                this.show();
            } else if (action === 'closeMenu') {
                this.hide();
            } else if (action === 'setCursor') {
                this.setPointerEvents(data.data.enabled);
            }
        }
    },
    
    /**
     * Envoyer un message à l'iframe
     */
    sendToIframe(data) {
        if (this.iframe && this.iframe.contentWindow) {
            this.iframe.contentWindow.postMessage(data, '*');
        } else {
            console.error('[RageUI Bridge] Cannot send to iframe - iframe or contentWindow not available');
        }
    },
    
    /**
     * Afficher l'iframe (menu visible)
     * Note: L'iframe est toujours visible, on active juste les pointer-events pour le menu
     */
    show() {
        if (this.iframe) {
            // L'iframe interactions est toujours visible, on active juste les events
            this.setPointerEvents(false); // Menu n'a pas besoin de pointer events par défaut
            this.isVisible = true;
        } else {
            console.error('[RageUI Bridge] Iframe not found when trying to show');
        }
    },
    
    /**
     * Masquer l'iframe (menu caché)
     */
    hide() {
        if (this.iframe) {
            // On ne cache pas l'iframe (utilisée par interactions aussi)
            // On désactive juste les pointer events
            this.setPointerEvents(false);
            this.isVisible = false;
        }
    },
    
    /**
     * Activer/désactiver les événements de pointeur
     */
    setPointerEvents(enabled) {
        if (this.iframe) {
            this.iframe.style.pointerEvents = enabled ? 'auto' : 'none';
        }
    }
};

// Export global
window.NullRageUIBridge = NullRageUIBridge;
