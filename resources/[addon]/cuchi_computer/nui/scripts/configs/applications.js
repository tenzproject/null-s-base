/*
 * ⚠️ WARNING ⚠️
 * Modifying this code without 
 * proper knowledge can result 
 * in its failure. 
 * 
 * Handle with care to avoid breaking it.
*/

const Applications = {
    "code": {
        usable: false
    },
    "console": {
        usable: true,
        width: 640,
        height: 420,
        appCode: `
<div id="app-console" class="application">
    <h1 id="app-console-title"><button id="console-quit" class="app-exit"></button><button id="console-minimize" class="app-minimize"></button>Command Prompt</h1>
    <div id="console-text"></div>
</div>`
    },
    "addresses": {
        usable: true,
        appCode: `
<div id="app-addresses" class="application">
    <h1 id="app-addresses-title"><button id="addresses-quit" class="app-exit"></button><button id="addresses-minimize" class="app-minimize"></button>Addresses</h1>
    <p id="addresses-description">Description .... some warning before accessing address</p>
    <div id="addresses-container">
    </div>
</div>`
    },
    "informations": {
        usable: true,
        appCode: `
<div id="app-informations" class="application">
    <h1 id="app-informations-title"><button id="informations-quit" class="app-exit"></button><button id="informations-minimize" class="app-minimize"></button>Informations</h1>
    <div id="informations-text"></div>
</div>`
    },
    "market": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-market" class="application">
    <h1 id="app-market-title"><button id="market-quit" class="app-exit"></button><button id="market-minimize" class="app-minimize"></button>Market</h1>
    <div id="market-wrapper">
        <div id="market-top">
            <h1>Market</h1>
            <p id="market-description"></p>
            <div id="market-actions">
                <button class="market-btn" id="market-create">Create</button>
                <button class="market-btn" id="market-delete">Delete</button>
                <button class="market-btn" id="market-refresh">Refresh</button>
            </div>
        </div>
        <div id="market-creation">
            <input id="market-creation-title" placeholder="Title" type="text" maxlength="16">
            <input id="market-creation-desc" placeholder="Description" type="text" maxlength="512">
            <div>
                <button class="market-btn" id="market-creation-post">Post</button>
                <button class="market-btn" id="market-creation-cancel">Cancel</button>
            </div>
            <div id="market-loader"></div>
        </div>
        <div id="market-deletion">
            <input id="market-deletion-id" placeholder="ID" type="number" min="1" max="2000000000">
            <div>
                <button class="market-btn" id="market-deletion-delete">Delete</button>
                <button class="market-btn" id="market-deletion-cancel">Cancel</button>
            </div>
        </div>
        <div id="market-container"></div>
    </div>
</div>`
    },
    "themes": {
        usable: true,
        width: 500,
        height: 600,
        appCode: `
<div id="app-themes" class="application">
    <h1 id="app-themes-title"><button id="themes-quit" class="app-exit"></button><button id="themes-minimize" class="app-minimize"></button>Themes</h1>
    <div id="themes-wrapper">
        <div class="themes-section">
            <h2>Color Themes</h2>
            <div id="themes-container"></div>
        </div>
        <div class="themes-section">
            <h2>Wallpapers</h2>
            <div id="wallpapers-container"></div>
        </div>
    </div>
</div>`
    },
    "mail": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-mail" class="application">
    <h1 id="app-mail-title"><button id="mail-quit" class="app-exit"></button><button id="mail-minimize" class="app-minimize"></button>Mail</h1>
    <div id="mail-connection">
        <h1 id="mail-connection-title">Sign in</h1>
        <p id="mail-connection-info"></p>
        <input id="mail-connection-username" placeholder="Username" type="text" maxlength="16">
        <input id="mail-connection-password" placeholder="Password" type="password" maxlength="32">
        <label id="mail-connection-checkbox">
            <input id="mail-connection-save" type="checkbox"><span id="mail-checkbox-text">Save inputs for next time.</span>
        </label>
        <div class="mail-connection-actions">
            <button id="mail-connection-signin">Sign in</button>
            <button id="mail-connection-signup">No account? Sign up</button>
        </div>
    </div>
    <div id="mail-signup">
        <h1 id="mail-signup-title">Sign up</h1>
        <p id="mail-signup-error"></p>
        <input id="mail-signup-username" placeholder="Username" type="text" maxlength="16">
        <p id="mail-signup-preview">You mail address will be: </p>
        <input id="mail-signup-password" placeholder="Password" type="password" maxlength="32">
        <input id="mail-signup-password-confirmation" placeholder="Confirm Password" type="password" maxlength="32">
        <p id="mail-signup-warning">WARNING: Don't put a real password!</p>
        <div class="mail-connection-actions">
            <button id="mail-signup-signup">Sign up</button>
            <button id="mail-signup-signin">Already have an account? Sign in</button>
        </div>
    </div>
    <div id="mail-loader"></div>
    <div id="mail-wrapper">
        <div id="mail-top">
            <h1 id="mail-indication">mail@mail.com</h1>
            <div>
                <button id="mail-create">New mail</button>
                <button id="mail-refresh">Refresh</button>
                <button id="mail-signout">Disconnect</button>
            </div>
        </div>
        <div id="mail-container">

        </div>
        <div id="mail-reader">
            <h1 id="mail-reader-object"></h1>
            <div id="mail-reader-container"></div>
            <button id="mail-reader-answer">ANSWER</button>
        </div>
        <div id="mail-creator">
            <input id="mail-creator-to" placeholder="mail@" type="text">
            <input id="mail-creator-object" placeholder="Mail object" type="text" maxlength="32">
            <textarea rows='10' data-min-rows='10' id="mail-creator-text" placeholder="Text..." maxlength="4096"></textarea>
            <button id="mail-creator-send">Send</button>
        </div>
    </div>
</div>`
    },
    "laboratory-upgrades": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-laboratory-upgrades" class="application">
    <h1 id="app-laboratory-upgrades-title"><button id="laboratory-upgrades-quit" class="app-exit"></button><button id="laboratory-upgrades-minimize" class="app-minimize"></button>Améliorations du Laboratoire</h1>
    <div id="laboratory-upgrades-loader"></div>
    <div id="laboratory-upgrades-wrapper">
        <div id="laboratory-upgrades-top">
            <h1>Gestion du Laboratoire</h1>
            <p>Gérez les améliorations de votre laboratoire</p>
        </div>
        <div id="laboratory-upgrades-upgrades">
            <!-- Les améliorations seront ajoutées ici dynamiquement -->
        </div>
    </div>
</div>`
    },
    "market-study": {
        usable: true,
        width: 900,
        height: 707,
        appCode: `
<div id="app-market-study" class="application">
    <h1 id="app-market-study-title"><button id="market-study-quit" class="app-exit"></button><button id="market-study-minimize" class="app-minimize"></button>Analyse du Marché</h1>
    <div id="market-study-wrapper">
        <div id="market-study-header">
            <div id="market-study-drug-selector">
                <label for="market-study-drug-select">Produit :</label>
                <select id="market-study-drug-select">
                    <option value="">Sélectionner un produit</option>
                </select>
            </div>
            <div id="market-study-stats-cards">
                <div class="market-stat-card">
                    <div class="stat-label">Prix Actuel</div>
                    <div class="stat-value" id="market-study-current-price">--$</div>
                </div>
                <div class="market-stat-card">
                    <div class="stat-label">Prix Moyen (7j)</div>
                    <div class="stat-value" id="market-study-avg-price">--$</div>
                </div>
                <div class="market-stat-card">
                    <div class="stat-label">Tendance</div>
                    <div class="stat-value" id="market-study-trend">--</div>
                </div>
            </div>
        </div>
        <div id="market-study-chart-container">
            <canvas id="market-study-chart"></canvas>
        </div>
        <div id="market-study-period-selector">
            <button class="period-btn active" data-period="7">7 jours</button>
            <button class="period-btn" data-period="14">14 jours</button>
            <button class="period-btn" data-period="30">30 jours</button>
        </div>
    </div>
</div>`
    },
    "addresses-content": {
        usable: true,
        appCode: `
<div id="app-addresses-content" class="application">
    <h1 id="app-addresses-content-title"><button id="addresses-content-quit" class="app-exit"></button><button id="addresses-content-minimize" class="app-minimize"></button><span id="addresses-addresse"></span></h1>
    <div id="addresses-content"></div>
</div>        
`
    },
    "security": {
        width: 1000,
        height: 600,
        usable: true,
        appCode: `
            <div id="app-security" class="application">
                <h1 id="app-security-title"><button id="security-quit" class="app-exit"></button><button id="security-minimize" class="app-minimize"></button>Caméras de Sécurité</h1>
                <div id="security-loader"></div>
                <div id="security-wrapper">
                        <div class="window-body">
                            <div class="security-tabs">
                                <button class="security-tab active" data-tab="enter">Entrées</button>
                                <button class="security-tab" data-tab="exit">Sorties</button>
                                <button class="security-tab" data-tab="treatment">Traitements</button>
                            </div>
                            <div class="security-filters">
                                <input type="text" id="security-search" placeholder="Rechercher...">
                                <select id="security-sort" class="security-sort">
                                    <option value="time-desc">Date (Plus récent)</option>
                                    <option value="time-asc">Date (Plus ancien)</option>
                                    <option value="name-asc">Nom (A-Z)</option>
                                    <option value="name-desc">Nom (Z-A)</option>
                                </select>
                            </div>
                            <div id="security-content" class="security-content">
                                <!-- Le contenu sera injecté ici -->
                            </div>
                            <div class="security-pagination">
                                <button id="security-prev-page">Précédent</button>
                                <span id="security-page-info">Page 1 sur 1</span>
                                <button id="security-next-page">Suivant</button>
                            </div>
                        </div>
            </div>
        `
    },
    "laboratory-furnishing": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-laboratory-furnishing" class="application">
    <h1 id="app-laboratory-furnishing-title"><button id="laboratory-furnishing-quit" class="app-exit"></button><button id="laboratory-furnishing-minimize" class="app-minimize"></button>Meublement du Laboratoire</h1>
    <div id="laboratory-furnishing-loader"></div>
    <div id="laboratory-furnishing-wrapper">
        <div id="laboratory-furnishing-top">
            <h1>Choisir le Type de Laboratoire</h1>
            <p>Sélectionnez le type de laboratoire que vous souhaitez installer</p>
        </div>
        <div id="laboratory-furnishing-types">
            <!-- Les types de laboratoire seront ajoutés ici dynamiquement -->
        </div>
    </div>
</div>`
    },
    "employees-management": {
        usable: true,
        width: 800,
        height: 800,
        appCode: `
<div id="app-employees-management" class="application">
    <h1 id="app-employees-management-title"><button id="employees-management-quit" class="app-exit"></button><button id="employees-management-minimize" class="app-minimize"></button>Gestion des Employés</h1>
    <div id="employees-management-loader"></div>
    <div id="employees-management-wrapper">
        <div id="employees-management-top">
            <h1>Recrutement et Gestion du Personnel</h1>
            <p>Embauchez des employés pour améliorer l'efficacité de votre laboratoire</p>
        </div>
        <div id="employees-management-list">
            <!-- Les employés seront ajoutés ici dynamiquement -->
        </div>
    </div>
</div>`
    },
    "members-management": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-members-management" class="application">
    <h1 id="app-members-management-title"><button id="members-management-quit" class="app-exit"></button><button id="members-management-minimize" class="app-minimize"></button>Gestion des Membres</h1>
    <div id="members-management-loader"></div>
    <div id="members-management-wrapper">
        <div id="members-management-top">
            <p>Invitez des membres et gérez leurs permissions d'accès</p>
        </div>
        <div id="members-management-invite">
            <!-- Le formulaire d'invitation sera ajouté ici dynamiquement -->
        </div>
        <div id="members-management-list">
            <!-- Les membres seront ajoutés ici dynamiquement -->
        </div>
    </div>
</div>`
    },
    "laboratory-management": {
        usable: true,
        width: 800,
        height: 600,
        appCode: `
<div id="app-laboratory-management" class="application">
    <h1 id="app-laboratory-management-title"><button id="laboratory-management-quit" class="app-exit"></button><button id="laboratory-management-minimize" class="app-minimize"></button>Gestion du Laboratoire</h1>
    <div id="laboratory-management-loader"></div>
    <div id="lab-management-wrapper">
        <div id="lab-management-info">
            <!-- Les informations du laboratoire seront ajoutées ici dynamiquement -->
        </div>
        <div id="lab-management-expenses">
            <!-- Les dépenses du laboratoire seront ajoutées ici dynamiquement -->
        </div>
        <div id="lab-management-billing">
            <!-- Les informations de facturation seront ajoutées ici dynamiquement -->
        </div>
        <div id="lab-management-transfer">
            <!-- L'option de transfert de propriété sera ajoutée ici dynamiquement -->
        </div>
    </div>
</div>`
    },
    "delivery-service": {
        usable: true,
        width: 1250,
        height: 600,
        appCode: `
<div id="app-delivery-service" class="application">
    <h1 id="app-delivery-service-title"><button id="delivery-service-quit" class="app-exit"></button><button id="delivery-service-minimize" class="app-minimize"></button>Service de Livraison</h1>
    <div id="delivery-service-loader" class="loader"></div>
    <div id="delivery-service-wrapper">
        <!-- Conteneur principal -->
        <div id="delivery-main-container">
            <!-- Liste des articles -->
            <div id="delivery-items-container">
                <div id="delivery-search-container">
                    <input type="text" id="delivery-search" placeholder="Rechercher un article...">
                    <button id="delivery-search-button" onclick="searchDeliveryItems()">
                        <i class="fas fa-search"></i> Rechercher
                    </button>
                </div>
                <div id="delivery-items-list">
                    <!-- Les articles seront ajoutés ici dynamiquement -->
                </div>
            </div>
            
            <!-- Panier -->
            <div id="delivery-cart-container">
                <h3 id="delivery-cart-title">Votre panier</h3>
                <div id="delivery-cart-items">
                    <!-- Les articles du panier seront ajoutés ici dynamiquement -->
                </div>
                <div id="delivery-cart-summary">
                    <!-- Le résumé du panier sera ajouté ici dynamiquement -->
                </div>
            </div>
        </div>
        
        <!-- Formulaire de commande -->
        <div id="delivery-checkout-container">
            <div class="delivery-checkout-header">
                <h2>Finaliser votre commande</h2>
                <button class="delivery-back-button" onclick="backToMain()">Retour</button>
            </div>
            <div id="delivery-order-summary">
                <!-- Le résumé de la commande sera ajouté ici dynamiquement -->
            </div>
            <div class="delivery-checkout-form">
                <div class="delivery-info-message">
                    <p>La livraison sera effectuée à votre laboratoire actuel.</p>
                    <p>Temps de livraison moyen : 20-90 minutes</p>
                </div>
                <div class="delivery-form-group">
                    <label for="delivery-note">Note pour le livreur (optionnel)</label>
                    <textarea id="delivery-note" placeholder="Instructions spéciales pour la livraison"></textarea>
                </div>
                <button class="delivery-place-order" onclick="placeOrder()">Passer la commande</button>
            </div>
        </div>
        
        <!-- Confirmation de commande -->
        <div id="delivery-confirmation-container">
            <div class="delivery-confirmation-header">
                <h2>Commande confirmée</h2>
                <button class="delivery-back-button" onclick="backToMain()">Retour à la boutique</button>
            </div>
            <div id="delivery-confirmation-message">
                <!-- Le message de confirmation sera ajouté ici dynamiquement -->
            </div>
        </div>
    </div>
</div>`
    },
};
