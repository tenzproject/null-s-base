ScriptServer = {}
ScriptServer.Functions = {}

function ScriptServer.Functions:GetPlayerInformations(playerId, identifier)
    local playerData = {}
    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] then
            playerData = {
                firstname = result[1].firstname,
                lastname = result[1].lastname,
                sex = result[1].sex,
                dateOfBirth = result[1].dateofbirth
            }
            if result[1].sex == "m" then
                playerData.sex = "Homme"
            elseif result[1].sex == "f" then
                playerData.sex = "Femme"
            end
            for k, v in pairs(json.decode(result[1].accounts)) do
                if v.name == 'bank' then
                    playerData.bank = v.money
                elseif v.name == 'dirtycash' then
                    playerData.blackMoney = v.money
                elseif v.name == 'cash' then
                    playerData.money = v.money
                end
            end
            MySQL.Async.fetchAll('SELECT * FROM vips WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(result2)
                local havevip = false
                local expired = false
                local expirationmsg = ""
                if result2[1] then
                    if result2[1].vip == 1 and tonumber(result2[1].expiration) > os.time() then
                        havevip = true
                        expired = false
                        local tempsrestant = (((tonumber(result2[1].expiration)) - os.time())/60)
                        local day        = (tempsrestant / 60) / 24
                        local hrs        = (day - math.floor(day)) * 24
                        local minutes    = (hrs - math.floor(hrs)) * 60
                        local txtday     = math.floor(day)
                        local txthrs     = math.floor(hrs)

                        expirationmsg = txtday.." jours et "..ESX.Math.Round(hrs).." heures."
                    else
                        expired = true
                        havevip = false
                    end
                else
                    expired = false
                    havevip = false
                end

                playerData.vip = havevip
                playerData.expirationmsg = expirationmsg
                playerData.isexpired = expired
                TriggerClientEvent('brx_spawn:OnPlayerConnect', playerId, playerData)
            end)
        end
    end)
end

function ScriptServer.Functions:GetFristConnection(identifier, cb)
    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', { ['@identifier'] = identifier }, function(result)
        cb(result and result[1] ~= nil and false or true)
    end)
end

RegisterNetEvent('brx_spawn:OnPlayerConnect', function(data)
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    local identifier = ExtractIdentifiers(playerId)

    --if not ScriptServer.Functions:GetFristConnection(identifier) then
        ScriptServer.Functions:GetPlayerInformations(playerId, identifier.license)
    --end
end)

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            --identifiers.license = "license:"..id:gsub("license2:", "")..""
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    -- if identifiers.license ~= "" then
    --     if string.find(identifiers.license, "license2") then
    --         identifiers.license = id:gsub("license2:", "")
    --     end
    -- end

    return identifiers
end

RegisterNetEvent("null:esx:enter", function(bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.setEnter(bool)
    if bool then
        null.fct.instance.Set(xPlayer.source, xPlayer.source, "CharSelector")
    else
        null.fct.instance.Set(xPlayer.source, 0, "CharSelector")
    end
end)

-- AddEventHandler("playerConnecting", function()
--     local playerId = source
--     local identifier = GetPlayerIdentifiers(playerId)[1]
    
--     if not ScriptServer.Functions:GetFristConnection(identifier) then
--         ScriptServer.Functions:GetPlayerInformations(playerId, identifier)
--     end
-- end)