RegisterNetEvent('null:opencreategarage', function(Table)
    openCreateGarage()
end)
VehicleSort = {}
local GarageLoaded = false
localCarsOwned = {}
localCarsJobsOwned = {}
localCarsOrgOwned = {}

local Button = 1
local index = {
    list = 1
}

function starsBoutique(isboutique)
    if isboutique then
        return {RightBadge = RageUI.BadgeStyle.Star}
    else
        return{}
    end
end

local isBoutique = false

function openMenuGarage(SpawnPoint, TypeGarage, garageid)
    ESX.PlayerData = ESX.GetPlayerData()
    ESX.TriggerServerCallback('null:getOwnedCars', function(ownedCars, ownedCarsJobs, OwnedCarsOrg)
        localCarsOwned = ownedCars
        localCarsJobsOwned = ownedCarsJobs
        localCarsOrgOwned = OwnedCarsOrg
        GarageLoaded = true
    end)
    local menu = RageUI.CreateMenu("", "Bonjour "..GetPlayerName(PlayerId()).." voici votre garage")
    local MyVeh = RageUI.CreateSubMenu(menu,"", "Bonjour "..GetPlayerName(PlayerId()).." voici votre garage")
    local MyVehSociety = RageUI.CreateSubMenu(menu,"", "Bonjour "..GetPlayerName(PlayerId()).." voici votre garage")
    local MyVehIllegal = RageUI.CreateSubMenu(menu,"", "Bonjour "..GetPlayerName(PlayerId()).." voici votre garage")
    local Action = {
        'Aucun',
        'Entreprise',
        'Gang/Organisation',
        'Boutique'
    }
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while not GarageLoaded do 
        Wait(1)
    end
    while menu do
        Citizen.Wait(0)
        FreezeEntityPosition(PlayerPedId(), true)
        RageUI.IsVisible(menu, function()
            RageUI.Button('Mes Véhicules', nil, {}, true, {
                onSelected = function()
                    
                end
            }, MyVeh)
            RageUI.Button('Véhicules de société', nil, {}, ESX.PlayerData.job.name ~= "unemployed" and true or false, {
                onSelected = function()
                    
                end
            }, MyVehSociety)
            RageUI.Button('Véhicules de mon groupe', nil, {}, ESX.PlayerData.job2.name ~= "unemployed" and true or false, {
                onSelected = function()
                    
                end
            }, MyVehIllegal)
            --[[RageUI.Button('Locations', nil, {}, true, {
                onSelected = function()
                    TriggerEvent("xRent:openMenu")
                    RageUI.CloseAll()
                end
            })]]
        end, function()
        end)
        RageUI.IsVisible(MyVeh, function()
            if tostring(TypeGarage) == 'car' then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'car' and v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        end
                    elseif v.type == 'car' and not v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()
    
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'boat' then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'boat' and v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'aircraft' then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'aircraft' and v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    if ESX.PlayerData.job.name ~= 'unemployed' and ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, false)
                                    elseif ESX.PlayerData.job.name ~= 'unemployed' then
                                        openSelectedVehicle(v, SpawnPoint, false, TypeGarage, true)
                                    elseif ESX.PlayerData.job2.name ~= 'unemployed2' then
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, false)
                                    else
                                        openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                    end
                                end
                            })
                        end
                    end
                end
            end
        end, function()
        end)

        RageUI.IsVisible(MyVehSociety, function()
            if tostring(TypeGarage) == 'car' then
                for k,v in pairs(localCarsJobsOwned) do
                    if v.type == 'car' and v.state and v.job ~= 'unemployed' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    elseif v.type == 'car' and not v.state and v.job ~= 'unemployed' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()

                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'boat' then
                for k,v in pairs(localCarsJobsOwned) do
                    if v.type == 'boat' and v.state and v.job ~= 'unemployed' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'aircraft' then
                for k,v in pairs(localCarsJobsOwned) do
                    if v.type == 'aircraft' and v.state and v.job ~= 'unemployed' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    end
                end
            end
        end, function()
        end)
        RageUI.IsVisible(MyVehIllegal, function()
            if tostring(TypeGarage) == 'car' then
                for k,v in pairs(localCarsOrgOwned) do
                    if v.type == 'car' and v.state and v.job ~= 'unemployed2' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    elseif v.type == 'car' and not v.state and v.job ~= 'unemployed2' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()

                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate.." - En fourrière", {RightLabel = 'Fourrière'}, false, {
                                onSelected = function()
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'boat' then
                for k,v in pairs(localCarsOrgOwned) do
                    if v.type == 'boat' and v.state and v.job ~= 'unemployed2' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'aircraft' then
                for k,v in pairs(localCarsOrgOwned) do
                    if v.type == 'aircraft' and v.state and v.job ~= 'unemployed2' then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, {}, true, {
                                onSelected = function()
                                    isBoutique = v.boutique
                                    openSelectedVehicle(v, SpawnPoint, true, TypeGarage, true)
                                end
                            })
                        end
                    end
                end
            end
        end, function()
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(MyVeh) and not RageUI.Visible(MyVehIllegal) and not RageUI.Visible(MyVehSociety) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function openSelectedVehicle(vehicle, SpawnPoint, entreprise, TypeGarage, gang)
    local menu = RageUI.CreateMenu(GetLabelText(GetDisplayNameFromVehicleModel(vehicle.vehicle.model)), "Que souhaitez vous faire ?")
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        FreezeEntityPosition(PlayerPedId(), true)
        RageUI.IsVisible(menu, function()
            RageUI.Button('Sortir le véhicule', nil, {}, true, {
                onSelected = function()
                    if not VehicleSort[vehicle.plate] then
                        SpawnVehicle(vehicle.vehicle, vehicle.plate, SpawnPoint)
                        RageUI.CloseAll()
                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez sorti votre véhicule.")
                    else
                        if DoesEntityExist(VehicleSort[vehicle.plate].Entity) then
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                        else
                            SpawnVehicle(vehicle.vehicle, vehicle.plate, SpawnPoint)
                            RageUI.CloseAll()
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez sorti votre véhicule.")
                        end
                    end
                end
            })
            RageUI.Button('Renommer le véhicule', nil, {}, true, {
                onSelected = function()
                    null.fct.inputCb("Quelle nom voulez vous mettre?",function(label) 
                        TriggerServerEvent('null:renameVehicle', vehicle.owner, vehicle.vehicle, label)
                        RageUI.CloseAll()
                        Wait(150)
                        openMenuGarage(SpawnPoint, TypeGarage, vehicle.garage)
                    end)
                end
            })
            if not vehicle.boutique and not isBoutique then
                RageUI.Button('Donner le véhicule', 'Permet de donner le véhicule au joueurs le plus proche de vous', {}, true, {
                    onActive = function()
                        local player, closestplayer = ESX.Game.GetClosestPlayer()
                        if player ~= -1 or closestplayer < 3.0 then
                            --PlayerMarker2(player)
                        end
                    end,
                    onSelected = function()
                        local player, closestplayer = ESX.Game.GetClosestPlayer()
                        if player == -1 or closestplayer > 3.0 then
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Aucun joueurs au alentours.")
                            return
                        else
                            TriggerServerEvent('Null:changevehicleowner', GetPlayerServerId(player), vehicle)
                            RageUI.CloseAll()
                        end
                    end
                })
            end
            if not entreprise and not isBoutique then
                RageUI.Button('Attribuer le véhicule à son entreprise', 'Permet d\'attribuer le véhicule à votre entreprise\n~r~IMPOSSIBLE DE LE RECUPERER PAR LA SUITE', {}, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        if not vehicle.boutique then
                            TriggerServerEvent('Null:AttribuerVehicule', 'job', vehicle)
                        else
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas mettre un véhicule Boutique dans votre Entreprise")
                        end
                    end
                })
            end
            if not gang and not isBoutique then
                RageUI.Button('Attribuer le véhicule à son Gang/Organisation', 'Permet d\'attribuer le véhicule à votre Gang/Organisation\n~r~IMPOSSIBLE DE LE RECUPERER PAR LA SUITE', {}, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        if not vehicle.boutique then
                            TriggerServerEvent('Null:AttribuerVehicule', 'job2', vehicle)
                        else
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas mettre un véhicule Boutique dans votre Organisation")
                        end
                    end
                })
            end
        end, function()
        end)

        if not RageUI.Visible(menu) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function SpawnVehicle(vehicle, plate, SpawnPoint)
    local coords = SpawnPoint
    local heading = GetEntityHeading(PlayerPedId())
	ESX.Game.SpawnVehicle(vehicle.model, coords, heading, function(vehicleSpawn)
		ESX.Game.SetVehicleProperties(vehicleSpawn, vehicle)
		SetVehRadioStation(vehicleSpawn, 'OFF')
		TaskWarpPedIntoVehicle(PlayerPedId(), vehicleSpawn, -1)
        TriggerServerEvent('null:setstatevehicle', plate, false, vehicleSpawn)
	end)
end

function PutVehicleInGarage(vehicle, vehicleProps)
	-- Animation de disparition progressive
	CreateThread(function()
		local alpha = 255
		while alpha > 0 do
			Wait(10)
			alpha = alpha - 5
			if alpha < 0 then alpha = 0 end
			SetEntityAlpha(vehicle, alpha, false)
		end
		ESX.Game.DeleteVehicle(vehicle)
	end)
	
	TriggerServerEvent('null:setstatevehicle', vehicleProps.plate, true)
    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Votre véhicule à été ranger")
end


local NameGarage = "Pas définit"
local PositionGarage = "Aucune"
local PositionPointSpawn = "Aucune"
local PositionPointDelete = "Aucune"
local TypeGarage = "Aucune"

function openCreateGarage()
    local menu = RageUI.CreateMenu('', "Que souhaitez vous faire ?")
    local blip = false
    local BlipActive = false
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Button('Nom du GarageList', NameGarage, {}, true, {
                onSelected = function()
                    null.fct.inputCb("Quelle nom voulez vous mettre?",function(label) 
                        if label ~= nil then 
                            NameGarage = label
                        end
                    end)
                end
            })
            RageUI.Button('Position du GarageList', PositionGarage, {}, true, {
                onSelected = function()
                    PositionGarage = GetEntityCoords(PlayerPedId())
                end
            })
            RageUI.Button('Position du point de Spawn', PositionPointSpawn, {}, true, {
                onSelected = function()
                    PositionPointSpawn = GetEntityCoords(PlayerPedId())
                end
            })
            RageUI.Button('Position du point de Delete', PositionPointDelete, {}, true, {
                onSelected = function()
                    PositionPointDelete = GetEntityCoords(PlayerPedId())
                end
            })
            RageUI.Button('Type de garage', TypeGarage, {RightLabel='car, aircraft ou boat'}, true, {
                onSelected = function()
                    null.fct.inputCb("Type de garage (car/aircraft/boat)",function(label) 
                        if label ~= nil then 
                            TypeGarage = label
                        end
                    end)
                end
            })
            RageUI.Checkbox('Blip sur la map', nil, blip, {}, {
                onChecked = function()
                    blip = true
                    BlipActive = true
                end,
                onUnChecked = function()
                    blip = false
                    BlipActive = false
                end,
            })
            RageUI.Button('~g~Confirmer', nil, {}, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    TriggerServerEvent('null:createGarage', NameGarage, PositionGarage, PositionPointSpawn, PositionPointDelete, TypeGarage, BlipActive)
                end
            })
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

GarageList = {}
GarageLoaded = false
local GarageBlip = {}

RegisterNetEvent('null:refreshGarage', function(Table)
    GarageList = Table
    GarageLoaded = true

    for k,v in pairs(GarageList) do
        if v.BlipActive == 1 or v.blip == true then
            if tostring(v.type) == 'car' then
                ESX.addBlips({
                    name = 'garage_car_'..v.name,
                    label = 'Parking Publique [Terrestre]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 357,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_car",
                })
            elseif tostring(v.type) == 'boat' then
                ESX.addBlips({
                    name = 'garage_boat_'..v.name,
                    label = 'Parking Publique [Nautique]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 473,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_boat",
                })
            elseif tostring(v.type) == 'aircraft' then
                ESX.addBlips({
                    name = 'garage_aircraft_'..v.name,
                    label = 'Parking Publique [Aérien]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 473,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_flight",
                })
            end
        end
    end
end)

Citizen.CreateThread(function()
    Wait(1000)
    TriggerServerEvent('null:InitGarage')
end)


Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while not GarageLoaded do 
        Wait(1)
    end
    for k,v in pairs(Config.Garage.Impound) do
        local blip = AddBlipForCoord(v.PointFourriere)
        SetBlipSprite(blip, 643)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 26)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v.label)
        EndTextCommandSetBlipName(blip)
    end
    for k,v in pairs(GarageList) do
        if v.blip == 1 or v.blip == true then
            if tostring(v.type) == 'car' then
                ESX.addBlips({
                    name = 'garage_car_'..v.name,
                    label = 'Parking Publique [Terrestre]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 357,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_car",
                })
            elseif tostring(v.type) == 'boat' then
                ESX.addBlips({
                    name = 'garage_boat_'..v.name,
                    label = 'Parking Publique [Nautique]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 473,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_boat",
                })
            elseif tostring(v.type) == 'aircraft' then
                ESX.addBlips({
                    name = 'garage_aircraft_'..v.name,
                    label = 'Parking Publique [Aérien]',
                    category = nil,
                    position = vector3(v.position.x, v.position.y, v.position.z),
                    sprite = 473,
                    display = 4,
                    scale = 0.6,
                    color = 26,
                    type="blip_garage_flight",
                })
            end
        end
    end

    local isActive = false
    while true do 
        local isProche = false
        local spam = false
        for k,v in pairs(GarageList) do
            local PointGarage = vector3(v.position.x, v.position.y, v.position.z)

            local DistanceGarage = Vdist2(GetEntityCoords(PlayerPedId(), false), PointGarage)

            if DistanceGarage < 500 then
                isProche = true
                --DrawMarker(36, v.position.x, v.position.y, v.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, 3, 255, 236, 255, false, false, 2, true, false, false, false)
                DrawMarker(25, v.position.x, v.position.y, v.position.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
            end
            if DistanceGarage < 3 then
                null.fct.draw.Text3DBar(PointGarage.x, PointGarage.y, PointGarage.z, "Appuyez sur ["..ESX.Config("serverColor").."E~s~] pour "..ESX.Config("serverColor").."intéragir~s~")
                if IsControlJustPressed(1,51) then
                    --openMenuGarage(vector3(PointGarage.x, PointGarage.y, PointGarage.z), v.type, v.id)
                    openGarage(vector3(PointGarage.x, PointGarage.y, PointGarage.z), v.type, v.id)
                end
            end

            -- DELETE POINT

            local DeletePoint = vector3(v.DeletePoint.x, v.DeletePoint.y, v.DeletePoint.z)

            local DistanceDeletePoint = Vdist2(GetEntityCoords(PlayerPedId(), false), DeletePoint)

            if DistanceDeletePoint < 500 then
                isProche = true
                if v.type == 'boat' then
                    DrawMarker(36, v.DeletePoint.x, v.DeletePoint.y, v.DeletePoint.z+1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, Config.Garage.DeletePointRGB[1], Config.Garage.DeletePointRGB[2], Config.Garage.DeletePointRGB[3], Config.Garage.DeletePointRGB[4], false, false, 2, true, false, false, false)
                else
                    DrawMarker(36, v.DeletePoint.x, v.DeletePoint.y, v.DeletePoint.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, Config.Garage.DeletePointRGB[1], Config.Garage.DeletePointRGB[2], Config.Garage.DeletePointRGB[3], Config.Garage.DeletePointRGB[4], false, false, 2, true, false, false, false)
                end
            end
            if DistanceDeletePoint < 3 then
                if IsPedSittingInAnyVehicle(PlayerPedId()) then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger votre véhicule")
                    if IsControlJustPressed(1,51) then
                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
                        if vehicleProps then
                            local NewPosition = Vdist2(GetEntityCoords(PlayerPedId(), false), DeletePoint)
                            if NewPosition < 20 then
                                ESX.TriggerServerCallback('null:storevehicle', function(valid)
                                    if valid then
                                        TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
                                        Wait(1500)
                                        PutVehicleInGarage(vehicle, vehicleProps)
                                    else
                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule ne vous appartient pas")
                                    end
                                end, vehicleProps, v.garageid, vehicleProps.displayname)
                            else
                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous êtes trop loin du point")
                            end
                        end
                    end
                end
            end
        end
        for k,v in pairs(Config.Garage.Impound) do 
            local FourrierePoint = vector3(v.PointFourriere)

            local FourriereDistance = Vdist2(GetEntityCoords(PlayerPedId(), false), FourrierePoint)

            if FourriereDistance < 500 then
                isProche = true
                if v.type == "car" then
                    DrawMarker(25, v.PointFourriere.x, v.PointFourriere.y, v.PointFourriere.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                elseif v.type == "boat" then
                    DrawMarker(25, v.PointFourriere.x, v.PointFourriere.y, v.PointFourriere.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                elseif v.type == "aircraft" then
                    DrawMarker(25, v.PointFourriere.x, v.PointFourriere.y, v.PointFourriere.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                end
            end
            if FourriereDistance < 3 then
                null.fct.draw.Text3DBar(v.PointFourriere.x, v.PointFourriere.y, v.PointFourriere.z, "Appuyez sur ["..ESX.Config("serverColor").."E~s~] pour "..ESX.Config("serverColor").."intéragir~s~")
                 if IsControlJustPressed(1,51) then
                    --OpenFourriereMenu(v.type, v)
                    OpenImpound(v.type, v)
                 end
            end
        end

		if isProche then
			Wait(0)
		else
			Wait(750)
		end
    end
end))

function OpenFourriereMenu(TypeGarage, table)
    local priceFourriere = 1000
    ESX.TriggerServerCallback('null:getOwnedCars', function(ownedCars, ownedCarsJobs, OwnedCarsOrg)
        localCarsOwned = ownedCars
        localCarsJobsOwned = ownedCarsJobs
        localCarsOrgOwned = OwnedCarsOrg
        GarageLoaded = true
    end)
    local menu = RageUI.CreateMenu("", "Bonjour "..GetPlayerName(PlayerId()).." bienvenue à la Fourrière")

    local Action = {
        'Aucun',
        'Entreprise',
        'Gang/Organisation',
        'Boutique'
    }
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while not GarageLoaded do 
        Wait(1)
    end
    while menu do
        Citizen.Wait(0)
        FreezeEntityPosition(PlayerPedId(), true)
        RageUI.IsVisible(menu, function()
            RageUI.List('Filtre(s) :', Action, index.list, nil, {}, true, {
                onListChange = function(Index, Item)
                    index.list = Index;
                    Button = Index;
                end,
            })
            if tostring(TypeGarage) == 'car' then
                
                if Button == 1 then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'car' and not v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if not VehicleSort[v.vehicle.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if not VehicleSort[v.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        end
                    end
                end

                elseif Button == 2 then
                    for k,v in pairs(localCarsJobsOwned) do
                        if v.type == 'car' and not v.state and v.job ~= 'unemployed' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 3 then
                    for k,v in pairs(localCarsOrgOwned) do
                        if v.type == 'car' and not v.state and v.job ~= 'unemployed2' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 4 then
                    for k,v in pairs(localCarsOwned) do
                        if v.type == 'car' and not v.state and v.boutique then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'boat' then
                RageUI.Separator(ESX.Config("serverColor")..'Bateaux en Fourrière')
                if Button == 1 then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'boat' and not v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if not VehicleSort[v.vehicle.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if not VehicleSort[v.vehicle.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        end
                    end
                end
                elseif Button == 2 then
                    for k,v in pairs(localCarsJobsOwned) do
                        if v.type == 'boat' and not v.state and v.job ~= 'unemployed' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 3 then
                    for k,v in pairs(localCarsOrgOwned) do
                        if v.type == 'boat' and not v.state and v.job ~= 'unemployed2' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then
                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 4 then
                    for k,v in pairs(localCarsOwned) do
                        if v.type == 'boat' and not v.state and v.boutique then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                end
            elseif tostring(TypeGarage) == 'aircraft' then
                RageUI.Separator(ESX.Config("serverColor")..'Avions en Fourrière')
                if Button == 1 then
                for k,v in pairs(localCarsOwned) do
                    if v.type == 'aircraft' and not v.state then
                        if v.label ~= nil then 
                            RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                return
                                            end
                                            if not VehicleSort[v.vehicle.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        else
                            RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                onSelected = function()
                                    RageUI.CloseAll()
                                    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                        if valid then
                                            if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                return
                                            end
                                            if not VehicleSort[v.vehicle.plate] then
                                                RageUI.GoBack()
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                            else
                                                if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                end
                                            end
                                        else
                                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                        end
                                    end, v.vehicle)
                                end
                            })
                        end
                    end
                end
                elseif Button == 2 then
                    for k,v in pairs(localCarsJobsOwned) do
                        if v.type == 'aircraft' and not v.state and v.job ~= 'unemployed' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 3 then
                    for k,v in pairs(localCarsOrgOwned) do
                        if v.type == 'aircraft' and not v.state and v.job ~= 'unemployed2' then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                elseif Button == 4 then
                    for k,v in pairs(localCarsOwned) do
                        if v.type == 'aircraft' and not v.state and v.boutique then
                            if v.label ~= nil then 
                                RageUI.Button('['..GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model))..'] - '..v.label, v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            else
                                RageUI.Button(GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)), v.vehicle.plate, starsBoutique(v.boutique), true, {
                                    onSelected = function()
                                        RageUI.CloseAll()
                                        ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
                                            if valid then

                                                if not VehicleSort[v.vehicle.plate] then
                                                    RageUI.GoBack()
                                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                    SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                else
                                                    if DoesEntityExist(VehicleSort[v.plate].Entity) then
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous ne pouvez pas remettre ce véhicule dans votre garage car il existe déjà sur la map")
                                                    else
                                                        RageUI.GoBack()
                                                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez payé "..priceFourriere.."$ la fourrière")
                                                        SpawnVehicle(v.vehicle, v.plate, table.PointSpawn)
                                                    end
                                                end
                                            else
                                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous n'avez pas l'argent nécéssaire")
                                            end
                                        end, v.vehicle)
                                    end
                                })
                            end
                        end
                    end
                end
            end
        end, function()
        end)

        if not RageUI.Visible(menu) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function openRangerVehicle(position, garageid)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    FreezeEntityPosition(vehicle, true)
    local menu = RageUI.CreateMenu('', "Que souhaitez vous faire ?")
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function() 
            vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
            FreezeEntityPosition(vehicle, true)
            if GetEntityHealth(vehicle) >= GetEntityMaxHealth(vehicle)-50 then
                RageUI.Button('Ranger le véhicule', nil, {}, true, {
                    onSelected = function()
                        local NewPosition = Vdist2(GetEntityCoords(PlayerPedId(), false), position)
                        if NewPosition < 20 then
                            
                            ESX.TriggerServerCallback('null:storevehicle', function(valid)
                                if valid then
                                    RageUI.CloseAll()
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDeformationFixed(vehicle)
                                    SetVehicleUndriveable(vehicle, false)
                                    SetVehicleEngineHealth(vehicle, 1000.0)
                                    PutVehicleInGarage(vehicle, vehicleProps)
                                else
                                    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule ne vous appartient pas")
                                end
                            end, vehicleProps, garageid, vehicleProps.displayname)
                        else
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous êtes trop loin du point")
                        end
                    end
                })
            else
                RageUI.Separator('Votre véhicule est endomagé')
                priceRepair = 1500
                RageUI.Button('Payer '..priceRepair..'$ et ranger le véhicule', nil, {}, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback('null:storevehiclewithmoney', function(valid)
                            if valid then
                                RageUI.CloseAll()
                                PutVehicleInGarage(vehicle, vehicleProps)
                            else
                                ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule ne vous appartient pas")
                            end
                        end, vehicleProps, garageid)
                    end
                })
            end
        end, function()
        end)

        if not RageUI.Visible(menu) then
            FreezeEntityPosition(vehicle, false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

RegisterNetEvent('null:DeleteEntity',function(Entity)
    if DoesEntityExist(Entity) then 
        if NetworkHasControlOfEntity(Entity) then
            DeleteEntity(Entity)
        end
    end
end)


AddTextEntry('BLIP_APARTCAT', 'GarageList ')

RegisterNetEvent('null:UpdateTableVehicleSort', function(table)
    VehicleSort = table
end)
local garagepos = false
local BlipsGarage = {}
RegisterCommand('garagepos', function()
    if Config.GroupeHighPerm[ESX.PlayerData.group] ~= nil then
        garagepos = not garagepos
        if garagepos then
            for k,v in pairs(GarageList) do
                BlipsGarage[v.name] = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
                SetBlipSprite(BlipsGarage[v.name], 357)
                SetBlipDisplay(BlipsGarage[v.name], 4)
                SetBlipScale(BlipsGarage[v.name], 0.8)
                SetBlipColour(BlipsGarage[v.name], 5)
                SetBlipAsShortRange(BlipsGarage[v.name], true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.name)
                EndTextCommandSetBlipName(BlipsGarage[v.name])
                SetBlipCategory(BlipsGarage[v.name], 11)
            end
        else
            for k,v in pairs(BlipsGarage) do 
                RemoveBlip(v)
            end
        end
    end
end)