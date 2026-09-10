--[[
    InfoPanel - Panneau d'informations avancé avec support des actions à touches
    
    Exemple d'utilisation:
    RageUI.InfoPanel({
        title = "Contrôles",
        items = {
            { label = "Se déplacer", key = "ZQSD" },
            { label = "Courir", key = "SHIFT" },
            { label = "Sauter", key = "ESPACE" },
            { label = "Inventaire", key = "F2", value = "Ouvert" },
            { label = "Santé", value = "85/100" },
            { label = "VIP", value = "true" }
        }
    })
]]

RageUI.InfoPanel = LPH_NO_VIRTUALIZE(function(data)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "infopanel",
            label = data.title or "",
            description = "",
            panelItems = data.items or {},
            enabled = false
        }
        RageUI._AddRenderItem(item)
    end
end)
