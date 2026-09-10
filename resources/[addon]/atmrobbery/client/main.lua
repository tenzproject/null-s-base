local HashATM = nil

-- exports.ox_target:addModel(ATM.Props, {
--     {
--         icon = "fas fa-credit-card",
--         label = "Braquer l'ATM",
--         event = "robberyAtm",
--         distance = 1.5,
--         canInteract = function(entity, coords, distance)
--             HashATM = entity
--             return true
--         end,
--     },
-- })

RegisterNetEvent("robberyAtm")
AddEventHandler("robberyAtm", function()
    ESX.TriggerServerCallback('prz_atmrobbery:getRobbery', function(cb)
        if cb then
            AnimHack()
            TriggerEvent("mhacking:show")
            TriggerEvent("mhacking:start", 4, 30, AtmHackFirstSuccess)
            TriggerServerEvent("prz_atmrobbery:robberyAlert", GetEntityCoords(HashATM))
        end
    end, HashATM)
end)


RegisterNetEvent('amt:notify')
AddEventHandler('amt:notify', function()
    local _source = source
    if ESX then
        local xPlayers = ESX.GetPlayers()

        for i=1, #xPlayers, 1 do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            
            if xPlayer.job.name == 'police' then
                ESX.ShowNotification('Un braquage ATM est en cours')
                local blipRobbery = AddBlipForCoord(xPlayer.getCoords(true)) -- Remplacer xPlayer.getCoords(true) par les coordonnées de l'ATM
                SetBlipSprite(blipRobbery, 161)
                SetBlipScale(blipRobbery, 2.0)
                SetBlipColour(blipRobbery, 3)
                PulseBlip(blipRobbery)
                Wait(60000)
                RemoveBlip(blipRobbery)
            end
        end
    else
        print("ESX n'est pas initialisé.")
    end
end)

local lastAtm = nil
function AtmHackFirstSuccess(success)
    if lastAtm ~= nil then
        local time = GetGameTimer()
        if (time - lastAtm) < 35000 then
            return
        else
            lastAtm = GetGameTimer()
        end
    else
        lastAtm = GetGameTimer()
    end

    FreezeEntityPosition(GetPlayerPed(-1),false)
    TriggerEvent('mhacking:hide')
    if success then
        TriggerServerEvent("prz_atmrobbery:stopAtm", HashATM)
        ESX.ShowNotification("Tu as Réussi a  ~y~hacker~s~ le ~b~NetWork~s~, la police a été prévenu !")
        TriggerEvent("prz_atmrobbery:setBlip")
        ClearPedTasks(PlayerPedId())
        Wait(2500)
        AnimCash()
    else
		ESX.ShowNotification("Tu as ~r~Raté~s~ le Hack du ~y~NetWork~s~, la police a été prévenu !")
		ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
	end
end

function AnimCash()
	local animDict = "anim@heists@ornate_bank@grab_cash"
	local animName = "grab"

	RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end

	SetEntityHeading(PlayerPedId(), GetEntityHeading(HashATM))

	local model = GetHashKey('prop_cs_heist_bag_02')
	RequestModel(model)
	while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(10)
    end

	local object = CreateObject(model, GetEntityCoords(PlayerPedId()), true, true, true)
	AttachEntityToEntity(object, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.0, 0.0, -0.16, 250.0, -30.0, 0.0, false, false, false, false, 0, true)

	TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, -1, 2, 0, 0, 0, 0)
    if lib.progressCircle({
        duration = ATM.GrapTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
        },
    }) then
        DeleteEntity(object)
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('prz_atmrobbery:giveCash')
    end
end

function AnimHack()
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"),true)
	Citizen.Wait(250)
	FreezeEntityPosition(PlayerPedId(), true)
	TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_STAND_MOBILE', -1, true)
	Citizen.Wait(2000)
end

local blipAtm = nil
RegisterNetEvent('prz_atmrobbery:setBlip')
AddEventHandler('prz_atmrobbery:setBlip', function(coords)
    local playerId = GetPlayerServerId(NetworkGetEntityOwner(GetPlayerPed(-1)))

    local blipAtm = AddBlipForCoord(coords.x, coords.y, coords.z)
    ESX.ShowNotification('~r~Un braquage ATM est en cours~r~, regardé votre GPS !')
    SetBlipSprite(blipAtm, 161)
    SetBlipScale(blipAtm, 1.5)
    SetBlipColour(blipAtm, 5)
    
    PulseBlip(blipAtm)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Braquage d'atm")
    EndTextCommandSetBlipName(blipAtm)
    Citizen.Wait(120000) -- Ligneadd
    RemoveBlip(blipAtm) --Lige add
end)

RegisterNetEvent('prz_atmrobbery:killBlip')
AddEventHandler('prz_atmrobbery:killBlip', function()
	RemoveBlip(blipAtm)
end)