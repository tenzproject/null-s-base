
$(document).ready(function() {
    $('.confirm-container').hide();
    // Confirm UI
    const confirmContainer = document.querySelector('.confirm-container');
    const confirmTitle = document.querySelector('.confirm-title');
    let currentConfirmCallback = null;

    function showConfirm(text) {
        $('.confirm-container').show();
        $('.input-container').hide();
        confirmTitle.textContent = text;
        confirmContainer.style.display = 'block';
        // Force un reflow pour que l'animation fonctionne
        confirmContainer.offsetHeight;
        confirmContainer.classList.add('visible');
    }

    function hideConfirm() {
        $('.confirm-container').hide();
        confirmContainer.classList.remove('visible');
        confirmContainer.classList.add('hiding');
        
        // Attendre la fin de l'animation avant de cacher complètement
        setTimeout(() => {
            confirmContainer.style.display = 'none';
            confirmContainer.classList.remove('hiding');
            currentConfirmCallback = null;
        }, 200); // Même durée que l'animation CSS
    }

    // Gestionnaire de clic pour les boutons
    document.querySelectorAll('.confirm-button').forEach(button => {
        button.addEventListener('click', () => {
            const action = button.dataset.action;
            if (currentConfirmCallback) {
                currentConfirmCallback(action === 'yes');
            }
            hideConfirm();
        });
    });

    window.addEventListener('message', function(event) {
        const data = event.data;
        switch (data.type) {
            case 'SHOW_CONFIRM':
                currentConfirmCallback = (result) => {
                    fetch(`https://${GetParentResourceName()}/confirmCallback`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify({
                            result: result
                        })
                    });
                };
                showConfirm(data.text);
                break;

            case 'HIDE_CONFIRM':
                hideConfirm();
                break;
        }
    });
});
    
