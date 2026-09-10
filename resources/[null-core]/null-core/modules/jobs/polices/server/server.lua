local PoliceCounter = 0
while SaveData.json == nil do Wait(10) end
while SaveData.json["entreprises"] == nil do Wait(10) end
while SaveData.json["entreprises"]["Police"] == nil do Wait(10) end

RegisterNetEvent('Null:createpolice', function(namejob, labeljob, PosVestiaire, PosArmory, PosBoss, color, Cellule)
    local xPlayer = ESX.GetPlayerFromId(source)

    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Police"][namejob] ~= nil then 
            xPlayer.showNotification('Ce police job existe déjà.')
            return
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Chef", "boss", 6)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Capitaine", "intendent", 5)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Lieutenant", "lieutenant", 4)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Sergent", "chef", 3)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Caporal", "sergeant", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Officier", "officer", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Recrue", "recruit", 0)
        PoliceCounter = PoliceCounter +1
        SaveData.json["entreprises"]["Police"][namejob] = {}
        SaveData.json["entreprises"]["Police"][namejob].type =  "Police"
        SaveData.json["entreprises"]["Police"][namejob].name = namejob
        SaveData.json["entreprises"]["Police"][namejob].label = labeljob
        SaveData.json["entreprises"]["Police"][namejob].PosVestiaire = PosVestiaire
        SaveData.json["entreprises"]["Police"][namejob].PosArmory = PosArmory
        SaveData.json["entreprises"]["Police"][namejob].PosBoss = PosBoss
        SaveData.json["entreprises"]["Police"][namejob].cellule = Cellule
        SaveData.json["entreprises"]["Police"][namejob].color = color
        SaveData.json["entreprises"]["Police"][namejob].sprite = 60

        Cache.SaveOne('entreprises')
        TriggerClientEvent('esx:showNotification', source, 'Le Job à été crée avec succès.')
        Wait(1000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
        TriggerClientEvent('Null:receivePolice', -1, SaveData.json["entreprises"]["Police"])
        TriggerClientEvent('Null:receivePolice2', -1, SaveData.json["entreprises"]["Police"])
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation mécano (0)")
    end
end)

RegisterNetEvent('Null:initPolice', function()
	TriggerClientEvent('Null:receivePolice', source, SaveData.json["entreprises"]["Police"])
    TriggerClientEvent('Null:receivePolice2', -1, SaveData.json["entreprises"]["Police"])
end)

RegisterNetEvent('Null:DeletePolice', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.json["entreprises"]["Police"][value] then
			SaveData.json["entreprises"]["Police"][value] = nil
            PoliceCounter = PoliceCounter - 1
            Cache.SaveOne('entreprises')
            TriggerClientEvent('Null:receivePolice', -1, SaveData.json["entreprises"]["Police"])
            TriggerClientEvent('Null:receivePolice2', -1, SaveData.json["entreprises"]["Police"])
            TriggerClientEvent('Null:deletepoliceblips', -1, value)
        else
            print("Tentative de suppression d'une entreprise inexistante ("..value..")")
		end
	end
end)


local ArmedeServiceList = {}



RegisterNetEvent("null:policebuilder:takearmory")
AddEventHandler("null:policebuilder:takearmory", function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "null:policebuilder:takearmory") 
    if ArmedeServiceList[xPlayer.getIdunique()] == nil then ArmedeServiceList[xPlayer.getIdunique()] = {} end
    if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
        local Armory = ArmesPolice[xPlayer.job.name]
        if Armory == nil then return end
        for k,v in pairs(Armory["foreveryone"]) do
            if v.type == "weapon" then
                xPlayer.addWeapon(v.name, 1, {
                    police = true,
                }, false, true)
                ArmedeServiceList[xPlayer.getIdunique()][v.name] = {type = v.type, time = os.time()}
            elseif v.type == "item" then
                xPlayer.addInventoryItem(v.name, v.count or 1)
                ArmedeServiceList[xPlayer.getIdunique()][v.name] = {type = v.type, time = os.time(), count = v.count or 1}
            end
        end 
        if Armory[xPlayer.job.grade_name] then
            for k,v in pairs(Armory[xPlayer.job.grade_name]) do
                if v.type == "weapon" then
                    xPlayer.addWeapon(v.name, 1, {
                        police = true,
                    }, false, true)
                    ArmedeServiceList[xPlayer.getIdunique()][v.name] = {type = v.type, time = os.time()}
                elseif v.type == "item" then
                    xPlayer.addInventoryItem(v.name, v.count or 1)
                    ArmedeServiceList[xPlayer.getIdunique()][v.name] = {type = v.type, time = os.time(), count = v.count or 1}
                end
            end 
        end
    else
        TriggerEvent("BanSql:ICheatServer", source, "Trigger Event Police Armory")
    end
end)

RegisterNetEvent("null:police:removeservice", function()
    local src = source;
    local xPlayer = ESX.GetPlayerFromId(src);
    if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
        local Armory = ArmesPolice[xPlayer.job.name]
        if Armory == nil then return end
        for k,v in pairs(Armory["foreveryone"]) do
            if v.type == "weapon" then
                xPlayer.removeWeapon(v.name)
                ArmedeServiceList[xPlayer.getIdunique()][v.name] = nil
            elseif v.type == "item" then
                local item = xPlayer.getInventoryItem(v.name)
                if item and item.count > 0 then
                    xPlayer.removeInventoryItem(v.name, item.count)
                end
                ArmedeServiceList[xPlayer.getIdunique()][v.name] = nil
            end
        end 
        if Armory[xPlayer.job.grade_name] then
            for k,v in pairs(Armory[xPlayer.job.grade_name]) do
                if v.type == "weapon" then
                    xPlayer.removeWeapon(v.name)
                    ArmedeServiceList[xPlayer.getIdunique()][v.name] = nil
                elseif v.type == "item" then
                    local item = xPlayer.getInventoryItem(v.name)
                    if item and item.count > 0 then
                        xPlayer.removeInventoryItem(v.name, item.count)
                    end
                    ArmedeServiceList[xPlayer.getIdunique()][v.name] = nil
                end
            end 
        end
    end
end);


local IsinTig = {}
local SaveTIG = {}

function BackInTig(target, time, author, job)
    local xPlayer = ESX.GetPlayerFromId(target)
    IsinTig[target] = {}
    IsinTig[target].time = time
    IsinTig[target].author = author
    IsinTig[target].job = job
    TriggerClientEvent("Police:SendSomeoneInTig", target, time, author)
end

RegisterServerEvent("Police:SendInfoTigs")
AddEventHandler("Police:SendInfoTigs", function(playerid, time)
    local author = GetPlayerName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
        BackInTig(playerid, time*60, author, "police")
        xPlayer.showNotification("Vous avez placé " .. GetPlayerName(playerid) .. " en T.I.G pendant " .. time .. " minute(s).")
    else
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche flic (0)")
    end
end)

AddEventHandler("Police:OutofTig", function(target)
    IsinTig[target] = {}
    IsinTig[target].time = 0
end)

RegisterServerEvent("Police:SendTigTime")
AddEventHandler("Police:SendTigTime", function()
    local src = source
    if IsinTig[src].time > 1 then
        IsinTig[src].time = IsinTig[src].time - 1
    else
        local xPlayer = ESX.GetPlayerFromId(src)
        TriggerClientEvent("Police:OutofTig", src)
        MySQL.Async.fetchAll("SELECT * FROM users_tig WHERE identifier = @identifier", {
            ["@identifier"] = xPlayer.identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute("DELETE FROM `users_tig` WHERE identifier = @identifier", {
                    ["@identifier"] = xPlayer.identifier
                })
            end
        end)
        IsinTig[src] = {}
        IsinTig[src].time = 0  
    end
end)

RegisterServerEvent("Police:SendTigTime2")
AddEventHandler("Police:SendTigTime2", function(timer)
    local src = source
    if IsinTig[src].time > 1 then
        IsinTig[src].time = IsinTig[src].time - timer
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.Async.fetchAll("SELECT * FROM users_tig WHERE identifier = @identifier", {
        ["@identifier"] = xPlayer.identifier
    }, function(result)
        if result[1] then
            BackInTig(src, tonumber(result[1].time), result[1].author, "police")
        else
            IsinTig[src] = {}
            IsinTig[src].time = 0  
        end
    end)

    if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
        if ArmedeServiceList[xPlayer.getIdunique()] ~= nil then
            Wait(5000)
            TriggerClientEvent("null:job:police:armeservice",source,true)
            xPlayer.showNotification("⏲ Vous avez quitter en service, vos armes de service vous ont était rendu.")
            local time = os.time()
            for k,v in pairs(ArmedeServiceList[xPlayer.getIdunique()]) do
                if (time - v.time) > 10*60 then
                    ArmedeServiceList[xPlayer.getIdunique()][k] = nil
                    goto continue
                end
                if v.type == "weapon" then
                    xPlayer.addWeapon(v.name, 1, {
                        police = true,
                    }, false, true)
                elseif v.type == "item" then
                    xPlayer.addInventoryItem(v.name, v.count or 1)
                end
                ::continue::
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not IsinTig[src] then return end

    if IsinTig[src].time > 1 then
        MySQL.Async.fetchAll("SELECT * FROM users_tig WHERE identifier = @identifier", {
            ["@identifier"] = xPlayer.identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute("UPDATE users_tig SET time = @time WHERE identifier = @identifier", {
                    ["@identifier"] = xPlayer.identifier,
                    ["@time"] = IsinTig[src].time
                })
            else
                MySQL.Async.execute("INSERT INTO `users_tig`(`identifier`, `time`, `author`, `job`) VALUES (@identifier,@time,@author,@job)", {
                    ["@identifier"] = xPlayer.identifier,
                    ["@time"] = IsinTig[src].time,
                    ["@author"] = IsinTig[src].author,
                    ["@job"] = IsinTig[src].job
                })
            end
        end)
    else
        MySQL.Async.execute("DELETE FROM `users_tig` WHERE identifier = @identifier", {
            ["@identifier"] = xPlayer.identifier
        })
    end

    if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
        if ArmedeServiceList[xPlayer.getIdunique()] ~= nil then
            for k,v in pairs(ArmedeServiceList[xPlayer.getIdunique()]) do
                if v.type == "weapon" then
                    if xPlayer.hasWeapon(v.name) then
                        xPlayer.removeWeapon(v.name, 1)
                    else
                        ArmedeServiceList[xPlayer.getIdunique()][v.name] = nil
                    end
                elseif v.type == "item" then
                    local item = xPlayer.getInventoryItem(v.name)
                    if item and item.count > 0 then
                        xPlayer.removeInventoryItem(v.name, item.count)
                    end
                    ArmedeServiceList[xPlayer.getIdunique()][v.name].count = item.count
                end
            end
        end
    end
end)
