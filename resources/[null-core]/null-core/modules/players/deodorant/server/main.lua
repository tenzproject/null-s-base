Citizen.CreateThread(function()
    ESX.RegisterUsableItem("deo", function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        
        local smells = xPlayer.getSmells()
        for k,v in pairs(smells) do
            if Config.smells.allSmells[k] then
                if Config.smells.allSmells[k].canHide then
                    v.hidden = true
                    xPlayer.setSmell(k, v)
                end
            end            
        end

        xPlayer.setSmell("deo", {
            value = 100
        })

        xPlayer.removeInventoryItem("deo", 1)
    end)
end)
