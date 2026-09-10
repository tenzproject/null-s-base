-- ============================================================
-- BANK UI — NUI Bridge (replaces RageUI OpenBank)
-- ============================================================

local BankUIOpen = false

local function SendBankNUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function CloseBankUI(fromNUI)
    if not BankUIOpen then return end
    BankUIOpen = false
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
    if not fromNUI then
        SendBankNUI("bank:close", {})
    end
end

-- ============================================================
-- OPEN BANK
-- ============================================================

function OpenBankUI()
    if BankUIOpen then return end

    ESX.TriggerServerCallback('null:bank:getData', function(bankData)
        if not bankData then return end

        SendBankNUI("bank:open", bankData)
        BankUIOpen = true 
        null.DisplayHud("3dinteractions", false)
        SetNuiFocus(true, true)
        FreezeEntityPosition(PlayerPedId(), true)
    end)
end

-- Override global OpenBank
OpenBank = OpenBankUI

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback("bank:close", function(data, cb)
    CloseBankUI(true)
    null.DisplayHud("3dinteractions", true)
    cb("ok")
end)

local function RefreshBankData()
    ESX.TriggerServerCallback('null:bank:getData', function(bankData)
        if bankData and BankUIOpen then
            SendBankNUI("bank:update", bankData)
        end
    end)
end

RegisterNUICallback("bank:deposit", function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then cb("error") return end

    TriggerServerEvent('Null:ActionBank', 'deposit', amount)
    ExecuteCommand("me viens de déposer de l'argent")

    Citizen.SetTimeout(300, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:withdraw", function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then cb("error") return end

    TriggerServerEvent('Null:ActionBank', 'withdraw', amount)
    ExecuteCommand("me viens de retirer de l'argent")

    Citizen.SetTimeout(300, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:transfer", function(data, cb)
    if not data.iban or not data.amount then cb("error") return end
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then cb("error") return end

    TriggerServerEvent('Null:banque:sendVirement', {
        IBAN = data.iban,
        MONTANT = amount,
        RAISON = data.reason or '',
    })

    Citizen.SetTimeout(500, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:acceptTransfer", function(data, cb)
    if not data.id then cb("error") return end

    TriggerServerEvent('Null:RVirement', data.id)

    Citizen.SetTimeout(500, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:requestLoan", function(data, cb)
    local amount = tonumber(data.amount)
    local installments = tonumber(data.installments)
    if not amount or not installments then cb("error") return end

    TriggerServerEvent('Null:bank:requestLoan', {
        amount = amount,
        installments = installments,
    })

    Citizen.SetTimeout(500, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:repayLoan", function(data, cb)
    if not data.loanId or not data.amount then cb("error") return end

    TriggerServerEvent('Null:bank:repayLoan', {
        loanId = data.loanId,
        amount = tonumber(data.amount),
    })

    Citizen.SetTimeout(500, function()
        RefreshBankData()
    end)
    cb("ok")
end)

RegisterNUICallback("bank:buyCard", function(data, cb)
    TriggerServerEvent('Null:bank:buyCard')
    cb("ok")
end)

RegisterNUICallback("bank:setPin", function(data, cb)
    if not data.pin then cb("error") return end
    TriggerServerEvent('Null:bank:setPin', { pin = tostring(data.pin) })
    cb("ok")
end)

RegisterNetEvent('null:bank:cardResult', function(data)
    SendBankNUI('bank:cardResult', data)
end)

RegisterNetEvent('null:bank:pinResult', function(data)
    SendBankNUI('bank:pinResult', data)
end)
