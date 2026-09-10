local initialized = false

local function Initialize()
    if initialized then return end
    
    while not ESX or not ESX.PlayerLoaded do
        Wait(100)
    end
    
    while not ESX.PlayerData or not ESX.PlayerData.idunique do
        Wait(100)
    end
    
    initialized = true
    
    local serverName = ESX.Config and ESX.Config("serverName") or "Null"
    local serverColor = ESX.Config and ESX.Config("serverColor") or "~p~"
    local discordApi = ESX.Config and ESX.Config("discordAPI") or ""
    local discordLink = ESX.Config and ESX.Config("serverDiscord2") or ""

    SetupPauseMenu(serverName, serverColor)
    
    SetupDiscordRichPresence(discordApi, serverName, discordLink)
end

function SetupPauseMenu(serverName, serverColor)
    if not Config._core.Discord.CustomPauseMenu then return end
    local playerId = PlayerId()
    local serverId = GetPlayerServerId(playerId)
    local playerName = GetPlayerName(playerId)
    local idUnique = ESX.PlayerData.idunique or "N/A"
    
    local header = string.format(
        "%s%s~s~ | %sVotre ID : %d ~s~| %sPseudo : %s",
        serverColor, string.upper(serverName),
        serverColor, serverId,
        serverColor, playerName
    )
    AddTextEntry('FE_THDR_GTAO', header)

    AddTextEntry('PM_PANE_CFX', serverColor .. serverName .. '~s~')
    
    for key, text in pairs(Config._core.Discord.PauseMenuTexts) do
        if text and key ~= 'FE_THDR_GTAO' and key ~= 'PM_PANE_CFX' then
            AddTextEntry(key, serverColor .. text)
        end
    end
end

function SetupDiscordRichPresence(appId, serverName, discordLink)
    if not appId or appId == "" then return end
    if not Config._core.Discord.Enabled then return end

    local playerId = PlayerId()
    local playerName = GetPlayerName(playerId)
    local idUnique = ESX.PlayerData.idunique or "0"
    
    SetDiscordAppId(appId)
    SetDiscordRichPresenceAsset("logo")
    SetDiscordRichPresenceAssetSmall("logo")
    SetDiscordRichPresenceAssetSmallText(serverName)
    
    local presenceText = string.format("[%s] %s", idUnique, playerName)
    SetRichPresence(presenceText)
    
    if discordLink and discordLink ~= "" then
        SetDiscordRichPresenceAction(0, "Discord", discordLink)
    end
end

function UpdateDiscordPresence(text)
    SetRichPresence(text)
end

exports('UpdateDiscordPresence', UpdateDiscordPresence)

function UpdatePauseMenuHeader(customText)
    if customText then
        AddTextEntry('FE_THDR_GTAO', customText)
    else
        local serverName = ESX.Config and ESX.Config("serverName") or "Null"
        local serverColor = ESX.Config and ESX.Config("serverColor") or "~p~"
        SetupPauseMenu(serverName, serverColor)
    end
end

exports('UpdatePauseMenuHeader', UpdatePauseMenuHeader)

CreateThread(function()
    Initialize()
end)

null.InitPrint('^2Discord & Pause Menu module loaded^7')
