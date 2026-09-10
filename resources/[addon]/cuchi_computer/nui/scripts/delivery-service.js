// Variables globales pour le service de livraison
let deliveryItemsList = {};
let currentDeliveryCart = {};
let pendingRefreshDelivery = false;
let deliveryAddress = "";
let deliveryNote = "";

// Fonction pour formater les prix
function formatDeliveryPrice(price) {
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'USD' }).format(price);
}

// Fonction pour initialiser la liste des articles
function initDeliveryItems() {
    if (!deliveryItemsList || Object.keys(deliveryItemsList).length === 0) {
        console.error('La liste des articles est vide ou non définie!');
        // Créer une liste d'articles factice pour les tests
        deliveryItemsList = {
            "test-item": {
                name: "test-item",
                label: "Article de test",
                price: 50,
                type: "item"
            }
        };
    }
    
    // Rafraîchir l'affichage
    refreshDeliveryItems();
}

// Fonction pour ajouter un article au panier
function addToCart(itemId, quantity = 1) {
    if (!deliveryItemsList[itemId]) {
        console.error(`Article ${itemId} non trouvé dans la liste`);
        return;
    }
    
    if (!currentDeliveryCart[itemId]) {
        currentDeliveryCart[itemId] = 0;
    }
    
    currentDeliveryCart[itemId] += quantity;
    refreshDeliveryCart();
    
    // Animation de confirmation
    const itemElement = document.querySelector(`.delivery-item[data-id="${itemId}"]`);
    if (itemElement) {
        itemElement.classList.add('added-to-cart');
        setTimeout(() => {
            itemElement.classList.remove('added-to-cart');
        }, 500);
    }
}

// Fonction pour supprimer un article du panier
function removeFromCart(itemId, quantity = 1) {
    if (!currentDeliveryCart[itemId] || currentDeliveryCart[itemId] <= 0) {
        return;
    }
    
    currentDeliveryCart[itemId] -= quantity;
    
    if (currentDeliveryCart[itemId] <= 0) {
        delete currentDeliveryCart[itemId];
    }
    
    refreshDeliveryCart();
}

// Fonction pour vider le panier
function clearCart() {
    currentDeliveryCart = {};
    refreshDeliveryCart();
}

// Fonction pour calculer le total du panier
function calculateCartTotal() {
    let total = 0;
    
    for (const [itemId, quantity] of Object.entries(currentDeliveryCart)) {
        if (deliveryItemsList[itemId]) {
            total += deliveryItemsList[itemId].price * quantity;
        }
    }
    
    // Ajouter les frais de livraison (10% du total, minimum 50$)
    const shippingCost = Math.max(50, total * 0.1);
    
    return {
        subtotal: total,
        shipping: shippingCost,
        total: total + shippingCost
    };
}

// Fonction pour rafraîchir l'affichage du panier
function refreshDeliveryCart() {
    const cartContainer = document.getElementById('delivery-cart-items');
    const cartSummary = document.getElementById('delivery-cart-summary');
    
    if (!cartContainer || !cartSummary) {
        pendingRefreshDelivery = true;
        return;
    }
    
    pendingRefreshDelivery = false;
    
    // Vider le conteneur du panier
    cartContainer.innerHTML = '';
    
    // Vérifier si le panier est vide
    if (Object.keys(currentDeliveryCart).length === 0) {
        cartContainer.innerHTML = '<div class="delivery-cart-empty">Votre panier est vide</div>';
        cartSummary.innerHTML = `
            <div class="delivery-cart-total">
                <span>Total:</span>
                <span>${formatDeliveryPrice(0)}</span>
            </div>
            <button class="delivery-checkout-button" disabled>Commander</button>
        `;
        return;
    }
    
    // Ajouter chaque article au panier
    for (const [itemId, quantity] of Object.entries(currentDeliveryCart)) {
        const item = deliveryItemsList[itemId];
        if (!item) continue;
        
        const itemElement = document.createElement('div');
        itemElement.className = 'delivery-cart-item';
        
        const itemImage = item.name ? `assets/images/items/${item.name}.png` : 'assets/images/items/default.png';
        
        itemElement.innerHTML = `
            <div class="delivery-cart-item-image">
                <img src="${itemImage}" alt="${item.label}" onerror="this.src='assets/images/items/default.png'">
            </div>
            <div class="delivery-cart-item-details">
                <div class="delivery-cart-item-name">${item.label}</div>
                <div class="delivery-cart-item-price">${formatDeliveryPrice(item.price)}</div>
            </div>
            <div class="delivery-cart-item-quantity">
                <button class="delivery-quantity-button minus" onclick="removeFromCart('${itemId}')">-</button>
                <span>${quantity}</span>
                <button class="delivery-quantity-button plus" onclick="addToCart('${itemId}')">+</button>
            </div>
            <div class="delivery-cart-item-total">
                ${formatDeliveryPrice(item.price * quantity)}
            </div>
            <button class="delivery-cart-item-remove" onclick="removeFromCart('${itemId}', ${quantity})">
                <i class="fas fa-trash"></i>
            </button>
        `;
        
        cartContainer.appendChild(itemElement);
    }
    
    // Mettre à jour le résumé du panier
    const totals = calculateCartTotal();
    
    cartSummary.innerHTML = `
        <div class="delivery-cart-subtotal">
            <span>Sous-total:</span>
            <span>${formatDeliveryPrice(totals.subtotal)}</span>
        </div>
        <div class="delivery-cart-shipping">
            <span>Frais de livraison:</span>
            <span>${formatDeliveryPrice(totals.shipping)}</span>
        </div>
        <div class="delivery-cart-total">
            <span>Total:</span>
            <span>${formatDeliveryPrice(totals.total)}</span>
        </div>
        <button class="delivery-checkout-button" onclick="showCheckoutForm()">Commander</button>
    `;
}

// Fonction pour afficher le formulaire de commande
function showCheckoutForm() {
    const mainContainer = document.getElementById('delivery-main-container');
    const checkoutContainer = document.getElementById('delivery-checkout-container');
    
    if (!mainContainer || !checkoutContainer) return;
    
    mainContainer.style.display = 'none';
    checkoutContainer.style.display = 'block';
    
    // Afficher le résumé de la commande
    const totals = calculateCartTotal();
    const orderSummary = document.getElementById('delivery-order-summary');
    
    if (orderSummary) {
        orderSummary.innerHTML = `
            <h3>Résumé de votre commande</h3>
            <div class="delivery-order-items">
                ${Object.entries(currentDeliveryCart).map(([itemId, quantity]) => {
                    const item = deliveryItemsList[itemId];
                    if (!item) return '';
                    return `
                        <div class="delivery-order-item">
                            <span>${item.label} x${quantity}</span>
                            <span>${formatDeliveryPrice(item.price * quantity)}</span>
                        </div>
                    `;
                }).join('')}
            </div>
            <div class="delivery-order-subtotal">
                <span>Sous-total:</span>
                <span>${formatDeliveryPrice(totals.subtotal)}</span>
            </div>
            <div class="delivery-order-shipping">
                <span>Frais de livraison:</span>
                <span>${formatDeliveryPrice(totals.shipping)}</span>
            </div>
            <div class="delivery-order-total">
                <span>Total:</span>
                <span>${formatDeliveryPrice(totals.total)}</span>
            </div>
        `;
    }
}

// Fonction pour revenir à la page principale
function backToMain() {
    const mainContainer = document.getElementById('delivery-main-container');
    const checkoutContainer = document.getElementById('delivery-checkout-container');
    const confirmationContainer = document.getElementById('delivery-confirmation-container');
    
    if (!mainContainer || !checkoutContainer || !confirmationContainer) return;
    
    mainContainer.style.display = 'flex';
    checkoutContainer.style.display = 'none';
    confirmationContainer.style.display = 'none';
}

// Fonction pour passer la commande
let LastOrderTime = null;
function placeOrder() {
    if (LastOrderTime && (Date.now() - LastOrderTime) < 1000) {
        return;
    }
    LastOrderTime = Date.now();
    const noteInput = document.getElementById('delivery-note');
    
    // L'adresse est automatiquement celle du laboratoire
    deliveryAddress = "Laboratoire actuel";
    deliveryNote = noteInput ? noteInput.value.trim() : "";
    
    // Préparer les données de la commande
    const orderItems = {};
    for (const [itemId, quantity] of Object.entries(currentDeliveryCart)) {
        if (deliveryItemsList[itemId]) {
            orderItems[itemId] = {
                id: itemId,
                name: deliveryItemsList[itemId].name,
                label: deliveryItemsList[itemId].label,
                price: deliveryItemsList[itemId].price,
                quantity: quantity
            };
        }
    }
    
    const totals = calculateCartTotal();
    
    // Afficher un loader pendant le traitement de la commande
    document.getElementById('delivery-service-loader').style.display = 'block';
    
    // Utiliser la méthode recommandée pour les callbacks NUI dans FiveM
    const data = {
        items: orderItems,
        address: deliveryAddress,
        note: deliveryNote,
        total: totals.total
    };
    
    // Utiliser la méthode spécifique à FiveM pour les callbacks NUI
    fetch("https://cuchi_computer/placeDeliveryOrder", {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        // Masquer le loader
        document.getElementById('delivery-service-loader').style.display = 'none';
        
        console.log('Réponse reçue:', resp);
        
        // Vérifier si la réponse contient les propriétés attendues
        if (resp && resp.success) {
            // Vider le panier
            clearCart();
            
            // Afficher la confirmation de commande
            showOrderConfirmation(resp.orderId);
        } else {
            // Afficher un message d'erreur
            const errorElement = document.createElement('div');
            errorElement.className = 'delivery-error-message';
            errorElement.textContent = (resp && resp.message) || 'Une erreur est survenue lors du traitement de votre commande.';
            
            const checkoutForm = document.querySelector('.delivery-checkout-form');
            if (checkoutForm) {
                checkoutForm.prepend(errorElement);
                
                // Supprimer le message d'erreur après 5 secondes
                setTimeout(() => {
                    errorElement.remove();
                }, 5000);
            }
        }
        if (loader) loader.style.display = 'none';
    });
}

// Fonction pour afficher la confirmation de commande
function showOrderConfirmation(orderId) {
    const mainContainer = document.getElementById('delivery-main-container');
    const checkoutContainer = document.getElementById('delivery-checkout-container');
    const confirmationContainer = document.getElementById('delivery-confirmation-container');
    
    if (!mainContainer || !checkoutContainer || !confirmationContainer) return;
    
    mainContainer.style.display = 'none';
    checkoutContainer.style.display = 'none';
    confirmationContainer.style.display = 'block';
    
    const confirmationMessage = document.getElementById('delivery-confirmation-message');
    if (confirmationMessage) {
        confirmationMessage.innerHTML = `
            <h2>Commande confirmée!</h2>
            <p>Votre commande #${orderId} a été passée avec succès.</p>
            <p>Vos articles seront livrés à votre laboratoire actuel.</p>
            ${deliveryNote ? `<p>Note: ${deliveryNote}</p>` : ''}
            <p>Temps de livraison moyen : 20-90 minutes</p>
            <p>Merci pour votre achat!</p>
        `;
    }
}

// Fonction pour rechercher des articles
function searchDeliveryItems() {
    const searchInput = document.getElementById('delivery-search');
    const itemsContainer = document.getElementById('delivery-items-list');
    
    if (!searchInput || !itemsContainer) return;
    
    const searchTerm = searchInput.value.toLowerCase();
    
    // Réinitialiser l'affichage si la recherche est vide
    if (searchTerm === '') {
        refreshDeliveryItems();
        return;
    }
    
    // Filtrer les articles en fonction du terme de recherche
    const filteredItems = Object.entries(deliveryItemsList).filter(([_, item]) => {
        return item.label.toLowerCase().includes(searchTerm);
    });
    
    // Vider le conteneur
    itemsContainer.innerHTML = '';
    
    // Afficher les résultats de la recherche
    if (filteredItems.length === 0) {
        itemsContainer.innerHTML = '<div class="delivery-no-results">Aucun résultat trouvé</div>';
        return;
    }
    
    // Ajouter chaque article filtré
    for (const [itemId, item] of filteredItems) {
        createItemElement(itemId, item, itemsContainer);
    }
}

// Fonction pour créer un élément d'article
function createItemElement(itemId, item, container) {
    const itemElement = document.createElement('div');
    itemElement.className = 'delivery-item';
    itemElement.dataset.id = itemId;
    
    const itemImage = item.name ? `assets/images/items/${item.name}.png` : 'assets/images/items/default.png';
    
    itemElement.innerHTML = `
        <div class="delivery-item-image">
            <img src="${itemImage}" alt="${item.label}" onerror="this.src='assets/images/items/default.png'">
        </div>
        <div class="delivery-item-details">
            <div class="delivery-item-name">${item.label}</div>
            <div class="delivery-item-price">${formatDeliveryPrice(item.price)}</div>
        </div>
        <button class="delivery-add-to-cart" onclick="addToCart('${itemId}')">
            <i class="fas fa-cart-plus"></i> Ajouter
        </button>
    `;
    
    container.appendChild(itemElement);
}

// Fonction pour rafraîchir la liste des articles
function refreshDeliveryItems() {
    console.log('Refreshing delivery items...');
    const itemsContainer = document.getElementById('delivery-items-list');
    
    if (!itemsContainer) {
        pendingRefreshDelivery = true;
        return;
    }
    
    pendingRefreshDelivery = false;
    itemsContainer.innerHTML = '';
    
    // Vérifier si la liste des articles est vide
    if (Object.keys(deliveryItemsList).length === 0) {
        itemsContainer.innerHTML = '<div class="delivery-no-items">Aucun article disponible</div>';
        return;
    }
    
    // Ajouter chaque article à la liste
    for (const [itemId, item] of Object.entries(deliveryItemsList)) {
        createItemElement(itemId, item, itemsContainer);
    }
}

// Fonction pour vérifier s'il y a un rafraîchissement en attente
function checkPendingRefreshDelivery() {
    if (pendingRefreshDelivery) {
        console.log('Checking pending refresh for delivery...');
        refreshDeliveryItems();
        refreshDeliveryCart();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefreshDelivery, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Delivery Service: Received show event:', event.data);
        
        // Déboguer tous les champs du message pour voir ce qui est reçu
        console.log('Delivery Service: Debugging all fields:');
        for (const key in event.data) {
            console.log(`Field ${key}:`, event.data[key]);
        }
        
        // Récupérer la liste des articles depuis le message
        if (event.data.itemsList) {
            console.log('Delivery Service: Items list received:', JSON.stringify(event.data.itemsList));
            console.log('Delivery Service: Items list type:', typeof event.data.itemsList);
            console.log('Delivery Service: Items list is array?', Array.isArray(event.data.itemsList));
            
            // Vérifier si c'est un objet avec des propriétés
            if (typeof event.data.itemsList === 'object' && !Array.isArray(event.data.itemsList)) {
                console.log('Delivery Service: Items list keys:', Object.keys(event.data.itemsList));
            }
            
            deliveryItemsList = event.data.itemsList;
        } else {
            console.error('Delivery Service: No items list received!');
        }
        
        // Attendre que le bureau soit initialisé avant de rafraîchir
        window.addEventListener('desktopInitialized', () => {
            console.log('Delivery Service: Desktop initialized, initializing delivery service');
            setTimeout(() => {
                // Initialiser les articles
                initDeliveryItems();
                
                // Initialiser les gestionnaires d'événements pour l'application
                initDeliveryEventListeners();
            }, 0);
        }, { once: true });
    }
});

// Fonction pour initialiser les gestionnaires d'événements
function initDeliveryEventListeners() {
    // Gestionnaire pour le bouton de recherche
    const searchButton = document.getElementById('delivery-search-button');
    if (searchButton) {
        searchButton.addEventListener('click', searchDeliveryItems);
    }
    
    // Gestionnaire pour la touche Entrée dans le champ de recherche
    const searchInput = document.getElementById('delivery-search');
    if (searchInput) {
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                searchDeliveryItems();
            }
        });
    }
    
    // Gestionnaire pour le bouton de checkout
    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('delivery-checkout-button') && !e.target.disabled) {
            showCheckoutForm();
        }
    });
    
    // Gestionnaire pour les boutons de retour
    const backButtons = document.querySelectorAll('.delivery-back-button');
    backButtons.forEach(button => {
        button.addEventListener('click', backToMain);
    });
    
    // Gestionnaire pour le bouton de commande
    const placeOrderButton = document.querySelector('.delivery-place-order');
    if (placeOrderButton) {
        placeOrderButton.addEventListener('click', placeOrder);
    }
    
    console.log('Delivery Service: Event listeners initialized');
}
