// Cache pour les requêtes DOM fréquentes
const domCache = {
    itemsGrids: null,
    navDisplay: null,
    clearCache() {
        this.itemsGrids = null;
        this.navDisplay = null;
    }
};

// Intersection Observer pour lazy loading des images
const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const img = entry.target;
            if (img.dataset.src) {
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                observer.unobserve(img);
            }
        }
    });
}, {
    rootMargin: '50px'
});

const defaultValues = {
    pants_1: 21,
    shoes_1: 34,
    torso_1: 15,
    decals_1: 0,
    arms: 15,
    tshirt_1: 15,
};

// Valeurs pour "retirer" un vêtement (nu/vide)
const nakedValues = {
    tshirt_1: 15,
    torso_1: 15,
    decals_1: 0,
    arms: 15,
    pants_1: 21,
    shoes_1: 34  // Valeur par défaut du serveur
};

const categoriesList = [
    'tshirt_1',
    'torso_1',
    'decals_1',
    'arms',
    'pants_1',
    'shoes_1',
    'mask_1',
    'bproof_1',
    'chain_1',
    'helmet_1',
    'ears_1',
    'glasses_1',
    'watches_1',
    'bracelets_1',
    'bags_1'
];

const variationNames = {
    tshirt_1: 'tshirt_2',
    torso_1: 'torso_2',
    arms: 'arms',
    pants_1: 'pants_2',
    shoes_1: 'shoes_2',
    decals_1: 'decals_2',
    mask_1: 'mask_2',
    bproof_1: 'bproof_2',
    chain_1: 'chain_2',
    helmet_1: 'helmet_2',
    ears_1: 'ears_2',
    glasses_1: 'glasses_2',
    watches_1: 'watches_2',
    bracelets_1: 'bracelets_2',
    bags_1: 'bags_2'
};

playerSex = "male";
var LoadedPlayerSex = null;

const complementaires = {
    top: {
        tshirt_1: 'tshirt_1',
        torso_1: 'torso_1',
        decals_1: 'decals_1',
        arms: 'arms'
    },
    pants: {
        pants_1: 'pants_1'
    },
    shoes: {
        shoes_1: 'shoes_1'
    }
};

// Objet pour stocker les articles du panier avec leurs variations
const cart = {
    tshirt_1: { item: defaultValues.tshirt_1, variation: 0, selected: false },
    torso_1: { item: defaultValues.torso_1, variation: 0, selected: false },
    decals_1: { item: defaultValues.decals_1, variation: 0, selected: false },
    arms: { item: defaultValues.arms, variation: 0, selected: false },
    pants_1: { item: defaultValues.pants_1, variation: 0, selected: false },
    shoes_1: { item: defaultValues.shoes_1, variation: 0, selected: false },
    // Accessoires
    mask_1: { item: null, variation: 0, selected: false },
    bproof_1: { item: null, variation: 0, selected: false },
    chain_1: { item: null, variation: 0, selected: false },
    helmet_1: { item: null, variation: 0, selected: false },
    ears_1: { item: null, variation: 0, selected: false },
    glasses_1: { item: null, variation: 0, selected: false },
    watches_1: { item: null, variation: 0, selected: false },
    bracelets_1: { item: null, variation: 0, selected: false },
    bags_1: { item: null, variation: 0, selected: false }
};

// Variables globales
let priceRecorded = false;
let prices = {
    mainPrice: 5,
    categoryPrices: {},
    customPrices: {}
};
let blackList = {};
let MenuCat = "clothes";
let MenuOpen = false;
let currentActiveCategory = null;
// Cache pour savoir si une catégorie a déjà été chargée
const loadedCategories = new Set();
// Panier pour les accessoires
const accessoriesCart = {};
// Sauvegarde du skin initial pour restauration si pas d'achat
let initialSkinState = null;

/* -------------------------------------------------------------------------- */
/*                                    UTILS                                   */
/* -------------------------------------------------------------------------- */

// checkImageExists is globally defined in script.js

function calculateItemPrice(category, itemId) {
    const id = parseInt(itemId);
    if (!prices || !prices.customPrices || !prices.categoryPrices) return prices.mainPrice;
    if (prices.customPrices[playerSex] && prices.customPrices[playerSex][category] && prices.customPrices[playerSex][category][id] !== undefined) {
        return prices.customPrices[playerSex][category][id];
    }
    if (prices.categoryPrices[playerSex] && prices.categoryPrices[playerSex][category]) {
        return prices.categoryPrices[playerSex][category];
    }
    return prices.mainPrice || 0;
}

function checkCanBuy(category, itemId) {
    const id = parseInt(itemId);
    if (!blackList) return true;
    if (blackList[playerSex] && blackList[playerSex][category] && blackList[playerSex][category][id] === true) {
        return false;
    }
    return true;
}

function calculateGroupTotal(categories) {
    let total = 0;
    categories.forEach(category => {
        if (cart[category] && cart[category].item !== null && cart[category].selected) {
            total += calculateItemPrice(category, cart[category].item);
        }
    });
    return total;
}

async function getMaxVariations(category) {
    return new Promise((resolve) => {
        $.post('https://' + GetParentResourceName() + '/getMaxVariations', JSON.stringify({
            category: category
        }), function (response) {
            resolve(response.max);
        });
    });
}

/* -------------------------------------------------------------------------- */
/*                               CORE FUNCTIONS                               */
/* -------------------------------------------------------------------------- */

$(document).ready(function () {
    $('.clothes').hide();
    $('.accesories').hide();
    $('#variantion-nav').css('display', 'none');
 
    async function initializeInterface() {
        while (priceRecorded === false) {
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        while (playerSex === null) {
            await new Promise(resolve => setTimeout(resolve, 100));
        }

        LoadedPlayerSex = playerSex;
        initializeNavigation();
        initializeCart();
    }

    // Message Listener
    window.addEventListener('message', function (event) {
        const data = event.data;

        if (data.prices) {
            priceRecorded = true;
            prices = {
                mainPrice: parseInt(data.prices.MainPrice),
                categoryPrices: data.prices.CategoryMainPrice,
                customPrices: data.prices.CustomPrice
            };
        }
        if (data.blackListVetement) {
            blackList = data.blackListVetement;
        }

        if (data.type === "open" && data.category !== undefined) {
            MenuOpen = true;
            const category = data.category;

            // Update sex if needed
            if (data.playerSex != undefined && data.playerSex != null && (data.playerSex === "male" || data.playerSex == "female")) {
                if (data.playerSex !== LoadedPlayerSex) {
                    LoadedPlayerSex = data.playerSex;
                    playerSex = data.playerSex;
                    // Reset cache on sex change
                    loadedCategories.clear();
                    document.querySelectorAll('.items-grid').forEach(el => el.remove());
                }
            }

            if (category === "clothes") {
                MenuCat = "clothes";
                const clothesEl = $('.clothes');
                clothesEl.show();
                clothesEl.removeClass('shop-closing').addClass('shop-opening');
                setTimeout(() => clothesEl.removeClass('shop-opening'), 400);
                $('#variantion-nav').css('display', 'flex');
                $('.confirm-container').hide();
                $('.input-container').hide();
                setupRotationArea();

                if (data.Skins) {
                    const skins = JSON.parse(data.Skins);
                    // Sauvegarder l'état initial du skin
                    initialSkinState = JSON.parse(JSON.stringify(skins));
                    handleSkinsUpdate(skins);
                }

                // Open default category
                renderCategory('tshirt_1', 'clothes');
                // Start background preloading
                preloadAllCategories('clothes', 'tshirt_1');

            } else if (category === "accesories") {
                MenuCat = "accesories";
                const accEl = $('.accesories');
                accEl.show();
                accEl.removeClass('shop-closing').addClass('shop-opening');
                setTimeout(() => accEl.removeClass('shop-opening'), 400);
                $('#variantion-nav').css('display', 'flex');
                $('.confirm-container').hide();
                $('.input-container').hide();
                setupRotationArea();

                if (data.Skins) {
                    const skins = JSON.parse(data.Skins);
                    // Sauvegarder l'état initial du skin pour les accessoires aussi
                    initialSkinState = JSON.parse(JSON.stringify(skins));
                    handleSkinsUpdate(skins);
                }
                
                // Vider le panier accessoires à l'ouverture
                Object.keys(accessoriesCart).forEach(key => delete accessoriesCart[key]);

                // Open default category
                renderCategory('bproof_1', 'accesories');
                // Start background preloading
                preloadAllCategories('accesories', 'bproof_1');

            } else if (category === "creator") {
                MenuCat = "creator";
                $('.creator').show();
                // $('.main-content').show();
                $('.confirm-container').hide();
                $('.input-container').hide();
                if (typeof initCreator === 'function') initCreator();
                setupRotationArea();
            } else if (category === "animations") {
                MenuCat = "animations";
                $('.animations').show();
                $('.confirm-container').hide();
                $('.input-container').hide();
                if (typeof initAnimations === 'function') initAnimations();
            }

        } else if (data.type === "close") {
            closeAll();
        } else if (data.action === "updateAnimationsData") {
            if (typeof updateAnimationsData === 'function') {
                updateAnimationsData(data);
            }
        }
    });

    initializeInterface();
});

function closeAll() {
    // La restauration du skin est gérée par Close() côté Lua via le callback exit
    // qui recharge le skin depuis la DB si changeSkin = false
    
    const clothesEl = $('.clothes');
    const accEl = $('.accesories');
    const creatorEl = $('.creator');
    
    // Play close animation for visible shop elements
    const visibleShop = clothesEl.is(':visible') ? clothesEl : (accEl.is(':visible') ? accEl : null);
    
    if (visibleShop) {
        visibleShop.removeClass('shop-opening').addClass('shop-closing');
        setTimeout(() => {
            clothesEl.hide().removeClass('shop-closing');
            accEl.hide().removeClass('shop-closing');
            creatorEl.hide();
            $('#variantion-nav').css('display', 'none');
        }, 280);
    } else {
        clothesEl.hide();
        accEl.hide();
        creatorEl.hide();
        $('#variantion-nav').css('display', 'none');
    }
    
    $('.confirm-container').hide();
    $('.input-container').hide();
    MenuOpen = false;
    initialSkinState = null;
    
    // Réinitialiser l'affichage du panier
    const cartFooter = document.querySelector('.cart-footer');
    if (cartFooter) cartFooter.style.display = 'none';
    const searchContainer = document.querySelector('.nykz-search-container');
    if (searchContainer) searchContainer.style.display = 'flex';
    
    const controls = document.querySelector('.camera-controls');
    if (controls) controls.remove();
    const rotationArea = document.querySelector('.rotation-area');
    if (rotationArea) rotationArea.remove();
}

function handleSkinsUpdate(skins) {
    for (const [category, value] of Object.entries(skins)) {
        if ((category.endsWith('_1') && variationNames[category] !== undefined) || category === 'arms') {
            const itemValue = value !== null && value !== undefined ? value : defaultValues[category];

            // Update Cart
            let variation = 0;
            if (category !== 'arms') {
                const variationKey = category.replace('_1', '_2');
                variation = skins[variationKey] || 0;
            }

            cart[category] = {
                item: itemValue,
                variation: variation
            };
        }
    }
    updateCartDisplay();
}

function setupRotationArea() {
    if (document.querySelector('.rotation-area')) return;

    const rotationArea = document.createElement('div');
    rotationArea.className = 'rotation-area';
    rotationArea.innerHTML = `
        <div class="rotation-hint">
            <i class="fas fa-arrows-rotate"></i>
            <span>Cliquez et maintenez pour tourner</span>
        </div>
    `;
    document.body.appendChild(rotationArea);

    let isRotating = false;

    rotationArea.addEventListener('mousedown', (e) => {
        isRotating = true;
        document.body.classList.add('no-select');
        $.post('https://' + GetParentResourceName() + '/startRotation', JSON.stringify({ mouseX: e.clientX }));
    });

    document.addEventListener('mousemove', (e) => {
        if (isRotating) {
            $.post('https://' + GetParentResourceName() + '/updateRotation', JSON.stringify({ mouseX: e.clientX }));
        }
    });

    const stopRotation = () => {
        if (isRotating) {
            isRotating = false;
            document.body.classList.remove('no-select');
            $.post('https://' + GetParentResourceName() + '/stopRotation', JSON.stringify({}));
        }
    };

    document.addEventListener('mouseup', stopRotation);
    rotationArea.addEventListener('mouseleave', stopRotation);
}

/* -------------------------------------------------------------------------- */
/*                             RENDERING LOGIC                                */
/* -------------------------------------------------------------------------- */

async function preloadAllCategories(shopType, excludeCategory = null) {
    const clothesCategories = ['tshirt_1', 'torso_1', 'decals_1', 'arms', 'pants_1', 'shoes_1'];
    const accessoryCategories = ['bproof_1', 'mask_1', 'chain_1', 'helmet_1', 'ears_1', 'glasses_1', 'watches_1', 'bracelets_1', 'bags_1'];

    const categories = shopType === 'clothes' ? clothesCategories : accessoryCategories;
    const containerId = shopType === 'clothes' ? '#clothes-container' : '#accessories-container';
    const parentContainer = document.querySelector(containerId);

    if (!parentContainer) return;

    for (const category of categories) {
        // Si le menu est fermé, on arrête tout
        if (!MenuOpen) break;

        // Si c'est la catégorie qu'on est en train d'afficher, on l'ignore
        if (category === excludeCategory) continue;

        // Si déjà chargé, on passe
        if (loadedCategories.has(category)) continue;

        // Création du grid caché si nécessaire
        let grid = parentContainer.querySelector(`.items-grid[data-grid-category="${category}"]`);
        if (!grid) {
            grid = document.createElement('div');
            grid.className = 'items-grid';
            grid.setAttribute('data-grid-category', category);
            grid.style.display = 'none';
            parentContainer.appendChild(grid);
        }

        // Chargement des images
        // On ne marque comme chargé que si on est allé au bout
        if (!loadedCategories.has(category)) {
            await loadImages(category, grid);
            loadedCategories.add(category);
        }

        // Petite pause pour laisser respirer l'UI
        await new Promise(r => setTimeout(r, 50));
    }
}

async function renderCategory(category, type) {
    currentActiveCategory = category;

    // Update UI Nav Active State - Support both old nav-item and new GW sidebar li elements
    document.querySelectorAll('.nav-item, .nykz-sidebar li').forEach(item => {
        item.classList.toggle('active', item.getAttribute('data-category') === category);
    });

    // Determine container
    let containerId = type === 'clothes' ? '#clothes-container' : '#accessories-container';
    const parentContainer = document.querySelector(containerId);
    if (!parentContainer) return;

    // S'assurer que le conteneur parent est visible
    parentContainer.classList.add('active');
    
    // Masquer la vue panier si elle est visible
    const cartView = document.getElementById('cart-view');
    if (cartView) cartView.classList.remove('active');

    // Set data-category for CSS or logic usage
    parentContainer.setAttribute('data-category', category);

    // Hide all existing grids inside this container
    // Toujours récupérer les grilles actuelles pour éviter les problèmes de cache
    const currentGrids = parentContainer.querySelectorAll('.items-grid');
    currentGrids.forEach(grid => {
        grid.style.display = 'none';
        grid.classList.remove('active');
    });

    // Check if grid exists for this category
    let grid = parentContainer.querySelector(`.items-grid[data-grid-category="${category}"]`);

    if (!grid) {
        // Create new grid
        grid = document.createElement('div');
        grid.className = 'items-grid active fade-in';
        grid.setAttribute('data-grid-category', category);
        // S'assurer que le display est grid
        grid.style.display = 'grid';
        parentContainer.appendChild(grid);

        // Load images only if not already loaded
        if (!loadedCategories.has(category)) {
            await loadImages(category, grid);
            loadedCategories.add(category);
        }
    } else {
        grid.style.display = 'grid';
        // Reset animation
        grid.classList.remove('fade-in');
        void grid.offsetWidth; // Trigger reflow
        grid.classList.add('active', 'fade-in');
    }

    // Update Input with current value
    const input = parentContainer.querySelector('.number-input');
    if (input) {
        input.value = cart[category]?.item ?? defaultValues[category] ?? 0;
    }

    // Update Variation Display
    if (!domCache.navDisplay) {
        domCache.navDisplay = document.querySelector('.nav-display');
    }
    if (domCache.navDisplay) {
        domCache.navDisplay.textContent = cart[category]?.variation || '0';
    }

    // Hide Cart, Show Shop
    const cartShop = document.querySelector('.cart-shop');
    const content = document.querySelector('.content');
    if (cartShop) cartShop.style.display = 'none';
    if (content) content.style.display = 'block';
}

async function loadImages(category, container) {
    // Le conteneur est le grid spécifique à la catégorie

    let imageCount = 0;
    let consecutiveFailures = 0;
    const maxConsecutiveFailures = 1;
    const batchSize = 15; // Reduced for smoother loading
    let currentBatch = 0;

    async function loadBatch() {
        const startIndex = currentBatch * batchSize;
        let imagesLoaded = 0;

        // On utilise une boucle séquentielle pour garantir l'ordre
        for (let i = startIndex; i < startIndex + batchSize; i++) {
            const imageUrl = `images/clothes/${playerSex}/${category}/${i}.webp`;

            // Use global checkImageExists
            const exists = await checkImageExists(imageUrl);
            const canBuy = await checkCanBuy(category, i);

            if (exists && canBuy) {
                consecutiveFailures = 0;
                const card = document.createElement('div');
                card.className = 'item-card';
                card.setAttribute('data-number', i);

                const itemPrice = calculateItemPrice(category, i);

                card.innerHTML = `
                    <img data-src="${imageUrl}" class="item-image" alt="${category} ${i}" onerror="this.style.display='none'">
                    <div class="item-info">
                        <span class="item-number">${i}</span>
                        <span class="item-price-tag">${itemPrice}$</span>
                    </div>
                `;
                
                // Lazy load image
                const img = card.querySelector('.item-image');
                imageObserver.observe(img);

                if (cart[category] && cart[category].item === i) {
                    card.classList.add('active');
                }

                card.addEventListener('click', () => {
                    // On sélectionne dans le grid actif
                    const activeGrid = document.querySelector(`.items-grid[data-grid-category="${category}"]`);
                    if (activeGrid) {
                        activeGrid.querySelectorAll('.item-card').forEach(c => c.classList.remove('active'));
                    }
                    card.classList.add('active');

                    // Update Cart
                    cart[category] = { item: i, variation: 0, selected: true };

                    // Reset Variation Display
                    const display = document.querySelector('.nav-display');
                    if (display) display.textContent = 0;

                    // Update Input
                    // Attention : l'input est unique par container parent, pas par grid
                    const parentContainer = container.parentElement; // Le parent est #clothes-container
                    const input = parentContainer.querySelector('.number-input');
                    if (input) input.value = i;

                    // Notify Server - Preview sur le personnage
                    $.post('https://' + GetParentResourceName() + '/updateSkin', JSON.stringify({
                        type: category,
                        number: i,
                        variation: 0
                    }));

                    updateCartDisplay();
                });

                container.appendChild(card);
                imagesLoaded++;
                imageCount++;

            } else if (!exists) {
                consecutiveFailures++;
                if (consecutiveFailures >= maxConsecutiveFailures) {
                    break;
                }
            }
        }

        if (imagesLoaded > 0 && consecutiveFailures < maxConsecutiveFailures) {
            currentBatch++;
            await loadBatch();
        }
    }

    await loadBatch();
    return imageCount;
}


/* -------------------------------------------------------------------------- */
/*                             EVENT LISTENERS                                */
/* -------------------------------------------------------------------------- */

function initializeNavigation() {
    // Support both old nav-item and new GW sidebar li elements
    const navItems = document.querySelectorAll('.nav-item, .cart-icon, .buy-acc, .nykz-sidebar li');
    const display = document.querySelector('.nav-display');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');

    // Nav Items Click
    navItems.forEach(item => {
        item.addEventListener('click', async function () {
            // Fix: Ignorer le logo (classe unable)
            if (this.classList.contains('unable')) return;

            const category = this.getAttribute('data-category');
            if (!category) return;

            // Notify Server
            $.post('https://' + GetParentResourceName() + '/changeCategory', JSON.stringify({
                category: category
            }));

            // Handle Cart Special Case
            if (category === 'cart') {
                // Update active state for both old and new nav elements
                document.querySelectorAll('.nav-item, .nykz-sidebar li').forEach(n => n.classList.remove('active'));
                this.classList.add('active');
                
                if (MenuCat === 'clothes') {
                    // Masquer toutes les catégories et afficher la vue panier vêtements
                    document.querySelectorAll('.category-content').forEach(content => {
                        content.classList.remove('active');
                    });
                    document.getElementById('cart-view')?.classList.add('active');
                    
                    // Masquer la barre de recherche et afficher les boutons de paiement
                    document.querySelector('.nykz-search-container')?.style && (document.querySelector('.nykz-search-container').style.display = 'none');
                    document.querySelector('.cart-footer')?.style && (document.querySelector('.cart-footer').style.display = 'flex');
                    
                    // Mettre à jour l'affichage du panier complet
                    updateFullCartDisplay();
                } else if (MenuCat === 'accesories') {
                    // Afficher la vue panier accessoires
                    document.querySelectorAll('.category-content').forEach(content => {
                        content.classList.remove('active');
                    });
                    document.getElementById('accessories-cart-view')?.classList.add('active');
                    
                    // Masquer le bouton ajouter au panier et afficher les boutons de paiement
                    document.getElementById('add-to-cart-section')?.style && (document.getElementById('add-to-cart-section').style.display = 'none');
                    document.querySelector('.nykz-search-container')?.style && (document.querySelector('.nykz-search-container').style.display = 'none');
                    document.querySelector('.accesories .cart-footer')?.style && (document.querySelector('.accesories .cart-footer').style.display = 'flex');
                    
                    // Mettre à jour l'affichage du panier accessoires
                    updateAccessoriesCartDisplay();
                }
                return;
            }

            // Restaurer l'affichage normal si on quitte le panier
            document.querySelector('.nykz-search-container')?.style && (document.querySelector('.nykz-search-container').style.display = 'flex');
            
            if (MenuCat === 'clothes') {
                // Masquer les boutons de paiement vêtements
                const clothesCartFooter = document.querySelector('.clothes .cart-footer');
                if (clothesCartFooter) clothesCartFooter.style.display = 'none';
                
                // Masquer la vue panier vêtements
                const cartView = document.getElementById('cart-view');
                if (cartView) cartView.classList.remove('active');
                
                // Réafficher le conteneur de catégorie vêtements
                const categoryContainer = document.querySelector('#clothes-container');
                if (categoryContainer) categoryContainer.classList.add('active');
            } else if (MenuCat === 'accesories') {
                // Masquer les boutons de paiement accessoires
                const accessoriesCartFooter = document.querySelector('.accesories .cart-footer');
                if (accessoriesCartFooter) accessoriesCartFooter.style.display = 'none';
                
                // Masquer la vue panier accessoires
                const accessoriesCartView = document.getElementById('accessories-cart-view');
                if (accessoriesCartView) accessoriesCartView.classList.remove('active');
                
                // Réafficher le conteneur de catégorie accessoires
                const categoryContainer = document.querySelector('#accessories-container');
                if (categoryContainer) categoryContainer.classList.add('active');
                
                // Afficher le bouton ajouter au panier
                document.getElementById('add-to-cart-section')?.style && (document.getElementById('add-to-cart-section').style.display = 'flex');
            }
            
            // Handle Clothes/Accessories Navigation
            if (MenuCat === 'clothes' || MenuCat === 'accesories') {
                await renderCategory(category, MenuCat);
            }
        });
    });

    // Input Changes
    const inputs = document.querySelectorAll('.number-input');
    inputs.forEach(input => {
        input.addEventListener('input', () => {
            if (!currentActiveCategory) return;
            
            // Trouver la grille active pour la catégorie actuelle
            const activeGrid = document.querySelector(`.items-grid[data-grid-category="${currentActiveCategory}"]`);
            if (!activeGrid) return;

            const searchValue = input.value;
            const cards = activeGrid.querySelectorAll('.item-card');

            // Réinitialiser toutes les cartes
            cards.forEach(card => {
                card.classList.remove('active');
                card.style.display = '';
            });

            // Si une valeur est recherchée, filtrer et activer la carte correspondante
            if (searchValue) {
                cards.forEach(card => {
                    const cardNumber = card.getAttribute('data-number');
                    if (cardNumber === searchValue) {
                        card.classList.add('active');
                        card.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                });
            }
        });

        input.addEventListener('keydown', (event) => {
            if (event.key === 'Enter') {
                if (!currentActiveCategory) return;
                
                const activeGrid = document.querySelector(`.items-grid[data-grid-category="${currentActiveCategory}"]`);
                const searchValue = parseInt(input.value);

                if (!isNaN(searchValue) && activeGrid) {
                    // Vérifier si la carte existe
                    const targetCard = activeGrid.querySelector(`.item-card[data-number="${searchValue}"]`);
                    if (targetCard) {
                        // Appliquer le vêtement/accessoire
                        cart[currentActiveCategory] = { item: searchValue, variation: 0 };
                        
                        // Preview sur le personnage
                        $.post('https://' + GetParentResourceName() + '/updateSkin', JSON.stringify({
                            type: currentActiveCategory,
                            number: searchValue,
                            variation: 0
                        }));

                        // Refresh UI
                        const cards = activeGrid.querySelectorAll('.item-card');
                        cards.forEach(c => c.classList.remove('active'));
                        targetCard.classList.add('active');
                        targetCard.scrollIntoView({ behavior: 'smooth', block: 'center' });

                        const display = document.querySelector('.nav-display');
                        if (display) display.textContent = 0;
                        updateCartDisplay();
                    }
                }
            }
        });
    });

    // Variation Controls
    async function updateVariationLogic(direction) { // direction: -1 or 1
        if (!currentActiveCategory) return;

        const category = currentActiveCategory;
        if (cart[category]?.item === null) return;

        const maxVariations = await getMaxVariations(category);
        let currentVal = parseInt(display.textContent) || 0;
        let newValue = currentVal + direction;

        if (newValue < 0) newValue = maxVariations - 1;
        if (newValue >= maxVariations) newValue = 0;

        display.textContent = newValue;
        cart[category].variation = newValue;

        // Preview des variations sur le personnage
        const variationType = variationNames[category];
        $.post('https://' + GetParentResourceName() + '/updateVariation', JSON.stringify({
            type: variationType,
            number: newValue
        }));

        updateCartDisplay();
    }

    prevBtn.addEventListener('click', () => updateVariationLogic(-1));
    nextBtn.addEventListener('click', () => updateVariationLogic(1));
}

function initializeCart() {
    // Payment Button
    $('.pay-button').off('click').on('click', function () {
        if (Object.values(cart).some(item => item.item !== null)) {
            const paymentMethod = $(this).hasClass('carte') ? 'bank' : 'cash';
            $.post('https://' + GetParentResourceName() + '/pay', JSON.stringify({
                items: cart,
                paymentMethod: paymentMethod
            }));
            // Effacer le skin initial car l'achat est confirmé
            initialSkinState = null;
            closeAll();
        }
    });

    // Add to Accessories Cart Button
    $('#addToAccessoriesCart').off('click').on('click', function () {
        if (MenuCat === 'accesories' && currentActiveCategory) {
            const category = currentActiveCategory;
            if (cart[category] && cart[category].item !== null) {
                // Ajouter au panier
                accessoriesCart[category] = {
                    item: cart[category].item,
                    variation: cart[category].variation
                };
                
                // Notification visuelle
                $(this).html('<i class="fas fa-check"></i> Ajouté au panier');
                setTimeout(() => {
                    $(this).html('<i class="fas fa-cart-plus"></i> Ajouter au panier');
                }, 1500);
            }
        }
    });
    
    // Payment Buttons for Accessories
    $('.accesories .pay-button').off('click').on('click', function () {
        if (Object.keys(accessoriesCart).length === 0) return;
        
        const paymentMethod = $(this).hasClass('carte') ? 'bank' : 'cash';
        
        // Acheter tous les accessoires du panier en une seule requête
        $.post('https://' + GetParentResourceName() + '/buyAccessories', JSON.stringify({
            items: accessoriesCart,
            method: paymentMethod
        }));
        
        // Vider le panier après paiement
        Object.keys(accessoriesCart).forEach(key => delete accessoriesCart[key]);
        // Effacer le skin initial car l'achat est confirmé
        initialSkinState = null;
    });

    // Remove Items
    document.addEventListener('click', function (e) {
        if (e.target.classList.contains('remove-item')) {
            const category = e.target.getAttribute('data-category');
            const nakedValue = nakedValues[category] !== undefined ? nakedValues[category] : defaultValues[category];
            cart[category] = { item: nakedValue, variation: 0, selected: false };

            $.post('https://null-ui/updateSkin', JSON.stringify({
                type: category,
                number: nakedValue,
                variation: 0
            }));
            updateCartDisplay();
        }
    });
}

function updateCartDisplay() {
    const cartItems = document.querySelector('.cart-items');
    if (!cartItems) return;
    cartItems.innerHTML = '';

    const categoryGroups = {
        'Haut': ['tshirt_1', 'torso_1', 'decals_1', 'arms'],
        'Pantalon': ['pants_1'],
        'Chaussures': ['shoes_1']
    };

    const categoryNames = {
        tshirt_1: 'T-Shirt',
        torso_1: 'Torse',
        decals_1: 'Calques',
        arms: 'Bras',
        pants_1: 'Pantalon',
        shoes_1: 'Chaussures'
    };

    const hasItems = Object.values(cart).some(item => item.item !== null);
    const cartTotalPrice = document.getElementById('clothes-total-price');
    
    if (!hasItems) {
        cartItems.innerHTML = `
            <div class="cart-empty">
                <i class="fas fa-shopping-cart" style="font-size: 24px; margin-bottom: 10px; opacity: 0.5;"></i>
                <div>Votre panier est vide</div>
                <div style="font-size: 14px; margin-top: 5px;">Sélectionnez des articles pour les ajouter au panier</div>
            </div>
        `;
        if (cartTotalPrice) cartTotalPrice.textContent = '0€';
        return;
    }

    let totalPrice = 0;
    
    for (const [groupName, categories] of Object.entries(categoryGroups)) {
        const hasGroupItems = categories.some(category => cart[category] && cart[category].item !== null);

        if (hasGroupItems) {
            const groupTotal = calculateGroupTotal(categories);
            totalPrice += groupTotal;

            const groupDiv = document.createElement('div');
            groupDiv.className = 'cart-group';
            groupDiv.innerHTML = `<h3>${groupName} - Total: ${groupTotal}$</h3>`;
 
            const itemsDiv = document.createElement('div');
            itemsDiv.className = 'cart-group-items';

            categories.forEach(category => {
                const item = cart[category];
                if (item && item.item !== null) {
                    const itemPrice = calculateItemPrice(category, item.item);
                    const cartItem = document.createElement('div');
                    cartItem.className = 'cart-item';
                    cartItem.innerHTML = `
                        <div class="cart-item-info">
                            <img src="images/clothes/${playerSex}/${category}/${item.item}.webp" class="cart-item-image" alt="${categoryNames[category]} ${item.item}" onerror="this.style.display='none'">
                                <div class="cart-item-details">
                                    <span>${categoryNames[category]} n°${item.item}</span>
                                    <span class="variation-number">Variation: ${item.variation}</span>
                                </div>
                                <span class="cart-item-price">${itemPrice}$</span>
                            </div>
                        </div>
                    `;
                    itemsDiv.appendChild(cartItem);
                }
            });

            // Group Actions (Pay / Remove)
            const groupActions = document.createElement('div');
            groupActions.className = 'group-actions';
            groupActions.innerHTML = `
                <div class="payment-dropdown" id="payment-option-${groupName}">
                    <button class="pay-group card" data-method="cash" data-group="${groupName}">
                        <i class="fas fa-money-bill"></i></i> Payer (${groupTotal}$ )
                    </button>
                    <button class="pay-group cash" data-method="card" data-group="${groupName}">
                        <i class="fas fa-credit-card"></i></i> Payer (${groupTotal}$)
                    </button>
                </div>
                <button class="remove-group" data-group="${groupName}" title="Retirer le groupe">×</button>
            `;

            groupDiv.appendChild(itemsDiv);
            groupDiv.appendChild(groupActions);
            cartItems.appendChild(groupDiv);

            const payButtons = groupActions.querySelectorAll('.pay-group');
            payButtons.forEach(button => {
                button.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const method = button.dataset.method;
                    const group = button.getAttribute('data-group');
                    const groupCategories = categoryGroups[group];

                    const items = {};
                    groupCategories.forEach(category => {
                        if (cart[category] && cart[category].item !== null) {
                            items[category] = { item: cart[category].item, variation: cart[category].variation };
                            if (complementaires[group.toLowerCase()] && complementaires[group.toLowerCase()][category]) {
                                items[complementaires[group.toLowerCase()][category]] = items[category];
                            }
                        }
                    });

                    $.post('https://' + GetParentResourceName() + '/payItem', JSON.stringify({
                        items: items,
                        method: method,
                        group: group
                    }));
                });
            });

            groupActions.querySelector('.remove-group').addEventListener('click', () => {
                categoryGroups[groupName].forEach(category => {
                    const nakedValue = nakedValues[category] !== undefined ? nakedValues[category] : defaultValues[category];
                    cart[category] = { item: nakedValue, variation: 0, selected: false };
                    $.post('https://null-ui/updateSkin', JSON.stringify({
                        type: category,
                        number: nakedValue,
                        variation: 0
                    }));
                });
                updateCartDisplay();
            });
        }
    }
    
    // Update total price display
    if (cartTotalPrice) cartTotalPrice.textContent = totalPrice + '€';
}

function updateAccessoriesCartDisplay() {
    const cartContainer = document.querySelector('.accessories-cart-container');
    const cartEmpty = document.querySelector('#accessories-cart-view .cart-empty');
    const totalPriceElement = document.getElementById('accessories-total-price');
    
    if (!cartContainer) return;
    
    cartContainer.innerHTML = '';
    
    const accessoryNames = {
        mask_1: { label: 'Masque', icon: 'fa-mask' },
        bproof_1: { label: 'Gilet par balle', icon: 'fa-vest' },
        chain_1: { label: 'Chaîne', icon: 'fa-link' },
        helmet_1: { label: 'Chapeau', icon: 'fa-hat-cowboy' },
        ears_1: { label: 'Boucles d\'oreilles', icon: 'fa-ear-listen' },
        glasses_1: { label: 'Lunettes', icon: 'fa-glasses' },
        watches_1: { label: 'Montre', icon: 'fa-clock' },
        bracelets_1: { label: 'Bracelet', icon: 'fa-ring' },
        bags_1: { label: 'Sac', icon: 'fa-bag-shopping' }
    };
    
    const hasItems = Object.keys(accessoriesCart).length > 0;
    
    if (!hasItems) {
        if (cartEmpty) cartEmpty.style.display = 'flex';
        cartContainer.style.display = 'none';
        if (totalPriceElement) totalPriceElement.textContent = '0€';
        return;
    }
    
    if (cartEmpty) cartEmpty.style.display = 'none';
    cartContainer.style.display = 'flex';
    
    let totalPrice = 0;
    
    Object.entries(accessoriesCart).forEach(([category, itemData]) => {
        const itemPrice = calculateItemPrice(category, itemData.item);
        totalPrice += itemPrice;
        const info = accessoryNames[category] || { label: category, icon: 'fa-question' };
        
        const cartItem = document.createElement('div');
        cartItem.className = 'acc-cart-item';
        cartItem.innerHTML = `
            <div class="acc-cart-item-icon">
                <i class="fas ${info.icon}"></i>
            </div>
            <div class="acc-cart-item-details">
                <span class="acc-cart-item-name">${info.label} n°${itemData.item}</span>
                <span class="acc-cart-item-variation">Variation ${itemData.variation}</span>
            </div>
            <span class="acc-cart-item-price">${itemPrice}€</span>
            <button class="cart-item-remove" data-category="${category}" title="Retirer">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        cartContainer.appendChild(cartItem);
        
        // Add remove functionality
        const removeBtn = cartItem.querySelector('.cart-item-remove');
        removeBtn.addEventListener('click', () => {
            delete accessoriesCart[category];
            updateAccessoriesCartDisplay();
        });
    });
    
    if (totalPriceElement) {
        totalPriceElement.textContent = totalPrice + '€';
    }
}

function updateFullCartDisplay() {
    const cartGroupsContainer = document.querySelector('.cart-groups-container');
    const cartEmpty = document.querySelector('#cart-view .cart-empty');
    const cartTotalPrice = document.querySelector('#clothes-total-price');
    
    if (!cartGroupsContainer) return;
    
    cartGroupsContainer.innerHTML = '';
    
    const categoryGroups = {
        'Haut': ['tshirt_1', 'torso_1', 'decals_1', 'arms'],
        'Pantalon': ['pants_1'],
        'Chaussures': ['shoes_1']
    };
    
    const categoryNames = {
        tshirt_1: 'T-Shirt',
        torso_1: 'Torse',
        decals_1: 'Calques',
        arms: 'Bras',
        pants_1: 'Pantalon',
        shoes_1: 'Chaussures'
    };
    
    const hasItems = Object.values(cart).some(item => item.item !== null);
    
    if (!hasItems) {
        cartEmpty.style.display = 'block';
        cartGroupsContainer.style.display = 'none';
        if (cartTotalPrice) cartTotalPrice.textContent = '0€';
        return;
    }
    
    cartEmpty.style.display = 'none';
    cartGroupsContainer.style.display = 'flex';
    
    let totalPrice = 0;
    
    for (const [groupName, categories] of Object.entries(categoryGroups)) {
        const hasGroupItems = categories.some(category => cart[category] && cart[category].item !== null);
        
        if (hasGroupItems) {
            const groupTotal = calculateGroupTotal(categories);
            totalPrice += groupTotal;
            
            const groupDiv = document.createElement('div');
            groupDiv.className = 'cart-group';
            
            const groupHeader = document.createElement('h3');
            groupHeader.innerHTML = `<i class="fas fa-shopping-bag"></i> ${groupName} - ${groupTotal}€`;
            groupDiv.appendChild(groupHeader);
            
            const itemsDiv = document.createElement('div');
            itemsDiv.className = 'cart-group-items';
            
            categories.forEach(category => {
                const item = cart[category];
                if (item && item.item !== null) {
                    const itemPrice = calculateItemPrice(category, item.item);
                    const cartItem = document.createElement('div');
                    cartItem.className = 'cart-item';
                    cartItem.innerHTML = `
                        <img src="images/clothes/${playerSex}/${category}/${item.item}.webp" class="cart-item-image" alt="${categoryNames[category]}" onerror="this.style.display='none'">
                        <div class="cart-item-details">
                            <span>${categoryNames[category]} n°${item.item}</span>
                            <span class="variation-number">Variation: ${item.variation}</span>
                        </div>
                        <span class="cart-item-price">${itemPrice}€</span>
                        <button class="cart-item-remove" data-category="${category}">
                            <i class="fas fa-times"></i>
                        </button>
                    `;
                    itemsDiv.appendChild(cartItem);
                }
            });
            
            groupDiv.appendChild(itemsDiv);
            
            const groupActions = document.createElement('div');
            groupActions.className = 'group-actions';
            groupActions.innerHTML = `
                <button class="pay-group" data-method="cash" data-group="${groupName}">
                    <i class="fas fa-money-bill"></i> Liquide (${groupTotal}€)
                </button>
                <button class="pay-group" data-method="bank" data-group="${groupName}">
                    <i class="fas fa-credit-card"></i> Carte (${groupTotal}€)
                </button>
                <button class="remove-group" data-group="${groupName}" title="Retirer le groupe">
                    <i class="fas fa-trash"></i>
                </button>
            `;
            
            groupDiv.appendChild(groupActions);
            cartGroupsContainer.appendChild(groupDiv);
            
            // Event listeners pour les boutons de paiement de groupe
            groupActions.querySelectorAll('.pay-group').forEach(button => {
                button.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const method = button.dataset.method;
                    const group = button.dataset.group;
                    const groupCategories = categoryGroups[group];
                    
                    const items = {};
                    groupCategories.forEach(category => {
                        if (cart[category] && cart[category].item !== null) {
                            items[category] = { item: cart[category].item, variation: cart[category].variation };
                        }
                    });
                    
                    $.post('https://' + GetParentResourceName() + '/payItem', JSON.stringify({
                        items: items,
                        method: method,
                        group: group
                    }));
                });
            });
            
            // Event listener pour supprimer le groupe
            groupActions.querySelector('.remove-group').addEventListener('click', () => {
                categories.forEach(category => {
                    const nakedValue = nakedValues[category] !== undefined ? nakedValues[category] : defaultValues[category];
                    cart[category] = { item: nakedValue, variation: 0, selected: false };
                    $.post('https://null-ui/updateSkin', JSON.stringify({
                        type: category,
                        number: nakedValue,
                        variation: 0
                    }));
                });
                updateFullCartDisplay();
            });
        }
    }
    
    // Event listeners pour supprimer des items individuels
    cartGroupsContainer.querySelectorAll('.cart-item-remove').forEach(button => {
        button.addEventListener('click', () => {
            const category = button.dataset.category;
            const nakedValue = nakedValues[category] !== undefined ? nakedValues[category] : defaultValues[category];
            cart[category] = { item: nakedValue, variation: 0, selected: false };
            
            $.post('https://null-ui/updateSkin', JSON.stringify({
                type: category,
                number: nakedValue,
                variation: 0
            }));
            updateFullCartDisplay();
        });
    });
    
    if (cartTotalPrice) cartTotalPrice.textContent = totalPrice + '€';
}

// Global Escape Key
$(document).on('keydown', function (e) {
    if (e.key === "Escape") {
        if (MenuOpen && MenuCat !== "creator") {
            e.preventDefault();
            e.stopPropagation();
            closeAll();
            $.post("https://" + GetParentResourceName() + "/exit", JSON.stringify({ type: MenuCat, changeSkin: false }));
        }
    }
});

// Click outside to close payment options
document.addEventListener('click', () => {
    document.querySelectorAll('.payment-options').forEach(opt => opt.classList.remove('show'));
});
