Fleeca = Fleeca or {}
Fleeca.BanksRobbed = {}
local FleecainRob = {}

Citizen.CreateThread(function()
    while not SaveData.cacheLoad do Wait(10) end
    local final = {}
    if SaveData.json["robbery"] == nil then SaveData.json["robbery"] = {} end
    if SaveData.json["robbery"]["fleeca"] == nil then SaveData.json["robbery"]["fleeca"] = {} end
    for k,v in pairs(SaveData.json["robbery"]["fleeca"]) do
        if v.label == nil then v.label = "Fleeca Bank" end
        table.insert(final, v)
    end
    SaveData.json["robbery"]["fleeca"] = final
end)

local function OpenDoor(getObjdoor, doorpos, id, type)
    TriggerClientEvent("Fleeca:OpenDoor", -1, getObjdoor, doorpos, id, type)
    if id then
        FleecainRob[id] = {}
    end
end

local function CloseDoor(getObjdoor, doorpos)
    TriggerClientEvent("Fleeca:CloseDoor", -1, getObjdoor, doorpos)
end


local function CheckCopsOnDuty(source, type, id, fleecatype)
    local Players = ESX.GetPlayers()
    local CopsOnDuty = 0

    for i = 1, #Players do
        local player = ESX.GetPlayerFromId(Players[i])
        if SaveData.json["entreprises"]["Police"][player.job.name] ~= nil then
            CopsOnDuty = CopsOnDuty + 1
        end
    end
    if fleecatype == 2 then
        if type == "door" then
            if CopsOnDuty >= Fleeca.RequiredCops then
                if Fleeca.BanksRobbed == nil then Fleeca.BanksRobbed = {} end
                if Fleeca.BanksRobbed[id] then
                    if (os.time() - Fleeca.CoolDown) > Fleeca.BanksRobbed[id] then
                        Fleeca.BanksRobbed[id] = os.time()
                        TriggerClientEvent("Fleeca:startFleeca", source, id, type, fleecatype)
                    else
                        TriggerClientEvent("esx:showNotification", source, Fleeca.Locale.BankCoolDown)
                    end
                else
                    --Fleeca.BanksRobbed[id] = os.time()
                    TriggerClientEvent("Fleeca:startFleeca", source, id, type, fleecatype)
                end
            else
                TriggerClientEvent("esx:showNotification", source, Fleeca.Locale.NoCops)
            end
        else
            TriggerClientEvent("Fleeca:startHackVault", source, id)
        end
    else
        if CopsOnDuty >= Fleeca.RequiredCops then
            if Fleeca.BanksRobbed == nil then Fleeca.BanksRobbed = {} end
            if Fleeca.BanksRobbed[id] then
                if (os.time() - Fleeca.CoolDown) > Fleeca.BanksRobbed[id] then
                    Fleeca.BanksRobbed[id] = os.time()
                    TriggerClientEvent("Fleeca:startFleeca", source, id, type, fleecatype)
                else
                    TriggerClientEvent("esx:showNotification", source, Fleeca.Locale.BankCoolDown)
                end
            else
                Fleeca.BanksRobbed[id] = os.time()
                TriggerClientEvent("Fleeca:startFleeca", source, id, type, fleecatype)
            end
        else
            TriggerClientEvent("esx:showNotification", source, Fleeca.Locale.NoCops)
        end
    end
end

RegisterNetEvent("null:fleeca:heistDrill", function(id, drillid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if not id or not drillid then return end
    if SaveData.json["robbery"]["fleeca"][id] == nil then return end
    if FleecainRob[id] == nil then return end
    if FleecainRob[id][drillid] ~= nil then return end
    local fleeca = SaveData.json["robbery"]["fleeca"][id]
    local coords = fleeca.hackPos.pos
    local distance = #(vector3(coords.x, coords.y, coords.z) - xPlayer.getCoords())
    if distance >= 100.0 then return end
    FleecainRob[id][drillid] = true
    TriggerClientEvent("Fleeca:HeistDrill", -1, id, drillid)
    local money = math.random(fleeca.moneywin.min, fleeca.moneywin.max)
    xPlayer.addAccountMoney("dirtycash", money)
    xPlayer.showNotification("Vous avez volé ~y~"..money.."$.")

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        --exports["null-core"]:ProgressGangMission(gangname, "daily_robbery_atm", 1)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_robbery_bank", 1)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_robbery_spree", 1)
        exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", money)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", money)
        exports["null-core"]:AddGangXP(gangname, 100)
    end
end)

RegisterServerEvent("Fleeca:OpenDoor")
AddEventHandler("Fleeca:OpenDoor", OpenDoor)

RegisterServerEvent("Fleeca:CloseDoor")
AddEventHandler("Fleeca:CloseDoor", CloseDoor)

RegisterServerEvent("Fleeca:getFleeca")
AddEventHandler("Fleeca:getFleeca", function()
    TriggerClientEvent("Fleeca:getFleeca", source, SaveData.json["robbery"]["fleeca"])
end)

RegisterServerEvent("Staff:Fleeca:Create")
AddEventHandler("Staff:Fleeca:Create", function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil then return end
    if not xPlayer.getPermission("gestion_builder") then return end
    
    local id = #SaveData.json["robbery"]["fleeca"] + 1

    if data.rewards == nil then data.rewards = Fleeca.DefaultReward end

    SaveData.json["robbery"]["fleeca"][id] = {
        id = id,
        label = data.label or "Fleeca Bank",
        hackPos = data.hackPos,
        otherDoors = data.addDoor,
        --hackPos2 = data.hackPos2,
        vaultPos = data.vaultPos,
        zone = data.zone,
        drills = data.drills,
        vault = data.vault,
        --door = data.door,
        vaultprops = data.vault.finalSelect,
        moneywin = {
            min = data.rewards[1],
            max = data.rewards[2],
        }
    }
    xPlayer.showNotification("Braquage : #"..id.." à était créer. (Prochain reboot)")
    TriggerClientEvent("Fleeca:getFleeca", -1, SaveData.json["robbery"]["fleeca"])
end)

RegisterServerEvent("null:fleeca:braquage:supp")
AddEventHandler("null:fleeca:braquage:supp", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil then return end
    if not xPlayer.getPermission("gestion_builder") then return end
    
    SaveData.json["robbery"]["fleeca"][id] = nil
    xPlayer.showNotification("Braquage : #"..id.." à était supprimer. (Prochain reboot)")
    TriggerClientEvent("Fleeca:getFleeca", -1, SaveData.json["robbery"]["fleeca"])
end)

ESX.RegisterUsableItem("hack_laptop", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("null:inventory:closeinv", source)
    local selectFleecaId = nil
    local selectType = "vault"
    local FleecaType = 1
    local playerCoords = xPlayer.getCoords()
    for k,v in pairs(SaveData.json["robbery"]["fleeca"]) do
        local distancefirst = #(vector3(v.hackPos.pos.x, v.hackPos.pos.y, v.hackPos.pos.z) - playerCoords)
        if distancefirst < 100.0 then
            if #v.otherDoors > 0 then
                FleecaType = 2
                local distance = #(vector3(v.hackPos.pos.x, v.hackPos.pos.y, v.hackPos.pos.z) - playerCoords)
                local MinDistance = nil
                for k2, v2 in pairs(v.otherDoors) do 
                    local distance2 = #(vector3(v2.hackpos.pos.x, v2.hackpos.pos.y, v2.hackpos.pos.z) - playerCoords)
                    if MinDistance and MinDistance > distance2 then
                        MinDistance = distance2
                    elseif MinDistance == nil then
                        MinDistance = distance2
                    end
                end
                print(distance, MinDistance)
                if distance <= 2.0 then
                    selectType = "vault"
                    selectFleecaId = k
                    break
                elseif MinDistance <= 2.0 then
                    selectType = "door"
                    selectFleecaId = k
                    break
                end
            else
                FleecaType = 1
                local coords = vector3(v.hackPos.pos.x, v.hackPos.pos.y, v.hackPos.pos.z)
                local distance = #(coords - playerCoords)
                if distance <= 2.0 then
                    selectType = "vault"
                    selectFleecaId = k
                    break
                end
            end
        end
    end
    if selectFleecaId == nil then 
        xPlayer.showNotification("❌ Vous devez être proche d'un terminal d'accès.")
        return 
    end
    CheckCopsOnDuty(source, selectType, selectFleecaId, FleecaType)
end)