-- ============================================================
--  CarRental — Server
--  Gestion des locations: paiement, timer 30min, despawn auto
-- ============================================================

local ActiveRentals = {}

RegisterNetEvent('null:carrental:rent')
AddEventHandler('null:carrental:rent', function(model, price, plate, netId, paymentType)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Empêcher deux locations simultanées
    for _, rental in pairs(ActiveRentals) do
        if rental.source == source then
            TriggerClientEvent('esx:showNotification', source, "~r~Vous avez déjà un véhicule de location en cours")
            return
        end
    end

    -- Vérifier que le modèle existe dans la config
    local found = false
    for _, cat in pairs(Config.CarRental.categories) do
        for _, v in ipairs(cat.vehicles) do
            if v.model == model and v.price == tonumber(price) then
                found = true
                break
            end
        end
        if found then break end
    end

    if not found then
        DropPlayer(source, "Tentative de triche: véhicule de location invalide")
        return
    end

    -- Déterminer le compte à débiter
    local accountType = paymentType == "cash" and "cash" or "bank"

    -- Vérifier le solde
    local balance = tonumber(xPlayer.getAccount(accountType).money)
    if balance < tonumber(price) then
        TriggerClientEvent('esx:showNotification', source, "~r~Vous n'avez pas assez d'argent " .. (accountType == "cash" and "en cash" or "en banque"))
        return
    end

    -- Prélever le montant
    xPlayer.removeAccountMoney(accountType, tonumber(price), {
        title = 'Location Véhicule',
        description = 'Location: ' .. model,
        category = 'purchase'
    })

    -- Enregistrer la location
    local rentalId = tostring(source) .. "_" .. tostring(os.time())
    ActiveRentals[rentalId] = {
        source = source,
        model = model,
        plate = plate,
        netId = netId,
        startTime = os.time(),
        endTime = os.time() + Config.CarRental.duration,
    }

    -- Démarrer le timer côté client
    TriggerClientEvent('null:carrental:startTimer', source, Config.CarRental.duration)

    TriggerClientEvent('esx:showNotification', source, "[🚗] " .. price .. "$ ont été prélevés " .. (accountType == "cash" and "en cash" or "de votre compte en banque") .. ". Bonne route !")

    -- Timer serveur pour le despawn automatique
    SetTimeout(Config.CarRental.duration * 1000, function()
        local rental = ActiveRentals[rentalId]
        if not rental then return end

        -- Forcer le despawn du véhicule
        local vehicle = NetworkGetEntityFromNetworkId(rental.netId)
        if vehicle and DoesEntityExist(vehicle) then
            -- Éjecter tous les passagers
            local seatCount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
            for i = -1, seatCount - 2 do
                local ped = GetPedInVehicleSeat(vehicle, i)
                if ped and ped ~= 0 then
                    TaskLeaveVehicle(ped, vehicle, 0)
                end
            end
            Wait(2000)
            DeleteEntity(vehicle)
        end

        -- Notifier le joueur
        if GetPlayerName(source) then
            TriggerClientEvent('null:carrental:stopTimer', source)
            TriggerClientEvent('esx:showNotification', source, "~r~Votre location de véhicule est terminée.")
        end

        ActiveRentals[rentalId] = nil
    end)
end)

-- Nettoyer les locations quand un joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
    local source = source
    for rentalId, rental in pairs(ActiveRentals) do
        if rental.source == source then
            local vehicle = NetworkGetEntityFromNetworkId(rental.netId)
            if vehicle and DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            ActiveRentals[rentalId] = nil
        end
    end
end)

-- Nettoyage côté client (quand le timer client atteint 0)
RegisterNetEvent('null:carrental:cleanup')
AddEventHandler('null:carrental:cleanup', function()
    local source = source
    for rentalId, rental in pairs(ActiveRentals) do
        if rental.source == source then
            -- Tenter aussi le despawn côté serveur
            local vehicle = NetworkGetEntityFromNetworkId(rental.netId)
            if vehicle and DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            ActiveRentals[rentalId] = nil
        end
    end
end)

-- Commande admin pour forcer la fin d'une location
RegisterCommand('endrental', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() == 'user' then return end
    end

    local targetId = tonumber(args[1])
    if not targetId then return end

    for rentalId, rental in pairs(ActiveRentals) do
        if rental.source == targetId then
            local vehicle = NetworkGetEntityFromNetworkId(rental.netId)
            if vehicle and DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            TriggerClientEvent('null:carrental:stopTimer', rental.source)
            ActiveRentals[rentalId] = nil
            if source == 0 then
                print("^2[Null]^7 Location terminée pour le joueur " .. targetId)
            end
        end
    end
end, false)

-- ============================================================
--  StarterPack — Intégré au CarRental
-- ============================================================

StarterPack = {}

CreateThread(function()
    Wait(500)
    MySQL.Async.fetchAll("SELECT * FROM starterpack", {}, function(result)
        for k, v in pairs(result) do
            if not StarterPack[v.identifier] then
                StarterPack[v.identifier] = {}
            end
        end
    end)
end)

local function GeneratePlate()
    local plate = ""
    for i = 1, 6 do
        plate = plate .. '' .. math.random(0, 9)
    end
    return plate
end

RegisterNetEvent("Null:starterpack")
AddEventHandler("Null:starterpack", function(pack)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local Verif = StarterPack[xPlayer.identifier] and "take" or false

    if Config.StarterPack.Pack[pack] then
        if not Verif then
            StarterPack[xPlayer.identifier] = {}
            MySQL.Async.execute("INSERT INTO starterpack (identifier) VALUES (@identifier)", {
                ["@identifier"] = xPlayer.identifier
            })

            -- Armes
            if Config.StarterPack.Pack[pack]["Reward"].weapon then
                for k, v in pairs(Config.StarterPack.Pack[pack]["Reward"].weapon) do
                    xPlayer.addWeapon(v.name, 200)
                end
            end

            -- Items
            if Config.StarterPack.Pack[pack]["Reward"].items then
                for k, v in pairs(Config.StarterPack.Pack[pack]["Reward"].items) do
                    xPlayer.addInventoryItem(v.name, v.count)
                end
            end

            -- Cash
            if Config.StarterPack.Pack[pack]["Reward"].cash then
                xPlayer.addAccountMoney(Config.StarterPack.Money.cash, Config.StarterPack.Pack[pack]["Reward"].cash)
            end

            -- Véhicule
            if Config.StarterPack.Pack[pack]["Reward"].car then
                local Plate = GeneratePlate()
                SaveData.json["owned_vehicles"][string.upper(Plate)] = {
                    owner = xPlayer.identifier,
                    model = Config.StarterPack.Pack[pack]["Reward"].car,
                    plate = string.upper(Plate),
                    vehicle = {model = GetHashKey(Config.StarterPack.Pack[pack]["Reward"].car), plate = Plate},
                    label = Config.StarterPack.Pack[pack]["Reward"].car,
                    coffre = {},
                    type = "car",
                    state = true,
                    boutique = false,
                    garage = true,
                }
                if Config.StarterPack.KeySystem then
                    MySQL.Async.execute("INSERT INTO open_car (owner, plate) VALUES (@owner, @plate)", {
                        ["@owner"] = xPlayer.identifier,
                        ["@plate"] = Plate,
                    })
                end
            end

            TriggerClientEvent("esx:showNotification", source, Config.StarterPack.Pack[pack].Notification)

            -- Logs
            local Content = {
                {
                    ["author"] = {
                        ["name"] = "StarterPack",
                        ["icon_url"] = Config.StarterPack.Logs.Icon,
                    },
                    ["title"] = (Config.StarterPack.Logs.Content["Title"]):format(pack),
                    ["description"] = (Config.StarterPack.Logs.Content["Description"]):format(xPlayer.identifier, xPlayer.source, xPlayer.getIdunique()),
                    ["color"] = Config.StarterPack.Logs.Content["Colour"],
                    ["footer"] = {
                        ["text"] = "Logs Module",
                    }
                }
            }
            PerformHttpRequest(Config.StarterPack.Logs.WebHook, function() end, 'POST', json.encode({username = nil, embeds = Content}), {['Content-Type'] = 'application/json'})
        else
            TriggerClientEvent("esx:showNotification", source, "Vous avez déjà pris votre starterpack !")
        end
    else
        DropPlayer(source, Config.StarterPack.MessageBan)
    end
end)
