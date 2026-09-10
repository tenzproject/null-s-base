local GiftBox = nil
local GiftGetted = false

function StartGetBoxWhile(coords, id)
    Citizen.CreateThread(function()
        while true do
            if GiftGetted then break end
            DrawInstructionBarNotification(coords.x, coords.y,coords.z, "[E] Récuperer le cadeau")
            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(coords.x, coords.y,coords.z)) < 4.0 then
                if IsControlJustPressed(0, 51) then
                    TriggerServerEvent("null:noel:get", id)
                    break
                end
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent("null:noel:dropgift", function(coords, idgift, sleighCoords)
    GiftGetted = false
    local sleighBlip = nil
    local giftBlip = nil
    local isGiftDropped = false

    sleighBlip = AddBlipForCoord(sleighCoords.x, sleighCoords.y, sleighCoords.z)
    SetBlipSprite(sleighBlip, 251) -- Icône pour le traîneau
    SetBlipColour(sleighBlip, 1) -- Rouge
    SetBlipScale(sleighBlip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Traîneau du Père Noël")
    EndTextCommandSetBlipName(sleighBlip)

    Citizen.CreateThread(function()   
        TriggerEvent("chat:addMessage", {
            args = {"🛷 Le traîneau du Père Noël passe au-dessus de Los Santos ! Faites attention, un cadeau pourrait bien vous tomber sur la tête !"}
        })     
        TriggerEvent("inventory:sendMessage", "🛷 Le traîneau du Père Noël passe au-dessus de Los Santos ! Faites attention, un cadeau pourrait bien vous tomber sur la tête !", 8000)
        while true do
            Wait(100)
            
            local direction = coords - sleighCoords
            local distance = #(direction)

            if distance > 0 then
                direction = direction / distance
            end

            local speed = 4.5
            sleighCoords = sleighCoords + (direction * speed)
            SetBlipCoords(sleighBlip, sleighCoords.x, sleighCoords.y, sleighCoords.z)


            local distance = #(sleighCoords - coords)
            if distance < 5.0 then
                RemoveBlip(sleighBlip)

                TriggerServerEvent("null:noel:giftdropped", idgift)

                giftDropBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(giftDropBlip, 94) -- Icône pour le traîneau
                SetBlipColour(giftDropBlip, 2)
                SetBlipScale(giftDropBlip, 1.0)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Cadeau Entrain de tomber du traîneau du Père noël")
                EndTextCommandSetBlipName(giftDropBlip)

                Wait(7000)

                RemoveBlip(giftDropBlip)

                giftBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(giftBlip, 478) -- Icône pour le traîneau
                SetBlipColour(giftBlip, 2)
                SetBlipScale(giftBlip, 1.0)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Cadeau tomber du traîneau du Père noël")
                EndTextCommandSetBlipName(giftBlip)

                local giftModel = `prop_lev_crate_01`
                RequestModel(giftModel)
                while not HasModelLoaded(giftModel) do
                    Wait(1)
                end
                GiftBox = CreateObject(giftModel, coords.x, coords.y, coords.z, true, true, true)
                PlaceObjectOnGroundProperly(GiftBox)
                SetModelAsNoLongerNeeded(giftModel)
                StartGetBoxWhile(coords, idgift)
                

                TriggerEvent("chat:addMessage", {
                    args = {"🎁 Un cadeau est tomber du traîneau du Père noël, viens le récuperer avant les autres !"}
                })    
                TriggerEvent("inventory:sendMessage", "🎁 Un cadeau est tomber du traîneau du Père noël, viens le récuperer avant les autres !", 9000)
                break 
            end
        end
        Wait(30000)
        RemoveBlip(giftBlip)
    end)
end)




RegisterNetEvent("null:noel:deletegift", function()
    DeleteEntity(GiftBox)
    GiftGetted = true
    RemoveBlip(giftBlip)
end)