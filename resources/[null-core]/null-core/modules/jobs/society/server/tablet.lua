local lasterBlanchiment = {}

local drinksUnicorn = {
    {name = "Cola", value = "cocafrais", price = 150},
    {name = "Rhum", value = "rhum", price = 175},
    {name = "Tequila", value = "tequila", price = 135},
    {name = "Ice tea", value = "icetea", price = 144},
    {name = "Maximator", value = "beer", price = 165},
    {name = "Martini", value = "martini", price = 130},
    {name = "Mojito", value = "mojito", price = 175},
    {name = "Orangina", value = "orangina", price = 120},
    {name = "Redbull", value = "redbull", price = 130},
    {name = "Vodka", value = "vodka", price = 165},
    {name = "Fanta", value = "fanta", price = 110},
    {name = "Champagne", value = "champagne", price = 110},
}

local healsZonah = {
    {name = "Bandage", value = "bandage", price = 200},
    {name = "Kit de soins", value = "medikit", price = 500},
}

local function isBarJob(jobName)
    if null and null.data and null.data.jobs and null.data.jobs.bars then
        for _, v in pairs(null.data.jobs.bars.list) do
            if v.name == jobName then return true end
        end
    end
    return false
end

local function isMecanoJob(jobName)
    if null and null.data and null.data.jobs and null.data.jobs.mecanos then
        for _, v in pairs(null.data.jobs.mecanos.list) do
            if v.name == jobName then return true end
        end
    end
    return false
end

local function isAmbulanceJob(jobName)
    if null and null.data and null.data.jobs and null.data.jobs.ambulances then
        for _, v in pairs(null.data.jobs.ambulances.list) do
            if v.name == jobName then return true end
        end
    end
    return false
end

local function isRealEstateJob(jobName)
    return jobName == "realestateagent"
end

local function getGradesList(jobName)
    local grades = {}
    if ESX.Jobs[jobName] and ESX.Jobs[jobName].grades then
        for k, v in pairs(ESX.Jobs[jobName].grades) do
            table.insert(grades, {
                grade = tonumber(k),
                name = v.name,
                label = v.label,
                salary = v.salary or 0,
                mensuelpay = v.mensuelpay or 0,
            })
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
    end
    return grades
end

local function getEmployeesList(jobName)
    local employees = {}
    if SocietyList[jobName] and SocietyList[jobName].PlyList then
        for idunique, ply in pairs(SocietyList[jobName].PlyList) do
            local gradeLabel = "Inconnu"
            if ESX.Jobs[jobName] and ESX.Jobs[jobName].grades and ESX.Jobs[jobName].grades[tostring(ply.job_grade)] then
                gradeLabel = ESX.Jobs[jobName].grades[tostring(ply.job_grade)].label
            end
            local isOnline = ESX.GetPlayerFromIdentifier(ply.identifier) ~= nil
            table.insert(employees, {
                idunique = tostring(ply.idunique),
                identifier = ply.identifier,
                firstname = ply.firstname or "Inconnu",
                lastname = ply.lastname or "Inconnu",
                name = (ply.firstname or "") .. " " .. (ply.lastname or ""),
                job = ply.job or jobName,
                job_grade = ply.job_grade or 0,
                job2 = ply.job2 or "",
                job2_grade = ply.job2_grade or 0,
                gradeLabel = gradeLabel,
                online = isOnline,
            })
        end
    end
    return employees
end

local function getHistoryList(jobName, cb)
    MySQL.Async.fetchAll('SELECT * FROM `vhistoriquesociety` WHERE `society` = @society ORDER BY id DESC LIMIT 100', {
        ['@society'] = jobName
    }, function(result)
        local history = {}
        for _, v in pairs(result or {}) do
            table.insert(history, {
                id = v.id,
                label = v.label or "",
                info = v.info or "",
                count = v.count or 0,
                time = v.time and os.date('%Y-%m-%d %H:%M:%S', v.time / 1000) or "",
                society = v.society or "",
            })
        end
        cb(history)
    end)
end

local function getEnterprisesList()
    local enterprises = {}
    for name, data in pairs(SocietyList) do
        local employeeCount = 0
        if data.PlyList then
            for _ in pairs(data.PlyList) do employeeCount = employeeCount + 1 end
        end
        local politique = nil
        if SocietyCache[name] and SocietyCache[name].data and SocietyCache[name].data.politique then
            politique = SocietyCache[name].data.politique
        end
        table.insert(enterprises, {
            name = name,
            label = data.label or name,
            state = data.state or false,
            employeeCount = employeeCount,
            politique = politique,
        })
    end
    return enterprises
end

local function getPolitiqueConfig()
    local config = {}
    if Config and Config.Society and Config.Society.Politique then
        for k, v in pairs(Config.Society.Politique) do
            config[k] = {
                type = v.type,
                default = v.default,
                description = v.description or "",
            }
        end
    end
    return config
end

ESX.RegisterServerCallback("societyTablet:getData", function(source, cb, societyName, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local jobName = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local gradeName = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name

    if jobName ~= societyName then return cb(nil) end

    local isBoss = gradeName == "boss"
    local isGov = societyName == "gouvernement"

    local accounts = { cash = 0, dirtycash = 0 }
    if SocietyCache[societyName] and SocietyCache[societyName].data and SocietyCache[societyName].data["accounts"] then
        accounts = SocietyCache[societyName].data["accounts"]
    end

    local politique = {}
    if SocietyCache[societyName] and SocietyCache[societyName].data and SocietyCache[societyName].data.politique then
        politique = SocietyCache[societyName].data.politique
    end

    local gradeLabel = "Inconnu"
    local gradeNum = job2 and xPlayer.getJob2().grade or xPlayer.getJob().grade
    if ESX.Jobs[societyName] and ESX.Jobs[societyName].grades and ESX.Jobs[societyName].grades[tostring(gradeNum)] then
        gradeLabel = ESX.Jobs[societyName].grades[tostring(gradeNum)].label
    end

    local canLaunder = isBoss and (isMecanoJob(societyName) or isBarJob(societyName))
    local canBuyDrinks = isBoss and isBarJob(societyName)
    local canBuyHeals = isBoss and isAmbulanceJob(societyName)

    local employeeCount = 0
    if SocietyList[societyName] and SocietyList[societyName].PlyList then
        for _ in pairs(SocietyList[societyName].PlyList) do employeeCount = employeeCount + 1 end
    end

    local state = false
    if SocietyList[societyName] then
        state = SocietyList[societyName].state or false
    end

    local societyLabel = societyName
    if SocietyList[societyName] and SocietyList[societyName].label then
        societyLabel = SocietyList[societyName].label
    end

    local societyType = ""
    if SocietyList[societyName] and SocietyList[societyName].type then
        societyType = SocietyList[societyName].type
    end

    local brandLogo = nil
    local brandTagline = nil
    local brandBg = nil
    if SocietyList[societyName] then
        if SocietyList[societyName].logo and SocietyList[societyName].logo ~= "" then
            brandLogo = SocietyList[societyName].logo
        end
        if SocietyList[societyName].description and SocietyList[societyName].description ~= "" then
            brandTagline = SocietyList[societyName].description
        end
        if SocietyList[societyName].brandColor and SocietyList[societyName].brandColor ~= "" then
            brandBg = SocietyList[societyName].brandColor
        end
    end

    local blanchimentConfig = { pourcentage = 75, delai = 10 }
    if Config and Config.Society and Config.Society.Blanchiment then
        blanchimentConfig = Config.Society.Blanchiment
    end

    local isMecano = isMecanoJob(societyName)
    local isRealEstate = isRealEstateJob(societyName)

    local maxGrades = 8

    local function sendResponse(history)
        cb({
            societyName = societyName,
            societyLabel = societyLabel,
            societyType = societyType,
            isBoss = isBoss,
            isGovernment = isGov,
            isJob2 = job2 or false,
            accounts = accounts,
            employees = isBoss and getEmployeesList(societyName) or {},
            grades = getGradesList(societyName),
            history = history,
            salaryData = SaveData.json["salary"],
            taxesData = SaveData.json["taxes"],
            politique = politique,
            politiqueConfig = getPolitiqueConfig(),
            enterprises = (isGov and isBoss) and getEnterprisesList() or {},
            canLaunder = canLaunder,
            blanchimentConfig = blanchimentConfig,
            canBuyDrinks = canBuyDrinks,
            drinks = canBuyDrinks and drinksUnicorn or {},
            canBuyHeals = canBuyHeals,
            heals = canBuyHeals and healsZonah or {},
            playerGrade = gradeNum,
            playerGradeLabel = gradeLabel,
            employeeCount = employeeCount,
            state = state,
            isMecano = isMecano,
            isRealEstate = isRealEstate,
            customHistory = {},
            properties = {},
            maxGrades = maxGrades,
            brandLogo = brandLogo,
            brandTagline = brandTagline,
            brandBg = brandBg,
        })
    end

    if isBoss then
        getHistoryList(societyName, sendResponse)
    else
        sendResponse({})
    end
end)

ESX.RegisterServerCallback("societyTablet:getEmployees", function(source, cb, societyName)
    cb(getEmployeesList(societyName))
end)

ESX.RegisterServerCallback("societyTablet:getGrades", function(source, cb, societyName)
    cb(getGradesList(societyName))
end)

ESX.RegisterServerCallback("societyTablet:getAccounts", function(source, cb, societyName)
    local accounts = { cash = 0, dirtycash = 0 }
    if SocietyCache[societyName] and SocietyCache[societyName].data and SocietyCache[societyName].data["accounts"] then
        accounts = SocietyCache[societyName].data["accounts"]
    end
    cb(accounts)
end)

ESX.RegisterServerCallback("societyTablet:fireEmployee", function(source, cb, societyName, identifier, idunique, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        xTarget.setJob("unemployed", 0)
        xTarget.showNotification("Vous avez été viré de votre emploi.")
    else
        MySQL.Async.execute("UPDATE users SET job='unemployed', job_grade='0' WHERE identifier=@identifier", {
            ["@identifier"] = identifier,
        })
    end

    if SocietyList[societyName] and SocietyList[societyName].PlyList then
        SocietyList[societyName].PlyList[idunique] = nil
    end

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a viré " .. identifier, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:promoteEmployee", function(source, cb, societyName, identifier, idunique, currentGrade, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    local newGrade = currentGrade + 1
    if not ESX.Jobs[societyName] or not ESX.Jobs[societyName].grades[tostring(newGrade)] then
        return cb({ success = false, message = "Grade maximum atteint" })
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local success = xTarget.setJob(societyName, newGrade)
        if not success then
            return cb({ success = false, message = "Impossible de promouvoir" })
        end
        xTarget.showNotification("Vous avez été promu.")
    else
        MySQL.Async.execute("UPDATE users SET job_grade=@job_grade WHERE identifier=@identifier AND job=@job", {
            ["@identifier"] = identifier,
            ["@job_grade"] = tostring(newGrade),
            ["@job"] = societyName,
        })
    end

    if SocietyList[societyName] and SocietyList[societyName].PlyList and SocietyList[societyName].PlyList[idunique] then
        SocietyList[societyName].PlyList[idunique].job_grade = newGrade
    end

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a promu " .. identifier, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:demoteEmployee", function(source, cb, societyName, identifier, idunique, currentGrade, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    local newGrade = currentGrade - 1
    if newGrade < 0 then
        return cb({ success = false, message = "Grade minimum atteint" })
    end

    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        local success = xTarget.setJob(societyName, newGrade)
        if not success then
            return cb({ success = false, message = "Impossible de rétrograder" })
        end
        xTarget.showNotification("Vous avez été rétrogradé.")
    else
        MySQL.Async.execute("UPDATE users SET job_grade=@job_grade WHERE identifier=@identifier AND job=@job", {
            ["@identifier"] = identifier,
            ["@job_grade"] = tostring(newGrade),
            ["@job"] = societyName,
        })
    end

    if SocietyList[societyName] and SocietyList[societyName].PlyList and SocietyList[societyName].PlyList[idunique] then
        SocietyList[societyName].PlyList[idunique].job_grade = newGrade
    end

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a rétrogradé " .. identifier, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:editGradeSalary", function(source, cb, societyName, grade, amount, salaryType, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if salaryType == "Mensuel" then
        if amount > SaveData.json["salary"]["Mensuel"].max or amount < SaveData.json["salary"]["Mensuel"].min then
            return cb({ success = false, message = "Salaire hors limites (Min: " .. SaveData.json["salary"]["Mensuel"].min .. " / Max: " .. SaveData.json["salary"]["Mensuel"].max .. ")" })
        end
        ESX.EditGrade("mensuelpay", societyName, { grade = grade, amount = amount })
    elseif salaryType == "Pour 30 Min" then
        if amount > SaveData.json["salary"]["Pour 30 Min"].max or amount < SaveData.json["salary"]["Pour 30 Min"].min then
            return cb({ success = false, message = "Salaire hors limites (Min: " .. SaveData.json["salary"]["Pour 30 Min"].min .. " / Max: " .. SaveData.json["salary"]["Pour 30 Min"].max .. ")" })
        end
        ESX.EditGrade("salary", societyName, { grade = grade, amount = amount })
    else
        return cb({ success = false, message = "Type invalide" })
    end

    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:deposit", function(source, cb, societyName, moneyType, amount, position, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    if myJob ~= societyName then
        return cb({ success = false, message = "Accès refusé" })
    end

    if moneyType ~= "cash" and moneyType ~= "dirtycash" then
        return cb({ success = false, message = "Type invalide" })
    end

    if amount <= 0 then
        return cb({ success = false, message = "Montant invalide" })
    end

    if xPlayer.getAccount(moneyType).money < amount then
        return cb({ success = false, message = "Vous n'avez pas assez d'argent" })
    end

    xPlayer.removeAccountMoney(moneyType, amount)
    if moneyType == "cash" then
        SocietyCache[societyName].data["accounts"].cash = SocietyCache[societyName].data["accounts"].cash + amount
        addHistorySociety(societyName, "Gains : Dépot d'Argent", "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.getIdunique() .. ")", amount)
    elseif moneyType == "dirtycash" then
        SocietyCache[societyName].data["accounts"].dirtycash = SocietyCache[societyName].data["accounts"].dirtycash + amount
        addHistorySociety(societyName, "Gains : Dépot d'Argent Sale", "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.getIdunique() .. ")", amount)
    end
    SaveSociety(societyName)
    null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a déposé " .. amount .. "$ (" .. moneyType .. ")", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:withdraw", function(source, cb, societyName, moneyType, amount, position, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if moneyType ~= "cash" and moneyType ~= "dirtycash" then
        return cb({ success = false, message = "Type invalide" })
    end

    if amount <= 0 then
        return cb({ success = false, message = "Montant invalide" })
    end

    if moneyType == "cash" then
        if SocietyCache[societyName].data["accounts"].cash < amount then
            return cb({ success = false, message = "Le coffre n'a pas assez d'argent" })
        end
        SocietyCache[societyName].data["accounts"].cash = SocietyCache[societyName].data["accounts"].cash - amount
        addHistorySociety(societyName, "Dépense : Retrait d'Argent", "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.getIdunique() .. ")", tonumber("-" .. tostring(amount)))
        local newamount, toreduc = RemoveTaxesOfAmount("retrait", amount, true, SocietyList[societyName] and SocietyList[societyName].label or societyName, societyName)
        xPlayer.addAccountMoney(moneyType, newamount)
    elseif moneyType == "dirtycash" then
        if SocietyCache[societyName].data["accounts"].dirtycash < amount then
            return cb({ success = false, message = "Le coffre n'a pas assez d'argent sale" })
        end
        SocietyCache[societyName].data["accounts"].dirtycash = SocietyCache[societyName].data["accounts"].dirtycash - amount
        addHistorySociety(societyName, "Dépense : Retrait d'Argent Sale", "Auteur: " .. xPlayer.getName() .. " (" .. xPlayer.getIdunique() .. ")", tonumber("-" .. tostring(amount)))
        xPlayer.addAccountMoney(moneyType, amount)
    end
    SaveSociety(societyName)
    null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a retiré " .. amount .. "$ (" .. moneyType .. ")", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:launder", function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    local jobName = xPlayer.getJob().name
    if not isMecanoJob(jobName) and not isBarJob(jobName) then
        return cb({ success = false, message = "Non autorisé" })
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return cb({ success = false, message = "Montant invalide" })
    end

    if lasterBlanchiment[jobName] ~= nil then
        if (os.time() - lasterBlanchiment[jobName]) < (Config.Society.Blanchiment.delai * 60) then
            local remaining = math.ceil((Config.Society.Blanchiment.delai * 60 - (os.time() - lasterBlanchiment[jobName])) / 60)
            return cb({ success = false, message = "Attendez encore " .. remaining .. " minute(s)" })
        end
    end
    lasterBlanchiment[jobName] = os.time()

    if xPlayer.getAccount('dirtycash').money < amount then
        return cb({ success = false, message = "Vous n'avez pas assez d'argent sale" })
    end

    xPlayer.removeAccountMoney('dirtycash', amount)
    local newmoney = math.floor(amount * (tonumber("0." .. tostring(Config.Society.Blanchiment.pourcentage))))
    xPlayer.addAccountMoney('cash', newmoney)

    cb({ success = true, message = "Blanchi " .. amount .. "$ → " .. newmoney .. "$ récupérés" })
end)

ESX.RegisterServerCallback("societyTablet:buyDrink", function(source, cb, itemValue, itemName, itemPrice, count, societyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if xPlayer.getJob().name ~= societyName or xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if xPlayer.getAccount("cash").money < itemPrice then
        return cb({ success = false, message = "Pas assez d'argent" })
    end

    local society = "society_" .. societyName
    TriggerEvent('Null:esx_addoninventory:getSharedInventory', society, function(inventory)
        inventory.addItem(itemValue, count)
        xPlayer.removeAccountMoney("cash", itemPrice)
        null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a acheté " .. itemName .. " " .. count .. "X", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    end)

    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:buyHeal", function(source, cb, itemValue, itemName, itemPrice, count, societyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if xPlayer.getJob().name ~= societyName or xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if xPlayer.getAccount("cash").money < itemPrice then
        return cb({ success = false, message = "Pas assez d'argent" })
    end

    TriggerEvent('Null:esx_addoninventory:getSharedInventory', 'society_ambulance', function(inventory)
        inventory.addItem(itemValue, count)
        xPlayer.removeAccountMoney("cash", itemPrice)
        null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a acheté " .. itemName .. " " .. count .. "X", "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    end)

    cb({ success = true })
end)

-- ==========================================================================
-- GRADE CRUD
-- ==========================================================================

ESX.RegisterServerCallback("societyTablet:createGrade", function(source, cb, societyName, gradeData, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if not ESX.Jobs[societyName] then
        return cb({ success = false, message = "Job introuvable" })
    end

    local gradeCount = 0
    for _ in pairs(ESX.Jobs[societyName].grades) do gradeCount = gradeCount + 1 end
    if gradeCount >= 8 then
        return cb({ success = false, message = "Maximum de grades atteint (8)" })
    end

    if not gradeData.name or gradeData.name == "" or not gradeData.label or gradeData.label == "" then
        return cb({ success = false, message = "Nom et label requis" })
    end

    local newGrades = ESX.AddGrade(societyName, {
        job_name = societyName,
        name = gradeData.name,
        label = gradeData.label,
        salary = tonumber(gradeData.salary) or 0,
        mensuelpay = tonumber(gradeData.mensuelpay) or 0,
        skin_mal = "{}",
        skin_female = "{}",
    })

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a créé le grade '" .. gradeData.label .. "' pour " .. societyName, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    TriggerEvent("Core:InitAllJob", ESX.Jobs)
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:deleteGrade", function(source, cb, societyName, grade, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if not ESX.Jobs[societyName] or not ESX.Jobs[societyName].grades[tostring(grade)] then
        return cb({ success = false, message = "Grade introuvable" })
    end

    local gradeInfo = ESX.Jobs[societyName].grades[tostring(grade)]
    if gradeInfo.name == "boss" then
        return cb({ success = false, message = "Impossible de supprimer le grade boss" })
    end

    local gradeCount = 0
    for _ in pairs(ESX.Jobs[societyName].grades) do gradeCount = gradeCount + 1 end
    if gradeCount <= 1 then
        return cb({ success = false, message = "Il doit rester au moins un grade" })
    end

    ESX.DeletGrade(societyName, grade)

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a supprimé le grade " .. grade .. " de " .. societyName, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    TriggerEvent("Core:InitAllJob", ESX.Jobs)
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:editGradeMeta", function(source, cb, societyName, grade, newName, newLabel, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if not ESX.Jobs[societyName] or not ESX.Jobs[societyName].grades[tostring(grade)] then
        return cb({ success = false, message = "Grade introuvable" })
    end

    if not newName or newName == "" or not newLabel or newLabel == "" then
        return cb({ success = false, message = "Nom et label requis" })
    end

    local oldName = ESX.Jobs[societyName].grades[tostring(grade)].name
    ESX.Jobs[societyName].grades[tostring(grade)].name = newName
    ESX.Jobs[societyName].grades[tostring(grade)].label = newLabel

    MySQL.Async.execute("UPDATE job_grades SET name=@newname, label=@newlabel WHERE job_name=@job_name AND name=@oldname", {
        ["@newname"] = newName,
        ["@newlabel"] = newLabel,
        ["@job_name"] = societyName,
        ["@oldname"] = oldName,
    })

    TriggerEvent("Core:InitAllJob", ESX.Jobs)
    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a modifié le grade " .. grade .. " de " .. societyName .. " (" .. oldName .. " → " .. newName .. " / " .. newLabel .. ")", "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

-- ==========================================================================
-- RECRUIT EMPLOYEE
-- ==========================================================================

ESX.RegisterServerCallback("societyTablet:recruitEmployee", function(source, cb, societyName, targetId, job2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    local myJob = job2 and xPlayer.getJob2().name or xPlayer.getJob().name
    local myGrade = job2 and xPlayer.getJob2().grade_name or xPlayer.getJob().grade_name
    if myJob ~= societyName or myGrade ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    if not targetId or targetId < 1 then
        return cb({ success = false, message = "Aucun joueur à proximité" })
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        return cb({ success = false, message = "Joueur introuvable" })
    end

    if xTarget.getJob().name == societyName then
        return cb({ success = false, message = "Ce joueur travaille déjà ici" })
    end

    xTarget.setJob(societyName, 0)
    xTarget.showNotification("Vous avez été recruté chez " .. (SocietyList[societyName] and SocietyList[societyName].label or societyName))

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. " U" .. xPlayer.getIdunique() .. ") a recruté " .. xTarget.getName() .. " (T" .. targetId .. ")", "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

-- ==========================================================================
-- CUSTOM HISTORY (MECANO)
-- ==========================================================================

ESX.RegisterServerCallback("societyTablet:getCustomHistory", function(source, cb, societyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    if xPlayer.getJob().name ~= societyName then return cb({}) end

    MySQL.Async.fetchAll('SELECT * FROM `vhistoriquesociety` WHERE `society` = @society AND `type` = @type ORDER BY id DESC LIMIT 100', {
        ['@society'] = societyName,
        ['@type'] = "mecano",
    }, function(result)
        local history = {}
        for _, v in pairs(result or {}) do
            table.insert(history, {
                id = v.id,
                label = v.label or "",
                info = v.info or "",
                count = v.count or 0,
                time = v.time and os.date('%Y-%m-%d %H:%M:%S', v.time / 1000) or "",
                society = v.society or "",
            })
        end
        cb(history)
    end)
end)

-- ==========================================================================
-- PROPERTIES (REAL ESTATE)
-- ==========================================================================

ESX.RegisterServerCallback("societyTablet:getProperties", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    if not isRealEstateJob(xPlayer.getJob().name) then return cb({}) end
    if xPlayer.getJob().grade_name ~= "boss" then return cb({}) end

    MySQL.Async.fetchAll('SELECT p.*, u.firstname, u.lastname FROM `vproperties` p LEFT JOIN users u ON u.identifier = p.owner AND p.owner != \'\' AND p.owner != \'none\' ORDER BY p.id ASC', {}, function(result)
        local properties = {}
        for _, v in pairs(result or {}) do
            local ownerName = nil
            if v.owner and v.owner ~= "" and v.owner ~= "none" then
                ownerName = v.firstname and ((v.firstname or "") .. " " .. (v.lastname or "")) or v.owner
            end
            table.insert(properties, {
                id = v.id,
                name = v.name or "",
                label = v.label or v.name or "",
                price = v.price or 0,
                isBuy = v.isBuy == 1 or v.isBuy == true,
                owner = ownerName,
                immeuble = v.immeuble or "0",
            })
        end
        cb(properties)
    end)
end)

ESX.RegisterServerCallback("societyTablet:evictProperty", function(source, cb, propertyId, propertyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if not isRealEstateJob(xPlayer.getJob().name) or xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    MySQL.Async.execute("UPDATE vproperties SET owner='none', isBuy=0 WHERE id=@id", {
        ["@id"] = propertyId,
    })

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. ") a viré le propriétaire de " .. propertyName, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:assignProperty", function(source, cb, propertyId, propertyName, targetId, toSelf)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if not isRealEstateJob(xPlayer.getJob().name) or xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    local targetIdentifier = nil
    if toSelf then
        targetIdentifier = xPlayer.identifier
    else
        if not targetId or targetId < 1 then
            return cb({ success = false, message = "Aucun joueur à proximité" })
        end
        local xTarget = ESX.GetPlayerFromId(targetId)
        if not xTarget then
            return cb({ success = false, message = "Joueur introuvable" })
        end
        targetIdentifier = xTarget.identifier
    end

    MySQL.Async.execute("UPDATE vproperties SET owner=@owner, isBuy=1 WHERE id=@id", {
        ["@owner"] = targetIdentifier,
        ["@id"] = propertyId,
    })

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. ") a attribué la propriété " .. propertyName .. " à " .. targetIdentifier, "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)

ESX.RegisterServerCallback("societyTablet:deleteProperty", function(source, cb, propertyId, propertyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, message = "Erreur" }) end

    if not isRealEstateJob(xPlayer.getJob().name) or xPlayer.getJob().grade_name ~= "boss" then
        return cb({ success = false, message = "Accès refusé" })
    end

    MySQL.Async.execute("DELETE FROM vproperties WHERE id=@id", {
        ["@id"] = propertyId,
    })

    null.logs.send("Logs Society", "Le joueur : " .. xPlayer.getName() .. " (T" .. source .. ") a supprimé la propriété " .. propertyName .. " (ID: " .. propertyId .. ")", "societyadmin", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    cb({ success = true })
end)
