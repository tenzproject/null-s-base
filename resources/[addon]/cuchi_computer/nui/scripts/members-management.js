// Variables globales pour la gestion des membres
let currentMembersData = {};
let currentMembersLabId = null;
let currentMembersLabType = null;
let pendingRefreshMembers = false;

// Définition des permissions disponibles
const availablePermissions = {
    global: [
        { id: "access_lab", label: "Accéder au labo" },
        { id: "access_safe", label: "Accéder au coffre privé" },
        { id: "access_storage", label: "Accéder au stockage" },
        { id: "access_camera", label: "Accéder aux caméras" },
        { id: "access_dealer", label: "Accéder au Dealer" }
    ],
    weed: [
        { id: "harvest_weed", label: "Récolter la weed" },
        { id: "process_weed", label: "Traiter la weed" }
    ],
    meth: [
        { id: "mix_meth", label: "Mixer la Meth" },
        { id: "break_meth", label: "Casser la Meth" },
        { id: "process_meth", label: "Mettre au fourneaux la Meth" }
    ]
};

function refreshMembers() {
    console.log('Attempting to refresh members...');
    const container = document.getElementById('members-management-list');
    const inviteForm = document.getElementById('members-management-invite');
    
    if (!container || !inviteForm) {
        console.log('Container or invite form not found, setting pending refresh');
        pendingRefreshMembers = true;
        return;
    }
    
    console.log('Container found, refreshing members');
    pendingRefreshMembers = false;
    
    // Afficher le formulaire d'invitation
    inviteForm.innerHTML = `
        <h2>Inviter un nouveau membre</h2>
        <div class="invite-form">
            <input type="text" id="invite-id" placeholder="ID unique du joueur" />
            <button class="member-button invite" onclick="inviteMember()">Inviter</button>
        </div>
    `;
    
    // Afficher la liste des membres
    container.innerHTML = '';
    
    // Si aucun membre n'est présent, afficher un message
    if (Object.keys(currentMembersData).length === 0) {
        container.innerHTML = '<div class="no-members">Aucun membre dans ce laboratoire. Invitez des membres pour qu\'ils puissent accéder au laboratoire.</div>';
        return;
    }
    
    // Afficher chaque membre
    for (const [id, member] of Object.entries(currentMembersData)) {
        container.appendChild(createMemberElement(member.idunique, member));
    }
}

function createMemberElement(id, member) {
    const div = document.createElement('div');
    div.className = 'member-item';
    
    // Convertir l'ID en nombre si ce n'est pas déjà le cas
    const memberId = typeof id === 'string' ? parseInt(id) : id;
    console.log(memberId, id);
    // Créer l'en-tête avec le nom et l'ID du membre
    let headerHTML = `
        <div class="member-header">
            <div class="member-info">
                <span class="member-name">${member.name || 'Membre'}</span>
                <span class="member-id">(ID: ${memberId})</span>
            </div>
            <div class="member-actions">
                <button class="member-button remove" onclick="removeMember(${memberId})">Retirer</button>
            </div>
        </div>
    `;
    
    // Créer les permissions globales
    let permissionsHTML = '<div class="member-permissions">';
    
    // Ajouter les permissions globales
    permissionsHTML += '<div class="permissions-section"><h3>Permissions générales</h3>';
    for (const perm of availablePermissions.global) {
        const isChecked = member.permissions && member.permissions.includes(perm.id);
        permissionsHTML += `
            <div class="permission-item">
                <label>
                    <input type="checkbox" data-member-id="${memberId}" data-permission="${perm.id}" ${isChecked ? 'checked' : ''} onchange="updatePermission(this)">
                    ${perm.label}
                </label>
            </div>
        `;
    }
    permissionsHTML += '</div>';
    
    // Ajouter les permissions spécifiques au type de laboratoire si c'est un labo de weed
    if (currentMembersLabType === 'weed') {
        permissionsHTML += '<div class="permissions-section"><h3>Permissions spécifiques (Weed)</h3>';
        for (const perm of availablePermissions.weed) {
            const isChecked = member.permissions && member.permissions.includes(perm.id);
            permissionsHTML += `
                <div class="permission-item">
                    <label>
                        <input type="checkbox" data-member-id="${memberId}" data-permission="${perm.id}" ${isChecked ? 'checked' : ''} onchange="updatePermission(this)">
                        ${perm.label}
                    </label>
                </div>
            `;
        }
        permissionsHTML += '</div>';
    }
    
    permissionsHTML += '</div>';
    
    // Assembler le tout
    div.innerHTML = headerHTML + permissionsHTML;
    
    return div;
}

function inviteMember() {
    const idInput = document.getElementById('invite-id');
    const memberId = parseInt(idInput.value.trim());
    
    if (isNaN(memberId) || memberId < 0) {
        MessageBox("error", "Erreur", "Veuillez entrer un ID valide (nombre positif).");
        return;
    }
    
    const loader = document.getElementById('members-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/inviteMember`, {
        method: 'POST',
        body: JSON.stringify({
            memberId: memberId,
            laboratory: currentMembersLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Ajouter le nouveau membre à la liste
            if (!currentMembersData[memberId]) {
                currentMembersData[memberId] = {
                    name: data.memberName || 'Membre',
                    permissions: ['access_lab'] // Permission de base
                };
            }
            refreshMembers();
            MessageBox("info", "Succès", "Membre invité avec succès!");
            idInput.value = ''; // Réinitialiser le champ
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible d'inviter ce membre.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors de l'invitation.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

function removeMember(memberId) {
    // S'assurer que memberId est un nombre
    memberId = typeof memberId === 'string' ? parseInt(memberId) : memberId;
    
    if (isNaN(memberId)) {
        console.error("ID de membre invalide");
        return;
    }

    const loader = document.getElementById('members-management-loader');
    if (loader) loader.style.display = 'block';
    
    fetch(`https://${GetParentResourceName()}/removeMember`, {
        method: 'POST',
        body: JSON.stringify({
            memberId: memberId,
            laboratory: currentMembersLabId
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Supprimer le membre de la liste
            // Rechercher le membre par son ID unique
            for (const [key, member] of Object.entries(currentMembersData)) {
                if (member.idunique === memberId) {
                    delete currentMembersData[key];
                    break;
                }
            }
            refreshMembers();
            MessageBox("info", "Succès", "Membre retiré avec succès!");
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de retirer ce membre.");
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors du retrait du membre.");
        console.error(error);
    })
    .finally(() => {
        if (loader) loader.style.display = 'none';
    });
}

function updatePermission(checkbox) {
    let memberId = checkbox.dataset.memberId;
    const permission = checkbox.dataset.permission;
    const isChecked = checkbox.checked;
    
    // Convertir l'ID en nombre
    memberId = parseInt(memberId);
    
    if (isNaN(memberId) || !permission) {
        console.error("Données de permission invalides");
        return;
    }
    
    // Vérifier si le membre existe dans currentMembersData
    // Rechercher le membre par son ID unique
    let memberKey = null;
    for (const [key, member] of Object.entries(currentMembersData)) {
        if (member.idunique === memberId) {
            memberKey = key;
            break;
        }
    }
    
    if (!memberKey) {
        console.error(`Membre avec ID ${memberId} introuvable`);
        return;
    }
    
    // Mettre à jour localement d'abord
    if (!currentMembersData[memberKey].permissions) {
        currentMembersData[memberKey].permissions = [];
    }
    
    if (isChecked && !currentMembersData[memberKey].permissions.includes(permission)) {
        currentMembersData[memberKey].permissions.push(permission);
    } else if (!isChecked && currentMembersData[memberKey].permissions.includes(permission)) {
        currentMembersData[memberKey].permissions = currentMembersData[memberKey].permissions.filter(p => p !== permission);
    }
    
    // Envoyer la mise à jour au serveur
    fetch(`https://${GetParentResourceName()}/updateMemberPermissions`, {
        method: 'POST',
        body: JSON.stringify({
            memberId: memberId,
            laboratory: currentMembersLabId,
            permissions: currentMembersData[memberKey].permissions
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log(`Permission ${permission} mise à jour pour ${memberId}`);
        } else {
            MessageBox("error", "Erreur", data.message || "Impossible de mettre à jour les permissions.");
            // Annuler le changement local si le serveur échoue
            refreshMembers();
        }
    })
    .catch(error => {
        MessageBox("error", "Erreur", "Une erreur est survenue lors de la mise à jour des permissions.");
        console.error(error);
        // Annuler le changement local si le serveur échoue
        refreshMembers();
    });
}

function checkPendingRefreshMembers() {
    if (pendingRefreshMembers) {
        console.log('Checking pending refresh for members...');
        refreshMembers();
    }
}

// Vérifier périodiquement s'il y a un rafraîchissement en attente
setInterval(checkPendingRefreshMembers, 100);

// Initialisation quand l'application est ouverte
window.addEventListener('message', (event) => {
    if (event.data.type === 'show') {
        console.log('Members Management: Received show event:', event.data);
        
        
        if (event.data.laboratory && event.data.laboratory.id) {
            console.log('Members Management: Laboratory data:', event.data.laboratory);
            currentMembersData = event.data.laboratory.members || {};
            currentMembersLabId = event.data.laboratory.id;
            currentMembersLabType = event.data.laboratory.type || null;
            console.log(JSON.stringify(currentMembersData));
            // Attendre que le bureau soit initialisé avant de rafraîchir
            window.addEventListener('desktopInitialized', () => {
                console.log('Members Management: Desktop initialized, refreshing members');
                setTimeout(refreshMembers, 0);
            }, { once: true });
        }
    }
});
