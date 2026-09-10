-- Intercepter les commandes depuis F8 et ExecuteCommand()
RegisterServerEvent('__cfx_internal:commandFallback')
AddEventHandler('__cfx_internal:commandFallback', function(command)
    local src = source
    local name = GetPlayerName(src)
    TriggerEvent('chatMessage', src, name, '/' .. command)

    if not WasEventCanceled() then
        -- TriggerClientEvent('chatMessage', -1, name, {255, 255, 255}, '/' .. command)
    end

    CancelEvent()
end)

RegisterServerEvent('_chat:messageEntered')
AddEventHandler('_chat:messageEntered', function(author, message)
    local src = source
    
    if not message or not author then
        return
    end
    
    -- Trigger chatMessage event for ESX command handler
    TriggerEvent('chatMessage', src, author, message)
end)

RegisterServerEvent('Null:_chat:messageEntered')
AddEventHandler('Null:_chat:messageEntered', function(author, color, message)
    local source = source
    --TriggerClientEvent('chatMessage', -1, author, color, message)
end)

if devmode then
    RegisterCommand('say', function(source, args, rawCommand)
        local msg = table.concat(args, ' ')
        local name = source == 0 and 'Console' or GetPlayerName(source)
        
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div class="chat-message"><span class="chat-author">{0}</span>: {1}</div>',
            args = { name, msg }
        })
    end, false)
end

AddEventHandler('chatMessage', function(source, author, message)
    if message:sub(1, 1) == '/' then
        return
    end
end)