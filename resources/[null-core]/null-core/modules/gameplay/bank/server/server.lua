-- ============================================================
-- BANK SYSTEM — Enhanced Server
-- ============================================================

Bank = {
    Accounts = {},   -- [identifier] = { bankid, identifier, history[], credits[], pendingTransfers[] }
    IBANMap = {},    -- [bankid] = identifier
}

-- ============================================================
-- UTILITIES
-- ============================================================

function GetDate()
    local d = os.date('*t')
    return string.format('%02d.%02d.%d - %02d:%02d:%02d', d.day, d.month, d.year, d.hour, d.min, d.sec)
end

function GetTimestamp()
    return os.time()
end

function GenerateTransactionId()
    return tostring(os.time()) .. '_' .. tostring(math.random(100000, 999999))
end

function GenerateIBAN()
    return 'FR' .. string.format('%02d', math.random(10, 99)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999))
end

function GenerateCardNumber()
    return string.format('%04d', math.random(1000, 9999)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999)) .. ' ' ..
           string.format('%04d', math.random(1000, 9999))
end

function Bank.GetAccount(identifier)
    return identifier and Bank.Accounts[identifier] or nil
end

function Bank.CreateAccount(identifier)
    if not identifier then return nil end
    if Bank.Accounts[identifier] then return Bank.Accounts[identifier] end

    local bankid = GenerateIBAN()
    while Bank.IBANMap[bankid] do
        bankid = GenerateIBAN()
        Wait(0)
    end

    local account = {
        bankid = bankid,
        cardNumber = GenerateCardNumber(),
        identifier = identifier,
        history = {{
            id = GenerateTransactionId(),
            amount = 0,
            title = 'Création du Compte',
            description = 'Ouverture d\'un compte Bancaire.',
            category = 'creation',
            date = GetDate(),
            timestamp = GetTimestamp(),
        }},
        credits = {},
        pendingTransfers = {},
        createdAt = GetTimestamp(),
        pin = nil,
        hasCard = false,
    }

    Bank.Accounts[identifier] = account
    Bank.IBANMap[bankid] = identifier

    MySQL.Async.execute([[
        INSERT INTO `vbank` (`identifier`, `history`, `bankid`)
        VALUES (@identifier, @history, @bankid)
    ]], {
        ['@identifier'] = identifier,
        ['@history'] = json.encode(account.history),
        ['@bankid'] = account.bankid,
    })

    return account
end

local function QuantityOk(number)
    number = tonumber(number)
    if type(number) == "number" then
        number = ESX.Math.Round(number)
        if number > 0 then return true, number end
    end
    return false, number
end

-- ============================================================
-- SQL MIGRATION
-- ============================================================
Citizen.CreateThread(function()

    local function EnsureColumn(tableName, columnName, definition)
        MySQL.Async.fetchAll(
            "SHOW COLUMNS FROM `" .. tableName .. "` LIKE @column",
            {
                ['@column'] = columnName
            },
            function(result)
                if not result or #result == 0 then
                    MySQL.Async.execute(
                        "ALTER TABLE `" .. tableName .. "` ADD COLUMN `" .. columnName .. "` " .. definition,
                        {},
                        function()
                            print(("[vBank] Colonne %s.%s créée"):format(tableName, columnName))
                        end
                    )
                end
            end
        )
    end

    EnsureColumn("vbank", "card_number", "VARCHAR(25) DEFAULT NULL")
    EnsureColumn("vbank", "credits", "TEXT DEFAULT NULL")
    EnsureColumn("vbank", "pending_transfers", "TEXT DEFAULT NULL")
    EnsureColumn("vbank", "created_at", "BIGINT DEFAULT 0")
    EnsureColumn("vbank", "pin", "VARCHAR(10) DEFAULT NULL")
    EnsureColumn("vbank", "has_card", "TINYINT(1) DEFAULT 0")

    Wait(2000)

    MySQL.Async.fetchAll("SELECT * FROM vbank", {}, function(result)
        for _, row in pairs(result or {}) do
            local ident = row.identifier

            local histRaw = {}
            local creditsRaw = {}
            local pendingRaw = {}

            if row.history and row.history ~= '' then
                histRaw = json.decode(row.history) or {}
            end

            if row.credits and row.credits ~= '' then
                creditsRaw = json.decode(row.credits) or {}
            end

            if row.pending_transfers and row.pending_transfers ~= '' then
                pendingRaw = json.decode(row.pending_transfers) or {}
            end

            -- Migration de l'ancien Virement
            if #pendingRaw == 0
                and row.Virement
                and row.Virement ~= ''
                and row.Virement ~= '[]'
            then
                local oldVir = json.decode(row.Virement)

                if oldVir then
                    for _, v in pairs(oldVir) do
                        table.insert(pendingRaw, {
                            id = v.id or GenerateTransactionId(),
                            amount = tonumber(v.amount) or 0,
                            description = v.Description or '',
                            fromIban = 'Inconnu',
                            date = v.Date or GetDate(),
                            timestamp = GetTimestamp()
                        })
                    end
                end
            end

            -- Conversion de l'ancien historique
            local histArray = {}

            for _, entry in pairs(histRaw) do
                local amountStr = tostring(entry.amount or 0)
                local cleanAmount = amountStr:gsub('~[^~]*~', '')
                local numAmount = tonumber(cleanAmount) or 0

                table.insert(histArray, {
                    id = entry.id or GenerateTransactionId(),
                    amount = numAmount,
                    rawAmount = entry.amount,
                    title = entry.Title or entry.title or '',
                    description = entry.Description or entry.description or '',
                    category = entry.category or entry.type or 'other',
                    date = entry.Date or entry.date or GetDate(),
                    timestamp = entry.timestamp or 0
                })
            end

            local cardNumber = row.card_number

            if not cardNumber or cardNumber == '' then
                cardNumber = GenerateCardNumber()
            end

            Bank.Accounts[ident] = {
                bankid = row.bankid,
                cardNumber = cardNumber,
                identifier = ident,
                history = histArray,
                credits = creditsRaw,
                pendingTransfers = pendingRaw,
                createdAt = tonumber(row.created_at) or 0,
                pin = row.pin,
                hasCard = tonumber(row.has_card) == 1
            }

            Bank.IBANMap[row.bankid] = ident

            if not row.card_number or row.card_number == '' then
                MySQL.Async.execute(
                    "UPDATE vbank SET card_number = @card WHERE identifier = @id",
                    {
                        ['@card'] = cardNumber,
                        ['@id'] = ident
                    }
                )
            end
        end
    end)
end)

-- ============================================================
-- TRANSACTION SYSTEM
-- ============================================================

function Bank.AddTransaction(src, info)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    local tx = {
        id = GenerateTransactionId(),
        amount = tonumber(info.amount) or 0,
        title = info.title or '',
        description = info.description or '',
        category = info.category or 'other',
        date = GetDate(),
        timestamp = GetTimestamp(),
    }
    table.insert(account.history, tx)

    -- Keep last 200 transactions
    if #account.history > 200 then
        table.remove(account.history, 1)
    end

    return tx
end

function Bank.AddTransactionOffline(identifier, info)
    local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if xPlayer then
        return Bank.AddTransaction(xPlayer.source, info)
    end
    local account = Bank.GetAccount(identifier)
    if not account then return end

    local tx = {
        id = GenerateTransactionId(),
        amount = tonumber(info.amount) or 0,
        title = info.title or '',
        description = info.description or '',
        category = info.category or 'other',
        date = GetDate(),
        timestamp = GetTimestamp(),
    }
    table.insert(account.history, tx)
    if #account.history > 200 then table.remove(account.history, 1) end

    Bank.SaveAccount(identifier)
    return tx
end

-- ============================================================
-- SAVE
-- ============================================================

function Bank.SaveAccount(identifier)
    local account = Bank.Accounts[identifier]
    if not account then return end
    MySQL.Async.execute('UPDATE vbank SET history = @history, credits = @credits, pending_transfers = @pending, pin = @pin, has_card = @hasCard WHERE identifier = @id', {
        ['@id'] = identifier,
        ['@history'] = json.encode(account.history),
        ['@credits'] = json.encode(account.credits),
        ['@pending'] = json.encode(account.pendingTransfers),
        ['@pin'] = account.pin,
        ['@hasCard'] = account.hasCard and 1 or 0,
    })
end

AddEventHandler('playerDropped', function(reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and Bank.Accounts[xPlayer.identifier] then
        Bank.SaveAccount(xPlayer.identifier)
    end
end)

-- ============================================================
-- BUILD DATA FOR UI
-- ============================================================

function Bank.BuildUIData(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then
        account = Bank.CreateAccount(xPlayer.identifier)
    end

    local cash = 0
    local bankMoney = 0
    for _, acc in pairs(xPlayer.getAccounts()) do
        if acc.name == eBank.Money.AccountName then cash = acc.money end
        if acc.name == eBank.Bank.AccountName then bankMoney = acc.money end
    end

    local playerName = xPlayer.firstname ~= nil and (xPlayer.firstname and xPlayer.lastname) or xPlayer.getName() or 'Inconnu'

    -- Sort history by timestamp descending for UI
    local sortedHistory = {}
    for _, h in ipairs(account.history) do
        table.insert(sortedHistory, h)
    end
    table.sort(sortedHistory, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

    -- Credit config
    local creditConfig = nil
    if eBank.Credit and eBank.Credit.Active then
        creditConfig = {
            maxAmount = eBank.Credit.MaxAmount,
            minAmount = eBank.Credit.MinAmount,
            interestRate = eBank.Credit.InterestRate,
            installments = eBank.Credit.Installments,
            maxActiveLoans = eBank.Credit.MaxActiveLoans,
        }
    end

    return {
        iban = account.bankid,
        cardNumber = account.cardNumber,
        playerName = playerName,
        cash = cash,
        bank = bankMoney,
        history = sortedHistory,
        credits = account.credits,
        pendingTransfers = account.pendingTransfers,
        creditConfig = creditConfig,
        categories = eBank.Categories or {},
        brand = (eBank.Brand and eBank.Brand.Enabled) and {
            id      = eBank.Brand.Id or 'bank',
            name    = eBank.Brand.Name or 'Banque',
            tagline = eBank.Brand.Tagline or '',
            logo    = eBank.Brand.Logo or '',
            bgColor = eBank.Brand.BgColor or '#1a1a1a',
            accent  = eBank.Brand.Accent or '#3b82f6',
        } or nil,
        hasCard = account.hasCard,
        hasPin = account.pin ~= nil,
        cardConfig = {
            price = eBank.CardConfig and eBank.CardConfig.price or 250,
            itemName = eBank.CardConfig and eBank.CardConfig.itemName or 'bank_card',
        },
    }
end

-- ============================================================
-- CLIENT INIT
-- ============================================================

ESX.RegisterServerCallback('null:bank:getData', function(source, cb)
    local bankData = Bank.BuildUIData(source)
    cb(bankData)
end)

RegisterNetEvent('Null:GetInformationsBank', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not Bank.GetAccount(xPlayer.identifier) then
        Bank.CreateAccount(xPlayer.identifier)
    end
    TriggerClientEvent('Null:ReceiveInformaionsBank', src, Bank.GetAccount(xPlayer.identifier))
end)

-- ============================================================
-- DEPOSIT / WITHDRAW
-- ============================================================

RegisterNetEvent('Null:ActionBank', function(actionType, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local isOk, amount = QuantityOk(amount)
    if not isOk then
        xPlayer.showNotification('Quantité invalide')
        return
    end

    if actionType == 'withdraw' then
        if xPlayer.getAccount(eBank.Bank.AccountName).money >= amount then
            xPlayer.removeAccountMoney(eBank.Bank.AccountName, amount)
            xPlayer.addAccountMoney(eBank.Money.AccountName, amount)
            if amount >= eBank.History.MinimumTransactionPrice then
                Bank.AddTransaction(xPlayer.source, {
                    amount = -amount,
                    title = 'Retrait',
                    description = 'Retrait en espèces',
                    category = 'withdraw',
                })
            end
        else
            xPlayer.showNotification('~r~Solde insuffisant')
        end
    elseif actionType == 'deposit' then
        if xPlayer.getAccount(eBank.Money.AccountName).money >= amount then
            xPlayer.removeAccountMoney(eBank.Money.AccountName, amount)
            xPlayer.addAccountMoney(eBank.Bank.AccountName, amount)
            if amount >= eBank.History.MinimumTransactionPrice then
                Bank.AddTransaction(xPlayer.source, {
                    amount = amount,
                    title = 'Dépôt',
                    description = 'Dépôt en espèces',
                    category = 'deposit',
                })
            end
        else
            xPlayer.showNotification('~r~Pas assez de liquide')
        end
    end
end)

-- ============================================================
-- TRANSFERS
-- ============================================================

RegisterNetEvent('Null:banque:sendVirement', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end

    local iban = data.IBAN or data.iban
    local montant = tonumber(data.MONTANT or data.amount)
    local raison = data.RAISON or data.reason or ''

    if not iban or not montant or montant <= 0 then
        xPlayer.showNotification("~r~Données invalides")
        return
    end

    if not Bank.IBANMap[iban] then
        xPlayer.showNotification("~r~L'IBAN renseigné n'existe pas.")
        return
    end

    local targetIdent = Bank.IBANMap[iban]
    if targetIdent == xPlayer.identifier then
        xPlayer.showNotification("~r~Vous ne pouvez pas vous envoyer d'argent.")
        return
    end

    if xPlayer.getAccount(eBank.Bank.AccountName).money < montant then
        xPlayer.showNotification("~r~Solde insuffisant.")
        return
    end

    local senderAccount = Bank.GetAccount(xPlayer.identifier)
    xPlayer.removeAccountMoney(eBank.Bank.AccountName, montant)

    -- Sender transaction
    Bank.AddTransaction(xPlayer.source, {
        amount = -montant,
        title = 'Virement envoyé',
        description = raison ~= '' and raison or ('Virement vers ' .. iban),
        category = 'transfer',
    })

    -- Try to credit target directly
    local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdent)
    if targetPlayer then
        targetPlayer.addAccountMoney(eBank.Bank.AccountName, montant)
        targetPlayer.showNotification('Vous avez reçu un virement de ~g~' .. montant .. '$')
        Bank.AddTransaction(targetPlayer.source, {
            amount = montant,
            title = 'Virement reçu',
            description = raison ~= '' and raison or ('Virement de ' .. (senderAccount and senderAccount.bankid or 'Inconnu')),
            category = 'transfer',
        })
    else
        -- Offline: add to pending transfers
        local targetAccount = Bank.GetAccount(targetIdent)
        if targetAccount then
            table.insert(targetAccount.pendingTransfers, {
                id = GenerateTransactionId(),
                amount = montant,
                description = raison,
                fromIban = senderAccount and senderAccount.bankid or 'Inconnu',
                date = GetDate(),
                timestamp = GetTimestamp(),
            })
            Bank.AddTransactionOffline(targetIdent, {
                amount = montant,
                title = 'Virement reçu',
                description = raison ~= '' and raison or ('Virement de ' .. (senderAccount and senderAccount.bankid or 'Inconnu')),
                category = 'transfer',
            })
        end
    end

    xPlayer.showNotification('Virement de ~g~' .. montant .. '$~s~ envoyé')
end)

-- Accept pending transfer
RegisterNetEvent('Null:RVirement', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    for i, transfer in ipairs(account.pendingTransfers) do
        if transfer.id == id then
            xPlayer.addAccountMoney(eBank.Bank.AccountName, transfer.amount)
            xPlayer.showNotification('Virement de ~g~' .. transfer.amount .. '$~s~ accepté')
            table.remove(account.pendingTransfers, i)
            return
        end
    end
end)

-- ============================================================
-- CARD / PIN
-- ============================================================

RegisterNetEvent('Null:bank:buyCard', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    local itemName = (eBank.CardConfig and eBank.CardConfig.itemName) or 'bank_card'
    local price = (eBank.CardConfig and eBank.CardConfig.price) or 250

    if account.hasCard then
        TriggerClientEvent('null:bank:cardResult', src, { success = false, message = 'Vous avez déjà une carte' })
        return
    end

    if xPlayer.getAccount(eBank.Bank.AccountName).money < price then
        TriggerClientEvent('null:bank:cardResult', src, { success = false, message = 'Solde insuffisant' })
        return
    end

    xPlayer.removeAccountMoney(eBank.Bank.AccountName, price)
    xPlayer.addInventoryItem(itemName, 1)
    account.hasCard = true
    Bank.SaveAccount(xPlayer.identifier)
    Bank.AddTransaction(src, {
        amount = -price,
        title = 'Achat carte bancaire',
        description = 'Carte ' .. itemName .. ' au tarif ' .. price .. '$',
        category = 'purchase',
    })
    TriggerClientEvent('null:bank:cardResult', src, { success = true })
end)

RegisterNetEvent('Null:bank:setPin', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    local pin = tostring(data.pin or '')
    if not pin:match('^%d%d%d%d$') then
        TriggerClientEvent('null:bank:pinResult', src, { success = false, message = 'Code invalide' })
        return
    end

    account.pin = pin
    Bank.SaveAccount(xPlayer.identifier)
    TriggerClientEvent('null:bank:pinResult', src, { success = true })
end)

-- ============================================================
-- ATM
-- ============================================================

function Bank.BuildATMData(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then
        account = Bank.CreateAccount(xPlayer.identifier)
    end

    local cash = 0
    local bankMoney = 0
    for _, acc in pairs(xPlayer.getAccounts()) do
        if acc.name == eBank.Money.AccountName then cash = acc.money end
        if acc.name == eBank.Bank.AccountName then bankMoney = acc.money end
    end

    local playerName = xPlayer.firstname ~= nil and (xPlayer.firstname and xPlayer.lastname) or xPlayer.getName() or 'Inconnu'

    -- Recent 6 transactions for ATM
    local recent = {}
    for i = #account.history, math.max(1, #account.history - 5), -1 do
        table.insert(recent, account.history[i])
    end

    -- Spending per month
    local now = os.time()
    local MONTH_LABELS = {'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'}
    local months = {}
    for i = 5, 0, -1 do
        local t = os.date('*t', now)
        local ts = os.time({year = t.year, month = t.month - i, day = 1, hour = 0})
        local d = os.date('*t', ts)
        table.insert(months, { label = MONTH_LABELS[d.month], total = 0 })
    end
    for _, tx in ipairs(account.history) do
        if tx.amount < 0 then
            local parts = tx.date and tx.date:match('(%d%d)%.(%d%d)%.(%d%d%d%d)') or {}
            local txMonth = tonumber(parts[2])
            local txYear = tonumber(parts[3])
            if txMonth and txYear then
                for j = 1, #months do
                    local t = os.date('*t', now)
                    local ts = os.time({year = t.year, month = t.month - (6 - j), day = 1, hour = 0})
                    local d = os.date('*t', ts)
                    if d.month == txMonth and d.year == txYear then
                        months[j].total = months[j].total + math.abs(tx.amount)
                        break
                    end
                end
            end
        end
    end

    return {
        iban = account.bankid,
        cardNumber = account.cardNumber,
        playerName = playerName,
        cash = cash,
        bank = bankMoney,
        recent = recent,
        spending = months,
        hasPin = account.pin ~= nil,
        brand = (eBank.Brand and eBank.Brand.Enabled) and {
            id = eBank.Brand.Id or 'bank',
            name = eBank.Brand.Name or 'Banque',
            bgColor = eBank.Brand.BgColor or '#1a1a1a',
            accent = eBank.Brand.Accent or '#10b981',
        } or nil,
        atmId = tostring(math.random(1000, 9999)),
    }
end

ESX.RegisterServerCallback('null:atm:getData', function(source, cb)
    cb(Bank.BuildATMData(source))
end)

ESX.RegisterServerCallback('null:atm:verifyPin', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not data then cb(false) return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then cb(false) return end
    if not account.pin then cb(false) return end
    cb(tostring(data.pin) == account.pin)
end)

RegisterNetEvent('Null:atm:withdraw', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end
    local isOk, amount = QuantityOk(data.amount)
    if not isOk then
        TriggerClientEvent('null:atm:opResult', src, { success = false, message = 'Montant invalide' })
        return
    end
    if xPlayer.getAccount(eBank.Bank.AccountName).money < amount then
        TriggerClientEvent('null:atm:opResult', src, { success = false, message = 'Solde insuffisant' })
        return
    end
    xPlayer.removeAccountMoney(eBank.Bank.AccountName, amount)
    xPlayer.addAccountMoney(eBank.Money.AccountName, amount)
    Bank.AddTransaction(src, {
        amount = -amount,
        title = 'Retrait DAB',
        description = 'Retrait aux distributeurs',
        category = 'withdraw',
    })
    TriggerClientEvent('null:atm:opResult', src, { success = true, message = 'Retrait effectué', type = 'withdraw', amount = amount })
    TriggerClientEvent('null:atm:update', src, Bank.BuildATMData(src))
end)

RegisterNetEvent('Null:atm:deposit', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end
    local isOk, amount = QuantityOk(data.amount)
    if not isOk then
        TriggerClientEvent('null:atm:opResult', src, { success = false, message = 'Montant invalide' })
        return
    end
    if xPlayer.getAccount(eBank.Money.AccountName).money < amount then
        TriggerClientEvent('null:atm:opResult', src, { success = false, message = 'Pas assez d\'espèces' })
        return
    end
    xPlayer.removeAccountMoney(eBank.Money.AccountName, amount)
    xPlayer.addAccountMoney(eBank.Bank.AccountName, amount)
    Bank.AddTransaction(src, {
        amount = amount,
        title = 'Dépôt DAB',
        description = 'Dépôt aux distributeurs',
        category = 'deposit',
    })
    TriggerClientEvent('null:atm:opResult', src, { success = true, message = 'Dépôt effectué', type = 'deposit', amount = amount })
    TriggerClientEvent('null:atm:update', src, Bank.BuildATMData(src))
end)

-- ============================================================
-- CREDIT / LOANS
-- ============================================================

RegisterNetEvent('Null:bank:requestLoan', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end
    if not eBank.Credit or not eBank.Credit.Active then
        xPlayer.showNotification("~r~Les crédits ne sont pas disponibles.")
        return
    end

    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    local amount = tonumber(data.amount)
    local installments = tonumber(data.installments)

    if not amount or not installments then return end
    if amount < eBank.Credit.MinAmount or amount > eBank.Credit.MaxAmount then
        xPlayer.showNotification("~r~Montant invalide.")
        return
    end

    -- Check max active loans
    local activeCount = 0
    for _, c in ipairs(account.credits) do
        if not c.paidOff then activeCount = activeCount + 1 end
    end
    if activeCount >= eBank.Credit.MaxActiveLoans then
        xPlayer.showNotification("~r~Vous avez déjà un crédit actif.")
        return
    end

    -- Validate installments
    local validInstall = false
    for _, v in ipairs(eBank.Credit.Installments) do
        if v == installments then validInstall = true break end
    end
    if not validInstall then return end

    local interest = amount * eBank.Credit.InterestRate
    local totalDue = amount + interest
    local perInstallment = math.ceil(totalDue / installments)

    local loan = {
        id = GenerateTransactionId(),
        originalAmount = amount,
        interest = interest,
        totalDue = totalDue,
        installments = installments,
        perInstallment = perInstallment,
        paid = 0,
        paidInstallments = 0,
        paidOff = false,
        createdAt = GetTimestamp(),
        createdDate = GetDate(),
    }

    table.insert(account.credits, loan)
    xPlayer.addAccountMoney(eBank.Bank.AccountName, amount)

    Bank.AddTransaction(src, {
        amount = amount,
        title = 'Crédit obtenu',
        description = 'Crédit de ' .. amount .. '$ en ' .. installments .. ' mensualités',
        category = 'loan',
    })

    xPlayer.showNotification('Crédit de ~g~' .. amount .. '$~s~ accordé')
end)

RegisterNetEvent('Null:bank:repayLoan', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not data then return end

    local account = Bank.GetAccount(xPlayer.identifier)
    if not account then return end

    local loanId = data.loanId
    local amount = tonumber(data.amount)
    if not loanId or not amount or amount <= 0 then return end

    for _, loan in ipairs(account.credits) do
        if loan.id == loanId and not loan.paidOff then
            local remaining = loan.totalDue - loan.paid
            if amount > remaining then amount = remaining end

            if xPlayer.getAccount(eBank.Bank.AccountName).money < amount then
                xPlayer.showNotification("~r~Solde insuffisant.")
                return
            end

            xPlayer.removeAccountMoney(eBank.Bank.AccountName, amount)
            loan.paid = loan.paid + amount
            loan.paidInstallments = loan.paidInstallments + 1

            if loan.paid >= loan.totalDue then
                loan.paidOff = true
                xPlayer.showNotification('Crédit ~g~entièrement remboursé~s~')
            else
                xPlayer.showNotification('Remboursement de ~g~' .. amount .. '$~s~ effectué')
            end

            Bank.AddTransaction(src, {
                amount = -amount,
                title = 'Remboursement crédit',
                description = 'Remboursement de ' .. amount .. '$',
                category = 'repayment',
            })
            return
        end
    end
end)

-- ============================================================
-- TRANSACTION HISTORY (legacy event for other modules)
-- ============================================================

RegisterNetEvent('getTransactionHistory', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local account = Bank.GetAccount(xPlayer.identifier)
    if account then
        TriggerClientEvent('receiveTransactionHistory', src, account.history)
    end
end)
