if not IsDuplicityVersion() then return end

ESX.RegisterServerCallback('null:driveschool:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}, 0, 0) end

    local licenses = {}
    for i = 1, #Config.DriveSchool.License do
        local lic = Config.DriveSchool.License[i]
        licenses[i] = {
            id = lic.id,
            label = lic.label,
            description = lic.description or '',
            icon = lic.icon or 'car',
            pricing = lic.pricing,
            theory = false,
            practice = false,
        }
    end

    local cash = xPlayer.getAccount('money') and xPlayer.getAccount('money').money or 0
    local bank = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0

    MySQL.Async.fetchAll("SELECT * FROM user_licenses WHERE owner = @identifier", {
        ['@identifier'] = xPlayer.identifier,
    }, function(result)
        for _, row in ipairs(result or {}) do
            for i = 1, #licenses do
                if row.type == licenses[i].id then
                    licenses[i].theory = true
                    licenses[i].practice = true
                elseif row.type == licenses[i].id .. "dmv" then
                    licenses[i].theory = true
                    licenses[i].practice = false
                end
            end
        end
        cb(licenses, cash, bank)
    end)
end)

RegisterNetEvent('null:driveschool:giveLicense', function(license)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    AddLicense(src, license, function()
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        
        if license == "identity_card" then
            xPlayer.addInventoryItem(license, 1, {
                creation = os.time(),
                firstname = xPlayer.firstname,
                lastname = xPlayer.lastname,
                birthday = xPlayer.dateofbirth,
                sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
            })
        elseif license == "drive" then
            GetLicenses(xPlayer.source, function(licenses)
                xPlayer.addInventoryItem(license, 1, {
                    creation = os.time(),
                    firstname = xPlayer.firstname,
                    lastname = xPlayer.lastname,
                    birthday = xPlayer.dateofbirth,
                    sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
                    licenses = licenses or {}, 
                })
            end)
        elseif license == "weapon" then
            GetLicenses(xPlayer.source, function(licenses)
                xPlayer.addInventoryItem(license, 1, {
                    creation = os.time(),
                    firstname = xPlayer.firstname,
                    lastname = xPlayer.lastname,
                    birthday = xPlayer.dateofbirth,
                    sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
                    licenses = licenses or {}, 
                })
            end)
        else
            xPlayer.addInventoryItem(license, 1, {
                creation = os.time(),
                firstname = xPlayer.firstname,
                lastname = xPlayer.lastname,
                birthday = xPlayer.dateofbirth,
                sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
            })
        end

        local licenses = {}
        for i = 1, #Config.DriveSchool.License do
            local lic = Config.DriveSchool.License[i]
            licenses[i] = {
                id = lic.id,
                label = lic.label,
                description = lic.description or '',
                icon = lic.icon or 'car',
                pricing = lic.pricing,
                theory = false,
                practice = false,
            }
        end
        
        MySQL.Async.fetchAll("SELECT * FROM user_licenses WHERE owner = @identifier", {
            ['@identifier'] = xPlayer.identifier,
        }, function(result)
            for _, row in ipairs(result or {}) do
                for i = 1, #licenses do
                    if row.type == licenses[i].id then
                        licenses[i].theory = true
                        licenses[i].practice = true
                    elseif row.type == licenses[i].id .. "dmv" then
                        licenses[i].theory = true
                        licenses[i].practice = false
                    end
                end
            end
            TriggerClientEvent('null:driveschool:updateData', src, licenses)
        end)
    end)
end)

RegisterNetEvent('null:driveschool:removeMoney', function(account, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    
    if account == 'money' then
        xPlayer.removeAccountMoney('money', amount)
    elseif account == 'bank' then
        xPlayer.removeAccountMoney('bank', amount, {title = 'Auto-école', description = 'Passage de permis', category = 'purchase'})
    end
end)
