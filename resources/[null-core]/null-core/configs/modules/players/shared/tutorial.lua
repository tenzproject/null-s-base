-- ============================================================================
-- TUTORIAL SYSTEM - Configuration
-- All coordinates are configurable - modify as needed for your server
-- ============================================================================

Config.Tutorial = {
    enabled = true,

    -- ============================================================================
    -- BMX ITEM (Usable item that spawns a BMX for the player)
    -- ============================================================================
    bmx = {
        itemName = 'bmx',           -- Nom de l'item dans la DB
        model = 'bmx',                        -- Modèle du véhicule à spawn
        spawnOffset = vector3(0.0, 2.0, 0.0), -- Offset par rapport au joueur pour le spawn
    },

    -- ============================================================================
    -- AUTO-ECOLE (Driving school destination)
    -- ============================================================================
    driveschool = {
        coords = vector3(237.7559, -1411.3409, 30.5857),
        label = "l'auto-école",
        arrivalRadius = 20.0,
    },

    -- ============================================================================
    -- VEHICLE PICKUP (PED + interaction pour récupérer le véhicule gratuit)
    -- ============================================================================
    vehiclePickup = {
        -- PED d'interaction
        pedModel = 's_m_m_autoshop_02',
        pedCoords = vector4(186.1276, -1481.3079, 29.1421, 51.5848),
        pedScenario = 'WORLD_HUMAN_CLIPBOARD',
        interactionText = 'Récupérer votre véhicule',
        interactionKey = 'E',
        interactionDistance = 8.0,
        
        -- Véhicule gratuit (donné au joueur, enregistré dans son garage)
        vehicleModel = 'blista',
        
        -- Positions de spawn du véhicule (sélection aléatoire pour éviter collisions)
        spawnPositions = {
            vector4(202.9231, -1470.0177, 29.1412, 38.3326),
            vector4(208.6016, -1465.9910, 29.1624, 45.8955),
        },
    },

    -- ============================================================================
    -- MAGASIN DE VETEMENTS (Clothing store)
    -- ============================================================================
    clothingStore = {
        coords = vector3(-817.896545, -1095.107300, 10.926220),
        label = "le magasin de vêtements",
        arrivalRadius = 20.0,
        continueKey = 47, -- F key (control ID)
        continueKeyLabel = '~INPUT_DETONATE~', -- Label GTA pour la touche F
    },

    -- ============================================================================
    -- POLE EMPLOI (Job center)
    -- ============================================================================
    jobCenter = {
        coords = nil, -- Auto-resolved from Config.FreeJobs.Agence.InteractionCoords
        label = "le pôle emploi",
        arrivalRadius = 20.0,
        -- Jobs proposés dans la tablette
        jobs = {
            { name = "Bûcheron", description = "Coupez du bois et vendez-le. Un travail physique mais bien payé." },
            { name = "Pêcheur", description = "Pêchez des poissons et revendez-les au marché." },
            { name = "Nettoyeur de piscine", description = "Nettoyez les piscines des habitants. Simple et efficace." },
        },
    },

    -- ============================================================================
    -- TEXTES ET MESSAGES (Configurables)
    -- ============================================================================
    messages = {
        bmxGiven = '~b~Tutoriel~s~~n~Vous avez reçu un BMX ! Utilisez-le depuis votre inventaire pour vous déplacer.',
        gotoDriveschool = '~b~Tutoriel~s~~n~Rendez-vous à l\'auto-école marquée sur votre GPS avec votre BMX !',
        gotoVehiclePickup = '~b~Tutoriel~s~~n~Rendez-vous au point GPS pour récupérer votre véhicule gratuit !',
        vehicleReceived = '~g~Véhicule reçu !~s~~n~Il est maintenant dans votre garage. Rendez-vous au magasin de vêtements.',
        gotoClothing = '~b~Tutoriel~s~~n~Rendez-vous au magasin de vêtements marqué sur votre GPS.',
        clothingContinue = '~b~Tutoriel~s~ - Appuyez sur ~INPUT_DETONATE~ pour passer à la prochaine étape',
        gotoJobCenter = '~b~Tutoriel~s~~n~Rendez-vous au pôle emploi marqué sur votre GPS.',
        tutorialComplete = '~g~Félicitations !~s~~n~Vous avez terminé le tutoriel. Bon jeu sur le serveur !',
    },

    -- ============================================================================
    -- MISC SETTINGS
    -- ============================================================================
    discordLink = "discord.gg/null",
}
