local identifier = "dealer"

while GetResourceState("lb-phone") ~= "started" do
    Wait(500)
end

local function addApp()
    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = identifier, -- unique app identifier

        name = "DealWP",
        description = "DealWP te permet de faire des affaires avec les habitants. En toute sécurité et en toute transparence.",
        developer = "Null",

        defaultApp = false, --  set to true, the app will automatically be added to the player's phone
        size = 11212, -- the app size in kb
        price = 25, -- OPTIONAL make players pay with in-game money to download the app
 
        images = { -- OPTIONAL array of screenshots of the app, used for showcasing the app
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/appstore1.png",
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/appstore2.png",
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/appstore3.png",
        },

        -- ui = "http://localhost:5500/" .. GetCurrentResourceName() .. "/ui/index.html",
        ui = GetCurrentResourceName() .. "/ui/index.html",

        icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/icon.png",

        fixBlur = true -- set to true if you use em, rem etc instead of px in your css
    })

    if not added then
        print("Could not add app:", errorMessage)
    end
end

addApp()

AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then
        addApp()
    end
end)

-- Variables pour la vente de drogue
local activeDrugs = {}
local activeOffers = {}
local isLookingForBuyers = false
local nextOfferId = 1

local function hasItem(itemName)
    local inventory = ESX.GetPlayerData().inventory
    for i=1, #inventory do
        if inventory[i].name == itemName and inventory[i].count > 0 then
            return true
        end
    end
    return false
end

RegisterNUICallback("drawNotification", function(data, cb)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(data.message)
    EndTextCommandThefeedPostTicker(false, false)
    cb("ok")
end)

RegisterNUICallback("checkDealingStatus", function(data, cb)
    print("checkDealingStatus callback triggered")
    cb({ isLookingForBuyers = isLookingForBuyers })
end)

RegisterNUICallback("getActiveOffers", function(data, cb)
    print("getActiveOffers callback triggered")
    
    local offers = {}
    for id, offer in pairs(activeOffers) do
        offers[#offers + 1] = offer
    end
    
    print("Active offers count:", #offers)
    cb({ offers = offers })
end)

RegisterNUICallback("checkDrugAvailability", function(data, cb)
    local hasItemResult = hasItem(data.itemName)
    
    exports["lb-phone"]:SendCustomAppMessage(identifier, {
        type = "updateDrugStatus",
        drugId = data.drugId,
        hasItem = hasItemResult
    })
    
    cb({ hasItem = hasItemResult })
end)

RegisterNUICallback("startDealing", function(data, cb)
    print("startDealing callback triggered with data:", json.encode(data))
    
    if isLookingForBuyers then
        print("Already looking for buyers")
        exports["lb-phone"]:SetPopUp({
            title = 'Vous cherchez déjà des acheteurs',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
        return
    end
    
    activeDrugs = {}
    local drugItems = {
        ["weed"] = "weed_pooch",
        ["meth"] = "meth_pooch",
        ["coke"] = "coke_pooch"
    }
    
    print("Selected drugs:", json.encode(data.selectedDrugs))
    
    for _, drugId in ipairs(data.selectedDrugs) do
        local hasItemResult = hasItem(drugItems[drugId])
        print("Checking drug:", drugId, "Has item:", hasItemResult)
        
        if hasItemResult then
            table.insert(activeDrugs, {
                id = drugId,
                item = drugItems[drugId],
                label = drugId == "weed" and "Pochon de Weed" or drugId == "meth" and "Pochon de Meth" or "Pochon de Coke"
            })
        end
    end
    
    print("Active drugs:", json.encode(activeDrugs))
    
    if #activeDrugs > 0 then
        isLookingForBuyers = true
        print("Triggering server event dealwp:startDealing")
        TriggerServerEvent("dealwp:startDealing", activeDrugs)
        exports["lb-phone"]:SendNotification({
            app = "dealer",
            title = "Recherche en cours",
            content = "Recherche d'acheteurs en cours...",
        })
        cb({ success = true })
    else
        print("No drugs available")
        exports["lb-phone"]:SetPopUp({
            title = 'Vous n\'avez pas les drogues sélectionnées',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
    end
end)

RegisterNUICallback("acceptDealOffer", function(data, cb)
    if inOffer then
        exports["lb-phone"]:SetPopUp({
            title = 'Vous avez deja accepté une offre.',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
    else
        local offerId = data.offerId
        local offer = activeOffers[offerId]
        
        if offer then
            TriggerServerEvent("dealwp:acceptOffer", offerId, offer)
            exports["lb-phone"]:SetPopUp({
                title = 'Nous vous avons mis en contact avec l\'acheteur, il vous contactera prochainement',
                buttons = {
                    {
                        title = 'OK',
                        color = 'green'
                    }
                },
            })
            activeOffers[offerId] = nil
            cb({ success = true })
        else
            exports["lb-phone"]:SetPopUp({
                title = 'Offre non trouvée',
                buttons = {
                    {
                        title = 'OK',
                        color = 'red'
                    }
                },
            })
            cb({ success = false })
        end
    end
end)

-- Callback pour négocier une offre
RegisterNUICallback("negotiateDealOffer", function(data, cb)
    local offerId = data.offerId
    local newPrice = data.newPrice
    local offer = activeOffers[offerId]
    
    if offer then
        TriggerServerEvent("dealwp:negotiateOffer", offerId, offer, newPrice)
        cb({ success = true })
    else
        exports["lb-phone"]:SetPopUp({
            title = 'Offre non trouvée',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
    end
end)

-- Callback pour refuser une offre
RegisterNUICallback("declineDealOffer", function(data, cb)
    local offerId = data.offerId
    local offer = activeOffers[offerId]
    
    if offer then
        TriggerServerEvent("dealwp:declineOffer", offerId, offer)
        activeOffers[offerId] = nil
        cb({ success = true })
    else
        exports["lb-phone"]:SetPopUp({
            title = 'Offre non trouvée',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
    end
end)

-- Événement pour recevoir une nouvelle offre d'achat
RegisterNetEvent("dealwp:newOffer")
AddEventHandler("dealwp:newOffer", function(drugId, price, quantity)
    local drugInfo = nil
    
    for _, drug in ipairs(activeDrugs) do
        if drug.id == drugId then
            drugInfo = drug
            break
        end
    end
    
    if drugInfo then
        local offerId = nextOfferId
        nextOfferId = nextOfferId + 1
        
        local offer = {
            id = offerId,
            drugId = drugId,
            drugLabel = drugInfo.label,
            price = price,
            quantity = quantity,
            item = drugInfo.item
        }
        
        activeOffers[offerId] = offer
        
        exports["lb-phone"]:SendCustomAppMessage(identifier, {
            type = "newDealOffer",
            offer = offer
        })
    end
end)

-- Événement pour recevoir le résultat d'une négociation
RegisterNetEvent("dealwp:negotiationResult")
AddEventHandler("dealwp:negotiationResult", function(offerId, accepted, newPrice)
    local offer = activeOffers[offerId]
    
    if offer then
        if accepted then
            -- Mettre à jour l'offre avec le nouveau prix
            offer.price = newPrice
            activeOffers[offerId] = offer
            
            -- Notifier le joueur
            exports["lb-phone"]:SendCustomAppMessage(identifier, {
                type = "updateOffer",
                offerId = offerId,
                newPrice = newPrice,
                message = "Négociation acceptée"
            })
        else
            -- Notifier le joueur que la négociation a été refusée
            exports["lb-phone"]:SendCustomAppMessage(identifier, {
                type = "updateOffer",
                offerId = offerId,
                message = "Négociation refusée"
            })
        end
    end
end)

local buyerPed = nil
local inOffer = false
RegisterNetEvent("dealwp:acceptedOffer")
AddEventHandler("dealwp:acceptedOffer", function(offerId, offer, position, pedModel, pedAnim)
    if inOffer then return end
    if offer then
        inOffer = true
        RequestModel(pedModel)    
        while not HasModelLoaded(pedModel) do
            Citizen.Wait(100)
        end
        buyerPed = CreatePed(0, pedModel, position.x, position.y, position.z-1, position.w, false, false) 

        RequestAnimDict(pedAnim.dict)
        while not HasAnimDictLoaded(pedAnim.dict) do
            Wait(0)
        end
        TaskPlayAnim(buyerPed, pedAnim.dict, pedAnim.anim, 8.0, -8.0, -1, 51, 0, false, false, false)
        SetBlockingOfNonTemporaryEvents(buyerPed, true)
        SetEntityInvincible(buyerPed, true)
        FreezeEntityPosition(buyerPed, true)
        local playerPed = PlayerPedId()
        Citizen.CreateThread(function()
            while true do
                local distance = #(GetEntityCoords(playerPed) - vector3(position.x, position.y, position.z)) 
                if distance < 2.0 then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accepter l'offre")
                    if IsControlJustPressed(0, 51) then
                        local PlayerCoords = GetEntityCoords(playerPed)
                        local pedCoords = GetEntityCoords(buyerPed)
                        TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 1000)
                        TaskTurnPedToFaceCoord(buyerPed, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
                        Wait(1200)
                        FreezeEntityPosition(buyerPed, true)
                        FreezeEntityPosition(playerPed, true)
                        ClearPedTasks(buyerPed)
                        local dict, anim = "mp_common", "givetake1_a" 
                        ESX.Streaming.RequestAnimDict(dict)
                        TaskPlayAnim(playerPed, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                        TaskPlayAnim(buyerPed, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                        TriggerServerEvent("dealwp:dealCompleted", offerId)
                        isSelling = false
                        Citizen.CreateThread(function()
                            Wait(2000)
                            ClearPedTasks(buyerPed)
                            ClearPedTasks(playerPed)
                            FreezeEntityPosition(playerPed, false)
                            SetBlockingOfNonTemporaryEvents(buyerPed, false)
                            FreezeEntityPosition(buyerPed, false)
                            local gooutcoords = exports["null-core"]:GenerateRandomCoordAroundPoint(pedCoords, 50.0)
                            TaskGoToCoordAnyMeans(buyerPed, gooutcoords, 1.0, 0, 0, 786603, 0)
                            Wait(30000)
                            DeleteEntity(buyerPed)
                        end)
                        inOffer = false
                        break
                    end
                end
                Wait(0)
            end
        end)
    end
end)

-- Callback pour arrêter la recherche d'acheteurs
RegisterNUICallback("stopDealing", function(data, cb)
    print("stopDealing callback triggered")
    
    if not isLookingForBuyers then
        print("Not looking for buyers, nothing to stop")
        exports["lb-phone"]:SetPopUp({
            title = 'Vous ne recherchez pas d\'acheteurs',
            buttons = {
                {
                    title = 'OK',
                    color = 'red'
                }
            },
        })
        cb({ success = false })
        return
    end
    
    -- Arrêter la recherche
    isLookingForBuyers = false
    TriggerServerEvent("dealwp:stopDealing")
    
    -- Nettoyer les variables
    activeDrugs = {}
    activeOffers = {}
    
    -- Notifier l'utilisateur
    exports["lb-phone"]:SendNotification({
        app = "dealer",
        title = "Recherche arrêtée",
        content = "Vous avez arrêté la recherche d'acheteurs.",
    })
    
    print("Dealing stopped successfully")
    cb({ success = true })
end)

-- Événement pour arrêter la recherche d'acheteurs (déclenché par le serveur)
RegisterNetEvent("dealwp:stopDealing")
AddEventHandler("dealwp:stopDealing", function()
    isLookingForBuyers = false
    activeDrugs = {}
    activeOffers = {}
    
    exports["lb-phone"]:SendCustomAppMessage(identifier, {
        type = "dealingStopped"
    })
end)