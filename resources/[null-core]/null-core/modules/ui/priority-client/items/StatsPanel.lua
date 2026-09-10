RageUI.StatsPanel = LPH_NO_VIRTUALIZE(function(Stats)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        if not Stats or type(Stats) ~= "table" then
            return
        end
        
        local leftItems = {}
        local rightItems = {}
        
        for i, stat in ipairs(Stats) do
            if stat.label then
                table.insert(leftItems, stat.label)
                table.insert(rightItems, tostring(stat.value or 0) .. "%")
            end
        end
        
        local item = {
            type = "info",
            label = "Statistiques",
            description = "",
            leftItems = leftItems,
            rightItems = rightItems,
            enabled = false
        }
        RageUI._AddRenderItem(item)
    end
end)
