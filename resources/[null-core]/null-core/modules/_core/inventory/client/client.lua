-- ============================================================================
-- OLD INVENTORY UI (RageUI menus) — DISABLED
-- The new React inventory (main.lua + new_inventory.lua) handles everything
-- Vehicle trunk (L key) and openChest export are kept active below
-- ============================================================================

local currentDistantInventory = nil

--[[ OLD RAGEUI INVENTORY MENUS — DISABLED
local openInventoryMenu = LPH_JIT_MAX(function()
    if currentDistantInventory == nil then return end

    local menu = RageUI.CreateMenu(nil, "Listes des actions disponibles")
    local menuDepositObject = RageUI.CreateSubMenu(menu, nil, "Listes des actions disponibles")
    local menuWithdrawObject = RageUI.CreateSubMenu(menu, nil, "Listes des actions disponibles")
    local menuDepositWeapon = RageUI.CreateSubMenu(menu, nil, "Listes des actions disponibles")
    local menuWithdrawWeapon = RageUI.CreateSubMenu(menu, nil, "Listes des actions disponibles")

    RageUI.Visible(menu, true)

    Citizen.CreateThread(function ()
        while menu do
            RageUI.IsVisible(menu, function ()
                RageUI.Separator(("%s"):format(ESX.InventoryTypeName[currentDistantInventory.type] ~= nil and ESX.InventoryTypeName[currentDistantInventory.type] or "Inventaire"))

                if currentDistantInventory.maxWeight ~= -1 then
                    RageUI.Separator(("Poids: %s/%s kg"):format(currentDistantInventory.weight, currentDistantInventory.maxWeight))
                end

                RageUI.Separator(("Argent: ~g~%s~s~ $"):format(currentDistantInventory.cash ~= nil and currentDistantInventory.cash or 0))
                RageUI.Separator(("Argent sale: ~r~%s~s~ $"):format(currentDistantInventory.dirtycash ~= nil and currentDistantInventory.dirtycash or 0))

                RageUI.Line()

                RageUI.Button("Déposer de l'argent", nil, {}, true, {
                    onSelected = function ()
                        null.fct.inputCb('Montant', function(data)
                            if data == nil or data == '' then
                                return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                            end
                            data = tonumber(data)

                            ESX.TriggerServerCallback('null:inv:transfertCashToStorage', function(final)
                                if final then
                                    currentDistantInventory.cash = currentDistantInventory.cash + data
                                end
                            end, currentDistantInventory.id, data, "cash", currentDistantInventory.type)
                        end)
                    end
                })

                RageUI.Button("Retirer de l'argent", nil, {}, true, {
                    onSelected = function ()
                        null.fct.inputCb('Montant', function(data)
                            if data == nil or data == '' then
                                return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                            end
                            data = tonumber(data)

                            ESX.TriggerServerCallback('null:inv:transfertStorageToCash', function(final)
                                if final then
                                    currentDistantInventory.cash = currentDistantInventory.cash - data
                                end
                            end, currentDistantInventory.id, data, "cash", currentDistantInventory.type)
                        end)
                    end
                })

                RageUI.Button("Déposer de l'argent sale", nil, {}, true, {
                    onSelected = function ()
                        null.fct.inputCb('Montant', function(data)
                            if data == nil or data == '' then
                                return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                            end
                            data = tonumber(data)
                            ESX.TriggerServerCallback('null:inv:transfertCashToStorage', function(final)
                                if final then
                                    currentDistantInventory.dirtycash = currentDistantInventory.dirtycash + data
                                end
                            end, currentDistantInventory.id, data, "dirtycash", currentDistantInventory.type)
                        end)
                    end
                })

                RageUI.Button("Retirer de l'argent sale", nil, {}, true, {
                    onSelected = function ()
                        null.fct.inputCb('Montant', function(data)
                            if data == nil or data == '' then
                                return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                            end
                            data = tonumber(data)

                            ESX.TriggerServerCallback('null:inv:transfertStorageToCash', function(final)
                                if final then
                                    currentDistantInventory.dirtycash = currentDistantInventory.dirtycash - data
                                end
                            end, currentDistantInventory.id, data, "dirtycash", currentDistantInventory.type)
                        end)
                    end
                })

                RageUI.Button("Déposer un objet", nil, {}, true, {}, menuDepositObject)
                RageUI.Button("Retirer un objet", nil, {}, true, {}, menuWithdrawObject)
                RageUI.Button("Déposer une arme", nil, {}, true, {}, menuDepositWeapon)
                RageUI.Button("Retirer une arme", nil, {}, true, {}, menuWithdrawWeapon)
            end)

            RageUI.IsVisible(menuDepositObject, function ()
                for i = 1, #ESX.PlayerData.inventory, 1 do
                    if ESX.ContribItem(ESX.PlayerData.inventory[i].name) then goto continue end

                    local item = ESX.PlayerData.inventory[i]

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = ("%s (%s)"):format(item.metadata.label, item.label)
                    end

                    RageUI.Button(("%s"):format(label), nil, { RightLabel = ("%s"):format(item.count) }, true, {
                        onSelected = function ()
                            null.fct.inputCb('Montant', function(result)
                                if result == nil or result == '' then
                                    return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                                end
                                result = tonumber(result)
                                
                                ESX.TriggerServerCallback('null:inv:transfertItemToStorage', function(final)
                                    if final then
                                        -- Todo Refresh l'inv
                                        local find = false
                                        for k,v in pairs(currentDistantInventory.items) do
                                            if v.name == item.name and not item.unique then
                                                find = true
                                                currentDistantInventory.items[k].count = currentDistantInventory.items[k].count + result
                                            end
                                        end

                                        if not find then
                                            table.insert(currentDistantInventory.items, {
                                                name=item.name,
                                                label=item.label,
                                                count=result,
                                                extra = item.extra,
                                                unique = item.unique,
                                                metadata = item.metadata,
                                            })
                                        end
                                    end
                                end, currentDistantInventory.id, item.name, result, currentDistantInventory.type, currentDistantInventory.maxWeight, item.extra ~= nil and item.extra.identifier or nil)
                            end)
                        end
                    })

                    ::continue::
                end
            end)

            RageUI.IsVisible(menuWithdrawObject, function ()
                for i = 1, #currentDistantInventory.items, 1 do
                    if ESX.ContribItem(currentDistantInventory.items[i].name) then goto continue end

                    local item = currentDistantInventory.items[i]

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = ("%s (%s)"):format(item.metadata.label, item.label)
                    end

                    RageUI.Button(("%s"):format(label), nil, { RightLabel = ("%s"):format(item.count) }, true, {
                        onSelected = function ()
                            null.fct.inputCb('Montant', function(result)
                                if result == nil or result == '' then
                                    return ESX.ShowNotification("~r~Le montant ne peut pas être nul", "Erreur")
                                end
                                result = tonumber(result)
                                local data2 = 'data'
                                
                                ESX.TriggerServerCallback('null:inv:transfertStorageToItem', function(final)
                                    if final then
                                        
                                        if item.count > result then
                                            currentDistantInventory.items[i].count = currentDistantInventory.items[i].count - result
                                        elseif item.count == result then
                                            table.remove(currentDistantInventory.items, i)
                                        end
                                    end
                                end, currentDistantInventory.id, item.name, result, currentDistantInventory.type, currentDistantInventory.maxWeight)
                            end)
                        end
                    })

                    ::continue::
                end
            end)

            RageUI.IsVisible(menuDepositWeapon, function ()
                for i = 1, #ESX.PlayerData.loadout, 1 do
                    if ESX.ContribWeapon(ESX.PlayerData.loadout[i].name) then goto continue end
                    if ESX.PlayerData.loadout[i].permanent then goto continue end

                    local item = ESX.PlayerData.loadout[i]

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = ("%s (%s)"):format(item.metadata.label, item.label)
                    end

                    RageUI.Button(("%s"):format(label), nil, {}, true, {
                        onSelected = function ()
                            ESX.TriggerServerCallback('null:inv:transfertWeaponToStorage', function(final)
                                if final then
                                    table.insert(currentDistantInventory.loadout, {
                                        name = item.name,
                                        label = item.label,
                                        metadata = item.metadata,
                                        permanent = item.permanent,
                                        serialnumber = item.serialnumber
                                    })
                                end
                            end, currentDistantInventory.id, item.name, currentDistantInventory.type, item.metadata, currentDistantInventory.maxWeight)
                        end
                    })

                    ::continue::
                end
            end)

            RageUI.IsVisible(menuWithdrawWeapon, function ()
                for i = 1, #currentDistantInventory.loadout, 1 do
                    if ESX.ContribWeapon(currentDistantInventory.loadout[i].name) then goto continue end
                    if currentDistantInventory.loadout[i].permanent then goto continue end

                    local item = currentDistantInventory.loadout[i]

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = ("%s (%s)"):format(item.metadata.label, item.label)
                    end

                    RageUI.Button(("%s"):format(label), nil, {}, true, {
                        onSelected = function ()
                            ESX.TriggerServerCallback('null:inv:transferStorageToWeapon', function(final)
                                if final then
                                    table.remove(currentDistantInventory.loadout, i)
                                end
                            end, currentDistantInventory.id, item.name, currentDistantInventory.type, item.metadata)
                        end
                    })

                    ::continue::
                end
            end)

            if
                not RageUI.Visible(menu) and
                not RageUI.Visible(menuDepositObject) and
                not RageUI.Visible(menuWithdrawObject) and
                not RageUI.Visible(menuDepositWeapon) and
                not RageUI.Visible(menuWithdrawWeapon)
            then
                TriggerServerEvent("inventory:unsubscribe", currentDistantInventory.id)
                TriggerServerEvent("null:closeCoffre", currentDistantInventory.savename)
                currentDistantInventory = nil

			    menu = RMenu:DeleteType("menu", true)
            end

            Citizen.Wait(0)
        end
    end)
end)
--]]

--[[ OLD RAGEUI SEARCH INVENTORY — DISABLED
local openSearchInventory = LPH_JIT_MAX(function(canMoove, cash, _dirtycash)
    if currentDistantInventory == nil then return end

    local menu = RageUI.CreateMenu(nil, "Listes des actions disponibles")

    RageUI.Visible(menu, true)

    local dirtycash = _dirtycash

    Citizen.CreateThread(function ()
        while menu do
            RageUI.IsVisible(menu, function ()
                RageUI.Separator("↓ Argents ↓")

                RageUI.Button(("Argent liquide: ~g~%s~s~ $"):format(cash), nil, {}, true, {
                    onSelected = function ()
                        if not canMoove then return end

                        --TriggerServerEvent("police:confiscate", currentDistantInventory.identifier, "item_account", "cash", cash)
                    end
                })
                RageUI.Button(("Argent sale: ~r~%s~s~ $"):format(dirtycash), nil, {}, true, {
                    onSelected = function ()
                        if not canMoove then return end
                        
                        --TriggerServerEvent("police:confiscate", currentDistantInventory.identifier, "item_account", "dirtycash", dirtycash)
                    end
                })

                RageUI.Separator("↓ Objets ↓")

                for i = 1, #currentDistantInventory.items, 1 do
                    local item = currentDistantInventory.items[i]
                    if item == nil then goto continue end

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = item.metadata.label
                    end

                    local canConfiscate = true
                    --if canMoove == false then
                    --    canConfiscate = false
                    --end

                    if ESX.ContribItem(item.name) then
                        canConfiscate = false
                    end

                    RageUI.Button(("%s (%s)"):format(label, item.label), nil, { RightLabel = ("Quantité: %s"):format(item.count) }, canConfiscate, {
                        onSelected = function ()
                            if not canMoove then return end

                            TriggerServerEvent("police:confiscate", currentDistantInventory.identifier, "item_standard", item.name, item.count, i, item.metadata)
                        end
                    })

                    ::continue::
                end

                RageUI.Separator("↓ Armes ↓")

                for i = 1, #currentDistantInventory.loadout, 1 do
                    local item = currentDistantInventory.loadout[i]
                    if item == nil then goto continue end

                    local label = item.label
                    if item.metadata ~= nil and item.metadata.label ~= nil then
                        label = item.metadata.label
                    end

                    local canConfiscate = true
                    --if canMoove == false then
                    --    canConfiscate = false
                    --end

                    if ESX.ContribWeapon(item.name) then
                        canConfiscate = false
                    elseif item.permanent then
                        canConfiscate = false
                    end

                    RageUI.Button(("%s (%s)"):format(label, item.label), nil, {}, canConfiscate, {
                        onSelected = function ()
                            if not canMoove then return end

                            TriggerServerEvent("police:confiscate", currentDistantInventory.identifier, "item_weapon", item.name, 1, i, item)
                        end
                    })

                    ::continue::
                end
            end)

            if not RageUI.Visible(menu) then
                TriggerServerEvent("inventory:unsubscribe", currentDistantInventory.id)
                currentDistantInventory = nil

                menu = RMenu:DeleteType("menu", true)
            end

            Citizen.Wait(0)
        end
    end)
end)


-- OLD EVENT HANDLERS — DISABLED (handled by ui.lua and main.lua now)
--[=[
AddEventHandler("inventory:onClose", function ()
    if currentDistantInventory == nil then return end

    TriggerServerEvent("inventory:unsubscribe", currentDistantInventory.id)
    currentDistantInventory = nil
    searching = nil
end)

RegisterNetEvent("inventory:update", function (data, inventory)
    TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())

    if currentDistantInventory == nil then return end

    if inventory.id == currentDistantInventory.id then
        currentDistantInventory.items = data.items
        currentDistantInventory.loadout = data.loadout
        currentDistantInventory.cash = data.cash
        currentDistantInventory.dirtycash = data.dirtycash
        currentDistantInventory.weight = inventory.weight

        TriggerEvent("inventory:right:changeWeight", currentDistantInventory.weight)
    end

    if not exports["null-core"]:getPreference("interfaces") then return end

    if formatInventory then
        local rightInventory = formatInventory(currentDistantInventory)
        TriggerEvent("esx:refreshRightInventory", rightInventory)
    end
end)

RegisterNetEvent("inventory:openTarget", function (target)
    --if getInPersoMenu() then return end
    currentDistantInventory = target

    if not exports["null-core"]:getPreference("interfaces") then
        RageUI.CloseAll()
        return openInventoryMenu()
    end

    local finalWeight = 0
    for k,v in pairs(target.items) do
        if v.weight ~= nil then
            finalWeight = finalWeight + (v.weight * v.count)
        end
    end
    for k,v in pairs(target.loadout) do
        finalWeight = finalWeight + 5
    end

    local rightInventory
    if formatInventory then
        rightInventory = formatInventory(target)
    end
    exports["null-core"]:openInventory({
        name = target.type,
        title = ("%s"):format(ESX.InventoryTypeName[target.type] ~= nil and ESX.InventoryTypeName[target.type] or "Inventaire"),
        weight = finalWeight,
        maxWeight = target.maxWeight ~= -1 and target.maxWeight or 999999999,
        inventory = rightInventory,
        data = { id = target.id, type = target.type },
        literal = target
    })
end)

RegisterNetEvent("inventory:openSearch", function (target, canMoove, cash, dirtycash)
    --if getInPersoMenu() then return end

    currentDistantInventory = target

    if not exports["null-core"]:getPreference("interfaces") then
        RageUI.CloseAll()
        return openSearchInventory(canMoove, cash, dirtycash)
    end

    target.cash = cash
    target.dirtycash = dirtycash

    local finalWeight = 0
    for k,v in pairs(target.items) do
        if v.weight ~= nil then
            finalWeight = finalWeight + (v.weight * v.count)
        end
    end
    for k,v in pairs(target.loadout) do
        finalWeight = finalWeight + 5
    end

    local rightInventory
    if formatInventory then
        rightInventory = formatInventory(target)
    end
    exports["null-core"]:openInventory({
        name = target.type,
        title = ("%s"):format(ESX.InventoryTypeName[target.type] ~= nil and ESX.InventoryTypeName[target.type] or "Inventaire"),
        weight = finalWeight or 0,
        maxWeight = target.maxWeight ~= -1 and target.maxWeight or 999999999,
        inventory = rightInventory,
        data = { id = target.id, identifier = target.identifier, type = target.type, canMoove = canMoove, isSearch = true },
        literal = target
    })
end)
--]=]

RegisterKeyMapping("openCoffre", "Ouvrir un coffre de véhicule", "keyboard", "L")
RegisterCommand("openCoffre", function ()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(PlayerPedId()) ~= 0 and GetVehiclePedIsIn(PlayerPedId()) or GetClosestVehicle(playerCoords, 7.0, 0, 71)
    --if Entity(vehicle) == nil or Entity(vehicle).state == nil or Entity(vehicle).state.plate == nil then return end

    if not DoesEntityExist(vehicle) then
        return ESX.ShowNotification("Il n'y a pas de véhicule proche", "Erreur")
    end

    local vehiclePos = GetEntityCoords(vehicle)
    local dist = #(playerCoords - vehiclePos)
    local locked = GetVehicleDoorLockStatus(vehicle) 

    if dist > 3 then
        return ESX.ShowNotification("Il n'y a pas de véhicule proche.", "Erreur")
    end

    if locked ~= 1 then
        return ESX.ShowNotification("Ce coffre est fermé", "Erreur")
    end

    local vPlate = GetVehicleNumberPlateText(vehicle)

    if IsPedSittingInAnyVehicle(playerPed) then
        return TriggerServerEvent("inventory:openTarget", plate, ESX.InventoryType.VEHICLE_GLOVE_BOX)
    end

    local vehclass = GetVehicleClass(vehicle)
    local vehMaxWeight = Config.WeightTrunk[vehclass]
    if Config.CustomVehicleWeight[GetEntityModel(vehicle)] then
        vehMaxWeight = Config.CustomVehicleWeight[GetEntityModel(vehicle)]
    end

    ESX.TriggerServerCallback('null:getCoffre', function(data, id, weight)
        if data then
            local inventory = data
            inventory.weight = weight or 0
            inventory.id = id
            inventory.maxWeight = vehMaxWeight
            inventory.type = "VEHICLE"
            TriggerEvent("inventory:openTarget",inventory)
            
        end
    end, vPlate, "trunk", vehMaxWeight)

    --TriggerServerEvent("inventory:openTarget", plate, ESX.InventoryType.VEHICLE, { model = GetEntityModel(vehicle) })
end, false)

AddEventHandler("esx:thread:maxWeight", function()
    local threadmaxWeight = LPH_NO_VIRTUALIZE(function()
        while ESX.GetCurrentWeight() > ESX.GetMaxWeight() do
            Wait(0)
            DrawMissionText('~b~Vous êtes trop lourd, Vos actions sont limité', 1)

            DisablePlayerFiring(PlayerPedId(), true)
            DisableControlAction(0, 21, true)  -- disable sprint
            RageUI.disableKeyFrame(21) -- disable sprint
        end
    end)

    threadmaxWeight()

	DisablePlayerFiring(PlayerPedId(), false)
end)

function DrawMissionText(msg, time)
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(msg)
    DrawSubtitleTimed(time and math.ceil(time) or 0, true)
end


exports("openChest", function(name)
    ESX.TriggerServerCallback('null:getCoffre', function(data, id)
        if data then
            local inventory = data
            inventory.weight = 0
            inventory.id = id
            inventory.maxWeight = 1000
            inventory.type = "SOCIETY"
            TriggerEvent("inventory:openTarget",inventory)
        end
    end, name)
end)
]]