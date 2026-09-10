-- ============================================================
--  Taxi — Menu de service (Compat & Annonces)
--  Le menu principal d'interaction est désormais une UI React
--  (TaxiBoard) ouverte via OpenMenuTaxi() défini dans main.lua.
--  Ce fichier ne conserve que :
--   - le menu d'annonces RageUI (ouverture/fermeture du service)
--   - la facturation rapide d'un client proche
-- ============================================================

local CFG = Config.Taxi

local serviceMenuOpen = false
local serviceMenu = RageUI.CreateMenu("Service Taxi", "Annonces & Facturation")
serviceMenu.Display.Header = true
serviceMenu.Closed = function() serviceMenuOpen = false end

local serviceStatus = false

function OpenTaxiServiceMenu()
    if serviceMenuOpen then
        serviceMenuOpen = false
        RageUI.Visible(serviceMenu, false)
        return
    end

    serviceMenuOpen = true
    RageUI.Visible(serviceMenu, true)

    Citizen.CreateThread(function()
        while serviceMenuOpen do
            RageUI.IsVisible(serviceMenu, function()
                RageUI.Checkbox("Prendre mon service", "Vous rend disponible pour les appels taxi des joueurs.", serviceStatus, {}, {
                    onChecked = function()
                        serviceStatus = true
                        TriggerServerEvent("null:taxi:setService", true)
                        if ESX and ESX.ShowNotification then
                            ESX.ShowNotification("~g~Service taxi pris~s~ — vous recevrez les appels clients")
                        end
                    end,
                    onUnChecked = function()
                        serviceStatus = false
                        TriggerServerEvent("null:taxi:setService", false)
                        if ESX and ESX.ShowNotification then
                            ESX.ShowNotification("~o~Service taxi quitté")
                        end
                    end,
                })

                RageUI.Line()

                if serviceStatus == true then

                    RageUI.Checkbox("Status de l'entreprise", "Affiche le statut de l'entreprise.", entreprisestatus, {}, {
                    onChecked = function()
                        entreprisestatus = true 
                        TriggerServerEvent("vsociety:updateSocietyStatus", "taxi", true)
                    end,
                    onUnChecked = function()
                        entreprisestatus = false
                        TriggerServerEvent("vsociety:updateSocietyStatus", "taxi", false)
                    end,
                })

                RageUI.Button("Montrer mon badge", nil, {}, true, {
                    onSelected = function()
                        if ShowJobBadge then ShowJobBadge(ESX.PlayerData.job.name) end
                    end,
                })

                RageUI.Button("Facturer un client proche", "Envoie une facture au joueur le plus proche.", {}, true, {
                    onSelected = function()
                        local closest, dist = ESX.Game.GetClosestPlayer()
                        if closest ~= -1 and dist <= 3.0 then
                            local amount = null.fct.input("Montant de la facture")
                            if amount and tonumber(amount) and tonumber(amount) > 0 then
                                TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closest), tonumber(amount), ESX.PlayerData.job.name)
                                ESX.ShowNotification("~g~Facture envoyée")
                            end
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end,
                })

                RageUI.Button("Ouvrir le tableau de bord", "Affiche les missions disponibles.", { RightLabel = "→" }, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        TaxiClient.OpenBoard()
                    end,
                })
            end

            end)
            Wait(0)
        end
    end)
end
