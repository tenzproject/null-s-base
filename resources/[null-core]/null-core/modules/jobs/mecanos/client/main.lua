local IndexDispo = 1
local status = false
VerifiedPlate = {}
openMecano = function()
    local menu = RageUI.CreateMenu(ESX.PlayerData.job.label, "Menu ".. ESX.PlayerData.job.label)
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                onChecked = function()
                    status = true 
                    TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, true)
                end,
                onUnChecked = function()
                    status = false 
                    TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, false)
                end
            })
            RageUI.Line()
            RageUI.Button('Facture', nil, {}, true, {
                onSelected = function() 
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Il n\'y a aucun joueurs au alentours')
                    else
                        local string = null.fct.input('Montant', false, 9000000, "number")
                        if string ~= "" then
                            Montant = tonumber(string)
                        end
                        TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), ESX.PlayerData.job.name)
                    end
                end,
            onActive = function()

            end})
            RageUI.Button('Verifier le propriétaire d\'un véhicule', nil, {}, true, {
                onSelected = function() 
                    local playerPed = PlayerPedId()
                    local vehicle,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
                    local coords = GetEntityCoords(playerPed, false)
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if IsPedSittingInAnyVehicle(playerPed) then
                        ESX.ShowNotification('Vous ne pouvez pas faire sa a l\'intérieur d\'un véhicule')
                        return
                    end

                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Il n\'y a aucun joueurs au alentours')
                    else
                        if DoesEntityExist(vehicle) and dist4 < 4 then
                            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
                            
                            FreezeEntityPosition(playerPed, true)
                            Citizen.CreateThread(function()
                                Citizen.Wait(10000)
                                FreezeEntityPosition(playerPed, false)
                                ClearPedTasksImmediately(playerPed)
                                TriggerServerEvent("null:mecano:verifOwner", GetPlayerServerId(closestPlayer), GetVehicleNumberPlateText(vehicle))
                            end)
                        else
                            ESX.ShowNotification('Aucun véhicule au alentours')
                        end
                    end
                end,
                onActive = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer ~= -1 and closestDistance <= 3.0 then
                        PlayerMarker(closestPlayer)
                    end
                    local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                    local VehiclePos = 	GetEntityCoords(vehicle)
                    DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 170, false, true, nil, true)
                end})
            RageUI.Button('Réparer véhicule', nil, {}, true, {
                onSelected = function() 
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed, false)
                    local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                    local VehiclePos = 	GetEntityCoords(vehicle)
                    local distance = Vdist(coords.x, coords.y, coords.z, VehiclePos)
                    --local vehicle = ESX.Game.GetVehicleInDirection()
                    if IsPedSittingInAnyVehicle(playerPed) then
                        local vehicle = GetVehiclePedIsIn(PlayerPed, false)
                    else
                        local vehicle = ESX.Game.GetVehicleInDirection()
                    end
    
                    if DoesEntityExist(vehicle) then
                        if distance > 2 then
                            ESX.ShowNotification("Vous êtes trop loin du véhicule")
                            return
                        end
                        if SocietyList[ESX.PlayerData.job.name] ~= nil and SocietyList[ESX.PlayerData.job.name].data ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique["Politique de vérification"] then
                            if VerifiedPlate[GetVehicleNumberPlateText(vehicle)] ~= true then 
                                ESX.ShowNotification('Vous devez verifier le propriétaire du véhicule.')
                                return
                            end
                        end
                        TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
                        Citizen.CreateThread(function()
                            Citizen.Wait(20000)
    
                            SetVehicleFixed(vehicle)
                            SetVehicleDeformationFixed(vehicle)
                            SetVehicleUndriveable(vehicle, false)
                            SetVehicleEngineHealth(vehicle, 1000.0)
                            SetVehicleEngineOn(vehicle, true, true)
                            ClearPedTasksImmediately(playerPed)
    
                            ESX.ShowNotification('Le véhicule à été reparer')
                        end)
                    else
                        ESX.ShowNotification('Aucun véhicule au alentours')
                    end
                end,
            onActive = function()
                local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                local VehiclePos = 	GetEntityCoords(vehicle)
                DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 170, false, true, nil, true)
            end})
            RageUI.Button('Crocheter', nil, {}, true, {
                onSelected = function() 
                    local playerPed = PlayerPedId()
                    local vehicle = ESX.Game.GetVehicleInDirection()
                    local coords = GetEntityCoords(playerPed, false)
        
                    if IsPedSittingInAnyVehicle(playerPed) then
                        ESX.ShowNotification('Vous ne pouvez pas faire sa a l\'intérieur d\'un véhicule')
                        return
                    end
        
                    if DoesEntityExist(vehicle) then
                        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
                        Citizen.CreateThread(function()
                            Citizen.Wait(10000)
        
                            SetVehicleDoorsLocked(vehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                            ClearPedTasksImmediately(playerPed)
        
                            ESX.ShowNotification('Le véhicule à été dévérouiller')
                        end)
                    else
                        ESX.ShowNotification('Aucun véhicule au alentours')
                    end
                end,
                onActive = function()
                    local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                    local VehiclePos = 	GetEntityCoords(vehicle)
                    DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 170, false, true, nil, true)
                end})
            RageUI.Button('Nettoyer', nil, {}, true, {
                onSelected = function() 
                    local playerPed = PlayerPedId()
                    local vehicle = ESX.Game.GetVehicleInDirection()
                    local coords = GetEntityCoords(playerPed, false)
    
                    if IsPedSittingInAnyVehicle(playerPed) then
                        ESX.ShowNotification('Vous ne pouvez pas faire sa a l\'intérieur d\'un véhicule')
                        return
                    end
    
                    if DoesEntityExist(vehicle) then
                        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_MAID_CLEAN", 0, true)
                        Citizen.CreateThread(function()
                            Citizen.Wait(10000)
    
                            SetVehicleDirtLevel(vehicle, 0)
                            ClearPedTasksImmediately(playerPed)
    
                            ESX.ShowNotification('Le véhicule à été dévérouiller')
                        end)
                    else
                        ESX.ShowNotification('Aucun véhicule au alentours')
                    end
                end,
                onActive = function()
                    local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                    local VehiclePos = 	GetEntityCoords(vehicle)
                    DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 170, false, true, nil, true)
                end})
            RageUI.Button('Fourrière', nil, {}, true, {
                onSelected = function() 
                    local playerPed = PlayerPedId()

                    if IsPedSittingInAnyVehicle(playerPed) then
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
    
                        if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                            ESX.ShowNotification('Le véhicule à été mis en fourrière')
                            ESX.Game.DeleteVehicle(vehicle)
                        else
                            ESX.ShowNotification('Vous devez être conducteur !', "Erreur")
                        end
                    else
                        local vehicle = ESX.Game.GetVehicleInDirection()
    
                        if DoesEntityExist(vehicle) then
                            ESX.ShowNotification('Le véhicule à été mis en fourrière')
                            ESX.Game.DeleteVehicle(vehicle)
                        else
                            ESX.ShowNotification('Aucun véhicule au alentours', "Erreur")
                        end
                    end
                end,
                onActive = function()
                    local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                    local VehiclePos = 	GetEntityCoords(vehicle)
                    DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 170, false, true, nil, true)
                end})
                RageUI.Button("Montrer son badge", nil, {}, true, {
                    onSelected = function()
                        ShowJobBadge(ESX.PlayerData.job.name)
                    end
                })
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end



RegisterNetEvent('null:VerifOwnerReceive', function(plate)
    VerifiedPlate[plate] = true
end)

MecanoPosition = {}
local BlipsMecano = {}

RegisterNetEvent('Null:receiveMecano', function(Table)
    for _, v in pairs(Table or {}) do
        null.data.markers.unregister("job_mecano_vestiaire_"..v.name)
        null.data.markers.unregister("job_mecano_custom1_"..v.name)
        null.data.markers.unregister("job_mecano_custom2_"..v.name)
        null.data.markers.unregister("job_mecano_custom3_"..v.name)
        null.data.markers.unregister("job_mecano_boss_"..v.name)
    end
    null.data.jobs.mecanos.list = Table
    null.data.jobs.mecanos.loaded = true
    Wait(1000)
    for k,v in pairs(BlipsMecano) do
        RemoveBlip(v)
    end
    BlipsMecano = {}

    for k,v in pairs(null.data.jobs.mecanos.list) do
        MecanoPosition[v.name] = vector3(v.PosCustom.x, v.PosCustom.y, v.PosCustom.z)
        if v.type == 'Mécano' then
            if BlipsMecano[v.name] == nil then
                BlipsMecano[v.name] = AddBlipForCoord(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z)
                SetBlipSprite(BlipsMecano[v.name], 446)
                SetBlipDisplay(BlipsMecano[v.name], 4)
                SetBlipScale(BlipsMecano[v.name], 0.6)
                SetBlipColour(BlipsMecano[v.name], 51)
                SetBlipAsShortRange(BlipsMecano[v.name], true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.label)
                EndTextCommandSetBlipName(BlipsMecano[v.name])
                SetBlipCategory(BlipsMecano[v.name], 10)
            end
            if not null.data.markers.isRegister("job_mecano_vestiaire_"..v.name) then
                null.data.markers.register("job_mecano_vestiaire_"..v.name, {
                    Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenVestiaire(ESX.PlayerData.job.name)
                    end
                })
                null.data.markers.register("job_mecano_custom1_"..v.name, {
                    Position = vector3(v.PosCustom.x, v.PosCustom.y, v.PosCustom.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        if PlayerState.isInVehicle then
                            if SocietyList[ESX.PlayerData.job.name] ~= nil and SocietyList[ESX.PlayerData.job.name].data ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique["Politique de vérification"] then
                                if VerifiedPlate[GetVehicleNumberPlateText(PlayerState.vehicle)] ~= true then 
                                    ESX.ShowNotification('Vous devez verifier le propriétaire du véhicule.')
                                    return
                                end
                            end
                            TriggerEvent('null:openMenuCustom', v.name, v.label, vector3(v.PosCustom.x, v.PosCustom.y, v.PosCustom.z))
                        else
                            ESX.ShowNotification('Vous devez être dans un véhicule')
                        end
                    end
                })
                null.data.markers.register("job_mecano_custom2_"..v.name, {
                    Position = vector3(v.PosCustom2.x, v.PosCustom2.y, v.PosCustom2.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        if PlayerState.isInVehicle then
                            if SocietyList[ESX.PlayerData.job.name] ~= nil and SocietyList[ESX.PlayerData.job.name].data ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique["Politique de vérification"] then
                                if VerifiedPlate[GetVehicleNumberPlateText(PlayerState.vehicle)] ~= true then 
                                    ESX.ShowNotification('Vous devez verifier le propriétaire du véhicule.')
                                    return
                                end
                            end
                            TriggerEvent('null:openMenuCustom', v.name, v.label, vector3(v.PosCustom2.x, v.PosCustom2.y, v.PosCustom2.z))
                        else
                            ESX.ShowNotification('Vous devez être dans un véhicule')
                        end
                    end
                })
                null.data.markers.register("job_mecano_custom3_"..v.name, {
                    Position = vector3(v.PosCustom3.x, v.PosCustom3.y, v.PosCustom3.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        if PlayerState.isInVehicle then
                            if SocietyList[ESX.PlayerData.job.name] ~= nil and SocietyList[ESX.PlayerData.job.name].data ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique ~= nil and SocietyList[ESX.PlayerData.job.name].data.politique["Politique de vérification"] then
                                if VerifiedPlate[GetVehicleNumberPlateText(PlayerState.vehicle)] ~= true then 
                                    ESX.ShowNotification('Vous devez verifier le propriétaire du véhicule.')
                                    return
                                end
                            end
                            TriggerEvent('null:openMenuCustom', v.name, v.label, vector3(v.PosCustom3.x, v.PosCustom3.y, v.PosCustom3.z))
                        else
                            ESX.ShowNotification('Vous devez être dans un véhicule')
                        end
                    end
                })
                null.data.markers.register("job_mecano_boss_"..v.name, {
                    Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenSocietyMenu(
                            {
                                label = ESX.PlayerData.job.label, 
                                name = ESX.PlayerData.job.name 
                            }, 
                            vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                            nil
                        )
                    end
                })
            end
        end
    end
end)

RegisterNetEvent('Null:deletemecanoblips', function(value)
    for k,v in pairs(BlipsMecano) do
        if k == value then
            RemoveBlip(v)
            break
        end
    end
end)


Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('Null:initMecano')
end)

RegisterNetEvent('null:mecano:addchoicenotif')
AddEventHandler('null:mecano:addchoicenotif', function(id, name, pos,sprite, color, tag,msg)
    if null.data.jobs.mecanos.list[ESX.PlayerData.job.name] then
        if tag == nil then tag = 'default' end
        ESX.ShowAccept(msg, function(result)
            if result then
                SetNewWaypoint(pos.x,pos.y)
                --[[ESX.addBlips({
                    name = tag..':mecano-blip_'..id,
                    label = name,
                    category = nil,
                    position = vector3(pos.x,pos.y,pos.z),
                    sprite = sprite,
                    display = 4,
                    scale = 0.75,
                    color = color
                })]]
                ESX.ShowNotification("Un point sur votre GPS a était placé.")
            end
        end)
    end
end)
