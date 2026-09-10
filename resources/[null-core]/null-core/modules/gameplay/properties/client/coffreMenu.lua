local Coffre = {}

local function CheckQuantity(number)
    number = tonumber(number)
  
    if type(number) == 'number' then
        number = ESX.Math.Round(number)
        if number > 0 then
            return true, number
        end
    end
  
    return false, number
end

local function SizeOfTable(t)
    local total = 0
    for k,v in pairs(t) do
        total = total + v
    end
    return total
end 

local function GetWeightRestantProperties(data)
    local countList = {}
    if json.encode(data) == "[]" then 
        return 0
    else 
        for k,v in pairs(data["item"]) do 
            table.insert(countList, v.count)
        end
        for k,v in pairs(data["weapons"]) do 
            table.insert(countList, ESX.GetWeaponWeight(v.name))
        end
        return SizeOfTable(countList)
    end
end

local List = {
    Actions = {
        "Déposer",
        "Prendre"
    },
    ActionIndex = 1
}

local Grades = {}
local GradesAllowed = {}
local KeysPerms = { enter = true, deposit = true, withdraw = true }

function OpenMenuCoffreProperties(info, notPersonnal, typeJob, sharedPerms)

    SetPlayerControl(PlayerId(), false, 12)

    if true then
        local label, price, poids = info.label, info.price, info.poids
        local menu = RageUI.CreateMenu(label, "Coffre - Que voulez vous faire ?")
        local actionCoffre = RageUI.CreateSubMenu(menu, "Actions", "Que voulez-vous faire ?")
        local gerePropertiesMenu = RageUI.CreateSubMenu(actionCoffre, "Gérer", "Que voulez-vous faire ?")
        local gradeListMenu = RageUI.CreateSubMenu(actionCoffre, "Liste des grades", "Grade ayant accès au coffre")
        local keysPermsMenu = RageUI.CreateSubMenu(actionCoffre, "Donner des clés", "Définissez les permissions")
        local manageAccessMenu = RageUI.CreateSubMenu(actionCoffre, "Gérer les accès", "Modifier les permissions des personnes")
        local editAccessSubMenu = RageUI.CreateSubMenu(manageAccessMenu, "Modifier accès", "Modifier les permissions")

        local editPersonIdx = 0
        local editPerms = { enter = true, deposit = true, withdraw = true }

        RageUI.Visible(menu, not RageUI.Visible(menu))

        TriggerServerEvent("null:properties:GetCoffreProperties", info.name)

        local idxList = 1
        
        -- Calculate permissions in real-time from current Properties data
        -- This ensures permissions are up-to-date even if keys were given while player is inside
        local currentPerms = sharedPerms
        if notPersonnal and not currentPerms then
            -- Look up current permissions from Properties global table
            local propData = Properties and Properties[info.name]
            if propData and propData.parms and propData.parms.PeopleAlloweds then
                for _, person in ipairs(propData.parms.PeopleAlloweds) do
                    if person.identifier == MyLicense then
                        currentPerms = person.perms or { enter = true, deposit = true, withdraw = true }
                        break
                    end
                end
            end
        end
        
        -- Owner always has full permissions
        local isOwner = not notPersonnal
        if notPersonnal and not isOwner then
            -- Check if actually owner (owner field might have changed)
            local propData = Properties and Properties[info.name]
            if propData and (propData.owner == MyLicense or propData.owner == ESX.PlayerData.job.name or propData.owner == ESX.PlayerData.job2.name) then
                isOwner = true
            end
        end
        
        local canDeposit  = isOwner or (currentPerms and currentPerms.deposit)
        local canWithdraw = isOwner or (currentPerms and currentPerms.withdraw)

        while menu do
            Wait(0)
            RageUI.IsVisible(menu, function()
                if canDeposit or canWithdraw then
                    RageUI.Button("Coffre", nil, {}, true, {
                        onSelected = function()
                            RageUI.CloseAll()
                            null.DebugPrint("proprieties_"..info.name)
                            ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                                if data then
                                    local inventory = data
                                    inventory.weight = 0
                                    inventory.id = id
                                    inventory.maxWeight = poids
                                    inventory.type = "PROPERTY"
                                    TriggerEvent("inventory:openTarget",inventory)
                                end
                            end, "proprieties_"..info.name, "PROPERTY", poids)
                        end
                    })
                end
                if isOwner then
                    RageUI.Button("Actions sur la propriété", nil, {}, true, {
                        onSelected = function()
                        end
                    }, actionCoffre)
                end

            end, function()
            end)

            RageUI.IsVisible(actionCoffre, function()

                RageUI.Button("Nom de la propriété :", nil, { RightLabel = label }, true, {})
                local proprio
                if not notPersonnal then 
                    proprio = "Vous"
                else 
                    proprio = info.owner
                end
                RageUI.Button("Propriétaire :", nil, { RightLabel = proprio }, true, {})
                --RageUI.Button("Prix d'achat :", nil, { RightLabel = price.."$" }, true, {})
                --RageUI.Button("Prix de revente :", nil, { RightLabel = math.floor((price*75)/100).."$" }, true, {})
                RageUI.Button("Poids maximal du coffre :", nil, { RightLabel = poids.."kg" }, true, {})
                RageUI.Button("Poids du coffre utilisé :", nil, { RightLabel = GetWeightRestantProperties(Coffre).."/"..info.poids }, true, {})
                RageUI.Separator("")
            RageUI.List("Attribuer la propriété", {
                    {Name = "Entreprise", Value = 1},
                    {Name = "Organisation", Value = 2},
                    }, idxList, nil, {}, not notPersonnal, {
                    onListChange = function(Index, Item)
                        idxList = Index;
                    end,
                    onSelected = function()
                        if not notPersonnal then
                            if idxList == 1 then 
                                TriggerServerEvent("null:properties:PlayerAttribuetPropreties", info, 1)
                            elseif idxList == 2 then 
                                TriggerServerEvent("null:properties:PlayerAttribuetPropreties", info, 2)
                            end
                        else
                            ESX.ShowNotification("Vous ne pouvez pas faire ceci")
                        end
                    end
                })
                RageUI.Button("Donner des clés (permissions)", nil, {}, not notPersonnal, {
                    onSelected = function()
                        KeysPerms = { enter = true, deposit = true, withdraw = true }
                    end
                }, keysPermsMenu)
                RageUI.Button("Gérer les accès existants", nil, {}, not notPersonnal, {}, manageAccessMenu)
                --[[RageUI.Button("Rendre la propriété", "~r~Vous renderez cette propriété pour "..math.floor((price*75)/100).."$", {}, not notPersonnal, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:PlayerHasRenderProperties", info, math.floor((price*75)/100))
                    end
                })]]
                if notPersonnal then
                    RageUI.Button("Gérer la propriété en temps que patron", "Vous devez être patron du job/organisation", {}, ESX.PlayerData.job.grade_name == "boss" or ESX.PlayerData.job2.grade_name == "boss", {}, gerePropertiesMenu)
                end

            end, function()
            end)

            RageUI.IsVisible(keysPermsMenu, function()

                RageUI.Checkbox("Peut entrer dans la propriété", nil, KeysPerms.enter, {}, {
                    onChecked   = function() KeysPerms.enter    = true  end,
                    onUnChecked = function() KeysPerms.enter    = false end,
                })
                RageUI.Checkbox("Peut déposer dans le coffre", nil, KeysPerms.deposit, {}, {
                    onChecked   = function() KeysPerms.deposit  = true  end,
                    onUnChecked = function() KeysPerms.deposit  = false end,
                })
                RageUI.Checkbox("Peut retirer du coffre", nil, KeysPerms.withdraw, {}, {
                    onChecked   = function() KeysPerms.withdraw = true  end,
                    onUnChecked = function() KeysPerms.withdraw = false end,
                })
                RageUI.Separator("")
                RageUI.Button("Confirmer et donner les clés", nil, { RightBadge = RageUI.BadgeStyle.Tick }, true, {
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("null:properties:PlayerDonnedKeysToPlayerProperties", info, GetPlayerServerId(closestPlayer), KeysPerms)
                            RageUI.GoBack()
                        else
                            ESX.ShowNotification("~r~Propriété\n~s~Aucun joueur à proximité")
                        end
                    end
                })

            end, function() end)

            RageUI.IsVisible(manageAccessMenu, function()

                local parms = Properties and Properties[info.name] and Properties[info.name].parms
                if parms and parms.PeopleAlloweds and #parms.PeopleAlloweds > 0 then
                    for idx, person in ipairs(parms.PeopleAlloweds) do
                        local perms = person.perms or { enter = true, deposit = true, withdraw = true }
                        local summary = (perms.enter and "E" or "-")..(perms.deposit and "D" or "-")..(perms.withdraw and "R" or "-")
                        RageUI.Button(person.name, "[E]ntrer [D]époser [R]etirer : "..summary, {}, true, {
                            onSelected = function()
                                editPersonIdx = idx
                                editPerms = { enter = perms.enter, deposit = perms.deposit, withdraw = perms.withdraw }
                            end
                        }, editAccessSubMenu)
                        RageUI.Button("Retirer les clés de "..person.name, nil, { RightBadge = RageUI.BadgeStyle.Lock }, true, {
                            onSelected = function()
                                TriggerServerEvent("null:properties:RevokeKeysProperties", info, idx)
                                RageUI.GoBack()
                            end
                        })
                        RageUI.Separator("")
                    end
                else
                    RageUI.Button("Aucun accès partagé", nil, {}, false, {})
                end

            end, function() end)

            RageUI.IsVisible(editAccessSubMenu, function()
                RageUI.Checkbox("Peut entrer dans la propriété", nil, editPerms.enter, {}, {
                    onChecked   = function() editPerms.enter    = true  end,
                    onUnChecked = function() editPerms.enter    = false end,
                })
                RageUI.Checkbox("Peut déposer dans le coffre", nil, editPerms.deposit, {}, {
                    onChecked   = function() editPerms.deposit  = true  end,
                    onUnChecked = function() editPerms.deposit  = false end,
                })
                RageUI.Checkbox("Peut retirer du coffre", nil, editPerms.withdraw, {}, {
                    onChecked   = function() editPerms.withdraw = true  end,
                    onUnChecked = function() editPerms.withdraw = false end,
                })
                RageUI.Separator("")
                RageUI.Button("Confirmer les modifications", nil, { RightBadge = RageUI.BadgeStyle.Tick }, true, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:UpdateAccessPermsProperties", info, editPersonIdx, editPerms)
                        RageUI.GoBack()
                    end
                })

            end, function() end)

            RageUI.IsVisible(gerePropertiesMenu, function()

                RageUI.Button("Grade ayant accès a la propriété", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:GetGradeListProperties", info)
                    end
                }, gradeListMenu)

            end, function()
            end)

            RageUI.IsVisible(gradeListMenu, function()
                for k,v in pairs(Grades) do 
                    RageUI.Checkbox(v, "Attention à ne pas vous enlever l'accés !", GradesAllowed[v], {}, {
                        onChecked = function()
                            GradesAllowed[v] = true
                        end,
                        onUnChecked = function()
                            GradesAllowed[v] = false
                        end
                    })
                end

                RageUI.Button("Confirmer les modifications", nil, {RightBadge = RageUI.BadgeStyle.Tick}, true, {
                    onSelected = function()
                        TriggerServerEvent('null:properties:UpdateGradeListProperties', info, GradesAllowed)
                        RageUI.GoBack()
                    end
                })

            end, function()
            end)

            if not RageUI.Visible(menu)
            and not RageUI.Visible(actionCoffre)
            and not RageUI.Visible(gerePropertiesMenu)
            and not RageUI.Visible(gradeListMenu)
            and not RageUI.Visible(keysPermsMenu)
            and not RageUI.Visible(manageAccessMenu)
            and not RageUI.Visible(editAccessSubMenu)
            then menu = RMenu:DeleteType('menu', true)
                actionCoffre = RMenu:DeleteType('actionCoffre', true)
                gerePropertiesMenu = RMenu:DeleteType('gerePropertiesMenu', true)
                gradeListMenu = RMenu:DeleteType('gradeListMenu', true)
                keysPermsMenu = RMenu:DeleteType('keysPermsMenu', true)
                manageAccessMenu = RMenu:DeleteType('manageAccessMenu', true)
                editAccessSubMenu = RMenu:DeleteType('editAccessSubMenu', true)
                SetPlayerControl(PlayerId(), true, 12)
            end
        end
    end
end


RegisterNetEvent("null:properties:GetCoffreProperties")
AddEventHandler("null:properties:GetCoffreProperties", function(data)
    Coffre = data
end)

RegisterNetEvent("null:properties:UpdateCoffreProperties")
AddEventHandler("null:properties:UpdateCoffreProperties", function(data)
    Coffre = data
end)

RegisterNetEvent("null:properties:ResultOfGradeListProperties")
AddEventHandler("null:properties:ResultOfGradeListProperties", function(GradeList, GradesAlloweds)
    Grades = GradeList
    GradesAllowed = GradesAlloweds
end)