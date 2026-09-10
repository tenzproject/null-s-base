local isOpen = false
local currentSociety = nil
local currentPosition = nil
local currentJob2 = false

function OpenSocietyTablet(society, position, job2)
    if isOpen then return end
    isOpen = true
    currentSociety = society
    currentPosition = position
    currentJob2 = job2 or false

    SetNuiFocus(true, true)

    ESX.TriggerServerCallback("societyTablet:getData", function(result)
        if result then
            SendNUIMessage({
                action = "societyTablet:open",
            })
            SendNUIMessage({
                action = "societyTablet:setData",
                data = result,
            })
        else
            ESX.ShowNotification("Impossible de charger les données de l'entreprise.", "error")
            SetNuiFocus(false, false)
            isOpen = false
        end
    end, society.name, job2)
end

OpenSocietyMenu = OpenSocietyTablet

RegisterNUICallback("societyTablet:close", function(data, cb)
    isOpen = false
    currentSociety = nil
    currentPosition = nil
    currentJob2 = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("societyTablet:fireEmployee", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:fireEmployee", function(result)
        cb(result)
        if result.success then
            RefreshEmployees()
        end
    end, currentSociety.name, data.identifier, data.idunique, currentJob2)
end)

RegisterNUICallback("societyTablet:promoteEmployee", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:promoteEmployee", function(result)
        cb(result)
        if result.success then
            RefreshEmployees()
        end
    end, currentSociety.name, data.identifier, data.idunique, data.job_grade, currentJob2)
end)

RegisterNUICallback("societyTablet:demoteEmployee", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:demoteEmployee", function(result)
        cb(result)
        if result.success then
            RefreshEmployees()
        end
    end, currentSociety.name, data.identifier, data.idunique, data.job_grade, currentJob2)
end)

RegisterNUICallback("societyTablet:editGradeSalary", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:editGradeSalary", function(result)
        cb(result)
        if result.success then
            RefreshGrades()
        end
    end, currentSociety.name, data.grade, data.amount, data.type, currentJob2)
end)

RegisterNUICallback("societyTablet:deposit", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:deposit", function(result)
        cb(result)
        if result.success then
            RefreshAccounts()
        end
    end, currentSociety.name, data.moneyType, data.amount, currentPosition, currentJob2)
end)

RegisterNUICallback("societyTablet:withdraw", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:withdraw", function(result)
        cb(result)
        if result.success then
            RefreshAccounts()
        end
    end, currentSociety.name, data.moneyType, data.amount, currentPosition, currentJob2)
end)

RegisterNUICallback("societyTablet:rename", function(data, cb)
    local newname = null.fct.input("Nouveau nom pour votre entreprise :", "null-core")
    if newname and newname ~= "" then
        TriggerServerEvent("vsociety:changelabelsociety", currentSociety.name, newname)
        cb({ success = true })
    else
        cb({ success = false, message = "Nom invalide" })
    end
end)

RegisterNUICallback("societyTablet:launder", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:launder", function(result)
        cb(result)
    end, data.amount)
end)

RegisterNUICallback("societyTablet:buyDrink", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:buyDrink", function(result)
        cb(result)
    end, data.value, data.name, data.price, data.count, ESX.PlayerData.job.name)
end)

RegisterNUICallback("societyTablet:buyHeal", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:buyHeal", function(result)
        cb(result)
    end, data.value, data.name, data.price, data.count, ESX.PlayerData.job.name)
end)

RegisterNUICallback("societyTablet:togglePolitique", function(data, cb)
    if not isOpen or not currentSociety then return cb({}) end
    TriggerServerEvent("Null:EditPolitique", data.key, data.value, currentSociety.name)
    cb({})
end)

RegisterNUICallback("societyTablet:govRenameSociety", function(data, cb)
    local newname = null.fct.input("Nouveau nom de l'entreprise ?")
    if newname and newname ~= "" then
        TriggerServerEvent("vsociety:changelabelsociety", data.name, newname)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback("societyTablet:govChangeSalary", function(data, cb)
    local newValue = null.fct.input("Nouvelle valeur :", false, 9000000, "number")
    if newValue then
        TriggerServerEvent("Null:gouv:updateSalary", data.salaryType, newValue, data.subType)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback("societyTablet:govChangeTax", function(data, cb)
    local newValue = null.fct.input("Nouveau montant :", false, 100, "number")
    if newValue then
        TriggerServerEvent("Null:gouv:updateTaxes", data.taxType, newValue)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback("societyTablet:govToggleElectricity", function(data, cb)
    TriggerServerEvent("null:weather:changeBlackout", not inBlackout)
    cb({ success = true })
end)

RegisterNUICallback("societyTablet:govTogglePolitique", function(data, cb)
    TriggerServerEvent("Null:EditPolitique", data.key, data.value, data.societyName)
    cb({})
end)

-- ==========================================================================
-- GRADE CRUD
-- ==========================================================================

RegisterNUICallback("societyTablet:createGrade", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:createGrade", function(result)
        cb(result)
        if result.success then
            RefreshGrades()
        end
    end, currentSociety.name, data, currentJob2)
end)

RegisterNUICallback("societyTablet:deleteGrade", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:deleteGrade", function(result)
        cb(result)
        if result.success then
            RefreshGrades()
        end
    end, currentSociety.name, data.grade, currentJob2)
end)

RegisterNUICallback("societyTablet:editGradeMeta", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:editGradeMeta", function(result)
        cb(result)
        if result.success then
            RefreshGrades()
        end
    end, currentSociety.name, data.grade, data.name, data.label, currentJob2)
end)

-- ==========================================================================
-- RECRUIT EMPLOYEE
-- ==========================================================================

RegisterNUICallback("societyTablet:recruitEmployee", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 3.0 then
        return cb({ success = false, message = "Aucun joueur à proximité" })
    end
    local targetId = GetPlayerServerId(closestPlayer)
    ESX.TriggerServerCallback("societyTablet:recruitEmployee", function(result)
        cb(result)
        if result.success then
            RefreshEmployees()
        end
    end, currentSociety.name, targetId, currentJob2)
end)

-- ==========================================================================
-- CUSTOM HISTORY (MECANO)
-- ==========================================================================

RegisterNUICallback("societyTablet:loadCustomHistory", function(data, cb)
    if not isOpen or not currentSociety then return cb({}) end
    ESX.TriggerServerCallback("societyTablet:getCustomHistory", function(result)
        SendNUIMessage({ action = "societyTablet:updateCustomHistory", data = result })
        cb({})
    end, currentSociety.name)
end)

-- ==========================================================================
-- PROPERTIES (REAL ESTATE)
-- ==========================================================================

RegisterNUICallback("societyTablet:loadProperties", function(data, cb)
    if not isOpen or not currentSociety then return cb({}) end
    ESX.TriggerServerCallback("societyTablet:getProperties", function(result)
        SendNUIMessage({ action = "societyTablet:updateProperties", data = result })
        cb({})
    end, currentSociety.name)
end)

RegisterNUICallback("societyTablet:deleteProperty", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:deleteProperty", function(result)
        cb(result)
        if result.success then
            ESX.TriggerServerCallback("societyTablet:getProperties", function(props)
                SendNUIMessage({ action = "societyTablet:updateProperties", data = props })
            end, currentSociety.name)
        end
    end, data.id, data.name)
end)

RegisterNUICallback("societyTablet:evictProperty", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    ESX.TriggerServerCallback("societyTablet:evictProperty", function(result)
        cb(result)
        if result.success then
            ESX.TriggerServerCallback("societyTablet:getProperties", function(props)
                SendNUIMessage({ action = "societyTablet:updateProperties", data = props })
            end, currentSociety.name)
        end
    end, data.id, data.name)
end)

RegisterNUICallback("societyTablet:assignProperty", function(data, cb)
    if not isOpen or not currentSociety then return cb({ success = false }) end
    local targetId = -1
    if not data.toSelf then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
            return cb({ success = false, message = "Aucun joueur à proximité" })
        end
        targetId = GetPlayerServerId(closestPlayer)
    end
    ESX.TriggerServerCallback("societyTablet:assignProperty", function(result)
        cb(result)
        if result.success then
            ESX.TriggerServerCallback("societyTablet:getProperties", function(props)
                SendNUIMessage({ action = "societyTablet:updateProperties", data = props })
            end, currentSociety.name)
        end
    end, data.id, data.name, targetId, data.toSelf)
end)

function RefreshEmployees()
    if not isOpen or not currentSociety then return end
    ESX.TriggerServerCallback("societyTablet:getEmployees", function(result)
        SendNUIMessage({ action = "societyTablet:updateEmployees", data = result })
    end, currentSociety.name)
end

function RefreshGrades()
    if not isOpen or not currentSociety then return end
    ESX.TriggerServerCallback("societyTablet:getGrades", function(result)
        SendNUIMessage({ action = "societyTablet:updateGrades", data = result })
    end, currentSociety.name)
end

function RefreshAccounts()
    if not isOpen or not currentSociety then return end
    ESX.TriggerServerCallback("societyTablet:getAccounts", function(result)
        SendNUIMessage({ action = "societyTablet:updateAccounts", data = result })
    end, currentSociety.name)
end

exports("OpenSocietyTablet", OpenSocietyTablet)
