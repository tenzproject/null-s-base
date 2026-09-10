Config.DriveSchool = {}

Config.DriveSchool.Locations = {
    vector3(215.5863, -1398.6481, 30.5835)
}

Config.DriveSchool.SpeedMultiplier = 3.6 -- 3.6 for km/h, 2.236936 for mph
Config.DriveSchool.MaxErrors = 3
Config.DriveSchool.MinTheoryScore = 5

-- Brand de l'auto-école (configurable côté UI)
-- accentColor : couleur principale (boutons, indicateurs, accents)
-- bgColor     : couleur de fond du brand hero (sidebar)
-- logo        : chemin relatif dans null-cache/images/
-- name        : nom affiché en grand
-- tagline     : sous-titre court
Config.DriveSchool.Brand = {
    name = 'Auto-École',
    tagline = 'Permis de conduire officiels',
    logo = 'shopui/brands/driving-school.png',
    accentColor = '#c62828',
    bgColor = '#1E1E1E',
    bgIsLight = false,
}

Config.DriveSchool.License = {
    {
        label = 'Permis A',
        id = 'drive_bike',
        description = 'Deux-roues motorisés',
        icon = 'bike',
        pricing = {
            theory = 3000,
            practice = 4000
        },
        vehicle = {
            model = 'faggio',
            coords = vector3(231.2591, -1392.982, 30.50785),
            heading = 144.40260314941,
            plate = "DMV1"
        }
    },
    {
        label = 'Permis B',
        id = 'drive',
        description = 'Véhicules légers',
        icon = 'car',
        pricing = {
            theory = 3000,
            practice = 4000
        },
        vehicle = {
            model = 'blista',
            coords = vector3(231.2591, -1392.982, 30.50785),
            heading = 144.40260314941,
            plate = "DMV1"
        }
    },
    {
        label = 'Permis C',
        id = 'drive_truck',
        description = 'Poids lourds',
        icon = 'truck',
        pricing = {
            theory = 3000,
            practice = 4000
        },
        vehicle = {
            model = 'pounder',
            coords = vector3(231.2591, -1392.982, 30.50785),
            heading = 144.40260314941,
            plate = "DMV1"
        }
    }
}

Config.DriveSchool.PracticeCoords = {
    {
        { coordinate = vector3(227.1181, -1399.691, 30.1), speedLimit = 50 },
        { coordinate = vector3(183.7479, -1394.595, 29.05295), speedLimit = 50 },
        { coordinate = vector3(210.3608, -1327.127, 29.16619), speedLimit = 50 },
        { coordinate = vector3(217.6466, -1145.248, 29.3349), speedLimit = 50 },
        { coordinate = vector3(83.13854, -1136.699, 29.15778), speedLimit = 50 },
        { coordinate = vector3(55.52874, -1248.127, 29.34311), speedLimit = 50 },
        { coordinate = vector3(82.69904, -1338.678, 29.3447), speedLimit = 50 },
        { coordinate = vector3(131.4893, -1387.581, 29.28993), speedLimit = 50 },
        { coordinate = vector3(220.603, -1445.61, 29.24681), speedLimit = 50 },
        { coordinate = vector3(242.2584, -1536.136, 29.24705), speedLimit = 50 },
        { coordinate = vector3(301.6448, -1523.68, 29.34156), speedLimit = 50 },
        { coordinate = vector3(256.1726, -1445.458, 29.24207), speedLimit = 50 },
        { coordinate = vector3(233.427, -1397.215, 30.5071), speedLimit = 50 },
    }
}

Config.DriveSchool.Questions = {
    {
        label = "Que signifie un feu rouge clignotant à un carrefour?",
        options = {
            { label = "Ralentir et continuer si aucun véhicule n'arrive", correct = false },
            { label = "S'arrêter complètement, puis continuer si c'est sûr", correct = true },
            { label = "Ignorer le feu rouge s'il n'y a personne", correct = false }
        }
    },
    {
        label = "Quelle est la limite de vitesse standard en zone résidentielle?",
        options = {
            { label = "35 mph (environ 56 km/h)", correct = false },
            { label = "15 mph (environ 24 km/h)", correct = false },
            { label = "25 mph (environ 40 km/h)", correct = true }
        }
    },
    {
        label = "Que faire en présence d'un bus scolaire avec les feux clignotants rouges activés?",
        options = {
            { label = "Continuer si vous êtes sur une route à plusieurs voies", correct = false },
            { label = "S'arrêter complètement, dans les deux directions de circulation", correct = true },
            { label = "Ralentir et dépasser si aucun enfant ne traverse", correct = false }
        }
    },
    {
        label = "Comment réagir à un panneau stop octogonal rouge?",
        options = {
            { label = "S'arrêter complètement avant la ligne de stop", correct = true },
            { label = "Ralentir mais ne pas s'arrêter complètement", correct = false },
            { label = "S'arrêter uniquement si d'autres véhicules approchent", correct = false }
        }
    },
    {
        label = "Quelle est la limite légale d'alcoolémie pour les conducteurs?",
        options = {
            { label = "0,05% pour tous les conducteurs", correct = false },
            { label = "0,10% pour les conducteurs expérimentés", correct = false },
            { label = "0,08% pour les conducteurs adultes", correct = true }
        }
    },
    {
        label = "Que signifie un panneau jaune avec une flèche en zigzag?",
        options = {
            { label = "Intersection avec priorité, accélérez", correct = false },
            { label = "Zone de travaux, suivez la déviation", correct = false },
            { label = "Virage dangereux à venir, ralentissez", correct = true }
        }
    },
    {
        label = "Comment réagir en présence d'un panneau « Yield »?",
        options = {
            { label = "S'arrêter complètement, même si la route est dégagée", correct = false },
            { label = "Cédez le passage aux véhicules sur la route principale", correct = true },
            { label = "Accélérer pour rejoindre la circulation", correct = false }
        }
    },
    {
        label = "Quelle est la vitesse maximale autorisée sur une autoroute?",
        options = {
            { label = "65 mph (environ 105 km/h), sauf indication contraire", correct = true },
            { label = "75 mph (environ 120 km/h)", correct = false },
            { label = "55 mph (environ 88 km/h)", correct = false }
        }
    },
    {
        label = "Que faire si vous voyez un panneau indiquant « Pedestrian Crossing »?",
        options = {
            { label = "Ralentir et être prêt à s'arrêter pour les piétons", correct = true },
            { label = "Accélérer pour dégager rapidement la zone", correct = false },
            { label = "Ignorer le panneau si aucun piéton n'est visible", correct = false }
        }
    },
    {
        label = "Que faire si vous entendez une sirène de véhicule d'urgence?",
        options = {
            { label = "Continuer à rouler jusqu'à ce que vous trouviez un feu rouge", correct = false },
            { label = "Accélérer pour ne pas gêner le véhicule d'urgence", correct = false },
            { label = "Se ranger sur le bord de la route et laisser passer le véhicule", correct = true }
        }
    }
}
