--RegisterNetEvent('es:activateMoney')
--AddEventHandler('es:activateMoney', function(money)
--      ESX.PlayerData.money = money
--end)

--RegisterNetEvent('esx:setAccountMoney')
--AddEventHandler('esx:setAccountMoney', function(account)
--    for i=1, #ESX.PlayerData.accounts, 1 do
--        if ESX.PlayerData.accounts[i].name == account.name then
--            ESX.PlayerData.accounts[i] = account
--            break
--        end
--    end
--end)

local isHandcuffed = false

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

LastFoundEmote = ""



RegisterNetEvent("copyanim:contextmenu")
AddEventHandler("copyanim:contextmenu", function(id)
    ESX.TriggerServerCallback('animations:getAnimationsAsync', function(anim)
        if anim then
            ExecuteCommand("e "..anim)
            return
        end
        ESX.ShowNotification("Aucune animation trouvée")
        return
    end, id)
end)

local cachedUID = {}

function _Player()
    local black_money
    for i = 1, #ESX.PlayerData.accounts, 1 do
        if ESX.PlayerData.accounts[i].name == 'black_money' then
            black_money = ESX.PlayerData.accounts[i].money
        end
    end

    local srvid = GetPlayerIdFromPed(LastEntityHit)
    local currentIdUnique = nil
    if cachedUID[srvid] then 
        currentIdUnique = cachedUID[srvid]
    else
        local canTrigger = exports["null-core"]:actionCooldown('canTriggerCallBack_idunique_'..srvid, 2000)
        if canTrigger then
            ESX.TriggerServerCallback("null:GetIDUnique2", function(result) 
                cachedUID[srvid] = result
                currentIdUnique = result
            end, srvid)
        else
            currentIdUnique = "Inconnu"
        end
    end

    Action_Config = {
        Player = {
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Label = "Imiter l'animation",
                OnClick = function()
                    TriggerEvent("copyanim:contextmenu", GetPlayerIdFromPed(LastEntityHit))
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Label = "ID : "..GetPlayerIdFromPed(LastEntityHit) or "Inconnu",
                OnClick = function()
                    exports["null-core"]:copy(GetPlayerIdFromPed(LastEntityHit))
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Label = ("UID : %s"):format(currentIdUnique),
                OnClick = function()
                    if cachedUID[srvid] then 
                        exports["null-core"]:copy(cachedUID[srvid])
                    end
                end,
            },

            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Blocked = false,
                Label = "Utiliser un item",
            
                Action = (function()
                    local actions = {}
                    local itemList = {"hand_cuffs", "cle_menottes"}
                    
                    local itemActions = {
                        hand_cuffs = function()
                            local playerPed = PlayerPedId()
                            if DoesEntityExist(LastEntityHit) and IsEntityAPed(LastEntityHit) then
                                local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(LastEntityHit))
                                local targetId = NetworkGetPlayerIndexFromPed(LastEntityHit)
                        
                                if distance <= 3.0 then
                                    if targetId ~= -1 then
                                        local serverId = GetPlayerServerId(targetId)
                                        
                                        ESX.TriggerServerCallback('esx_menotte:isTargetHandcuffed', function(isTargetHandcuffed)
                                            if not isTargetHandcuffed then
                                                TriggerServerEvent('esx_menotte:handcuff', serverId)
                                                TriggerServerEvent('items:useItem', 'hand_cuffs')
                                            else
                                                ESX.ShowNotification("~r~Le joueur est déjà menotté.")
                                            end
                                        end, serverId)
                                    end
                                else
                                    ESX.ShowNotification("~r~Vous êtes trop loin du joueur.")
                                end
                            else
                                ESX.ShowNotification("~r~Aucune cible valide.")
                            end
                        end,                                    
                        cle_menottes = function()
                            if isHandcuffed then
                                TriggerServerEvent('esx_menotte:uncuff', GetPlayerServerId(PlayerId()))
                                TriggerServerEvent('items:addItem', 'hand_cuffs')
                            else
                                ESX.ShowNotification("~r~Le joueur n'est pas menotté")
                            end
                        end
                    }
                    
                    --for _, itemName in ipairs(itemList) do
                        --local count = exports.ox_inventory:GetItemCount(itemName)
                        --if count > 0 then
                            --local itemData = exports.ox_inventory:Items()[itemName]
                            --table.insert(actions, {
                                --string.format("%s (x%d)", itemData.label, count),
                                --itemActions[itemName] or function()
                                    --TriggerServerEvent('items:useItem', itemName)
                                --end
                            --})
                        --end
                    --end
            
                    return actions
                end)(),
            },

            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Label = "Action ",
                Action = {
                    {
                        "Otage",
                        function()
                            ExecuteCommand('otage')
                        end
                    },
                    {
                        "Porter sur l'epaule",
                        function()
                            ExecuteCommand('porter')
                        end
                    },
                    --[[{
                        "Porter sur le dos",
                        function()
                            ExecuteCommand("piggyback")
                        end
                    },]]
				},	
            },
            --[[{
                Type = "buttom",
                Blocked = false,
                CloseOnClick = true,
                Label = "Fouiller",
                OnClick = function()
                    local PlayerId = GetPlayerIdFromPed(LastEntityHit)
                    if PlayerId then
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            --exports.ox_inventory:openInventory('player', PlayerId)
                            ExecuteCommand('me Fouille la personne')
                        else
                            ESX.ShowNotification("~r~joueur trop loin")
                        end
                    else
                        ESX.ShowNotification("~r~ID invalide")
                    end
                end
            },]]
            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Blocked = false,
                Label = "Animations ",
                
                Action = {
                    { 'Coup de poing pris', function() ExecuteCommand('nearby punched') end },
                    { 'Frérot 2', function() ExecuteCommand('nearby bro2') end },
                    { 'Gros bisous', function() ExecuteCommand('nearby kiss2') end },
                    { 'Donner 2', function() ExecuteCommand('nearby give2') end },
                    { 'Otage braquer', function() ExecuteCommand('nearby give2') end },
                    { 'Coup de tête mettre', function() ExecuteCommand('nearby ') end },
                    { 'Coup de tête pris', function() end },
                    { 'Mettre une gifle', function() ExecuteCommand('nearby slap') end },
                    { 'Mettre une gifle 2', function() ExecuteCommand('nearby slap2') end },
                    { 'Prendre une gifle 2', function() ExecuteCommand('nearby slaped2') end },
                    { 'Coup de poing mettre', function() ExecuteCommand('nearby punch') end },
                    { 'Poingnée de main', function() ExecuteCommand('nearby punch') end },
                    { 'Baseball lancer', function() ExecuteCommand('nearby baseball') end },
                    { 'Câlin2', function() ExecuteCommand('nearby hug2') end },
                    { 'Prendre une gifle', function() ExecuteCommand('nearby sleped') end },
                    { 'Baseball tirer ', function() ExecuteCommand('nearby baseballthrow') end },
                    { 'Donner', function() ExecuteCommand('nearby give') end },           
                },    
            },

            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Blocked = false,
                Label = "Report (" .. (GetPlayerIdFromPed(LastEntityHit) or "Inconnu") .. ")",
                
                Action = {
                    { 'Report HRP', function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(targetServerId)
                        ExecuteCommand("report "..targetServerId.." (ID Temporaire) fais du HRP") 
                    end },
                    { 'Report FreeKill', function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(targetServerId)
                        ExecuteCommand("report "..targetServerId.." (ID Temporaire) fais du FreeKill") 
                    end },
                    { 'Report Troll', function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(targetServerId)
                        ExecuteCommand("report "..targetServerId.." (ID Temporaire) fais du Troll") 
                    end },
                },
            },
            {
                Type = "buttom",
                IsAllowed = true,
                Blocked = false,
                CloseOnClick = true,
                Label = "Suggérer une animation",
                OnClick = function()
                    Citizen.Wait(500)
                    local animMsg = null.fct.input("Animation à suggérer")
                    if animMsg and animMsg ~= '' then
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(PlayerId())
                        TriggerServerEvent('ContextMenu:Player:Notify', targetServerId, nil, targetPseudoPlayerPed.." vous suggère de faire l'animation ~b~"..animMsg)
                    else
                        Notification(nil, "Vous devez écrire quelque chose.", 3500)
                    end
                end,
            },
            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Blocked = false,
                Label = "Suggérer un niveau de voix",
                
                Action = {
                    { "Chuchoté", function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(PlayerId())
                        TriggerServerEvent('ContextMenu:Player:Notify', targetServerId, nil, targetPseudoPlayerPed.." vous suggère de ~y~chuchoter") end },
                    { "Parler", function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(PlayerId())
                        TriggerServerEvent('ContextMenu:Player:Notify', targetServerId, nil, targetPseudoPlayerPed.." vous suggère de ~b~parler") end },
                    { "Crier", function() 
                        local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                        local targetPseudoPlayerPed = GetPlayerName(PlayerId())
                        TriggerServerEvent('ContextMenu:Player:Notify', targetServerId, nil, targetPseudoPlayerPed.." vous suggère de ~r~crier") end }
                }
            },
            {
                Type = "buttom",
                IsAllowed = true,
                Blocked = false,
                CloseOnClick = true,
                Label = "Suggérer de sauter",
                OnClick = function()
                    local targetServerId = GetPlayerIdFromPed(LastEntityHit)
                    local targetPseudoPlayerPed = GetPlayerName(PlayerId())
                    TriggerServerEvent('ContextMenu:Player:Notify', targetServerId, nil, targetPseudoPlayerPed.." vous suggère de ~g~sauter")
                end,
            },
            
            {
                IsRestricted = true,
                
                Type = "buttom-submenu",
                Label = "Outils de debug",
                IsRestricted = true,
                CloseOnClick = false,
                Action = {
                    {
                        ("Modèle : %s"):format(
                            (function()
                            local model = GetEntityModel(LastEntityHit)
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
                            print("Le modèle du joueur : " .. modelName)
                        end,
                    },
                    {
                        ("Position : %.2f, %.2f, %.2f"):format(GetEntityCoords(LastEntityHit).x, GetEntityCoords(LastEntityHit).y, GetEntityCoords(LastEntityHit).z),
                        function()
                            local playerposition = GetEntityCoords(LastEntityHit)
                            print(("Position du joueur : %s"):format(playerposition))
                        end,
                    },
                },
            },
            {
                IsRestricted = true,
                Type = "buttom-submenu",
                Label = "Administration",
                IsRestricted = true,
                CloseOnClick = false,
                Action = {
                    --{
                    --    ("nom du joueur : %s"):format(getplayername(lastentityhit)),
                    --    function()
                    --    end,
                    --},
                    {
                        "Prendre l'aparence",
                        function()
                            model = GetEntityModel(LastEntityHit)
                            SetPlayerModel(PlayerId(), model)
                            SetPedDefaultComponentVariation(PlayerPedId())
                        end,
                    },
                    {
                        'Téleporter sur moi',
                        function()
                            local targetId = GetPlayerIdFromPed(LastEntityHit)
                            if targetId and targetId ~= -1 then
                                print("Tentative de téléportation vers le joueur avec ID: " .. targetId)
                                ExecuteCommand('bring ' .. cachedUID[targetId])
                            else
                                print("ID de joueur invalide pour LastEntityHit: " .. LastEntityHit)
                            end
                        end
                    },                                                                                              
                    {
                        'Retourner', 
                        function()
                            local targetId = GetPlayerIdFromPed(LastEntityHit)
                            if targetId then
                                ExecuteCommand('back ' .. cachedUID[targetId])
                            else
                                print("ID de joueur invalide.")
                            end
                        end
                    },
                    {
                        "Heal",
                        function()
                            local targetId = GetPlayerIdFromPed(LastEntityHit)
                            ExecuteCommand("heal "..targetId)
                        end,
                    },
                    {
                        "Revive ",
                        function()
                            local targetId = GetPlayerIdFromPed(LastEntityHit)
                            ExecuteCommand("revive "..cachedUID[targetId])
                        end
                    },
                    {
                        "Skin",
                        function()
                            ExecuteCommand(("skin %s"):format(GetPlayerIdFromPed(LastEntityHit)))
                        end,
                    },
                    {
                        "Donner a manger",
                        function()
                            TriggerEvent("esx_status:set", "hunger", 1000000)
                        end,
                    },
                    {
                        "Donner a boire",
                        function()
                            TriggerEvent("esx_status:set", "thirst", 1000000)
                        end,
                    },
                    {
                        'Donner un item',
                        permissions = "give_item",
                        function()
                            local id = GetPlayerIdFromPed(LastEntityHit)
                            if id == nil then return end
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
                        'Donner une arme',
                        permissions = "give_weapon",
                        function()
                            local id = GetPlayerIdFromPed(LastEntityHit)
                            if id == nil then return end
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
                        "Gilet pare balle",
                        function()
                            SetPedArmour(lastentityhit, 100)
                        end,
                    },
                    {
                        "Tuer",
                        function()
                            SetEntityHealth(lastentityhit, 0)
                        end,
                    },
                    {
                        'Kick', 
                        KeepNuiFocus = true,
                        function()
                            local id = GetPlayerIdFromPed(LastEntityHit)
                            local reason = null.fct.input("Entrez une raison")
                            if not reason then return end
                            ExecuteCommand('kick ' .. id .. " " .. reason)
                        end
                    }, 
                    {
                        'Ban', 
                        KeepNuiFocus = true,
                        function()
                            local id = GetPlayerIdFromPed(LastEntityHit)
                            local temps = null.fct.input("Entrez une durée (en heure)")
                            Wait(250)
                            local reason = null.fct.input("Entrez une raison")
                            if not reason or not temps then return end
                            ExecuteCommand('ban ' .. cachedUID[id] .. " " .. temps .. " " .. reason)
                        end
                    },

                },
                {
                    mod = "mod", -- SI VOUS METTEZ "mod" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                    admin = "admin", -- SI VOUS METTEZ "admin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                    superadmin = "superadmin", -- SI VOUS METTEZ "superadmin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                    _dev = "_dev", -- SI VOUS METTEZ "_dev" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                    owner = "owner", -- SI VOUS METTEZ "owner" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
    
                    Type = "buttom-submenu",
                    CloseOnClick = false,
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
            }
        }
    }
end