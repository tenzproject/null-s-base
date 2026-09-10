Config.Society = {}

Config.Society.Politique = {
    ["Politique de conservation de l'environnement"] = {
        type = "All", 
        default = false, 
        description = "Obligation pour les entreprises et les particuliers de réduire leur empreinte écologique, en réduisant les émissions de gaz et la gestion des déchets."
    },


    ["Politique de vérification"] = {
        type = "Mécano", 
        default = false, 
        description = "Demander une vérification du propriétaire pour modifier un véhicule."
    },
    
    ["Politique de Licence de Vente d'Alcool"] = {
        type = {"Bars", "Restaurant"}, 
        default = false, 
        description = "Obligation pour tous les bars et restaurants de détenir une licence valide pour vendre de l'alcool. Cette licence peut être renouvelée annuellement, et la vente d’alcool sans licence entraîne des sanctions sévères."
    },
    
    ["Politique de Licence de Musique Live et Événements"] = {
        type = {"Bars", "Restaurant"}, 
        default = false, 
        description = "Obligation d'obtenir une licence spécifique pour organiser des événements musicaux ou autres spectacles en direct dans les bars et restaurants. Cette licence garantit que l’établissement respecte les normes sonores et de sécurité."
    },

    ["Politique d’arrestation"] = {
        type = "Police", 
        default = true, 
        description = "Obligation de lire les droits du suspect avant toute mise en garde à vue."
    },
    ["Politique de sécurité publique"] = {
        type = "Police", 
        default = true, 
        description = "Mise en place d’un plan de prévention contre le crime dans les zones à risque."
    },
    ["Politique de gestion des armes"] = {
        type = "Police", 
        default = true, 
        description = "Régulation stricte sur la possession et l’utilisation d'armes à feu en ville. Chaque citoyen ou organisation doit suivre un processus de vérification et de formation avant d'obtenir un permis."
    },
    ["Politique de distribution des armes"] = {
        type = "Police", 
        default = true, 
        description = "Mise en place de règles strictes sur la distribution d'armes à feu au sein des forces de police. Les armes doivent être attribuées sur la base des besoins spécifiques, avec un contrôle des stocks et des inspections régulières."
    },
    ["Politique de contrôle des excès de force"] = {
        type = "Police", 
        default = true, 
        description = "Obligation de filmer toutes les interventions de la police lors de contrôles ou d'arrestations. Les excès de force seront examinés par une commission indépendante."
    },

    ["Politique de priorité"] = {
        type = "Ambulance", 
        default = false, 
        description = "Les patients en état critique sont pris en charge en premier."
    },

    ["Politique de transparence"] = {
        type = "Gouvernement", 
        default = true, 
        description = "Obligation de rendre publics les budgets et décisions importantes."
    },
    ["Politique d'égalité des chances"] = {
        type = "Gouvernement", 
        default = true, 
        description = "Mise en place de lois visant à garantir l'égalité de traitement pour toutes les citoyennes et tous les citoyens, quelle que soit leur origine."
    },
    ["Politique de couverture des événements majeurs"] = {
        type = "Gouvernement", 
        default = true, 
        description = "Obligation pour les autorités de couvrir et de fournir des informations sur tous les événements majeurs ou les crises qui affectent la ville."
    },
}

Config.Society.Blanchiment = {
    pourcentage = 75, -- il rend 75%
    delai = 10 -- delai entre chaque blanchiment
}

Config.Society.Economy = {
    Salary = {
        ["Mensuel"] = {
            min = 900,
            max = 7500,
        },
        ["Pour 30 Min"] = {
            min = 0,
            max = 50,
        },
    }
}