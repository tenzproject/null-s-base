/**
 * Loading Screen Config
 * ----------------------
 * Tout le contenu modifiable du loading screen est ici.
 * Modifie librement: nom, accent, patch notes, équipe, galerie, musiques, etc.
 */
window.LOADING_CONFIG = {
    // Couleur d'accent par défaut (peut être override par le convar `hexcolor` côté Lua)
    accent: '#7C3AED',

    // Identité serveur (peut être override par les convars `serverName` / `serverCHAR`)
    serverName: 'Null\'s V1',
    serverSubtitle: 'ROLEPLAY SERIOUS',
    serverLogo: 'img/logo.png',
    // Bannière par défaut (override par `backgroundBanner` / `bannerUrl` côté serveur)
    backgroundBanner: 'img/background.png',

    // Astuce affichée au-dessus de la barre de progression
    tip: 'Astuce: Rejoignez le Discord pour suivre les mises à jour et le règlement.',

    // Réseaux sociaux (footer)
    socials: [
        { icon: 'fa-brands fa-discord', label: 'discord.gg/null' },
        { icon: 'fa-brands fa-tiktok',  label: '@Nullfr' },
    ],

    // Playlist musicale (chemins relatifs au dossier html/)
    music: [
        { label: 'AMIRI JEANS X NEW JAZZ (remix)', author: 'Püsshi', src: 'audio/amiri.mp3' },
        { label: 'LIFE X AFTER THE STORM (remix)', author: 'Püsshi', src: 'audio/life.mp3' },
        { label: 'TNF X OVER (remix)',             author: 'Püsshi', src: 'audio/tnf.mp3' },
        { label: 'Macarena Remix',                 author: 'JRK19',  src: 'audio/JRK19Macarena.mp3' },
    ],

    // Panneau "Voir plus" (bouton en haut à droite)
    panel: {
        enabled: true,
        title: 'Centre d\'information',
        subtitle: 'Patchnotes • Équipe • Galerie',

        // Onglet "Patch Notes"
        patchnotes: [
            {
                version: '4.0.40',
                date: '26/04/2026',
                tag: 'MAJEUR',
                title: 'Refonte du loading screen',
                changes: [
                    { type: 'added',   text: 'Nouveau panneau d\'informations avec patch notes, équipe et galerie' },
                    { type: 'changed', text: 'Transition caméra optimisée entre l\'enter phase et le spawn' },
                    { type: 'changed', text: 'Style enter phase aligné avec l\'identité visuelle Null' },
                    { type: 'fixed',   text: 'Suppression des effets de blur incompatibles avec le jeu' },
                ],
            },
            {
                version: '4.0.39',
                date: '20/04/2026',
                tag: 'CORRECTIFS',
                title: 'Stabilité serveur',
                changes: [
                    { type: 'fixed', text: 'Correction des freezes lors du chargement initial' },
                    { type: 'fixed', text: 'Correction d\'un bug d\'inventaire lors de la déconnexion' },
                ],
            },
        ],

        // Onglet "Équipe"
        team: [
            {
                role: 'Fondateur',
                name: 'Null',
                avatar: 'img/logo.png',
                description: 'Fondateur et lead développeur du projet.',
                badge: 'FOUNDER',
            },
            {
                role: 'Développeur',
                name: 'DevName',
                avatar: 'img/logo.png',
                description: 'Développeur scripts & UI. Spécialiste front-end.',
                badge: 'DEV',
            },
            {
                role: 'Game Master',
                name: 'StaffName',
                avatar: 'img/logo.png',
                description: 'Animation & événements RP.',
                badge: 'STAFF',
            },
        ],

        // Onglet "Galerie" — défilement automatique horizontal
        gallery: [
            { src: 'img/background.png', caption: 'Los Santos by night' },
            { src: 'img/background.png', caption: 'Vinewood' },
            { src: 'img/background.png', caption: 'Sandy Shores' },
            { src: 'img/background.png', caption: 'Paleto Bay' },
            { src: 'img/background.png', caption: 'Grove Street' },
        ],
        galleryAutoScrollSpeed: 35, // pixels/seconde, 0 = désactivé
    },
};
