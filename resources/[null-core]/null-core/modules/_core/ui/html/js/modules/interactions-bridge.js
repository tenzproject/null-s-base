/**
 * Null UI - Interactions Bridge
 * Pont de communication pour les dialogs Input et Confirm
 */

const NullInteractionsBridge = {
    iframe: null,
    initialized: false,
    originalZIndex: null,
    activeComponents: new Set(),  // Stack des composants actifs (context-menu, input, confirm, hud-editor)

    /**
     * Initialiser le pont
     */
    init() {
        if (this.initialized) {
            console.warn('[Interactions Bridge] Already initialized, skipping');
            return;
        }

        this.iframe = document.getElementById('core-nui');

        if (!this.iframe) {
            console.error('[Interactions Bridge] Iframe not found');
            return;
        }

        // L'iframe est toujours visible pour les 3D interactions et Info UI
        // pointer-events géré dynamiquement selon les composants actifs
        this.iframe.style.display = 'block';
        this.iframe.style.pointerEvents = 'none';
        this.iframe.style.zIndex = '10000';

        // Écouter les messages du client Lua
        window.addEventListener('message', (event) => {
            const data = event.data;

            // Filtrer les actions Interactions (action ou type)
            if (data && (data.action || data.type)) {
                this.handleNUIMessage(data);
            }
        });

        this.initialized = true;
    },

    /**
     * Gérer les messages NUI
     */
    handleNUIMessage(data) {
        const action = data.action || data.type;

        if (action === 'openInput') {
            this.addComponent('input');
        } else if (action === 'openConfirm') {
            this.addComponent('confirm');
        } else if (action === 'openHUDEditor') {
            this.addComponent('hud-editor');
        } else if (action === 'openContextMenu') {
            this.addComponent('context-menu');
        } else if (action === 'boutique:open') {
            this.addComponent('boutique');
        } else if (action === 'animations:open') {
            this.addComponent('animations');
        } else if (action === 'weaponCustom:open') {
            this.addComponent('weapon-custom');
        } else if (action === 'illegalTablet:open') {
            this.addComponent('illegal-tablet');
        } else if (action === 'illegalDevice:open') {
            this.addComponent('illegal-device');
        } else if (action === 'shopui:open') {
            this.addComponent('shopui');
        } else if (action === 'policeTablet:open') {
            this.addComponent('police-tablet');
        } else if (action === 'reglement:open') {
            this.addComponent('reglement');
        } else if (action === 'tutorial:open') {
            this.addComponent('tutorial');
        } else if (action === 'newInventory:open') {
            this.addComponent('inventory');
        } else if (action === 'devPanel:open') {
            this.addComponent('dev-panel');
        } else if (action === 'driveSchool:open') {
            this.addComponent('drive-school');
        } else if (action === 'shop:open') {
            this.addComponent('shop');
        } else if (action === 'newCreator:open') {
            this.addComponent('creator');
        } else if (action === 'garage:open') {
            this.addComponent('garage');
        } else if (action === 'bank:open') {
            this.addComponent('bank');
        } else if (action === 'atm:open') {
            this.addComponent('atm');
        } else if (action === 'dealership:open') {
            this.addComponent('dealership');
        } else if (action === 'realtor:open') {
            this.addComponent('realtor');
        } else if (action === 'burglary:openMinigame') {
            this.addComponent('burglary');
        } else if (action === 'burglary:openLoot') {
            this.addComponent('burglary');
        } else if (action === 'catalog:open') {
            this.addComponent('catalog');
        } else if (action === 'pawnshop:open') {
            this.addComponent('pawnshop');
        } else if (action === 'societyTablet:open') {
            this.addComponent('society');
        } else if (action === 'imagemaker:open') {
            this.addComponent('imagemaker');
        } else if (action === 'pauseMenu:open') {
            this.addComponent('pauseMenu');
        } else if (action === 'radio:open') {
            this.addComponent('radio');
        } else if (action === 'propInteract:open') {
            this.addComponent('prop-interact');
        } else if (action === 'openItemGrid') {
            this.addComponent('menu:itemGrid');
        } else if (action === 'craftTablet:open') {
            this.addComponent('craft-tablet');
        } else if (action === 'supplierTablet:open') {
            this.addComponent('supplier-tablet');
        } else if (action === 'freejobTablet:open') {
            this.addComponent('freejob-tablet');
        } else if (action === 'freejobInfo:open') {
            this.addComponent('freejob-info');
        } else if (action === 'doorlock:open') {
            this.addComponent('doorlock');
        } else if (action === 'taxiBoard:open') {
            this.addComponent('taxiBoard');
        } else if (action === 'wavePlayground:open') {
            this.addComponent('wavePlayground');
        } else if (action === 'showcase:welcome:open' || action === 'showcase:tablet:open') {
            this.addComponent('showcase');
        } else if (action === 'panelAdmin:open') {
            this.addComponent('panel-admin');
        }
        // else if (action === 'objectives:start') {
        //     this.addComponent('objectives');
        // } 

        else if (action === 'closeInput') {
            this.removeComponent('input');
        } else if (action === 'closeConfirm') {
            this.removeComponent('confirm');
        } else if (action === 'closeHUDEditor') {
            this.removeComponent('hud-editor');
        } else if (action === 'boutique:close') {
            this.removeComponent('boutique');
        } else if (action === 'animations:close') {
            this.removeComponent('animations');
        } else if (action === 'weaponCustom:close') {
            this.removeComponent('weapon-custom');
        } else if (action === 'illegalTablet:close') {
            this.removeComponent('illegal-tablet');
        } else if (action === 'illegalDevice:close') {
            this.removeComponent('illegal-device');
        } else if (action === 'shopui:close') {
            this.removeComponent('shopui');
        } else if (action === 'reglement:close') {
            this.removeComponent('reglement');
        } else if (action === 'tutorial:close') {
            this.removeComponent('tutorial');
        } else if (action === 'newInventory:close') {
            this.removeComponent('inventory');
        } else if (action === 'devPanel:close') {
            this.removeComponent('dev-panel');
        } else if (action === 'driveSchool:close') {
            this.removeComponent('drive-school');
        } else if (action === 'shop:close') {
            this.removeComponent('shop');
        } else if (action === 'newCreator:close') {
            this.removeComponent('creator');
        } else if (action === 'garage:close') {
            this.removeComponent('garage');
        } else if (action === 'bank:close') {
            this.removeComponent('bank');
        } else if (action === 'atm:close') {
            this.removeComponent('atm');
        } else if (action === 'dealership:close') {
            this.removeComponent('dealership');
        } else if (action === 'realtor:close') {
            this.removeComponent('realtor');
        } else if (action === 'burglary:close') {
            this.removeComponent('burglary');
        } else if (action === 'catalog:close') {
            this.removeComponent('catalog');
        } else if (action === 'pawnshop:close') {
            this.removeComponent('pawnshop');
        } else if (action === 'societyTablet:close') {
            this.removeComponent('society');
        } else if (action === 'imagemaker:close') {
            this.removeComponent('imagemaker');
        } else if (action === 'pauseMenu:close') {
            this.removeComponent('pauseMenu');
        } else if (action === 'radio:close') {
            this.removeComponent('radio');
        } else if (action === 'propInteract:close') {
            this.removeComponent('prop-interact');
        } else if (action === 'doorlock:close') {
            this.removeComponent('doorlock');
        } else if (action === 'craftTablet:close') {
            this.removeComponent('craft-tablet');
        } else if (action === 'supplierTablet:close') {
            this.removeComponent('supplier-tablet');
        } else if (action === 'freejobTablet:close') {
            this.removeComponent('freejob-tablet');
        } else if (action === 'taxiBoard:close') {
            this.removeComponent('taxiBoard');
        } else if (action === 'wavePlayground:close') {
            this.removeComponent('wavePlayground');
        } else if (action === 'freejobInfo:close') {
            this.removeComponent('freejob-info');
        } else if (action === 'showcase:close') {
            this.removeComponent('showcase');
        } else if (action === 'panelAdmin:close') {
            this.removeComponent('panel-admin');
        } else if (action === 'closeItemGrid') {
            this.removeComponent('menu:itemGrid');
            // } else if (action === 'objectives:stop') {
            //     this.removeComponent('objectives');
        } else if (action === 'tutorial:setFocus') {
            if (data.data && data.data.focused) {
                this.addComponent('tutorial');
            } else {
                this.removeComponent('tutorial');
            }
        } else if (action === 'closeContextMenu') {
            this.removeComponent('context-menu');

            if (this.activeComponents.size === 0) {
                fetch('https://null-core/contextMenuClosed', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        keepNuiFocus: data.keepNuiFocus || false
                    })
                }).catch(err => {
                    console.error('[Interactions Bridge] Error sending contextMenuClosed:', err);
                });
            }
        } else if (action === 'hideFocus') {
            const modalComponents = ['input', 'confirm', 'hud-editor', 'panel-admin'];
            const hasModalActive = Array.from(this.activeComponents).some(comp => modalComponents.includes(comp));

            if (!hasModalActive) {
                this.clearComponents();
            }
        }

        this.sendToIframe(data);
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
     * Ajouter un composant actif
     */
    addComponent(component) {
        this.activeComponents.add(component);
        this.updateIframeState();
    },

    /**
     * Retirer un composant actif
     */
    removeComponent(component) {
        this.activeComponents.delete(component);
        this.updateIframeState();
    },

    /**
     * Vider tous les composants actifs
     */
    clearComponents() {
        this.activeComponents.clear();
        this.updateIframeState();
    },

    /**
     * Mettre à jour l'état de l'iframe selon les composants actifs
     */
    updateIframeState() {
        if (!this.iframe) return;

        const hasActive = this.activeComponents.size > 0;

        // Si au moins un composant est actif, activer les pointer-events
        if (hasActive) {
            this.iframe.style.pointerEvents = 'auto';
            this.iframe.style.zIndex = '99999';
            // Forcer le focus sur l'iframe pour que les évènements clavier
            // (Space/Enter/Escape) soient reçus par le window de React,
            // sans nécessiter un clic souris préalable.
            try {
                if (this.iframe.contentWindow) {
                    this.iframe.contentWindow.focus();
                }
            } catch (e) { /* cross-origin guard, ignore */ }
        } else {
            this.iframe.style.pointerEvents = 'none';
            this.iframe.style.zIndex = '10000';
        }

        // Notifie l'app React (notifications, etc.) du changement d'état des
        // interfaces afin qu'elle puisse adapter son rendu (position, style…).
        this.sendToIframe({
            type: 'null:interfaceState',
            active: hasActive,
            components: Array.from(this.activeComponents),
        });
    },

    /**
     * Afficher l'iframe (legacy, utilise addComponent maintenant)
     */
    show() {
        this.addComponent('legacy-show');
    },

    /**
     * Récuperer le focus IFrame (legacy, utilise addComponent maintenant)
     */
    showFocus() {
        this.addComponent('legacy-focus');
    },

    /**
     * Masquer l'iframe (legacy, utilise clearComponents maintenant)
     */
    hide() {
        this.clearComponents();
    },

    /**
     * Retirer le Focus NUI (legacy, utilise clearComponents maintenant)
     */
    hideFocus() {
        this.clearComponents();
    }

};

// Export global
window.NullInteractionsBridge = NullInteractionsBridge;
