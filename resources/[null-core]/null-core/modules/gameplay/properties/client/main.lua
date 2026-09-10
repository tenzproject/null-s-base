Properties = nil
local CurrentProperties = nil 
local InVisite = false
local InProperties = false 
local BlipsList = {}
MyLicense = nil
local function Init()
    while null.data == nil or null.data.markers == nil or null.data.markers.list == nil do
        Wait(1)
    end
    for k,v in pairs(Properties) do 
        if not null.data.markers.list[k] then 
            if v.positions and v.immeuble == '0' then 
                null.data.markers.list[k] = {}
                null.data.markers.list[k].Position = vector3(v.positions.EXIT.x, v.positions.EXIT.y, v.positions.EXIT.z)
                null.data.markers.list[k].Public = true 
                null.data.markers.list[k].Job = nil
                null.data.markers.list[k].Job2 = nil
                null.data.markers.list[k].Blip = false
                null.data.markers.list[k].Action = function()
                    ActionProperties(k)
                end
            end
        end
        AddBlips(v)
    end
end

local function IsAllowedInProperty(data)
    if not data.parms then return false end
    -- Check if owner
    if data.owner == MyLicense then return true end
    if data.owner == ESX.PlayerData.job.name or data.owner == ESX.PlayerData.job2.name then return true end
    -- Check PeopleAlloweds
    if data.parms.PeopleAlloweds then
        for _, v in ipairs(data.parms.PeopleAlloweds) do
            if v.identifier == MyLicense then return true end
        end
    end
    return false
end

function AddBlips(data)
    if not BlipsList[data.name] then 
        while not MyLicense do 
            Wait(10)
        end
        if data.positions then
            local isOwner = data.owner == MyLicense or data.owner == ESX.PlayerData.job.name or data.owner == ESX.PlayerData.job2.name
            local isAllowed = not isOwner and IsAllowedInProperty(data)

            if not data.isBuy and data.immeuble == '0' and not isOwner and not isAllowed then
                BlipsList[data.name] = AddBlipForCoord(data.positions.EXIT.x, data.positions.EXIT.y, data.positions.EXIT.z)
                SetBlipSprite(BlipsList[data.name], 350)
                SetBlipScale(BlipsList[data.name], 0.50)
                SetBlipColour(BlipsList[data.name], 3)
                SetBlipDisplay(BlipsList[data.name], 4)
                SetBlipAsShortRange(BlipsList[data.name], true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName("Propriété libre")
                EndTextCommandSetBlipName(BlipsList[data.name])
            end
            if data.isBuy and (isOwner or isAllowed) then
                BlipsList[data.name] = AddBlipForCoord(data.positions.EXIT.x, data.positions.EXIT.y, data.positions.EXIT.z)
                SetBlipSprite(BlipsList[data.name], 411)
                SetBlipScale(BlipsList[data.name], 0.6)
                SetBlipColour(BlipsList[data.name], 26)
                SetBlipDisplay(BlipsList[data.name], 4)
                SetBlipAsShortRange(BlipsList[data.name], true)
                BeginTextCommandSetBlipName('STRING')
                if data.owner == MyLicense then
                    AddTextComponentSubstringPlayerName("Votre Propriété")
                elseif data.owner == ESX.PlayerData.job.name then
                    AddTextComponentSubstringPlayerName("Propriété "..ESX.PlayerData.job.label)
                elseif data.owner == ESX.PlayerData.job2.name then
                    AddTextComponentSubstringPlayerName("Propriété "..ESX.PlayerData.job2.label)
                else
                    AddTextComponentSubstringPlayerName("Votre Propriété")
                end
                EndTextCommandSetBlipName(BlipsList[data.name])
            end
        end
    end
end

local dev = false
function UpdateBlips(data)
    while not MyLicense do 
        Wait(10)
    end
    if data then
        if data.positions then
            local isOwner  = data.owner == MyLicense or data.owner == ESX.PlayerData.job.name or data.owner == ESX.PlayerData.job2.name
            local isAllowed = not isOwner and IsAllowedInProperty(data)
            if data.isBuy and (isOwner or isAllowed) then
                BlipsList[data.name] = AddBlipForCoord(data.positions.EXIT.x, data.positions.EXIT.y, data.positions.EXIT.z)
                SetBlipSprite(BlipsList[data.name], 357)
                SetBlipScale(BlipsList[data.name], 0.75)
                SetBlipColour(BlipsList[data.name], 0)
                SetBlipDisplay(BlipsList[data.name], 4)
                SetBlipAsShortRange(BlipsList[data.name], true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName("Propriété")
                EndTextCommandSetBlipName(BlipsList[data.name])
            end
        end
    else 
        for k,v in pairs(Properties) do 
            if v.owner == ESX.PlayerData.job.name or v.owner == ESX.PlayerData.job2.name and data ~= nil then
                if dev then
                    BlipsList[v.name] = AddBlipForCoord(v.positions.EXIT.x, v.positions.EXIT.y, v.positions.EXIT.z)
                    SetBlipSprite(BlipsList[v.name], 357)
                    SetBlipScale(BlipsList[v.name], 0.75)
                    SetBlipColour(BlipsList[v.name], 0)
                    SetBlipDisplay(BlipsList[v.name], 4)
                    SetBlipAsShortRange(BlipsList[v.name], true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName("Propriété")
                    EndTextCommandSetBlipName(BlipsList[v.name])
                end
            else 
                if DoesBlipExist(BlipsList[v.name]) then 
                    RemoveBlip(BlipsList[v.name])
                end
            end
        end
    end
end

function SizeOf(t)
    local count = 0

    for k,v in pairs(t) do
        count = count + 1
    end

    return tonumber(count)
end


function ActionProperties(propertiesId, buynotcreatedproperties)
    if buynotcreatedproperties then
        OpenMenuBuyPropreties(Properties[propertiesId])
    else
        if Properties[propertiesId] then 
            if not Properties[propertiesId].isBuy or Properties[propertiesId].isBuy == 0 then 
                OpenMenuBuyPropreties(Properties[propertiesId])
            else 
                ESX.TriggerServerCallback("null:properties:GetPlayerProperties", function(personalPropertiesList, jobProperties, job2Properties) 
                    local PlayerProperties = json.decode(personalPropertiesList)
                    local JobProperties = json.decode(jobProperties)
                    local job2Properties = json.decode(job2Properties)
                    for k,v in pairs(PlayerProperties) do 
                        if Properties[propertiesId].name == v.name then 
                            local isOwner = v.owner == MyLicense
                            if isOwner then
                                EnterProperties("myproperties", v)
                            else
                                local sharedPerms = nil
                                local propParms = Properties[propertiesId].parms
                                if propParms and propParms.PeopleAlloweds then
                                    for _, person in ipairs(propParms.PeopleAlloweds) do
                                        if person.identifier == MyLicense then
                                            sharedPerms = person.perms or { enter = true, deposit = true, withdraw = true }
                                            break
                                        end
                                    end
                                end
                                EnterProperties("sharedkeys", v, nil, sharedPerms or { enter = true, deposit = true, withdraw = true })
                            end
                            return
                        end
                    end
                    for k,v in pairs(JobProperties) do 
                        if Properties[propertiesId].owner == ESX.PlayerData.job.name then 
                            if Properties[propertiesId].name == v.name then 
                                if Properties[propertiesId].parms.GradesAlloweds[ESX.PlayerData.job.grade_label] or SizeOf(Properties[propertiesId].parms.GradesAlloweds) == 0 then 
                                    if SizeOf(Properties[propertiesId].parms.GradesAlloweds) == 0 then 
                                        TriggerServerEvent("null:properties:CheckIfGradeNotExistProperties", Properties[propertiesId], typeJob)
                                    end
                                    EnterProperties("jobproperties", v)
                                    return
                                else 
                                    ESX.ShowNotification("~r~Coffre propriété\n~s~Vous n'avez pas la permissions d'accéde à cette propriété.")
                                    return
                                end
                            end
                        end
                    end

                    for k,v in pairs(job2Properties) do
                        if Properties[propertiesId].owner == ESX.PlayerData.job2.name then 
                            if Properties[propertiesId].name == v.name then 
                                if Properties[propertiesId].parms.GradesAlloweds[ESX.PlayerData.job2.grade_label] or SizeOf(Properties[propertiesId].parms.GradesAlloweds) == 0 then 
                                    if SizeOf(Properties[propertiesId].parms.GradesAlloweds) == 0 then 
                                        TriggerServerEvent("null:properties:CheckIfGradeNotExistProperties", Properties[propertiesId], typeJob)
                                    end
                                    EnterProperties("jobproperties2", v)
                                    return
                                else 
                                    ESX.ShowNotification("~r~Coffre propriété\n~s~Vous n'avez pas la permissions d'accéde à cette propriété.")
                                    return
                                end
                            end
                        end
                    end
                    OpenMenuSonnerProperties(Properties[propertiesId])
                end)
            end
        end
    end
end

Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    while not MyLicense do Wait(50) end
    ESX.TriggerServerCallback("null:properties:GetProperties", function(propertiesList)
        Properties = propertiesList
    end)
    while Properties == nil do Wait(100) end
    Init()
end)

RegisterNetEvent("h:propertySyncProperties")
AddEventHandler("h:propertySyncProperties", function()
    ESX.TriggerServerCallback("null:properties:GetProperties", function(propertiesList)
        Properties = propertiesList
    end)
end)

-- Periodic check to ensure properties data is loaded (handles resource restart)
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        if Properties == nil then
            TriggerServerEvent("null:properties:RequestData")
        end
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
    UpdateBlips()
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
    ESX.PlayerData.job2 = job2
    UpdateBlips()
end)

RegisterNetEvent("null:properties:UpdatePropertiesList")
AddEventHandler("null:properties:UpdatePropertiesList", function(propertiesList)
    Properties = propertiesList
    Init()
end)

RegisterNetEvent("null:properties:UpdatePropertiesBuyed")
AddEventHandler("null:properties:UpdatePropertiesBuyed", function(propertiesId, isBuy, newOwner)
    if Properties[propertiesId] and null.data.markers.list[propertiesId] then 
        Properties[propertiesId].isBuy = isBuy
        null.data.markers.list[propertiesId].isBuy = isBuy
        Properties[propertiesId].owner = newOwner
        UpdateBlips(Properties[propertiesId])
    end
end)

RegisterNetEvent("null:properties:UpdatePropertiesJob")
AddEventHandler("null:properties:UpdatePropertiesJob", function(propertiesId, jobName)
    if Properties[propertiesId] then 
        Properties[propertiesId].owner = jobName
        UpdateBlips(Properties[propertiesId])
    end
end)

RegisterNetEvent("null:properties:KeysUpdated")
AddEventHandler("null:properties:KeysUpdated", function(propName, perms)
    -- Player received keys while possibly inside the property
    -- Show notification about new permissions
    local permStr = ""
    if perms.enter then permStr = permStr .. "Entrée " end
    if perms.deposit then permStr = permStr .. "Dépôt " end
    if perms.withdraw then permStr = permStr .. "Retrait" end
    ESX.ShowNotification("~g~Accès mis à jour~s~\nVous pouvez maintenant utiliser le coffre. Perms: "..permStr)
    -- If inside property, re-register the coffre marker with updated permissions
    if InProperties and CurrentProperties and CurrentProperties.name == propName then
        null.data.markers.register("propertiesCoffre", {
            Position = vector3(CurrentProperties.positions.COFFRE.x, CurrentProperties.positions.COFFRE.y, CurrentProperties.positions.COFFRE.z+1),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                OpenMenuCoffreProperties(CurrentProperties, true, nil, perms)
            end
        })
    end
end)

RegisterNetEvent("null:properties:KeysRevoked")
AddEventHandler("null:properties:KeysRevoked", function(propName)
    -- Keys were revoked - if inside property, remove coffre marker access
    if InProperties and CurrentProperties and CurrentProperties.name == propName then
        ESX.ShowNotification("~r~Accès retiré~s~\nVos clés ont été révoquées. Vous ne pouvez plus utiliser le coffre.")
        -- Remove the coffre marker - player must exit
        null.data.markers.unregister("propertiesCoffre")
    end
end)

RegisterNetEvent("null:properties:EnterPropertiesBySonnet")
AddEventHandler("null:properties:EnterPropertiesBySonnet", function(propreties, bucketID)
    if Properties[propreties.name] then 
        EnterProperties("bysonnet", propreties, bucketID)
    end
end)

RegisterNetEvent("null:properties:ExitProperties")
AddEventHandler("null:properties:ExitProperties", function(propertiesId)
    if Properties[propertiesId] then 
        ExitProperties("myproperties")
    end
end)


RegisterNetEvent("null:properties:forceExitProperty")
AddEventHandler("null:properties:forceExitProperty", function()
    if InProperties then
        ExitProperties("myproperties")
    end
end)


function EnterProperties(enterType, info, bucketID, sharedPerms)
    RageUI.CloseAll()
    CurrentProperties = info
    local pPed = PlayerPedId()

    if enterType == "visite" then 
        InVisite = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
    elseif enterType == "myproperties" then 
        InProperties = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "solo", info.bucketID)
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", info, "enter")
            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
        null.data.markers.register("propertiesExit", {
            Position = vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                ExitProperties("myproperties")
            end
        })
        null.data.markers.register("propertiesCoffre", {
            Position = vector3(info.positions.COFFRE.x, info.positions.COFFRE.y, info.positions.COFFRE.z+1),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                -- Owner enters with full permissions
                OpenMenuCoffreProperties(info, false, nil, { enter = true, deposit = true, withdraw = true })
            end
        })
        -- if not succes and not succes2 then 
        --     ExitProperties("error")
        -- end
    elseif enterType == "jobproperties" then 
        InProperties = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "group", info.bucketID)
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", info, "enter")
            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
        null.data.markers.register("propertiesExit", {
            Position = vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                ExitProperties("myproperties")
            end
        })
        null.data.markers.register("propertiesCoffre", {
            Position = vector3(info.positions.COFFRE.x, info.positions.COFFRE.y, info.positions.COFFRE.z+1),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                OpenMenuCoffreProperties(info, true, "job")
            end
        })
        -- if not succes and not succes2 then 
        --     ExitProperties("error")
        -- end
    elseif enterType == "jobproperties2" then 
        InProperties = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "group", info.bucketID)
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", info, "enter")
            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
        null.data.markers.register("propertiesExit", {
            Position = vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                ExitProperties("myproperties")
            end
        })
        null.data.markers.register("propertiesCoffre", {
            Position = vector3(info.positions.COFFRE.x, info.positions.COFFRE.y, info.positions.COFFRE.z+1),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                OpenMenuCoffreProperties(info, true, "job2")
            end
        })
        -- if not succes and not succes2 then 
        --     ExitProperties("error")
        -- end
    elseif enterType == "sharedkeys" then 
        InProperties = true
        local perms = sharedPerms or { enter = true, deposit = true, withdraw = true }
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "group", info.bucketID)
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", info, "enter")
            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
        null.data.markers.register("propertiesExit", {
            Position = vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                ExitProperties("myproperties")
            end
        })
        if perms.enter then
            null.data.markers.register("propertiesCoffre", {
                Position = vector3(info.positions.COFFRE.x, info.positions.COFFRE.y, info.positions.COFFRE.z+1),
                Public = true,
                Job = nil,
                Job2 = nil,
                Blip = false,
                Action = function()
                    OpenMenuCoffreProperties(info, true, nil, perms)
                end
            })
        end
    elseif enterType == "bysonnet" then 
        InProperties = true
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "group", bucketID)
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", info, "enter")
            SetEntityCoords(pPed, vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z))
            DoScreenFadeIn(800)
            Wait(1000)
        end)
        null.data.markers.register("propertiesExit", {
            Position = vector3(info.positions.ENTER.x, info.positions.ENTER.y, info.positions.ENTER.z),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                ExitProperties("myproperties")
            end
        })
        null.data.markers.register("propertiesCoffre", {
            Position = vector3(info.positions.COFFRE.x, info.positions.COFFRE.y, info.positions.COFFRE.z+1),
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = false,
            Action = function()
                OpenMenuCoffreProperties(info, true)
            end
        })
        -- if not succes and not succes2 then 
        --     ExitProperties("error")
        -- end
    end
end

function ExitProperties(exitType)
    RageUI.CloseAll()
    local pPed = PlayerPedId()

    if exitType == "visite" then 
        InVisite = false
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            SetEntityCoords(pPed, vector3(CurrentProperties.positions.EXIT.x, CurrentProperties.positions.EXIT.y, CurrentProperties.positions.EXIT.z))
            DoScreenFadeIn(800)
            Wait(1000)
            CurrentProperties = nil
        end)
    elseif exitType == "myproperties" then 
        InProperties = false
        ESX.ShowNotification("~g~Propriété~s~\nVous sortez ...")
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "remettre")
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", CurrentProperties, "exit")
            SetEntityCoords(pPed, vector3(CurrentProperties.positions.EXIT.x, CurrentProperties.positions.EXIT.y, CurrentProperties.positions.EXIT.z))
            DoScreenFadeIn(800)
            Wait(1000)
            CurrentProperties = nil
        end)
        null.data.markers.unregister("propertiesExit")
        null.data.markers.unregister("propertiesCoffre")
    elseif exitType == "jobproperties" then 
        InProperties = false
        ESX.ShowNotification("~g~Propriété~s~\nVous sortez ...")
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "remettre")
            TriggerServerEvent("null:properties:PlayerEntrerOrExitThisProperties", CurrentProperties, "exit")
            SetEntityCoords(pPed, vector3(CurrentProperties.positions.EXIT.x, CurrentProperties.positions.EXIT.y, CurrentProperties.positions.EXIT.z))
            DoScreenFadeIn(800)
            Wait(1000)
            CurrentProperties = nil
        end)
        null.data.markers.unregister("propertiesExit")
        null.data.markers.unregister("propertiesCoffre")
    elseif exitType == "error" then 
        Wait(2000)
        ESX.ShowNotification("~r~Propriété~s~\nUne erreur est survenu. Reconnectez-vous.")
        Citizen.CreateThread(function()
            DoScreenFadeOut(800)

            while not IsScreenFadedOut() do
                Wait(0)
            end

            TriggerServerEvent("null:properties:SetBucket", "remettre")
            SetEntityCoords(pPed, vector3(CurrentProperties.positions.EXIT.x, CurrentProperties.positions.EXIT.y, CurrentProperties.positions.EXIT.z))
            DoScreenFadeIn(800)
            CurrentProperties = nil
            Wait(1000)
        end)
    end
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do 
        if InVisite then
            interval = 1
            Visual.Subtitle("Vous êtes en pleine visite.\nAppuyez sur [~p~E~s~] pour sortir de la visite", 100)
            if IsControlJustPressed(1, 51) then
                ExitProperties("visite")
            end
        else 
            interval = 800
        end
        Wait(interval)
    end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do 
        if InProperties then 
            Wait(1)
            if CurrentProperties and #(GetEntityCoords(PlayerPedId()) - vector3(CurrentProperties.positions.ENTER.x, CurrentProperties.positions.ENTER.y, CurrentProperties.positions.ENTER.z)) > 50 then
                SetEntityCoords(PlayerPedId(), vector3(CurrentProperties.positions.ENTER.x, CurrentProperties.positions.ENTER.y, CurrentProperties.positions.ENTER.z))
            end
        else 
            Wait(1000)
        end
    end
end))

RegisterNetEvent("null:properties:NotificationSonnedProperties")
AddEventHandler("null:properties:NotificationSonnedProperties", function(propertiesId, id)
    local timed = 0
    if Properties[propertiesId] then 
        --ESX.ShowNotification("~g~Propriété\n~s~Une personne viens de sonner à votre propriété.")
        PlaySoundFrontend(l_6C6, "DOOR_BUZZ", "MP_PLAYER_APARTMENT", 1)
        ESX.ShowAccept("Une personne viens de sonner à votre propriété.", function(result)
            if result then
                TriggerServerEvent("null:properties:ReturnPlayerSonnedProperties", "accept", id, Properties[propertiesId])
                PlaySoundFrontend(-1, "WOODEN_DOOR_OPEN_HANDLE_AT", 0, 1)
            else
                TriggerServerEvent("null:properties:ReturnPlayerSonnedProperties", "decline", id, Properties[propertiesId])
            end
        end)
    end
end)

Citizen.CreateThread(function()
    Wait(4000)
    TriggerServerEvent('loadlicense')
end)

RegisterNetEvent("InitLicense")
AddEventHandler('InitLicense', function(license)
    MyLicense = license
end)