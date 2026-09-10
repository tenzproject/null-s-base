local function GetNumberOfAccounts(citizenid)
    local numberOfAccounts = 0
    for _, account in pairs(Accounts) do
        if account.citizenid == citizenid then
            numberOfAccounts = numberOfAccounts + 1
        end
    end
    return numberOfAccounts
end

-- Exported Functions NOT TOCH

local function CreatePlayerAccount(playerId, accountName, accountBalance, accountUsers)
    local xPlayer, citizenid = ESX.GetPlayerFromId(playerId), ESX.GetPlayerFromId(playerId).identifier
    if not xPlayer or not citizenid then return false end

    if Accounts[accountName] then
        return false
    end

    Accounts[accountName] = {
        citizenid = citizenid,
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'shared',
        users = accountUsers
    }

    local insertSuccess = MySQL.insert.await('INSERT INTO bank_accounts (citizenid, account_name, account_balance, account_type, users) VALUES (?, ?, ?, ?, ?)', { citizenid, accountName, accountBalance, 'shared', accountUsers })
    return insertSuccess
end
exports('CreatePlayerAccount', CreatePlayerAccount)

local function CreateJobAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'job'
    }
    local insertSuccess = MySQL.insert.await('INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)', { accountName, accountBalance, 'job' })
    return insertSuccess
end
exports('CreateJobAccount', CreateJobAccount)

local function CreateGangAccount(accountName, accountBalance)
    Accounts[accountName] = {
        account_name = accountName,
        account_balance = accountBalance,
        account_type = 'gang'
    }
    local insertSuccess = MySQL.insert.await('INSERT INTO bank_accounts (account_name, account_balance, account_type) VALUES (?, ?, ?)', { accountName, accountBalance, 'gang' })
    return insertSuccess
end
exports('CreateGangAccount', CreateGangAccount)

local function CreateBankStatement(playerId, account, amount, reason, statementType, accountType)
    local xPlayer, citizenid = ESX.GetPlayerFromId(playerId), ESX.GetPlayerFromId(playerId).identifier
    if not xPlayer or not citizenid then return false end

    local newStatement = {
        citizenid = citizenid,
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = statementType
    }
    if accountType == 'player' or accountType == 'shared' then
        if accountType == 'player' then account = 'checking' end
        if not Statements[citizenid] then Statements[citizenid] = {} end
        if not Statements[citizenid][account] then Statements[citizenid][account] = {} end
        Statements[citizenid][account][#Statements[citizenid][account] + 1] = newStatement
    else
        if not Statements[account] then Statements[account] = {} end
        Statements[account][#Statements[account] + 1] = newStatement
    end

    local insertSuccess = MySQL.insert.await('INSERT INTO bank_statements (citizenid, account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?, ?)', { citizenid, account, amount, reason, statementType })
    if not insertSuccess then return false end
    return true
end
exports('CreateBankStatement', CreateBankStatement)

local function AddMoney(accountName, amount, reason)
    if not reason then reason = 'External Deposit' end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'deposit'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance + amount
        if not Statements[accountName] then Statements[accountName] = {} end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        MySQL.insert.await('INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)', { accountName, amount, reason, 'deposit' })
        local updateSuccess = MySQL.update.await('UPDATE bank_accounts SET account_balance = account_balance + ? WHERE account_name = ?', { amount, accountName })
        return updateSuccess
    end
    return false
end

exports('AddMoney', AddMoney)
exports('AddGangMoney', AddMoney)
local function hasKey(identifier, cid, house)
    if houseowneridentifier[house] and houseownercid[house] then
        if houseowneridentifier[house] == identifier and houseownercid[house] == cid then
            return true
        else
            if housekeyholders[house] then
                for i = 1, #housekeyholders[house], 1 do
                    if housekeyholders[house][i] == cid then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function RemoveMoney(accountName, amount, reason)
    if not reason then reason = 'External Withdrawal' end
    local newStatement = {
        amount = amount,
        reason = reason,
        date = os.time() * 1000,
        statement_type = 'withdraw'
    }
    if Accounts[accountName] then
        local accountToUpdate = Accounts[accountName]
        accountToUpdate.account_balance = accountToUpdate.account_balance - amount
        if not Statements[accountName] then Statements[accountName] = {} end
        Statements[accountName][#Statements[accountName] + 1] = newStatement
        MySQL.insert.await('INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)', { accountName, amount, reason, 'withdraw' })
        local updateSuccess = MySQL.update.await('UPDATE bank_accounts SET account_balance = account_balance - ? WHERE account_name = ?', { amount, accountName })
        return updateSuccess
    end
    return false
end
exports('RemoveMoney', RemoveMoney)
exports('RemoveGangMoney', RemoveMoney)

local function GetAccount(accountName)
    if Accounts[accountName] then
        return Accounts[accountName]
    end
    return nil
end
exports('GetAccount', GetAccount)
exports('GetGangAccount', GetAccount)

local function GetAccountBalance(accountName)
    local account = GetAccount(accountName)
    return account and account.account_balance or 0
end
exports('GetAccountBalance', GetAccountBalance)

-- Callbacks
ESX.RegisterServerCallback('BankATM:server:openBank', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(false) end
    
    local playerAccounts = {
        ['personal'] = {
            accountid = 'personal',
            type = 'personal',
            name = xPlayer.getName(),
            bankbalance = xPlayer.getAccount('bank').money,
            account_type = 'personal',
            sort_code = Config.SortCode,
            account_number = Config.AccountNumber,
            is_frozen = false,
            transactions = {}
        }
    }
    
    cb(playerAccounts)
end)

ESX.RegisterServerCallback('BankATM:server:openATM', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(false) end
    
    local hasCard = false
    local bankCards = xPlayer.getInventoryItem('bank_card')
    if bankCards and bankCards.count > 0 then
        hasCard = true
    end
    
    local playerAccounts = {
        ['personal'] = {
            accountid = 'personal',
            type = 'personal',
            name = xPlayer.getName(),
            bankbalance = xPlayer.getAccount('bank').money,
            account_type = 'personal',
            sort_code = Config.SortCode,
            account_number = Config.AccountNumber,
            is_frozen = false,
            transactions = {}
        }
    }
    
    if hasCard then
        cb(playerAccounts)
    else
        cb(false)
    end
end)

RegisterServerEvent('BankATM:server:doTransaction')
AddEventHandler('BankATM:server:doTransaction', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    if data.type == "withdraw" then
        if xPlayer.getAccount('bank').money >= data.amount then
            xPlayer.removeAccountMoney('bank', data.amount)
            xPlayer.addAccountMoney("cash", data.amount)
            TriggerClientEvent('BankATM:client:updateMoney', src, xPlayer.getAccount('bank').money, xPlayer.getAccount('cash').money)
            CreateBankStatement(src, 'personal', data.amount, 'ATM Withdrawal', 'withdraw', 'personal')
        end
    elseif data.type == "deposit" then
        if xPlayer.getAccount('bank').money >= data.amount then
            xPlayer.removeAccountMoney("cash", data.amount)
            xPlayer.addAccountMoney('bank', data.amount)
            TriggerClientEvent('BankATM:client:updateMoney', src, xPlayer.getAccount('bank').money, xPlayer.getAccount("cash").money)
            CreateBankStatement(src, 'personal', data.amount, 'ATM Deposit', 'deposit', 'personal')
        end
    end
end)


RegisterNetEvent("BankATM:server:doCommand")
AddEventHandler("BankATM:server:doCommand", function(data)
    local src = source
    if data.type == "withdraw" then
        withdraw_money(src, data.money)
    elseif data.type == "deposit" then
        deposit_money(src, data.money)
    end
end)

function get_money(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local bank = xPlayer.getAccount('bank').money
    return bank
end

function deposit_money(src,count)
    local xPlayer = ESX.GetPlayerFromId(src)
    local money = xPlayer.getAccount('bank').money
    if money < count then
        TriggerClientEvent("BankATM:client:notify",src,config.msg_deposit1)
        return
    end
 
    xPlayer.removeMoney(count)
    xPlayer.addAccountMoney('bank',count)
    TriggerClientEvent("BankATM:client:update_nui",src,{type="putmoney"})
    Wait(2000)
    TriggerClientEvent("BankATM:client:notify",src,config.msg_deposit2[1].. count .." "..config.msg_deposit2[2])
end

function withdraw_money(src,money)
    local xPlayer = ESX.GetPlayerFromId(src)
    local bank = xPlayer.getAccount('bank').money
    if bank < money then
        TriggerClientEvent("BankATM:client:notify",src,config.msg_withdraw1)
        return
    end
	

    xPlayer.addMoney(money)
    xPlayer.removeAccountMoney('bank',money)
    TriggerClientEvent("BankATM:client:update_nui",src,{type="pickupmoney"})
    Wait(4000)
    TriggerClientEvent("BankATM:client:notify",src,config.msg_withdraw2[1].. money .." "..config.msg_withdraw2[2])

end