const safezoneManager = {
    fadeOutTimeout: null,

    init() {
        // Cacher l'indicateur au démarrage
        $('.safezone-indicator').removeClass('show fade-out');
    },

    setSafezone(status) {
        const indicator = $('.safezone-indicator');
        const icon = indicator.find('.safezone-icon');

        // Annuler le timeout précédent si existant
        if (this.fadeOutTimeout) {
            clearTimeout(this.fadeOutTimeout);
            this.fadeOutTimeout = null;
        }

        if (status) {
            // En safezone
            icon.attr('src', 'images/protect-g.webp');
            indicator.removeClass('fade-out').addClass('show');
            indicator.addClass('fade-in');

            setTimeout(() => {
                indicator.removeClass('fade-in');
            }, 1000);

        } else {
            // Plus en safezone
            // Fade Out l'ancien indicateur protect
            indicator.addClass('fade-out');
            setTimeout(() => {
                indicator.removeClass('fade-out').removeClass('show');
                icon.attr('src', 'images/unprotect.webp');
                indicator.addClass('show').addClass('fade-in');

                setTimeout(() => {
                    indicator.removeClass('fade-in');
                }, 1000);

                // Faire disparaître après 3 secondes
                this.fadeOutTimeout = setTimeout(() => {
                    indicator.addClass('fade-out');
                    setTimeout(() => {
                        indicator.removeClass('show');
                    }, 1000);
                }, 4000);
            }, 1000);
        }
    }
};

// Initialiser le safezoneManager au chargement
$(document).ready(() => {
    safezoneManager.init();
});


window.addEventListener('message', (event) => {
    const item = event.data;
    if (item.type === "safezone") {
        safezoneManager.setSafezone(item.status);
    }
});