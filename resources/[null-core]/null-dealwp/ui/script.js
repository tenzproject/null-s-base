// Liste des drogues disponibles pour la vente
const drugsList = [
    { id: 'weed', label: 'Pochon de Weed', item: 'weed_pooch' },
    { id: 'meth', label: 'Pochon de Meth', item: 'meth_pooch' },
    { id: 'coke', label: 'Pochon de Coke', item: 'coke_pooch' }
];

// État des drogues sélectionnées
let selectedDrugs = [];

// Fonction pour mettre à jour le statut d'une drogue (disponible ou non)
function updateDrugStatus(drugId, hasItem) {
    const statusElement = document.getElementById(`${drugId}-status`);
    
    if (statusElement) {
        if (hasItem) {
            statusElement.textContent = 'Disponible';
            statusElement.style.color = 'var(--green)';
            document.getElementById(drugId).disabled = false;
        } else {
            statusElement.textContent = 'Non disponible';
            statusElement.style.color = 'var(--red)';
            document.getElementById(drugId).disabled = true;
            document.getElementById(drugId).checked = false;
        }
    }
}

// Fonction pour afficher une offre d'achat
function showDealOffer(offer) {
    const offersContainer = document.getElementById('deal-offers');
    const offerElement = document.createElement('div');
    offerElement.className = 'deal-offer';
    offerElement.id = `offer-${offer.id}`;
    
    offerElement.innerHTML = `
        <div class="deal-offer-header">
            <div class="deal-offer-title">${offer.drugLabel}</div>
            <div class="deal-offer-time">${new Date().toLocaleTimeString()}</div>
        </div>
        <div class="deal-offer-details">
            Quantité: ${offer.quantity} | Prix: $${offer.price}
        </div>
        <div class="deal-offer-actions">
            <button class="deal-action accept-btn" data-offer-id="${offer.id}">Accepter</button>
            <button class="deal-action negotiate-btn" data-offer-id="${offer.id}">Négocier</button>
            <button class="deal-action decline-btn" data-offer-id="${offer.id}">Refuser</button>
        </div>
    `;
    
    offersContainer.prepend(offerElement);
    
    // Ajouter les événements pour les boutons
    offerElement.querySelector('.accept-btn').onclick = () => acceptOffer(offer.id);
    offerElement.querySelector('.negotiate-btn').onclick = () => negotiateOffer(offer.id);
    offerElement.querySelector('.decline-btn').onclick = () => declineOffer(offer.id);
    
    // Notification pour alerter le joueur
    sendNotification({ 
        title: 'Nouvelle offre', 
        content: `Offre pour ${offer.quantity} ${offer.drugLabel}`,
        icon: 'fas fa-cannabis'
    });
}

// Fonction pour mettre à jour une offre après négociation
function updateOffer(offerId, newPrice, message) {
    const offerElement = document.getElementById(`offer-${offerId}`);
    
    if (offerElement) {
        // Mettre à jour le prix dans l'élément d'offre
        const detailsElement = offerElement.querySelector('.deal-offer-details');
        if (newPrice) {
            // Extraire le texte actuel et remplacer uniquement le prix
            const currentText = detailsElement.textContent;
            const updatedText = currentText.replace(/Prix: \$\d+/, `Prix: $${newPrice}`);
            detailsElement.textContent = updatedText;
        }
        
        // Désactiver le bouton de négociation
        const negotiateBtn = offerElement.querySelector('.negotiate-btn');
        if (negotiateBtn) {
            negotiateBtn.disabled = true;
            negotiateBtn.classList.add('disabled');
            negotiateBtn.textContent = 'Déjà négocié';
        }
        
        // Si la négociation a été acceptée, mettre en évidence l'offre
        if (message === "Négociation acceptée") {
            offerElement.style.borderColor = 'rgba(46, 204, 113, 0.35)';
        } else if (message === "Négociation refusée") {
            offerElement.style.borderColor = 'rgba(231, 76, 60, 0.35)';
        }
        
        // Afficher une notification pour informer le joueur
        sendNotification({
            title: 'Résultat de négociation',
            content: message,
            icon: message.includes('acceptée') ? 'fas fa-check-circle' : 'fas fa-times-circle'
        });
    }
}

// Fonction pour accepter une offre
function acceptOffer(offerId) {
    fetchNui('acceptDealOffer', { offerId });
    removeOffer(offerId);
}

// Fonction pour négocier une offre
function negotiateOffer(offerId) {
    // Afficher un popup pour entrer un nouveau prix
    let newPrice = null;
    setPopUp({
        title: 'Négocier le prix',
        description: 'Proposez un nouveau prix',
        input: {
            type: 'input',
            placeholder: 'Nouveau prix',
            value: '',
            inputType: 'number',
            onChange: (value) => {
                console.log(value);
                if (value && !isNaN(value)) {
                    newPrice = value;
                }
            }
        },
        buttons: [
            {
                title: 'Annuler',
                color: 'red'
            },
            {
                title: 'Proposer',
                color: 'blue',
                cb: () => {
                    console.log(newPrice);
                    if (newPrice && !isNaN(newPrice)) {
                        fetchNui('negotiateDealOffer', { offerId, newPrice: parseInt(newPrice) });
                    };
                }
            }
        ]
    });
}

// Fonction pour refuser une offre
function declineOffer(offerId) {
    fetchNui('declineDealOffer', { offerId });
    removeOffer(offerId);
}

// Fonction pour supprimer une offre de l'interface
function removeOffer(offerId) {
    const offerElement = document.getElementById(`offer-${offerId}`);
    if (offerElement) {
        offerElement.remove();
    }
}

    // Vérifier la disponibilité des drogues
    drugsList.forEach(drug => {
        fetchNui('checkDrugAvailability', { drugId: drug.id, itemName: drug.item });
    });
    
    // Ajouter les événements pour les checkboxes
    document.querySelectorAll('.drug-checkbox').forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            const drugId = this.dataset.id;
            const drugItem = this.dataset.item;
            
            if (this.checked) {
                if (!selectedDrugs.includes(drugId)) {
                    selectedDrugs.push(drugId);
                }
            } else {
                selectedDrugs = selectedDrugs.filter(id => id !== drugId);
            }
        });
    });
    
    // Ajouter l'événement pour le bouton de recherche d'acheteurs
    document.getElementById('start-dealing').onclick = () => {
        if (selectedDrugs.length === 0) {
            sendNotification({ 
                title: 'Erreur', 
                content: 'Sélectionnez au moins un produit',
                icon: 'fas fa-exclamation-triangle'
            });
            return;
        }
        
        fetchNui('startDealing', { selectedDrugs }).then(response => {
            if (response && response.success) {
                // Cacher le bouton de recherche et afficher le bouton d'annulation
                document.getElementById('start-dealing').style.display = 'none';
                document.getElementById('stop-dealing').style.display = 'block';
            }
        });
    };
    
    // Ajouter l'événement pour le bouton d'annulation de recherche
    document.getElementById('stop-dealing').onclick = () => {
        fetchNui('stopDealing', {}).then(response => {
            if (response && response.success) {
                // Afficher le bouton de recherche et cacher le bouton d'annulation
                document.getElementById('start-dealing').style.display = 'block';
                document.getElementById('stop-dealing').style.display = 'none';
                
                // Vider la liste des offres
                document.getElementById('deal-offers').innerHTML = '';
            }
        });
    };

// Gérer les changements de thème
onSettingsChange((settings) => {
    let theme = settings.display.theme;
    document.getElementsByClassName('app')[0].dataset.theme = theme;
});

getSettings().then((settings) => {
    let theme = settings.display.theme;
    document.getElementsByClassName('app')[0].dataset.theme = theme;
});
