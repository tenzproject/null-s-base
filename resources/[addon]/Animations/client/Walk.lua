local canChange = true
local unable_message = "You are unable to change your walking style right now."

function WalkMenuStart(name)
    if not canChange then
        EmoteChatMessage(unable_message)
        return
    end
    if Config.Animations.PersistentWalk then SetResourceKvp("walkstyle", name) end
    RequestWalking(name)
    SetPedMovementClipset(PlayerPedId(), name, 0.2)
    RemoveAnimSet(name)
end

function ResetWalk()
    if not canChange then
        EmoteChatMessage(unable_message)
        return
    end
    ResetPedMovementClipset(PlayerPedId())
end

function WalksOnCommand()
    local WalksCommand = ""
    for a in pairsByKeys(RP.Walks) do
        WalksCommand = WalksCommand .. "" .. string.lower(a) .. ", "
    end
    EmoteChatMessage(WalksCommand)
    EmoteChatMessage("To reset do /walk reset")
end

function WalkCommandStart(name)
    if not canChange then
        EmoteChatMessage(unable_message)
        return
    end
    name = firstToUpper(string.lower(name))

    if name == "Reset" then
        ResetPedMovementClipset(PlayerPedId())
        DeleteResourceKvp("walkstyle")
        return
    end

    if tableHasKey(RP.Walks, name) then
        local name2 = table.unpack(RP.Walks[name])
        WalkMenuStart(name2)
    elseif name == "Injured" then
        WalkMenuStart("move_m@injured")
    else
        EmoteChatMessage("'" .. name .. "' is not a valid walk")
    end
end

--[[Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, Config.Animations.OpenMenuKey) then
            RageUI.Visible(RMenu:Get('walkmenu', 'main'), not RageUI.Visible(RMenu:Get('walkmenu', 'main')))
        end
    end
end)

RMenu.Add('walkmenu', 'main', RageUI.CreateMenu("Walking Styles", "Choose your walking style"))
RMenu:Get('walkmenu', 'main').Closed = function() end

RageUI.CreateWhile(1.0, true, function()
    if RageUI.Visible(RMenu:Get('walkmenu', 'main')) then
        RageUI.DrawContent({ header = true, glare = false, instructionalText = true }, function()
            for walkName, walkData in pairs(RP.Walks) do
                RageUI.Button(walkName, nil, {}, true, function(Hovered, Active, Selected)
                    if Selected then
                        WalkMenuStart(walkData[1])
                    end
                end)
            end
            RageUI.Button("Reset Walk", nil, {}, true, function(Hovered, Active, Selected)
                if Selected then
                    ResetWalk()
                end
            end)
        end)
    end
end)

if Config.Animations.WalkingStylesEnabled and Config.Animations.PersistentWalk then
    AddEventHandler('playerSpawned', function()
        local kvp = GetResourceKvpString("walkstyle")
        if kvp ~= nil then
            WalkMenuStart(kvp)
        end
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Wait(5000)
        local kvp = GetResourceKvpString("walkstyle")
        if kvp ~= nil then
            WalkMenuStart(kvp)
        end
    end)

    RegisterNetEvent('esx:playerLoaded', function()
        Wait(5000)
        local kvp = GetResourceKvpString("walkstyle")
        if kvp ~= nil then
            WalkMenuStart(kvp)
        end
    end)
end

if Config.Animations.WalkingStylesEnabled then
    RegisterCommand('walks', function() WalksOnCommand() end, false)
    RegisterCommand('walk', function(_, args, _) WalkCommandStart(tostring(args[1])) end, false)
    TriggerEvent('chat:addSuggestion', '/walk', 'Set your walkingstyle.', { { name = "style", help = "/walks for a list of valid styles" } })
    TriggerEvent('chat:addSuggestion', '/walks', 'List available walking styles.')
end
]]
function toggleWalkstyle(bool, message)
    canChange = bool
    if message then
        unable_message = message
    end
end

exports('toggleWalkstyle', toggleWalkstyle)