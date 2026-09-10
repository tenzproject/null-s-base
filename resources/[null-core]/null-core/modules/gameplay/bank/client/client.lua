local Bank = {}
Virement = {
    IBAN = nil,
    MONTANT = nil,
    RAISON = nil,
    Validate = false,
}

Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    TriggerServerEvent('Null:GetInformationsBank')
end)

RegisterNetEvent('Null:ReceiveInformaionsBank', function(table)
    Bank = table
end)

local BanqueTimeoutButton = true
function OpenBank()
    local menu = RageUI.CreateMenu("", "Actions Disponibles")
    local OpenPlayerHistory = RageUI.CreateSubMenu(menu, "", "Voici votre historique")
    local OpenPlayerBank = RageUI.CreateSubMenu(menu, "", "Actions Disponibles")
    local OpenVirementSend = RageUI.CreateSubMenu(menu, "", "Actions Disponibles")
    local OpenVirementAttente = RageUI.CreateSubMenu(menu, "", "Virements disponible")

    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            local MoneyLiquide = 0
            local MoneyBank = 0
            for i = 1, #ESX.PlayerData.accounts, 1 do
                if ESX.PlayerData.accounts[i].name == eBank.Money.AccountName then 
                    MoneyLiquide = ESX.PlayerData.accounts[i].money
                elseif ESX.PlayerData.accounts[i].name == eBank.Bank.AccountName then
                    MoneyBank = ESX.PlayerData.accounts[i].money
                end
            end
            RageUI.Info('Gestion Bancaire', {'Iban :','Argent Liquide :', 'Argent en Banque :'}, {ESX.Config("serverColor")..Bank.bankid,MoneyLiquide..'$',ESX.Config("serverColor")..MoneyBank..'$'})
            if eBank.Virement.Active then 
                RageUI.Button('Effectuer un virement', nil, {}, true, {
                    onSelected = function()
    
                    end
                }, OpenVirementSend)
                RageUI.Button('Mes virements en attentes', nil, {}, true, {
                    onSelected = function()
    
                    end
                }, OpenVirementAttente)
            end
            RageUI.Button('Retirer de l\'argent', nil, {}, true, {
                onSelected = function()
                    local withdraw = null.fct.input('Combien ?')
                    if withdraw ~= nil and withdraw ~= "" then
                        ExecuteCommand("me viens de retirer de l'argent")
                        TriggerServerEvent('Null:ActionBank', 'withdraw', withdraw)
                    end
                end
            })
            RageUI.Button('Déposer de l\'argent', nil, {}, true, {
                onSelected = function()
                    local deposit = null.fct.input('Combien ?')
                    if deposit ~= nil and deposit ~= "" then
                        ExecuteCommand("me viens de déposer de l'argent")
                        TriggerServerEvent('Null:ActionBank', 'deposit', deposit)
                    end
                end
            })            
            if eBank.History.Active then 
                RageUI.Button('Voir l\'historique de mon compte', nil, {}, true, {
                    onSelected = function()
    
                    end
                }, OpenPlayerHistory)
            end
        end, function()
        end)

        RageUI.IsVisible(OpenFinancement, function()

        end, function()
        end)

        RageUI.IsVisible(OpenVirementSend, function()
            RageUI.Button('IBAN', nil, {RightLabel = Virement.IBAN}, true, {
                onSelected = function()
                    Virement.IBAN = null.fct.input('IBAN')
                    if not Virement.IBAN then 
                        ESX.ShowNotification('Vous devez rentrer un IBAN')
                    end
                end
            })
            RageUI.Button('Raison', nil, {RightLabel = Virement.RAISON}, true, {
                onSelected = function()
                    Virement.RAISON = null.fct.input('RAISON')
                    if not Virement.RAISON then 
                        ESX.ShowNotification('Vous devez rentrer une RAISON')
                    end
                end
            })
            RageUI.Button('Montant', nil, {RightLabel = Virement.MONTANT}, true, {
                onSelected = function()
                    Virement.MONTANT = null.fct.input('MONTANT')
                    if not Virement.MONTANT then 
                        ESX.ShowNotification('Vous devez rentrer un MONTANT')
                    end
                end
            })
            if Virement.IBAN and Virement.RAISON and Virement.MONTANT then Virement.Validate = true end
            RageUI.Button('~g~Confirmer', nil, {}, Virement.Validate, {
                onSelected = function()
                    TriggerServerEvent('Null:banque:sendVirement', Virement)
                    Virement.MONTANT = nil
                    Virement.RAISON = nil
                    Virement.IBAN = nil
                    Virement.Validate = false
                end
            })
        end, function()
        end)

        RageUI.IsVisible(OpenVirementAttente, function()
            if Bank.Virement == nil or json.encode(Bank.Virement) == '[]' then 
                RageUI.Separator('Aucun virement en attente')
            else
                for k,v in pairs(Bank.Virement) do 
                    RageUI.Button(v.Description, nil, {}, BanqueTimeoutButton, {
                        onActive = function()
                            RageUI.Info('Virement en Attente', {'Date :','Montant :', 'Description :'}, {v.Date,v.amount..'$',v.Description})
                        end,
                        onSelected = function()
                            BanqueTimeoutButton = false
                            TriggerServerEvent('Null:RVirement', k)
                            Citizen.SetTimeout(1500, function()
                                BanqueTimeoutButton = true
                            end)
                        end
                    })
                end
            end
        end, function()
        end)
        -- Dans votre code principal

        RageUI.IsVisible(OpenPlayerHistory, function()
            -- Récupérez l'historique des transactions pour le compte actuel depuis le serveur
            TriggerServerEvent('getTransactionHistory')  -- Demandez l'historique au serveur
        
            -- Gestionnaire d'événement pour recevoir l'historique du serveur
            RegisterNetEvent('receiveTransactionHistory')
            AddEventHandler('receiveTransactionHistory', function(transactions)
                for k, v in pairs(transactions) do
                    -- Affichez chaque transaction dans le menu
                    RageUI.Button(v.Description, nil, {RightLabel = 'Montant : ' .. v.amount}, true, {
                        onActive = function()
                            -- Affichez les détails de la transaction ici
                            RageUI.Info('Historique Bancaire', {'Type :', 'Montant :', 'Description :', 'Date :'}, {v.type, v.amount .. '$', v.Description, v.date})
                        end,
                        onSelected = function()
                            -- Réagissez à la sélection de la transaction si nécessaire
                        end
                    }, OpenPlayerHistory)
                end
            end)
        end, function()
        end)
        

        if not RageUI.Visible(menu) and not RageUI.Visible(OpenPlayerHistory) and not RageUI.Visible(OpenFinancement) and not RageUI.Visible(OpenVirementSend) and not RageUI.Visible(OpenVirementAttente) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

-- ============================================================
-- ATM CLIENT BRIDGE
-- ============================================================

RegisterNUICallback('atm:close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'openGeneral', action = 'atm:close' })
    cb({})
end)

RegisterNUICallback('atm:getData', function(data, cb)
    ESX.TriggerServerCallback('null:atm:getData', function(result)
        cb(result or {})
    end)
end)

RegisterNUICallback('atm:verifyPin', function(data, cb)
    ESX.TriggerServerCallback('null:atm:verifyPin', function(success)
        cb({ success = success })
    end, data)
end)

RegisterNUICallback('atm:withdraw', function(data, cb)
    TriggerServerEvent('Null:atm:withdraw', data)
    cb({})
end)

RegisterNUICallback('atm:deposit', function(data, cb)
    TriggerServerEvent('Null:atm:deposit', data)
    cb({})
end)

RegisterNetEvent('null:atm:opResult', function(data)
    SendNUIMessage({ action = 'atm:opResult', data = data })
end)

RegisterNetEvent('null:atm:update', function(data)
    SendNUIMessage({ action = 'atm:update', data = data })
end)

function OpenAtmUI()
    ESX.TriggerServerCallback('null:atm:getData', function(atmData)
        if not atmData then
            ESX.ShowNotification("~r~Impossible de récupérer les données ATM")
            return
        end
        SendNUIMessage({ type = 'openGeneral', action = 'atm:open', data = atmData })
        SetNuiFocus(true, true)
    end)
end

