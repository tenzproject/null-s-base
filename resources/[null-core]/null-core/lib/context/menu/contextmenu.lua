function IsAllowed()
    if ESX.PlayerData.group == "user" then return false end
    if not nTable.staffMode then return false end
    return true
end

local menuPool = MenuPool()
local selectedWorldPosition = nil
local checkboxStates = {}
local subcheckboxStates = {}
local currentEntity = nil

EnableEditorRuntime()

menuPool.OnOpenMenu = function(screenPosition, hitSomething, worldPosition, hitEntity, normalDirection)
    local entityType = GetEntityType(hitEntity)
    CreateMenu(screenPosition, worldPosition, entityType, hitEntity, materialHash)
end

menuPool.CustomProcess = function()
    if selectedWorldPosition then
        DrawMarker(28, selectedWorldPosition.x, selectedWorldPosition.y, selectedWorldPosition.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 100, false, true, 2, nil, nil, true)
    end
    if SelectedEntity then
        local entityType = GetEntityType(SelectedEntity)
        DrawMarker(0, GetPedBoneCoords(SelectedEntity, 31086, 0.7, 0.0, 0.0), 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 0, 255, 20, 0, 0, 0, 0, 0, 0, 0)
    end
    if currentEntity then
        local entityType = GetEntityType(currentEntity)
        if entityType == 1 then
            DrawMarker(0, GetPedBoneCoords(currentEntity, 31086, 0.7, 0.0, 0.0), 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 255, 255, 255, 20, 0, 0, 0, 0, 0, 0, 0)
        end
    end
end

menuPool.OnCloseMenu = function()
    if not EditWithGizmo then
        EditEntity = nil
    end
    menuPool.buttonPressed = false
end

function CloseAllMenu()
    menuPool:CloseAllMenus()
end

function CreateMenu(screenPosition, worldPosition, entityType, hitEntity, materialHash)
    _G.LastEntityHit = hitEntity
    _G.LastCoordsHit = worldPosition
    local playerPed = PlayerPedId()
    local isInAnyVehicle = IsPedInAnyVehicle(playerPed, true)
    local currentVehicle = 0
    menuPool:Reset()
    local contextMenu = menuPool:AddMenu()
    currentEntity = hitEntity
    contextMenu.OnClosed = function()
        currentEntity = nil
    end
    contextMenu.alpha = 150
    contextMenu.colors.border = Color(0, 0, 0, 0)
    if hitEntity ~= nil and DoesEntityExist(hitEntity) then
        _My()
        if playerPed == hitEntity then
            for k,v in pairs(Action_Config.My) do 
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.Type == "buttom" then 
                    local item = contextMenu:AddItem(v.Label)
                    v.EntityHit = hitEntity
                    item.OnRelease = v.OnClick
                    item.closeMenuOnRelease = v.CloseOnClick
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end
                elseif v.Type == "checkbox" then
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  
                
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
            end
        elseif IsEntityAVehicle(hitEntity) then
            _Vehicule()
            for k,v in pairs(Action_Config.Vehicule) do 
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.Type == "buttom" then 
                    local item = contextMenu:AddItem(v.Label)
                    v.EntityHit = hitEntity
                    item.OnRelease = v.OnClick
                    item.closeMenuOnRelease = v.CloseOnClick
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end
                elseif v.Type == "checkbox" then
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  
                
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
            end
        elseif IsEntityAPed(hitEntity) and IsPedAPlayer(hitEntity) then
                _Player()
                for k,v in pairs(Action_Config.Player) do 
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.Type == "buttom" then 
                    local item = contextMenu:AddItem(v.Label)
                    v.EntityHit = hitEntity
                    item.OnRelease = v.OnClick
                    item.closeMenuOnRelease = v.CloseOnClick
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end
                elseif v.Type == "checkbox" then
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  
                
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
         
        end
        elseif IsEntityAPed(hitEntity) then
            _Peds()
            for k,v in pairs(Action_Config.Peds) do 
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.Type == "buttom" then 
                    local item = contextMenu:AddItem(v.Label)
                    v.EntityHit = hitEntity
                    item.OnRelease = v.OnClick
                    item.closeMenuOnRelease = v.CloseOnClick
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end
                elseif v.Type == "checkbox" then
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  
                
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
            end
        elseif IsEntityAnObject(hitEntity) then
            local Found = false
            local atmList = {
                "prop_atm_01",
                "prop_atm_02",
                "prop_atm_03",
                "prop_fleeca_atm"
            }
            local obj = GetEntityModel(hitEntity)
            print("[DEBUG] Object detected, model hash: " .. obj)
            for k,v in pairs(atmList) do
                print("[DEBUG] Checking ATM: " .. v .. " hash: " .. GetHashKey(v))
                if obj == GetHashKey(v) then
                    Found = true
                    print("[DEBUG] ATM FOUND! Calling _Atm()")
                    _Atm()
                    break
                end
            end
            if not Found then
                print("[DEBUG] Not an ATM, calling _Object()")
                _Object()
            end
            for k,v in pairs(Action_Config.Object) do 
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.Type == "buttom" then 
                    if not v.Blocked then
                        local item = contextMenu:AddItem(v.Label)
                        v.EntityHit = hitEntity
                        item.OnRelease = v.OnClick
                        item.closeMenuOnRelease = v.CloseOnClick
                    end
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end
                elseif v.Type == "checkbox" then
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  
                
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
            end
        else
            _Ground()
            for k,v in pairs(Action_Config.Ground) do 
                if v.permissions then
                    if not ESX.HasPermissions(v.permissions) then
                        goto pass
                    end
                end
                if v.IsRestricted then 
                    if not IsAllowed() then 
                        goto pass
                    end
                end
                if v.Blocked then 
                    goto pass 
                end
                if v.Type == "buttom" then 
                    local item = contextMenu:AddItem(v.Label)
                    v.EntityHit = hitEntity
                    item.OnRelease = v.OnClick
                    item.closeMenuOnRelease = v.CloseOnClick
                elseif v.Type == "buttom-submenu" then
                    -- Crée un sous-menu principal pour l'élément courant
                    local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                    
                    -- Parcourt les actions pour chaque item dans le sous-menu
                    for _, action in pairs(v.Action) do
                        if action.permissions then
                            if not ESX.HasPermissions(action.permissions) then
                                goto passaction
                            end
                        end
                        -- Si l'action est une checkbox
                        if action.Type == "checkbox" then
                            -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                            local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
                
                            -- Crée la checkbox avec l'état initial
                            local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
                
                            -- Sauvegarde l'état actuel lorsque la valeur change
                            checkboxItem.OnValueChanged = function(isChecked)
                                subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                                -- Exécute la fonction OnRelease si elle est définie
                                if action.OnRelease then
                                    action.OnRelease(isChecked)
                                end
                            end
                
                            -- Définit si le menu doit se fermer après un clic
                            checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                        -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                        elseif action[3] then
                            -- Créer un sous-sous-menu associé à ce sous-item
                            local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                            -- Ajoute immédiatement les éléments du sous-sous-menu
                            for _, subAction in pairs(action[3]) do
                                local subSubItem = subSubMenu:AddItem(subAction[1])
                                subSubItem.OnRelease = subAction[2]
                                subSubItem.closeMenuOnRelease = v.CloseOnClick
                            end
                        else
                            -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                            local subItem = subMenu:AddItem(action[1])
                            subItem.OnRelease = action[2]
                            subItem.closeMenuOnRelease = v.CloseOnClick
                        end
                        ::passaction::
                    end         
                elseif v.Type == "checkbox" then
                    -- Vérifie si l'état de la checkbox existe dans la table des états, sinon utilise la valeur par défaut
                    local initialState = checkboxStates[v.Label] or v.IsChecked or false
                
                    -- Crée la checkbox avec l'état initial
                    local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
                
                    -- Sauvegarde l'état actuel lorsque la valeur change
                    checkboxItem.OnValueChanged = function(isChecked)
                        checkboxStates[v.Label] = isChecked  -- Met à jour l'état dans la table globale
                
                        -- Exécute la fonction OnRelease si elle est définie
                        if v.OnRelease then
                            v.OnRelease(isChecked)
                        end
                    end
                
                    -- Définit si le menu doit se fermer après un clic
                    checkboxItem.closeMenuOnClick = v.CloseOnClick or false
                end
                :: pass ::
            end
        end
    else
        _sky()
        for k,v in pairs(Action_Config.Sky) do 
            if v.permissions then
                if not ESX.HasPermissions(v.permissions) then
                    goto pass
                end
            end
            if v.IsRestricted then 
                if not IsAllowed() then 
                    goto pass
                end
            end
            if v.Blocked then 
                goto pass 
            end
            if v.Type == "buttom" then 
                local item = contextMenu:AddItem(v.Label)
                v.EntityHit = hitEntity
                item.OnRelease = v.OnClick
                item.closeMenuOnRelease = v.CloseOnClick
            elseif v.Type == "buttom-submenu" then
                -- Crée un sous-menu principal pour l'élément courant
                local subMenu = menuPool:AddSubmenu(contextMenu, v.Label)
                
                -- Parcourt les actions pour chaque item dans le sous-menu
                for _, action in pairs(v.Action) do
                    if action.permissions then
                        if not ESX.HasPermissions(action.permissions) then
                            goto passaction
                        end
                    end
                    -- Si l'action est une checkbox
                    if action.Type == "checkbox" then
                        -- Récupère l'état mémorisé de la checkbox ou utilise sa valeur par défaut
                        local initialState = subcheckboxStates[action.Label] or action.IsChecked or false
            
                        -- Crée la checkbox avec l'état initial
                        local checkboxItem = subMenu:AddCheckboxItem(action.Label, initialState)
            
                        -- Sauvegarde l'état actuel lorsque la valeur change
                        checkboxItem.OnValueChanged = function(isChecked)
                            subcheckboxStates[action.Label] = isChecked  -- Met à jour l'état dans la table globale
            
                            -- Exécute la fonction OnRelease si elle est définie
                            if action.OnRelease then
                                action.OnRelease(isChecked)
                            end
                        end
            
                        -- Définit si le menu doit se fermer après un clic
                        checkboxItem.closeMenuOnClick = action.CloseOnClick or false
                    -- Si l'action contient un sous-menu imbriqué (action[3]), on le crée immédiatement
                    elseif action[3] then
                        -- Créer un sous-sous-menu associé à ce sous-item
                        local subSubMenu = menuPool:AddSubmenu(subMenu, action[1])  -- Ajoute le sous-sous-menu au sous-menu parent
                        -- Ajoute immédiatement les éléments du sous-sous-menu
                        for _, subAction in pairs(action[3]) do
                            local subSubItem = subSubMenu:AddItem(subAction[1])
                            subSubItem.OnRelease = subAction[2]
                            subSubItem.closeMenuOnRelease = v.CloseOnClick
                        end
                    else
                        -- Si ce n'est pas une checkbox ou un sous-sous-menu, exécute simplement l'action
                        local subItem = subMenu:AddItem(action[1])
                        subItem.OnRelease = action[2]
                        subItem.closeMenuOnRelease = v.CloseOnClick
                    end
                    ::passaction::
                end
            elseif v.Type == "checkbox" then
                local initialState = checkboxStates[v.Label] or v.IsChecked or false
            
                local checkboxItem = contextMenu:AddCheckboxItem(v.Label, initialState)
            
                checkboxItem.OnValueChanged = function(isChecked)
                    checkboxStates[v.Label] = isChecked  
            
                    if v.OnRelease then
                        v.OnRelease(isChecked)
                    end
                end
            
                checkboxItem.closeMenuOnClick = v.CloseOnClick or false
            end
            
            :: pass ::
        end
    end
    contextMenu:SetPosition(screenPosition)
    contextMenu:Visible(true)
end
Citizen.CreateThread((function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(1, 19) then -- 19 is the control ID for ALT key   
            menuPool:CloseAllMenus()
        end
    end
end))