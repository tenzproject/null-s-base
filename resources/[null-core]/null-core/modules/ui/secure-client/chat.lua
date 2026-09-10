local chatInputActive = false
local chatInputActivating = false
local chatHidden = true
local chatCanOpen = true
local chatLoaded = false

RegisterNetEvent('chatMessage')
AddEventHandler('chatMessage', function(author, color, text)
    local args = { text }
    
    if author ~= "" then
        table.insert(args, 1, author)
    end
    
    SendNUIMessage({
        action = 'chatAddMessage',
        data = {
            message = {
                color = color,
                multiline = true,
                args = args
            }
        }
    })
end)

RegisterNetEvent('chat:addMessage')
AddEventHandler('chat:addMessage', function(message)
    SendNUIMessage({
        action = 'chatAddMessage',
        data = {
            message = message
        }
    })
end)

RegisterNetEvent('chat:addSuggestions')
AddEventHandler('chat:addSuggestions', function(suggestions)
    for i = 1, #suggestions, 1 do
        SendNUIMessage({
            action = 'chatAddSuggestion',
            data = {
                suggestion = suggestions[i]
            }
        })
    end
end)

RegisterNetEvent('chat:addSuggestion')
AddEventHandler('chat:addSuggestion', function(name, help, params)
    SendNUIMessage({
        action = 'chatAddSuggestion',
        data = {
            suggestion = {
                name = name,
                help = help,
                params = params or nil
            }
        }
    })
end)

RegisterNetEvent('chat:removeSuggestion')
AddEventHandler('chat:removeSuggestion', function(name)
    SendNUIMessage({
        action = 'chatRemoveSuggestion',
        data = {
            name = name
        }
    })
end)

RegisterNetEvent('chat:clear')
AddEventHandler('chat:clear', function()
    SendNUIMessage({
        action = 'chatClear',
        data = {}
    })
end)

RegisterNUICallback('chatResult', function(data, cb)
    null.DebugPrint("chatResult : " .. json.encode(data))
    chatInputActive = false
    SetNuiFocus(false)
    
    Wait(50)
    
    if not data.canceled and data.message then
        local id = PlayerId()
        local playerName = GetPlayerName(id)
        local r, g, b = 0, 0, 255
        
        if data.message:sub(1, 1) == '/' then
            TriggerServerEvent('_chat:messageEntered', playerName, data.message)
            ExecuteCommand(data.message:sub(2))
            null.DebugPrint("Commande executée : " .. data.message:sub(2))
        else
            TriggerServerEvent('Null:_chat:messageEntered', playerName, {r, g, b}, data.message)
        end
    end
    
    cb('ok')
end)

local nbrCall = 0
function DisableChat(bool)
    if bool then
        nbrCall += 1
        chatCanOpen = false
    elseif nbrCall <= 1 then
        chatCanOpen = true
        nbrCall = 0
    elseif nbrCall > 1 then
        nbrCall -= 1
    end
end

function refreshCommands()
    local registeredCommands = GetRegisteredCommands()
    local suggestions = {}
    
    for i = 1, #registeredCommands, 1 do
        if IsAceAllowed(('command.%s'):format(registeredCommands[i].name)) then
            table.insert(suggestions, {
                name = '/' .. registeredCommands[i].name,
                help = ''
            })
        end
    end
    
    TriggerEvent('chat:addSuggestions', suggestions)
end

AddEventHandler('onClientResourceStart', function(resName)
    Citizen.Wait(500)
    refreshCommands()
end)

AddEventHandler('onClientResourceStop', function(resName)
    Citizen.Wait(500)
    refreshCommands()
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    SetTextChatEnabled(false)
    SetNuiFocus(false)
    
    while true do
        Citizen.Wait(0)

        if chatInputActive and IsPauseMenuActive() then
            chatInputActive = false
            chatInputActivating = false
            SetNuiFocus(false)
            
            SendNUIMessage({
                action = 'chatClose',
                data = {}
            })
        end

        if not chatInputActive then
            if IsControlPressed(0, 245) and chatCanOpen then -- T key
                chatInputActive = true
                chatInputActivating = true
                
                SendNUIMessage({
                    action = 'chatOpen',
                    data = {}
                })
            end
        end
        
        if chatInputActivating then 
            if not IsControlPressed(0, 245) then
                SetNuiFocus(true)
                chatInputActivating = false
            end
        end
        
        local shouldBeHidden = IsScreenFadedOut()
        
        if (shouldBeHidden and not chatHidden) or (not shouldBeHidden and chatHidden) then
            chatHidden = shouldBeHidden
            
            SendNUIMessage({
                action = 'chatScreenStateChange',
                data = {
                    shouldHide = shouldBeHidden
                }
            })
        end
    end
end))

exports('inChat', function()
    return chatInputActive
end)

exports('setChatCanOpen', function(bool)
    chatCanOpen = bool

    if chatInputActive then
        chatInputActive = false
        chatInputActivating = false
        SetNuiFocus(false)
            
        SendNUIMessage({
            action = 'chatClose',
            data = {}
        })
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    refreshCommands()
    null.InitPrint("Chat Module Loaded successfully")
end)

Citizen.CreateThread(function()
    Wait(5000)
	TriggerEvent('chat:addSuggestion', '/jail', 'Jail un joueur (Staff)', {
	  {name="Id Unique", help="Id Unique du joueur a jail"},
	  {name="Temps", help="Temps du jail (Minutes)"},
	  {name="Raison", help="Raison du jail"},
	})
	TriggerEvent('chat:addSuggestion', '/ban', 'Ban un joueur (Staff)', {
	  {name="Id Unique", help="Id Unique du joueur a ban"},
	  {name="Temps", help="Temps du ban (Jours)"},
	  {name="Raison", help="Raison du ban"},
	})
	--[[TriggerEvent('chat:addSuggestion', '/jailoffline', "Jail un joueur hors ligne (Staff)", {
		{name="idunique", help="IdUnique du joueur a jail"},
		{name="Temps", help="Temps du jail"}, 
		{name="Raison", help="Raison du jail"},
	})]]
	TriggerEvent('chat:addSuggestion', '/adminprops', 'Admin Props (Staff)', {})
	TriggerEvent('chat:addSuggestion', '/giveata', 'Mettre une limite physique a un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
		{name="Temps", help="Temps en minutes de la limite physique"},
	})
	TriggerEvent('chat:addSuggestion', '/removeata', 'Retirer une limite physique a un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/skin', 'skin un joueur (ou sois) (Staff)', {
		{name="Id temporaire", help="Id temporaire du joueur a skin"},
	})
	TriggerEvent('chat:addSuggestion', '/unjail', 'Unjail un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur a unjail"},
	})
	TriggerEvent('chat:addSuggestion', '/getid', 'Récuperer `l\'id temporaire d\'un joueur grace a sont id unique  (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/revive', 'Revive un joueur mort (Staff)', {
		{name="Id Unique", help="Id Unique du joueur a revive"},
	})
	TriggerEvent('chat:addSuggestion', '/wipe', 'wipe un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur a wipe"},
	})
	TriggerEvent('chat:addSuggestion', '/register', 'register un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur a register"},
	})
	TriggerEvent('chat:addSuggestion', '/goto', 'Se téléporter sur un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/tpa', 'Se téléporter sur un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/back', 'téléporter le joueur a ca derniere position (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/tppc', 'Téléporter un joueur/groupe au Parking Central (Staff)', {
		{name="Id Unique/Groupe illégal", help="Id Unique du joueur / setjob d'un groupe illégal"},
	})
	TriggerEvent('chat:addSuggestion', '/tpcoords', 'Se téléporter sur des coordonnées (Staff)', {
		{name="X", help="position en X"},
		{name="Y", help="position en Y"},
		{name="Z", help="position en Z"},
	})
	TriggerEvent('chat:addSuggestion', '/msgstaff', 'Envoyer un message a un joueur (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
		{name="Message", help="Message a envoyer"},
	})
	TriggerEvent('chat:addSuggestion', '/closemsgstaff', 'Empeche le joueur a vous repondre (Staff)', {
		{name="Id Unique", help="Id Unique du joueur"},
	})
	TriggerEvent('chat:addSuggestion', '/rs', 'Repondre au message d\'un staff', {
		{name="Message", help="Message a envoyer"},
	})
	TriggerEvent('chat:addSuggestion', '/bring', 'téléporter un joueur/groupe sur soi (Staff)', {
		{name="Id Unique/Groupe illégal", help="Id Unique du joueur / setjob d'un groupe illégal"},
	})
	TriggerEvent('chat:addSuggestion', '/gotomain', 'Vous déplace dans l\'instance principale du serveur (Staff)', {})

	TriggerEvent('chat:addSuggestion', '/report', 'Effectuer un report (faire une demande au Staff)', {
		{name="Raison", help="Raison de votre report (Veuillez ne pas mettre une raison trop longue)"},
	})
    
	TriggerEvent('chat:addSuggestion', '/reglement', 'Permet de voir le réglement du serveur. (Attention, il se peut qu\'il ne soit pas toujours à jour, veuillez toujours vous informez sur le discord)', {})

    TriggerEvent('chat:addSuggestion', '/hudedit', 'Permet de modifier l\'affichage de vos UI (HUD)', {})
    TriggerEvent('chat:addSuggestion', '/boutique', 'Permet d\'ouvrir la boutique de '..ESX.Config("serverName"), {})

    TriggerEvent('chat:addSuggestion', '/animations', 'Permet d\'ouvrir le menu Animation', {})

end)