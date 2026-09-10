local Billing = {
    PlayerEffectuedBilling = {},
    Notification = function(id, str)
        TriggerClientEvent('esx:showNotification', id, str)
    end
}

RegisterNetEvent("Core:AddBilling", function(target, amount, society)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer.job.name ~= "unemployed" then
        if target and amount then 
            if amount <= 0 then 
                Billing.Notification(_source, "Une erreur c'est produite.")
                return
            else
                TriggerClientEvent("Core:AfficheBilling", target, _source, amount, society)
                table.insert(Billing.PlayerEffectuedBilling, _source)
                Billing.Notification(_source, "Facture envoyé avec succés.")
            end
        else 
            Billing.Notification(_source, "Une erreur c'est produite.")
        end
    else 
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche facture (0)")
    end
end)


local DemandeList = {}
local ReponseList = {}
RegisterNetEvent('null:billing:receviereponse')
AddEventHandler('null:billing:receviereponse', function(id, bool, passed)
    ReponseList[id] = {amount=DemandeList[id].amount,society=DemandeList[id].society,source=DemandeList[id].source,target=DemandeList[id].target, reponseeee=bool}
end)
ESX.RegisterServerCallback('Core:AddChoiceBilling', function(source, cb, target, amount, society)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    if target == nil then
        target = source
        xTarget = ESX.GetPlayerFromId(source)
    end
    if xTarget == nil then 
        print("Probleme Facture (045) Merci de contacter Null")
        return 
    end
    if xPlayer.job.name ~= "unemployed" then
        if target and amount then 
            if amount <= 0 then 
                cb(false)
            else
                if xTarget.getAccount("cash").money >= amount then
                    local id = math.random(0,99999999)
                    local response = nil
                    local maxTime = 0
                    DemandeList[id] = {amount=amount,society=society,source=source,target=target}
                    TriggerClientEvent("null:billing:receviedemande", target,id,amount,society)
                    while ReponseList[id] == nil do
                        maxTime = maxTime + 1
                        if maxTime >= 10 then 
                            DemandeList[id] = nil
                            ReponseList[id] = nil
                            break 
                        end
                        Wait(1000)
                    end
                    if ReponseList[id] ~= nil then
                        if ReponseList[id].reponseeee then
                            xTarget.removeAccountMoney("cash", amount)
                            --AddMoneyToSociety(xPlayer.getJob().name, "cash", amount)
                            SocietyCache[xPlayer.getJob().name].data["accounts"].cash = SocietyCache[xPlayer.getJob().name].data["accounts"].cash+amount
                            cb(true)
                            addHistorySociety(xPlayer.getJob().name, "Gains : Facture", "~n~Auteur: "..xPlayer.getName().." ("..xPlayer.idunique..")~n~Client: "..xTarget.getName().."~n~", amount)
                        elseif ReponseList[id].reponseeee == false then
                            cb(false)
                        end
                        DemandeList[id] = nil
                        ReponseList[id] = nil
                    else
                        cb(false)
                    end
                else
                    xPlayer.showNotification("Cette personne n'a pas asser d'argent !")
                    cb(false)
                end
            end
        else 
            cb(false)
        end
    else 
        cb(false)
    end
end)

RegisterNetEvent("Core:PayeBilling", function(type, sender, amount, society)
    local xPlayer = ESX.GetPlayerFromId(source)
    local EffectuedPassedBilling = false

    for k,v in pairs(Billing.PlayerEffectuedBilling) do 
        if v == sender then 
            EffectuedPassedBilling = true 
            table.remove(Billing.PlayerEffectuedBilling, k)
        end
    end
    if EffectuedPassedBilling then
        if type == "paye" then
            if xPlayer.getAccount('cash').money >= amount then 
                xPlayer.removeAccountMoney('cash', amount)
                if society and SocietyCache[society] then
                    SocietyCache[society].data["accounts"].cash = SocietyCache[society].data["accounts"].cash + amount
                    SocietySaved[society] = SocietyCache[society]
                    print("[^4INFORMATION^7] (^4ID:"..source.."^7) a ajouter de l'argent (^4SOMMES:"..amount.."$^7) dans une societer (^4SOCIETY:"..society.."^7)")
                else 
                    if society then 
                        print("[^1ERREUR^7] (^4ID:"..source.."^7) a tenter de mettre de l'argent (^4SOMMES:"..amount.."$^7) dans une societer non existante (^4SOCIETY:"..society.."^7)")
                    end
                end
                Billing.Notification(source, "Vous avez payer "..amount.."$")
                Billing.Notification(sender, "Vous avez reçu "..amount.."$")
            elseif xPlayer.getAccount('bank').money >= amount then
                xPlayer.removeAccountMoney('bank', amount, {title = 'Paiement Facture', description = 'Facture payée', category = 'fine'})
                if society and SocietyCache[society] then
                    SocietyCache[society].data["accounts"].cash = SocietyCache[society].data["accounts"].cash + amount
                    SocietySaved[society] = SocietyCache[society]
                    print("[^4INFORMATION^7] (^4ID:"..source.."^7) a ajouter de l'argent (^4SOMMES:"..amount.."$^7) dans une societer (^4SOCIETY:"..society.."^7)")
                else 
                    if society then 
                        print("[^1ERREUR^7] (^4ID:"..source.."^7) a tenter de mettre de l'argent (^4SOMMES:"..amount.."$^7) dans une societer non existante (^4SOCIETY:"..society.."^7)")
                    end
                end
                Billing.Notification(source, "Vous avez payer "..amount.."$")
                Billing.Notification(sender, "Vous avez reçu "..amount.."$")
            else
                Billing.Notification(source, "Vous n'avez pas assez d'argent")
                Billing.Notification(sender, "Le joueur n'a pas assez d'argent")
            end
        elseif type == "decline" then 
            Billing.Notification(source, "Vous avez refuser la facture")
            Billing.Notification(sender, "Le joueur a refuser")
        elseif type == "passed" then 
            Billing.Notification(source, "Vous avez mis trop de temps à régler cette facture.")
            Billing.Notification(sender, "Le joueur a mis trop de temps à régler cette facture")
        end
    else 
        ExecuteCommand("ban " .. _source .. " 0 Tentative de triche facture (1)")
    end
end)