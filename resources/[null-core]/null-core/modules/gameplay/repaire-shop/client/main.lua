function OpenRepairMenu(id)
    if not id then return end

    local myRepairs = {}
    local numberRepairs = 0

    ESX.TriggerServerCallback("Null:repairshop:get", function(result) 
        myRepairs = result
        numberRepairs = ESX.Table.SizeOf(myRepairs)
    end)

    local menu = RageUI.CreateMenu(nil, "")
    RageUI.Visible(menu, true)
    local isVip = GetVIP() 
    local vipType = nil
    pcall(function() vipType = exports["null-core"]:GetVIP() end)
    Citizen.CreateThread(function()
        while menu do
            RageUI.IsVisible(menu, function()
                local timetorepair = tostring(Config.Repair.TimeToRepair).." Minutes"
                if isVip and Config.VIP and Config.VIP.Tiers then
                    local tier = Config.VIP.Tiers[vipType or "Basic"]
                    if tier and tier.advantages and tier.advantages.repairTimeMinutes then
                        timetorepair = tostring(tier.advantages.repairTimeMinutes).." Minutes (~y~VIP~s~)"
                    elseif Config.Repair.TimeToRepairVIP then
                        timetorepair = tostring(Config.Repair.TimeToRepairVIP).." Minutes (~y~VIP~s~)"
                    end
                end
                RageUI.Button("Faire réparer nouvelle une arme", "Coût d'une réparation complète : \nPistolet: "..Config.Repair.Prices["pistol"].."$\nMitrailette: "..Config.Repair.Prices["rifle"].."$\nPompe: "..Config.Repair.Prices["shotgun"].."$\nSniper: "..Config.Repair.Prices["sniper"].."$\n\nTemps de réparation : "..timetorepair.."", {}, true, {
                    onSelected = function()
                        local optionlist = {}
                        for k,v in pairs(ESX.PlayerData.loadout) do
                            table.insert(optionlist, {value=v.name,label=v.label.." ("..v.name..")"})
                        end
                        local result = null.fct.input("Votre choix", true, {
                            {type = 'select', label = 'Quelle arme voulez-vous réparer ?',options=optionlist, searchable = true}})
                        if result == nil then return end
                        TriggerServerEvent("null:repair:weapon", result, ESX.GetAmmoType(result))
                        RageUI.CloseAll()
                    end
                })
                if numberRepairs > 0 then
                    RageUI.Separator("Vos armes réparées :")
                    for k,v in pairs(myRepairs) do
                        if v.pourcent == 100 and v.finish then
                            -- RageUI.SliderProgress(ESX.GetWeaponLabel(k), 100, 100, nil, {ProgressColor = {R = 0, G = 255, B = 0, A = 255}, ProgressBackgroundColor = {R = 0, G = 0, B = 0, A = 150}}, true, {
                            --     onSelected = function()
                            --         TriggerServerEvent("null:repair:get", k)
                            --         RageUI.CloseAll()
                            --     end
                            -- })

                            RageUI.Button(ESX.GetWeaponLabel(k), "Prendre votre arme", {}, true, {
                                onSelected = function()
                                    TriggerServerEvent("null:repair:get", k)
                                    RageUI.CloseAll()
                                end
                            })
                        end
                    end
                    RageUI.Separator("Vos armes en réparation :")
                    for k,v in pairs(myRepairs) do
                        if v.pourcent < 100 and not v.finish then
                            -- RageUI.SliderProgress(ESX.GetWeaponLabel(k), v.pourcent, 100, nil, {ProgressColor = {R = 0, G = 200, B = 100, A = 150}, ProgressBackgroundColor = {R = 0, G = 0, B = 0, A = 150}}, true, {
                            --     onSelected = function()
                            --         ESX.ShowNotification("Nous n'avons pas fini de réparer cette arme !")
                            --     end
                            -- })
                            RageUI.Progress(ESX.GetWeaponLabel(k), v.pourcent, 100, nil, true, false, {})
                        end
                    end
                else

                end
            end)

            if not RageUI.Visible(menu) then
                menu = RMenu:DeleteType("menu", true)
            end

            Citizen.Wait(0)
        end
    end)
end