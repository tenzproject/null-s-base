--[[
    ImageSelectorPanel - Panneau de sélection d'images avec grille cliquable
    
    Exemple d'utilisation:
    local selectedImage = RageUI.ImageSelectorPanel("Sélectionner un véhicule", {
        images = {
            { url = "./assets/img/car1.png", label = "Voiture 1" },
            { url = "./assets/img/car2.png", label = "Voiture 2" },
            { url = "./assets/img/car3.png", label = "Voiture 3" },
            { url = "./assets/img/car4.png", label = "Voiture 4" }
        },
        columns = 3,
        selectedIndex = 1
    }, function(index, image)
        -- votre logique ici
    end)
]]

RageUI.ImageSelectorPanel = LPH_NO_VIRTUALIZE(function(Title, Options, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local opts = Options or {}
        local item = {
            type = "imageselector",
            label = Title or "Sélectionner une image",
            description = "",
            images = opts.images or {},
            columns = opts.columns or 3,
            selectedIndex = opts.selectedIndex or 1,
            callback = Callback,
            enabled = false
        }
        RageUI._AddRenderItem(item)
        
        -- Stocker le callback dans le menu pour le NUI
        if RageUI.CurrentMenu and Callback then
            RageUI.CurrentMenu._imageSelectorCallback = Callback
        end
        
        return item.selectedIndex
    end
    return (Options and Options.selectedIndex) or 1
end)
