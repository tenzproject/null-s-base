SocietyCache  = {}
SocietyList   = {}
BarSocietyList = {}

local function defaultData()
    return { weapons = {}, items = {}, accounts = { cash = 0, dirtycash = 0 } }
end

local function applyEnterpriseMetadata(name)
    for _, bucket in pairs(SaveData.json["entreprises"]) do
        for _, ent in pairs(bucket) do
            if ent.name == name and SocietyList[name] then
                SocietyList[name].type        = ent.type
                SocietyList[name].brandColor  = ent.brandColor  or "#3498db"
                SocietyList[name].logo        = ent.logo        or ""
                SocietyList[name].description = ent.description or ""
                if ent.PosBoss then SocietyList[name].position = ent.PosBoss end
                return
            end
        end
    end
end

function addHistorySociety(society, label, info, count)
    MySQL.Async.execute("INSERT INTO `vhistoriquesociety` (`society`, `label`, `info`, `count`) VALUES (@society, @label, @info, @count)", {
        ['@society'] = society, ['@label'] = label, ['@info'] = info, ['@count'] = count,
    })
end

function SaveSociety(name)
    local entry = SocietyCache[name]
    if not entry or not entry.data then return end
    MySQL.Async.execute("UPDATE society SET data = @data WHERE name = @name", {
        ["@name"] = name, ["@data"] = json.encode(entry.data),
    })
end

function SaveAllSociety()
    for name, entry in pairs(SocietyCache) do
        if entry.data then
            if not entry.data.politique then entry.data.politique = {} end
            local societyType = SocietyList[name] and SocietyList[name].type
            if societyType then
                for k, v in pairs(Config.Society.Politique) do
                    if entry.data.politique[k] == nil then
                        if type(v.type) == "table" then
                            for _, y in pairs(v.type) do
                                if y == societyType or y == "All" then entry.data.politique[k] = v.default end
                            end
                        elseif v.type == societyType or v.type == "All" then
                            entry.data.politique[k] = v.default
                        end
                    end
                end
            end
            MySQL.Async.execute("UPDATE society SET data = @data WHERE name = @name", {
                ["@name"] = name, ["@data"] = json.encode(entry.data),
            })
        end
    end
end

function RemoveTaxesOfAmount(type, amount, addtogouv, job, name)
    local toRemove = amount * (SaveData.json["taxes"][type] / 100)
    local final    = amount - toRemove
    if addtogouv then
        addHistorySociety("gouvernement", "Gains : Taxes (" .. type .. ")", "De l'entreprise: " .. job .. "\nType de taxes: " .. type, toRemove)
        SocietyCache["gouvernement"].data["accounts"].cash = SocietyCache["gouvernement"].data["accounts"].cash + toRemove
        SaveSociety("gouvernement")
        if name then
            if not SocietyCache[name].data["taxes"] then SocietyCache[name].data["taxes"] = 0 end
            SocietyCache[name].data["taxes"] = SocietyCache[name].data["taxes"] + toRemove
            SaveSociety(name)
        end
    end
    return final, toRemove
end

function GetSalary(typesalary)
    if not typesalary then return SaveData.json["salary"] end
    return SaveData.json["salary"][typesalary] or SaveData.json["salary"]
end

RegisterNetEvent("Core:InitAllJob")
AddEventHandler("Core:InitAllJob", function(ESXJOB)
    ESX.Jobs = ESXJOB
    MySQL.Async.fetchAll('SELECT name FROM jobs', {}, function(result)
        if result then
            for _, v in pairs(result) do TriggerEvent('Null:esx_phone:registerNumber', v.name, v.name, true, true) end
        end
    end)
end)

RegisterNetEvent("Null:gouvernement")
AddEventHandler("Null:gouvernement", function(ESXJOB)
    TriggerEvent("Core:InitAllJob", ESXJOB)
end)

RegisterNetEvent("Null:gouv:updateSalary")
AddEventHandler("Null:gouv:updateSalary", function(salarytype, value, type2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.getJob().name ~= "gouvernement" then return end
    SaveData.json["salary"][salarytype][type2] = value
    TriggerClientEvent("Null:updateSalary", -1, GetSalary())
end)

RegisterNetEvent("Null:gouv:updateTaxes")
AddEventHandler("Null:gouv:updateTaxes", function(taxes, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.getJob().name ~= "gouvernement" then return end
    SaveData.json["taxes"][taxes] = value
    TriggerClientEvent("Null:updateTaxes", -1, SaveData.json["taxes"])
end)

local function LoadSociety(name, cb)
    MySQL.Async.fetchAll('SELECT * FROM society WHERE name = @name', { ['@name'] = name }, function(data)
        if data and data[1] then
            local v = data[1]
            SocietyCache[v.name] = { name = v.name, data = json.decode(v.data) or defaultData(), state = false }
            if v.legal and not SocietyList[v.name] then
                SocietyList[v.name] = { name = v.name, label = v.label, state = false, PlyList = {} }
                applyEnterpriseMetadata(v.name)
                MySQL.Async.fetchAll('SELECT * FROM users WHERE job = @job', { ['@job'] = v.name }, function(result)
                    if result then
                        for _, u in pairs(result) do
                            SocietyList[v.name].PlyList[u.idunique] = {
                                name = u.name, firstname = u.firstname, lastname = u.lastname,
                                idunique = u.idunique, job = u.job, job_grade = u.job_grade,
                                job2 = u.job2, job2_grade = u.job2_grade, identifier = u.identifier,
                            }
                        end
                    end
                end)
            end
        end
        if cb then cb() end
    end)
end

local function InitSociety()
    MySQL.Async.fetchAll('SELECT * FROM society', {}, function(data)
        SocietyCache = {}
        SocietyList = {}

        for _, v in pairs(data) do
            SocietyCache[v.name] = { name = v.name, data = json.decode(v.data) or defaultData(), state = false }
            if v.legal then
                local jobName = v.name
                SocietyList[jobName] = { name = jobName, label = v.label, state = false, PlyList = {} }
                applyEnterpriseMetadata(jobName)
                MySQL.Async.fetchAll('SELECT * FROM users WHERE job = @job', { ['@job'] = jobName }, function(result)
                    if result then
                        for _, u in pairs(result) do
                            SocietyList[jobName].PlyList[u.idunique] = {
                                name = u.name, firstname = u.firstname, lastname = u.lastname,
                                idunique = u.idunique, job = u.job, job_grade = u.job_grade,
                                job2 = u.job2, job2_grade = u.job2_grade, identifier = u.identifier,
                            }
                        end
                    end
                end)
            end
        end
    end)
end

function InitSociety2()
    InitSociety()
end

RegisterNetEvent('vFrame:setjob')
AddEventHandler('vFrame:setjob', function(job, lastJob)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if SocietyList[lastJob] then SocietyList[lastJob].PlyList[xPlayer.getIdunique()] = nil end
    if not SocietyList[job] then return end
    SocietyList[job].PlyList[xPlayer.getIdunique()] = {
        name = xPlayer.getName(), firstname = xPlayer.firstname, lastname = xPlayer.lastname,
        idunique = xPlayer.idunique, job = xPlayer.getJob().name, job_grade = xPlayer.getJob().grade,
        job2 = xPlayer.getJob2().name, job2_grade = xPlayer.getJob2().grade, identifier = xPlayer.identifier,
    }
end)

ESX.RegisterServerCallback("Null:GetMemberOfSociety", function(source, cb, type, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end
    if type == "staff" then
        if Config.GroupeHighPerm[xPlayer.getGroup()] ~= true then return cb({}) end
        if not SocietyList[name] then return cb({}) end
        cb(SocietyList[name].PlyList, ESX.Jobs[name] and ESX.Jobs[name].grades or {})
    elseif type == "boss" then
        if xPlayer.getJob().name ~= name and xPlayer.getJob().name ~= "gouvernement" then return cb({}) end
        if not SocietyList[name] then return cb({}) end
        cb(SocietyList[name].PlyList, ESX.Jobs[name] and ESX.Jobs[name].grades or {})
    end
end)

RegisterNetEvent('vsociety:updateSocietyStatus')
AddEventHandler('vsociety:updateSocietyStatus', function(societyname, state)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if not SocietyList[societyname] then SocietyList[societyname] = {} end
    SocietyList[societyname].state = state
    local label = SocietyList[societyname].label
    local displayName = (not label or label == "Aucun") and societyname or label
    local msg  = state and "L'entreprise est désormais ~g~Disponible~s~" or "L'entreprise est désormais ~r~Indisponible~s~"
    local logo = SocietyList[societyname].logo ~= "" and SocietyList[societyname].logo or nil
    TriggerClientEvent('null:notificationAdvanced', -1, msg, displayName, "Annonce", SocietyList[societyname].brandColor, logo)
end)

RegisterNetEvent("null:sendSocietyNotifToSource")
AddEventHandler("null:sendSocietyNotifToSource", function(jobName, msg, title, subject)
    local _source = source
    local logo, color
    if SocietyList[jobName] then
        logo  = SocietyList[jobName].logo ~= "" and SocietyList[jobName].logo or nil
        color = SocietyList[jobName].brandColor
        title = title or SocietyList[jobName].label or jobName
    end
    TriggerClientEvent("null:notificationAdvanced", _source, msg, title, subject, color, logo)
end)

RegisterNetEvent('vsociety:changelabelsociety')
AddEventHandler('vsociety:changelabelsociety', function(societyname, newname)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    if not newname or newname == "" then return end
    local myjob = xPlayer.getJob().name
    if myjob ~= societyname and myjob ~= "gouvernement" then return end
    MySQL.Async.execute("UPDATE society SET label = @label WHERE name = @name", {
        ["@name"] = societyname, ["@label"] = newname,
    })
    if SocietyList[societyname] then SocietyList[societyname].label = newname end
    TriggerClientEvent('esx:showNotification', _source, 'Vous avez changé le nom de votre entreprise en : ' .. newname)
    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. _source .. " U" .. xPlayer.getIdunique() .. ") a changé le nom de son entreprise en " .. newname, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
end)

Citizen.CreateThread(function()
    while SaveData.json == nil or SaveData.json["salary"] == nil do Wait(10) end
    if not SaveData.json["salary"]["Primes"] then
        SaveData.json["salary"]["Primes"] = { min = 0, max = 10000 }
    end
    for _, v in pairs(SaveData.json["entreprises"]["Bar"] or {}) do
        BarSocietyList[v.name] = { name = v.name, label = v.label }
    end
    InitSociety()
end)

Citizen.CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        SaveAllSociety()
    end
end)

RegisterCommand("savesociety", function(source)
    if source == 0 then SaveAllSociety() end
end)






RegisterNetEvent("Core:AddMoneyBusiness")
AddEventHandler("Core:AddMoneyBusiness", function(position, ActionType, societyInfo, moneyType, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not SocietyCache[societyInfo.name] then return end
    if #(GetEntityCoords(GetPlayerPed(_source)) - position) >= 8 then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (6)")
        return
    end
    if ActionType ~= "deposit" then return end
    if moneyType ~= "cash" and moneyType ~= "dirtycash" then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (5)")
        return
    end
    if xPlayer.getAccount(moneyType).money < amount or amount <= 0 then
        xPlayer.showNotification("Vous n'avez pas cette quantité.")
        return
    end
    SocietyCache[societyInfo.name].data["accounts"][moneyType] = SocietyCache[societyInfo.name].data["accounts"][moneyType] + amount
    SaveSociety(societyInfo.name)
    null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. _source .. " U" .. xPlayer.getIdunique() .. ") a déposé " .. amount .. "$ (" .. moneyType .. ")", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    TriggerClientEvent("Core:UpdateCoffreSociety", _source, SocietyCache[societyInfo.name].data, 0)
end)

RegisterNetEvent("Core:AddMoneyToSocietyCache")
AddEventHandler("Core:AddMoneyToSocietyCache", function(position, ActionType, societyInfo, moneyType, amount, job2)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not SocietyCache[societyInfo.name] then return end
    local playerJob = job2 and xPlayer.job2.name or xPlayer.job.name
    if playerJob ~= societyInfo.name then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (12)")
        return
    end
    if #(GetEntityCoords(GetPlayerPed(_source)) - position) >= 8 then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (17)")
        return
    end
    if moneyType ~= "cash" and moneyType ~= "dirtycash" then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (14)")
        return
    end
    local accounts = SocietyCache[societyInfo.name].data["accounts"]
    if ActionType == "deposit" then
        if xPlayer.getAccount(moneyType).money < amount or amount <= 0 then
            xPlayer.showNotification("~g~Coffre entreprise~s~\nVous n'avez pas cette quantité.")
            return
        end
        accounts[moneyType] = accounts[moneyType] + amount
        xPlayer.removeAccountMoney(moneyType, amount)
        addHistorySociety(societyInfo.name, "Gains : Dépot d'" .. (moneyType == "cash" and "Argent" or "Argent Sale"), "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.idunique .. ")", amount)
        SaveSociety(societyInfo.name)
        xPlayer.showNotification("~g~Coffre entreprise~s~\nVous avez déposé " .. amount .. " (" .. moneyType .. ") dans le coffre.")
        null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. _source .. " U" .. xPlayer.getIdunique() .. ") a déposé " .. amount .. "$ (" .. moneyType .. ")", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    elseif ActionType == "remove" then
        if accounts[moneyType] < amount or amount <= 0 then
            xPlayer.showNotification("~g~Coffre entreprise~s~\nIl n'y a pas cette quantité.")
            return
        end
        accounts[moneyType] = accounts[moneyType] - amount
        addHistorySociety(societyInfo.name, "Dépense : Retrait d'" .. (moneyType == "cash" and "Argent" or "Argent Sale"), "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.idunique .. ")", -amount)
        SaveSociety(societyInfo.name)
        if moneyType == "cash" then
            local newamount, toreduc = RemoveTaxesOfAmount("retrait", amount, true, societyInfo.label, societyInfo.name)
            xPlayer.addAccountMoney(moneyType, newamount)
            xPlayer.showNotification("~g~Coffre~s~\nVous avez pris " .. amount .. "$.\n~b~Gouvernement~s~: -" .. toreduc .. "$ (" .. SaveData.json["taxes"].retrait .. "%)")
        else
            xPlayer.addAccountMoney(moneyType, amount)
            xPlayer.showNotification("~g~Coffre entreprise~s~\nVous avez pris " .. amount .. " (" .. moneyType .. ") du coffre.")
        end
        null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. _source .. " U" .. xPlayer.getIdunique() .. ") a retiré " .. amount .. "$ (" .. moneyType .. ")", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    else
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (16)")
        return
    end
    TriggerClientEvent("Core:UpdateCoffreSociety", _source, SocietyCache[societyInfo.name].data, 0)
end)

ESX.RegisterServerCallback("Core:GetSocietyInfo", function(source, cb, society)
    if not society then return cb(nil, 0) end
    if SocietyCache[society] then return cb(SocietyCache[society], 0) end
    LoadSociety(society, function()
        if SocietyCache[society] then
            cb(SocietyCache[society], 0)
        else
            print("[^1Null^7] Société introuvable en DB: " .. tostring(society))
            cb(nil, 0)
        end
    end)
end)

RegisterNetEvent('Null:EditPolitique')
AddEventHandler('Null:EditPolitique', function(index, value, job)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if job ~= xPlayer.job.name and xPlayer.job.name ~= "gouvernement" then return end
    if not SocietyCache[job] or xPlayer.job.grade_name ~= "boss" then return end
    if not SocietyCache[job].data.politique then SocietyCache[job].data.politique = {} end
    SocietyCache[job].data.politique[index] = value
    SaveSociety(job)
    TriggerClientEvent("null:reciveNewPolitique", -1, job, value)
end)

ESX.RegisterServerCallback("Core:GetSocietyHistorique", function(source, cb, society, type)
    local query  = 'SELECT * FROM `vhistoriquesociety` WHERE `society` = @society'
    local params = { ['@society'] = society }
    if type == "mecano" then
        query = query .. ' AND `type` = @type'
        params['@type'] = type
    end
    MySQL.Async.fetchAll(query .. ' ORDER BY id DESC LIMIT 200', params, function(result)
        if result then
            for _, v in pairs(result) do
                if v.time then v.time = os.date('%Y-%m-%d %H:%M:%S', v.time / 1000) end
            end
            cb(result)
        else
            cb({})
        end
    end)
end)

RegisterNetEvent("null:entreprise:updateBrand")
AddEventHandler("null:entreprise:updateBrand", function(entrepriseType, jobname, brand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.GroupeHighPerm or not Config.GroupeHighPerm[xPlayer.getGroup()] then return end
    if not entrepriseType or not jobname or not brand then return end
    if not SaveData or not SaveData.json or not SaveData.json["entreprises"] then return end
    local bucket = SaveData.json["entreprises"][entrepriseType]
    if not bucket or not bucket[jobname] then return end
    local data = bucket[jobname]
    data.brandColor  = brand.brandColor  or data.brandColor  or "#3498db"
    data.logo        = brand.logo        or data.logo        or ""
    data.description = brand.description or data.description or ""
    if SocietyList[jobname] then
        SocietyList[jobname].brandColor  = data.brandColor
        SocietyList[jobname].logo        = data.logo
        SocietyList[jobname].description = data.description
    end
    pcall(function() exports["null-core"]:SaveCacheData("entreprises") end)
    if entrepriseType == "Restaurant" then
        TriggerClientEvent("null:restaurant:recevieData", -1, SaveData.json["entreprises"]["Restaurant"])
    end
end)

RegisterNetEvent("null:entreprise:updatePoints")
AddEventHandler("null:entreprise:updatePoints", function(entrepriseType, jobname, points)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not Config.GroupeHighPerm or not Config.GroupeHighPerm[xPlayer.getGroup()] then return end
    if type(entrepriseType) ~= "string" or type(jobname) ~= "string" or type(points) ~= "table" then return end

    local bucket = SaveData and SaveData.json and SaveData.json["entreprises"] and SaveData.json["entreprises"][entrepriseType]
    local data = bucket and bucket[jobname]
    if not data then return end

    local allowed = {
        ["Farm"] = { PosRecolte = true, PosTraitement = true, PosVente = true, PosBoss = true, PosVestiaire = true },
        ["Mécano"] = { PosCustom = true, PosCustom2 = true, PosCustom3 = true, PosBoss = true, PosVestiaire = true },
        ["Bar"] = { PosBar = true, PosBoss = true, PosVestiaire = true },
        ["Restaurant"] = { PosRecolte = true, PosTraitement = true, PosBoss = true, PosVestiaire = true },
        ["Ambulance"] = { PosBoss = true, PosVestiaire = true },
        ["Police"] = { PosArmory = true, PosBoss = true, PosVestiaire = true },
    }
    if not allowed[entrepriseType] then return end

    local changed = false
    for _, point in pairs(points) do
        if type(point) == "table" then
            local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
            if x and y and z and math.abs(x) <= 100000 and math.abs(y) <= 100000 and math.abs(z) <= 100000 then
                local key = tostring(point.key or "")
                local cellId = key:match("^cellule:(.+)$")
                if allowed[entrepriseType][key] then
                    data[key] = { x = x, y = y, z = z }
                    changed = true
                elseif entrepriseType == "Police" and cellId and data.cellule and data.cellule[cellId] then
                    data.cellule[cellId] = { x = x, y = y, z = z }
                    changed = true
                end
            end
        end
    end
    if not changed then return end

    Cache.SaveOne('entreprises')
    if entrepriseType == "Farm" then
        TriggerClientEvent('Null:SendEntrepriseFarmList', -1, SaveData.json["entreprises"]["Farm"])
    elseif entrepriseType == "Mécano" then
        TriggerClientEvent('Null:receiveMecano', -1, SaveData.json["entreprises"]["Mécano"])
    elseif entrepriseType == "Bar" then
        TriggerClientEvent('Null:receiveBarBuilder', -1, SaveData.json["entreprises"]["Bar"])
    elseif entrepriseType == "Police" then
        TriggerClientEvent('Null:receivePolice', -1, SaveData.json["entreprises"]["Police"])
    elseif entrepriseType == "Ambulance" then
        TriggerClientEvent('null:ambulance:recevie', -1, SaveData.json["entreprises"]["Ambulance"])
    elseif entrepriseType == "Restaurant" then
        TriggerClientEvent('null:restaurant:recevieData', -1, SaveData.json["entreprises"]["Restaurant"])
    end
end)

ESX.RegisterServerCallback("Core:GetSociety", function(source, cb)
    cb(SocietyList, GetSalary(), SaveData.json["taxes"])
end)

ESX.RegisterServerCallback("Core:GetBarList", function(source, cb)
    cb(BarSocietyList)
end)

ESX.RegisterServerCallback('Core:getEmployees2', function(source, cb, societyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job2.grade_name ~= 'boss' then return cb({}) end
    MySQL.Async.fetchAll('SELECT firstname, lastname, identifier, job2, job2_grade FROM users WHERE job2 = @job2 ORDER BY job2_grade DESC', {
        ['@job2'] = societyName
    }, function(results)
        local employees = {}
        if results then
            for _, r in pairs(results) do
                if ESX.Jobs[r.job2] and ESX.Jobs[r.job2].grades[tostring(r.job2_grade)] then
                    table.insert(employees, {
                        name = (r.firstname or 'Inconnu') .. ' ' .. (r.lastname or 'Inconnu'),
                        identifier = r.identifier,
                        job2 = {
                            name        = r.job2,
                            label       = ESX.Jobs[r.job2].label,
                            grade       = r.job2_grade,
                            grade_name  = ESX.Jobs[r.job2].grades[tostring(r.job2_grade)].name,
                            grade_label = ESX.Jobs[r.job2].grades[tostring(r.job2_grade)].label,
                        },
                    })
                end
            end
        end
        cb(employees)
    end)
end)



RegisterNetEvent("Core:ActionEmployesSociety")
AddEventHandler("Core:ActionEmployesSociety", function(position, ActionType, societyInfo, emloyesTaked, job2)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    local playerJob = job2 and xPlayer.job2.name or xPlayer.job.name
    if playerJob ~= societyInfo.name then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (24)")
        return
    end
    if #(GetEntityCoords(GetPlayerPed(_source)) - position) >= 8 then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (27)")
        return
    end
    local xTarget = ESX.GetPlayerFromIdentifier(emloyesTaked.identifier)
    if ActionType == "virer" then
        if xTarget then
            xTarget.setJob("unemployed", 0)
            xTarget.showNotification("~g~Action employé~s~\nVous avez été viré de votre emploi.")
            SocietyList[societyInfo.name].PlyList[xTarget.getIdunique()] = nil
        else
            MySQL.Async.execute("UPDATE users SET job='unemployed', job_grade='0' WHERE identifier=@identifier", { ["@identifier"] = emloyesTaked.identifier })
            SocietyList[societyInfo.name].PlyList[emloyesTaked.idunique] = nil
        end
        xPlayer.showNotification("~g~Action employé~s~\nVous avez viré " .. emloyesTaked.firstname .. ".")
    elseif ActionType == "promouvoir" then
        if xTarget then
            if xTarget.setJob(emloyesTaked.name, emloyesTaked.job_grade + 1) then
                xTarget.showNotification("~g~Action employé~s~\nVous avez été promu.")
                xPlayer.showNotification("~g~Action employé~s~\nVous avez promu " .. emloyesTaked.firstname .. ".")
                if SocietyList[societyInfo.name].PlyList[xTarget.getIdunique()] then
                    SocietyList[societyInfo.name].PlyList[xTarget.getIdunique()].job_grade = emloyesTaked.job_grade + 1
                end
            else
                xPlayer.showNotification("~g~Action employé~s~\nGrade maximum pour " .. emloyesTaked.firstname .. ".")
            end
        else
            if ESX.Jobs[societyInfo.name] and ESX.Jobs[societyInfo.name].grades[tostring(emloyesTaked.job_grade + 1)] then
                MySQL.Async.execute("UPDATE users SET job_grade=@job_grade WHERE identifier=@identifier AND job=@job", {
                    ["@identifier"] = emloyesTaked.identifier,
                    ["@job"]        = societyInfo.name,
                    ["@job_grade"]  = tostring(emloyesTaked.job_grade + 1),
                })
                xPlayer.showNotification("~g~Action employé~s~\nVous avez promu " .. emloyesTaked.firstname .. ".")
                if SocietyList[societyInfo.name].PlyList[emloyesTaked.idunique] then
                    SocietyList[societyInfo.name].PlyList[emloyesTaked.idunique].job_grade = emloyesTaked.job_grade + 1
                end
            else
                xPlayer.showNotification("~g~Action employé~s~\nGrade maximum pour " .. emloyesTaked.firstname .. ".")
            end
        end
    else
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (26)")
    end
end)

ESX.RegisterServerCallback('Core:setJob2', function(source, cb, identifier, job2, grade2, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job2.grade_name ~= 'boss' then
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche society (28)")
        return cb()
    end
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        xTarget.setJob2(job2, grade2)
        local msgs = { hire = _U('you_have_been_hired', job2), promote = ESX.Config("serverColor") .. 'Vous avez été promu par le boss !', fire = '~r~Vous avez été viré par le boss !' }
        if msgs[type] then TriggerClientEvent('esx:showNotification', xTarget.source, msgs[type]) end
    else
        MySQL.Async.execute('UPDATE users SET job2 = @job2, job2_grade = @job2_grade WHERE identifier = @identifier', {
            ['@job2'] = job2, ['@job2_grade'] = grade2, ['@identifier'] = identifier,
        })
    end
    cb()
end)

RegisterNetEvent('Core:GetSocietyGrade')
AddEventHandler('Core:GetSocietyGrade', function(position, societyInfo, job2)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    local playerJob = job2 and xPlayer.job2.name or xPlayer.job.name
    if playerJob ~= societyInfo.name then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (29)")
        return
    end
    if #(GetEntityCoords(GetPlayerPed(_source)) - position) >= 8 then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (31)")
        return
    end
    if ESX.Jobs[societyInfo.name] then
        TriggerClientEvent("Core:GetGradeList", _source, ESX.Jobs[societyInfo.name].grades)
    end
end)

RegisterNetEvent('Core:SocietyActionsGrade')
AddEventHandler('Core:SocietyActionsGrade', function(position, societyInfo, ActionType, args, job2)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    local playerJob = job2 and xPlayer.job2.name or xPlayer.job.name
    if playerJob ~= societyInfo.name then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (32)")
        return
    end
    if #(GetEntityCoords(GetPlayerPed(_source)) - position) >= 8 then
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (35)")
        return
    end
    local handlers = {
        delgrade       = function() ESX.DeletGrade(societyInfo.name, args) end,
        createGrade    = function() ESX.AddGrade(societyInfo.name, args) end,
        editSalaire    = function() ESX.EditGrade("salary", societyInfo.name, args) end,
        editMensuelPay = function() ESX.EditGrade("mensuelpay", societyInfo.name, args) end,
    }
    if handlers[ActionType] then
        handlers[ActionType]()
        TriggerClientEvent("Core:UpdateGradeList", _source, ESX.Jobs[societyInfo.name] and ESX.Jobs[societyInfo.name].grades or {})
    else
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche society (34)")
    end
end)

ESX.RegisterServerCallback('Null:bossmenu:getMoneyFromEntreprise', function(source, cb, jobname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= jobname then return cb(0) end
    local entry = SocietyCache[jobname]
    cb(entry and entry.data and entry.data["accounts"] and entry.data["accounts"].cash or 0)
end)
