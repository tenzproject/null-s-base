local playerInfoLoaded = false
local lastMoney, lastDirtyMoney = -1, -1
local lastFirstName, lastLastName = "", ""
 
AddEventHandler('esx:playerLoaded', function(xPlayer)
    playerInfoLoaded = true
    Citizen.Wait(2000)
    SendPlayerInfo()
end)

function SendPlayerInfo()
    if ESX == nil or ESX.PlayerLoaded == false then return end
    -- NOTE: do NOT gate on the global `DisplayHud` here. Global HUD hide/show
    -- is already handled React-side through the `hud-hide` NUI action which
    -- toggles the HUD container's `hudVisible` state. Checking DisplayHud here
    -- would block the initial `playerInfo` payload until DisplayHud is flipped
    -- to true by the spawn flow — leaving PlayerInfo permanently invisible if
    -- that flip is delayed or missed.

    local xPlayer = ESX.PlayerData
    if not xPlayer or not xPlayer.firstname then return end

    local firstName = xPlayer.firstname or ""
    local lastName = xPlayer.lastname or ""
    local uniqueId = xPlayer.idunique
    local tempId = tostring(GetPlayerServerId(PlayerId()))

    local age = 0
    if xPlayer.dateofbirth and xPlayer.dateofbirth ~= "" then
        local d, m, y = string.match(xPlayer.dateofbirth, "(%d+)/(%d+)/(%d+)")
        if d and m and y then
            local now = os.date("*t")
            age = now.year - tonumber(y)
            if now.month < tonumber(m) or (now.month == tonumber(m) and now.day < tonumber(d)) then
                age = age - 1
            end
            if age < 0 then age = 0 end
        end
    end
    local money = 0
    local dirtyMoney = 0

    if xPlayer.accounts then
        for _, account in ipairs(xPlayer.accounts) do
            if account.name == "cash" then
                money = account.money
            elseif account.name == "dirtycash" then
                dirtyMoney = account.money
            end
        end
    end

    local jobLabel = "Citoyen"
    local jobGrade = ""
    if xPlayer.job and xPlayer.job.name and xPlayer.job.name ~= "unemployed" then
        jobLabel = xPlayer.job.label or xPlayer.job.name
        if xPlayer.job.grade_label and xPlayer.job.grade_label ~= "" then
            jobGrade = xPlayer.job.grade_label
        end
    end

    local illegalLabel = ""
    local illegalGrade = ""
    if xPlayer.job2 and xPlayer.job2.name and xPlayer.job2.name ~= "unemployed" and xPlayer.job2.name ~= "unemployed2" then
        illegalLabel = xPlayer.job2.label or xPlayer.job2.name
        if xPlayer.job2.grade_label and xPlayer.job2.grade_label ~= "" then
            illegalGrade = xPlayer.job2.grade_label
        end
    end

    local playerCount = 0
    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            playerCount = playerCount + 1
        end
    end

    SendNUIMessage({
        action = 'playerInfo',
        firstName = firstName,
        lastName = lastName,
        age = age,
        uniqueId = uniqueId,
        tempId = tempId,
        money = money,
        dirtyMoney = dirtyMoney,
        job = jobLabel,
        jobGrade = jobGrade,
        illegalGroup = illegalLabel,
        illegalGrade = illegalGrade,
        playerCount = playerCount
    })
end

-- Update loop
CreateThread(function()
    while true do
        if ESX ~= nil and ESX.PlayerLoaded == true then
            SendPlayerInfo()
        end
        Wait(2000)
    end
end)

-- Listen for account changes
RegisterNetEvent('esx:setAccountMoney', function(account)
    Citizen.Wait(100)
    SendPlayerInfo()
end)

function HidePlayerInfo()
    SendNUIMessage({
        action = 'hide'
    })
end

null.InitPrint("Player Info HUD Loaded successfully 2")
