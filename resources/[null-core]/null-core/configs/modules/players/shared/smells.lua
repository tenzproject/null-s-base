Config.smells = {
    allSmells = {
        ["weed"] = {
            label = "Weed",
            canHide = true,
            description = "Votre odeur de Weed diminue avec le temps.",
            removePerMinute = 10, -- pourcentage perdu par minutes 
            ProgressColor = {R = 0, G = 241, B = 0, A = 200},
            ProgressBackgroundColor = {R = 0, G = 0, B = 0, A = 150},
        },
        ["deo"] = {
            label = "Déodorant",
            canHide = false,
            description = "Votre odeur de Déodorant diminue avec le temps.",
            removePerMinute = 25, -- pourcentage perdu par minutes 
            ProgressColor = {R = 0, G = 241, B = 0, A = 200},
            ProgressBackgroundColor = {R = 0, G = 0, B = 0, A = 150},
        },
    }
}