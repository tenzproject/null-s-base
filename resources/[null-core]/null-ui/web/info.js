$(document).ready(function() {
    const infoContainer = document.querySelector('.info-container');
    const infoTitle = document.querySelector('.info-title');
    const infoName = document.querySelector('.info-name');
    const infoIcon = document.querySelector('.info-icon');
    const infoItems = document.querySelector('.info-items');

    let canShow = true;

    // Positions disponibles pour l'info-container
    const positions = {
        'top-right': 'top-right',      // En haut à droite
        'middle-right': 'middle-right', // Milieu à droite (par défaut)
        'top-left': 'top-left',        // En haut à gauche
        'middle-left': 'middle-left'    // Milieu à gauche
    };

    function showInfo(data) {
        if (!canShow) return;
        // Définir la position de l'info-container
        // Supprimer toutes les classes de position existantes
        Object.values(positions).forEach(pos => {
            infoContainer.classList.remove(pos);
        });

        // Ajouter la classe de position spécifiée ou utiliser middle-right par défaut
        const position = data.position && positions[data.position] ? positions[data.position] : positions['middle-right'];
        infoContainer.classList.add(position);

        // Définir le titre et le nom
        infoTitle.textContent = data.title;
        if (data.name) {
            infoName.textContent = data.name;
            if (data.color) {
                infoName.style.color = data.color;
                // Ajouter un text-shadow avec une version transparente de la couleur
                //const shadowColor = data.color.replace('rgb', 'rgba').replace(')', ', 0.4)');
                //infoName.style.textShadow = `0 0 5px ${shadowColor}`;
            }
        }
        
        // Gérer l'icône
        if (data.icon) {
            infoIcon.src = data.icon;
            infoIcon.style.display = 'block';
        } else {
            infoIcon.src = '';
            infoIcon.style.display = 'none';
        }
        
        // Vider les items existants
        infoItems.innerHTML = '';
        
        // Ajouter les nouveaux items
        data.items.forEach(item => {
            const itemElement = document.createElement('div');
            itemElement.className = 'info-item';
            
            // Définir la couleur par défaut si non spécifiée
            const color = item.color || 'rgb(0, 235, 136)';
            const shadowColor = color.replace('rgb', 'rgba').replace(')', ', 0.4)');
            
            // Gérer le texte ou l'icône pour left et right
            const leftContent = item.leftIcon ? `<i class="${item.leftIcon}"></i> ${item.left}` : item.left;
            const rightContent = item.rightIcon ? `${item.right} <i class="${item.rightIcon}"></i>` : item.right;
            
            itemElement.innerHTML = `
                <span class="info-item-left">${leftContent}</span>
                <span class="info-item-right" style="color: ${color}; text-shadow: 0 0 0px ${shadowColor}">${rightContent}</span>
            `;
            infoItems.appendChild(itemElement);
        });
        
        // Afficher le conteneur avec animation
        $(".info-container").addClass("visible");
        setTimeout(() => {
            $(".info-container").show();
        }, 300);
    }
    
    function hideInfo() {
        $(".info-container").addClass("hiding");
        setTimeout(() => {
            $(".info-container").hide();
            $(".info-container").removeClass("hiding");
        }, 300);
    }
    
    function forceCanInfo(bool = false) {
        if (!bool) {
            hideInfo();
        }
        canShow = bool;
    }

    window.addEventListener('message', function(event) {
        const data = event.data;
        switch (data.type) {
            case 'SHOW_INFO':
                showInfo(data);
                break;
    
            case 'HIDE_INFO':
                hideInfo();
                break;
    
            case 'FORCE_CAN_INFO':
                forceCanInfo(data.bool);
                break;

        }
    });
});