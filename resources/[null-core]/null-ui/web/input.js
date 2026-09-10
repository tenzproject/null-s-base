
let currentInputCallback = null;

$(document).ready(function() {
    $('.input-container').hide();
    // Input UI
    const inputContainer = document.querySelector('.input-container');
    const inputTitle = document.querySelector('.input-title');
    const inputField = document.querySelector('.input-field');

    function showInput(text) {
        $('.confirm-container').hide();
        $('.input-container').show();
        inputTitle.textContent = text;
        inputField.value = '';
        inputContainer.style.display = 'block';
        inputContainer.classList.add('visible');
        inputField.focus();
    }

    function hideInput() {
        $('.input-container').hide();
        inputContainer.classList.remove('visible');
        inputContainer.classList.add('hiding');
        
        setTimeout(() => {
            inputContainer.style.display = 'none';
            inputContainer.classList.remove('hiding');
            currentInputCallback = null;
        }, 200);
    }

    // Gestionnaire de clic pour les boutons
    document.querySelectorAll('.input-button').forEach(button => {
        button.addEventListener('click', () => {
            const action = button.dataset.action;
            if (currentInputCallback) {
                if (action === 'submit') {
                    currentInputCallback(inputField.value);
                } else {
                    currentInputCallback(null);
                }
            }
            hideInput();
        });
    });

    // Gestionnaire pour la touche Entrée
    inputField.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' && currentInputCallback) {
            currentInputCallback(inputField.value);
            hideInput();
        } else if (event.key === 'Escape') {
            if (inputContainer && inputContainer.style.display !== 'none') {
                if (currentInputCallback) {
                    currentInputCallback(null);
                }
                    hideInput();
                return;
            }
        }
    });


    window.addEventListener('message', function(event) {
        const data = event.data;
        switch (data.type) {
            case 'SHOW_INPUT':
                currentInputCallback = (result) => {
                    fetch(`https://${GetParentResourceName()}/inputCallback`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify({
                            result: result
                        })
                    });
                };
                showInput(data.text);
                break;
    
            case 'HIDE_INPUT':
                hideInput();
                break;
        }
    });
});