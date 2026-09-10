-- @desc Shared config file
-- @author Elio
-- @version 2.0

-- Global configuration
Configf = {
    language = 'fr',
    color = { r = 230, g = 230, b = 230, a = 255 }, -- Text color
    font = 0, -- Text font
    time = 5000, -- Duration to display the text (in ms)
    scale = 0.5, -- Text scale
    dist = 250, -- Min. distance to draw 
}

-- Languages available
Languages = {
    ['en'] = {
        commandName = 'me',
        commandDescription = 'Display an action above your head.',
        commandSuggestion = {{ name = 'action', help = '"scratch his nose" for example.'}},
        prefix = 'the person '
    },
    ['fr'] = {
        commandName = 'me',
        commandDescription = 'Affiche une action au dessus de votre tête.',
        commandSuggestion = {{ name = 'action', help = '"se gratte le nez" par exemple.'}},
        prefix = 'l\'individu '
    },
    ['dk'] = {
        commandName = 'me',
        commandDescription = 'Viser en handling over hovedet.',
        commandSuggestion = {{ name = 'Handling', help = '"Tager en smøg op ad lommen" for eksempel.'}},
        prefix = 'Personen '
    },
}

-- @desc Client-side /me handling
-- @author Elio
-- @version 3.0

local c = Configf -- Pre-load the config
local lang = Languages[Configf.language] -- Pre-load the language
local peds = {}

-- Localization
local GetGameTimer = GetGameTimer

local function sanitize3dMeText(text)
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

local function addTextComponents(text)
    local maxLength = 48

    for i = 1, #text, maxLength do
        AddTextComponentString(text:sub(i, i + maxLength - 1))
    end
end

-- @desc Draw text in 3d
-- @param coords world coordinates to where you want to draw the text
-- @param text the text to display
local function draw3dText(coords, text)
    text = sanitize3dMeText(text)
    if text == nil then return end

    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    
    -- Experimental math to scale the text down
    local scale = 200 / (GetGameplayCamFov() * dist)

    -- Format the text
    SetTextColour(c.color.r, c.color.g, c.color.b, c.color.a)
    SetTextScale(0.0, c.scale * scale)
    SetTextFont(c.font)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    -- Diplay the text
    BeginTextCommandDisplayText("STRING")
    addTextComponents(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()

end

-- @desc Display the text above the head of a ped
-- @param ped the target ped
-- @param text the text to display
local function displayText(ped, text)
    text = sanitize3dMeText(text)
    if text == nil or ped == nil or ped == 0 or not DoesEntityExist(ped) then return end

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local targetPos = GetEntityCoords(ped)
    local dist = #(playerPos - targetPos)
    local los = HasEntityClearLosToEntity(playerPed, ped, 17)

    if dist <= c.dist and los then
        local exists = peds[ped] ~= nil

        peds[ped] = {
            time = GetGameTimer() + c.time,
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

-- @desc Trigger the display of teh text for a player
-- @param text text to display
-- @param target the target server id
local function onShareDisplay(text, target)
    local player = GetPlayerFromServerId(target)
    if player ~= -1 and ((player ~= PlayerId() and player > 0) or target == GetPlayerServerId(PlayerId())) then
        local ped = GetPlayerPed(player)
        displayText(ped, text)
    end
end

-- Register the event
RegisterNetEvent('3dme:shareDisplay', onShareDisplay)

-- Add the chat suggestion
TriggerEvent('chat:addSuggestion', '/' .. lang.commandName, lang.commandDescription, lang.commandSuggestion)



function OnCustom(vehicle)
    -- Activer le modkit pour les modifications
    SetVehicleModKit(vehicle, 0)
    
    -- Suspension (type 15, niveau max)
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1)
    
    -- Moteur (type 11, niveau max)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1)
    
    -- Freins (type 12, niveau max)
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1)
    
    -- Transmission (type 13, niveau max)
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1)
    
    -- Turbo (type 18, activé)
    ToggleVehicleMod(vehicle, 18, true)
end


function GetPlayerIdFromPed(id)
    local toreturn = 0
    for i = 0,900000 do
        if NetworkIsPlayerActive(i) then
            if GetPlayerPed(i) == id then
                toreturn = GetPlayerServerId(i)
                break
            end
        end
    end
    return toreturn 
end


function IsModelAtm(model, entity)
    atmlist = {
        {
            prop = 'prop_atm_01'
        },
        {
            prop = 'prop_atm_02'
        },
        {
            prop = 'prop_atm_03'
        },
        {
            prop = 'prop_fleeca_atm'
        }
    }
    for i = 1, #atmlist do
        if model == GetHashKey(atmlist[i].prop) then
            dist = #(GetEntityCoords(entity) - GetEntityCoords(PlayerPedId()))
            if dist > 1.5 then
                return true
            else
                return false
            end
        end
    end
    return true
end

--------- changement place opti ---------

RegisterKeyMapping("conducteur", "Place Conducteur", "keyboard", "1") --Changer NUMPAD pour n'importe quelle autre touche si nécessaire
RegisterKeyMapping("passager", "Place Passager", "keyboard", "2")
RegisterKeyMapping("arrieregauche", "Place Arrière Gauche", "keyboard", "3")
RegisterKeyMapping("arrieredroite", "Place Arrière Droite", "keyboard", "4")

RegisterCommand("conducteur", function() 
    local plyPed = PlayerPedId()
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local CarSpeed = GetEntitySpeed(plyVehicle) * 3.6 -- Conversion en km/h
    if IsPedSittingInAnyVehicle(plyPed) then
        if CarSpeed <= 200.0 then -- Vitesse max pour pouvoir changer de siège en km/h
            SetPedIntoVehicle(plyPed, plyVehicle, -1)
        end
    end
end)

RegisterCommand("passager", function()
    local plyPed = PlayerPedId()
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local CarSpeed = GetEntitySpeed(plyVehicle) * 3.6
    if IsPedSittingInAnyVehicle(plyPed) then
        if CarSpeed <= 200.0 then
            SetPedIntoVehicle(plyPed, plyVehicle, 0)
        end
    end
end)

RegisterCommand("arrieregauche", function() 
    local plyPed = PlayerPedId()
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local CarSpeed = GetEntitySpeed(plyVehicle) * 3.6 
    if IsPedSittingInAnyVehicle(plyPed) then
        if CarSpeed <= 200.0 then -- Vitesse en km/h
            SetPedIntoVehicle(plyPed, plyVehicle, 1)
        end
    end
end)

RegisterCommand("arrieredroite", function() 
    local plyPed = PlayerPedId()
    local plyVehicle = GetVehiclePedIsIn(plyPed, false)
    local CarSpeed = GetEntitySpeed(plyVehicle) * 3.6
    if IsPedSittingInAnyVehicle(plyPed) then
        if CarSpeed <= 200.0 then
            SetPedIntoVehicle(plyPed, plyVehicle, 2)
        end
    end
end)


------------- changement place auto -------------

local disableShuffle = true
function disableSeatShuffle(flag)
	disableShuffle = flag
end

Citizen.CreateThread((function()
	while true do
		Citizen.Wait(0)
		if IsPedInAnyVehicle(GetPlayerPed(-1), false) and disableShuffle then
			if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) == GetPlayerPed(-1) then
				if GetIsTaskActive(GetPlayerPed(-1), 165) then
					SetPedIntoVehicle(GetPlayerPed(-1), GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
				end
			end
		end
	end
end))

function godMod(enable)
    print("godMod appelée avec :", enable)
    local playerPed = PlayerPedId()
    SetEntityInvincible(playerPed, enable)

    if enable then
        ESX.ShowNotification("Godmode activé")
    else
        ESX.ShowNotification("Godmode désactivé")
    end
end




function showNames(enable)
    for _, player in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(player)
        local playerId = GetPlayerServerId(player)

        if enable then
            DisplayPlayerNameTagsOnBlips(true)
            print("Affichage activé pour :", playerId)
        else
            DisplayPlayerNameTagsOnBlips(false)
            print("Affichage désactivé pour :", playerId)
        end
    end
end

function EnumerateObjects()
    return coroutine.wrap(function()
        local handle, object = FindFirstObject()
        if not handle or handle == -1 then
            return
        end
        local success
        repeat
            coroutine.yield(object)
            success, object = FindNextObject(handle)
        until not success
        EndFindObject(handle)
    end)
end










