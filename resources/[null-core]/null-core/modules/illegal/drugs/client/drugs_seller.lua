Citizen.CreateThread(function()
    while not null.data.markers.loaded do Wait(100) end
    for k,v in pairs(Config.DrugSellers.Positions) do 
        local markId = "drugsSeller_npc_"..k
        null.data.markers.register(markId, {
            Position = vector3(v.x, v.y, v.z+0.4),
            Label = "Appuyez sur [~y~E~s~] pour toquer à la porte",
            Public = true,
            Marker = false,
            Job = nil,
            Job2 = nil,
            Action = function()
                null.data.markers.setVisible(markId, false)
                PlayUrl("knock_door", "sound/knockdoor.mp3", 0.2, false)
                Wait(500)
                ESX.TriggerServerCallback("null:drugsseller:arehere?", function(here, quantity, price, type, name, pedModel) 
                    Wait(math.random(500, 3500))
                    if here then
                        PlayUrl("open_door", "sound/opendoor.mp3", 0.1, false)
                        null.data.markers.setVisible(markId, false)
                        CreateNPCDrugsSeller(k, quantity, price, type, name, pedModel)
                    else
                        null.data.markers.setVisible(markId, true)
                        null.data.markers.editLabel(markId, "Il n'y a l'air d'avoir personne.")
                        Wait(3000)
                        null.data.markers.editLabel(markId, "Appuyez sur [~y~E~s~] pour toquer à la porte")
                    end
                end, k)
            end
        })
    end
end)


local LastDrugsDealerPed = nil
function CreateNPCDrugsSeller(id, quantity, price, drugtype, name, pedModel)
    local NPCPosition = Config.DrugSellers.Positions[id]
    local markId = "drugsSeller_npc_"..id

    RequestModel(pedModel)    
    while not HasModelLoaded(pedModel) do
        Citizen.Wait(100)
    end    
    LastDrugsDealerPed = CreatePed(0, pedModel, NPCPosition.x, NPCPosition.y, NPCPosition.z-1.0, NPCPosition.w, false, false) 
    SetBlockingOfNonTemporaryEvents(LastDrugsDealerPed, true)
    SetEntityInvincible(LastDrugsDealerPed, true)
    FreezeEntityPosition(LastDrugsDealerPed, true)
    SetPedCanRagdoll(LastDrugsDealerPed, false)
    Citizen.CreateThread(function()
        Wait(3*60*1000) -- Part apres 3 minutes
        if not LastDrugsDealerPed then return end
        PlayUrl("close_door", "sound/closedoor.mp3", 0.1, false)
        DeleteEntity(LastDrugsDealerPed)
        LastDrugsDealerPed = nil
        Remove3DInteraction(markId..":talk")
        null.data.markers.setVisible(markId, true)
        null.data.markers.editLabel(markId, "Appuyez sur [~y~E~s~] pour toquer à la porte")
    end)
    Citizen.CreateThread(function()
        --while GetResourceState("null-ui") ~= "started" do Wait(200) end
        Add3DInteraction({
            id = markId..":talk",
            type = "multi",
            coords = NPCPosition,
            text = {
                title = name,
                lines = {
                    {
                        left = "Je vend de la ", 
                        right = ""..drugtype
                    },
                    {
                        left = "J'en est "..quantity.."x pour "..price.."$ unité", 
                        right = ""
                    },
                    {
                        left = "Faire affaire avec "..name, 
                        key = "E", 
                        action = function() 
                            local Quantity = null.fct.input("T'en veux combien ?")
                            if Quantity == nil then return end
                            Quantity = tonumber(Quantity)
                            if PlayerState.accounts.dirtycash < Quantity * price then 
                                ESX.ShowNotification("T'as pas autant d'argent sur toi.")
                                return
                            end
                            if Quantity < 1 then return end
                            if Quantity > quantity then
                                ESX.ShowNotification("J'ai pas autant.")
                                return
                            end
                            Remove3DInteraction(markId..":talk")
                            local PlayerCoords = GetEntityCoords(PlayerPedId())
                            TaskTurnPedToFaceCoord(PlayerPedId(), NPCPosition.x, NPCPosition.y, NPCPosition.z, 1000)
                            TaskTurnPedToFaceCoord(LastDrugsDealerPed, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
                            Wait(1200)
                            FreezeEntityPosition(LastDrugsDealerPed, true)
                            FreezeEntityPosition(PlayerPedId(), true)
                            ClearPedTasks(LastDrugsDealerPed)
                            local dict, anim = "mp_common", "givetake1_a" 
                            ESX.Streaming.RequestAnimDict(dict)
                            TaskPlayAnim(PlayerPedId(), dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                            TaskPlayAnim(LastDrugsDealerPed, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                            Wait(1500)
                            PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 1)
                            TriggerServerEvent("null:drugsseller:buy", id, Quantity)
                            FreezeEntityPosition(PlayerPedId(), false)
                            Wait(2000)
                            if not LastDrugsDealerPed then return end
                            Wait(1000)
                            SetEntityHeading(LastDrugsDealerPed, (NPCPosition.w + 180.0) % 360.0)
                            Wait(1000)
                            PlayUrl("close_door", "sound/closedoor.mp3", 0.1, false)
                            DeleteEntity(LastDrugsDealerPed)
                            LastDrugsDealerPed = nil
                            null.data.markers.setVisible(markId, true)
                            null.data.markers.editLabel(markId, "Appuyez sur [~y~E~s~] pour toquer à la porte")
                        end
                    },
                }
            },
        })
    end)
end 