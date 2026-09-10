--[[
    ColorPanel - Panneau de sélection de couleur interactif avec la souris
    
    Exemple d'utilisation:
    local selectedColor = RageUI.ColorPanel("Couleur du véhicule", currentColor, function(color)
    end)
]]

RageUI.ColorPanel = LPH_NO_VIRTUALIZE(function(Title, CurrentColor, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "colorpanel",
            label = Title or "Sélectionner une couleur",
            description = "",
            currentColor = CurrentColor or { r = 255, g = 255, b = 255 },
            callback = Callback,
            enabled = false
        }
        RageUI._AddRenderItem(item)
        
        -- Stocker le callback dans le menu pour le NUI
        if RageUI.CurrentMenu then
            RageUI.CurrentMenu._colorPanelCallback = Callback
        end
        
        return item.currentColor
    end
    return CurrentColor or { r = 255, g = 255, b = 255 }
end)