local originalRegisterNetEvent = RegisterNetEvent
local playerEventCount = {}
local MAX_EVENTS_PER_SECOND = Config.Protection.Events.AntiSpam.MaxEventsPerSecond
local ENABLE_ANTISPAM = Config.Protection.Events.AntiSpam.Enable
local CHARACTERS = {[1] = 'A',[2] = 'B',[3] = 'C',[4] = 'D',[5] = 'E',[6] = 'F',[7] = 'G',[8] = 'H',[9] = 'I',[10] = 'J',[11] = 'K',[12] = 'L',[13] = 'M',[14] = 'N',[15] = 'O',[16] = 'P',[17] = 'Q',[18] = 'R',[19] = 'S',[20] = 'T',[21] = 'U',[22] = 'V',[23] = 'W',[24] = 'X',[25] = 'Y',[26] = 'Z'}
local SPECIALCHARACTERS = {[1] = "/", [2] = "*", [3] = "-", [4] = "+",[5] = "*",[6] = "ù",[7] = "%"}

local TOKEN = {}

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(1000)
        playerEventCount = {}
    end
end))

function RegisterNetEvent(eventName, handler)
    if handler then
        if ENABLE_ANTISPAM then
            originalRegisterNetEvent(eventName, function(...)
                local src = source
                playerEventCount[src] = (playerEventCount[src] or 0) + 1
                if playerEventCount[src] > MAX_EVENTS_PER_SECOND then
                    print(("^1[ANTISPAM] Kick %s - trop d'events (%s/%s)"):format(src, playerEventCount[src], MAX_EVENTS_PER_SECOND))
                    DropPlayer(src, "Anti-spam: trop de requêtes")
                    return
                end
                
                handler(...)
            end)
        else
            originalRegisterNetEvent(eventName, handler)
        end
    else
        originalRegisterNetEvent(eventName)
    end
end

RegisterServerEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xply)
    local xPlayer = xply
    local src = source
    local numbers1 = math.random (9500, 15000)
    local numbers2 = math.random(7850, 27000)
    local numbers3 = math.random(500, 1000)
    local numbers4 = math.random(50000, 100000)
    local CharSpecialRandom1 = math.random(1,7)
    local CharSpecialRandom2 = math.random(1,7)
    local lettersrandom1 = math.random(1,26)
    TOKEN[src] = {}
    TOKEN[src].token = SPECIALCHARACTERS[CharSpecialRandom1]..''..numbers4..''..numbers1..''..numbers4..''..SPECIALCHARACTERS[CharSpecialRandom2]..''..CHARACTERS[lettersrandom1]..'TOKEN!!!!4/*-+'..numbers4..''..numbers3..''..numbers2
    TriggerClientEvent('null:protection:token:retrevie', src, TOKEN[src].token)
    local tokennn = TOKEN[src].token
    --print("[^4CONNECTION^0] Connection de : "..xPlayer.getName().." (U"..xply.idunique.." T"..src..") [Token : "..tokennn.."]") 
end)

function VerifyToken(source, tokenReceive, eventName, onAccepted, onRefused)
    if TOKEN[source].token == tokenReceive then
        onAccepted();
    else
        onRefused();
        local xPlayer = ESX.GetPlayerFromId(source)
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche token (0)")
    end
end