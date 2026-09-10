--[[
    PercentagePanel - Item de pourcentage (0-100) navigable avec les flèches Gauche/Droite
    
    Exemple d'utilisation:
    local volume = 75
    volume = RageUI.PercentagePanel(volume, "Volume", "Muet", "Max", function(newPercent)
        -- newPercent: 0-100
    end)
]]

RageUI.PercentagePanel = LPH_NO_VIRTUALIZE(function(Percent, HeaderText, MinText, MaxText, Callback, Enabled)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local currentValue = Percent or 50
        if currentValue < 0 then currentValue = 0 end
        if currentValue > 100 then currentValue = 100 end

        local item = {
            type = "percentagepanel",
            label = HeaderText or "",
            description = "",
            enabled = Enabled ~= false,
            value = currentValue,
            min = 0,
            max = 100,
            minText = MinText or "0%",
            maxText = MaxText or "100%",
            onChanged = function(newValue)
                currentValue = newValue
                if type(Callback) == "function" then
                    Callback(newValue)
                elseif type(Callback) == "table" then
                    if Callback.onProgressChange then
                        Callback.onProgressChange(newValue)
                    elseif Callback.onChange then
                        Callback.onChange(newValue)
                    end
                end
            end
        }
        RageUI._AddRenderItem(item)

        return currentValue
    end
    return Percent or 50
end)
