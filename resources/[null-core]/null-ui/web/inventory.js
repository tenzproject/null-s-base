let StartZone = null;
let playerSex = "male";

const inventory = {
    container: null,
    leftGrid: null,
    rightGrid: null,
    selectedItem: null,
    draggedItem: null,
    containerright: null,
    containercenter: null,
    containerleft: null,

    isOpen: false,
    isRightOpen: false,

    init() {
        this.initDragAndDrop();
        this.initSearch();
        this.setupEventListeners();
    },

    initDragAndDrop() {
        let ghostImage = null;
        let isDragging = false;
        let draggedItem = null;
        let mouseX = 0;
        let mouseY = 0;

        document.addEventListener('mousemove', (e) => {
            mouseX = e.clientX;
            mouseY = e.clientY;
            if (ghostImage && isDragging) {
                ghostImage.style.left = (mouseX) + 'px';
                ghostImage.style.top = (mouseY) + 'px';
            }
        });

        document.addEventListener('mousedown', (e) => {
            if (e.button === 0) {
                console.log('[INVENTORY DEBUG JS] Left click detected');
                const itemSlot = e.target.closest('.item-slot');
                console.log('[INVENTORY DEBUG JS] Item slot found:', itemSlot ? 'yes' : 'no');
                if (itemSlot && !isDragging) {
                    e.preventDefault();
                    closeContextMenu();
                    isDragging = true;
                    draggedItem = itemSlot;
                    StartZone = e.target.closest('.equip-slot, .shortcut-slot, .inventory-right, .inventory-left');
                    itemSlot.classList.add('dragging');

                    const item = JSON.parse(itemSlot.dataset.item);
                    const existingImg = itemSlot.querySelector('.item-content img');
                    ghostImage = document.createElement('div');
                    ghostImage.className = 'drag-ghost';

                    if (existingImg) {
                        ghostImage.innerHTML = `<img src="${existingImg.src}" alt="${item.label || item.name}">`;
                    } else {
                        ghostImage.innerHTML = `<img src="images/items/${item.name}.webp" alt="${item.label || item.name}">`;
                    }

                    ghostImage.style.left = (mouseX) + 'px';
                    ghostImage.style.top = (mouseY) + 'px';
                    document.body.appendChild(ghostImage);
                }
            } else if (e.button === 1) {
                closeContextMenu();
                //console.log('middle click');
            } else if (e.button === 2) {
                e.preventDefault();
                console.log('[INVENTORY DEBUG JS] Right click detected');
                const itemSlot = e.target.closest('.item-slot');
                console.log('[INVENTORY DEBUG JS] Item slot found:', itemSlot ? 'yes' : 'no');
                if (itemSlot) {
                    console.log('[INVENTORY DEBUG JS] Item dataset:', itemSlot.dataset.item);
                    closeContextMenu();
                    const contextMenu = $('.context-menu');
                    const item = JSON.parse(itemSlot.dataset.item);
                    console.log('[INVENTORY DEBUG JS] Parsed item:', item);
                    itemSlot.classList.add('selected');

                    contextMenu.find('.menu-option').hide();

                    let label = item.label || item.name;
                    if (item.metadata && item.metadata.title) {
                        label = item.metadata.title;
                    }
                    contextMenu.find('.title').text(label).show();

                    if (item.metadata && item.metadata.description) {
                        contextMenu.find('.description').text(item.metadata.description).show();
                    }
                    if (item.metadata && item.metadata.police) {
                        contextMenu.find('.description').text("Armes de votre service de Police.").show();
                    }
                    if (item.metadata && item.metadata.gouvernement) {
                        contextMenu.find('.description').text("Armes de votre service de Gouvernement.").show();
                    }
                    if (item.name === "identity_card" && item.metadata && item.metadata.firstname) {
                        contextMenu.find('.identitycard').show();
                        contextMenu.find('.name').html("<p class='value'>Nom</b> : " + item.metadata.firstname + " " + item.metadata.lastname);
                        contextMenu.find('.sex').html("<p class='value'>Sexe</b> : " + item.metadata.sex);
                        contextMenu.find('.dateofbirth').html("<p class='value'>Date de naissance</b> : " + item.metadata.birthday);
                        contextMenu.find('.licenses').html("");
                    }
                    if (item.name === "drive" && item.metadata && item.metadata.firstname) {
                        contextMenu.find('.identitycard').show();
                        contextMenu.find('.name').html("<p class='value'>Nom</b> : " + item.metadata.firstname + " " + item.metadata.lastname);
                        contextMenu.find('.sex').html("");
                        contextMenu.find('.dateofbirth').html("");
                        if (item.metadata.licenses) {
                            var htmlFinal = "";
                            for (var key in item.metadata.licenses) {
                                if (key === "drive_truck") {
                                    if (htmlFinal == "") {
                                        htmlFinal += "Camion";
                                    } else {
                                        htmlFinal += ", Camion";
                                    }
                                } else if (key === "drive_bike") {
                                    if (htmlFinal == "") {
                                        htmlFinal += "Moto";
                                    } else {
                                        htmlFinal += ", Moto";
                                    }
                                } else if (key === "drive") {
                                    if (htmlFinal == "") {
                                        htmlFinal += "Voiture";
                                    } else {
                                        htmlFinal += ", Voiture";
                                    }
                                }
                            }
                            if (htmlFinal !== "") {
                                htmlFinal += ".";
                                contextMenu.find('.licenses').html("<p class='value'>Catégorie</b> : " + htmlFinal);
                            } else {
                                contextMenu.find('.licenses').html("");
                            }
                        }
                    }
                    if (item.name === "weapon" && item.metadata && item.metadata.firstname) {
                        contextMenu.find('.identitycard').show();
                        contextMenu.find('.name').html("<p class='value'>Nom</b> : " + item.metadata.firstname + " " + item.metadata.lastname);
                        contextMenu.find('.sex').html("");
                        contextMenu.find('.dateofbirth').html("");
                        if (item.metadata.licenses) {
                            var htmlFinal = "";
                            for (var key in item.metadata.licenses) {
                                if (key === "weapon") {
                                    htmlFinal += "Léger";
                                } else if (key === "weapon2") {
                                    htmlFinal += "Lourd";
                                }
                            }
                            if (htmlFinal !== "") {
                                htmlFinal += ".";
                                contextMenu.find('.licenses').html("<p class='value'>Catégorie</b> : " + htmlFinal);
                            } else {
                                contextMenu.find('.licenses').html("");
                            }
                        }
                    }

                    // Afficher et configurer la durabilité si elle existe
                    if (item.durability) {
                        const durability = 100 - item.durability;
                        let durabilityClass = 'high';
                        if (durability < 30) durabilityClass = 'low';
                        else if (durability < 70) durabilityClass = 'medium';

                        const durabilityEl = contextMenu.find('.durability');
                        durabilityEl.find('.durability-bar').removeClass('high medium low').addClass(durabilityClass);
                        durabilityEl.find('.fill').css('width', durability + '%');
                        durabilityEl.show();
                    }

                    // Afficher arms perms si permanent
                    if (item.permanent === true) {
                        contextMenu.find('.arms-perm').show();
                    }

                    // Afficher le numéro de série s'il existe
                    if (item.serialnumber) {
                        contextMenu.find('.serial .value').text(item.serialnumber);
                        contextMenu.find('.serial').show();
                    }

                    // Afficher les boutons d'action
                    contextMenu.find('.use-btn, .rename-btn, .give-btn, .delete-btn').show();

                    // Configurer les actions des boutons
                    contextMenu.find('.use-btn').off('click').on('click', () => {
                        fetch(`https://null-ui/inventory:changeSlot`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ item: item })
                        });
                        closeContextMenu();
                    });

                    contextMenu.find('.rename-btn').off('click').on('click', () => {
                        fetch(`https://null-ui/inventory:renameItem`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ item: item })
                        });
                        closeContextMenu();
                    });

                    contextMenu.find('.give-btn').off('click').on('click', () => {
                        fetch(`https://null-ui/inventory:giveItem`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ item: item })
                        });
                        closeContextMenu();
                    });

                    contextMenu.find('.delete-btn').off('click').on('click', () => {
                        fetch(`https://null-ui/inventory:dropItem`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ item: item })
                        });
                        closeContextMenu();
                    });

                    // Positionner le menu
                    contextMenu.css({
                        display: 'block',
                        left: e.pageX + 'px',
                        top: e.pageY + 'px'
                    });

                    // Fermer le menu au clic en dehors
                    $(document).off('click.contextMenu').on('click.contextMenu', function (e) {
                        if (!contextMenu.is(e.target) && contextMenu.has(e.target).length === 0) {
                            closeContextMenu();
                            $(document).off('click.contextMenu');
                            itemSlot.classList.remove('selected');
                        }
                    });
                    $(document).off('mouseover.contextMenu').on('mouseover.contextMenu', function (e) {
                        if (!contextMenu.is(e.target) && contextMenu.has(e.target).length === 0) {
                            closeContextMenu();
                            $(document).off('mouseover.contextMenu');
                            itemSlot.classList.remove('selected');
                        }
                    });
                }
            }
        });

        // Terminer le drag au mouseup
        document.addEventListener('mouseup', (e) => {
            if (isDragging) {
                const dropZone = e.target.closest('.equip-slot, .shortcut-slot, .inventory-right, .inventory-left, .character-model');
                if (dropZone && dropZone !== StartZone) {
                    handleDrop(draggedItem, dropZone);
                }

                // Nettoyer
                if (ghostImage) {
                    document.body.removeChild(ghostImage);
                    ghostImage = null;
                }
                if (draggedItem) {
                    draggedItem.classList.remove('dragging');
                    draggedItem = null;
                }
                isDragging = false;

                // Retirer les effets de survol
                document.querySelectorAll('.drag-over').forEach(el => {
                    el.classList.remove('drag-over');
                });
            }
        });

        // Gérer le survol des zones de drop
        const dropZones = document.querySelectorAll('.equip-slot, .shortcut-slot, .inventory-right, .inventory-left');
        dropZones.forEach(zone => {
            zone.addEventListener('mouseover', (e) => {
                if (isDragging && StartZone !== zone) {
                    e.preventDefault();
                    zone.classList.add('drag-over');
                }
            });

            zone.addEventListener('mouseout', (e) => {
                if (isDragging) {
                    e.preventDefault();
                    zone.classList.remove('drag-over');
                }
            });
        });

        // Fonction pour gérer le drop
        function handleDrop(draggedItem, dropZone) {
            const itemData = JSON.parse(draggedItem.dataset.item);
            const startZoneIsEquipSlot = StartZone && StartZone.classList.contains('equip-slot');

            if (dropZone.classList.contains('shortcut-slot') && itemData.type === 'weapon') {
                const shortcuts = document.querySelector('.weapon-shortcuts');
                const slotNumber = Array.from(shortcuts.children).indexOf(dropZone);
                fetch(`https://null-ui/shortcut:set`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        item: itemData,
                        slot: slotNumber + 1
                    })
                });
            }
            else if (dropZone.classList.contains('equip-slot') && itemData.type !== 'weapon') {
                const slotType = dropZone.dataset.slot;
                if (itemData.type2 === slotType) {
                    fetch(`https://null-ui/shortcut:equipAccessory`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            item: itemData,
                            type: slotType
                        })
                    });
                }
            }
            else if (dropZone.classList.contains('inventory-right')) {
                // Si on drag depuis un equip-slot vers l'inventaire, retirer l'accessoire
                if (startZoneIsEquipSlot && itemData.type === 'accessory') {
                    fetch(`https://null-ui/shortcut:removeAccessory`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            type: itemData.type2,
                            item: null
                        })
                    });
                }
                fetch(`https://null-ui/inventory:changeSlot`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        item: itemData,
                        target: 'inventoryRight'
                    })
                });
            }
            else if (dropZone.classList.contains('inventory-left')) {
                // Si on drag depuis un equip-slot vers l'inventaire, retirer l'accessoire
                if (startZoneIsEquipSlot && itemData.type === 'accessory') {
                    fetch(`https://null-ui/shortcut:removeAccessory`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            type: itemData.type2,
                            item: null
                        })
                    });
                }
                fetch(`https://null-ui/inventory:changeSlot`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        item: itemData,
                        target: 'inventoryLeft'
                    })
                });
            }
            else if (dropZone.classList.contains('character-model')) {
                if (itemData.type === "accessory") {
                    fetch(`https://null-ui/shortcut:equipAccessory`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            item: itemData,
                            type: itemData.type2
                        })
                    });
                } else if (itemData.type === "weapon") {
                    fetch(`https://null-ui/inventory:changeSlot`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            item: itemData
                        })
                    });
                } else if (itemData.type === "item") {
                    fetch(`https://null-ui/inventory:changeSlot`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            item: itemData
                        })
                    });
                }
            }
        }
    },

    initSearch() {
        const searchInput = document.getElementById('inventory-search');
        if (!searchInput) return;

        // Déplacer la fonction applyFilters au niveau de l'objet pour qu'elle soit accessible partout
        this.applyFilters = () => {
            const searchTerm = searchInput.value.toLowerCase();
            const activeFilter = document.querySelector('.filter-btn.active')?.dataset.filter || 'all';
            const itemSlots = document.querySelectorAll('.inventory-left .inventory-grid .item-slot');

            itemSlots.forEach(slot => {
                if (!slot.dataset.item) return;
                const item = JSON.parse(slot.dataset.item);

                const matchesFilter = activeFilter === 'all' ? true : this.matchesFilter(item, activeFilter);
                const matchesSearch = (item.label || '').toLowerCase().includes(searchTerm) ||
                    (typeof item.name === 'string' && item.name.toLowerCase().includes(searchTerm));

                if (matchesFilter && matchesSearch) {
                    slot.classList.remove('filtered');
                } else {
                    slot.classList.add('filtered');
                }
            });
        };

        // Gérer le focus de la recherche
        searchInput.addEventListener('focus', () => {
            $.post('https://null-ui/inventory:searchFocus', JSON.stringify({}));
        });

        searchInput.addEventListener('blur', () => {
            $.post('https://null-ui/inventory:searchBlur', JSON.stringify({}));
        });

        // Appliquer les filtres lors de la saisie
        searchInput.addEventListener('input', () => this.applyFilters());

        // Initialiser les filtres
        this.initFilters();
    },

    initFilters() {
        const filterButtons = document.querySelectorAll('.filter-btn');
        if (!filterButtons.length) return;

        filterButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                filterButtons.forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                // Appliquer immédiatement les filtres avec la recherche existante
                this.applyFilters();
            });
        });
    },

    matchesFilter(item, filterType) {
        switch (filterType) {
            case 'weapon':
                return item.type === 'weapon';
            case 'clothes':
                return item.type === 'accessory';
            case 'food':
                return item.type === 'item';
            default:
                return true;
        }
    },

    setupEventListeners() {
        // Boutons d'action
        // document.querySelectorAll('.inv-button').forEach(button => {
        //     button.addEventListener('click', () => {
        //         if (!this.selectedItem) return;
        //         const action = button.dataset.action;
        //         const itemData = this.getItemData(this.selectedItem);

        //         switch(action) {
        //             case 'use':
        //                 $.post('https://null-ui/inventory:useItem', JSON.stringify({
        //                     name: itemData.name,
        //                     slot: itemData.slot
        //                 }));
        //                 break;
        //             case 'give':
        //                 $.post('https://null-ui/inventory:startGiveItem', JSON.stringify({
        //                     name: itemData.name,
        //                     slot: itemData.slot
        //                 }));
        //                 break;
        //             case 'rename':
        //                 $.post('https://null-ui/inventory:startRename', JSON.stringify({
        //                     name: itemData.name,
        //                     slot: itemData.slot
        //                 }));
        //                 break;
        //             case 'delete':
        //                 $.post('https://null-ui/inventory:dropItem', JSON.stringify({
        //                     name: itemData.name,
        //                     slot: itemData.slot
        //                 }));
        //                 break;
        //         }
        //     }); 
        // });

        this.setupDragAndDrop();
    },

    setupDragAndDrop() {
        const slots = document.querySelectorAll('.inventory-grid');
        slots.forEach(grid => {
            grid.addEventListener('dragstart', (e) => {
                if (e.target.classList.contains('item-slot')) {
                    this.draggedItem = e.target;
                    e.target.classList.add('dragging');
                }
            });

            grid.addEventListener('dragend', (e) => {
                if (this.draggedItem) {
                    this.draggedItem.classList.remove('dragging');
                    this.draggedItem = null;
                }
            });

            grid.addEventListener('dragover', (e) => {
                e.preventDefault();
            });

            // grid.addEventListener('dblclick', (e) => {
            //     e.preventDefault();
            //     e.stopPropagation();
            //     if (e.target.classList.contains('item-slot')) {
            //         fetch(`https://null-ui/inventory:changeSlot`, {
            //             method: 'POST',
            //             headers: {
            //                 'Content-Type': 'application/json'
            //             },
            //             body: JSON.stringify({
            //                 item: this.getItemData(e.target)
            //             })
            //         });
            //     }
            // });

            grid.addEventListener('drop', (e) => {
                e.preventDefault();
                const target = e.target.closest('.item-slot');
                if (!target || !this.draggedItem) return;

                const fromGrid = this.draggedItem.closest('.inventory-grid');
                const toGrid = target.closest('.inventory-grid');
                const itemData = this.getItemData(this.draggedItem);
                const toSlot = Array.from(toGrid.children).indexOf(target);

                if (fromGrid === this.leftGrid && toGrid === this.rightGrid) {
                    $.post('https://null-ui/inventory:transferToRight', JSON.stringify({
                        name: itemData.name,
                        fromSlot: itemData.slot,
                        toSlot: toSlot
                    }));
                } else if (fromGrid === this.rightGrid && toGrid === this.leftGrid) {
                    $.post('https://null-ui/inventory:transferToLeft', JSON.stringify({
                        name: itemData.name,
                        fromSlot: itemData.slot,
                        toSlot: toSlot
                    }));
                }
            });
        });
    },

    createItemElement(item) {
        const div = document.createElement('div');
        div.className = 'item-slot';
        div.draggable = true;
        div.dataset.item = JSON.stringify(item);

        const content = document.createElement('div');
        content.className = 'item-content';

        if (item.type === "accessory") {
            const img = document.createElement('img');
            let datatoget = "torso_1";
            if (item.type2 === "pants") {
                datatoget = "pants_1";
            } else if (item.type2 === "top") {
                datatoget = "torso_1";
            } else if (item.type2 === "shoes") {
                datatoget = "shoes_1";
            } else if (item.type2 === "gillet") {
                datatoget = "bproof_1";
            } else if (item.type2 === "hat") {
                datatoget = "helmet_1";
            } else if (item.type2 === "glasses") {
                datatoget = "glasses_1";
            } else if (item.type2 === "mask") {
                datatoget = "mask_1";
            } else if (item.type2 === "ear") {
                datatoget = "ears_1";
            } else if (item.type2 === "neck") {
                datatoget = "chain_1";
            } else if (item.type2 === "bag") {
                datatoget = "bags_1";
            } else if (item.type2 === "bracelet") {
                datatoget = "bracelets_1";
            } else if (item.type2 === "watch") {
                datatoget = "watches_1";
            }
            const clotheValue = item.data && item.data[datatoget] !== undefined ? item.data[datatoget] : 0;
            img.src = "images/clothes/" + playerSex + "/" + datatoget + "/" + clotheValue + ".webp";
            img.className = 'accessory';
            img.alt = item.label || item.name;
            img.onerror = function () {
                // Si l'URL fournie échoue, on utilise l'image par défaut
                this.src = 'images/items/box.png';
                this.onerror = null; // Éviter les boucles infinies
            };
            content.appendChild(img);
        } else {
            // Créer l'image avec l'URL fournie
            const img = document.createElement('img');
            img.src = "images/items/" + item.name + ".webp";
            img.alt = item.label || item.name;
            img.onerror = function () {
                // Si l'URL fournie échoue, on utilise l'image par défaut
                this.src = 'images/items/box.png';
                this.onerror = null; // Éviter les boucles infinies
            };
            content.appendChild(img);
        }

        // Ajouter le compteur si nécessaire
        if (item.count > 1) {
            const count = document.createElement('span');
            count.className = 'item-count';
            count.textContent = item.count;
            content.appendChild(count);
        }

        // Ajouter le label (priorité: metadata.title > label > name)
        const label = document.createElement('span');
        label.className = 'item-label';
        let displayLabel = item.label || item.name;
        if (item.metadata && item.metadata.title) {
            displayLabel = item.metadata.title;
        }
        label.textContent = displayLabel;
        content.appendChild(label);

        div.appendChild(content);

        // Ajouter les événements
        div.addEventListener('click', () => {
            this.selectItem(div);
        });

        return div;
    },

    selectItem(element) {
        if (this.selectedItem) {
            this.selectedItem.classList.remove('selected');
        }
        element.classList.add('selected');
        this.selectedItem = element;
    },

    getItemData(element) {
        try {
            return JSON.parse(element.dataset.item);
        } catch (e) {
            console.error('Error parsing item data:', e);
            return {};
        }
    },

    updateLeftInventory(items) {
        if (!this.leftGrid) return;
        this.leftGrid.innerHTML = '';
        if (Array.isArray(items)) {
            items.forEach(item => {
                this.leftGrid.appendChild(this.createItemElement(item));
            });
            // Ne pas appeler showinv ici, c'est géré par inventory:open
            this.applyFilters();
        }
    },

    updateRightInventory(items) {
        if (!this.rightGrid) return;
        this.rightGrid.innerHTML = '';
        if (Array.isArray(items)) {
            items.forEach(item => {
                this.rightGrid.appendChild(this.createItemElement(item));
            });
            this.applyFilters();
        }
    },

    updateWeight(side, current, max) {
        const container = document.querySelector(`.inventory-${side}`);
        if (!container) return;

        const currentWeightEl = container.querySelector('.current-weight');
        const maxWeightEl = container.querySelector('.max-weight');
        if (currentWeightEl && maxWeightEl) {
            if (current !== undefined && current !== null) {
                currentWeightEl.textContent = current.toFixed(1);
            }
            if (max !== undefined && max !== null) {
                maxWeightEl.textContent = max.toFixed(1);
            }
        }
    },

    show() {
        if (this.container) {
            this.container.classList.remove('closing');
            this.container.style.display = 'flex';
            this.container.classList.add('opening');
            setTimeout(() => {
                this.container.classList.remove('opening');
            }, 400);
            this.applyFilters();
        }
        window.postMessage({
            type: 'FORCE_CAN_INFO',
            bool: false,
        }, '*');
        closeContextMenu();
    },

    hide() {
        if (this.container) {
            this.container.classList.remove('opening');
            const rightVisible = this.containerright && 
                (this.containerright.style.opacity === '1' || this.containerright.style.opacity === 1);
            if (!rightVisible) {
                this.container.classList.add('right-hidden');
            }
            this.container.classList.add('closing');
            setTimeout(() => {
                if (this.container) {
                    this.container.style.display = 'none';
                    this.container.classList.remove('closing', 'right-hidden');
                }
            }, 280);
            this.selectedItem = null;
        }
        window.postMessage({
            type: 'FORCE_CAN_INFO',
            bool: true,
        }, '*');
        closeContextMenu();
    },

    showinv(side) {
        if (side === 'left') {
            if (this.containerleft) {
                this.containerleft.style.opacity = 1;
            }
            if (this.containercenter) {
                this.containercenter.style.opacity = 1;
            }
        } else if (side === 'right') {
            if (this.containerright) {
                this.containerright.style.opacity = 1;
            }
            if (this.containercenter) {
                this.containercenter.style.opacity = 1;
            }
        }
    },

    hideinv(side) {
        if (side === 'left') {
            if (this.containerleft) {
                this.containerleft.style.opacity = 0;
            }
        } else if (side === 'right') {
            if (this.containerright) {
                this.containerright.style.opacity = 0;
            }
        }
        
        // Ne masquer le center que si les deux inventaires sont fermés
        if (!this.isRightOpen && side === 'left') {
            if (this.containercenter) {
                this.containercenter.style.opacity = 0;
            }
        }
    }
};


const closeContextMenu = () => {
    const contextMenu = $('.context-menu');
    contextMenu.hide();
    document.querySelectorAll('.item-slot').forEach(slot => {
        slot.classList.remove('selected');
    });
};

$(document).ready(function () {
    inventory.hide();
});

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    // S'assurer que les éléments DOM sont trouvés
    inventory.container = document.querySelector('.inventory-container');
    inventory.containerleft = document.querySelector('.inventory-left');
    inventory.containercenter = document.querySelector('.inventory-center');
    inventory.containerright = document.querySelector('.inventory-right');
    inventory.leftGrid = document.querySelector('.inventory-left .inventory-grid');
    inventory.rightGrid = document.querySelector('.inventory-right .inventory-grid');

    if (inventory.container && inventory.leftGrid && inventory.rightGrid) {
        inventory.init();
    }
});

// Ajouter au gestionnaire de messages NUI existant
window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.type) {
        case 'setprices':
            if (data.playerSex) { 
                playerSex = data.playerSex;
            }
            break;
        case 'shortcut:setShortcut':
            let index, shortcut;
            if (data && data.data) {
                ({ index, shortcut } = data.data);
            } else {
                ({ index, shortcut } = data);
            }

            // Trouver le slot de shortcut
            const shortcuts = document.querySelector('.weapon-shortcuts');
            if (!shortcuts) return;

            const shortcutSlot = shortcuts.children[index - 1];
            if (!shortcutSlot) return;

            // Sauvegarder le numéro existant s'il y en a un
            const existingNumber = shortcutSlot.querySelector('.slot-number')?.textContent || index;

            // Vider le slot
            shortcutSlot.innerHTML = '';

            if (shortcut.name !== 'none') {
                // Créer le contenu de l'item
                const content = document.createElement('div');
                content.className = 'item-content';

                // Ajouter l'image
                const img = document.createElement('img');

                img.src = "images/items/" + shortcut.name + ".webp";
                img.alt = shortcut.label || shortcut.name;
                img.onerror = function () {
                    // Si l'URL fournie échoue, on utilise l'image par défaut
                    this.src = 'https://image.wac-fivem.com/image/box.png';
                    this.onerror = null; // Éviter les boucles infinies
                };
                content.appendChild(img);

                // Ajouter au slot
                shortcutSlot.appendChild(content);
                shortcutSlot.dataset.weapon = shortcut.name;

                // Ajouter le gestionnaire de double-clic
                shortcutSlot.ondblclick = function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    const slotIndex = Array.from(shortcuts.children).indexOf(shortcutSlot) + 1;
                    //console.log('Double-click on shortcut:', slotIndex);
                    fetch(`https://null-ui/shortcut:remove`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            slot: slotIndex
                        })
                    });
                };
            } else {
                // Créer le contenu pour le slot vide avec le numéro existant
                const content = document.createElement('div');
                content.className = 'item-content empty';

                const number = document.createElement('span');
                number.className = 'slot-number';
                number.textContent = existingNumber;
                content.appendChild(number);

                shortcutSlot.appendChild(content);
                shortcutSlot.dataset.weapon = '';
                shortcutSlot.ondblclick = null;
            }
            break;
        case 'shortcut:setAccessory':
            const { type, item } = event.data.data;
            //console.log('Setting accessory:', type, item);

            // Trouver le slot correspondant au type
            const slot = document.querySelector(`.equip-slot[data-slot="${type}"]`);
            if (!slot) {
                console.error('Slot not found for type:', type);
                return;
            }

            // Récupérer l'image par défaut
            const defaultImg = slot.querySelector('img:not(.item-img)');
            if (defaultImg) {
                defaultImg.style.display = 'none';
            }

            // Vider le slot des anciens contenus d'items
            const oldContent = slot.querySelector('.item-content');
            if (oldContent) oldContent.remove();

            if (item && item.name !== 'none') {
                // Créer le contenu de l'item
                const content = document.createElement('div');
                content.className = 'item-content';


                const img = document.createElement('img');
                let datatoget = "torso_1";
                if (item.type2 === "pants") {
                    datatoget = "pants_1";
                } else if (item.type2 === "top") {
                    datatoget = "torso_1";
                } else if (item.type2 === "shoes") {
                    datatoget = "shoes_1";
                } else if (item.type2 === "gillet") {
                    datatoget = "bproof_1";
                } else if (item.type2 === "hat") {
                    datatoget = "helmet_1";
                } else if (item.type2 === "glasses") {
                    datatoget = "glasses_1";
                } else if (item.type2 === "mask") {
                    datatoget = "mask_1";
                } else if (item.type2 === "ear") {
                    datatoget = "ears_1";
                } else if (item.type2 === "neck") {
                    datatoget = "chain_1";
                } else if (item.type2 === "bag") {
                    datatoget = "bags_1";
                } else if (item.type2 === "bracelet") {
                    datatoget = "bracelets_1";
                } else if (item.type2 === "watch") {
                    datatoget = "watches_1";
                }
                const clotheValue = item.data && item.data[datatoget] !== undefined ? item.data[datatoget] : 0;
                img.src = "images/clothes/" + playerSex + "/" + datatoget + "/" + clotheValue + ".webp";
                img.className = 'item-img';
                img.alt = item.label || item.name;
                img.onerror = function () {
                    // Si l'URL fournie échoue, on utilise l'image par défaut
                    this.src = 'https://image.wac-fivem.com/image/box.png';
                    this.onerror = null; // Éviter les boucles infinies
                };
                content.appendChild(img);

                // Ajouter le label (priorité: metadata.title > label > name)
                const label = document.createElement('span');
                label.className = 'item-label';
                let displayLabel = item.label || item.name;
                if (item.metadata && item.metadata.title) {
                    displayLabel = item.metadata.title;
                }
                label.textContent = displayLabel;
                content.appendChild(label);

                // Ajouter au slot
                slot.appendChild(content);
                slot.dataset.item = JSON.stringify(item);

                // Ajouter le gestionnaire de double-clic
                slot.ondblclick = function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    //console.log('Double-click on accessory slot:', type);
                    fetch(`https://null-ui/shortcut:removeAccessory`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            type: type,
                            item: null
                        })
                    });
                };
            } else {
                // Remettre l'image par défaut visible
                if (defaultImg) {
                    defaultImg.style.display = '';
                }
                slot.dataset.item = '';
                slot.ondblclick = null;
            }
            break;
    }
});
 
// Événements NUI
window.addEventListener('message', (event) => {
    if (!event.data) return;

    const data = event.data;

    switch (data.type) {
        case 'inventory:open':
            inventory.isOpen = true;
            inventory.isRightOpen = false;
            inventory.show();
            // Toujours afficher left et center à l'ouverture
            inventory.showinv('left');
            break;

        case 'inventory:close':
            inventory.isOpen = false;
            inventory.isRightOpen = false;
            
            // Masquer tous les éléments
            inventory.hideinv('left');
            inventory.hideinv('right');
            inventory.hide();
            
            // Réinitialiser les poids
            inventory.updateWeight('left', 0.0, 0.0);
            inventory.updateWeight('right', 0.0, 0.0);
            
            // Réinitialiser le titre du right
            const right = document.querySelector('.inventory-right h2');
            if (right) {
                right.textContent = '';
            }
            break;

        case 'inventory:setLeft':
            if (data.data && Array.isArray(data.data.inventory)) {
                inventory.updateLeftInventory(data.data.inventory);
            }
            break;

        case 'inventory:setRight':
            if (data.data && Array.isArray(data.data.inventory)) {
                // Ne pas appeler showinv ici, c'est géré par setInventoryRightData
                inventory.updateRightInventory(data.data.inventory);
            }
            break;

        case 'inventory:setLeftWeight':
            if (data.data) {
                inventory.updateWeight('left',
                    parseFloat(data.data.weight) || undefined,
                    parseFloat(data.data.maxWeight) || undefined
                );
            }
            break;

        case 'inventory:setRightWeight':
            if (data.data) {
                inventory.updateWeight('right',
                    parseFloat(data.data.weight) || undefined,
                    parseFloat(data.data.maxWeight) || undefined
                );
            }
            break;

        case 'inventory:setMaxRightWeight':
            const rightWeight = event.data.data.weight;
            //console.log('Setting right inventory max weight:', rightWeight);
            const rightWeightEl = document.querySelector('.inventory-right .weight-info .max-weight');
            if (rightWeightEl) {
                rightWeightEl.textContent = rightWeight.toFixed(1);
            }
            break;

        case 'inventory:setMaxLeftWeight':
            const leftWeight = event.data.data.weight;
            //console.log('Setting left inventory max weight:', leftWeight);
            const leftWeightEl = document.querySelector('.inventory-left .weight-info .max-weight');
            if (leftWeightEl) {
                leftWeightEl.textContent = leftWeight.toFixed(1);
            }
            break;

        case 'inventory:setInventoryLeftData':
            //console.log('Setting left inventory data:', event.data.data);
            const leftTitle = document.querySelector('.inventory-left h2');
            if (leftTitle) {
                leftTitle.textContent = event.data.data.title || 'Inventaire';
            }
            break;

        case 'inventory:setInventoryRightData':
            //console.log('Setting right inventory data:', event.data.data);
            const rightTitle = document.querySelector('.inventory-right h2');
            if (rightTitle) {
                rightTitle.textContent = event.data.data.title || '';
                // Gérer l'affichage/masquage du right inventory
                if (event.data.data.title !== '') {
                    inventory.showinv('right');
                    inventory.isRightOpen = true;
                } else {
                    inventory.hideinv('right');
                    inventory.isRightOpen = false;
                }
            }
            break;

        case 'inventory:disableRightInventory':
            //console.log('Toggling right inventory:', event.data.data);
            const rightInventory = document.querySelector('.inventory-right');
            if (rightInventory) {
                if (event.data.data.disable) {
                    rightInventory.classList.add('disabled');
                    rightInventory.style.opacity = '0.5';
                    rightInventory.style.pointerEvents = 'none';
                } else {
                    rightInventory.classList.remove('disabled');
                    rightInventory.style.opacity = '';
                    rightInventory.style.pointerEvents = '';
                }
            }
            break;
    }
});

// Fermeture avec Échap
document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape' && inventory.isOpen) {
        $.post('https://null-ui/inventory:close', JSON.stringify({}));
    }
});

// Empêcher Tab de sélectionner des éléments dans l'inventaire
document.addEventListener('keydown', (e) => {
    if (e.key === 'Tab' && inventory.isOpen) {
        e.preventDefault();
        e.stopPropagation();
    }
});



function initializeShortcutSlots() {
    const shortcuts = document.querySelector('.weapon-shortcuts');
    if (!shortcuts) return;

    Array.from(shortcuts.children).forEach((slot, index) => {
        if (!slot.querySelector('.slot-number')) {
            const content = document.createElement('div');
            content.className = 'item-content empty';

            const number = document.createElement('span');
            number.className = 'slot-number';
            number.textContent = index + 1;
            content.appendChild(number);

            slot.innerHTML = '';
            slot.appendChild(content);
        }
    });
}

document.addEventListener('DOMContentLoaded', initializeShortcutSlots);

// Fonction pour mettre à jour les stats
function updateStat(statName, value) {
    const progressBar = document.querySelector(`.stat-progress-bar.${statName}`);
    if (progressBar) {
        // S'assurer que la valeur est entre 0 et 100
        const percentage = Math.max(0, Math.min(100, value));
        progressBar.style.width = `${percentage}%`;

        // Ajouter/retirer la classe low si en dessous de 20%
        if (percentage <= 20) {
            progressBar.classList.add('low');
        } else {
            progressBar.classList.remove('low');
        }
    }
}

// Gestionnaire de messages NUI
window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.type) {
        case 'inventory:updateStats':
            const stats = data.data;
            if (stats) {
                if (stats.health !== undefined) updateStat('health', stats.health);
                if (stats.hunger !== undefined) updateStat('hunger', stats.hunger);
                if (stats.thirst !== undefined) updateStat('thirst', stats.thirst);
                if (stats.oxygen !== undefined) updateStat('oxygen', stats.oxygen);
                if (stats.stamina !== undefined) updateStat('stamina', stats.stamina);
                if (stats.stress !== undefined) updateStat('stress', stats.stress);
                if (stats.alcohol !== undefined) updateStat('alcohol', stats.alcohol);
                if (stats.drug !== undefined) updateStat('drug', stats.drug);
            }
            break;
    }
});