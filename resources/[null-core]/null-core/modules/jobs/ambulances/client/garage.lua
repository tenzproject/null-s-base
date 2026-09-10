local PlayerData = {}

local alreadyopened = false

local function CheckSpawnData(data)
    local found = false
    local essaiMax = #data * 2
    local essai = 0
    local pos = vector3(339.08, -586.61, 27.8)
    local heading = 100.0
    while not found do
        Wait(100)
        local r = math.random(1, #data)
        local _pos = data[r]
        if ESX.Game.IsSpawnPointClear(_pos.pos, 2.0) then
            pos = _pos.pos
            heading = _pos.heading
            found = true
        else
            ESX.ShowNotification("Toutes les places de parking sont prises !")
        end
        essai = essai + 1
        if essai > essaiMax then
            break
        end
    end
    return found, pos, heading
end

local function CheckSpawnData2(pos)
    if ESX.Game.IsSpawnPointClear(pos, 2.0) then
        return true
    else
        ESX.ShowNotification("Toutes les places de parking sont prises !")
        return false
    end
end

RegisterNetEvent('PharmaPublique:SendState', function(boolean)
    alreadyopened = boolean
end)

local function MarkVehicle(vehicle)
    AddTextEntry('BLIPVEHICLEFUNCTION', 'Véhicule de fonction')
    if not DoesBlipExist(blip) then
        blip = AddBlipForEntity(vehicle)
        SetBlipSprite(blip, 225)
        SetBlipColour(blip, 54)
        BeginTextCommandSetBlipName('BLIPVEHICLEFUNCTION')
        EndTextCommandSetBlipName(blip)
    elseif not DoesBlipExist(blip2) then
        blip2 = AddBlipForEntity(vehicle)
        SetBlipSprite(blip2, 225)
        SetBlipColour(blip2, 54)
        BeginTextCommandSetBlipName('BLIPVEHICLEFUNCTION')
        EndTextCommandSetBlipName(blip2)
    elseif not DoesBlipExist(blip3) then
        blip3 = AddBlipForEntity(vehicle)
        SetBlipSprite(blip3, 225)
        SetBlipColour(blip3, 54)
        BeginTextCommandSetBlipName('BLIPVEHICLEFUNCTION')
        EndTextCommandSetBlipName(blip3)
    elseif not DoesBlipExist(blip4) then
        blip4 = AddBlipForEntity(vehicle)
        SetBlipSprite(blip4, 225)
        SetBlipColour(blip4, 54)
        BeginTextCommandSetBlipName('BLIPVEHICLEFUNCTION')
        EndTextCommandSetBlipName(blip4)
    elseif not DoesBlipExist(blip5) then
        blip5 = AddBlipForEntity(vehicle)
        SetBlipSprite(blip5, 225)
        SetBlipColour(blip5, 54)
        BeginTextCommandSetBlipName('BLIPVEHICLEFUNCTION')
        EndTextCommandSetBlipName(blip5)
    else
        ESX.ShowNotification("Vous avez utilisé toutes vos balises GPS.")
    end
end

local function spawnVeh(model, zone, heading)
    local vehicule = nil
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
    local veh = CreateVehicle(GetHashKey(model), zone, heading, 1, 0)
    MarkVehicle(veh)
    vehicule = veh
    for i = 0,14 do
        SetVehicleExtra(veh, i, 0)
    end
    SetVehicleDirtLevel(veh, 0.1)
end

local function spawnVeh2(model, zone, heading)
    local vehicule = nil
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
    local veh = CreateVehicle(GetHashKey(model), zone, heading, 1, 0)
    SetVehicleLivery(veh,1)
    MarkVehicle(veh)
    vehicule = veh
    for i = 0,14 do
        SetVehicleExtra(veh, i, 0)
    end
    SetVehicleDirtLevel(veh, 0.1)
end



function AmbulanceDeleteVeh()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local vehicule = ESX.Game.GetClosestVehicle(playerCoords)
    if IsPedInAnyVehicle(ped, false) then
        DeleteEntity(vehicule)
        ESX.ShowNotification("Vous avez rangé le véhicule !")
    else
        ESX.ShowNotification("Vous devez être dans un véhicule !")
    end
end

function AmbulanceDeleteVeh2()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local vehicule = ESX.Game.GetClosestVehicle(playerCoords)
    if IsPedInAnyVehicle(ped, false) then
        DeleteEntity(vehicule)
        ESX.ShowNotification("Vous avez rangé le véhicule !")
    else
        ESX.ShowNotification("Vous devez être dans un véhicule !")
    end
end


local Garageveh = {
    helico = {
        {
            nom = "Hélicoptère EMS",
            spawn = "polmav",
        },
    },
}


function AmbulanceOpenGarageMenu2(PosSortie)
    local garageshop2 = RageUI.CreateMenu("", "Hélicoptère disponibles")
    RageUI.Visible(garageshop2, not RageUI.Visible(garageshop2))
    while garageshop2 do
        Citizen.Wait(0)
        RageUI.IsVisible(garageshop2, function()
            RageUI.Separator("Hélicoptère disponibles")
            
            for k,v in pairs(Garageveh.helico) do
                RageUI.Button(v.nom, nil, { RightBadge = RageUI.BadgeStyle.Car }, true, {
                    onSelected = function()
                        local good = CheckSpawnData2(PosSortie)
                        if good then
                            ESX.ShowNotification("Vous avez sorti un "..ESX.Config("serverColor")..v.nom.. " ~s~sur le toit")
                            spawnVeh2(v.spawn, PosSortie, 100)
                            garageshop2 = RMenu:DeleteType('garageshop2')
                        end
                    end
                })
            end
        end, function()
        end)

        if not RageUI.Visible(garageshop2) then
            garageshop2 = RMenu:DeleteType('garageshop2', true)
        end
    end
end