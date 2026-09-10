local isBlocked = false

RegisterNetEvent('blacklistgun:toggleBlock')
AddEventHandler('blacklistgun:toggleBlock', function(toggle)
    isBlocked = toggle

    if isBlocked then
        Citizen.CreateThread(function()
            local playerPed = PlayerPedId()
            while isBlocked do
                SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) 
                DisablePlayerFiring(playerPed, true)
                Citizen.Wait(0)
            end
        end)
    end
end)


CreateThread(function()
    local savedInfoPosition = GetResourceKvpString("null-core:"..ESX.Config("serverName")..":staff:info-position")
    if savedInfoPosition then
        nTable.InfoPosition = savedInfoPosition
    else
        nTable.InfoPosition = "middle-left"
        SetResourceKvp("null-core:"..ESX.Config("serverName")..":staff:info-position", "middle-left")
    end
end)

RegisterCommand("loc", function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local zoneNameShort = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneNameLabel = GetLabelText(zoneNameShort)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local locationText = "Zone : " .. zoneNameLabel
    if streetName ~= nil and streetName ~= "" then
        locationText = locationText .. " | Rue : " .. streetName
    end
    print("Vous êtes ici : " .. locationText)
end, false)