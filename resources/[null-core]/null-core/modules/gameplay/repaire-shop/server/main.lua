if SaveData.json["repair"] == nil then SaveData.json["repair"] = {} end

ESX.RegisterServerCallback("Null:repairshop:get", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    if SaveData.json["repair"][idunique] ~= nil then
        for k,v in pairs(SaveData.json["repair"][idunique]) do
            local diftime = (os.time() - v.time)
            local totalTime = v.repairtime * 60
            if diftime > totalTime then
                v.pourcent = 100
                v.finish = true
            else
                v.pourcent = (diftime / totalTime) * 100
                v.finish = false
            end
        end
        cb(SaveData.json["repair"][idunique])
        return
    end
    cb({})
end)

function GetRepairPrice(weapontype, durability)
    local maxprice = Config.Repair.Prices[weapontype]
    local percentToRepair = (100 - durability) / 100
    local repairPrice = maxprice * percentToRepair
    return repairPrice
end

RegisterNetEvent("null:repair:get", function(weapon)
    if not weapon then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    if not xPlayer then return end
    if xPlayer.hasWeapon(weapon) then return end
    if SaveData.json["repair"][idunique] == nil then return end
    if SaveData.json["repair"][idunique][weapon] == nil then return end
    if SaveData.json["repair"][idunique][weapon].take ~= false then return end
    if SaveData.json["repair"][idunique][weapon].finish ~= true then return end
    if SaveData.json["repair"][idunique][weapon].pourcent ~= 100 then return end
    SaveData.json["repair"][idunique][weapon].take = true 
    local data = SaveData.json["repair"][idunique][weapon]
    xPlayer.addWeapon(weapon, 
        0, 
        data.metadata, 
        data.permanent,
        data.serialnumber,
        0.0,
        data.components
    )
    SaveData.json["repair"][idunique][weapon] = nil
end)

RegisterNetEvent("null:repair:weapon", function(weaponname, weapontype)
    if not weaponname then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local idunique = xPlayer.getIdunique()
    if not xPlayer.hasWeapon(weaponname) then return end
    local index, weapon = xPlayer.getWeapon(weaponname)
    local price = GetRepairPrice(weapontype, weapon.durability or 100)
    if xPlayer.getAccount("cash").money < price then return end
    if SaveData.json["repair"][idunique] ~= nil and SaveData.json["repair"][idunique][weaponname] ~= nil then return end
    xPlayer.removeAccountMoney("cash", price)
    xPlayer.removeWeapon(weaponname)
    if SaveData.json["repair"][idunique] == nil then
        SaveData.json["repair"][idunique] = {}
    end
    local repairtime = Config.Repair.TimeToRepair
    pcall(function()
        local vipRepair = exports["null-core"]:GetVIPRepairTime(xPlayer.identifier)
        if vipRepair and vipRepair < repairtime then
            repairtime = vipRepair
        end
    end)

    SaveData.json["repair"][idunique][weaponname] = {
        time = os.time(),
        repairtime = repairtime,
        name = weaponname,
        pourcent = 0,
        finish = false,
        take = false,
        -- save data:
        metadata = weapon.metadata or {},
        durability = weapon.durability or 0,
        serialnumber = weapon.serialnumber,
        components = weapon.components or {},
        permanent = weapon.permanent or false
    }
end)