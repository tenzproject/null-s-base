--[[
    GridPanel - Panneau de grille interactif (inspiré du RageUI par défaut)
    Permet de sélectionner une position X/Y sur une grille
    
    Exemple d'utilisation:
    local x, y = RageUI.GridPanel("Position", currentX, currentY, "Horizontal", "Vertical", function(x, y)
    end)
]]

RageUI.GridPanel = LPH_NO_VIRTUALIZE(function(Title, CurrentX, CurrentY, LabelX, LabelY, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "gridpanel",
            label = Title or "Grille",
            description = "",
            currentX = CurrentX or 0.5,
            currentY = CurrentY or 0.5,
            labelX = LabelX or "X",
            labelY = LabelY or "Y",
            callback = Callback,
            enabled = false
        }
        RageUI._AddRenderItem(item)
        
        -- Stocker le callback dans le menu pour le NUI
        if RageUI.CurrentMenu then
            RageUI.CurrentMenu._gridPanelCallback = Callback
        end
        
        return item.currentX, item.currentY
    end
    return CurrentX or 0.5, CurrentY or 0.5
end)