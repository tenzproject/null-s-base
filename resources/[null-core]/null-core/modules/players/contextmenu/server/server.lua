function IsAllowed(src)
    return ESX.GetPlayerFromId(src).getGroup() ~= 'user'
end

RegisterServerEvent('contextmenu:NetworkOverrideClockTime')
AddEventHandler('contextmenu:NetworkOverrideClockTime', function(time)
    local src = source
    if IsAllowed(src) then
        TriggerClientEvent('contextmenu:NetworkOverrideClockTime_response', -1, time)
    end
end)

RegisterNetEvent("ContextMenu:Player:Notify", function(target, nl, msg)
    if target == -1 then return end
    if target == nil then return end
    if target == 0 then return end
    TriggerClientEvent("esx:showNotification",target, msg)
end)


RegisterServerEvent('contextmenu:SetWeatherType')
AddEventHandler('contextmenu:SetWeatherType', function(weather)
    local src = source
    if IsAllowed(src) then
        TriggerClientEvent('contextmenu:SetWeatherType_response', -1, weather)
    end
end) 

RegisterNetEvent("veh_actioncontext", function(action, netid)
    local src = source
    if IsAllowed(src) then
    TriggerClientEvent("veh_actioncontext_response", -1, action, netid)
    end
end)


Configf = {
    language = 'fr',
    color = { r = 230, g = 230, b = 230, a = 255 }, -- Text color
    font = 0, -- Text font
    time = 5000, -- Duration to display the text (in ms)
    scale = 0.5, -- Text scale
    dist = 250, -- Min. distance to draw 
}

Languages = {
    ['fr'] = {
        commandName = 'me',
        commandDescription = 'Affiche une action au dessus de votre tête.',
        commandSuggestion = {{ name = 'action', help = '"se gratte le nez" par exemple.'}},
        prefix = 'l\'individu '
    },
}
-- Pre-load the language
local lang = Languages[Configf.language]

local function sanitizeMeMessage(message)
    message = tostring(message or "")
    message = message:gsub("[%z\1-\31\127]", " ")
    message = message:gsub("<[^>]->", "")
    message = message:gsub("~.-~", "")
    message = message:gsub("%s+", " ")
    message = message:gsub("^%s+", ""):gsub("%s+$", "")

    if message == "" then
        return nil
    end

    return message:sub(1, 96)
end

-- @desc Legacy /me handler kept available for explicit internal calls only.
-- The active /me command is modules/players/me/server/main.lua.
local function onMeCommand(source, args)
    local message = sanitizeMeMessage(table.concat(args, " "))
    if message == nil then
        return
    end

    local text = "* " .. lang.prefix .. message .. " *"
    TriggerClientEvent('3dme:shareDisplay', -1, text, source)
end


ESX.RegisterServerCallback("GetPlayerData", function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    local data = {
        name = json.encode(xPlayer.getName()),
        identifier = json.encode(xPlayer.getIdentifier()),
        group = json.encode(xPlayer.getGroup()),
        job = json.encode(xPlayer.getJob()),
        money = json.encode(xPlayer.getAccount('cash').money),
        bank = json.encode(xPlayer.getAccount('bank').money),
        dirty = json.encode(xPlayer.getAccount('dirtycash').money),
        inventory = json.encode(xPlayer.getInventory()),
        weapons = json.encode(xPlayer.getLoadout()),

    }
    text = ""
    for k,v in pairs(data) do
        text = text .. k .. "  :  " .. v .. " \n "
    end
    cb(text)
end)

ESX.RegisterServerCallback("GetAllItem", function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    local data = {}
    MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
        for k,v in pairs(result) do
            table.insert(data, v)
        end
        cb(sorttalbe_item(data))
    end)
end)
local anim_server = {}

RegisterNetEvent("setAnimServer")
AddEventHandler("setAnimServer", function(anim)
    id = source
    anim_server[id] = anim
end)


ESX.RegisterServerCallback("animations:getAnimationsAsync", function(src, cb, id)
    if anim_server[id] ~= nil then
        cb(anim_server[id])
    else
        cb(nil)
    end
end)

    

    

function sorttalbe_item(trable)
    local sorted = {}
    for k, v in pairs(trable) do
        table.insert(sorted, v)
    end
    table.sort(sorted, function(a, b)
        return a.label < b.label
    end)
    return sorted
end


local handcuffedPlayers = {}

ESX.RegisterServerCallback('esx_menotte:isTargetHandcuffed', function(source, cb, targetId)
    if handcuffedPlayers[targetId] then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('esx_menotte:handcuff')
AddEventHandler('esx_menotte:handcuff', function(targetId)
    local _source = source
    handcuffedPlayers[targetId] = true

    TriggerClientEvent('esx_menotte:handcuffAnimation', targetId)
end)

RegisterServerEvent('esx_menotte:uncuff')
AddEventHandler('esx_menotte:uncuff', function(targetId)
    local _source = source
    handcuffedPlayers[targetId] = nil

    TriggerClientEvent('esx_menotte:uncuffAnimation', targetId)
end)

RegisterServerEvent('items:useItem')
AddEventHandler('items:useItem', function(itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    --if xPlayer then
        --local item = exports.ox_inventory:GetItem(source, itemName)
        --if item and item.count > 0 then
            --exports.ox_inventory:RemoveItem(source, itemName, 1)
        --end
    --end
end)

RegisterServerEvent('items:addItem')
AddEventHandler('items:addItem', function(itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    --if xPlayer then
        --exports.ox_inventory:AddItem(source, itemName, 1)
    --end
end)
