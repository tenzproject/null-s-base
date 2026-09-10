local BlackOutIsActive = false
local reportsTable = {}
local DayOfWeek = nil
reportsCount = 0
reportsTotal = 0
reportsTotalCount = 0
reportsNoTraiter = 0
stafflist = {}
StreamersModeActive = {}

--[[

Made By Null
25-06-2024

]]

local heavyFields = { inventory = true, loadout = true, clothes_equiped = true }

-- Compteurs de session pour les gamertags staff (reset au restart serveur)
-- Indexés par idunique
PlayerKillStats = PlayerKillStats or {}     -- { [idu] = { kills = 0, deaths = 0, lastKillAt = 0 } }
PlayerReportStats = PlayerReportStats or {} -- { [idu] = { totalMade = 0 } }

local function ensureKillStats(idu)
	if not idu then return nil end
	if not PlayerKillStats[idu] then
		PlayerKillStats[idu] = { kills = 0, deaths = 0, lastKillAt = 0 }
	end
	return PlayerKillStats[idu]
end

local function ensureReportStats(idu)
	if not idu then return nil end
	if not PlayerReportStats[idu] then
		PlayerReportStats[idu] = { totalMade = 0 }
	end
	return PlayerReportStats[idu]
end

local function refreshIduForStaff(idu)
	if not idu then return end
	local p = ESX.PlayersByIdUnique and ESX.PlayersByIdUnique[idu]
	if p and p.source and ESX.ScheduleAdminRefresh then
		ESX.ScheduleAdminRefresh(p.source)
	end
end

-- Anti-doublon: plusieurs chemins peuvent déclencher l'incrémentation (logs/playerDied,
-- ambulance EMS:UpdateTableIsDead, etc). On dédoublonne par couple (killer→victim)
-- pendant une courte fenêtre.
local _lastKillIncrementAt = {} -- [killerIdu .. ">" .. victimIdu] = ms
local KILL_DEDUP_WINDOW_MS = 8000

function NullIncrementKillStat(killerIdu, victimIdu)
	local now = GetGameTimer()
	local key = tostring(killerIdu or "?") .. ">" .. tostring(victimIdu or "?")
	local last = _lastKillIncrementAt[key]
	if last and (now - last) < KILL_DEDUP_WINDOW_MS then
		return
	end
	_lastKillIncrementAt[key] = now

	if killerIdu and killerIdu ~= victimIdu then
		local s = ensureKillStats(killerIdu)
		s.kills = (s.kills or 0) + 1
		s.lastKillAt = os.time()
		refreshIduForStaff(killerIdu)
	end
	if victimIdu then
		local s = ensureKillStats(victimIdu)
		s.deaths = (s.deaths or 0) + 1
		refreshIduForStaff(victimIdu)
	end
end

function NullIncrementReportMade(idu)
	if not idu then return end
	local s = ensureReportStats(idu)
	s.totalMade = (s.totalMade or 0) + 1
	refreshIduForStaff(idu)
end

local function countActiveReportsByIdu(idu)
	local n = 0
	for _, r in pairs(reportsTable) do
		if r and r.idu == idu then n = n + 1 end
	end
	return n
end

local function getLightPlayerData(xPlayerData)
	if xPlayerData == nil then return nil end
	local light = {}
	for k, v in pairs(xPlayerData) do
		if type(v) ~= "function" and not heavyFields[k] then
			light[k] = v
		end
	end
	-- Stats staff (gamertag avancé)
	local idu = light.idunique
	if idu then
		local ks = PlayerKillStats[idu]
		light.staffKills = ks and ks.kills or 0
		light.staffDeaths = ks and ks.deaths or 0
		local rs = PlayerReportStats[idu]
		light.staffReportsMade = rs and rs.totalMade or 0
		light.staffReportsActive = countActiveReportsByIdu(idu)
	end
	return light
end

local function getLightAllPlayers(playersByIdUnique)
	local result = {}
	for idunique, data in pairs(playersByIdUnique) do
		result[idunique] = getLightPlayerData(data)
	end
	return result
end

ESX.RegisterServerCallback('null:admin:getPlayerInventory', function(source, cb, targetIdUnique)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer or xPlayer.getGroup() == "user" then return cb(nil, nil) end
	local target = ESX.GetPlayerFromIdUnique(targetIdUnique)
	if not target then return cb({}, {}) end
	cb(target.inventory, target.loadout)
end)

RegisterNetEvent("AdminMenu:checkIsAdmin")
AddEventHandler("AdminMenu:checkIsAdmin", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local playerGroup = xPlayer.getGroup()

    if xPlayer.getGroup() ~= "user" then
        TriggerClientEvent("AdminMenu:checkIsAdminOk", _src, Config.GroupeGrade[playerGroup:lower()], xPlayer.getGroup())
    end
end)

RegisterNetEvent("null:staff:activeStreamerMode", function(bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if bool == false then bool = nil end
    StreamersModeActive[xPlayer.getIdunique()] = bool
end)

--[[RegisterNetEvent("AdminMenu:atazone")
AddEventHandler("AdminMenu:atazone", function(radius, time)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local playerGroup = xPlayer.getGroup()

    if xPlayer.getGroup() ~= "user" then
        local plyinzone = ESX.Game.GetClosestPlayerInRadius(xPlayer.getCoords(),radius)
        
        for k,v in pairs(plyinzone) do
            TriggerEvent("ata:server:staff:updateNoCane", v.id, time)
        end
    end
end)]]

--[[RegisterCommand("unban", function(source, args)
    if source == 0 then
        if Config.Anticheat.votre_anticheat["WaveShield"] == true then
            exports["WaveShield"]:unbanPlayer(args[1])
        end
        print("vous avez débanni")
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
            if args[1] ~= nil then
                ESX.ShowNotification("Vous avez debanni "..args[1])
                if Config.Anticheat.votre_anticheat["WaveShield"] == true then
                    exports["WaveShield"]:unbanPlayer(args[1])
                end
            else
                ESX.ShowNotification("Mauvaise formulation !")
            end
        end
    end
end)]]

RegisterNetEvent("AdminMenu:waveshield:ban")
AddEventHandler("AdminMenu:waveshield:ban", function(time,target,raison)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local playerGroup = xPlayer.getGroup()

    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        ESX.ShowNotification("Vous avez banni "..target)
        exports["WaveShield"]:banPlayer(target, time, "Si vous pensez que c'est une erreur, veuillez faire un ticket", "Main", raison) 
    else
        ESX.ShowNotification("Vous n'avez pas les permissions require")
    end
end)

RegisterNetEvent("AdminMenu:updatestaffactif")
AddEventHandler("AdminMenu:updatestaffactif", function(bool)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local idunique = xPlayer.getIdunique()

    if xPlayer.getGroup() ~= "user" and ESX.PlayersByIdUnique[idunique] ~= nil then
        local finalservicemsg = "pris"
        if bool then
            finalservicemsg = "pris"
            null.logs.send("Staff",xPlayer.getName().."~s~ a pris son service", "prise-service", {idunique = idunique, name = xPlayer.getName()})
        else
            finalservicemsg = "quitter"
            null.logs.send("Staff",xPlayer.getName().."~s~ a quitter son service", "quitte-service", {idunique = idunique, name = xPlayer.getName()})
        end
        xPlayer.setStaffMode(bool)
        notifStaff("Le staff "..ESX.Config("serverColor")..xPlayer.getName().."~s~ a "..finalservicemsg.." sont service", xPlayer.source)

        ESX.PlayersByIdUnique[idunique].staffmode = bool
        if stafflist[idunique] then
            stafflist[idunique].staffmode = bool
        else
            --null.DebugPrint("[admin server] [AdminMenu:updatestaffactif] ^1 aucun staff[n] pour ", idunique or "N/A", "impossible donc de l'actualiser.")
            stafflist[xPlayer.getIdunique()] = {
                group = xPlayer.getGroup(),
                source = xPlayer.source,
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                nbrReport = 0,
                staffmode = bool,
            }
        end

        --refreshPlayer(_src, "forAllStaff")
        --refreshStaffMode(_src, "forAllStaff", bool)
        
        refreshPlayer(_src, "forAllStaff", false)

        -- TriggerClientEvent("null:admin:staffCountUpdate", -1, getStaffInServiceCount())
    end
end)

RegisterServerEvent('Yvelt:VehicleActionServer')
AddEventHandler('Yvelt:VehicleActionServer', function(action, veh, arg1, arg2)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() ~= "user" then
        TriggerClientEvent('Yvelt:reciveActionVeh', -1, action, veh, arg1)
    end
end)

CreateThread(function()
    Wait(10000)
    local xPlayers = ESX.GetPlayers();
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i]);
        if xPlayer.getGroup() ~= "user" then
            stafflist[xPlayer.getIdunique()] = {
                group = xPlayer.getGroup(),
                source = xPlayer.source,
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                nbrReport = 0,
                staffmode = false,
            }
        end
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    SaveData.Admin.PlayersBlips[xPlayer.idunique] = GetEntityCoords(GetPlayerPed(xPlayer.source))
    if xPlayer.getGroup() ~= "user" then
        stafflist[xPlayer.idunique] = {
            group = xPlayer.getGroup(),
            source = xPlayer.source,
            idunique = xPlayer.idunique,
            name = xPlayer.getName(),
            nbrReport = 0,
            staffmode = false,
        }
        null.DebugPrint("Init Staff:",xPlayer.getIdunique())
    end

    TriggerClientEvent("null:admin:addPlayer", -1, xPlayer.idunique, getLightPlayerData(ESX.PlayersByIdUnique[xPlayer.idunique]), stafflist[xPlayer.idunique])
    TriggerClientEvent('null:reports:refreh', source, reportsTable)
end)

AddEventHandler('playerDropped', function(reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil then return end

    if reportsTable[source] ~= nil then
        reportsTable[source] = nil
        TriggerClientEvent('null:reports:refreh', -1, reportsTable)
    end

    SaveData.Admin.PlayersBlips[xPlayer.idunique] = nil
    stafflist[xPlayer.idunique] = nil
    TriggerClientEvent("null:admin:addPlayer", -1, xPlayer.idunique, nil, stafflist[xPlayer.idunique])
end)

local NumberPlayerTotalCached = nil
RegisterNetEvent("null:admin:staffinit")
AddEventHandler("null:admin:staffinit", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not NumberPlayerTotalCached then
        NumberPlayerTotalCached = ESX.Table.SizeOf(SaveData.Players.Offline.List)
    end
    TriggerClientEvent('null:admin:allrefresh', source, getLightAllPlayers(ESX.PlayersByIdUnique), reportsTable, stafflist, NumberPlayerTotalCached)
end)

RegisterNetEvent("null:admin:restart")
AddEventHandler("null:admin:restart", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end

    TriggerClientEvent('null:admin:restart', -1, getLightAllPlayers(ESX.PlayersByIdUnique), reportsTable)
end)


RegisterNetEvent("null:admin:refresh:server")
AddEventHandler("null:admin:refresh:server", function(target, type)
    Wait(1000)
    if source == 0 then
        refreshPlayer(target, type)
    else
        refreshPlayer(target, type)
    end
end)

function getStaffInServiceCount()
    local count = 0
    for k, v in pairs(stafflist) do
        if v.staffmode == true then
            count = count + 1
        end
    end
    return count
end

function refreshPlayer(target, type, Init)
    local xTarget = ESX.GetPlayerFromId(target)
    if xTarget == nil then return end
    if Init == nil then Init = true end
    local targetIdunique = xTarget.getIdunique()
    if ESX.PlayersByIdUnique[targetIdunique] == nil then return end
    local lightData = getLightPlayerData(ESX.PlayersByIdUnique[targetIdunique])
    if type == "forAll" then
        TriggerClientEvent("null:admin:refreshOnePlayer", -1, targetIdunique, lightData)
    elseif type == "forMe" then
        TriggerClientEvent("null:admin:refreshOnePlayer", source, targetIdunique, lightData)
    elseif type == "forAllStaff" then
        local staffCount = getStaffInServiceCount()
        for k,v in pairs(ESX.PlayersByIdUnique) do
            if v.permission_group == "user" then goto continue end
            TriggerClientEvent("null:admin:refreshOnePlayer", v.source, targetIdunique, lightData)
            TriggerClientEvent("null:admin:staffCountUpdate", v.source, staffCount)
            ::continue::
        end
    elseif type == "forAnyone" then

    else
        TriggerClientEvent("null:admin:refreshOnePlayer", -1, targetIdunique, lightData)
    end
end

RegisterNetEvent("null:staff:changegamertag", function(bool, oldbool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    local idunique = xPlayer.getIdunique()
    if ESX.PlayersByIdUnique[idunique].gamertag == bool then return end

    xPlayer.setGamertag(bool)

    refreshPlayer(xPlayer.source, "forAllStaff", false)
end)

RegisterNetEvent("null:admin:demanderefreshallplayerforme")
AddEventHandler("null:admin:demanderefreshallplayerforme", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end
    --[[local xPlayers = ESX.GetPlayers();
    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i]);
        ESX.PlayersByIdUnique[xPlayer.getIdunique()] = InitPlayersTable(xPlayer)
        if xPlayer.getGroup() ~= "user" then
            stafflist[xPlayer.getIdunique()] = {
                group = xPlayer.getGroup(),
                source = xPlayer.source,
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                nbrReport = 0,
                staffmode = ESX.PlayersByIdUnique[xPlayer.getIdunique()].staffmode,
            }
        end
    end]]

    TriggerClientEvent("null:player:refreh", source, getLightAllPlayers(ESX.PlayersByIdUnique))
end)

RegisterNetEvent("null:detectrppack:staff:setHave", function(pack)
    -- local xPlayer = ESX.GetPlayerFromId(pack)
    -- if ESX.PlayersByIdUnique[xPlayer.getIdunique()] == nil then return end

    -- ESX.PlayersByIdUnique[xPlayer.getIdunique()].havegfpack = true
    -- for k,v in pairs(ESX.Players) do
    --     local xPlayer = ESX.GetPlayerFromId(v.source)
    --     if xPlayer == nil then goto continue end
    --     if xPlayer.getGroup() == "user" then goto continue end

    --     TriggerClientEvent("null:admin:refreshOnePlayer", v.source, xPlayer.getIdunique(), ESX.PlayersByIdUnique[xPlayer.getIdunique()])
    --     ::continue::
    -- end
end)


ESX.RegisterServerCallback("null:staff:getPlayerInstance", function(source, cb, target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    if xPlayer.getGroup() == "user" then cb(nil) return end
    cb(null.fct.instance.Get(xTarget.source))
end)


RegisterNetEvent("null:staff:deleteownedveh:plate")
AddEventHandler("null:staff:deleteownedveh:plate", function(plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= true then return end
    SaveData.json["owned_vehicles"][plate] = nil
end)

ESX.RegisterServerCallback("null:staff:getplayerVeh", function(source, cb, target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xPlayer == nil then cb({}) end
    if xTarget == nil then cb({}) end
    if xPlayer.getGroup() == "user" then cb({}) end
    
    local ownedCars = {}
	local ownedCarsJobs = {}
	local OwnedCarsOrg = {}

    for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if v.owner == xTarget.identifier then
			table.insert(ownedCars, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		elseif v.owner == xTarget.job.name then
			table.insert(ownedCarsJobs, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		elseif v.owner == xTarget.job2.name then
			table.insert(OwnedCarsOrg, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		end
	end

	cb(ownedCars, ownedCarsJobs, OwnedCarsOrg)
end)

ESX.RegisterServerCallback("null:staff:getplayerVehIdUnique", function(source, cb, identifier, job, job2)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer == nil then cb({}) end
    if xPlayer.getGroup() == "user" then cb({}) end
    
    local ownedCars = {}
	local ownedCarsJobs = {}
	local OwnedCarsOrg = {}
    for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if v.owner == identifier then
			table.insert(ownedCars, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		end
	end
    cb(ownedCars, ownedCarsJobs, OwnedCarsOrg)
end)

ESX.RegisterServerCallback("null:staff:getsocietyVeh", function(source, cb, name)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer == nil then cb({}) end
    if xPlayer.getGroup() == "user" then cb({}) end
    
    local ownedCars = {}
    for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if v.owner == name then
            table.insert(ownedCars, {garageid = v.garage, owner = v.owner, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
        end
    end
    cb(ownedCars)
end)

ESX.RegisterServerCallback("AdminMenu:getCashList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if xPlayer == nil then return end
    if xPlayer.getGroup() == "user" then return end
    cb({})
end)

ESX.RegisterServerCallback("null:admin:gethistoconnexion", function(source, cb, idu)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer == nil then return end
    if xPlayer.getGroup() == "user" then return end
    local tosend = {}
    for k,v in pairs(SaveData.json["deco-reco"]) do
        if v.idunique == idu then
            table.insert(tosend, v)
        end
    end


    cb(tosend)
    --[[MySQL.Async.fetchAll('SELECT * FROM vhistorycodeco WHERE idu = @idu',{
        ['@idu'] = idu,
    }, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb({})
        end
    end)]]
end)

ESX.RegisterServerCallback("null:admin:changeweaponacc", function(source, cb, idunique,weaponname, accname, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then cb(false) end
    if ESX.PlayersByIdUnique[idunique] == nil then cb(false) end
    local xTarget = ESX.GetPlayerFromId(ESX.PlayersByIdUnique[idunique].source)
    local theweapon = nil
    for k,v in pairs(ESX.PlayersByIdUnique[idunique].loadout) do
        if v.name == weaponname then
            theweapon = v
            break
        end
    end
    if theweapon == nil then cb(false) end
    if theweapon.components == nil then cb(false) end
    if #theweapon.components == 0 then cb(false) end
    if type == "remove" then
        local found = false
        for k,v in pairs(theweapon.components) do
            if v == accname then
                found = true
                xTarget.removeWeaponComponent(theweapon.name, v)
                cb(true)
            end
        end
        if not found then cb(false) end
    elseif type == "add" then
        local theWeapon1, theWeapon2 = ESX.GetWeapon(weaponname)
        local found = false
        for k,v in pairs(theWeapon2.components) do
            if v == accname then
                found = true
            end
        end
        if not found then cb(false) end
        xTarget.addWeaponComponent(theweapon.name, accname)
        cb(true)
    end
    cb(false)
end)

Citizen.CreateThread(function()
    local DayOfWeek = os.date("%W")
    if DayOfWeek == 1 then
        print("^7[^4Null^7] Nous sommes un "..os.date("%A").." il y a donc un reset des reports de la semaine")
        for k,v in pairs(SaveData.Admin.Staffs.List) do
            SaveData.Admin.Staffs.List[v.idunique].nbrReport_take_week = 0
            SaveData.Admin.Staffs.List[v.idunique].nbrReport_close_week = 0
            MySQL.Async.execute("UPDATE `staff` SET `nbrReport_take_week` = @nbrReport_take_week WHERE `idunique` = @idunique", {['@nbrReport_take_week'] = '0', ['@idunique'] = v.idunique}, function()  end)
            MySQL.Async.execute("UPDATE `staff` SET `nbrReport_close_week` = @nbrReport_close_week WHERE `idunique` = @idunique", {['@nbrReport_close_week'] = '0', ['@idunique'] = v.idunique}, function()  end)
        end
    end
    print("^7[^4Null^7] Nous sommes un "..os.date("%A").." il n'y a donc pas de reset des reports de la semaine")
end)

local WlEvalStaff = {[0] = true,[1] = true, [2] = true, [3] = true, [4] = true, [5] = true}


ESX.RegisterServerCallback("null:admin:getHistoEvalStaff", function(source, cb, idunique)
    xPlayer = ESX.GetPlayerFromId(source) 
    if xPlayer.getGroup() == "user" then cb({}) return end
    MySQL.Async.fetchAll('SELECT * FROM vhistoevalstaff WHERE idunique = @idunique', {['@idunique'] = idunique}, function(result)
        local finalResult = {}
        for k,v in pairs(result) do
            finalResult[v.id] = v
            if SaveData.Admin.Staffs.List[v.staffidunique] ~= nil then
                finalResult[v.id].staffname = SaveData.Admin.Staffs.List[v.staffidunique].name
            else
                finalResult[v.id].staffname = "Inconnu"
            end
        end
        cb(finalResult)
    end)
end)

RegisterNetEvent("null:admin:change-evalstaff")
AddEventHandler("null:admin:change-evalstaff", function(idunique,new, thereason, old)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if WlEvalStaff[new] ~= true then return end
    player = ReturnPlayerId(idunique) or {id = 0}
    local xTarget = ESX.GetPlayerFromId(player.id)
    if xTarget ~= nil then 
        xTarget.setEval(new) 
        refreshPlayer(player.id)
    end
    MySQL.Async.execute("UPDATE `users` SET `eval_staff` = @eval_staff WHERE `idunique` = @idunique", {['@eval_staff'] = new, ['@idunique'] = idunique}, function()  end)
    LiteMySQL:Insert('vhistoevalstaff', {
        idunique = xTarget.getIdunique(),
        reason = thereason or "Inconnu",
        staffidunique = xPlayer.getIdunique(),
        neweval = new,
        oldeval = old,
        date = os.date("%Y/%m/%d %X"),
    });    
end)

RegisterNetEvent("null:staff:setInstance")
AddEventHandler("null:staff:setInstance", function(target,newinstace)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    null.fct.instance.Set(target, newinstace)
end)

RegisterNetEvent("null:staff:resetReportWeekly")
AddEventHandler("null:staff:resetReportWeekly", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)
    if Config.GroupeHighPerm[xPlayer.getGroup()] == nil then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end

    for k,v in pairs(SaveData.Admin.Staffs.List) do
        SaveData.Admin.Staffs.List[v.idunique].nbrReport_take_week = 0
        SaveData.Admin.Staffs.List[v.idunique].nbrReport_close_week = 0
        MySQL.Async.execute("UPDATE `staff` SET `nbrReport_take_week` = @nbrReport_take_week WHERE `idunique` = @idunique", {['@nbrReport_take_week'] = '0', ['@idunique'] = v.idunique}, function()  end)
        MySQL.Async.execute("UPDATE `staff` SET `nbrReport_close_week` = @nbrReport_close_week WHERE `idunique` = @idunique", {['@nbrReport_close_week'] = '0', ['@idunique'] = v.idunique}, function()  end)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getStaffListOffline", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local staffListe = {}

    local stafflistonline = {}

    for k,v in pairs(ESX.PlayersByIdUnique) do
        local xPlayer = ESX.GetPlayerFromId(v.source);
        if xPlayer.getGroup() ~= "user" then
            table.insert(stafflistonline, {
                group = xPlayer.getGroup(),
                source = xPlayer.source,
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                staffmode = v.staffmode
            })
        end
    end

    if xPlayer ~= nil then
        local maxReportsWeek = -1
        local topStaffWeek = {}
        for k, v in pairs(SaveData.Admin.Staffs.List) do
            local online = false
            local staffmode = false
            if v.nbrReport_take_week + v.nbrReport_close_week > maxReportsWeek then
                maxReportsWeek = v.nbrReport_take_week + v.nbrReport_close_week
                topStaffWeek = {name=v.name,idu=v.idu,nbrReport=v.nbrReport,nbrReport_take_week=v.nbrReport_take_week,nbrReport_close_week=v.nbrReport_close_week}
            end
            for k, x in pairs(stafflistonline) do
                if x.idunique == v.idunique then
                    online = true
                    staffmode = x.staffmode
                end
            end
            table.insert(staffListe, {
                group = v.permission_group,
                identifier = v.identifier,
                discord = v.discord,
                name = v.name,
                idu = v.idunique,
                online = online,
                nbrReport = v.nbrReport,
                nbrReport_take_week = v.nbrReport_take_week,
                nbrReport_close_week = v.nbrReport_close_week,
                staffmode = staffmode,
            })
        end
        cb(staffListe, topStaffWeek)
    end
end)


ESX.RegisterServerCallback("AdminMenu:getBanList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local BanListe = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM fireac_banlist', {
        }, function(result)
            for k, v in pairs(result) do
                table.insert(BanListe, {
                    banid = v.BANID,
                    raison = v.REASON,
                    license = v.LICENSE,
                    name = v.name,
                    note = v.Note
                })
            end
            cb(BanListe)
        end)
    end
end) 

ESX.RegisterServerCallback("AdminMenu:getEntreprise", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local Entreprise = {}
    local EntrepriseAll = {
        ["Mécano"] = {},
        ["Bar"] = {},
        ["Ambulance"] = {},
        ["Police"] = {},
        ["Farm"] = {},
        ["Restaurant"] = {},
    }
    while SaveData.json == nil do Wait(10) end
    while SaveData.json["entreprises"] == nil do Wait(10) end
    if xPlayer ~= nil then
        if xPlayer.getGroup() ~= "user" then
            for k,v in pairs(SaveData.json["entreprises"]["Farm"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Farm"][v.name] = v
            end
            for k,v in pairs(SaveData.json["entreprises"]["Mécano"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Mécano"][v.name] = v
            end
            for k,v in pairs(SaveData.json["entreprises"]["Bar"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Bar"][v.name] = v
            end
            for k,v in pairs(SaveData.json["entreprises"]["Police"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Police"][v.name] = v
            end
            for k,v in pairs(SaveData.json["entreprises"]["Ambulance"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Ambulance"][v.name] = v
            end
            for k,v in pairs(SaveData.json["entreprises"]["Restaurant"]) do
                Entreprise[v.name] = v
                EntrepriseAll["Restaurant"][v.name] = v
            end
            cb(Entreprise, EntrepriseAll)
        end
    end
end)

ESX.RegisterServerCallback("AdminMenu:getBanList2", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local BanListe = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM banlist', {
        }, function(result)
            for k, v in pairs(result) do
                table.insert(BanListe, {
                    raison = v.reason,
                    license = v.licenseid,
                    sourceplayername = v.sourceName,
                    targetplayername = v.targetName,
                    expiration = v.expiration,
                    permanent = v.permanent
                })
            end
            cb(BanListe)
        end)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getJailList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local JailListe = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM vjails', {
        }, function(result)
            for k, v in pairs(result) do
                table.insert(JailListe, {
                    raison = v.raison,
                    license = v.identifier,
                    staffname = v.staffname,
                    sourcename = v.sourcename,
                    time = v.time
                })
            end
            cb(JailListe)
        end)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getTenueList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local TenueListe = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM vclothes', {
        }, function(result)
            for k, v in pairs(result) do
                if v.type == "shoes" or v.type == "pants" or v.type == "top" then
                    table.insert(TenueListe, {
                        id = v.id,
                        label = v.name,
                        type = v.type,
                        skin = json.decode(v.data) or {}
                    })
                end
            end
            cb(TenueListe)
        end)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getAccsList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local TenueListe = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM vclothes', {
        }, function(result)
            for k, v in pairs(result) do
                if v.type ~= "shoes" and v.type ~= "pants" and v.type ~= "top" then
                    table.insert(TenueListe, {
                        id = v.id,
                        label = v.name,
                        type = v.type,
                        skin = json.decode(v.data) or {}
                    })
                end
            end
            cb(TenueListe)
        end)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getOwnedVehList", function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local vehListe = {}
    if xPlayer ~= nil then
        vehListe = {}
        for k, v in pairs(SaveData.json["owned_vehicles"]) do
            local vehicle = v.vehicle
            local modelvehicle = vehicle.model
            vhBBoutique = "???"
            vhSState = "???"

            if v.boutique == true then 
                vhBBoutique = "Oui"
            elseif v.boutique == false then 
                vhBBoutique = "Non"
            end
            if v.state == true then 
                vhSState = "Oui"
            elseif v.state == false then 
                vhSState = "Non"
            end
            table.insert(vehListe, {
                owner = v.owner,
                plate = v.plate,
                type = v.type,
                vehicle = vehicle,
                model = modelvehicle,
                state = vhSState,
                label = v.label,
                boutique = vhBBoutique
            })
            model = vehicle.model
        end
        cb(vehListe)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getItemOnDtb", function(source, cb, onlyboutique)
    local itemTable = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        if xPlayer ~= nil then
            for k, v in pairs(ESX.GetItemList()) do
                if onlyboutique == true then
                    if not ESX.ContribItem(v.name) then
                        goto continue
                    end
                elseif onlyboutique == false then
                    if ESX.ContribItem(v.name) then
                        goto continue
                    end
                end
                if v.name == nil then
                    v.name = v.label
                end
                if v.label == nil then
                    v.label = v.name
                end
                table.insert(itemTable, {name = v.name, label = v.label})
                ::continue::
            end
            cb(itemTable)
        end
    end
end)

ESX.RegisterServerCallback("AdminMenu:getWeapon", function(source, cb, onlyboutique)
    local weapon = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        if xPlayer ~= nil then
            for k, v in pairs(ESX.GetWeaponList()) do
                if onlyboutique == true then
                    if not ESX.ContribWeapon(v.name) then
                        goto continue
                    end
                elseif onlyboutique == false then
                    if ESX.ContribWeapon(v.name) then
                        goto continue
                    end
                end
                table.insert(weapon, {name = v.name, label = v.label})
                ::continue::
            end
            cb(weapon)
        end
    end
end)

ESX.RegisterServerCallback("AdminMenu:getAllJobs", function(source, cb)
    local allJobs = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        MySQL.Async.fetchAll("SELECT * FROM jobs", {
        }, function(data)
            for _, v in pairs(data) do
                table.insert(allJobs, {
                    NameSociety = v.name,
                    LabelSociety = v.label})
            end
            cb(allJobs)
        end)
    end
end)


ESX.RegisterServerCallback("AdminMenu:getJobsGrades", function(source, cb, jobName)
    local gradeJobs = {}

    MySQL.Async.fetchAll("SELECT * FROM job_grades WHERE job_name = @job_name", {['job_name'] = jobName}, function(data)
        for _,v in pairs(data) do
            table.insert(gradeJobs, {
                gradeJob = v.grade,
                gradeLabel = v.label
            })
        end
        cb(gradeJobs)
    end)
end)

ESX.RegisterServerCallback('null:GetIDUnique', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier',{
            ['@identifier'] = xPlayer.identifier,
            ['@idunique'] = xPlayer.idunique,
        }, function(result)
            if result[1].idunique ~= nil then
                cb(result[1].idunique)
            else
                cb()
            end
        end)
    end
end)

ESX.RegisterServerCallback('null:GetMyIDUnique', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        cb(xPlayer.getIdunique())
    end
end)

ESX.RegisterServerCallback('null:GetIDUnique2', function(source, cb, player)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer ~= nil then
        cb(xPlayer.getIdunique())
    end
end)

ESX.RegisterServerCallback('null:GetByIDUnique', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer ~= nil then
        MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
            ['@idunique'] = xPlayer.idunique,
            ['@identifier'] = xPlayer.identifier,
        }, function(result)
            cb(result[1])
        end)
    end
end)

RegisterNetEvent("null:staff:verifpackrp")
AddEventHandler("null:staff:verifpackrp", function(target_id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    TriggerClientEvent("null:detectrppack", target_id)
    xPlayer.showNotification("Vérification du pack en Cours...")
end)

RegisterNetEvent("null:staff:addafkpoint")
AddEventHandler("null:staff:addafkpoint", function(idu, nbr)
    local xPlayer = ESX.GetPlayerFromId(source)
    player = ReturnPlayerId(idu) or {id = 0}
    local xTarget = ESX.GetPlayerFromId(player.id)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if xTarget == nil then 
        MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
            ['@idunique'] = idu,
        }, function(result)
            if result[1] ~= nil then
                if result[1].afk_time == nil then result[1].afk_time = 0 end
                local newNbr = result[1].afk_time + nbr
                MySQL.Async.execute("UPDATE `users` SET `afk_point` = @afk_point WHERE `idunique` = @idunique", {['@afk_point'] = newNbr, ['@idunique'] = idu}, function()  end)
            end
        end)
    else
        local afk = xTarget.getAfk()
        xTarget.setAfk(afk.time, afk.point + nbr)
    end
end)


Citizen.CreateThread(function()
    SaveData.structuresSql["users"] = {}
    MySQL.Async.fetchAll('DESCRIBE users', {}, function(result)
        for i, row in ipairs(result) do
            table.insert(SaveData.structuresSql["users"], {
                Field = row.Field, 
                Type = row.Type,  
                Null = row.Null,  
                Key = row.Key,
                Default = row.Default, 
                Extra = row.Extra
            })
        end
    end)
end)

ESX.RegisterServerCallback('null:staff:getInfoForUsersTable', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer ~= nil and xPlayer.getGroup() ~= "user" then
        cb(SaveData.structuresSql["users"])
    else
        cb({})
    end
end)

RegisterNetEvent("null:staff:wipetableUsers")
AddEventHandler("null:staff:wipetableUsers", function(inputTable, option)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end

    local finalQuery = "SELECT * FROM users WHERE"
    local queryConditions = {}
    local tableLoadout = nil
    local tableInventory = nil
    for k, v in pairs(inputTable) do
        local tablename = SaveData.structuresSql["users"][k].Field
        if tablename == "loadout" then
            tableLoadout = v
        elseif tablename == "inventory" then
            tableInventory = v
        else
            if type(v) == "table" then
                local condition = string.format("%s = '%s'", tablename, json.encode(v))
                table.insert(queryConditions, condition)
            else
                local condition = string.format("%s = '%s'", tablename, v)
                table.insert(queryConditions, condition)
            end
        end
    end

    if #queryConditions > 0 then
        finalQuery = finalQuery .. " " .. table.concat(queryConditions, " AND ") 
    elseif tableLoadout == nil and tableInventory == nil then
        print("Aucune condition valide n'a été fournie.")
        return  
    else
        finalQuery = "SELECT * FROM users"
    end
    print("Requête SQL générée :", finalQuery)

    MySQL.Async.fetchAll(finalQuery, {}, function(result)
        for _, row in ipairs(result) do
            row.loadout = json.decode(row.loadout)
            row.inventory = json.decode(row.inventory)
            if row.loadout == nil then row.loadout = {} end
            if row.inventory == nil then row.inventory = {} end
            if tableLoadout ~= nil then
                local total = 0
                for k,v in pairs(row.loadout) do
                    for x,w in pairs(tableLoadout) do
                        if w.name == v.name then
                            total = total + 1
                        end
                    end
                end
                if option == 1 then
                    if #row.inventory == total and total ~= 0 then
                    else
                        goto continue
                    end
                elseif option == 2 then
                    if total >= 1 then
                    else
                        goto continue
                    end
                elseif option == 3 then
                    if total >= #tableLoadout then
                    else
                        goto continue
                    end
                end
            end

            if tableInventory ~= nil then
                local total = 0
                for k,v in pairs(row.inventory) do
                    for x,w in pairs(tableInventory) do
                        if w.name == v.name then
                            total = total + 1
                        end
                    end
                end
                if option == 1 then
                    if #row.inventory == total and total ~= 0 then
                    else
                        goto continue
                    end
                elseif option == 2 then
                    if total >= 1 then
                    else
                        goto continue
                    end
                elseif option == 3 then
                    if total >= #tableInventory then
                    else
                        goto continue
                    end
                end
            end

            print("WIPE "..row.idunique.." ("..row.identifier..")")

            local xTarget = ESX.GetPlayerFromIdentifier(row.identifier)
            if xTarget ~= nil then
                DropPlayer(xTarget.source, "Vous avez été Wipe...")
                refreshPlayer(xTarget.source)
            end
            WipeTable(row.identifier)

            ::continue::
        end
    end)
end)


RegisterNetEvent("null:staff:removeafkpoint")
AddEventHandler("null:staff:removeafkpoint", function(idu, nbr)
    local xPlayer = ESX.GetPlayerFromId(source)
    player = ReturnPlayerId(idu) or {id = 0}
    local xTarget = ESX.GetPlayerFromId(player.id)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if xTarget == nil then 
        MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
            ['@idunique'] = idu,
        }, function(result)
            if result[1] ~= nil then
                local newNbr = result[1].afk_time - nbr
                MySQL.Async.execute("UPDATE `users` SET `afk_point` = @afk_point WHERE `idunique` = @idunique", {['@afk_point'] = newNbr, ['@idunique'] = idu}, function()  end)
            end
        end)
    else
        local afk = xTarget.getAfk()
        xTarget.setAfk(afk.time, afk.point - nbr)
    end
end)

RegisterNetEvent("null:staff:updateplayerWeight")
AddEventHandler("null:staff:updateplayerWeight", function(src, newWeight)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end

    xTarget.setMaxWeight(newWeight)
    xTarget.showNotification('Le poids de votre inventaire a été changé à '..newWeight..'kg.')

end)

RegisterNetEvent("null:staff:updateinventoryIdUnique:offline")
AddEventHandler("null:staff:updateinventoryIdUnique:offline", function(idu, newinventory)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    for k,v in pairs(newinventory) do
        if v.label ~= nil then v.label = nil end
    end
    MySQL.Async.execute("UPDATE `users` SET `inventory` = @inventory WHERE `idunique` = @idunique", {['@inventory'] = json.encode(newinventory), ['@idunique'] = idu}, function()  end)
end)
RegisterNetEvent("null:staff:updateloadoutIdUnique:offline")
AddEventHandler("null:staff:updateloadoutIdUnique:offline", function(idu, newloadout)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    for k,v in pairs(newloadout) do
        if v.label ~= nil then v.label = nil end
    end
    MySQL.Async.execute("UPDATE `users` SET `loadout` = @loadout WHERE `idunique` = @idunique", { ['@loadout'] = json.encode(newloadout), ['@idunique'] = idu }, function()  end)
end)

RegisterNetEvent("vAdminMenu:addbannote")
AddEventHandler("vAdminMenu:addbannote", function(banid, banNote)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    MySQL.Async.execute("UPDATE `fireac_banlist` SET `Note` = @Note WHERE `BANID` = @BANID", {['@Note'] = banNote, ['@BANID'] = banid}, function()  end)
    TriggerClientEvent("esx:showNotification", _src, "~g~La note : "..banNote.." a bien était ajouter")
end)

RegisterNetEvent("vAdminMenu:addstaffglobal")
AddEventHandler("vAdminMenu:addstaffglobal", function(idunique, group, discord)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if discord == nil then return end
    player = ReturnPlayerId(idunique) or {id = 0}
    xTarget = ESX.GetPlayerFromId(player.id)

    if xTarget ~= nil then
        local name = xTarget.getName()
        xTarget.setGroup(group)
        TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
        MySQL.Async.execute("INSERT INTO staff (idunique, discord, name, permission_group, date) VALUES (@idunique, @discord, @name, @permission_group, @date)",{
            ["@idunique"] = idunique,
            ["@discord"] = discord,
            ["@name"] = name,
            ["@permission_group"] = group,
            ["@date"] = os.date("%d/%m/%Y | %X"),
        }, function()
        end)
        InitAllStaffs()
        TriggerClientEvent("null:admin:refreshOnePlayer", -1, idunique, getLightPlayerData(ESX.PlayersByIdUnique[idunique]), stafflist[idunique])
        null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a ajouter un nouveau staff : "..xTarget.getName().."(U"..xTarget.getIdunique()..") en tant que "..group,"addstaff", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
        TriggerClientEvent("esx:showNotification", _src, "~b~"..name.." a bien était rajouter a la liste des staffs coter serveur !")
    else
		ESX.GetNameByIdUnique(idunique, function(result)
            local staffName = result or ("Inconnu (U"..idunique..")")
            MySQL.Async.execute("UPDATE `users` SET `permission_group` = @permission_group WHERE `idunique` = @idunique", {['@permission_group'] = group, ['@idunique'] = idunique}, function()  end)
            MySQL.Async.execute("INSERT INTO staff (idunique, discord, name, permission_group, date) VALUES (@idunique, @discord, @name, @permission_group, @date)",{
                ["@idunique"] = idunique,
                ["@discord"] = discord,
                ["@name"] = staffName,
                ["@permission_group"] = group,
                ["@date"] = os.date("%d/%m/%Y | %X"),
            }, function()
            end)
            InitAllStaffs()
            TriggerClientEvent("null:admin:refreshOnePlayer", -1, idunique, getLightPlayerData(ESX.PlayersByIdUnique[idunique]), stafflist[idunique])
            null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a ajouter un nouveau staff : "..staffName.."(U"..idunique..") en tant que "..group,"addstaff", {idunique = xPlayer.getIdunique(), idunique_cible = idunique, name = xPlayer.getName(), name_cible = staffName})
            TriggerClientEvent("esx:showNotification", _src, "~b~"..staffName.." a bien était rajouter a la liste des staffs coter serveur !")
        end)
    end
end)


RegisterNetEvent("vAdminMenu:rankstaff")
AddEventHandler("vAdminMenu:rankstaff", function(idunique, rank, name)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    SaveData.Admin.Staffs.List[idunique].permission_group = rank
    MySQL.Async.execute("UPDATE `staff` SET `permission_group` = @permission_group WHERE `idunique` = @idunique", {['@permission_group'] = rank, ['@idunique'] = idunique}, function()  end)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a changer le rank du staff : "..SaveData.Admin.Staffs.List[idunique].name.." (U"..SaveData.Admin.Staffs.List[idunique].idunique..") en tant que "..rank,"rankstaff", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
    TriggerClientEvent("null:admin:refreshOnePlayer", -1, idunique, getLightPlayerData(ESX.PlayersByIdUnique[idunique]), stafflist[idunique])
    TriggerClientEvent("esx:showNotification", _src, "~b~"..name.." a bien était rank a la liste des staffs coter serveur !")
end)

RegisterNetEvent("vAdminMenu:deletegaragevh")
AddEventHandler("vAdminMenu:deletegaragevh", function(model, plate)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if SaveData.json["owned_vehicles"][plate] ~= nil then
        SaveData.json["owned_vehicles"][plate] = nil
        TriggerClientEvent("esx:showNotification", _src, "~b~Model : "..model.."/ Plaque : "..plate.." a bien était supprimer !")
        local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : Inconnu\nAction : Delete vehicle\nModel du véhicule : "..model.."\nPlaque du véhicule : "..plate.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
        ReworkLogs(w, "remove-vehicle", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    else
        TriggerClientEvent("esx:showNotification", _src, "~b~Model : "..model.."/ Plaque : "..plate.." n'existe pas/plus !")
    end
end)

RegisterNetEvent("vAdminMenu:deletestaff")
AddEventHandler("vAdminMenu:deletestaff", function(idunique, group, name)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    MySQL.Async.execute("DELETE FROM staff WHERE idunique = @idunique", {['@idunique'] = idunique}, function()  end)
    stafflist[idunique] = nil
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a demote le staff : "..SaveData.Admin.Staffs.List[idunique].name.." (U"..SaveData.Admin.Staffs.List[idunique].idunique..")","demotestaff", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
    TriggerClientEvent("null:admin:refreshOnePlayer", -1, idunique, getLightPlayerData(ESX.PlayersByIdUnique[idunique]), stafflist[idunique])
    TriggerClientEvent("esx:showNotification", _src, "~b~"..name.." a bien était supprimer a la liste des staffs coter serveur !")
end)


RegisterNetEvent("AdminMenu:goto")
AddEventHandler("AdminMenu:goto", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)
    
    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end

    if xTarget.getGroup() == "_dev" then
        return TriggerClientEvent("esx:showNotification", _src, "Tu ne peux pas te téléporter sur un fondateur")
    end
    local coords = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent("AdminMenu:setCoords", _src, coords)

    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : Téléportation sur le joueur", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "TP", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
end)

RegisterNetEvent("null:staff:teleport:id")
AddEventHandler("null:staff:teleport:id", function(id)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(id)
    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end

    if xTarget == nil then
        TriggerClientEvent("esx:showNotification", _src, "Aucun joueur n'a cette ID")
        return
    end

    if xTarget.getGroup() == "_dev" then
        return TriggerClientEvent("esx:showNotification", _src, "Tu ne peux pas te téléporter sur un fondateur")
    end

    local coords = GetEntityCoords(GetPlayerPed(id))
    TriggerClientEvent("AdminMenu:setCoords", _src, coords)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : Téléportation sur le joueur", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "goto", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
end) 

exports('getPlayerWithUniqueID', function(idunique)
    -- méthode qui créer des erreurs si fonction mal gérer
    -- if idunique == nil then return nil end
    -- if type(idunique) ~= "number" then return nil end
    -- if ESX.PlayersByIdUnique[idunique] == nil then return nil end

    if idunique == nil then return {id = nil} end
    if type(idunique) ~= "number" then return {id = nil} end
    if ESX.PlayersByIdUnique[idunique] == nil then return {id = nil} end

    return ReturnPlayerId(idunique)
end)

exports('getPlayerSourceByIdUnique', function(idunique)
    if idunique == nil then return 0 end
    if type(idunique) ~= "number" then return 0 end
    if ESX.PlayersByIdUnique[idunique] == nil then return 0 end

    local playerInfo = ReturnPlayerId(idunique)
    if playerInfo == false or playerInfo.source == nil then
        return false
    else
        return playerInfo.source
    end
end)



RegisterNetEvent("null:staff:teleport:playertocoord")
AddEventHandler("null:staff:teleport:playertocoord", function(target, coords, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)
    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end
    TriggerClientEvent("AdminMenu:setCoords", target, coords)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : Téléportation sur lieux\nLieux de téléportation : "..label.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "TP", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
end)



RegisterNetEvent("null:staff:messageplayer")
AddEventHandler("null:staff:messageplayer", function(target, message)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    TriggerClientEvent("esx:showNotification", _src, "~g~Message envoyer !")
    ESX.ChatMessage(target, message, "STAFF", { 255, 0, 0 })
    TriggerClientEvent("esx:showNotification", target, ""..message)
    TriggerClientEvent("AdminMenu:playSound", target)
    ESX.ChatMessage(target, "Utilisez la commande /rs pour repondre au staff", "STAFF", { 255, 0, 0 })
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)

    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /msgstaff ("..message..") le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "msgstaff", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("null:staff:screenshotplayer")
AddEventHandler("null:staff:screenshotplayer", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if target == nil then
        TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    TriggerClientEvent("AdminMenu:takeScreenShot", target, Config.Logs["screenshot"])
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("null:staff:removeplayeritem")
AddEventHandler("null:staff:removeplayeritem", function(target, amount, item, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.removeInventoryItem(item, tonumber(amount))
    TriggerClientEvent("esx:showNotification", _src, "Vous avez retirer ~y~"..amount.."~b~ "..label.." ~s~à ~b~"..xTarget.getName())
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a retirer ~y~"..amount.."~b~ "..label)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer l'item "..label.." ("..item.." x"..amount..") au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-item", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("null:staff:removeplayerweapon")
AddEventHandler("null:staff:removeplayerweapon", function(target, weapon, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.removeWeapon(weapon, 1)
    TriggerClientEvent("esx:showNotification", _src, "Vous avez retirer : ~r~"..label)
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a retirer : ~r~"..label)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer l'arme "..label.." ("..weapon..") au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-weapon", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("null:staff:repairweapon")
AddEventHandler("null:staff:repairweapon", function(target, weapon, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    SetDurability(xTarget.source, weapon, 0.0)
    TriggerClientEvent("esx:showNotification", _src, "Vous avez réparer : ~r~"..label)
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a réparer : ~r~"..label)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a réparer l'arme "..label.." ("..weapon..") au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-weapon", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)

RegisterServerEvent("null:staff:setStreamer", function(idunique, bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetData = ReturnPlayerId(idunique)
    local xTarget = targetData and ESX.GetPlayerFromId(targetData.source) or nil
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= true then return end
    if xTarget == nil then
        if bool then
            MySQL.Async.execute("UPDATE `users` SET `streamer` = '1' WHERE `idunique` = @idunique", {['@idunique'] = idunique}, function()  end)
            if ESX.PlayersByIdUnique.List[idunique] ~= nil then
                SaveData.streamerList[idunique] = {name = ESX.PlayersByIdUnique.List[idunique].name, idunique = ESX.PlayersByIdUnique.List[idunique].idunique}
            end
        else
            MySQL.Async.execute("UPDATE `users` SET `streamer` = '0' WHERE `idunique` = @idunique", {['@idunique'] = idunique}, function()  end)
            SaveData.streamerList[idunique] = nil
        end
    else
        xTarget.setStreamer(bool)
        TriggerClientEvent("null:setStreamer",xTarget.source, bool)
        if bool then
            SaveData.connectedStreamerList[xTarget.getIdunique()] = {name = xTarget.getName(), idunique = xTarget.getIdunique()}
            ESX.PlayersByIdUnique[xTarget.getIdunique()].streamer = true
        else
            SaveData.connectedStreamerList[xTarget.getIdunique()] = nil
            ESX.PlayersByIdUnique[xTarget.getIdunique()].streamer = false
        end
    end
end)

RegisterNetEvent("null:staff:removeplayerweaponOffline")
AddEventHandler("null:staff:removeplayerweaponOffline", function(target, weapon, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget ~= nil then 
        xTarget.removeWeapon(weapon, 1)
        null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer l'arme "..label.." ("..weapon..") au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-weapon", {idunique = xPlayer.getIdunique(), idunique_cible = target, name = xPlayer.getName(), name_cible = xTarget.getName()})
        return 
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
        ['@idunique'] = target,
    }, function(result)
        if result[1] then
            local formattedLoadout = json.decode(result[1].loadout) or {}
            for _,v in pairs(formattedLoadout) do
                if v.name == weapon then
                    table.remove(formattedLoadout, _)
                end
            end
            MySQL.Async.execute("UPDATE `users` SET `loadout` = @loadout WHERE `idunique` = @idunique", { ['@loadout'] = json.encode(formattedLoadout), ['@idunique'] = target }, function()  end)
            null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer l'arme "..label.." ("..weapon..") au joueur : "..result[1].name.." (U"..target..")", "remove-weapon", {idunique = xPlayer.getIdunique(), idunique_cible = target, name = xPlayer.getName(), name_cible = result[1].name})
        else
            TriggerClientEvent("esx:showNotification", _src, "La personne sélectioner n'existe pas")
        end

    end)
    TriggerClientEvent("esx:showNotification", _src, "Vous avez retirer : ~r~"..label)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("null:staff:player:removemoney")
AddEventHandler("null:staff:player:removemoney", function(target, account, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.removeAccountMoney(account, tonumber(amount))
    TriggerClientEvent("esx:showNotification", _src, "Vous avez retirer ~g~"..amount.."$~s~ à ~b~"..xTarget.getName())
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a retirer ~g~"..amount.."$")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer "..amount.."$ (cash) au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-account", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)


RegisterNetEvent("null:staff:player:idunique:removemoney")
AddEventHandler("null:staff:player:idunique:removemoney", function(idunique, account, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromIdUnique(idunique)

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if xTarget == nil then
        MySQL.Async.fetchAll('SELECT accounts FROM users WHERE idunique = @idunique',{
            ['@idunique'] = idunique,
        }, function(result)
            if result[1] ~= nil then
                local newAccounts = json.decode(result[1].accounts)
                for k,v in pairs(newAccounts) do 
                    if v.name == account then
                        v.money = v.money - amount
                    end
                end
                MySQL.Async.execute("UPDATE `users` SET `accounts` = @accounts WHERE `idunique` = @idunique", {['@accounts'] = json.encode(newAccounts), ['@idunique'] = idunique}, function()  end)
            end
        end)
    else
        xTarget.removeAccountMoney(account, tonumber(amount))
        TriggerClientEvent("esx:showNotification", _src, "Vous avez retirer ~g~"..amount.."$~s~ à ~b~"..xTarget.getName())
    end

    TriggerClientEvent("esx:showNotification", target, "Un admin vous a retirer ~g~"..amount.."$")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a retirer "..amount.."$ (cash) au joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "remove-account", {idunique = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:giveVeh")
AddEventHandler("AdminMenu:giveVeh", function(target, model, veh)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    TriggerClientEvent("esx:spawnVehicle", target, model)
    TriggerClientEvent("esx:showNotification", _src, "~g~Spawn du véhicule effectuer")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : GIVE VEHICULE\nVéhicule : "..veh.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "car", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
end)

RegisterNetEvent("AdminMenu:giveGarageVeh")
AddEventHandler("AdminMenu:giveGarageVeh", function(data, target, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "~r~Joueur introuvable")
    end
    
    SaveData.json["owned_vehicles"][string.upper(data.plate)] = {
        owner = xTarget.identifier,
        model = data.model,
        plate = string.upper(data.plate),
        vehicle = data,
        datetoremove = nil,
        label = data.model,
        coffre = {},
        type = "car",
        state = true,
        boutique = false,
        garage = true,
    }
    TriggerClientEvent("esx:showNotification", _src, "~g~Give effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give un véhicule garage")
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : ATTRIBUTION DE VEHICULE\nVéhicule : "..label.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "give-vehicle", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
end)

RegisterNetEvent("AdminMenu:giveWeapon")
AddEventHandler("AdminMenu:giveWeapon", function(target, model, amount, option)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    local HasPerm = true
    if Config.WeaponOnlyForOwner[model] ~= nil then
        HasPerm = false
        for k,v in pairs(Config.WeaponOnlyForOwner[model]) do 
            if v == xPlayer.getGroup() then
                HasPerm = true
            end 
        end
    end

    if not HasPerm then 
        xPlayer.showNotification("Vous ne pouvez pas give cette armes.")
        return 
    end

    if option ~= nil and option[1] ~= nil then
        if option[2] ~= nil then
            xTarget.addWeapon(
                model, 
                amount, 
                {
                    label = option[1],
                    description = option[2]
                }, 
                option[4] or false,
                option[3] or false
            )
        else
            xTarget.addWeapon(
                model, 
                amount, 
                {
                    label = option[1]
                }, 
                option[4] or false,
                option[3] or false
            )
        end
    else
        xTarget.addWeapon(model, amount, nil, false, true)
    end

    TriggerClientEvent("esx:showNotification", _src, "~g~Give d'arme effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give : ~b~"..ESX.GetWeaponLabel(model))
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    --local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : GIVE WEAPON\nArme : "..ESX.GetWeaponLabel(model).."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    --ReworkLogs(w, "give-weapon", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give l'arme "..ESX.GetWeaponLabel(model).." ("..model..") a "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "give-weapon", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:giveMoneyCash")
AddEventHandler("AdminMenu:giveMoneyCash", function(target, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
 
    xTarget.addAccountMoney("cash", amount)
    TriggerClientEvent("esx:showNotification", _src, "Give de ~g~"..amount.."$~s~ effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give ~g~"..amount.."$")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give "..amount.."$ (cash) a "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "give-account", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:giveMoneyBank")
AddEventHandler("AdminMenu:giveMoneyBank", function(target, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.addAccountMoney("bank", tonumber(amount), {title = 'Give Admin', description = 'Ajout par un administrateur', category = 'other'})
    TriggerClientEvent("esx:showNotification", _src, "Give de ~b~"..amount.."$~s~ effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give ~b~"..amount.."$")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give "..amount.."$ (bank) a "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "give-account", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:giveMoneyBlack")
AddEventHandler("AdminMenu:giveMoneyBlack", function(target, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.addAccountMoney("dirtycash", tonumber(amount))
    TriggerClientEvent("esx:showNotification", _src, "Give de ~r~"..amount.."$~s~ effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give ~r~"..amount.."$")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give "..amount.."$ (dirtycash) a "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "give-account", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:kickPlayer")
AddEventHandler("AdminMenu:kickPlayer", function(target, reason)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
        ["@target_id"] = xTarget.identifier,
        ["@staff_name"] = xPlayer.getName(),
        ["@target_name"] = xTarget.getName(),
        ["@type"] = "Kick",
        ["@raison"] = reason,
        ["@date"] = os.date("%d/%m/%Y | %X"),
    }, function()
    end)
    DropPlayer(target, "Vous avez été kick pour "..reason)
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
    --local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : KICK\nRaison : `"..reason.."`", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    --ReworkLogs(w, "KICK", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a kick "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "kick", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
end)

RegisterNetEvent("AdminMenu:ban")
AddEventHandler("AdminMenu:ban", function(target, time, reason, ac)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    local secondetime = time*24*60

    if Config.Anticheat.votre_anticheat["WaveShield"] == true and ac == "ws" then
        exports["WaveShield"]:banPlayer(target, reason, "Si vous pensez que c'est une erreur, veuillez faire un ticket", "Main", secondetime)
    end

    if Config.Anticheat.votre_anticheat["others"] == true and ac == "others" then
        ExecuteCommand("ban "..xTarget.getIdunique() .." "..time.." "..reason)
    end

    MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
        ["@target_id"] = xTarget.identifier,
        ["@staff_name"] = xPlayer.getName(),
        ["@target_name"] = xTarget.getName(),
        ["@type"] = "BAN",
        ["@raison"] = reason.." pour "..time.."jours",
        ["@date"] = os.date("%d/%m/%Y | %X"),
    }, function()
    end)
    TriggerClientEvent("esx:showNotification", _src, "~b~"..xTarget.getName().." a bien été banni du serveur !")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:unban")
AddEventHandler("AdminMenu:unban", function(idban, ac)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if Config.Anticheat.votre_anticheat["WaveShield"] == true and ac == "ws" then
        exports["WaveShield"]:unbanPlayer(idban)
    end
end)

RegisterNetEvent("AdminMenu:addBanSancton")
AddEventHandler("AdminMenu:addBanSancton", function(target, time, reason)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
        ["@target_id"] = target,
        ["@staff_name"] = xPlayer.getName(),
        ["@target_name"] = target,
        ["@type"] = "BAN",
        ["@raison"] = reason.." pour "..time.."jours",
        ["@date"] = os.date("%d/%m/%Y | %X"),
    }, function()
    end)
end)

RegisterNetEvent("AdminMenu:warn")
AddEventHandler("AdminMenu:warn", function(target, reason)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
        ["@target_id"] = xTarget.identifier,
        ["@staff_name"] = xPlayer.getName(),
        ["@target_name"] = xTarget.getName(),
        ["@type"] = "WARN",
        ["@raison"] = reason,
        ["@date"] = os.date("%d/%m/%Y | %X"),
    }, function()
    end)
    TriggerClientEvent("esx:showNotification", target, "Vous avez été warn pour "..reason)
    TriggerClientEvent("esx:showNotification", _src, "~b~"..xTarget.getName().."~s~ a bien été warn.")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)

    null.logs.send("Logs Staff","Le joueur "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a warn le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "warn", {idunique = xPlayer.getIdunique, name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
						
end)

ESX.RegisterServerCallback("AdminMenu:getPlayerSanction", function(source, cb, target)
    local sanction = {}
    local xTarget = ESX.GetPlayerFromId(target)
    if xTarget ~= nil then
        MySQL.Async.fetchAll("SELECT * FROM sanction_list WHERE target_id = @target_id", {['@target_id'] = xTarget.identifier}, function(data)
            for k, v in pairs(data) do
                table.insert(sanction, {staff = v.staff_name, target = v.target_name, type = v.type, raison = v.raison, time = v.time, date = v.date})
            end
            cb(sanction)
        end)
    end
end)

ESX.RegisterServerCallback("null:staff:getPlayerFarmList", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] == true then
        local Plys = SaveData.Get("FarmPlayers")
        if Plys == nil then Plys = {} end
        for k,v in pairs(Plys) do
            local xtarget = ESX.GetPlayerFromId(k)
            Plys[k] = {name = xtarget.getName(), source = xtarget.source, idunique = xtarget.getIdunique()}
        end
        cb(Plys)
    end
end)

ESX.RegisterServerCallback("AdminMenu:getPlayerWeaponIdunique", function(source, cb, idunique)
    local weapons = {}
--[[    MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
        ['@idunique'] = idunique,
    }, function(result)
        if result[1] then
            print(result[1].identifier)
            print(result[1].loadout[1])
            for k,v in pairs(result[1].loadout) do
                print(result[1].loadout[v])
            end
        else
            print("RIEN TROUVER")
        end

    end)]]
--[[    MySQL.Async.fetchAll("SELECT * FROM users WHERE idunique = '"..idunique.."'", {
    }, function(data)
        --for k, v in pairs(data) do
            print(data)
            print(data[1].loadout)
            table.insert(weapons, data)
            --table.insert(weapons, {name = v.staff_name, hash = v.target_name})
        --end
        cb(weapons)
    end)]]
end)

local identifier = nil
ESX.RegisterServerCallback("AdminMenu:getPlayerSanctionIdUnique", function(source, cb, identifer)
    local sanction = {} 
    MySQL.Async.fetchAll("SELECT * FROM sanction_list WHERE target_id = @target_id", {['@target_id'] = identifer}, function(result)
        for k, v in pairs(result) do
            table.insert(sanction, {staff = v.staff_name, target = v.target_name, type = v.type, raison = v.raison, time = v.time, date = v.date})
        end
        cb(sanction)
    end)
end)


--[[EwenServerUtils.getIdentifiers = function(source)
    if (source ~= nil) then
        local identifiers = {}
        local playerIdentifiers = GetPlayerIdentifiers(source)
        for _, v in pairs(playerIdentifiers) do
            local before, after = playerIdentifiers[_]:match("([^:]+):([^:]+)")
            identifiers[before] = playerIdentifiers[_]
        end
        return identifiers
    end
end
]]

local ListePack = {
    ["entreprise"] = {price = 9500},
    ["gang"] = {price = 7500},
    ["deplacement"] = {price = 3000},
    ["bunker"] = {price = 1500},
    ["veh-unique"] = {price = 20000},
    ["Basic"] = {price = 1000},
    ["Premium"] = {price = 2500},
}

RegisterNetEvent("null:staff:boutique:addcoins", function(idboutique, nbrtoAdd, idunique)
    local xPlayer = ESX.GetPlayerFromId(source) 
    local xTarget = ESX.GetPlayerFromIdUnique(idunique)
    if not xPlayer then return end
    if not idboutique or not nbrtoAdd then return end
    if not xPlayer.getPermission("givecoins") then return end
    LiteMySQL:Insert('tebex_players_wallet', {
        identifiers = idboutique,
        idunique = idunique,
        transaction = 'Ajout de Coins par '..xPlayer.getName().." (U"..xPlayer.getIdunique()..")",
        price = 0,
        currency = 'Points',
        points = nbrtoAdd,
    })
    if xTarget then
        xPlayer.showNotification("Vous avez envoyer ~b~"..nbrtoAdd.."~s~ coins à ~b~"..xTarget.getName())
        xTarget.showNotification("Vous avez reçu ~b~"..nbrtoAdd.."~s~ coin(s)")
        TriggerClientEvent("null:boutique:newCoinsAmount", xTarget.source, getPoints(xTarget.source))
    else
        xPlayer.showNotification("Vous avez envoyer ~b~"..nbrtoAdd.."~s~ à ~b~"..idboutique)
    end
end)
 
ESX.RegisterServerCallback("AdminMenu:getIdUniqueBoutiqueInfo", function(source, cb, idunique)
    local xTarget = ESX.GetPlayerFromIdUnique(idunique)
    local historique = {}
    if xTarget then
        local identifier = null.fct.getIdentifiers(xTarget.source)
        if (identifier['fivem']) then
            local before, idboutique = identifier['fivem']:match("([^:]+):([^:]+)")
            MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE idunique = @idunique", {['@idunique'] = idunique}, function(result)
                if result[1] ~= nil then
                    local pack = {}
                    for k, v in pairs(result) do
                        local finalpoint = 0
                        if v.points == nil then
                            finalpoint = 0
                        else
                            finalpoint = v.points
                        end
                        if string.find(v.transaction, "Achat du pack ") then
                            for w,y in pairs(ListePack) do
                                if string.find(v.transaction, w) then
                                    pack[w] = true
                                end
                            end 
                        end
                        table.insert(historique, {label = v.transaction, point = finalpoint, currency = v.currency, date = v.created_at})
                    end
                    MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
                        ['@identifiers'] = idboutique
                    }, function(result3)
                        local point = 0
                        if (result3[1]["SUM(points)"] ~= nil) then
                            point = result3[1]["SUM(points)"]
                        end
                        MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
                            ['@license'] = idboutique
                        }, function(result2)
                            local total = 0
                            local havebuy = 0
                            if result2[1] ~= nil then
                                total = result2[1].totalbuy
                                havebuy = result2[1].havebuy
                            end
                            cb(historique, pack, idboutique, point, {total, havebuy})
                        end)
                    end)
                else
                    cb({}, {}, idboutique, 0, {0, 0})
                end
            end)
        else
            cb({}, {}, nil)
        end
    else
        MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE idunique = @idunique", {['@idunique'] = idunique}, function(result)
            if result[1] ~= nil and result[1].identifiers then
                local pack = {}
                local idboutique = result[1].identifier
                for k, v in pairs(result) do
                    local finalpoint = 0
                    if v.points == nil then
                        finalpoint = 0
                    else
                        finalpoint = v.points
                    end
                    if string.find(v.transaction, "Achat du pack ") then
                        for w,y in pairs(ListePack) do
                            if string.find(v.transaction, w) then
                                pack[w] = true
                            end
                        end 
                    end
                    table.insert(historique, {label = v.transaction, point = finalpoint, currency = v.currency, date = v.created_at})
                end
                MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
                    ['@identifiers'] = idboutique
                }, function(result3)
                    local point = 0
                    if (result3[1]["SUM(points)"] ~= nil) then
                        point = result3[1]["SUM(points)"]
                        print(point)
                    end
                    MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
                        ['@license'] = idboutique
                    }, function(result2)
                        local total = 0
                        local havebuy = 0
                        if result2[1] ~= nil then
                            total = result2[1].totalbuy
                            havebuy = result2[1].havebuy
                        end
                        cb(historique, pack, idboutique, point, {total, havebuy})
                    end)
                end)
            else
                cb({}, {}, nil)
            end
        end)
    end
end)
local ListePack = {
    ["entreprise"] = {price = 9500},
    ["gang"] = {price = 7500},
    ["deplacement"] = {price = 3000},
    ["bunker"] = {price = 1500},
    ["veh-unique"] = {price = 20000},
    ["Basic"] = {price = 1000},
    ["Premium"] = {price = 2500},
}

RegisterNetEvent("Null:boutique:staff:deletepack")
AddEventHandler("Null:boutique:staff:deletepack", function(idunique, selectedPack)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end

    MySQL.Async.execute('DELETE FROM tebex_players_wallet WHERE `idunique` = @idunique AND `transaction` = @transaction', {
        ['@idunique'] = idunique,
        ['@transaction'] = "Achat du pack "..selectedPack
    })
end)

RegisterNetEvent("Null:boutique:staff:addpack")
AddEventHandler("Null:boutique:staff:addpack", function(idunique, selectedPack, after)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end

    LiteMySQL:Insert('tebex_players_wallet', {
        identifiers = after,
        idunique = idunique,
        transaction = "Achat du pack "..selectedPack,
        price = 0,
        currency = 'Points',
        points = 0,
    });
end)

RegisterNetEvent("AdminMenu:clearPlayerInv")
AddEventHandler("AdminMenu:clearPlayerInv", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    for i = 1, #xTarget.inventory, 1 do
        if xTarget.inventory[i].count > 0 then
            xTarget.setInventoryItem(xTarget.inventory[i].name, 0)
        end
    end

    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : CLEAR INVENTAIRE", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "CLEAR_INV", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("esx:showNotification", _src, ("Clear de ~b~%s ~s~effectuer"):format(xTarget.getName()))
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a clear votre inventaire")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:clearPlayerWeapon")
AddEventHandler("AdminMenu:clearPlayerWeapon", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    for i= #xTarget.loadout, 1, -1 do
        xTarget.removeWeapon(xTarget.loadout[i].name)
    end

    TriggerClientEvent("esx:showNotification", _src, ("Clear d'armes de ~b~%s ~s~effectuer"):format(xTarget.getName()))
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a clear vos armes")
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : CLEAR WEAPON", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "CLEAR_WEAPON", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:wipe")
AddEventHandler("AdminMenu:wipe", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if xTarget ~= nil then
        WipeTable(xTarget.identifier)
        DropPlayer(target, "Vous avez été Wipe...")
        TriggerClientEvent("esx:showNotification", _src, "~g~Wipe effectuer")
    end
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : WIPE", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "CLEAR_WEAPON", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:wipeoffline")
AddEventHandler("AdminMenu:wipeoffline", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if target ~= nil then
        local xPlayers = ESX.GetPlayers();
        local isonline = false

        for i = 1, #xPlayers, 1 do
            local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
            if xTarget.getIdunique() == idunique then
                isonline = true
                DropPlayer(xPlayers[i], "Vous avez été Wipe...")
            end
        end

        WipeTable(target)
        TriggerClientEvent("esx:showNotification", _src, "~g~Wipe effectuer")
    end
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..target.."\nAction : WIPE", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "CLEAR_WEAPON", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:clearPlayerVeh")
AddEventHandler("AdminMenu:clearPlayerVeh", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "~r~Joueur introuvable")
    end
    
    for k,v in pairs(SaveData.json["owned_vehicles"]) do
        if v.owner == xTarget.identifier then SaveData.json["owned_vehicles"][k] = nil break end
    end
    TriggerClientEvent("esx:showNotification", _src, "~g~Véhicule(s) supprimé(s)")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a clear vos véhicules")
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : CLEAR VEHICULES", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "CLEAR_VEHICULE", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:setRank")
AddEventHandler("AdminMenu:setRank", function(target, rank, label)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if not Config.GroupeGrade[rank] then
        return TriggerClientEvent("esx:showNotification", _src, "~r~Rôle staff invalide")
    end

    MySQL.Async.execute("UPDATE `users` SET `permission_group` = @permission_group WHERE `identifier` = @identifier", {['@permission_group'] = rank, ['@identifier'] = xTarget.identifier}, function()  end)
    MySQL.Async.execute("UPDATE `staff` SET `permission_group` = @permission_group WHERE `idunique` = @idunique", {['@permission_group'] = rank, ['@idunique'] = xTarget.getIdunique()}, function()  end)
    SaveData.Admin.Staffs.List[xTarget.getIdunique()].permission_group = rank
    xTarget.setGroup(rank)


    TriggerClientEvent("AdminMenu:reciviestaffrole", target)
    TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
    TriggerClientEvent("esx:showNotification", _src, "Le rang "..label.." a bien été atribuer à ~b~"..xTarget.getName())
    TriggerClientEvent("esx:showNotification", target, "Le rang "..label.." vous a été attribuer")
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : SETRANK\nAncien rang : "..xTarget.getGroup().."\nNouveau rang : "..rank.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "SET_RANK", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:setRankbyIdUnique")
AddEventHandler("AdminMenu:setRankbyIdUnique", function(idunique, rank)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xPlayers = ESX.GetPlayers();
    local isonline = false

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if not Config.GroupeGrade[rank] then
        return TriggerClientEvent("esx:showNotification", _src, "~r~Rôle staff invalide")
    end

    if rank == "user" then
        MySQL.Async.execute("DELETE FROM staff WHERE idunique = @idunique", {['@idunique'] = idunique}, function()  end)
        SaveData.Admin.Staffs.List[idunique] = nil
    else
        MySQL.Async.execute("UPDATE `staff` SET `permission_group` = @permission_group WHERE `idunique` = @idunique", {['@permission_group'] = rank, ['@idunique'] = idunique}, function()  end)
        SaveData.Admin.Staffs.List[idunique].permission_group = rank
    end

    for i = 1, #xPlayers, 1 do
        local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
        if xTarget.getIdunique() == idunique then
            isonline = true
            xTarget.setGroup(rank)
            TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayers[i])
            if rank == "user" then
                TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {false, xTarget.getGroup()})
            else
                TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
            end
        end
    end

    MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
        ['@idunique'] = idunique,
        ['@identifier'] = xPlayer.identifier,
    }, function(result)
        if result[1] then
            MySQL.Async.execute("UPDATE `users` SET `permission_group` = @permission_group WHERE `identifier` = @identifier", {['@permission_group'] = rank, ['@identifier'] = result[1].identifier}, function()  end)
        else
        end
    end)
    TriggerClientEvent("esx:showNotification", _src, "Le rang "..rank.." a bien été atribuer")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:setNamebyIdUnique")
AddEventHandler("AdminMenu:setNamebyIdUnique", function(idunique, name)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    
    MySQL.Async.execute("UPDATE `staff` SET `name` = @name WHERE `idunique` = @idunique", {['@name'] = name, ['@idunique'] = idunique}, function()  end)
    SaveData.Admin.Staffs.List[idunique].name = name

    TriggerClientEvent("esx:showNotification", _src, "Le nom "..name.." a bien était changer")
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:giveItem")
AddEventHandler("AdminMenu:giveItem", function(target, item, label, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if amount == nil then amount = 1 end
    if item == nil then return end
    if label == nil then label = ESX.GetItemLabel(item) end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xTarget.addInventoryItem(item, amount)
    TriggerClientEvent("esx:showNotification", _src, "Give de ~y~x"..amount.." ~b~"..label.."~s~ effectuer")
    TriggerClientEvent("esx:showNotification", target, "Un admin vous a give ~y~x"..amount.."~b~ "..label)
    --local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : GIVE ITEM\nLabel de l'item : "..label.."\nName de l'item : "..item.."\nMontant d'item give : "..amount.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    --ReworkLogs(w, "give-item", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give l'item "..ESX.GetItemLabel(item).." (x"..amount..") a "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "give-item", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:giveItemPerso")
AddEventHandler("AdminMenu:giveItemPerso", function(item, label, amount)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    xPlayer.addInventoryItem(item, amount)
    TriggerClientEvent("esx:showNotification", _src, "Give de ~y~x"..amount.." ~b~"..label.."~s~ effectuer")
    --local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."Action : GIVE ITEM A LUI MÊME\nLabel de l'item : "..label.."\nName de l'item : "..item.."\nMontant d'item give : "..amount.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    --ReworkLogs(w, "give-item", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a give l'item "..ESX.GetItemLabel(item).." (x"..amount..") a lui même", "give-item", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xPlayer.getIdunique(), name_cible = xPlayer.getName()})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:openSkinMenu")
AddEventHandler("AdminMenu:openSkinMenu", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    TriggerClientEvent('null:openSkinMenu', target)
    --TriggerClientEvent("esx_skin:openSaveableMenu", target)
    TriggerClientEvent("esx:showNotification", _src, "Le menu skin a bien été ouvert")
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : OPEN SKIN MENU", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "SKIN_MENU", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:giveLicence")
AddEventHandler("AdminMenu:giveLicence", function(target, licence)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Le joueur n'est plus connecter")
    end

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    TriggerEvent("esx_license:addLicense", target, licence)
    if licence == "weapon" then
        TriggerClientEvent("esx:showNotification", _src, "Le ~r~PPA~s~ a bien été attribuer")
        TriggerClientEvent("esx:showNotification", target, "Un admin vous a give le ~r~PPA")
    elseif licence == "drive" then
        TriggerClientEvent("esx:showNotification", _src, "Le ~b~permis de conduire~s~ a bien été attribuer")
        TriggerClientEvent("esx:showNotification", target, "Un admin vous a give le ~b~permis de conduire")
    end
    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nJoueur : "..xTarget.getName().."\nAction : GIVE LICENCE\nType de licence : "..licence.."", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "GIVE_LICENCE", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("null:admin:freezeVehicle")
AddEventHandler("null:admin:freezeVehicle", function(veh)
    
end)

RegisterNetEvent("AdminMenu:annonce")
AddEventHandler("AdminMenu:annonce", function(message)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xPlayers = GetPlayers()

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    for i = 1, #xPlayers, 1 do
        ESX.ChatMessage(xPlayers[i], message, "ANNONCE", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
    end



    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nAction : ANNONCE\n*Annonce :*\n`"..message.."`", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "ANNONCE", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:annonceSTAFF")
AddEventHandler("AdminMenu:annonceSTAFF", function(message)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xPlayers = GetPlayers()

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    for i = 1, #xPlayers, 1 do
        if xPlayers[i].getGroup() ~= "user" then
            ESX.ChatMessage(xPlayers[i], message, "Annonce Staff", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
        end
    end

    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nAction : ANNONCE\n*Annonce :*\n`"..message.."`", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "ANNONCE", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:annonceReboot")
AddEventHandler("AdminMenu:annonceReboot", function(message)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xPlayers = GetPlayers()

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    for i = 1, #xPlayers, 1 do
        ESX.ChatMessage(xPlayers[i], "Prochain reboot dans ~r~"..message.."~s~ minute(s)", "Annonce", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
    end

    local w = {{ ["author"] = { ["name"] = "Logs", ["icon_url"] = ESX.Config("serverCHAR") }, ["title"] = Title, ["description"] = "Staff : "..xPlayer.getName().."\nAction : ANNONCE REBOOT\n*Annonce :*\n`Prochain reboot dans ~r~"..message.."~s~ minute(s)`", ["footer"] = { ["text"] = os.date("%d/%m/%Y | %X"), ["icon_url"] = ESX.Config("serverCHAR")}, } }
    ReworkLogs(w, "ANNONCE", function(err, text, headers) end, 'POST', json.encode({username = "LogsAdmin", embeds = w, avatar_url = ESX.Config("serverCHAR")}), { ['Content-Type'] = 'application/json'})
    TriggerClientEvent("AdminMenu:serverInteractFinish", _src)
end)

RegisterNetEvent("AdminMenu:checkPlayerIdExist")
AddEventHandler("AdminMenu:checkPlayerIdExist", function(target)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(target)

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end

    if xTarget == nil then
        return TriggerClientEvent("esx:showNotification", _src, "Ce joueur n'existe pas")
    end

    TriggerClientEvent("AdminMenu:playerAsBeenSearch", _src, xTarget.source)
end)

RegisterNetEvent("Null:staff2:getiduinfo")
AddEventHandler("Null:staff2:getiduinfo", function(idunique, type)
    if type == nil then type = "idunique" end
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)   
    local identifier = nil

    if xPlayer.getGroup() == "user" then
        DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
        return
    end
    if type == "idunique" then
        if ESX.PlayersByIdUnique[idunique] ~= nil then
            MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license',{
                ['@license'] = ESX.PlayersByIdUnique[idunique].identifier,
            }, function(result1)
                local formattedLoadout = {}
                for k,v in pairs(ESX.PlayersByIdUnique[idunique].loadout) do
                    local allcomp = {}
                    local getWeap1, getWeap2 = ESX.GetWeapon(v.name)
                    if getWeap2 ~= nil then 
                        allcomp = getWeap2.components 
                    end
                    formattedLoadout[k] = {label = v.label, name = v.name, ammo = v.ammo, components = v.components, allcomponents = allcomp}
                end
                local lightData = getLightPlayerData(ESX.PlayersByIdUnique[idunique])
                if result1[1] ~= nil then 
                    TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, ESX.PlayersByIdUnique[idunique].identifier, ESX.PlayersByIdUnique[idunique].job.name, ESX.PlayersByIdUnique[idunique].job2.name, ESX.PlayersByIdUnique[idunique].group, false, formattedLoadout, result1[1], {}, lightData)
                else
                    TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, ESX.PlayersByIdUnique[idunique].identifier, ESX.PlayersByIdUnique[idunique].job.name, ESX.PlayersByIdUnique[idunique].job2.name, ESX.PlayersByIdUnique[idunique].group, false, formattedLoadout, {}, {}, lightData)
                end 
                local toSend = getLightPlayerData(ESX.PlayersByIdUnique[idunique])
                toSend.loadout = formattedLoadout
                if result1[1] ~= nil then
                    toSend.account_info = result1[1]
                end
                local inJail = IN_JAIL[ESX.PlayersByIdUnique[idunique].identifier]
                if inJail then
                    toSend.injail = true
                    toSend.injailraison = inJail.raison
                    toSend.injailtime = raison.time
                else
                    toSend.injail = false
                end
                TriggerClientEvent("null:staff:recevieSearchIdUniqueInfo", _src, idunique, toSend)
            end)
        else
            MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
                ['@idunique'] = idunique,
            }, function(result)
                if result[1] ~= nil then
                    local formattedLoadout = {}
                    for k,v in pairs(json.decode(result[1].loadout)) do
                        local allcomp = {}
                        local getWeap1, getWeap2 = ESX.GetWeapon(v.name)
                        if getWeap2 ~= nil then 
                            allcomp = getWeap2.components 
                        end
                        formattedLoadout[k] = {label = v.label, name = v.name, ammo = v.ammo, components = v.components, allcomponents = allcomp}
                    end
                    MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license',{
                        ['@license'] = result[1].identifier,
                    }, function(result2)
                        local toSend = result[1]
                        toSend.loadout = formattedLoadout
                        if result2[1] ~= nil then
                            toSend.account_info = result2[1]
                        end
                        TriggerClientEvent("null:staff:recevieSearchIdUniqueInfo", _src, idunique, toSend)
                    end)
                else
                    TriggerClientEvent("AdminMenu:playerAsNotSearchIdUnique", _src, nil)
                end 
            end) 
        end
    elseif type == "discord" then
        local discordId = idunique
        local found = false
        for k,v in pairs(ESX.PlayersByIdUnique) do
            if tostring(v.discord) == tostring(discordId) then
                found = v.idunique
            end
        end
        if found == false then
            MySQL.Async.fetchAll('SELECT * FROM users WHERE discord = @discord',{
                ['@discord'] = discordId,
            }, function(result)
                if result[1] ~= nil then
                    local formattedLoadout = {}
                    
                    for k,v in pairs(json.decode(result[1].loadout)) do
                        local allcomp = {}
                        local getWeap1, getWeap2 = ESX.GetWeapon(v.name)
                        if getWeap2 ~= nil then 
                            allcomp = getWeap2.components 
                        end
                        formattedLoadout[k] = {label = v.label, name = v.name, ammo = v.ammo, components = v.components, allcomponents = allcomp}
                    end

                    MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license',{
                        ['@license'] = result[1].identifier,
                    }, function(result2)
                        if result2[1] ~= nil then
                            local formattedLoadout = json.decode(result[1].loadout) or {}
                            TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, result[1].identifier, result[1].job, result[1].job2, result[1].permission_group, result[1].isDead, formattedLoadout, result2[1], json.decode(result[1].accounts), result[1])
                        else
                            TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, result[1].identifier, result[1].job, result[1].job2, result[1].permission_group, result[1].isDead, formattedLoadout, {}, json.decode(result[1].accounts), result[1])
                        end 
                    end)
                else
                    TriggerClientEvent("AdminMenu:playerAsNotSearchIdUnique", _src, nil)
                end 
            end)
        else
            MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license',{
                ['@license'] = ESX.PlayersByIdUnique[found].identifier,
            }, function(result1)
                local formattedLoadout = {}
                for k,v in pairs(ESX.PlayersByIdUnique[found].loadout) do
                    local allcomp = {}
                    local getWeap1, getWeap2 = ESX.GetWeapon(v.name)
                    if getWeap2 ~= nil then 
                        allcomp = getWeap2.components 
                    end
                    formattedLoadout[k] = {label = v.label, name = v.name, ammo = v.ammo, components = v.components, allcomponents = allcomp}
                end
                local lightFound = getLightPlayerData(ESX.PlayersByIdUnique[found])
                if result1[1] ~= nil then
                    TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, ESX.PlayersByIdUnique[found].identifier, ESX.PlayersByIdUnique[found].job.name, ESX.PlayersByIdUnique[found].job2.name, ESX.PlayersByIdUnique[found].group, false, formattedLoadout, result1[1], {}, lightFound)
                else
                    TriggerClientEvent("AdminMenu:playerAsBeenSearchIdUnique", _src, ESX.PlayersByIdUnique[found].identifier, ESX.PlayersByIdUnique[found].job.name, ESX.PlayersByIdUnique[found].job2.name, ESX.PlayersByIdUnique[found].group, false, formattedLoadout, {}, {}, lightFound)
                end 
            end)
        end
    end
end)

RegisterNetEvent('Null:sendmessage')
AddEventHandler('Null:sendmessage', function(args)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
		TriggerClientEvent('chatMessage', -1, "ANNONCE", {255, 0, 0}, '   '..args)
	end
end)


ESX.RegisterServerCallback('Null:staff2:getiduinfo', function(source, cb)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local identifier = nil

    if xPlayer ~= nil then
        if xPlayer.getGroup() == "user" then
            DropPlayer(_src, "Vous n'avez pas à faire cela !!!")
            return
        end

        MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
            ['@idunique'] = idunique,
        }, function(result)
            identifier = result[1].identifier

            if identifier == nil then
                cb(false)
            else
                cb(true)
            end
        end)
    end
end)

RegisterNetEvent("null:staff:newnotestaff")
AddEventHandler("null:staff:newnotestaff", function(Informations)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if Informations == nil then return end
    local toSave = {}
    toSave.playerInfo = {
        idunique = xPlayer.getIdunique(),
        name = xPlayer.getName(),
        note = Informations.Note,
        reportCount = 0, -- TODO save le nombre de report des players
    }
    toSave.staffInfo = {
        idunique = Informations.idu,
        name = Informations.name,
        closedReportCount = SaveData.Admin.Staffs.List[Informations.idu] ~= nil and SaveData.Admin.Staffs.List[Informations.idu].nbrReport_close_week or 0,
    }
    toSave.reportInfo = {
        timeBTWCreateAndTake = (Informations.takeattime - Informations.createdTime),
        timeBTWTakeAndClose = (Informations.closeTime - Informations.takeattime),
        createdAt = Informations.createdTime,
        takeAt = Informations.takeattime,
        closeAt = Informations.closeTime,
        description = Informations.description,
    }

    local pourcentageToBeReportFarm = 0
    if toSave.reportInfo.timeBTWCreateAndTake <= 3 then
        pourcentageToBeReportFarm += 20
    end
    if toSave.reportInfo.timeBTWTakeAndClose <= 3 then
        pourcentageToBeReportFarm += 40
    end
    if #Informations.description <= 4 then
        pourcentageToBeReportFarm += 20
    end
    if Informations.Note ~= nil and Informations.Note >= 4 then
        pourcentageToBeReportFarm += 10
    end

    toSave.Verif = {
        pourcentToBeFakeReport = pourcentageToBeReportFarm
    }

    if SaveData.json["staffsnotes"][Informations.idu] == nil then SaveData.json["staffsnotes"][Informations.idu] = {} end
    local id = #SaveData.json["staffsnotes"][Informations.idu] + 1
    SaveData.json["staffsnotes"][Informations.idu][id] = toSave
end)

ESX.RegisterServerCallback('Null:staff:getStaffNotes', function(source, cb, idunique)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["staffsnotes"][idunique] == nil then 
        cb({})
    else
        cb(SaveData.json["staffsnotes"][idunique])
    end
end)

exports("getNumberReport", function()
    local nbr, nbr2 = 0, 0
    for k,v in pairs(reportsTable) do 
        if not v.taken then
            nbr = nbr + 1 
        else
            nbr2 = nbr2 + 1 
        end
    end
    return nbr, nbr2
end)

RegisterCommand('report', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if IN_JAIL[xPlayer.identifer] ~= nil then
        TriggerClientEvent('esx:showNotification', source, "Vous ne pouvez pas faire de report en Jail/Proche de jail.")
        return
    end
    if #table.concat(args, " ") <= 2 then
        TriggerClientEvent("esx:showNotification", source, "~r~Veuillez rentrer une raison plus longue.")
    elseif #table.concat(args, " ") >= 45 then
        TriggerClientEvent("esx:showNotification", source, "~r~Veuillez rentrer une raison moins longue.")
    else
        if reportsTable[source] ~= nil then
            TriggerClientEvent("esx:showNotification", source, "~r~[Report]~s~ Vous avez déja un report actif.")
        else
            TriggerClientEvent("esx:showNotification", source, "~r~[Report]~s~ Votre report à bien été envoyer au staff.")
            TriggerClientEvent("AdminMenu:newReportNotif", -1)
            reportsCount = reportsCount + 1
            reportsTotal = reportsTotal + 1
            reportsNoTraiter = reportsNoTraiter + 1
            reportsTable[source] = { 
                streamer = xPlayer.isStreamer(), 
                timeElapsed = {0,0}, 
                uniqueId = reportsTotal, 
                id = source,
                idu = xPlayer.getIdunique(), 
                nom = GetPlayerName(source), 
                args = table.concat(args, " "), 
                createdTime = os.time(),
                createdAt = os.date('%c'), 
                takeby = "Personne", 
                taken = false 
            }
            TriggerClientEvent("null:reports:refreh", -1, reportsTable)
            NullIncrementReportMade(xPlayer.getIdunique())
            null.logs.send("Logs Joueur","Le joueur "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a fais un report : "..reportsTable[source].args.."", "create-report", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
        end
    end
end, false)

RegisterServerEvent("AdminMenu:closeReport")
AddEventHandler("AdminMenu:closeReport", function(reportId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = ESX.GetPlayers()
    if xPlayer.getGroup() == "user" then
        DropPlayer(source, "Vous n'avez pas les permission de faire cela")
        return
    end
    if not reportsTable[reportId] then
        TriggerClientEvent("esx:showNotification", source, "~b~[Report] ~s~Ce report n'est plus valide")
        return
    end

    if SaveData.Admin.Staffs.List[xPlayer.getIdunique()] ~= nil then
        local newNbrWeekClose = SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport_close_week + 1
        SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport_close_week = newNbrWeekClose
        MySQL.Async.execute("UPDATE `staff` SET `nbrReport_close_week` = @nbrReport_close_week WHERE `idunique` = @idunique", {['@nbrReport_close_week'] = newNbrWeekClose, ['@idunique'] = xPlayer.getIdunique()}, function()  end)
    end

    null.logs.send("Logs Staff","Le Staff "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a close le report de "..reportsTable[reportId].nom.." (RU"..reportId.." U"..reportsTable[reportId].idu..")", "close-report", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = reportsTable[reportId].idu, name_cible = reportsTable[reportId].nom})
    notifStaff(GetPlayerName(source).." a cloturé le report #"..reportsTable[reportId].uniqueId)
    TriggerClientEvent("null:staff:openreportnote",reportsTable[reportId].id ,{
        name = reportsTable[reportId].takeby,
        idu = reportsTable[reportId].takebyid,
        creatorIDU = reportsTable[reportId].idu,
        id = reportId,
        createdTime = reportsTable[reportId].createdTime,
        takeattime = reportsTable[reportId].takeattime,
        closeTime = os.time(),
        description = reportsTable[reportId].args,
    })
    reportsCount = reportsCount - 1
    reportsTable[reportId] = nil
    TriggerClientEvent('null:reports:refreh', -1, reportsTable)
end)

RegisterNetEvent("AdminMenu:takeReport")
AddEventHandler("AdminMenu:takeReport", function(reportId ,nomMec, raisonMec)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = ESX.GetPlayers()
    local namestaff = GetPlayerName(source)
    if xPlayer.getGroup() == "user" then  DropPlayer(source, "Vous n'avez pas les permission de faire cela") return end
    if not reportsTable[reportId] then return end
    reportsTable[reportId].takeby = GetPlayerName(source)
    reportsTable[reportId].takebyid = xPlayer.getIdunique()
    reportsTable[reportId].takeattime = os.time()
    reportsTable[reportId].taken = true
    reportsNoTraiter = reportsNoTraiter - 1

    if SaveData.Admin.Staffs.List[xPlayer.getIdunique()] ~= nil then
        local newNbr = SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport + 1
        local newNbrWeekTake = SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport_take_week + 1
        SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport = newNbr
        SaveData.Admin.Staffs.List[xPlayer.getIdunique()].nbrReport_take_week = newNbrWeekTake
        MySQL.Async.execute("UPDATE `staff` SET `nbrReport` = @nbrReport WHERE `idunique` = @idunique", {['@nbrReport'] = newNbr, ['@idunique'] = xPlayer.getIdunique()}, function()  end)
        MySQL.Async.execute("UPDATE `staff` SET `nbrReport_take_week` = @nbrReport_take_week WHERE `idunique` = @idunique", {['@nbrReport_take_week'] = newNbrWeekTake, ['@idunique'] = xPlayer.getIdunique()}, function()  end)
    end

    null.logs.send("Logs Staff","Le Staff "..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a prit le report de "..reportsTable[reportId].nom.." (RU"..reportsTable[reportId].uniqueId.." U"..reportsTable[reportId].idu..")", "take-report", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = reportsTable[reportId].idu, name_cible = reportsTable[reportId].nom})
    notifStaff(GetPlayerName(source).." a pris le report #"..reportsTable[reportId].uniqueId)
    TriggerClientEvent('null:reports:refreh', -1, reportsTable)
end)

-- Session counter task
-- TODO -> add report time elapsed
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(1000 * 60)
        for k, v in pairs(reportsTable) do
            reportsTable[k].timeElapsed[1] = reportsTable[k].timeElapsed[1] + 1
            if reportsTable[k].timeElapsed[1] > 60 then
                reportsTable[k].timeElapsed[1] = 0
                reportsTable[k].timeElapsed[2] = reportsTable[k].timeElapsed[2] + 1
            end
        end
    end
end))

RegisterNetEvent("null:staff:requestGroupVerif", function(target)
    if target ~= nil then 
        local src = target
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer.getGroup() ~= "user" then
            TriggerClientEvent("null:staff:recevieRequestGroup", src, {true, xPlayer.getGroup()})
        else
            TriggerClientEvent("null:staff:recevieRequestGroup", src, {false,"user"})
        end
    else
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer.getGroup() ~= "user" then
            TriggerClientEvent("null:staff:recevieRequestGroup", src, {true, xPlayer.getGroup()})
        else
            TriggerClientEvent("null:staff:recevieRequestGroup", src, {false,"user"})
        end
    end
end)

ESX.RegisterServerCallback("AdminMenu:getGroupForNotif", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        cb(xPlayer.getGroup())
    end
end)


Citizen.CreateThread(function()
    Config.TypeMarker = {}
    Config.HeightMarker = {}
    Config.RotateMarker = {}
    for i = 1, 43 do
        table.insert(Config.TypeMarker, i)
    end
    for i = 1, 10 do
        table.insert(Config.HeightMarker, i)
    end
    for i = 1, 8 do
        table.insert(Config.RotateMarker, i)
    end

end)

if SaveData.StaffWithBlips == nil then SaveData.StaffWithBlips = {} end

RegisterNetEvent("null:staff:activeBlips", function(bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if bool == false then bool = nil end
    SaveData.StaffWithBlips[xPlayer.source] = bool
end)
--[[
Citizen.CreateThread(function()
    Wait(5000)
    while true do
        Wait(2000)
        for k,v in pairs(ESX.PlayersByIdUnique) do
            local Coords = GetEntityCoords(v.ped)
            SaveData.Admin.PlayersBlips[v.source] = {x = Coords.x, y = Coords.y}
        end
        ::continue::
    end
end)

Citizen.CreateThread(function()
    Wait(5000)
    while true do
        Wait(2000)
        for k,v in pairs(SaveData.StaffWithBlips) do
            TriggerClientEvent("null:staff:recevieBlips", k, SaveData.Admin.PlayersBlips)
        end
    end
end)]]


ESX.RegisterServerCallback("AdminMenu:getGroupForNotif", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        cb(xPlayer.getGroup())
    end
end)

Citizen.CreateThread(function()
    Config.TypeMarker = {}
    Config.HeightMarker = {}
    Config.RotateMarker = {}
    for i = 1, 43 do
        table.insert(Config.TypeMarker, i)
    end
    for i = 1, 10 do
        table.insert(Config.HeightMarker, i)
    end
    for i = 1, 8 do
        table.insert(Config.RotateMarker, i)
    end
end)
