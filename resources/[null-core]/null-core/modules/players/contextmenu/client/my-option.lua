local playerName = ""
local playerJob = ""
local playerJob2 = ""
checkboxStates = checkboxStates or {}
function hasSaspJob()
    local job = ESX.GetPlayerData().job.name
    return job == 'sasp'
end

function hasDoaJob()
    local job2 = ESX.GetPlayerData().job2.name
    return job2 == 'doa'
end
local isHandcuffed = false

while nTable == nil do Wait(10) end

if nTable.invincible == nil then
    nTable.invincible = false
end

function IsPlayerInAnim(...)
    for k,v in pairs(Config.Animation) do 
        if v.use and v.IsPlayerInAnim then
            return v.IsPlayerInAnim(...)
        end
    end
end

function EmoteCommandStart(name)
    for k,v in pairs(Config.Animation) do 
        if v.use and v.EmoteCommandStart then
            v.EmoteCommandStart(name)
        end
    end
end

function getPlayerAnim()
    for k,v in pairs(Config.Animation) do 
        if v.use and v.getPlayerAnim then
            return v.getPlayerAnim()
        end
    end
end

ContextMenuConfig = {
    language = 'fr',
    color = { r = 230, g = 230, b = 230, a = 255 }, -- Text color
    font = 0, -- Text font
    time = 5000, -- Duration to display the text (in ms)
    scale = 0.5, -- Text scale
    dist = 250, -- Min. distance to draw 
}

local CMLocale = {
    commandName = 'me',
    commandDescription = 'Affiche une action au dessus de votre tête.',
    commandSuggestion = {{ name = 'action', help = '"se gratte le nez" par exemple.'}},
    prefix = 'l\'individu '
}

local peds = {}

local GetGameTimer = GetGameTimer

local function sanitizeContext3DText(text)
    text = tostring(text or "")
    text = text:gsub("[%z\1-\31\127]", " ")
    text = text:gsub("[\128-\255]", "")
    text = text:gsub("~.-~", "")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")

    if text == "" then
        return nil
    end

    return text:sub(1, 88)
end

local function addContextTextComponents(text)
    local maxLength = 48

    for i = 1, #text, maxLength do
        AddTextComponentString(text:sub(i, i + maxLength - 1))
    end
end

local function draw3dText(coords, text)
    text = sanitizeContext3DText(text)
    if text == nil then return end

    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    
    local scale = 200 / (GetGameplayCamFov() * dist)

    SetTextColour(ContextMenuConfig.color.r, ContextMenuConfig.color.g, ContextMenuConfig.color.b, ContextMenuConfig.color.a)
    SetTextScale(0.0, ContextMenuConfig.scale * scale)
    SetTextFont(ContextMenuConfig.font)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    addContextTextComponents(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()

end

local function displayText(ped, text)
    text = sanitizeContext3DText(text)
    if text == nil or ped == nil or ped == 0 or not DoesEntityExist(ped) then return end

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local targetPos = GetEntityCoords(ped)
    local dist = #(playerPos - targetPos)
    local los = HasEntityClearLosToEntity(playerPed, ped, 17)

    if dist <= ContextMenuConfig.dist and los then
        local exists = peds[ped] ~= nil

        peds[ped] = {
            time = GetGameTimer() + ContextMenuConfig.time,
            text = text
        }

        if not exists then
            local display = true

            while display do
                Wait(0)
                local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 1.0)
                draw3dText(pos, peds[ped].text)
                display = GetGameTimer() <= peds[ped].time
            end

            peds[ped] = nil
        end

    end
end

local function onShareDisplay(text, target)
    local player = GetPlayerFromServerId(target)
    if player ~= -1 and (player ~= PlayerId() or target == GetPlayerServerId(PlayerId())) then
        local ped = GetPlayerPed(player)
        displayText(ped, text)
    end
end

RegisterNetEvent('3dme:shareDisplay', onShareDisplay)

TriggerEvent('chat:addSuggestion', '/' .. CMLocale.commandName, CMLocale.commandDescription, CMLocale.commandSuggestion)


RegisterNetEvent('esx_menotte:handcuffAnimation')
AddEventHandler('esx_menotte:handcuffAnimation', function()
    isHandcuffed = true
    
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Wait(100)
    end
    
    TaskPlayAnim(LastEntityHit, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
    SetEnableHandcuffs(LastEntityHit, true)
    DisablePlayerFiring(LastEntityHit, true)
    SetCurrentPedWeapon(LastEntityHit, GetHashKey('WEAPON_UNARMED'), true)
    ESX.ShowNotification('~g~Le joueur est menotté')
end)

RegisterNetEvent('esx_menotte:uncuffAnimation')
AddEventHandler('esx_menotte:uncuffAnimation', function()
    isHandcuffed = false
    
    ClearPedSecondaryTask(LastEntityHit)
    SetEnableHandcuffs(LastEntityHit, false)
    DisablePlayerFiring(LastEntityHit, false)
    ESX.ShowNotification('~r~Le joueur est démenotté')
end)
function _My()
    local hasAccessToAdmin = false
    if Config.GroupeHighPerm[ESX.PlayerData.group] or ESX.PlayerData.group == "admin" or ESX.PlayerData.group == "superadmin" then
        hasAccessToAdmin = true
    end

    local menuActions = {
        {
            user = "user", -- SI VOUS METTEZ "user" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            mod = "mod", -- SI VOUS METTEZ "mod" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            admin = "admin", -- SI VOUS METTEZ "admin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            superadmin = "superadmin", -- SI VOUS METTEZ "superadmin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            _dev = "_dev", -- SI VOUS METTEZ "_dev" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            owner = "owner", -- SI VOUS METTEZ "owner" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !

            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = true,
            KeepNuiFocus = true,
            Label = "La personne (...)",
            OnClick = function()
                local input = null.fct.input("Votre message :")
                if input == nil then return end
                ExecuteCommand('me ' .. input)
            end,
        },
        {
            Type = "buttom",
            IsAllowed = true,
            Blocked = false,
            CloseOnClick = true,
            Label = "Se nettoyer",
            OnClick = function()
                local playerPed = PlayerPedId()
                ExecuteCommand('e cleanhands')
                ShowProgressBar('Vous vous nettoyez', 3000)
        
                ClearPedBloodDamage(playerPed)
                ResetPedVisibleDamage(playerPed)
                ClearPedLastWeaponDamage(playerPed)
                ClearPedEnvDirt(playerPed)
                ClearPedWetness(playerPed)
                ExecuteCommand("e c")
            end,
        },
        {
            user = "user", -- SI VOUS METTEZ "user" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            mod = "mod", -- SI VOUS METTEZ "mod" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            admin = "admin", -- SI VOUS METTEZ "admin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            superadmin = "superadmin", -- SI VOUS METTEZ "superadmin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            _dev = "_dev", -- SI VOUS METTEZ "_dev" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            owner = "owner", -- SI VOUS METTEZ "owner" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !

            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = false,
            Label = ("ID: %s"):format(GetPlayerServerId(PlayerId())),
            OnClick = function()
                exports["null-core"]:copy(GetPlayerServerId(PlayerId()))
            end,
        },
        {
            user = "user", -- SI VOUS METTEZ "user" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            mod = "mod", -- SI VOUS METTEZ "mod" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            admin = "admin", -- SI VOUS METTEZ "admin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            superadmin = "superadmin", -- SI VOUS METTEZ "superadmin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            _dev = "_dev", -- SI VOUS METTEZ "_dev" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
            owner = "owner", -- SI VOUS METTEZ "owner" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !

            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = false,
            Label = ("UID: %s"):format(ESX.PlayerData.idunique),
            OnClick = function()
                exports["null-core"]:copy(ESX.PlayerData.idunique)
            end,
        },
        {
            Type = "buttom",
            Blocked = not IsPlayerInAnim(),
            CloseOnClick = true,
            Label = "Ajuster l'animation (~y~VIP~s~)",
            OnClick = function()
                if not GetVIP() then return end
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local getIfPlayerPlayAnim = IsPlayerInAnim()
        
                if getIfPlayerPlayAnim and not IsPedInAnyVehicle(ped, false) then
                    local clonePed = ClonePed(ped, false, false, true)
                    local getPlayedAnim = getPlayerAnim()
                    local animOption = getPlayedAnim["AnimationOptions"]
                    if getPlayedAnim and type(getPlayedAnim) == "table" and json.encode(getPlayedAnim) ~= "[]" then
                        SetEntityNoCollisionEntity(ped, clonePed, false)
                        FreezeEntityPosition(ped, true)
                        if getPlayedAnim[1] == "Scenario" then
                            Citizen.CreateThread(function()
                                Wait(1000)
                                TaskStartScenarioInPlace(clonePed, getPlayedAnim[2], 0, true)
                            end)
                        else
                            TaskPlayAnim(clonePed, getPlayedAnim[1], getPlayedAnim[2], 8.0, 8.0, -1, animOption.MovementType, 0, false, false, false)
                        end
                        SetEntityHeading(clonePed, GetEntityHeading(ped))
                        SetEntityAlpha(clonePed, 50, true)
                        FreezeEntityPosition(clonePed, true)
                        SetEntityInvincible(clonePed, true)
                        TaskSetBlockingOfNonTemporaryEvents(clonePed, true)
        
                        CreateThread(function()
                            while DoesEntityExist(clonePed) do 
                                if not IsEntityPlayingAnim(clonePed, getPlayedAnim[1], getPlayedAnim[2], 3) then
                                    if getPlayedAnim[1] == "Scenario" then
                                        
                                    else
                                        TaskPlayAnim(clonePed, getPlayedAnim[1], getPlayedAnim[2], 8.0, 8.0, -1, animOption.MovementType, 0, false, false, false)
                                    end
                                end
                                Wait(1000)
                            end
                        end)
        
                        useGizmo(clonePed)
        
                        Wait(500) 
                        local clonePedPose = GetEntityCoords(clonePed)
        
                        if #(pedCoords - clonePedPose) > 10.0 then
                            DeleteEntity(clonePed)
                            FreezeEntityPosition(ped, false)
                            TriggerEvent("esx:showNotification", "🚫 Trop loin ! Placez l'animation à moins de 10m.")
                            return
                        end
        
                        local _, groundZ = GetGroundZFor_3dCoord(clonePedPose.x, clonePedPose.y, clonePedPose.z, false)
                        if clonePedPose.z - groundZ > 2.0 then
                            clonePedPose = vector3(clonePedPose.x, clonePedPose.y, groundZ + 0.1)
                        end
        
                        SetEntityAlpha(clonePed, 0, false)  
                        SetEntityCollision(clonePed, false, false)
        
                        FreezeEntityPosition(ped, false)
                        SetPedCanRagdoll(ped, false)
                        DisableControlAction(0, 21, true) 
                        DisableControlAction(0, 22, true) 
                        DisableControlAction(0, 30, true) 
                        DisableControlAction(0, 31, true) 
        
                        TaskTurnPedToFaceCoord(ped, clonePedPose.x, clonePedPose.y, clonePedPose.z, 1000)
                        Wait(1000)
        
                        TaskGoToCoordAnyMeans(ped, clonePedPose.x, clonePedPose.y, clonePedPose.z, 1.0, 0, 0, 786603, 0)
        
                        CreateThread(function()
                            local timeout = 10000 
                            local startTime = GetGameTimer()
        
                            while #(GetEntityCoords(ped) - clonePedPose) > 1.0 and (GetGameTimer() - startTime) < timeout do
                                Wait(500)
                            end
        
                            ClearPedTasksImmediately(ped)
                            FreezeEntityPosition(clonePedPose, true)
                            FreezeEntityPosition(ped, true)
                            SetEntityCollision(ped, false)
                            SetEntityCoords(ped, clonePedPose.x, clonePedPose.y, clonePedPose.z-0.98)
                            SetEntityHeading(ped, GetEntityHeading(clonePed))
        
                            Wait(200)

                            EmoteCommandStart(getPlayedAnim[4])
                            DeleteEntity(clonePed)
                            
        
                            EnableControlAction(0, 21, true) 
                            EnableControlAction(0, 22, true) 
                            EnableControlAction(0, 30, true) 
                            EnableControlAction(0, 31, true) 
                            SetPedCanRagdoll(ped, true)
        
                            CreateThread(function()
                                while IsPlayerInAnim() do
                                    Wait(500)
                                end
                                FreezeEntityPosition(ped, false)
                                SetEntityCollision(ped, true)
                            end)
                        end)
                    else
                        DeleteEntity(clonePed)
                        FreezeEntityPosition(ped, false)
                        ESX.ShowNotification("Cette animation n'est pas ajustable.")
                    end
                else
                    print("Error: You are not playing an animation")
                end
            end,
        },                                   
        {
            Type = "buttom",
            IsAllowed = true,
            Blocked = false,
            CloseOnClick = true,
            Label = "S'asseoir",
            OnClick = function()
                TriggerEvent('Boost-Sit:Sit')
            end,
        },              
        {
            Type = "buttom-submenu",
            CloseOnClick = true,
            Blocked = false,
            Label = "Utiliser un item",
        
            Action = (function()
                local actions = {}
                local itemList = {"basic_key", "basic_cuff", "police_key", "police_cuff", "cle_menottes", "water", "bread", "plantpot"}
                
                local itemActions = {}

                for k,v in pairs(itemList) do
                    for k2, v2 in pairs(ESX.PlayerData.inventory) do
                        if v2.name == v then
                            table.insert(actions, {
                                string.format("%s (x%d)", v2.label, v2.count),
                                itemActions[v2.name] or function()
                                    TriggerServerEvent('esx:useItem', v2.name)
                                end
                            })
                        end
                    end
                end
        
                return actions
            end)(),
        },
        
    }
    

    -- Ajouter le menu de sauvegarde si le joueur a le job SASP
    if hasSaspJob() then
        table.insert(menuActions, {
            Type = "buttom-submenu",
            Label = "Demande de renfort (SASP)",
            CloseOnClick = false,
            Action = {
                {
                    "Backup 1",
                    function()
                        TriggerEvent('Rvm-alert:B1sasp', GetEntityCoords(PlayerPedId()))
                        ExecuteCommand('me fait une backup 1')
                    end
                },
                {
                    "Backup 2",
                    function()
                        TriggerEvent('Rvm-alert:B2sasp', GetEntityCoords(PlayerPedId()))
                        ExecuteCommand('me fait une backup 2')
                    end,
                },
                {
                    "Backup 3",
                    function()
                        TriggerEvent('Rvm-alert:B3sasp', GetEntityCoords(PlayerPedId()))
                        ExecuteCommand('me fait une backup 3')
                    end,
                },
                {
                    "Global SAMS",
                    function()
                        TriggerEvent('Rvm-alert:sams', GetEntityCoords(PlayerPedId()))
                        ExecuteCommand('me fait une backup SAMS')
                    end
                },
            },
        })
    end


    if hasDoaJob() then
        table.insert(menuActions, {
            Type = "buttom-submenu",
            Label = "Demande de renfort (DOA)",
            CloseOnClick = false,
            Action = {
                {
                    "Backup DOA",
                    function()
                        TriggerEvent('Rvm-alert:doa', GetEntityCoords(PlayerPedId()))
                        ExecuteCommand('me fait une backup DOA')
                    end
                },
            },
        })
    end


    -- Ajouter les autres options du menu
    table.insert(menuActions, {
        Type = "buttom-submenu",
        Label = "Outils de debug",
        IsRestricted = false,
        CloseOnClick = false,
        Action = {
            {
                ("Modèle : %s"):format(
                    (function()
                    local model = GetEntityModel(PlayerPedId())
                    local modelHashMale = GetHashKey("mp_m_freemode_01")
                    local modelHashFemale = GetHashKey("mp_f_freemode_01")

                    if model == modelHashMale then
                        return "mp_m_freemode_01"
                    elseif model == modelHashFemale then
                        return "mp_f_freemode_01"
                    else
                        return "Inconnu"  -- Retourne "Inconnu" si le modèle ne correspond à aucun des deux
                    end
                    end)()
                ),
                function()
                    local model = GetEntityModel(PlayerPedId())
                    local modelName = "Inconnu"  -- Valeur par défaut

                    local modelHashMale = GetHashKey("mp_m_freemode_01")
                    local modelHashFemale = GetHashKey("mp_f_freemode_01")

                    if model == modelHashMale then
                        modelName = "mp_m_freemode_01"
                    elseif model == modelHashFemale then
                        modelName = "mp_f_freemode_01"
                    end

                    print("Votre modèle : " .. modelName)
                end,
            },
            {
                ("Position : %.2f, %.2f, %.2f"):format(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z),
                function()
                    local myposition = GetEntityCoords(PlayerPedId())
                    print(("Votre position : %s"):format(myposition))
                end,
            },
        },
    })
    table.insert(menuActions, {
        Type = "buttom-submenu",
        Label = "Informations sur vous",
        IsRestricted = false,
        CloseOnClick = false,
        Action = {
            {
                ("Pseudo : "..ESX.Config("serverColor").."%s"):format(GetPlayerName(PlayerId())),
                function()
                end,
            },
            {
                ("Prenom : %s"):format(ESX.PlayerData.firstname),
                function()
                end,
            },
            {
                ("Nom : %s"):format(ESX.PlayerData.lastname),
                function()
                end,
            },
            {
                "Job : "..ESX.PlayerData.job.label,
                function()
                end,
            },
            {
                "Grade : "..ESX.Config("serverColor")..ESX.PlayerData.job.grade_name,
                function()
                end
            },
            {
                "Groupe illégal : "..ESX.PlayerData.job2.label,
                function()
                end,
            },
            {
                "Grade : "..ESX.Config("serverColor")..ESX.PlayerData.job2.grade_name,
                function()
                end
            },
        },
    })

    table.insert(menuActions, {
        Type = "buttom-submenu",
        Label = "Administration",
        IsRestricted = true,
        CloseOnClick = false,
        Action = {

            --[[{
                ("Pseudo : %s"):format(GetPlayerName(PlayerId())),
                function()
                end,
            },
            {
                ("Prenom : %s"):format(ESX.PlayerData.firstname),
                function()
                end,
            },
            {
                ("Nom : %s"):format(ESX.PlayerData.lastname),
                function()
                end,
            },
            {
                "Job : "..ESX.PlayerData.job.label,
                function()
                end,
            },
            {
                "Grade : ~b~"..ESX.PlayerData.job.grade_name,
                function()
                end
            },
            {
                "Groupe illégal : "..ESX.PlayerData.job2.label,
                function()
                end,
            },
            {
                "Grade : ~b~"..ESX.PlayerData.job2.grade_name,
                function()
                end
            },]]
            {
                "Supprimer un item",
                permissions = "give_item",
                function()
                    ExecuteCommand('trash')
                end,
            },
            {
                "Heal",
                permissions = "heal",
                function()
                    SetEntityHealth(PlayerPedId(), 200)
                end,
            },
            {
                "Manger",
                permissions = "heal",
                function()
                    TriggerEvent("esx_status:set", "hunger", 1000000)
                end,
            },
            {
                "Boire",
                permissions = "heal",
                function()
                    TriggerEvent("esx_status:set", "thirst", 1000000)
                end,
            },
            {
                "Gilet pare balle",
                permissions = "invincible",
                function()
                    SetPedArmour(PlayerPedId(), 100)
                end,
            },
            {
                "Kill",
                permissions = "heal",
                function()
                    SetEntityHealth(PlayerPedId(), 0)
                end,
            },
            {
                Type = "checkbox",
                Label = "Godmod",
                permissions = "invincible",
                IsChecked = nTable and nTable.invincible or false,
                OnRelease = function(isChecked)
                    nTable.invincible = isChecked
                    godMod(isChecked)
                end,
            },
            --[[{
                "Liste des items",
                function()
                    --TriggerEvent("ox_inventory:openInventory", 'shop', { type = 'Admin', id = 1 })
                end,
            },
            {
                "Chercher un item",
                KeepNuiFocus = true,
                function()
                    local item = null.fct.input("Nom de l'item")
                    ExecuteCommand('adminsearch ' ..item)
                end,
            },]]
            {
                'Donner un item (autre joueurs/soi-meme)',
                KeepNuiFocus = true,
                permissions = "give_item",
                function() 
                    -- local id = null.fct.input("ID du joueur")
                    -- local item = null.fct.input("Nom de l'item")
                    -- local amount = null.fct.input("Quantité d'item")
                    -- ExecuteCommand('giveitem ' ..id.." "..item.." "..amount)
                    local id = null.fct.smallInput("ID du joueur", "Vous pouvez mettre l'id 0 pour vous donnez l'item.")
                    if id == nil then return end
                    id = tonumber(id)
                    if id == 0 then
                        id = PlayerState.serverId
                    end
                    ESX.TriggerServerCallback("AdminMenu:getItemOnDtb", function(items)
                        RageUI.OpenItemGrid({
                            items = items,
                            title = "Donner un Item",
                            mode = "item",
                            callback = function(data)
                                null.fct.inputCb("Nombre d'items à give", function(amount)
                                    if amount ~= nil and tonumber(amount) then
                                        TriggerServerEvent("AdminMenu:giveItem", id, data.name, data.label, tonumber(amount))
                                    else
                                        ESX.ShowNotification("Montant Invalide")
                                    end
                                end)
                            end
                        })
                    end, false)
                end
            },
            {
                'Donner une arme (autre joueurs/soi-meme)',
                KeepNuiFocus = true,
                permissions = "give_weapon",
                function() 
                    -- local id = null.fct.input("ID du joueur")
                    -- local item = null.fct.input("Nom de l'item")
                    -- local amount = null.fct.input("Quantité d'item")
                    -- ExecuteCommand('giveitem ' ..id.." "..item.." "..amount)
                    local id = null.fct.smallInput("ID du joueur", "Vous pouvez mettre l'id 0 pour vous donnez l'item.")
                    if id == nil then return end
                    id = tonumber(id)
                    if id == 0 then
                        id = PlayerState.serverId
                    end
                    ESX.TriggerServerCallback("AdminMenu:getWeapon", function(weapons)
                        RageUI.OpenItemGrid({
                            items = weapons,
                            title = "Donner une Arme",
                            mode = "weapon",
                            callback = function(data)
                                local Description = ""
                                if ESX.ContribWeapon(data.name) then
                                    Description = "Ceci est une arme permanante"
                                end
                                local Options = {}
                                if (StaffHasPerm("GIVE_WEAPON_BOUTIQUE")) then
                                    Options = null.fct.input2("Configuration de l'arme", true, {
                                        {type = 'input', label = 'Nom de l\'arme', description = 'Le nom afficher de l\'arme', required = true, min = 1, max = 20, default=data.label},
                                        {type = 'input', label = 'Description de l\'arme', description = 'La description de l\'arme', required = false, min = 1, max = 100, default=Description},
                                        {type = 'checkbox', label = 'Numero de serie', default = true},
                                        {type = 'checkbox', label = 'Arme Permanente'},
                                    }, false)
                                else
                                    Options = null.fct.input2("Configuration de l'arme", true, {
                                        {type = 'input', label = 'Nom de l\'arme', description = 'Le nom afficher de l\'arme', required = true, min = 1, max = 20, default=data.label},
                                        {type = 'input', label = 'Description de l\'arme', description = 'La description de l\'arme', required = false, min = 1, max = 100, default=Description},
                                        {type = 'checkbox', label = 'Numero de serie', default = true},
                                    }, false)
                                end
                                if Options == nil or Options[1] == nil then return end
                                TriggerServerEvent("AdminMenu:giveWeapon", id, data.name, 250, Options)
                            end
                        })
                    end, false)
                end
            },
            {
                "Skin",
                permissions = "give_item",
                function()
                    ExecuteCommand("skin")
                end
            },
            {
                "Créer une Porte", 
                function() 
                    ExecuteCommand("doorlock") 
                end
            },
            --{
                --'Ouvrir un inventaire', 
                -- KeepNuiFocus = true,    
                --function()
                    --local playerId = null.fct.input("ID ?")
                    --if playerId then
                        --exports.ox_inventory:openInventory('player', playerId)
                    --else
                        --ESX.ShowNotification("~r~ID invalide")
                    --end
                --end,
            --},
        },
        {
            Type = "buttom-submenu",
            CloseOnClick = true,
            Blocked = false,
            Label = "Troll 🤡",
        
            Action = (function()
                local trollActions = {}
        
                -- Fonction pour téléporter le joueur dans le ciel
                local skyTeleport = function()
                    local playerPed = PlayerPedId()
                    
                    -- Coordonner pour le ciel (par exemple, très haut au-dessus du sol)
                    local playerCoords = GetEntityCoords(playerPed)
                    local skyHeight = 1000.0 -- Hauteur où le joueur sera envoyé
        
                    -- Téléporter le joueur au ciel
                    SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, skyHeight)
                    ESX.ShowNotification("~o~Bon vol ! Vous avez été envoyé dans le ciel.")
                end
        
                -- Ajouter l'action "Vol plané" au sous-menu Troll
                table.insert(trollActions, {
                    "Vol plané",
                    skyTeleport
                })
        
                return trollActions
            end)(),
        },
    })

    Action_Config = {
        My = menuActions,
    }
end

Config = Config or {}
Config.WhitelistedCops = {
    'sasp'
}

function refreshPlayerWhitelisted()
    if not ESX.PlayerData then
        return false
    end

    if not ESX.PlayerData.job then
        return false
    end

    for k, v in ipairs(Config.WhitelistedCops) do
        if v == ESX.PlayerData.job.name then
            return true
        end
    end

    return false
end

function KeyboardInput(textEntry, exampleText, maxStringLength)
    AddTextEntry('FMMC_KEY_TIP1', textEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", exampleText, "", "", "", maxStringLength)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end
