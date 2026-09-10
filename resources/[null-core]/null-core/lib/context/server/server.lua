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

-- @desc Handle /me command
local function onMeCommand(source, args)
    local text = "* " .. lang.prefix .. table.concat(args, " ") .. " *"
    TriggerClientEvent('3dme:shareDisplay', -1, text, source)
end

-- Register the command
RegisterCommand(lang.commandName, onMeCommand)


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

