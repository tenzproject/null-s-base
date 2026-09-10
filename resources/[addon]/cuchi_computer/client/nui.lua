UIOpen = false
local Location = nil
local inLaboId = nil
local isLaptop = false

function OpenUI(location, laptype, data)
    local ped = PlayerPedId()
    Location = location or GetEntityCoords(ped)
    isLaptop = location == nil

    if not Config.Computer.LaptopInVehicle then
        local inVehicle = IsPedInAnyVehicle(ped, true)
        if inVehicle then
            Location = nil
            CustomNotification(GetLocale("in_vehicle"))
            return
        end
    end

    exports["null-core"]:setChatCanOpen(false)
    ESX.TriggerServerCallback("ccmp:startComputer", function(ip)
        if ip then
            local visibleApps = {}
            -- Configuration des applications visibles
            if laptype == "laboratory" then
                visibleApps = {
                    ["laboratory-upgrades"] = data ~= nil and data.laboratory ~= nil,
                    ["code"] = false,
                    ["informations"] = false,
                    ["mail"] = false,
                    ["console"] = false,
                    ["addresses-content"] = false,
                    ["addresses"] = false,
                    ["market"] = false,
                    ["themes"] = true,
                    ["market-study"] = data ~= nil and data.laboratory and data.laboratory.upgrades and data.laboratory.upgrades["market-study"] or false,
                    ["security"] = data ~= nil and data.laboratory and data.laboratory.upgrades and data.laboratory.upgrades["security"] or false
                }
                inLaboId = data ~= nil and data.laboratory ~= nil and data.laboratory.id or nil
            else
                visibleApps = {
                    ["laboratory-upgrades"] = false,
                    ["code"] = true,
                    ["addresses-content"] = false,
                    ["addresses"] = true,
                    ["market"] = true,
                    ["market-study"] = false,
                    ["security"] = false
                }
                inLaboId = nil
            end

            -- S'assurer que les données sont dans le bon format
            local marketStudyData = data and data.market or {}
            if type(marketStudyData) ~= "table" then
                marketStudyData = {}
            end
            -- Envoyer d'abord le message principal sans itemsList
            SendNUIMessage({
                type = "show",
                ip = ip,
                idunique = ESX.PlayerData.idunique,
                laptop = isLaptop,
                market = AppConfig.Market,
                mailDomain = AppConfig.Mail.domain,
                addresses = AppConfig.Addresses,
                laboratory = data and data.laboratory or nil,
                applications = visibleApps,
                marketStudy = marketStudyData,
                history = data and data.laboratory and data.laboratory.History or { enter = {}, exit = {}, treatment = {}, sells = {} },
                itemsList = Config.Computer.ItemsList  
            })
            SetNuiFocus(true, true)
            UIOpen = true

            StartAnimationAndCheck(isLaptop, Location)
        else
            Location = nil
            CustomNotification(GetLocale("already_in_use"))
        end
    end, Location)
end

function CloseUI()
    SendNUIMessage({
        type = "force-close"
    })
    FreezeEntityPosition(PlayerPedId(), false)
end

exports("isComputerOpen", function()
    return UIOpen
end)

exports("isComputerALaptop", function()
    return isLaptop
end)

exports("openLaptop", function(laptype, data)
    OpenUI(nil, laptype, data)
end)

exports("closeLaptop", CloseUI)

if Config.Computer.UseItem and Config.Computer.UseItem ~= "" then
    RegisterNetEvent("null:laptop:open", OpenUI)
end

RegisterNUICallback("exit", function(_, cb)
    StopAnimation(isLaptop)
    SetNuiFocus(false, false)
    exports["null-core"]:setChatCanOpen(true)
    UIOpen = false
    TriggerServerEvent("ccmp:stopComputer", Location, isLaptop)
    Location = nil
    isLaptop = false
    cb("OK")
end)

RegisterNUICallback("NUIOk", function(_, cb)
    NUIOk = true
    cb("OK")
end)

local dataWaiting = false
local appsData = {
    themes = AppConfig.Themes,
    wallpapers = AppConfig.Wallpapers
}
RegisterNUICallback("getApplicationsData", function(data, cb)
    if dataWaiting then
        cb("")
        return
    end

    dataWaiting = true
    TriggerServerEvent("cuchi_computer:getApplicationsData", data and data.application or nil)

    while dataWaiting do
        Wait(10)
    end
    cb(appsData)
end)

local waiting = {
    market = false,
    mail = false
}
RegisterNUICallback("appAction", function(data, cb)
    if data.app == "market" then
        if  data.type == "create" then
            if not data.title or not data.description or IsStringBlank(data.title) or IsStringBlank(data.description) then
                cb("error_market_empty_arg")
                return
            end

            local title = Sanitize(data.title)
            local description = Sanitize(data.description)
            if #title > 16 or #description > 512 then
                cb("error_market_arg_overflow")
                return
            end

            waiting.market = "waiting"
            TriggerServerEvent("cuchi_computer:postMarket", title, description)
            while waiting.market == "waiting" do
                Wait(50)
            end

            if waiting.market == "delay" then
                cb("error_market_delay")
            elseif waiting.market == "max" then
                cb("error_market_max")
            else
                cb("OK")
            end

            waiting.market = false
        elseif data.type == "delete" then
            local id = tonumber(data.id)
            if id and id > 0 and math.type(id) == "integer" then
                waiting.market = "waiting"
                TriggerServerEvent("cuchi_computer:delete", id)
                while waiting.market == "waiting" do
                    Wait(50)
                end

                if waiting.market == "not_yours" then
                    cb("error_market_id_not_yours")
                else
                    cb("OK")
                end

                waiting.market = false
            else
                cb("error_market_id")
            end
        end
    elseif data.app == "mail" then
        if data.type == "create-acc" then
            if not data.username or IsStringBlank(data.username) or not data.password or IsStringBlank(data.password) then
                cb("mail_empty")
                return
            end

            local username = Sanitize(data.username)
            if #username > 16 or #data.password > 32 then
                cb("mail_input_overflow")
                return
            end

            waiting.mail = "waiting"
            TriggerServerEvent("ccmp:createAccount", username, data.password)
            while waiting.mail == "waiting" do
                Wait(50)
            end

            if waiting.mail == "used" then
                cb("mail_username_taken")
            else
                cb("OK")
            end

            waiting.market = false
        elseif data.type == "connect" then
            waiting.mail = "waiting"
            TriggerServerEvent("ccmp:mailConnect", data.username, data.password)
            while waiting.mail == "waiting" do
                Wait(50)
            end

            if waiting.mail == "wrong" then
                cb("mail_connect_wrong")
            else
                cb("OK")
            end

            waiting.mail = false
        elseif data.type == "send" then
            waiting.mail = "waiting"

            local address, count = string.gsub(data.to, AppConfig.Mail.domain, "")
            if count ~= 1 then
                cb("mail_send_error_address")
                return
            end

            if ((not data.object or IsStringBlank(data.object)) and not data.answerTo) or not data.text or IsStringBlank(data.text) then
                cb("mail_send_error_empty")
                return
            end

            local object
            if not data.answerTo then
                address = Sanitize(address)
                object = Sanitize(data.object)
                if #object > 32 then
                    cb("mail_send_error_overflow")
                    return
                end
            end

            local text = Sanitize(data.text)
            if #text > 4096 then
                cb("mail_send_error_overflow")
                return
            end

            TriggerServerEvent("ccmp:mailSend", address, object, text, data.answerTo)
            while waiting.mail == "waiting" do
                Wait(50)
            end

            if waiting.mail == "mail_error" then
                cb("mail_send_error_address")
            else
                cb("OK")
            end

            waiting.mail = false
        elseif data.type == "refresh" then
            appsData["mail"] = false
            TriggerServerEvent("ccmp:mailRefresh")

            while not appsData["mail"] do
                Wait(50)
            end

            local mailsLength = #appsData["mail"]
            local sortedMails = {}
            if mailsLength > 0 then
                for i = 1, mailsLength, 1 do
                    local mailData = appsData["mail"][i]
                    if mailData.answer_to == nil then
                        sortedMails[mailData.id] = {mailData}
                    else
                        sortedMails[mailData.answer_to][#sortedMails[mailData.answer_to]+1] = mailData
                        table.sort(sortedMails[mailData.answer_to], function(a,b) return a.timestamp > b.timestamp end)
                    end
                end
            end
            cb(sortedMails)
        elseif data.type == "readed" then
            TriggerServerEvent("ccmp:readMail", data.id)
            cb("OK")
        end
    end
end)

RegisterNUICallback("ipTracer", function(data, cb)
    if data.ip then
        Framework.TriggerServerCallback("ccmp:ipTracer", function(location)
            if location == "DISCONNECTED" then
                cb("DISCONNECTED")
            else
                local x = Round(location.x, 3)
                local y = Round(location.y, 3)
                cb({
                    zone = GetNameOfZone(x, y, 0.0),
                    latitude = x,
                    longitude = y,
                    location = x.." "..y
                })
                SetNewWaypoint(x, y)
            end
        end, data.ip)
    end
end)

RegisterNUICallback("netscan", function(_, cb)
    Framework.TriggerServerCallback("ccmp:netscan", function(addresses)
        cb(addresses)
    end)
end)

RegisterNUICallback("purchaseUpgrade", function(data, cb)
    if data.upgrade and data.laboratory then
        Framework.TriggerServerCallback("null:labo:purchaseUpgrade", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.upgrade, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("purchaseLabType", function(data, cb)
    if data.labType and data.laboratory then
        Framework.TriggerServerCallback("null:labo:purchaseLabType", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.labType, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("hireEmployee", function(data, cb)
    if data.employee and data.laboratory then
        Framework.TriggerServerCallback("null:labo:hireEmployee", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.employee, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("fireEmployee", function(data, cb)
    if data.employee and data.laboratory then
        Framework.TriggerServerCallback("null:labo:fireEmployee", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.employee, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("payEmployee", function(data, cb)
    if data.employee and data.laboratory then
        Framework.TriggerServerCallback("null:labo:payEmployee", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.employee, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

-- Callbacks pour la gestion des membres
RegisterNUICallback("inviteMember", function(data, cb)
    if data.memberId and data.laboratory then
        Framework.TriggerServerCallback("null:labo:inviteMember", function(success, message, memberName)
            cb({
                success = success,
                message = message,
                memberName = memberName
            })
        end, data.memberId, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("removeMember", function(data, cb)
    if data.memberId and data.laboratory then
        Framework.TriggerServerCallback("null:labo:removeMember", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.memberId, data.laboratory)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNUICallback("updateMemberPermissions", function(data, cb)
    print("updateMemberPermissions")
    if data.memberId and data.laboratory and data.permissions then
        Framework.TriggerServerCallback("null:labo:updateMemberPermissions", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.memberId, data.laboratory, data.permissions)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

RegisterNetEvent("cuchi_computer:response", function(app, res)
    waiting[app] = res
end)

RegisterNetEvent("cuchi_computer:getApplicationsData", function(app, data)
    appsData[app] = data
    dataWaiting = false
end)

-- Callbacks pour la gestion du laboratoire
RegisterNUICallback("transferLabOwnership", function(data, cb)
    if data.newOwnerId and data.laboratoryId then
        -- S'assurer que newOwnerId est un nombre
        local newOwnerId = tonumber(data.newOwnerId)
        if not newOwnerId then
            cb({
                success = false,
                message = "ID de joueur invalide"
            })
            return
        end
        
        Framework.TriggerServerCallback("null:labo:transferOwnership", function(success, message, newOwnerName)
            cb({
                success = success,
                message = message,
                newOwnerName = newOwnerName
            })
        end, newOwnerId, data.laboratoryId)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

CreateThread(function()
    SendNUIMessage({
        type = "version",
        version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    })
end)

-- Callbacks pour le service de livraison
RegisterNUICallback("placeDeliveryOrder", function(data, cb)
    if data.items and data.address then
        Framework.TriggerServerCallback("null:labo:placeDeliveryOrder", function(success, message, orderId)
            cb({
                success = success,
                message = message,
                orderId = orderId
            })
        end, data.items, data.address, data.note, data.total, inLaboId)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)

-- Callbacks pour le système de facturation
RegisterNUICallback("getBillingInfo", function(data, cb)
    if data.laboratoryId then
        Framework.TriggerServerCallback("null:labo:getBillingInfo", function(billingInfo)
            cb(billingInfo)
        end, data.laboratoryId)
    else
        cb(nil)
    end
end)

RegisterNUICallback("payLabBill", function(data, cb)
    if data.laboratoryId then
        Framework.TriggerServerCallback("null:labo:payBill", function(success, message)
            cb({
                success = success,
                message = message
            })
        end, data.laboratoryId)
    else
        cb({
            success = false,
            message = "Données invalides"
        })
    end
end)
