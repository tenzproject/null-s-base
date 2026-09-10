UniqueVehList = {}

RegisterNetEvent("null:boutique:recevieUniqueVeh", function(data)
    -- for k,v in pairs(data) do 
    --     if v and type(v) == "table" then
    --         if BoutiqueVehiclesVideo[v.model] ~= nil then 
    --             data[k].video = true 
    --         end
    --     end
    -- end
    UniqueVehList = data
end)

function getUniqueVeh()
    return UniqueVehList
end
exports("getUniqueVeh", getUniqueVeh)