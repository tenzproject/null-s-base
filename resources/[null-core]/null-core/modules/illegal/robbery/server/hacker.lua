local talk = false
local WaitingDemandeForBraquage = {}
local WaitingPlayerForFinishDemande = {}
local BrinksSpawn = {}
local WaitingBrinksForFinish = {}

RegisterServerEvent("null:hacker:istalk", function (get, bool)
	if get then
        TriggerClientEvent("null:hacker:recevietalk", source, talk)
    else
        talk = bool
    end
end)

RegisterServerEvent("null:brinks:receviecoords", function(coords)
    local xPlayer = ESX.GetPlayerFromId(source)
	if BrinksSpawn[xPlayer.getIdunique()] == nil then return end

    BrinksSpawn[xPlayer.getIdunique()].position = coords
end)

RegisterServerEvent("null:brinks:everypedisdead", function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
	if BrinksSpawn[xPlayer.getIdunique()] == nil then return end

    TriggerClientEvent("null:braquage:brinks:openvehicle", -1)
    BrinksSpawn[xPlayer.getIdunique()].nbrPedAlive = 0
    Wait(5000)
    BrinksSpawn[xPlayer.getIdunique()].finish = true
    TriggerClientEvent("null:braquage:brinks:removeblips", -1)
    BrinksSpawn[xPlayer.getIdunique()] = nil
    local phonenumber = exports["lb-phone"]:GetEquippedPhoneNumber(source)
    exports["lb-phone"]:SendCoords("245-284", phonenumber, vec2(725.490112, -752.409119)) 
    exports["lb-phone"]:SendMessage("245-284", phonenumber, "Ramene le Brinks ICI (Fais attention a la Police)")
    WaitingBrinksForFinish[xPlayer.getIdunique()] = true
    TriggerClientEvent("null:braquage:brinks:initFin", source)
end)

RegisterServerEvent("null:brinks:finish", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if WaitingBrinksForFinish[xPlayer.getIdunique()] == nil then return end

    xPlayer.showNotification("Bien joué, att je te donne ta part")
    local total = math.random(Config.Robbery.BrinksRecompense[1], Config.Robbery.BrinksRecompense[2])
    xPlayer.addAccountMoney("dirtycash", total)
    xPlayer.showNotification("Braquage Brinks Fini.\nTotal : ~y~"..total.."$")

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:ProgressGangMission(gangname, "weekly_robbery_bank", 1)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_robbery_spree", 1)
        exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", total)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", total)
        exports["null-core"]:AddGangXP(gangname, 150)
    end
end)

RegisterServerEvent("null:brinks:updatepedalive", function(nbr)
    local xPlayer = ESX.GetPlayerFromId(source)
	if BrinksSpawn[xPlayer.getIdunique()] == nil then return end

    BrinksSpawn[xPlayer.getIdunique()].nbrPedAlive = nbr
end)

function FinishBraquageDemande(idu, source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local savedemande = WaitingDemandeForBraquage[idu]
    WaitingDemandeForBraquage[idu] = nil
    if Config.Phone.votre_telephone["lbphone"] then
        local phonenumber = exports["lb-phone"]:GetEquippedPhoneNumber(source)

        if savedemande.type == "Brinks" then
            if BrinksSpawn[idu] == nil then
                BrinksSpawn[idu] = {
                    idu = idu,
                    name = xPlayer.getName(),
                    position = vec3(934.05261230469, -3.533684015274, 78.763984680176),
                    nbrPedAlive = 4,
                    finish = false,
                }
            end
            TriggerClientEvent("null:braquage:brinks:spawn", -1)
            Wait(2*60*1000)
            exports["lb-phone"]:SendMessage("056-029", phonenumber, "Bonne nouvelle, d'apres mes infos un Camion brinks est sensé partir du casino, je ne connais pas la destination mais je crois qu'il va prendre l'autoroute.")
            Wait(6*60*1000) -- Faire attendre ()
            exports["lb-phone"]:SendMessage("056-029", phonenumber, "J'ai localiser le Brinks !")
            Wait(2000)
            exports["lb-phone"]:SendMessage("056-029", phonenumber, "Att je t'envois la pos dans, prépare toi")
            exports["lb-phone"]:SendCoords("056-029", phonenumber, vec2(1354.455078, 650.591003))
            exports["lb-phone"]:SendMessage("056-029", phonenumber, "D'apres mes infos, il devrait être ici dans 10 minutes, regarde sur le Panel Caméra pour avoir ca localisation exact")
            Wait(5000)
            TriggerClientEvent("null:braquage:brinks:PoliceNotify", -1) 
            Citizen.CreateThread(function ()
                while BrinksSpawn[idu] ~= nil and not BrinksSpawn[idu].finish do
                    if BrinksSpawn[idu] == nil then break end
                    TriggerClientEvent("null:braquage:brinks:PoliceBlip", -1, BrinksSpawn[idu].position)
                    Wait(30000)
                end
                print("[^5Null^7] Braquage Brinks Fini")
            end)
        elseif savedemande.type == "ROGER" then

        end
    elseif Config.Phone.votre_telephone["qs"] then

    else

    end
end

function initBraquageWaiting(source)
    Citizen.CreateThread(function ()
        if #WaitingDemandeForBraquage == nil then return end
        local originaltime = os.time()
        local xPlayer = ESX.GetPlayerFromId(source)
        local xPlayerIdU = xPlayer.getIdunique()
        local secondetonotif = WaitingDemandeForBraquage[xPlayerIdU].secondtowait
        local savedemande = WaitingDemandeForBraquage[xPlayerIdU]
        print("[^5Null^7] Demande de braquage effectuer (^5"..tostring(ESX.Math.Round(secondetonotif/60)).."^7 Minutes d'attente)")
        while (os.time() - originaltime) < (secondetonotif) do
            Wait(7000)
            WaitingDemandeForBraquage[xPlayerIdU].timepassed = WaitingDemandeForBraquage[xPlayerIdU].timepassed + 7
        end
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer == nil then
            print("[^5Null^7] Demande de braquage mise en attente (Joueur deconnecter)")
            WaitingPlayerForFinishDemande[xPlayerIdU] = savedemande
        else
            print("[^5Null^7] Demande de braquage fini (Temps fini)")
            FinishBraquageDemande(xPlayerIdU, xPlayer.source)
        end
    end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    if WaitingPlayerForFinishDemande[xPlayer.getIdunique()] ~= nil then
        WaitingPlayerForFinishDemande[xPlayer.getIdunique()] = nil
        Wait(3000)
        print("[^5Null^7] Demande de braquage fini (Joueur reconnnecter)")
        FinishBraquageDemande(xPlayer.getIdunique(), xPlayer.source)
    end
end)



ESX.RegisterServerCallback('null:hacker:payinfo', function(source, cb, infotype)
	local xPlayer = ESX.GetPlayerFromId(source)
    if WaitingDemandeForBraquage[xPlayer.getIdunique()] ~= nil then return end
    local price = Config.Robbery.HackerInfo[infotype]
    local phonenumber = exports["lb-phone"]:GetEquippedPhoneNumber(source)
    if xPlayer.getAccount("cash").money >= price then
        xPlayer.removeAccountMoney("cash", price)
        local item = xPlayer.getInventoryItem("camera")
        if item ~= nil and item.count > 0 then

        else
            xPlayer.addInventoryItem("camera", 1)
            xPlayer.showNotification("Je te prête mon Panel Camera, je te previens sur tu le perds tu me dois 15 000$")
        end
        WaitingDemandeForBraquage[xPlayer.getIdunique()] = {
            id = source,
            secondtowait = math.random(Config.Robbery.TempsAttenteBraquage[1], Config.Robbery.TempsAttenteBraquage[2]),
            phonenumber = phonenumber,
            name = xPlayer.getName(),
            type = infotype,
            time = os.time(),
            timepassed = 0,
        }
        initBraquageWaiting(source)
        cb(true)
    else
        cb(false)
    end
end)


ESX.RegisterServerCallback('null:hacker:GetDemande', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
    if WaitingDemandeForBraquage[xPlayer.getIdunique()] == nil then 
        cb(false) 
    else
        cb(true)
    end
end)


ESX.RegisterServerCallback('null:staff:hacker', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    cb(WaitingDemandeForBraquage, WaitingPlayerForFinishDemande, BrinksSpawn)
end)