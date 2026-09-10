const boutiqueManager = {
    currentCategory: null,
    selectedItem: null,
    isViewing: false,
    LastNotification: null,
    fadeOutTimeout: null,
    uniqueVehicles: [],

    init() {
        // Category cards click
        $('.boutique-category-card').on('click', (e) => {
            const category = $(e.currentTarget).data('category');
            if (!category) return;
            this.openCategory(category);
        });

        // Back button
        $('.boutique-back-btn').on('click', () => {
            this.showCategoriesPage();
        });

        // Close button
        $('.boutique-close-btn').on('click', () => {
            fetch(`https://null-ui/boutique:close`, { method: 'POST' });
        });

        // Detail overlay close
        $('.boutique-detail-close').on('click', () => {
            this.closeDetailOverlay();
        });

        // ESC key
        $(document).on('keydown', (e) => {
            if (e.key === 'Escape' && $('.boutique-container').hasClass('visible')) {
                if ($('.boutique-detail-overlay').is(':visible')) {
                    this.closeDetailOverlay();
                } else if ($('.boutique-items-page').is(':visible')) {
                    this.showCategoriesPage();
                } else {
                    fetch(`https://null-ui/boutique:close`, { method: 'POST' });
                }
            }
        });

        this.currentCategory = "vehicles";
        this.loadUniqueVehicles();
    },

    openCategory(category) {
        this.currentCategory = category;
        this.showItemsPage();
        this.loadItems(category);
    },

    showCategoriesPage() {
        $('.boutique-items-page').hide();
        $('.boutique-categories-page').show();
        $('.boutique-back-btn').hide();
        this.closeDetailOverlay();
    },

    showItemsPage() {
        $('.boutique-categories-page').hide();
        $('.boutique-items-page').show();
        $('.boutique-back-btn').show();
    },

    show() {
        const container = $('.boutique-container');
        container.addClass('visible');
        container.css('display', 'flex');

        this.showCategoriesPage();

        if (typeof ServerLogo !== 'undefined' && ServerLogo) {
            $('#boutique-server-logo').attr('src', ServerLogo);
        }

        this.uniqueVehicles = [];
        this.loadUniqueVehicles();
    },

    hide() {
        const container = $('.boutique-container');
        container.removeClass('visible');
        container.css('display', 'none');
        this.closeDetailOverlay();
        if (this.isViewing) {
            this.isViewing = false;
        }
    },

    updateUserInfo(data) {
        $('.coins-amount').text(data.coins);
    },

    loadItems(category) {
        const container = $('.boutique-items');
        container.html('<div class="loading"></div>');
        fetch(`https://null-ui/boutique:getItems`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ category })
        });
    },

    loadUniqueVehicles() {
        fetch(`https://null-ui/getUniqueVehicles`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
    },

    displayUniqueVehicles(vehicles) {
        this.uniqueVehicles = vehicles || [];
        if (this.currentCategory === 'vehicles' && $('.boutique-items-page').is(':visible')) {
            this._appendUniqueVehicles();
        }
    },

    _appendUniqueVehicles() {
        const container = $('.boutique-items');
        if (!this.uniqueVehicles || this.uniqueVehicles.length === 0) return;

        this.uniqueVehicles.forEach(vehicle => {
            const vehicleEl = $('<div>').addClass('boutique-item-card unique-vehicle');
            vehicleEl.html(`
                <div class="boutique-item-image">
                    <img src="${vehicle.image || 'images/boutique/vehicles/' + vehicle.model + '.webp'}" alt="${vehicle.label}">
                    <div class="boutique-item-tags">
                        <span class="boutique-tag"><i class="fas fa-gem"></i> Unique</span>
                    </div>
                </div>
                <div class="boutique-item-info">
                    <div class="boutique-item-name">${vehicle.label}</div>
                    <div class="boutique-item-controls">
                        <div class="boutique-price">
                            <i class="fas fa-gem"></i>
                            <span>${vehicle.price}</span>
                        </div>
                        <span class="boutique-stock">Stock: ${vehicle.stock}</span>
                    </div>
                </div>
            `);
            vehicleEl.on('click', () => {
                this.selectedItem = vehicle;
                this.showUniqueVehicleDetail(vehicle);
            });
            container.append(vehicleEl);
        });
    },

    displayItems(items) {
        const container = $('.boutique-items');
        container.empty();

        items.forEach(item => {
            const itemEl = $('<div>').addClass('boutique-item-card');
            itemEl.html(`
                <div class="boutique-item-image">
                    <img src="${item.image}" alt="${item.label}">
                    ${item.tags ? `<div class="boutique-item-tags">${item.tags.map(tag => `<span class="boutique-tag boutique-tag-${tag.toLowerCase()}">${tag}</span>`).join('')}</div>` : ''}
                </div>
                <div class="boutique-item-info">
                    <div class="boutique-item-name">${item.label}</div>
                    <div class="boutique-item-controls">
                        ${item.buyable !== false ? `
                            <div class="boutique-price">
                                <i class="fas fa-gem"></i>
                                <span>${item.price}</span>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `);
            itemEl.on('click', () => {
                this.selectedItem = item;
                if (this.currentCategory === 'cases') {
                    this.showCaseDetail(item);
                } else {
                    this.showItemDetail(item);
                }
            });
            container.append(itemEl);
        });

        if (this.currentCategory === 'vehicles') {
            this._appendUniqueVehicles();
        }
    },

    // ===== DETAIL OVERLAY SYSTEM =====
    openDetailOverlay(html) {
        const content = $('.boutique-detail-content');
        content.html(html);
        $('.boutique-detail-overlay').show();
    },

    closeDetailOverlay() {
        $('.boutique-detail-overlay').hide();
    },

    showItemDetail(item) {
        const html = `
            <div class="boutique-detail-image">
                <img src="${item.image}" alt="${item.label}">
            </div>
            <h3 class="boutique-detail-title">${item.label}</h3>
            ${item.description ? `<p class="boutique-detail-description">${item.description}</p>` : ''}

            ${item.stats ? `
                <div class="boutique-detail-section">
                    <h4>Statistiques</h4>
                    <div class="boutique-detail-stats">
                        ${Object.entries(item.stats).map(([stat, value]) => `
                            <div class="boutique-detail-stat-row">
                                <span class="boutique-detail-stat-label">${stat}</span>
                                <div class="boutique-detail-stat-bar">
                                    <div class="boutique-detail-stat-fill" style="width: ${(value / 10) * 100}%"></div>
                                </div>
                                <span class="boutique-detail-stat-value">${value}/10</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}

            ${this.currentCategory === 'packs' && item.info ? `
                <div class="boutique-detail-section">
                    <h4>Contenu du Pack</h4>
                    <div class="boutique-detail-info-grid">
                        ${Object.entries(item.info).map(([key, value]) => `
                            <div class="boutique-detail-info-item">
                                <span class="boutique-detail-info-label">${key}</span>
                                <span class="boutique-detail-info-value">${value}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}

            ${item.buyable !== false && item.price && item.five && item.teen ? `
                <div class="boutique-detail-section">
                    <h4>Quantité</h4>
                    <div class="boutique-detail-quantity">
                        <button class="qty-option active" data-amount="1">
                            1 caisse
                            <span class="qty-price">${item.price} <i class="fas fa-gem"></i></span>
                        </button>
                        <button class="qty-option" data-amount="5">
                            5 caisses
                            <span class="qty-price">${item.five} <i class="fas fa-gem"></i></span>
                        </button>
                        <button class="qty-option" data-amount="10">
                            10 caisses
                            <span class="qty-price">${item.teen} <i class="fas fa-gem"></i></span>
                        </button>
                    </div>
                </div>
            ` : ''}

            ${this.currentCategory === 'vehicles' && item.video ? `
                <div class="boutique-detail-section">
                    <h4>Vidéo</h4>
                    <video controls autoplay style="width: 100%; border-radius: 8px;">
                        <source src="./videos/boutique/vehicles/${item.model}.mp4" type="video/mp4">
                    </video>
                </div>
            ` : ''}

            <div class="boutique-detail-section" style="background:transparent; padding: 0;">
                <div class="boutique-detail-info-grid">
                    ${item.buyable !== false ? `
                        <div class="boutique-detail-info-item">
                            <span class="boutique-detail-info-label">Prix</span>
                            <span class="boutique-detail-info-value">${item.price} <i class="fas fa-gem"></i></span>
                        </div>
                    ` : ''}
                </div>
            </div>

            <div class="boutique-detail-actions">
                ${this.currentCategory === 'vehicles' ? `
                    <button class="boutique-detail-preview-btn" id="detail-preview-btn">
                        <i class="fas fa-eye"></i> Visualiser
                    </button>
                ` : ''}
                ${item.buyable !== false ? `
                    <button class="boutique-detail-buy-btn" id="detail-buy-btn">
                        <i class="fas fa-shopping-cart"></i> Acheter
                    </button>
                ` : ''}
            </div>
        `;

        this.openDetailOverlay(html);

        if (item.counter == null) item.counter = 1;

        // Quantity selector
        $('.boutique-detail-content').find('.qty-option').on('click', (e) => {
            const btn = $(e.currentTarget);
            btn.addClass('active').siblings().removeClass('active');
            item.counter = btn.data('amount');
        });

        // Buy
        $('#detail-buy-btn').on('click', () => {
            fetch(`https://null-ui/buyItem`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ category: this.currentCategory, item: item })
            });
        });

        // Preview
        $('#detail-preview-btn').on('click', () => {
            fetch(`https://null-ui/boutique:preview`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ type: this.currentCategory, item: item })
            });
        });
    },

    showUniqueVehicleDetail(vehicle) {
        const html = `
            <div class="boutique-detail-image">
                <img src="${vehicle.image || 'images/boutique/vehicles/' + vehicle.model + '.webp'}" alt="${vehicle.label}">
            </div>
            <h3 class="boutique-detail-title">${vehicle.label} <span style="color: #ffd700; font-size: 14px;"><i class="fas fa-gem"></i> Unique</span></h3>
            <p class="boutique-detail-description">Ce véhicule est unique et en stock limité.</p>

            ${vehicle.video ? `
                <div class="boutique-detail-section">
                    <h4>Vidéo</h4>
                    <video controls autoplay style="width: 100%; border-radius: 8px;">
                        <source src="videos/boutique/vehicles/${vehicle.model}.mp4" type="video/mp4">
                    </video>
                </div>
            ` : ''}

            <div class="boutique-detail-section">
                <h4>Informations</h4>
                <div class="boutique-detail-info-grid">
                    <div class="boutique-detail-info-item">
                        <span class="boutique-detail-info-label">Stock</span>
                        <span class="boutique-detail-info-value">${vehicle.stock || 0}/${vehicle.initStock || vehicle.stock || 0}</span>
                    </div>
                    <div class="boutique-detail-info-item">
                        <span class="boutique-detail-info-label">Prix</span>
                        <span class="boutique-detail-info-value">${vehicle.price} <i class="fas fa-gem"></i></span>
                    </div>
                    ${vehicle.idunique ? `
                        <div class="boutique-detail-info-item">
                            <span class="boutique-detail-info-label">ID Unique</span>
                            <span class="boutique-detail-info-value">${vehicle.idunique}</span>
                        </div>
                    ` : ''}
                    <div class="boutique-detail-info-item">
                        <span class="boutique-detail-info-label">Créé par</span>
                        <span class="boutique-detail-info-value">${vehicle.createBy || 'Admin'}</span>
                    </div>
                </div>
            </div>

            <div class="boutique-detail-actions">
                <button class="boutique-detail-preview-btn" id="detail-preview-btn">
                    <i class="fas fa-eye"></i> Visualiser
                </button>
                <button class="boutique-detail-buy-btn" id="detail-buy-btn">
                    <i class="fas fa-shopping-cart"></i> Acheter
                </button>
            </div>
        `;

        this.openDetailOverlay(html);

        $('#detail-buy-btn').on('click', () => {
            fetch(`https://null-ui/buyUniqueVehicle`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ vehicleId: vehicle.id })
            });
        });

        $('#detail-preview-btn').on('click', () => {
            fetch(`https://null-ui/boutique:preview`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ type: 'vehicles', item: vehicle, unique: true })
            });
        });
    },

    showCaseDetail(caseItem) {
        const html = `
            <div class="boutique-detail-image">
                <img src="${caseItem.image}" alt="${caseItem.label}">
            </div>
            <h3 class="boutique-detail-title">${caseItem.label}</h3>
            <p class="boutique-detail-description">${caseItem.description || 'Ouvrez cette caisse pour obtenir un objet aléatoire !'}</p>

            ${caseItem.possibleItems && caseItem.possibleItems.length > 0 ? `
                <div class="boutique-detail-section">
                    <h4>Contenus possibles</h4>
                    <div class="boutique-detail-stats">
                        ${caseItem.possibleItems.slice(0, 6).map(item => `
                            <div class="boutique-detail-stat-row">
                                <span class="boutique-detail-stat-label">${item.label}</span>
                                <span class="boutique-detail-stat-value" style="color: ${item.rarity === 4 ? '#e84118' : item.rarity === 3 ? '#ffd700' : item.rarity === 2 ? '#4cd137' : '#b8b8b8'};">★</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}

            ${caseItem.buyable !== false && caseItem.price && caseItem.five && caseItem.teen ? `
                <div class="boutique-detail-section">
                    <h4>Quantité</h4>
                    <div class="boutique-detail-quantity">
                        <button class="qty-option active" data-amount="1">
                            1 caisse
                            <span class="qty-price">${caseItem.price} <i class="fas fa-gem"></i></span>
                        </button>
                        <button class="qty-option" data-amount="5">
                            5 caisses
                            <span class="qty-price">${caseItem.five} <i class="fas fa-gem"></i></span>
                        </button>
                        <button class="qty-option" data-amount="10">
                            10 caisses
                            <span class="qty-price">${caseItem.teen} <i class="fas fa-gem"></i></span>
                        </button>
                    </div>
                </div>
            ` : ''}

            <div class="boutique-detail-actions">
                <button class="boutique-detail-buy-btn" id="detail-open-case-btn">
                    <i class="fas fa-box-open"></i> Ouvrir - ${caseItem.price} <i class="fas fa-gem"></i>
                </button>
            </div>
        `;

        this.openDetailOverlay(html);

        if (caseItem.counter == null) caseItem.counter = 1;

        $('.boutique-detail-content').find('.qty-option').on('click', (e) => {
            const btn = $(e.currentTarget);
            btn.addClass('active').siblings().removeClass('active');
            caseItem.counter = btn.data('amount');
        });

        $('#detail-open-case-btn').on('click', () => {
            this.openCaseModal(caseItem);
            this.closeDetailOverlay();
        });
    },

    // ===== PREVIEW =====
    startPreview(uniqueVeh) {
        $('.boutique-container').removeClass('visible');
        $('.boutique-container').css('display', 'none');
        $('body').addClass('preview-mode');

        $('.rotate-left').off('click').on('click', () => {
            fetch(`https://null-ui/boutique:rotate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ direction: 'left' })
            });
        });

        $('.rotate-right').off('click').on('click', () => {
            fetch(`https://null-ui/boutique:rotate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ direction: 'right' })
            });
        });

        $('.preview-controls .preview-buy-button').off('click').on('click', () => {
            if (uniqueVeh) {
                fetch(`https://null-ui/buyUniqueVehicle`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ vehicleId: this.selectedItem.id })
                });
            } else {
                fetch(`https://null-ui/buyItem`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ category: this.currentCategory, item: this.selectedItem })
                });
            }
            this.stopPreview();
        });

        $('.cancel-preview').off('click').on('click', () => {
            this.stopPreview();
        });
    },

    stopPreview() {
        $('.boutique-container').addClass('visible');
        $('.boutique-container').css('display', 'flex');
        $('body').removeClass('preview-mode');
        fetch(`https://null-ui/boutique:stopPreview`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ direction: 'right' })
        });
    },

    // ===== LEGACY COMPAT =====
    buyCurrentItem() {
        fetch(`https://null-ui/buyItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ category: this.currentCategory, item: this.selectedItem })
        });
    },

    previewCurrentItem() {
        fetch(`https://null-ui/boutique:preview`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ type: this.currentCategory, item: this.selectedItem })
        });
    },

    buyUniqueVehicle(vehicleId) {
        fetch(`https://null-ui/buyUniqueVehicle`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleId: vehicleId })
        });
    },

    previewUniqueVehicle() {
        fetch(`https://null-ui/boutique:preview`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ type: 'vehicles', item: this.selectedItem, unique: true })
        });
    },

    // ===== NOTIFICATIONS =====
    notification(message, time = 5500) {
        if (this.LastNotification !== null) {
            $('.boutique-notification').html(`<span>${this.parseLuaColors(message)}</span>`);
            clearTimeout(this.fadeOutTimeout);
            this.fadeOutTimeout = setTimeout(() => {
                $('.boutique-notification').addClass('hide');
                setTimeout(() => {
                    $('.boutique-notification').remove();
                    this.LastNotification = null;
                }, 500);
            }, time);
        } else {
            const notification = $(`
                <div class="boutique-notification">
                    <span>${this.parseLuaColors(message)}</span>
                </div>
            `);
            $('.notification-nui-container').append(notification);
            this.LastNotification = notification;
            notification.addClass('show');
            setTimeout(() => { notification.removeClass('show'); }, 500);
            this.fadeOutTimeout = setTimeout(() => {
                notification.addClass('hide');
                setTimeout(() => {
                    notification.remove();
                    this.LastNotification = null;
                }, 500);
            }, time);
        }
    },

    parseLuaColors(text) {
        const colorMap = {
            '~r~': '#FF0000', '~b~': '#1D99FFFF', '~g~': '#0B8800FF',
            '~y~': '#FFFF6BFF', '~p~': '#C300FFFF', '~c~': '#8D8D8DFF',
            '~m~': '#3F3F3FFF', '~u~': '#000000', '~o~': '#FF6600FF'
        };
        let result = '';
        let currentText = text;
        let colorStack = [];
        while (currentText.length > 0) {
            let colorFound = false;
            for (let color in colorMap) {
                if (currentText.startsWith(color)) {
                    colorStack.push(colorMap[color]);
                    result += `<span style="color: ${colorMap[color]}">`;
                    currentText = currentText.slice(color.length);
                    colorFound = true;
                    break;
                }
            }
            if (!colorFound) {
                if (currentText.startsWith('~s~')) {
                    if (colorStack.length > 0) { colorStack.pop(); result += '</span>'; }
                    currentText = currentText.slice(3);
                } else {
                    result += currentText[0];
                    currentText = currentText.slice(1);
                }
            }
        }
        while (colorStack.length > 0) { colorStack.pop(); result += '</span>'; }
        return result;
    },

    // ===== CAISSES =====
    displayCrateItems(items) {
        const crateItemsGrid = $('.crate-items-grid');
        crateItemsGrid.empty();
        const rarityLabels = { 1: 'Commun', 2: 'Rare', 3: 'Très Rare', 4: 'Légendaire' };
        items.forEach(item => {
            const itemElement = $(`
                <div class="crate-item rarity-${item.rarity}">
                    <img src="${item.image}" alt="${item.label}">
                    <div class="crate-item-name">${item.label}</div>
                    <div class="crate-item-rarity">${rarityLabels[item.rarity]}</div>
                </div>
            `);
            crateItemsGrid.append(itemElement);
        });
    },

    openCaseModal(caseItem) {
        this.selectedItem = caseItem;
        const modal = $('.case-wheel-modal');
        $('.wheel-title').text(caseItem.label);
        $('.wheel-price span').text(caseItem.price);
        if (caseItem.possibleItems && caseItem.possibleItems.length > 0) {
            this.displayPossibleItems(caseItem.possibleItems);
        }
        modal.fadeIn(300);
        $('.close-wheel-btn').off('click').on('click', () => { modal.fadeOut(300); });
        $('.spin-wheel-btn').off('click').on('click', () => { this.spinCase(caseItem); });
    },

    displayPossibleItems(items) {
        const grid = $('.possible-items-grid');
        grid.empty();
        const rarityLabels = { 1: 'Commun', 2: 'Rare', 3: 'Très Rare', 4: 'Légendaire' };
        items.forEach(item => {
            grid.append($(`
                <div class="possible-item rarity-${item.rarity}">
                    <img src="${item.image}" alt="${item.label}">
                    <div class="possible-item-name">${item.label}</div>
                </div>
            `));
        });
    },

    spinCase(caseItem) {
        fetch(`https://null-ui/boutique:openCase`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ caseId: caseItem.id })
        });
    },

    startCaseSpin(wonItem, allItems) {
        const wheelItems = $('.wheel-items');
        const spinBtn = $('.spin-wheel-btn');
        spinBtn.prop('disabled', true);
        wheelItems.empty();
        const itemsToShow = [];
        for (let i = 0; i < 20; i++) {
            itemsToShow.push(allItems[Math.floor(Math.random() * allItems.length)]);
        }
        itemsToShow[15] = wonItem;
        itemsToShow.forEach(item => {
            wheelItems.append($(`
                <div class="wheel-item rarity-${item.rarity}">
                    <img src="${item.image}" alt="${item.label}">
                    <div class="wheel-item-name">${item.label}</div>
                </div>
            `));
        });
        const itemWidth = 120;
        const targetPosition = -(15 * itemWidth - 200);
        wheelItems.css('transform', 'translateX(0)');
        setTimeout(() => { wheelItems.css('transform', `translateX(${targetPosition}px)`); }, 100);
        setTimeout(() => { this.showCaseResult(wonItem); spinBtn.prop('disabled', false); }, 3200);
    },

    showCaseResult(wonItem) {
        const rarityLabels = { 1: 'Commun', 2: 'Rare', 3: 'Très Rare', 4: 'Légendaire' };
        $('.prize-image').attr('src', wonItem.image);
        $('.prize-name').text(wonItem.label);
        $('.prize-rarity').text(rarityLabels[wonItem.rarity])
            .removeClass('rarity-1 rarity-2 rarity-3 rarity-4')
            .addClass(`rarity-${wonItem.rarity}`);
        $('.wheel-prize-display').fadeIn(300);
        setTimeout(() => {
            $('.wheel-prize-display').fadeOut(300);
            $('.case-wheel-modal').fadeOut(300);
        }, 3000);
    },

    // Legacy panel compat stubs
    showItemDetailsPanel(item) { this.showItemDetail(item); },
    showUniqueVehicleDetailsPanel(vehicle) { this.showUniqueVehicleDetail(vehicle); },
    showCaseDetailsPanel(caseItem) { this.showCaseDetail(caseItem); }
};

// NUI Message handler
window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.type) {
        case 'boutique:show':
            if (boutiqueManager.currentCategory === "weapons-custom") {
                boutiqueManager.currentCategory = "vehicles";
            }
            boutiqueManager.show();
            break;
        case 'boutique:hide':
            boutiqueManager.hide();
            break;
        case 'boutique:notification':
            boutiqueManager.notification(data.message);
            break;
        case 'inventory:sendMessage':
            if (data.message?.text && data.message?.time) {
                boutiqueManager.notification(data.message.text, data.message.time);
            } else if (data.message?.text) {
                boutiqueManager.notification(data.message.text);
            } else if (typeof data.message === 'string') {
                boutiqueManager.notification(data.message);
            }
            break;
        case 'boutique:uniqueVehicles':
        case 'boutique:displayUniqueVehicles':
            boutiqueManager.displayUniqueVehicles(data.vehicles);
            break;
        case 'boutique:updateUserInfo':
            boutiqueManager.updateUserInfo(data.data);
            break;
        case 'boutique:displayItems':
            boutiqueManager.displayItems(data.items);
            break;
        case 'boutique:displayCrateItems':
            boutiqueManager.displayCrateItems(data.items);
            break;
        case 'boutique:canPreview':
            boutiqueManager.startPreview(data.uniqueVeh);
            break;
        case 'boutique:startCaseSpin':
            boutiqueManager.startCaseSpin(data.wonItem, data.allItems);
            break;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    boutiqueManager.init();
});
