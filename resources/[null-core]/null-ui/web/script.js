let ServerLogo = null;
let serverColor = null;
let TabletOpen = false;

$(document).ready(function() {
    $(document).on('keydown', function(e) {
        if (e.key === "Escape") {
            if (TabletOpen) {
                TabletOpen = false;
                $('.tablet-interface').hide();
                $('.tablet-view').hide();
                $.post('https://null-ui/closeTablet', JSON.stringify({}));
                return;
            }
        }
    });

    window.addEventListener('message', function(event) {
        if (event.data.color) {
            const color = event.data.color;
            serverColor = color;
            let r, g, b;
            if (color.startsWith('#')) {
              const hex = color.replace('#', '');
              r = parseInt(hex.substring(0, 2), 16);
              g = parseInt(hex.substring(2, 4), 16);
              b = parseInt(hex.substring(4, 6), 16);
            } else {
              const match = color.match(/\d+/g);
              [r, g, b] = match.map(Number);
            }
            const root = document.documentElement;
            // Force le rafraîchissement du style
            root.style.removeProperty('--global-main-color');
            setTimeout(() => {
                // Variables globales existantes
                root.style.setProperty('--global-main-color', `rgb(${r}, ${g}, ${b})`);
                root.style.setProperty('--global-main-color-dark-10', `rgba(${r}, ${g}, ${b}, 0.1)`);
                root.style.setProperty('--global-main-color-dark-20', `rgba(${r}, ${g}, ${b}, 0.2)`);
                root.style.setProperty('--global-main-color-dark-30', `rgba(${r}, ${g}, ${b}, 0.3)`);
                root.style.setProperty('--global-main-color-dark-40', `rgba(${r}, ${g}, ${b}, 0.4)`);
                root.style.setProperty('--global-main-color-dark-50', `rgba(${r}, ${g}, ${b}, 0.5)`);
                root.style.setProperty('--global-main-color-dark-60', `rgba(${r}, ${g}, ${b}, 0.6)`);
                root.style.setProperty('--global-main-color-dark-70', `rgba(${r}, ${g}, ${b}, 0.7)`);
                root.style.setProperty('--global-main-color-dark-80', `rgba(${r}, ${g}, ${b}, 0.8)`);
                root.style.setProperty('--global-main-color-dark-90', `rgba(${r}, ${g}, ${b}, 0.9)`);
                
                // Variables GW pour le nouveau style unifié
                root.style.setProperty('--nykz-accent-color', `rgb(${r}, ${g}, ${b})`);
                root.style.setProperty('--nykz-accent-color-10', `rgba(${r}, ${g}, ${b}, 0.1)`);
                root.style.setProperty('--nykz-accent-color-20', `rgba(${r}, ${g}, ${b}, 0.2)`);
                root.style.setProperty('--nykz-accent-color-30', `rgba(${r}, ${g}, ${b}, 0.3)`);
                root.style.setProperty('--nykz-accent-color-40', `rgba(${r}, ${g}, ${b}, 0.4)`);
                root.style.setProperty('--nykz-accent-color-50', `rgba(${r}, ${g}, ${b}, 0.5)`);
                
                // background color : combine rgba(r,g,b,0.1) avec rgba(12,12,12,0.7)
                const opacity1 = 0.1;
                const opacity2 = 0.7;
                const totalOpacity = opacity1 + opacity2 * (1 - opacity1);
                
                let r2 = Math.round((r * opacity1 + 12 * opacity2 * (1 - opacity1)) / totalOpacity);
                let g2 = Math.round((g * opacity1 + 12 * opacity2 * (1 - opacity1)) / totalOpacity);
                let b2 = Math.round((b * opacity1 + 12 * opacity2 * (1 - opacity1)) / totalOpacity);

                root.style.setProperty('--global-main-color-dark-10--background', `rgba(${r2}, ${g2}, ${b2}, ${totalOpacity})`);
            }, 0);
        }
        if (event.data.logo) {
            ServerLogo = event.data.logo;
            $('.server-logo').attr('src', ServerLogo);
            $('#logo').attr('src', ServerLogo);
            $('.logo').attr('src', ServerLogo);
        }
    });

});


// Gestion de la tablette
window.addEventListener('message', function(event) {
    if (event.data.action === "openTablet") {
        $('.tablet-interface').show();
        $('.tablet-view').hide();
        $(`#${event.data.type}`).show();
        TabletOpen = true;
        
        if (event.data.type === "laboratoire") {
            displayLaboratories(event.data.data);
        } else if (event.data.type === "immobilier") {
            displayProperties(event.data.data);
        }
    }
    if (event.data.action === "rolePlayAnnounce") {
        rolePlayAnnounce(event.data.data);
    }
});


// Affichage des laboratoires
function displayLaboratories(labs) {
    const labsGrid = $('.labs-grid');
    labsGrid.empty();
    
    labs.forEach(lab => {
        const labElement = `
            <div class="lab-item" data-id="${lab.id}">
                <img src="${lab.image}" alt="${lab.name}">
                <h3>${lab.name}</h3>
                <p>${lab.description}</p>
                <div class="lab-price">${lab.price}$</div>
                <button class="purchase-btn" onclick="purchaseLab(${lab.id})">Acheter</button>
            </div>
        `;
        labsGrid.append(labElement);
    });
}

// Affichage des propriétés
function displayProperties(properties) {
    const propertiesGrid = $('.properties-grid');
    propertiesGrid.empty();
    
    properties.forEach(property => {
        const propertyElement = `
            <div class="property-item" data-id="${property.id}">
                <img src="${property.image}" alt="${property.name}">
                <h3>${property.name}</h3>
                <p>${property.description}</p>
                <div class="property-prices">
                    <div>Prix mensuel: ${property.monthlyPrice}$</div>
                    <div>Prix à vie: ${property.lifePrice}$</div>
                </div>
                <div class="purchase-buttons">
                    <button class="purchase-btn monthly" onclick="purchaseProperty(${property.id}, 'monthly')">Location mensuelle</button>
                    <button class="purchase-btn lifetime" onclick="purchaseProperty(${property.id}, 'lifetime')">Achat à vie</button>
                </div>
            </div>
        `;
        propertiesGrid.append(propertyElement);
    });
}

// Fonctions d'achat
function purchaseLab(labId) {
    $.post('https://null-ui/purchaseItem', JSON.stringify({
        type: 'laboratoire',
        itemId: labId
    }));
}

function purchaseProperty(propertyId, purchaseType) {
    $.post('https://null-ui/purchaseItem', JSON.stringify({
        type: 'immobilier',
        itemId: propertyId,
        purchaseType: purchaseType
    }));
}

let lastWeazelNews = null;
function rolePlayAnnounce(data) {
    if (lastWeazelNews) {
        lastWeazelNews.remove();
    }
    const div = document.createElement('div');
    div.classList.add('weazel-news');
    div.innerHTML = `
        <img src="${data.image || 'https://i.ibb.co/pBvcHYxT/OIP-1.jpg'}" alt="${data.title}">
        <h3>${data.title}</h3>
        <p>${data.description}</p>
    `;
    document.body.appendChild(div);
    lastWeazelNews = div;
    setTimeout(() => {
        div.remove();
        lastWeazelNews = null;
    }, data.time || 10000);
}

async function checkImageExists(url) {
    return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => resolve(true);
        img.onerror = () => resolve(false);
        img.src = url;
    });
}