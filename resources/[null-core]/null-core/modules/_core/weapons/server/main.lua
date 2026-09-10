function getDurability(src, name)
    local xPlayer = ESX.GetPlayerFromId(src)
    local hasWeapon = xPlayer.hasWeapon(name)

    if hasWeapon then
        local index, weapon = xPlayer.getWeapon(name)
        return weapon.durability or 0
    else
        return 0
    end
end

function SetDurability(src, weapon, durability)
    local xPlayer = ESX.GetPlayerFromId(src)
    local hasWeapon = xPlayer.hasWeapon(weapon)

    if hasWeapon and weapon and durability then
        xPlayer.editWeapon(weapon, {
            ["durability"] = durability
        })
    end
end

RegisterNetEvent("null:ammoDelete", function(index, item, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    count = tonumber(count) or 1
    if count < 1 then count = 1 end
    if count > 100 then count = 100 end
    
    if item and item.name then
        xPlayer.removeInventoryItem(item.name, count)
    end
end)

RegisterNetEvent("null:weapon:saveAmmo", function(weaponName, clipAmmo)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if type(weaponName) ~= 'string' then return end
    if not xPlayer.hasWeapon(weaponName) then return end

    clipAmmo = tonumber(clipAmmo) or 0
    if clipAmmo < 0 then clipAmmo = 0 end
    if clipAmmo > 500 then clipAmmo = 500 end

    local _, weapon = xPlayer.getWeapon(weaponName)
    local meta = weapon.metadata or {}
    if meta.ammo == clipAmmo then return end -- no change, skip write
    meta.ammo = clipAmmo
    xPlayer.editWeaponMetaData(weaponName, meta)
end)

RegisterNetEvent("null:durability:add", function(name, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasWeapon(name) then return end
    local index, weapon = xPlayer.getWeapon(name)
    if weapon.durability == nil then weapon.durability = 0 end
    local new = weapon.durability + value
    SetDurability(xPlayer.source, name, new)
end)

null.InitPrint("^2Weapons module loaded")
