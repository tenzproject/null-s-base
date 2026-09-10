-- -- Nouvelle Boutique NUI
-- local isOpen = false
-- local currentVehicle = nil
-- local inPreview = false
-- local BeforcePreviewCoords = nil
-- local lastPosition = nil
-- local previewVehicle = nil
-- local previewCam = nil

-- -- Ouvrir/Fermer la boutique
-- function ToggleBoutique()
--     if exports["null-core"]:playerIsDead() then return end
--     if (isInInterfaceValue ~= false and isInInterfaceValue ~= "boutique") then return end
--     isOpen = not isOpen
--     if isOpen then
--         setInInterface("boutique")
--     else
--         clearInterface()
--     end
    
--     if isOpen then
--         ESX.TriggerServerCallback('sBoutique:getPoints', function(coins, fidelity)
--             ESX.TriggerServerCallback('sBoutique:getIdboutique', function(fivemId)
--                 SendNUIMessage({
--                     type = 'boutique:show',
--                     logo = ESX.Config("serverCHAR"),
--                     serverName = ESX.Config("serverName")
--                 })
--                 null.DisplayHud(false)
--                 SetNuiFocus(true, true)
--                 SetNuiFocusKeepInput(false)
--                 --TriggerScreenblurFadeIn(1000)
--                 SendNUIMessage({
--                     type = 'boutique:updateUserInfo',
--                     data = {
--                         coins = coins,
--                         fidelity = fidelity,
--                         fivemId = fivemId or "Non lié"
--                     }
--                 })
--             end)
--         end) 
--     else
--         null.DisplayHud(true)
--         --TriggerScreenblurFadeOut(0)
--         SendNUIMessage({
--             type = 'boutique:hide'
--         })
--         SetNuiFocus(false, false)
--         SetNuiFocusKeepInput(true)
--         if inPreview then
--             StopPreview()
--         end
--     end
-- end

-- -- Notifications Boutique
-- function SendNotificationNui(message)
--     SendNUIMessage({
--         type = 'boutique:notification',
--         message = message
--     })
-- end

-- RegisterNetEvent("inventory:sendMessage")
-- AddEventHandler("inventory:sendMessage", function(message)
--     SendNotificationNui(message)
-- end)

-- -- Récupérer les items d'une catégorie
-- function GetCategoryItems(category)
--     local items = {}
    
--     if category == 'vehicles' then
--         for _, v in ipairs(Config.Boutique.Vehicles) do
--             table.insert(items, {
--                 label = v.label,
--                 model = v.model,
--                 price = v.price,
--                 description = v.description,
--                 stats = v.stats,
--                 video = false,
--                 image = "images/boutique/vehicles/"..v.model..".webp",
--             })
--         end
--     elseif category == 'weapons' then
--         for _, v in ipairs(Config.Boutique.Weapons) do
--             table.insert(items, {
--                 label = v.label,
--                 name = v.name,
--                 price = v.price,
--                 description = v.description,
--                 stats = v.stats,
--                 image = "images/boutique/weapons/"..v.name..".webp",
--             })
--         end
--     elseif category == 'crates' or category == 'cases' then
--         for k, v in pairs(Config.Boutique.Crates.List) do
--             if v.preview ~= false then
--                 local items_in_crate = Config.Boutique.Crates.List[k].Inside or {}
--                 local possibleItems = {}
                
--                 -- Construire la liste des items possibles pour l'UI
--                 for itemName, itemData in pairs(items_in_crate) do
--                     table.insert(possibleItems, {
--                         id = itemName,
--                         label = itemData.label or itemName,
--                         image = "images/items/"..itemName..".webp",
--                         rarity = itemData.rarity or 1
--                     })
--                 end
                
--                 items[v.position] = {
--                     id = k,
--                     label = v.label,
--                     name = k,
--                     buyable = v.buyable,
--                     price = v.price,
--                     five = v.five,
--                     teen = v.teen,
--                     image = "images/boutique/crates/"..k..".webp",
--                     description = v.description or "Ouvrez cette caisse pour obtenir un objet aléatoire !",
--                     possibleItems = possibleItems
--                 }
--             end
--         end
--     elseif category == 'packs' then
--         for k, v in pairs(Config.Boutique.Packs) do
--             items[v.index] = {
--                 label = v.label or k,
--                 type = k,
--                 price = v.price,
--                 image = "images/boutique/packs/"..k..".webp",
--                 description = v.description,
--                 info = v.info2
--             }
--         end
--     elseif category == 'boosts' then
--         for k, v in ipairs(Config.Boutique.Boosts) do
--             table.insert(items, {
--                 label = v.label,
--                 name = k,
--                 boostId = k,
--                 time = v.time,
--                 price = v.price,
--                 usableOn = "Récolte, Traitement, Vente, Drogues, Chantier, Chasse",
--                 image = "images/boutique/boosts/boost_"..k..".webp",
--                 description = string.format("Utilisable sur: %s\nDurée: %d heures", "Récolte, Traitement, Vente, Drogues, Chantier, Chasse", v.time)
--             })
--         end
--     end
    
--     return items
-- end

-- -- Prévisualisation des véhicules
-- function StartVehiclePreview(model)
--     -- Cacher le HUD
--     null.DisplayHud(false)
--     --TriggerScreenblurFadeOut(1000)
--     inPreview = true
--     BeforcePreviewCoords = GetEntityCoords(PlayerPedId())
--     -- Sauvegarder la position actuelle
--     local playerPed = PlayerPedId()
--     --local pos = GetEntityCoords(playerPed)
--     local pos = vec3(-290.816345, 1648.461304, -159.7)
--     local heading = GetEntityHeading(playerPed)
    

--     SetEntityVisible(playerPed, false, 0)
--     FreezeEntityPosition(playerPed, true)
--     SetEntityCollision(playerPed, false, false)
--     SetEntityInvincible(playerPed, true)

--     SetEntityCoords(playerPed, pos.x, pos.y, pos.z)
--     Wait(500)

--     previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
--     SetCamCoord(previewCam, -294.54629516602, 1651.7911376953, -159.02914428711)
--     SetCamRot(previewCam, -5.62162017822265, 0.0, -133.0, 2)
--     SetCamActive(previewCam, true)
--     RenderScriptCams(true, true, 1000, true, true)
--     Wait(200)
--     -- Créer le véhicule
--     ESX.Game.SpawnVehicle(model, pos, 47.98029708862305, function(vehicle)
--         SetEntityCoords(vehicle, pos.x, pos.y, pos.z)
--         SetVehicleOnGroundProperly(vehicle)
--         FreezeEntityPosition(vehicle, true)
--         SetVehicleDoorsLocked(vehicle, 2)

--         -- Sauvegarder les références
--         previewVehicle = vehicle
        
--         -- Afficher les contrôles
--         SendNUIMessage({
--             type = "boutique:startPreview"
--         })
--     end)
-- end

-- function StopPreview(fade)
--     if not inPreview then return end
--     local playerPed = PlayerPedId()
--     SetEntityCoords(playerPed, BeforcePreviewCoords.x, BeforcePreviewCoords.y, BeforcePreviewCoords.z)
--     BeforcePreviewCoords = nil
--     -- Supprimer le véhicule
--     ESX.Game.DeleteVehicle(previewVehicle)
--     previewVehicle = nil
--     -- Réinitialiser la caméra
--     if previewCam then
--         SetCamActive(previewCam, false)
--         RenderScriptCams(false, true, 1000, true, true)
--         DestroyCam(previewCam, true)
--         previewCam = nil
--     end

--     SetEntityVisible(playerPed, true, 0)
--     FreezeEntityPosition(playerPed, false)
--     SetEntityCollision(playerPed, true, false)
--     SetEntityInvincible(playerPed, false)

--     -- Réafficher le HUD
--     null.DisplayHud(true)
--     if fade then
--         --TriggerScreenblurFadeIn(1000)
--     end
--     inPreview = false
-- end

-- -- Callbacks NUI
-- RegisterNUICallback('boutique:getItems', function(data, cb)
--     if not data then return end
--     if data.category == "weapons-custom" then
--         ToggleBoutique()
--         OpenCustomArmes()
--     else
--         local items = GetCategoryItems(data.category)
--         SendNUIMessage({
--             type = 'boutique:displayItems',
--             items = items
--         })
--         cb('ok')
--     end
-- end)

-- RegisterNUICallback('boutique:preview', function(data, cb)
--     if data.type == 'vehicles' then
--         if not exports["null-core"]:GetSafeZone() then
--             ESX.ShowNotification("❌ Vous devez être en safezone.")
--             cb('ok')
--             return
--         end
--         StartVehiclePreview(data.item.model)
--         SendNUIMessage({
--             type = 'boutique:canPreview',
--             uniqueVeh = data.unique,
--         })
--     elseif data.type == 'crates' then
--         local crate_items = Config.Boutique.Crates.List[data.item.name].Inside or {}
--         for k,v in pairs(crate_items) do 
--             v.image = "images/boutique/crates/"..v.model..".webp"
--         end
--         SendNUIMessage({
--             type = 'boutique:displayCrateItems',
--             items = crate_items
--         })
--     end
--     cb('ok')
-- end)

-- RegisterNUICallback('boutique:rotate', function(data, cb)
--     if previewVehicle then
--         local currentHeading = GetEntityHeading(previewVehicle)
--         local newHeading = currentHeading + (data.direction == 'left' and -7 or 7)
--         SetEntityHeading(previewVehicle, newHeading)
--     end
--     cb('ok')
-- end)

-- RegisterNUICallback('boutique:stopPreview', function(data, cb)
--     StopPreview(true)
--     cb('ok')
-- end)

-- RegisterNUICallback('boutique:close', function(data, cb)
--     ToggleBoutique()
--     cb('ok')
-- end)

-- RegisterNUICallback('boutique:openCase', function(data, cb)
--     local caseId = data.caseId
    
--     -- Trouver la caisse dans la config
--     local caseData = nil
--     for k, v in pairs(Config.Boutique.Crates.List) do
--         if k == caseId then
--             caseData = v
--             caseData.name = k
--             break
--         end
--     end
    
--     if not caseData then
--         cb('ok')
--         return
--     end
    
--     -- Envoyer au serveur pour traiter l'achat et l'ouverture
--     TriggerServerEvent('sBoutique:openCaseWithAnimation', caseId)
--     cb('ok')
-- end)

-- RegisterNUICallback('buyItem', function(data, cb)
--     local category = data.category
--     local item = data.item
--     if category == 'crates' then
--         TriggerServerEvent('sBoutique:process_checkout_case', item.name, item.counter or 1)
--     elseif category == 'weapons' then
--         TriggerServerEvent('sBoutique:buyweapon', item.name, item.price, item.label)
--     elseif category == 'vehicles' then
--         TriggerServerEvent('sBoutique:BuyVehicle', item.model, item.price, item.label)
--     elseif category == 'boosts' then
--         TriggerServerEvent("Boostsystem:PlayerRequestToBuyBoost", item.name, item.time)
--     elseif category == 'packs' then
--         TriggerServerEvent('null:server:BuyPack', item.name)
--     end
--     cb('ok')
-- end)


-- RegisterCommand('menuboutique', function()
--     ToggleBoutique()
-- end)

-- RegisterCommand('boutique', function()
--     ToggleBoutique()
-- end)

-- RegisterKeyMapping('menuboutique', 'Ouvrir la boutique', 'keyboard', 'F1')


-- exports("ToggleBoutique", ToggleBoutique)
-- exports("IsInBoutique", function() return isOpen end)
-- exports("NotificationNUI", SendNotificationNui)

-- -- Event pour rafraîchir les coins après un achat
-- RegisterNetEvent('null:boutique:newCoinsAmount')
-- AddEventHandler('null:boutique:newCoinsAmount', function()
--     if isOpen then
--         ESX.TriggerServerCallback('sBoutique:getPoints', function(coins, fidelity)
--             SendNUIMessage({
--                 type = 'boutique:updateUserInfo',
--                 data = {
--                     coins = coins,
--                     fidelity = fidelity
--                 }
--             })
--         end)
--     end
-- end)

-- -- Event pour démarrer l'animation de caisse
-- RegisterNetEvent('boutique:startCaseSpin')
-- AddEventHandler('boutique:startCaseSpin', function(data)
--     SendNUIMessage({
--         type = 'boutique:startCaseSpin',
--         wonItem = data.wonItem,
--         allItems = data.allItems
--     })
-- end)





-- local picture
-- local mysterybox = RageUI.CreateMenu("", "Bonne chance !")
-- local finishLoad = false
-- local hasOthersCase = false
-- local caseModel = nil
-- local inCaseLoad = false

-- RegisterNetEvent('sBoutique:sCaisseOpenC')
-- AddEventHandler('sBoutique:sCaisseOpenC', function(animations, name, message, model)
--     -- Case not more allowed by Cfx
--     -- caseModel = model
--     -- inCaseLoad = true
--     -- OpenCaseThread()
--     -- RageUI.Visible(mysterybox, true)
--     -- finishLoad = false
--     -- ESX.PlayerData = ESX.GetPlayerData()
--     -- for k,v in pairs(ESX.PlayerData.inventory) do
--     --     if v.name == model then
--     --         hasOthersCase = true
--     --         break
--     --     end
--     -- end
--     -- mysterybox.Closable = false
--     -- mysterybox.Closed = function()
--     --     TriggerEvent('SHOW_IMAGE', false)
--     --     finishLoad = false
--     --     caseModel = nil
--     --     inCaseLoad = false
--     -- end
--     -- Citizen.Wait(0)
--     -- for k, v in pairs(animations) do
--     --     picture = ESX.GetImg("boutique_"..v.name)
--     --     print(picture)
--     --     if v.customUrl then
--     --         picture = v.url
--     --     end
--     --     RageUI.PlaySound("HUD_FREEMODE_SOUNDSET", "NAV_UP_DOWN")
--     --     if v.time == 5000 then
--     --         RageUI.PlaySound("HUD_AWARDS", "FLIGHT_SCHOOL_LESSON_PASSED")
--     --         ESX.ShowNotification(message)
--     --         finishLoad = true
--     --         Wait(1000)
--     --         mysterybox.Closable = true
--     --         Wait(3000)
--     --     end
--     --     Citizen.Wait(v.time)
--     -- end
-- end)

-- local threadCreated = false
-- function OpenCaseThread()
--     if threadCreated then return end
--     threadCreated = true
--     Citizen.CreateThread(function()    
--         while true do
--             if not inCaseLoad then 
--                 break 
--             end
--             Citizen.Wait(1)

--             RageUI.IsVisible(mysterybox, function()
--                 if hasOthersCase and finishLoad then
--                     RageUI.Button("Ouvrir une nouvelle caisse", nil, {}, true, {
--                         onSelected = function()
--                             TriggerEvent('SHOW_IMAGE', false)
--                             inCaseLoad = false
--                             RageUI.CloseAll()
--                             finishLoad = false
--                             Wait(1000)
--                             TriggerServerEvent('esx:useItem', caseModel)
--                         end
--                     })
--                 end
--             end, function()
--                 if picture then
--                     if finishLoad and hasOthersCase then
--                         RageUI.CaissePreviewOpen(picture, 200)
--                     else
--                         RageUI.CaissePreviewOpen(picture)
--                     end
--                 end
--             end)
--         end
--         threadCreated = false
--     end)
-- end

-- -- Ancienne Boutique RageUI
-- local selected = nil;

-- Citizen.CreateThread(function()
--     while (true) do
--         Citizen.Wait(1000)
--         local weapon = GetSelectedPedWeapon(PlayerPedId());
--         if (weapon ~= GetHashKey("weapon_unarmed")) and (weapon ~= 966099553) and (weapon ~= 0) then
--             if (selected ~= nil) and (weapon == GetHashKey("weapon_unarmed")) and (weapon == 966099553) and (weapon == 0) then
--                 selected = nil;
--             end
--             for i, v in pairs(ESX.GetWeaponList()) do
--                 if (GetHashKey(v.name) == weapon) then
--                     selected = v
--                 end
--             end
--         else
--             selected = nil;
--         end

--     end
-- end)

-- function OpenCustomArmes()
--     local BoutiqueSub = RageUI.CreateMenu('', "Que voulez-vous ?")
--     BoutiqueSub.onIndexChange = function(index)
--         if (selected ~= nil) then
--             GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(selected.name), selected.components[index].hash)
--             if (selected.components[index - 1] ~= nil) and (selected.components[index - 1].hash ~= nil) then
--                 RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(selected.name), selected.components[index - 1].hash)
--             end
--             if (index == 1) then
--                 RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(selected.name), selected.components[#selected.components].hash)
--             end
--         end
--     end
--     RageUI.Visible(BoutiqueSub, not RageUI.Visible(BoutiqueSub))
--     while BoutiqueSub do
--         Citizen.Wait(0)
--         RageUI.IsVisible(BoutiqueSub, function()
--             if (selected) then
--                 if (ESX.Table.SizeOf(selected) > 0) and selected.components ~= nil then
--                     for i, v in pairs(selected.components) do
--                         RageUI.Button(v.label, nil, { RightLabel = 250, RightBadge = RageUI.BadgeStyle.Coins }, true, {
--                             onSelected = function() 
--                                 local Confirm = ConfirmRequest("Etes vous sur ?")
--                                 if Confirm then
--                                     TriggerServerEvent('tebex:on-process-checkout-weapon-custom', selected.name, v.hash)
--                                     ESX.ShowNotification("Vous avez acheter "..v.label.." pour 250 Coins")
--                                 end
--                             end,
--                         })
--                     end
--                 else
--                     RageUI.Separator("Aucune personnalisation disponible")
--                 end
--             else
--                 RageUI.Separator("Vous n'avez pas d'arme dans vos main")
--             end
--         end, function()
--         end)

--         if not RageUI.Visible(BoutiqueSub) then
--             TriggerEvent('esx:restoreLoadout')
--             BoutiqueSub = RMenu:DeleteType('BoutiqueSub', true)
--         end
--     end
-- end

-- AddEventHandler("cstmMenu", function()
--     Wait(150)
--     RageUI.Visible(wp, true)
-- end)


-- -- Gestion des véhicules uniques pour la boutique
-- local uniqueVehicles = {}

-- -- Fonction pour récupérer les véhicules uniques depuis l'export
-- function GetUniqueVehicles()
--     local vehicles = exports["null-core"]:getUniqueVeh()
    
--     if vehicles and type(vehicles) == "table" then
--         uniqueVehicles = vehicles
--         return vehicles
--     else
--         print("Erreur: Impossible de récupérer les véhicules uniques ou format invalide")
--         return {}
--     end
-- end

-- -- Fonction pour envoyer les véhicules uniques à l'interface NUI
-- function SendUniqueVehiclesToNUI()
--     local vehicles = GetUniqueVehicles()
    
--     SendNUIMessage({
--         type = 'boutique:uniqueVehicles',
--         vehicles = vehicles
--     })
    
--     return vehicles
-- end

-- -- Callback pour récupérer les véhicules uniques depuis le NUI
-- RegisterNUICallback('getUniqueVehicles', function(data, cb)
--     local vehicles = SendUniqueVehiclesToNUI()
--     cb(vehicles)
-- end)

-- -- Callback pour acheter un véhicule unique
-- RegisterNUICallback('buyUniqueVehicle', function(data, cb)
--     if not data.vehicleId then
--         SendNotificationNui("Erreur: Identifiant de véhicule manquant")
--         cb({ success = false, message = "Identifiant de véhicule manquant" })
--         return
--     end
    
--     -- Déclencher l'événement serveur pour l'achat du véhicule unique
--     TriggerServerEvent('null:boutique:boughtUniqueVeh', data.vehicleId)
--     cb({ success = true })
-- end)

-- -- Ajouter les véhicules uniques lorsque la boutique est ouverte
-- RegisterNetEvent('boutique:opened')
-- AddEventHandler('boutique:opened', function()
--     SendUniqueVehiclesToNUI()
-- end)

-- -- Déclencher l'événement d'ouverture de la boutique quand la boutique s'ouvre
-- AddEventHandler('onClientResourceStart', function(resourceName)
--     if(GetCurrentResourceName() ~= resourceName) then
--         return
--     end
    
--     -- Hook into the existing ToggleBoutique function
--     local originalToggleBoutique = ToggleBoutique
--     if originalToggleBoutique then
--         ToggleBoutique = function()
--             originalToggleBoutique()
--             if isOpen then
--                 TriggerEvent('boutique:opened')
--             end
--         end
--     end
-- end)

-- -- Mettre à jour les véhicules uniques lorsqu'on change de catégorie vers "uniqueVehicles"
-- RegisterNUICallback('boutique:getItems', function(data, cb)
--     if data.category == 'uniqueVehicles' then
--         local vehicles = SendUniqueVehiclesToNUI()
--         cb(vehicles)
--     end
-- end)

-- -- Exporter les fonctions pour les utiliser dans d'autres ressources
-- exports("GetUniqueVehicles", GetUniqueVehicles)
-- exports("SendUniqueVehiclesToNUI", SendUniqueVehiclesToNUI)
