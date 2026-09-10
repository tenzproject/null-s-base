delGunStaffActive = false

function GetPlayerIdFromPed(id)
    local toreturn = 0
    for i = 0,900000 do
        if NetworkIsPlayerActive(i) then
            if GetPlayerPed(i) == id then
                toreturn = GetPlayerServerId(i)
                break
            end
        end
    end
    return toreturn 
end

function boolStaffGun()
    CreateThread(function()
        if delGunStaffActive then
            local playerPed = PlayerPedId()
            local weaponHash = GetHashKey("WEAPON_SNSPISTOL_MK2")

            -- Donner le pistolet au joueur avec accessoires
            GiveWeaponToPed(playerPed, weaponHash, 255, false, true)
            --GiveWeaponComponentToPed(playerPed, weaponHash, GetHashKey("COMPONENT_SNSPISTOL_MK2_CAMO_IND_01_SLIDE"))
            GiveWeaponComponentToPed(playerPed, weaponHash, GetHashKey("COMPONENT_AT_PI_SUPP_02"))
            GiveWeaponComponentToPed(playerPed, weaponHash, GetHashKey("COMPONENT_SNSPISTOL_MK2_CLIP_02"))
            GiveWeaponComponentToPed(playerPed, weaponHash, GetHashKey("COMPONENT_AT_PI_RAIL_02"))
            GiveWeaponComponentToPed(playerPed, weaponHash, GetHashKey("COMPONENT_AT_PI_FLSH_03"))
            
            -- Munitions illimitées et suppression des dégâts
            SetPedInfiniteAmmo(playerPed, true, weaponHash)
            SetWeaponDamageModifier(weaponHash, 0.0)

        else
            -- Retirer le pistolet du joueur et désactiver les munitions illimitées
            RemoveWeaponFromPed(PlayerPedId(), GetHashKey("WEAPON_SNSPISTOL_MK2"))
            SetPedInfiniteAmmo(PlayerPedId(), false, GetHashKey("WEAPON_SNSPISTOL_MK2"))
        end

        local result2, entity2
        while delGunStaffActive do
            Wait(5)
            if IsControlJustReleased(0, 24) then
                local weapon = GetSelectedPedWeapon(PlayerPedId())
                if weapon == GetHashKey("WEAPON_SNSPISTOL_MK2") then
                    result2, entity2 = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if entity2 ~= 0 then
                        if IsEntityAVehicle(entity2) then
                            showVehicleMenu(entity2)
                        elseif IsEntityAPed(entity2) and IsPedAPlayer(entity2) then
                            targetPlayer = GetPlayerIdFromPed(entity2)
                            if nPlayer then
                                for k, v in pairs(nPlayer) do
                                    if v.source == targetPlayer then
                                        selectedPlayer = v
                                    end
                                end
                                showPlayerMenu(selectedPlayer)
                            else
                                while nPlayer == nil do
                                    Wait(1)
                                end
                                for k, v in pairs(nPlayer) do
                                    if v.source == targetPlayer then
                                        selectedPlayer = v
                                    end
                                end
                                showPlayerMenu(selectedPlayer)
                            end
                        elseif GetVehiclePedIsIn(entity2, false) ~= 0 then
                            showVehicleMenu(GetVehiclePedIsIn(entity2, false))
                        else
                            vehmenuOpen = false
                            RageUI.CloseAll()
                            RageUI.Visible(mainMenuVeh, false)
                        end
                    end
                end
            end
        end

        -- Retirer l'arme et désactiver les munitions illimitées lorsque le mode StaffGun est désactivé
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey("WEAPON_SNSPISTOL_MK2"))
        SetPedInfiniteAmmo(PlayerPedId(), false, GetHashKey("WEAPON_SNSPISTOL_MK2"))
    end)
end

RegisterNetEvent('Yvelt:reciveActionVeh')
AddEventHandler('Yvelt:reciveActionVeh', function(action, veh, arg1)
    local target = NetworkGetEntityFromNetworkId(veh)
    if action == 'del' then
        SetEntityAsMissionEntity(target, false, false)
        DeleteEntity(target)
    elseif action == 'plate' then
        SetVehicleNumberPlateText(target, arg1)
    elseif action == 'gaz' then
        SetVehicleFuelLevel(target, 200.0)
    elseif action == 'retourner' then
        local pos = GetEntityCoords(target)
        SetEntityCoords(target, pos)
    elseif action == 'flip' then
    elseif action == 'clean' then
        SetVehicleDirtLevel(target, 0.1)
    elseif action == 'repair' then
        FixVehicleWindow(target, 0)
        SetVehicleFixed(target)
        SetVehicleDirtLevel(target, 0.0)
        SetVehicleUndriveable(target, false)
        SetVehicleEngineOn(target, true, true)
        SetVehicleEngineHealth(target, 1000.0)
        SetVehiclePetrolTankHealth(target, 1000.0)
        SetVehicleBodyHealth(target, 1000.0)
    end
end)

function repairVeh(veh)
    netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("Yvelt:VehicleActionServer", 'repair', netId)
end

function gazVeh(veh)
    netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("Yvelt:VehicleActionServer", 'gaz', netId)
end

function retournerVeh(veh)
    netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("Yvelt:VehicleActionServer", 'retourner', netId)
end

function plateVeh(veh, arg1)
    netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("Yvelt:VehicleActionServer", 'plate', netId, arg1)
end

function deleteVeh(veh)
    netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent("Yvelt:VehicleActionServer", 'del', netId)
end

local vehmenuOpen = false
local mainMenuVeh = RageUI.CreateMenu("Menu", 'MENU GESTION VEHICULE')

function showVehicleMenu(veh)
    local vehicle = veh
    if vehmenuOpen then
        vehmenuOpen = false
        RageUI.CloseAll()
        RageUI.Visible(mainMenuVeh, false)
        Wait(10)
    end
    vehmenuOpen = true
    RageUI.Visible(mainMenuVeh, true)
    CreateThread(function()
        while vehmenuOpen do
            Wait(1)
            RageUI.IsVisible(mainMenuVeh, function()
                local VehExist = DoesEntityExist(vehicle)

                RageUI.Button("Supprimer le véhicule", nil, {}, VehExist, {
                    onActive = function()
                        local vehiclePos = GetEntityCoords(vehicle)
                        DrawMarker(21, vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.3, 0.0, 0.0, 0.0, 0.0,0.0,0.0, 0.3,0.3, 0.3, 255, 0, 0, 255, true, true, p19, true)
                    end,
                    onSelected = function()
                        if DoesEntityExist(vehicle) then
                            deleteVeh(vehicle)
                            --RageUI.CloseAll()
                        end
                    end
                })
                RageUI.Button("Réparer le véhicule", nil, {}, VehExist, {
                    onActive = function()
                        local vehiclePos = GetEntityCoords(vehicle)
                        DrawMarker(21, vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.3, 0.0, 0.0, 0.0, 0.0,0.0,0.0, 0.3,0.3, 0.3, 255, 0, 0, 255, true, true, p19, true)
                    end,
                    onSelected = function()
                        if DoesEntityExist(vehicle) then
                            repairVeh(vehicle)
                        end
                    end
                })

                RageUI.Button("Nettoyer le véhicule", nil, {}, VehExist, {
                    onActive = function()
                        ClosetVehWithDisplay()
                    end,
                    onSelected = function()
                        local veh = ESX.Game.GetClosestVehicle(PlayerState.coords)
                        if not (veh) then
                            ESX.ShowNotification('🚨 Aucun véhicule au alentours')
                        else
                            SetVehicleDirtLevel(veh, 0.0)
                        end
                    end
                })
                RageUI.Button("Retourner le véhicule", nil, {}, VehExist, {
                    onActive = function()
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        local vehicle = ESX.Game.GetClosestVehicle(playerCoords)
                        local vehiclePos = GetEntityCoords(vehicle)
                        DrawMarker(21, vehiclePos.x, vehiclePos.y, vehiclePos.z + 1.3, 0.0, 0.0, 0.0, 0.0,0.0,0.0, 0.3,0.3, 0.3, 255, 0, 0, 255, true, true, p19, true)
                    end,
                    onSelected = function()
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        local vehicle = ESX.Game.GetClosestVehicle(playerCoords)
                        --local modelName = KeyboardInput('YveltPlate', "Veuillez entrer la "..c.."plaque~s~ du véhicule", '', 8)
        
                        if DoesEntityExist(vehicle) then
                            retournerVeh(vehicle, modelName)
                        end
                    end
                })

                RageUI.Button("Mettre le plein d'essence", nil, {}, VehExist, {
                    onActive = function()
                        ClosetVehWithDisplay()
                    end,
                    onSelected = function()
                        local veh = ESX.Game.GetClosestVehicle(PlayerState.coords)
                        if not (veh) then
                            ESX.ShowNotification('🚨 Aucun véhicule aux alentours')
                        else
                            SetVehicleFuelLevel(veh, 100.0)
                            ESX.ShowNotification('⛽ Le plein d\'essence a été fait')
                        end
                    end
                })

                RageUI.Button("Vider le réservoir", nil, {}, VehExist, {
                    onActive = function()
                        ClosetVehWithDisplay()
                    end,
                    onSelected = function()
                        local veh = ESX.Game.GetClosestVehicle(PlayerState.coords)
                        if not (veh) then
                            ESX.ShowNotification('🚨 Aucun véhicule aux alentours')
                        else
                            SetVehicleFuelLevel(veh, 0.0)
                            ESX.ShowNotification('⛽ Le réservoir a été vidé')
                        end
                    end
                })
                if VehExist then
                    RageUI.Checkbox("Freeze/Unfreeze le véhicule", nil, isVehicleFrozen, {}, {
                        onSelected = function(checked)
                            local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
                            if veh and veh ~= 0 then
                                if checked ~= isVehicleFrozen then
                                    isVehicleFrozen = checked
                                    FreezeEntityPosition(veh, isVehicleFrozen)
                                end
                            else
                                ESX.ShowNotification("🚨 Aucun véhicule aux alentours")
                            end
                        end
                    })
                end

                RageUI.Button("Perdre le contrôle", nil, {}, VehExist, {
                    onSelected = function()
                        local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
                        if veh and veh ~= 0 then
                            local tiltDuration = 2000 
                            local startTime = GetGameTimer()
                            
                            local vehicleHeading = GetEntityHeading(veh)
                
                            local driver = GetPedInVehicleSeat(veh, -1)
                            if driver and driver == PlayerPedId() then
                                TaskVehicleTempAction(PlayerPedId(), veh, 27, tiltDuration) 
                            end
                            
                            ApplyForceToEntity(veh, 1, 0.0, 1.5, 2.0, 0.0, 0.0, 0.5, false, true, true, false, false, true)
                            
                            while (GetGameTimer() - startTime) < tiltDuration do
                                Citizen.Wait(10)
                                
                                if driver and driver == PlayerPedId() then
                                    DisableControlAction(0, 59, true) 
                                    DisableControlAction(0, 60, true) 
                                end
                                
                                local progress = (GetGameTimer() - startTime) / tiltDuration
                                local tiltAngle = progress * 90.0 
                                
                                SetEntityRotation(veh, 0.0, tiltAngle, vehicleHeading, 2, true)
                            end
                
                            Citizen.CreateThread(function()
                                local sliding = true
                                while sliding do
                                    Citizen.Wait(10)
                
                                    ApplyForceToEntity(veh, 1, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, false, true, true, false, false, true)
                
                                    local roll, pitch, yaw = table.unpack(GetEntityRotation(veh, 2))
                                    if math.abs(roll) < 90.0 then
                                        SetEntityRotation(veh, 0.0, 90.0, vehicleHeading, 2, true)
                                    end
                                end
                            end)
                
                            SetVehicleCanBreak(veh, false)
                            Citizen.Wait(tiltDuration)
                
                        else
                        end
                    end
                }) 
            end)
        end
    end)
end


local plymenuOpen = false
local mainMenuPly = RageUI.CreateMenu("Menu", 'MENU GESTION VEHICULE')

function showPlayerMenu(ply)
    local idunique = ply.idunique
    local mygroup = ESX.PlayerData.group
    if plymenuOpen then
        plymenuOpen = false
        RageUI.CloseAll()
        RageUI.Visible(mainMenuPly, false)
        Wait(10)
    end
    plymenuOpen = true
    RageUI.Visible(mainMenuPly, true)
    CreateThread(function()
        while plymenuOpen do
            Wait(1)
            RageUI.IsVisible(mainMenuPly, function()
                RageUI.Button("Heal", nil, {}, (StaffHasPerm("HEAL")), {
                    onSelected = function()
                        serverInteraction = true
                        ExecuteCommand(("%s %s"):format(Config.Admin.Commands.heal, nPlayer[idunique].source))
                        Wait(250)
                        serverInteraction = false
                    end
                })
                RageUI.Button("Revive", nil, {}, (StaffHasPerm("REVIVE")), {
                    onSelected = function()
                        ExecuteCommand("revive "..nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button("Mettre en Jail", nil, {}, (StaffHasPerm("JAIL")), {
                    onSelected = function()
                        local warn = AdminMenu:input("Raison du jail", "", 30, false)
                        if warn ~= nil then
                            local time = AdminMenu:input("Temps du jail", "", 30, false)
                            ExecuteCommand("jail "..nPlayer[idunique].idunique.." "..time.." "..warn.."")
                        end
                    end
                })
                RageUI.Button("Bannir", nil, {}, (StaffHasPerm("JAIL")), {
                    onSelected = function()
                        local warn = AdminMenu:input("Raison du jail", "", 30, false)
                        if warn ~= nil then
                            local time = AdminMenu:input("Temps du jail", "", 30, false)
                            ExecuteCommand("ban "..nPlayer[idunique].idunique.." "..time.." "..warn.."")
                        end
                    end
                })
                RageUI.Button('Téléporter PC', nil, {}, true, {
                    onSelected = function()
                        ExecuteCommand('tppc ' .. nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button('Téléporter sur moi', nil, {}, true, {
                    onSelected = function()
                        ExecuteCommand('bring ' .. nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button('Se téléporter', nil, {}, true, {
                    onSelected = function()
                        ExecuteCommand('tpa ' .. nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button('Retourner', nil, {}, true, {
                    onSelected = function()
                        ExecuteCommand('back ' .. nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button("Mettre un Limite Physique", nil, {}, (StaffHasPerm("ATA")), {
                    onSelected = function()
                        local time = tonumber(AdminMenu:input("Temps de la Limite Physique (1-30 minutes)", "", 30, false))
                        if time ~= nil then
                            TriggerServerEvent("ata:server:staff:updateNoCane", nPlayer[idunique].source, time)
                        end
                        nPlayer[idunique].Ata = time
                    end
                })
                if nPlayer[idunique].Ata then 
                    RageUI.Button("Retirer la Limite Physique", nil, {}, (StaffHasPerm("ATA")), {
                        onSelected = function()
                            TriggerServerEvent("ata:server:staff:updateNoCane", nPlayer[idunique].source, 0)
                            nPlayer[idunique].Ata = false
                        end,
                        onActive = function()
                            RageUI.Info("Information Limite Physique", {"Temps restant"}, {nPlayer[idunique].Ata .." Minutes"})
                        end
                    })
                end
                RageUI.Button("Sortir de Jail", nil, {}, (StaffHasPerm("JAIL")), {
                    onSelected = function()
                        ExecuteCommand("unjail "..nPlayer[idunique].idunique)
                    end
                })
                RageUI.Button("Historique de Jail", nil, {}, true, {
                    onSelected = function()
                        nPlayer[idunique].SantionType = "Jail"
                        ESX.TriggerServerCallback("AdminMenu:getPlayerSanction", function(result)
                            nPlayer[idunique].sanction = result
                        end, nPlayer[idunique].source)
                    end
                })
                RageUI.Button("Historique de Ban", nil, {}, true, {
                    onSelected = function()
                        nPlayer[idunique].SantionType = "Ban"
                        ESX.TriggerServerCallback("AdminMenu:getPlayerSanction", function(result)
                            nPlayer[idunique].sanction = result
                        end, nPlayer[idunique].source)
                    end
                })
                RageUI.Button("Mettre un Avertissement", nil, {}, (StaffHasPerm("WARN")), {
                    onSelected = function()
                        local warn = AdminMenu:input("Raison du warn", "", 30, false)
                        if warn ~= nil then
                            serverInteraction = true
                            TriggerServerEvent("AdminMenu:warn", nPlayer[idunique].source, warn)
                            nPlayer[idunique].sanctionOk = true
                        end
                    end
                })
                RageUI.Button("Voir la liste des Warns", nil, {}, true, {
                    onSelected = function()
                        nPlayer[idunique].SantionType = "Warn"
                        ESX.TriggerServerCallback("AdminMenu:getPlayerSanction", function(result)
                            nPlayer[idunique].sanction = result
                        end, nPlayer[idunique].source)
                    end
                })
            end)
        end
    end)
end