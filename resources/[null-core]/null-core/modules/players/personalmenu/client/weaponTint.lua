Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    
    local value = GetResourceKvpString("Null:weaponTint")

    if value == nil then
        setWeaponTint(0)
    else
        setWeaponTint(value)
    end
end)

function setWeaponTint(weaponTint)
    if weaponTint ~= nil and tonumber(weaponTint) ~= nil and tonumber(weaponTint) >= 0 then
        if weaponTint ~= 0 then
            SetResourceKvp("Null:weaponTint", weaponTint)
        end
        SetPedWeaponTintIndex(PlayerPedId(), PlayerState.weapon, tonumber(weaponTint))
        return GetResourceKvpString("Null:weaponTint")
    end
end

function getWeaponTint(name)
    return tonumber(GetResourceKvpString("Null:weaponTint"))
end

AddEventHandler('Null:utils:changeweapon', function(weaponHash)
    null.fct.waitPlayerLoaded()
    if weaponHash == `WEAPON_UNARMED` then return end
    if ESX.GetGrade() == "default" then return end

    local count = GetWeaponTintCount(weaponHash)

    for i = 0, count do 
        if i == getWeaponTint() then
            SetPedWeaponTintIndex(PlayerPedId(), weaponHash, i)
        end
    end
end)