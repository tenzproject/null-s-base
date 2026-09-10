
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    
    Wait(10000)
    for k, v in pairs(Config.WeaponsBinds) do
        local value = GetResourceKvpString(ESX.Config("serverName")..':weaponKeybinds'..v.id)
        local value2 = GetResourceKvpString(ESX.Config("serverName")..':weaponKeybinds'..v.id..':label')

        if value == nil or value2 == nil then
            TriggerEvent("ZgegFramework:changeShortCut", k, v.weapon)
            setWeaponKeybind(k, v.weapon, v.weaponLabel)
        else
            TriggerEvent("ZgegFramework:changeShortCut", k, value, "number")
            setWeaponKeybind(k, value, value2)
        end
    end
end)

exports('setWeaponKeybind', function(name, weaponHash, weaponLabel)
    return setWeaponKeybind(name, weaponHash, weaponLabel)
end)

exports('getWeaponKeybind', function(name)
    return getWeaponKeybind(name)
end)


function setWeaponKeybind(name, weaponHash, weaponLabel)
    if name == nil or weaponHash == nil or weaponLabel == nil then return end
    SetResourceKvp(ESX.Config("serverName")..':weaponKeybinds'..name, weaponHash)
    SetResourceKvp(ESX.Config("serverName")..':weaponKeybinds'..name..':label', weaponLabel)
    TriggerEvent("ZgegFramework:changeShortCut", name, weaponHash)
    return {weapon = weaponHash, label = weaponLabel}
end

function getWeaponKeybind(name)
    local value = GetResourceKvpString(ESX.Config("serverName")..':weaponKeybinds'..name)
    local value2 = GetResourceKvpString(ESX.Config("serverName")..':weaponKeybinds'..name..':label')
    return {weapon = value, label = value2}
end

for i = 1, #Config.WeaponsBinds do
    RegisterCommand('weaponKeyBinds'..Config.WeaponsBinds[i].id, function()
        local success, isInInventory = pcall(function()
            return NullInventory.isOpen
        end)
        if success and isInInventory then
            local Data = Config.WeaponsBinds[i]            
        else
            if IsControlPressed(0, 62) then
                null.DebugPrint("Control 62 pressed")
                return
            end
            local keyboardData = getWeaponKeybind(Config.WeaponsBinds[i].id)

            if tonumber(keyboardData.weapon) == `WEAPON_UNARMED` then 
                null.DebugPrint("Weapon is unarmed")
                return 
            end
            if #ESX.PlayerData.loadout <= 0 then 
                null.DebugPrint("No weapons in loadout")
                return 
            end
    
            BlockWeaponWheelThisFrame()
            HudWeaponWheelIgnoreSelection()
            HudWeaponWheelIgnoreControlInput()
            
            local gameTimer = GetGameTimer()
    
            Citizen.CreateThread(function ()
                while GetGameTimer() - gameTimer < 1000 do
                    Citizen.Wait(1)
                    BlockWeaponWheelThisFrame()
                    HudWeaponWheelIgnoreSelection()
                    HudWeaponWheelIgnoreControlInput()
                    HideHudComponentThisFrame(19)
                end
            end)
    
            Wait(200)
    
            local loadout = ESX.PlayerData.loadout
            for k,v in pairs(ESX.PlayerData.loadout) do
                if v.name == keyboardData.weapon then
                    if v.metadata ~= nil and v.metadata.restricted == true then
                        null.DebugPrint("Weapon is restricted")
                        return 
                    end
                    if Config.AmmunationShop.repairSysteme and v.durability ~= nil and v.durability >= 95.0 then 
                        null.DebugPrint("Weapon is already at full durability")
                        return 
                    end
                    if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey(v.name) then
                        local _, weaponData = ESX.GetWeapon(v.name)
                        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                        PlayerState.weapon = GetSelectedPedWeapon(PlayerPedId())
                    else
                        SetCurrentPedWeapon(PlayerPedId(), v.name, true)
                        PlayerState.weapon = GetSelectedPedWeapon(PlayerPedId())
                    end
                end
            end 
        end
    end)
    RegisterKeyMapping('weaponKeyBinds'..Config.WeaponsBinds[i].id, ('%s'):format(Config.WeaponsBinds[i].label), 'keyboard', Config.WeaponsBinds[i].bind)
end