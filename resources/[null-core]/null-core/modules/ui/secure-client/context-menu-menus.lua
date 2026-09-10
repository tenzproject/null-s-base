LastEntityHit = nil
LastCoordsHit = nil
LastEntityType = nil
LastMenuPosition = nil
localCarsOwned = {}
localCarsJobsOwned = {}
localCarsOrgOwned = {}

Action_Config = {
    My = {},
    Ground = {},
    Vehicule = {},
    Player = {},
    Peds = {},
    Object = {},
    Sky = {}
}

function IsAllowed()
    if ESX.PlayerData.group == "user" then return false end
    if not nTable.staffMode then return false end
    return true
end

function HasPermission(perm)
    if not perm then return true end
    local group = ESX.PlayerData.group
    if group == "user" then return false end
    perm = string.lower(perm)
    local requiredGrade = nil
    for k, v in pairs(Config.Admin.PermissionsGrade) do
        if string.lower(k) == perm then
            requiredGrade = v
            break
        end
    end
    if requiredGrade == nil then return false end
    local gradeData = Config.GroupeGrade[group]
    if not gradeData then return false end
    return gradeData.grade >= requiredGrade
end

local function ConvertMenuItem(oldItem)
    local newItems = {}
    
    local isBlocked = false
    if oldItem.Blocked ~= nil then
        if type(oldItem.Blocked) == "function" then
            isBlocked = oldItem.Blocked()
        else
            isBlocked = oldItem.Blocked
        end
    end
    
    if oldItem.IsRestricted and not IsAllowed() then
        return nil
    end
    
    if oldItem.permissions and not HasPermission(oldItem.permissions) then
        return nil
    end
    
    if isBlocked then
        return nil
    end
    
    if oldItem.Type == "buttom" then
        return CreateContextMenuItem('button', oldItem.Label, 'action_' .. tostring(oldItem), {
            closeOnClick = oldItem.CloseOnClick ~= false
        })
        
    elseif oldItem.Type == "checkbox" then
        local isChecked = false
        if oldItem.IsChecked ~= nil then
            if type(oldItem.IsChecked) == "function" then
                isChecked = oldItem.IsChecked()
            else
                isChecked = oldItem.IsChecked
            end
        end
        
        return CreateContextMenuItem('checkbox', oldItem.Label, 'action_' .. tostring(oldItem), {
            checked = isChecked,
            closeOnClick = oldItem.CloseOnClick ~= false
        })
        
    elseif oldItem.Type == "buttom-submenu" then
        local subItems = {}
        if oldItem.Action and type(oldItem.Action) == "table" then
            for _, subAction in ipairs(oldItem.Action) do
                if type(subAction) == "table" and subAction.permissions and not HasPermission(subAction.permissions) then
                    -- Skip items the player doesn't have permission for
                elseif type(subAction) == "table" and subAction[1] then
                    table.insert(subItems, CreateContextMenuItem('button', subAction[1], 'subaction_' .. tostring(subAction)))
                end
            end
        end
        
        if #subItems > 0 then
            return CreateContextMenuItem('submenu', oldItem.Label, nil, {
                items = subItems,
                closeOnClick = oldItem.CloseOnClick ~= false
            })
        end
    end
    
    return nil
end

AddEventHandler('contextmenu:openMenu', function(hitEntity, worldPosition, hitSomething)
    LastEntityHit = hitEntity
    LastCoordsHit = worldPosition
    
    local playerPed = PlayerPedId()
    local items = {}
    local title = "Actions"
    local entityType = nil
    
    if hitEntity and DoesEntityExist(hitEntity) then
        local entType = GetEntityType(hitEntity)
        
        if playerPed == hitEntity then
            title = "Moi"
            entityType = "player"
            if _My then 
                _My() 
            end
            items = BuildMenuFromConfig(Action_Config.My)
            
        elseif entType == 2 then -- Vehicle
            title = "Véhicule"
            entityType = "vehicle"
            if _Vehicule then _Vehicule() end
            items = BuildMenuFromConfig(Action_Config.Vehicule)
            
        elseif entType == 1 and IsPedAPlayer(hitEntity) then -- Player ped
            title = "Joueur"
            entityType = "player"
            if _Player then _Player() end
            items = BuildMenuFromConfig(Action_Config.Player)
            
        elseif entType == 1 then -- NPC ped
            title = "PED"
            entityType = "ped"
            if _Peds then _Peds() end
            items = BuildMenuFromConfig(Action_Config.Peds)
            
        elseif entType == 3 then -- Object
            local objModel = GetEntityModel(hitEntity)
            local isATM = false
            local isTrash = false
            
            local atmModels = {
                [`prop_atm_01`] = true,
                [`prop_atm_02`] = true,
                [`prop_atm_03`] = true,
                [`prop_fleeca_atm`] = true
            }
            
            local trashModels = {
                [`prop_bin_01a`] = true,
                [`prop_bin_02a`] = true,
                [`prop_bin_03a`] = true,
                [`prop_bin_04a`] = true,
                [`prop_bin_05a`] = true,
                [`prop_bin_06a`] = true,
                [`prop_bin_07a`] = true,
                [`prop_bin_07b`] = true,
                [`prop_bin_07c`] = true,
                [`prop_bin_07d`] = true,
                [`prop_bin_08a`] = true,
                [`prop_bin_08open`] = true,
                [`prop_bin_09a`] = true,
                [`prop_bin_10a`] = true,
                [`prop_bin_10b`] = true,
                [`prop_bin_11a`] = true,
                [`prop_bin_11b`] = true,
                [`prop_bin_12a`] = true,
                [`prop_bin_13a`] = true,
                [`prop_bin_14a`] = true,
                [`prop_bin_14b`] = true,
                [`prop_bin_beach_01a`] = true,
                [`prop_bin_beach_01d`] = true,
                [`prop_bin_delpiero`] = true,
                [`prop_recyclebin_01a`] = true,
                [`prop_recyclebin_02a`] = true,
                [`prop_recyclebin_02b`] = true,
                [`prop_recyclebin_02_d`] = true,
                [`prop_recyclebin_03_a`] = true,
                [`prop_recyclebin_04_a`] = true,
                [`prop_recyclebin_04_b`] = true,
                [`prop_recyclebin_05_a`] = true,
                [`prop_dumpster_01a`] = true,
                [`prop_dumpster_02a`] = true,
                [`prop_dumpster_02b`] = true,
                [`prop_dumpster_3a`] = true,
                [`prop_dumpster_4a`] = true,
                [`prop_dumpster_4b`] = true,
                [`zprop_bin_01a_old`] = true
            }
            
            if atmModels[objModel] then
                isATM = true
            elseif trashModels[objModel] then
                isTrash = true
            end
            
            if isATM then
                title = "ATM"
                entityType = "atm"
                if _Atm then _Atm() end
                items = BuildMenuFromConfig(Action_Config.Object)
            elseif isTrash then
                title = "Poubelle"
                entityType = "trash"
                if _Trash then _Trash() end
                items = BuildMenuFromConfig(Action_Config.Object)
            else
                title = "Objet"
                entityType = "object"
                if _Object then _Object() end
                items = BuildMenuFromConfig(Action_Config.Object)
            end
        else
            title = "Sol"
            entityType = "ground"
            if _Ground then 
                _Ground() 
            end
            items = BuildMenuFromConfig(Action_Config.Ground)
        end
    elseif not hitSomething then
        -- Clic dans le ciel (rien touché)
        title = "Ciel"
        entityType = "sky"
        if _sky then
            _sky()
        end
        items = BuildMenuFromConfig(Action_Config.Sky)
    else
        title = "Sol"
        entityType = "ground"
        if _Ground then 
            _Ground() 
        end
        items = BuildMenuFromConfig(Action_Config.Ground)
    end
    
    if #items > 0 then
        LastEntityType = entityType
        
        local cursorX, cursorY = GetNuiCursorPosition()
        local screenWidth, screenHeight = GetActiveScreenResolution()
        local posX = (cursorX / screenWidth) * 1920
        local posY = (cursorY / screenHeight) * 1080
        
        LastMenuPosition = { x = posX, y = posY }
        
        SendNUIMessage({
            action = 'openContextMenu',
            data = {
                title = title,
                items = items,
                position = LastMenuPosition,
                entityType = entityType
            }
        })
        
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    
        StartContextMenuControlsThread()

        TriggerEvent('contextmenu:setOpen', true)
    end
end)

function BuildMenuFromConfig(config)
    if not config then return {} end
    
    local items = {}
    local actionRegistry = {}
    
    for k, v in pairs(config) do
        if v.IsRestricted and not IsAllowed() then
            goto continue
        end
        
        local isBlocked = false
        if v.Blocked ~= nil then
            if type(v.Blocked) == "function" then
                isBlocked = v.Blocked()
            else
                isBlocked = v.Blocked
            end
        end
        
        if isBlocked then
            goto continue
        end
        
        if v.permissions and not HasPermission(v.permissions) then
            goto continue
        end
        
        if v.Type == "buttom" then
            local actionId = 'action_' .. k
            actionRegistry[actionId] = v.OnClick
            
            table.insert(items, CreateContextMenuItem('button', v.Label, actionId, {
                closeOnClick = v.CloseOnClick == true,
                keepNuiFocus = v.KeepNuiFocus == true
            }))
            
        elseif v.Type == "checkbox" then
            local isChecked = false
            if v.IsChecked ~= nil then
                if type(v.IsChecked) == "function" then
                    isChecked = v.IsChecked()
                else
                    isChecked = v.IsChecked
                end
            end
            
            local actionId = 'checkbox_' .. k
            actionRegistry[actionId] = v.OnRelease
            
            table.insert(items, CreateContextMenuItem('checkbox', v.Label, actionId, {
                checked = isChecked,
                closeOnClick = v.CloseOnClick == true
            }))
            
        elseif v.Type == "buttom-submenu" then
            local subItems = {}
            if v.Action and type(v.Action) == "table" then
                for subK, subV in ipairs(v.Action) do
                    if type(subV) == "table" and subV.permissions and not HasPermission(subV.permissions) then
                        -- Skip items the player doesn't have permission for
                    elseif type(subV) == "table" and subV[1] then
                        local subActionId = 'subaction_' .. k .. '_' .. subK
                        actionRegistry[subActionId] = subV[2]
                        
                        table.insert(subItems, CreateContextMenuItem('button', subV[1], subActionId))
                    elseif type(subV) == "table" and subV.Type == "checkbox" then
                        local subIsChecked = false
                        if subV.IsChecked ~= nil then
                            if type(subV.IsChecked) == "function" then
                                subIsChecked = subV.IsChecked()
                            else
                                subIsChecked = subV.IsChecked
                            end
                        end
                        
                        local subActionId = 'subcheckbox_' .. k .. '_' .. subK
                        actionRegistry[subActionId] = subV.OnRelease
                        
                        table.insert(subItems, CreateContextMenuItem('checkbox', subV.Label, subActionId, {
                            checked = subIsChecked
                        }))
                    end
                end
            end
            
            if #subItems > 0 then
                table.insert(items, CreateContextMenuItem('submenu', v.Label, nil, {
                    items = subItems,
                    closeOnClick = v.CloseOnClick ~= false
                }))
            end
        end
        
        ::continue::
    end
    
    -- Stocker le registre des actions
    _G.CurrentActionRegistry = actionRegistry
    
    return items
end

-- Fonction pour rafraîchir le context-menu sans le fermer
function RefreshContextMenu()
    if not LastEntityType then return end
    
    local items = {}
    local title = "Actions"
    
    if LastEntityType == "player" then
        title = "Moi"
        if _My then _My() end
        items = BuildMenuFromConfig(Action_Config.My)
    elseif LastEntityType == "vehicle" then
        title = "Véhicule"
        if _Vehicule then _Vehicule() end
        items = BuildMenuFromConfig(Action_Config.Vehicule)
    elseif LastEntityType == "ped" then
        title = "PED"
        if _Peds then _Peds() end
        items = BuildMenuFromConfig(Action_Config.Peds)
    elseif LastEntityType == "object" then
        title = "Objet"
        if _Object then _Object() end
        items = BuildMenuFromConfig(Action_Config.Object)
    elseif LastEntityType == "sky" then
        title = "Ciel"
        if _sky then _sky() end
        items = BuildMenuFromConfig(Action_Config.Sky)
    elseif LastEntityType == "ground" then
        title = "Sol"
        if _Ground then _Ground() end
        items = BuildMenuFromConfig(Action_Config.Ground)
    end
    
    if #items > 0 then
        SendNUIMessage({
            action = 'updateContextMenu',
            data = {
                title = title,
                items = items,
                position = LastMenuPosition,
                entityType = LastEntityType
            }
        })
    end
end

-- Gestion des actions
AddEventHandler('contextmenu:action', function(action, checked)
    if _G.CurrentActionRegistry and _G.CurrentActionRegistry[action] then
        local callback = _G.CurrentActionRegistry[action]
        if callback then
            if checked ~= nil then
                callback(checked)
            else
                callback()
            end
            
            -- Rafraîchir le menu après l'action pour mettre à jour les checkboxes et items IsRestricted
            Citizen.SetTimeout(50, function()
                RefreshContextMenu()
            end)
        end
    end
end)

-- Charger les fichiers de menus originaux
-- Ces fonctions (_My, _Vehicule, etc.) sont définies dans les fichiers originaux
-- et créent Action_Config avec les menus

null.DebugPrint('Context Menu Système de menus chargé')
