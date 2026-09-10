
// Interaction UI
const interactionContainer = document.querySelector('.interaction-container');

function showInteraction(id, text, key = 'E') {
    const interactionItem = document.createElement('div');
    interactionItem.className = 'interaction-item';
    interactionItem.dataset.id = id;
    interactionItem.innerHTML = `
        <span class="interaction-key">${key}</span>
        <span class="interaction-text">${text}</span>
    `;
    interactionContainer.appendChild(interactionItem);
}

function hideInteraction(id) {
    const item = interactionContainer.querySelector(`[data-id="${id}"]`);
    if (item) {
        item.classList.add('leaving');
        setTimeout(() => {
            item.remove();
        }, 300);
    }
}

function clearAllInteractions() {
    const items = interactionContainer.querySelectorAll('.interaction-item');
    items.forEach(item => {
        item.classList.add('leaving');
        setTimeout(() => {
            item.remove();
        }, 300);
    });
}

// Map pour stocker les interactions actives
const activeInteractions = new Map();

// Fonction pour créer une interaction 3D
function create3DInteraction(id, type = 'basic') {
    const template = document.getElementById(`interaction3d-${type}-template`);
    if (!template) return null;

    // Supprimer l'ancienne interaction si elle existe
    const oldContainer = document.getElementById(`interaction-${id}`);
    if (oldContainer) {
        oldContainer.remove();
    }

    const clone = template.content.cloneNode(true);
    const container = clone.querySelector('.interaction-3d-container');
    container.id = `interaction-${id}`;
    document.body.appendChild(container);
    
    // Stocker la référence
    activeInteractions.set(id, container);
    
    return container;
}

// Fonction pour supprimer une interaction 3D
function remove3DInteraction(id) {
    const container = activeInteractions.get(id);
    if (container) {
        container.remove(); // Supprime physiquement l'élément du DOM
        activeInteractions.delete(id);
    }
}

// Fonction pour nettoyer les interactions non utilisées
function cleanupInteractions(currentIds) {
    const idsSet = new Set(currentIds);
    
    // Supprimer les interactions qui ne sont plus dans la liste
    for (const [id, container] of activeInteractions.entries()) {
        if (!idsSet.has(id)) {
            container.remove();
            activeInteractions.delete(id);
        }
    }
}

// Fonction pour mettre à jour l'état d'une interaction 3D
function update3DInteractionState(container, data) {
    if (!data || !data.id) return; // Vérification supplémentaire
                
    if (!data.show) {
        // Si l'interaction ne doit pas être affichée, on la supprime
        container.remove();
        activeInteractions.delete(data.id);
        return;
    }

    container.style.display = 'block';
    container.style.left = data.screenX + 'px';
    container.style.top = data.screenY + 'px';

    // Parse le texte si c'est un JSON
    let textData = data.text;
    try {
        textData = JSON.parse(data.text || '{}');
    } catch(e) {}

    if (typeof textData === 'object' && textData !== null) {
        // Mode multi
        const title = container.querySelector('.interaction-3d-title');
        const lines = container.querySelector('.interaction-3d-lines');
        
        if (title && textData.title) {
            title.textContent = textData.title;
        }

        if (lines && Array.isArray(textData.lines)) {
            lines.innerHTML = '';
            const lineTemplate = document.getElementById('interaction3d-line-template');

            textData.lines.forEach(line => {
                if (line.hidden) {
                    return;
                };
                const lineElement = lineTemplate.content.cloneNode(true);
                const lineContainer = lineElement.querySelector('.interaction-3d-line');
                
                lineContainer.querySelector('.line-left').textContent = line.left || '';
                
                if (line.key) {
                    lineContainer.querySelector('.line-key').style.display = 'block';
                    lineContainer.querySelector('.line-key').textContent = line.key;
                }
                
                const rightElement = lineContainer.querySelector('.line-right');
                if (typeof line.right === 'boolean') {
                    rightElement.classList.add(line.right ? 'boolean-true' : 'boolean-false');
                    rightElement.textContent = ''; // On laisse vide car l'icône est ajoutée via CSS
                } else {
                    rightElement.textContent = line.right || '';
                }

                lines.appendChild(lineContainer);
            });
        }
    } else {
        // Mode basic
        const content = container.querySelector('.interaction-3d-content');
        const key = content.querySelector('.interaction-3d-key');
        const text = content.querySelector('.interaction-3d-text');
        
        if (key) {
            if (data.key) {
                key.textContent = data.key;
                key.style.display = 'block';
            } else {
                key.style.display = 'none';
            }
        }
        if (text) text.textContent = data.text;
    }

    // Gère l'état de distance
    if (data.maxDistance === undefined) {
        data.maxDistance = 1.5;
    }
    if (data.distance < data.maxDistance) {
        container.classList.remove('far');
        container.classList.add('near');
    } else {
        container.classList.remove('near');
        container.classList.add('far');
    }
}


// Gestionnaire de messages NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.type) {
        case 'UPDATE_3D_INTERACTION':
            if (!data || !data.id) return; // Vérification supplémentaire
                
            if (!data.show) {
                remove3DInteraction(data.id);
                return;
            }

            // Détermine le type d'interaction
            let type = 'basic';
            try {
                const textData = JSON.parse(data.text || '{}');
                if (textData && textData.lines) {
                    type = 'multi';
                }
            } catch(e) {}

            let container = activeInteractions.get(data.id);
            if (!container) {
                container = create3DInteraction(data.id, type);
            }
            
            if (container) {
                update3DInteractionState(container, data);
            }
            break;

        case 'REMOVE_3D_INTERACTION':
            if (data && data.id) {
                remove3DInteraction(data.id);
            }
            break;

        case 'CLEAR_3D_INTERACTIONS':
            // Nettoyer toutes les interactions
            for (const container of activeInteractions.values()) {
                container.remove();
            }
            activeInteractions.clear();
            break;
    }
});


// DrawText UI
const drawTextContainer = document.querySelector('.drawtext-container');
const drawTextKey = document.querySelector('.drawtext-key');
const drawTextText = document.querySelector('.drawtext-text');

function showDrawText(text, key = 'E') {
    drawTextKey.textContent = key;
    drawTextText.textContent = text;
    drawTextContainer.style.display = 'block';
}

function hideDrawText() {
    drawTextContainer.style.display = 'none';
}
