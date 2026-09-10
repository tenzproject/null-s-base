local Type = {
    { Name = "Voiture", Value = "car"},
    { Name = "Avion", Value = "aircraft" },
    { Name = "Bateau", Value = "boat" }
}

RegisterCommand("garage:addvehicle", function(source, args, rawCommand)
    if Config.GroupeHighPerm[ESX.GetPlayerData()["group"]] then
        GarageGiveVh()
    else
        ESX.ShowNotification("Vous n'avez pas les permissions nécessaire a l'ouverture de ce menu !")
    end
end)

function defineorNot(str) 
    if str == nil then
        return "Non Défini"
    else
        return str
    end
end


local vhForJob = false
local plateAutomatic = true
local vhBoutique = false
local vhBoutique2 = 0

function GarageGiveVh()
    local patronicMenu = RageUI.CreateMenu("", "Donner un véhicule")
    patronicMenu.TitleFont = 2;
    local put = false
    local put2 = false
    local put3 = false
    local string1 = nil
    local string2 = nil
    local string3 = nil
    local select_type = "car";
    local INDEXFDP = 1;

    RageUI.Visible(patronicMenu, not RageUI.Visible(patronicMenu))
    
    while patronicMenu do
        Citizen.Wait(0)
        RageUI.IsVisible(patronicMenu, function()
            RageUI.Checkbox('Attribuer a un job', nil, vhForJob, {}, {
                onChecked = function()
                    vhForJob = true
                end,
                onUnChecked = function()
                    vhForJob = false
                    string3 = nil
                end
            })
            RageUI.Checkbox('Plaque Aléatoire', "Recommander !", plateAutomatic, {}, {
                onChecked = function()
                    plateAutomatic = true
                end,
                onUnChecked = function()
                    plateAutomatic = false
                end
            })
            RageUI.Line()
            if not vhForJob then
                RageUI.Button("Joueur seléctionné", "Votre réponse doit être un ID", { RightLabel = defineorNot(string1) }, true, {
                    onSelected = function()
                        string1 = null.fct.input('ID Du joueur')
                        put = false
                    end
                })
            else
                RageUI.Button("Job seléctionné", "Votre réponse doit être un setjob", { RightLabel = defineorNot(string1) }, true, {
                    onSelected = function()
                        string1 = null.fct.input('Setjob Du job')
                        put = false
                    end
                })
            end
            RageUI.Button("Voiture seléctionné", "Votre réponse doit être un ~HUD_COLOUR_NET_PLAYER22~Model de voiture telle que rmodrs6, adder", { RightLabel = defineorNot(string2) }, true, {
                onSelected = function()
                    string2 = null.fct.input('Model de la voiture', false, 20., "small_text")
                    if string2 ~= nil then
                        put2 = false
                    else
                        ESX.ShowHelpNotification("Votre réponse est ~r~incorrect")
                    end
                end
            })
            if not plateAutomatic then
                RageUI.Button("Plaque", nil, { RightLabel = defineorNot(string3) }, true, {
                    onSelected = function()
                        string3 = null.fct.input('Plaque de la voiture', false, 20., "small_text")
                        if string3 ~= nil then
                            put3 = false
                        else
                            ESX.ShowHelpNotification("Votre réponse est ~r~incorrect")
                        end
                    end
                })
            end
            RageUI.List("Type de véhicule", Type, INDEXFDP, nil, {}, true, {
                onListChange = function(Index, Item)
                    INDEXFDP = Index;
                    if Item.Value == "car" then
                        select_type = "car"
                        ESX.ShowNotification("Voiture seléctionné !")
                    elseif Item.Value == "aircraft" then
                        select_type = "aircraft"
                        ESX.ShowNotification("Avion seléctionné !")
                    elseif Item.Value == "boat" then
                        select_type = "boat"
                        ESX.ShowNotification("Bateau seléctionné !")
                    end
                end
            })
            if not vhForJob then
                RageUI.Checkbox('Véhicule boutique', nil, vhBoutique, {}, {
                    onChecked = function()
                        vhBoutique = true
                        vhBoutique2 = 1
                        ESX.ShowNotification("Véhicule boutique : Oui")
                    end,
                    onUnChecked = function()
                        vhBoutique = false
                        vhBoutique2 = 0
                        ESX.ShowNotification("Véhicule boutique : Non")
                    end
                })
            end
            if not put and not put2 and not put3 and select_type then
                RageUI.Button("~g~Confirmer", nil, {}, true, {
                    onSelected = function()
                        put = true
                        put2 = true
                        put3 = true
                        TriggerServerEvent("Kayce:AddVehToClient", string1, string2, string3, select_type, vhBoutique, vhForJob, plateAutomatic)
                        RageUI.CloseAll()
                        string1 = nil
                        string2 = nil
                        string3 = nil
                        vhForJob = false
                    end
                })
            end
        end)
        if not RageUI.Visible(patronicMenu) then
            patronicMenu = RMenu:DeleteType('patronicMenu', true)
        end
    end
end