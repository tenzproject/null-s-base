local UNARMED_HASH <const> = `WEAPON_UNARMED`
local PARACHUTE_HASH <const> = `GADGET_PARACHUTE`

local weapons = Config.WeaponParams.List
local listBags = Config.ListBags

local currentWeapon = UNARMED_HASH
local canFire = true

local function HasWeaponBag()
    local ped = PlayerPedId()
    local bagIndex = GetPlayerSkinData("bags_1") or 0
    null.DebugPrint("bagIndex: "..tostring(bagIndex))
    local sex = PlayerState.playerSex or "male"
    null.DebugPrint("sex: "..tostring(sex))
    local bagData = listBags[sex] and listBags[sex][bagIndex]
    null.DebugPrint(bagData)
    return bagData and bagData.weapon == true
end

local function IsWeaponRestricted(weaponHash)
    local loadout = ESX.PlayerData.loadout
    if not loadout then return false end
    
    for _, weapon in pairs(loadout) do
        if GetHashKey(weapon.name) == weaponHash then
            if weapon.durability and weapon.durability >= 95.0 then
                return true
            end
            if weapon.restricted then
                return true
            end
            if weapon.metadata and weapon.metadata.restricted then
                return true
            end
            return false
        end
    end
    return false
end

local function GetNearbyVehicleTrunk()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local checkPos = coords + forward * 2.0
    
    local vehicle = GetClosestVehicle(checkPos.x, checkPos.y, checkPos.z, 3.0, 0, 71)
    if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
        return vehicle
    end
    return nil
end

local function ProcessWeaponChange(ped, selectedWeapon)
    SetCurrentPedWeapon(ped, currentWeapon, true)
    
    if IsWeaponRestricted(selectedWeapon) then
        ESX.ShowNotification("~r~Cette arme est restreinte.")
        return false
    end
    
    local weaponData = weapons[selectedWeapon]
    if weaponData and weaponData.onlyBag then
        if not HasWeaponBag() then
            local vehicle = GetNearbyVehicleTrunk()
            if vehicle then
                SetVehicleDoorOpen(vehicle, 5, false, false)
                Wait(1500)
                SetVehicleDoorShut(vehicle, 5, false)
            else
                ESX.ShowNotification("~r~Vous devez disposer d'un sac ou être proche d'un véhicule.")
                return false
            end
        end
    end
    
    SetCurrentPedWeapon(ped, selectedWeapon, true)
    currentWeapon = selectedWeapon
    canFire = true
    return true
end

CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded(500)
    playerSex = ESX.PlayerData.sex or "male"
    
    local sleepTime = 500
    
    while true do
        Wait(sleepTime)
        sleepTime = 500 
        
        local ped = PlayerPedId()
        
		if NullGF.InZone then goto continue end
        
        if not IsEntityDead(ped) and IsPedOnFoot(ped) then
            local selectedWeapon = GetSelectedPedWeapon(ped)
            
            if selectedWeapon ~= currentWeapon and selectedWeapon ~= PARACHUTE_HASH then
                sleepTime = 0
                ProcessWeaponChange(ped, selectedWeapon)
            end
        end
        
        if not canFire then
            DisableControlAction(0, 25, true)
            DisablePlayerFiring(PlayerPedId(), true)
        end
        ::continue::
    end
end))

AddEventHandler('esx:onPlayerSpawn', function()
    currentWeapon = UNARMED_HASH
    canFire = true
end)

exports('GetCurrentWeapon', function()
    return currentWeapon
end)

exports('CanPlayerFire', function()
    return canFire
end)

null.InitPrint("^2Weapons module loaded")
