RageUI = {}
RageUI.Menus = {}
RageUI.Menus.__index = RageUI.Menus
RageUI.CurrentMenu = nil
RageUI.NextMenu = nil
RageUI.Options = 0
RageUI.ItemOffset = 0
RageUI.LastControl = false
RageUI.HoldTimer = 0
RageUI.HoldDelay = 150
RageUI.LastDirection = nil

RageUI.CheckboxStyle = {
    Tick = 1,
    Cross = 2
}

RageUI.Badges = {
    None = 0,
    Lock = 1,
    Star = 2,
    Warning = 3,
    Crown = 4,
    Medal = 5,
    Cash = 6,
    Coke = 7,
    Heroin = 8,
    Meth = 9,
    Weed = 10,
    Ammo = 11,
    Armor = 12,
    Barber = 13,
    Clothes = 14,
    Franklin = 15,
    Bike = 16,
    Car = 17,
    Gun = 18,
    Health = 19,
    Makeup = 20,
    Michael = 21,
    Trevor = 22,
}

RageUI.BadgeStyle = {
    None = 0,
    Lock = 1,
    Star = 2,
    Warning = 3,
    Crown = 4,
    Medal = 5,
    Cash = 6,
    Coke = 7,
    Heroin = 8,
    Meth = 9,
    Weed = 10,
    Ammo = 11,
    Armor = 12,
    Barber = 13,
    Clothes = 14,
    Franklin = 15,
    Bike = 16,
    Car = 17,
    Gun = 18,
    Health = 19,
    Makeup = 20,
    Michael = 21,
    Trevor = 22,
    Heart = 23,
    Tick = 24,
    Cross = 25,
    Alert = 26,
    Male = 27,
    Female = 28,
}


RageUI.disabledKeys = {}

function RageUI.setKeyState(key, state)
    if RageUI.disabledKeys[key] == nil then
        RageUI.disabledKeys[key] = state
    else
        if state == true then
            RageUI.disabledKeys[key] = true
        else
            RageUI.disabledKeys[key] = nil
        end
    end
end

function RageUI.disableKeyFrame(key)
    RageUI.setKeyState(key, true)
    CreateThread(function()
        Wait(0)
        RageUI.setKeyState(key, false)
    end)
end

Keys = {}
Keys._bindings = {}

function Keys.Register(key, name, description, callback)
    if callback then
        RegisterCommand(name, function()
            callback()
        end, false)
        RegisterKeyMapping(name, description or name, "keyboard", key)
        Keys._bindings[name] = { key = key, callback = callback }
    end
end

function RageUI.GetInMenu()
    return RageUI.CurrentMenu == nil
end

RageUI._Render = {
    Active = false,
    CurrentItems = {},
    LastHash = nil,
    PendingRefresh = false
}

RageUI.Settings = {
    Audio = {
        Use = "RageUI",
        RageUI = {
            UpDown = { audioName = "NAV_UP_DOWN", audioRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
            LeftRight = { audioName = "NAV_LEFT_RIGHT", audioRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
            Select = { audioName = "SELECT", audioRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
            Back = { audioName = "BACK", audioRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
            Error = { audioName = "ERROR", audioRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
        }
    },
    Controls = {
        Up = { Enabled = true, Keys = { { 0, 172 }} },
        Down = { Enabled = true, Keys = { { 0, 173 }} },
        Left = { Enabled = true, Keys = { { 0, 174 }} },
        Right = { Enabled = true, Keys = { { 0, 175 }} },
        Select = { Enabled = true, Keys = { { 0, 201 }, { 0, 176 }, { 0, 191 }} },
        Back = { Enabled = true, Keys = { { 0, 202 }, { 0, 177 }} },
    }
}

function RageUI.PlaySound(audioName, audioRef)
    --PlaySoundFrontend(-1, audioName, audioRef, true)
end

function RageUI.SendNUI(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

Citizen.CreateThread(function()
    Wait(100)
    SendNUIMessage({
        action = "setConfig",
        defaultPosition = {
            x = Config.NykzUI.DefaultPosition.X,
            y = Config.NykzUI.DefaultPosition.Y
        }
    })
end)

RageUI.IsVisible = LPH_NO_VIRTUALIZE(function(menu, callback)
    if menu == nil or not menu.Open or RageUI.CurrentMenu ~= menu then
        return false
    end
    
    if callback then
        RageUI._Render.Active = true
        RageUI._Render.CurrentItems = {}
        
        local ok, err = pcall(callback)
        
        RageUI._Render.Active = false
        
        if not ok then
            print("^1[RageUI] Erreur dans IsVisible callback: " .. tostring(err) .. "^0")
            return true
        end
        
        local hash = RageUI._ComputeHash(RageUI._Render.CurrentItems)
        local indexHash = tostring(menu.Index)
        local fullHash = hash .. "|" .. indexHash
        
        if fullHash ~= menu._lastHash then
            menu._lastHash = fullHash
            menu.Items = RageUI._Render.CurrentItems
            menu:Refresh()
        end
    end
    return true
end)

RageUI.Visible = LPH_NO_VIRTUALIZE(function(menu, visible)
    if menu == nil then
        return false
    end
    
    if visible == nil then
        return menu.Open
    end
    
    if visible then
        -- Fermer le menu actuel proprement si un autre est ouvert (comme l'ancien RageUI)
        local isTransition = false
        if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu ~= menu then
            local oldMenu = RageUI.CurrentMenu
            oldMenu.Open = false
            oldMenu._lastHash = nil
            isTransition = true
            -- NE PAS envoyer closeMenu au NUI ici, openMenu va le remplacer directement
        end
        
        menu.Open = true
        RageUI.CurrentMenu = menu
        menu._lastHash = nil 
        menu.Items = {}
        RageUI.SendNUI("openMenu", {
            title = menu.Title,
            subtitle = menu.Subtitle,
            position = { x = menu.X, y = menu.Y },
            maxVisibleItems = menu.MaxVisibleItems,
            transition = isTransition and "forward" or nil
        })
    else
        menu.Open = false
        menu._lastHash = nil
        if RageUI.CurrentMenu == menu then
            RageUI.CurrentMenu = nil
            RageUI.SendNUI("closeMenu", {})
        end
    end
    
    return menu.Open
end)

function RageUI.CloseAll()
    if RageUI.CurrentMenu ~= nil then
        local currentMenu = RageUI.CurrentMenu
        -- Remonter la chaîne de parents et reset tous les menus (comme l'ancien RageUI)
        local parent = currentMenu.Parent
        while parent ~= nil do
            parent.Open = false
            parent._lastHash = nil
            parent.Index = 1
            parent = parent.Parent
        end
        currentMenu.Open = false
        currentMenu._lastHash = nil
        currentMenu.Index = 1
        
        RageUI.CurrentMenu = nil
    end
    RageUI._Render.Active = false
    RageUI._Render.LastHash = nil
    RageUI._Render.CurrentItems = {}
    RageUI.SendNUI("closeMenu", {})
    
    RageUI.SetCursor(false)
end

RageUI.GoBack = LPH_NO_VIRTUALIZE(function()
    if RageUI.CurrentMenu ~= nil then
        if RageUI.CurrentMenu.Closable == false then
            return
        end
        
        local parent = RageUI.CurrentMenu.Parent
        local currentMenu = RageUI.CurrentMenu
        currentMenu.Open = false
        currentMenu._lastHash = nil
        
        if parent ~= nil then
            -- Appeler le callback Closed du sous-menu quand on revient au parent
            if currentMenu.Closed then
                local ok, err = pcall(currentMenu.Closed)
                if not ok then
                    print("^1[RageUI] Erreur dans Closed callback (submenu): " .. tostring(err) .. "^0")
                end
            end
            
            parent.Open = true
            parent._lastHash = nil 
            parent.Items = {}
            RageUI.CurrentMenu = parent
            RageUI.SendNUI("openMenu", {
                title = parent.Title,
                subtitle = parent.Subtitle,
                position = { x = parent.X, y = parent.Y },
                maxVisibleItems = parent.MaxVisibleItems,
                transition = "back"
            })
        else
            RageUI.CurrentMenu = nil
            RageUI.SendNUI("closeMenu", {})
            if currentMenu.Closed then
                local ok, err = pcall(currentMenu.Closed)
                if not ok then
                    print("^1[RageUI] Erreur dans Closed callback: " .. tostring(err) .. "^0")
                end
            end
        end
        local Audio = RageUI.Settings.Audio
        RageUI.PlaySound(Audio[Audio.Use].Back.audioName, Audio[Audio.Use].Back.audioRef)
    end
end)

setmetatable(RageUI.Menus, {
    __call = function(Table)
        if Table.Open then
            return true
        else
            return false
        end
    end,
})

RageUI.CursorActive = false

local DISABLED_CONTROLS_MENU = { 199, 200, 140, 141, 142, 257, 263, 264 }
local DISABLED_CONTROLS_MENU_NO_CURSOR = { 24, 25 }
local DISABLED_CONTROLS_CURSOR = { 30, 31, 32, 33, 34, 35, 21, 22, 36, 44, 1, 2, 270, 271, 272, 273 }

local AudioSettings = RageUI.Settings.Audio

local function PlayNavSound(soundType)
    local audio = AudioSettings[AudioSettings.Use][soundType]
    if audio then
        PlaySoundFrontend(-1, audio.audioName, audio.audioRef, true)
    end
end

local function IsKeyJustPressed(keys)
    for _, key in pairs(keys) do
        if IsDisabledControlJustPressed(key[1], key[2]) or IsControlJustPressed(key[1], key[2]) then
            return true
        end
    end
    return false
end

local function IsKeyPressed(keys)
    for _, key in pairs(keys) do
        if IsDisabledControlPressed(key[1], key[2]) or IsControlPressed(key[1], key[2]) then
            return true, key
        end
    end
    return false, nil
end

local function DisableControls(controls)
    for _, control in ipairs(controls) do
        DisableControlAction(0, control, true)
    end
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    local Controls = RageUI.Settings.Controls
    
    while true do
        Citizen.Wait(0)
        
        if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu.Open then
            local currentTime = GetGameTimer()
            
	            DisableControls(DISABLED_CONTROLS_MENU)
	            DisableControlAction(0, 201, true)
	            DisableControlAction(1, 176, true)
	            DisableControlAction(2, 176, true)
	            DisableControlAction(0, 202, true)
	            DisableControlAction(1, 177, true)
	            DisableControlAction(2, 177, true)
            
            if RageUI.CursorActive then
                DisableControls(DISABLED_CONTROLS_CURSOR)
            else
                DisableControls(DISABLED_CONTROLS_MENU_NO_CURSOR)
            end
            
            local isHoldingUp, _ = IsKeyPressed(Controls.Up.Keys)
            local isHoldingDown, _ = IsKeyPressed(Controls.Down.Keys)
            
            if isHoldingUp then
                if IsKeyJustPressed(Controls.Up.Keys) then
                    RageUI.SendNUI("navigate", { direction = "up" })
                    PlayNavSound("UpDown")
                    RageUI.HoldTimer = currentTime
                    RageUI.LastDirection = "up"
                    RageUI.HoldDelay = 140
                elseif RageUI.LastDirection == "up" and (currentTime - RageUI.HoldTimer) >= RageUI.HoldDelay then
                    RageUI.SendNUI("navigate", { direction = "up" })
                    PlayNavSound("UpDown")
                    RageUI.HoldTimer = currentTime
                    RageUI.HoldDelay = math.max(90, RageUI.HoldDelay - 20)
                end
            elseif isHoldingDown then
                if IsKeyJustPressed(Controls.Down.Keys) then
                    RageUI.SendNUI("navigate", { direction = "down" })
                    PlayNavSound("UpDown")
                    RageUI.HoldTimer = currentTime
                    RageUI.LastDirection = "down"
                    RageUI.HoldDelay = 140
                elseif RageUI.LastDirection == "down" and (currentTime - RageUI.HoldTimer) >= RageUI.HoldDelay then
                    RageUI.SendNUI("navigate", { direction = "down" })
                    PlayNavSound("UpDown")
                    RageUI.HoldTimer = currentTime
                    RageUI.HoldDelay = math.max(90, RageUI.HoldDelay - 20)
                end
            elseif RageUI.LastDirection == "up" or RageUI.LastDirection == "down" then
                RageUI.LastDirection = nil
                RageUI.HoldDelay = 140
            end
            
            local isHoldingLeft, _ = IsKeyPressed(Controls.Left.Keys)
            local isHoldingRight, _ = IsKeyPressed(Controls.Right.Keys)

            if isHoldingLeft then
                if IsKeyJustPressed(Controls.Left.Keys) then
                    RageUI.SendNUI("navigate", { direction = "left" })
                    PlayNavSound("LeftRight")
                    RageUI.HoldTimer = currentTime
                    RageUI.LastDirection = "left"
                    RageUI.HoldDelay = 140
                elseif RageUI.LastDirection == "left" and (currentTime - RageUI.HoldTimer) >= RageUI.HoldDelay then
                    RageUI.SendNUI("navigate", { direction = "left" })
                    PlayNavSound("LeftRight")
                    RageUI.HoldTimer = currentTime
                    RageUI.HoldDelay = math.max(40, RageUI.HoldDelay - 20)
                end
            elseif isHoldingRight then
                if IsKeyJustPressed(Controls.Right.Keys) then
                    RageUI.SendNUI("navigate", { direction = "right" })
                    PlayNavSound("LeftRight")
                    RageUI.HoldTimer = currentTime
                    RageUI.LastDirection = "right"
                    RageUI.HoldDelay = 140
                elseif RageUI.LastDirection == "right" and (currentTime - RageUI.HoldTimer) >= RageUI.HoldDelay then
                    RageUI.SendNUI("navigate", { direction = "right" })
                    PlayNavSound("LeftRight")
                    RageUI.HoldTimer = currentTime
                    RageUI.HoldDelay = math.max(40, RageUI.HoldDelay - 20)
                end
            elseif RageUI.LastDirection == "left" or RageUI.LastDirection == "right" then
                RageUI.LastDirection = nil
                RageUI.HoldDelay = 140
            end
            
            local isMouseClick = IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 25)
            
            if not isMouseClick then
                if IsKeyJustPressed(Controls.Select.Keys) then
                    RageUI.SendNUI("select", {})
                    PlayNavSound("Select")
                elseif IsKeyJustPressed(Controls.Back.Keys) then
                    RageUI.GoBack()
                end
            end
        end
    end
end))

RegisterNUICallback('itemSelected', function(data, cb)
    if RageUI.CurrentMenu ~= nil and data and data.index ~= nil then
        RageUI.CurrentMenu.Index = data.index + 1
        local item = RageUI.CurrentMenu.Items[data.index + 1]
        if item and item.onSelected then
            local ok, err = pcall(item.onSelected, data.value)
            if not ok then
                print("^1[RageUI] Erreur dans onSelected callback: " .. tostring(err) .. "^0")
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('itemChanged', function(data, cb)
    if RageUI.CurrentMenu ~= nil and data and data.index ~= nil then
        RageUI.CurrentMenu.Index = data.index + 1
        local item = RageUI.CurrentMenu.Items[data.index + 1]
        if item and item.onChanged then
            local ok, err = pcall(item.onChanged, data.value)
            if not ok then
                print("^1[RageUI] Erreur dans onChanged callback: " .. tostring(err) .. "^0")
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('indexChanged', function(data, cb)
    if RageUI.CurrentMenu ~= nil then
        RageUI.CurrentMenu.Index = data.index + 1
    end
    cb('ok')
end)

RegisterNUICallback('menuClosed', function(data, cb)
    if RageUI.CurrentMenu ~= nil then
        if RageUI.CurrentMenu.Closable == false then
            cb('ok')
            return
        end
        
        local currentMenu = RageUI.CurrentMenu
        currentMenu.Open = false
        currentMenu._lastHash = nil
        RageUI.CurrentMenu = nil
        
        if currentMenu.Closed then
            local ok, err = pcall(currentMenu.Closed)
            if not ok then
                print("^1[RageUI] Erreur dans Closed callback: " .. tostring(err) .. "^0")
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('panelChanged', function(data, cb)
    if RageUI.CurrentMenu ~= nil and data then
        local panelType = data.type
        local ok, err
        
        if panelType == 'color' then
            if RageUI.CurrentMenu._colorPanelCallback then
                ok, err = pcall(RageUI.CurrentMenu._colorPanelCallback, data.color)
                if not ok then print("^1[RageUI] Erreur dans colorPanel callback: " .. tostring(err) .. "^0") end
            end
        elseif panelType == 'grid' then
            if RageUI.CurrentMenu._gridPanelCallback then
                ok, err = pcall(RageUI.CurrentMenu._gridPanelCallback, data.x, data.y)
                if not ok then print("^1[RageUI] Erreur dans gridPanel callback: " .. tostring(err) .. "^0") end
            end
        elseif panelType == 'image' then
            if RageUI.CurrentMenu._imagePanelCallback then
                ok, err = pcall(RageUI.CurrentMenu._imagePanelCallback, data.action)
                if not ok then print("^1[RageUI] Erreur dans imagePanel callback: " .. tostring(err) .. "^0") end
            end
        elseif panelType == 'imageselector' then
            if RageUI.CurrentMenu._imageSelectorCallback then
                ok, err = pcall(RageUI.CurrentMenu._imageSelectorCallback, data.index + 1, data.image)
                if not ok then print("^1[RageUI] Erreur dans imageSelector callback: " .. tostring(err) .. "^0") end
            end
        end
    end
    cb('ok')
end)

RegisterNUICallback('collapsibleItemSelected', function(data, cb)
    if RageUI.CurrentMenu ~= nil and data and data.parentIndex ~= nil and data.childIndex ~= nil then
        local parentIndex = data.parentIndex + 1
        local childIndex = data.childIndex + 1
        
        if RageUI.CurrentMenu._collapsibleCallbacks and RageUI.CurrentMenu._collapsibleCallbacks[parentIndex] then
            local callbacks = RageUI.CurrentMenu._collapsibleCallbacks[parentIndex]
            if callbacks[childIndex] then
                local ok, err = pcall(callbacks[childIndex])
                if not ok then
                    print("^1[RageUI] Erreur dans collapsible callback: " .. tostring(err) .. "^0")
                end
            end
        end
    end
    cb('ok')
end)

RageUI.BeginRender = LPH_NO_VIRTUALIZE(function(menu)
    if menu == nil or not menu.Open then
        return false
    end
    
    RageUI.CurrentMenu = menu
    RageUI._Render.Active = true
    RageUI._Render.CurrentItems = {}
    return true
end)

RageUI.EndRender = LPH_NO_VIRTUALIZE(function()
    if not RageUI._Render.Active then
        return
    end
    
    RageUI._Render.Active = false
    
    local menu = RageUI.CurrentMenu
    if menu == nil then
        return
    end
    
    local hash = RageUI._ComputeHash(RageUI._Render.CurrentItems)
    
    if hash ~= RageUI._Render.LastHash or RageUI._Render.PendingRefresh then
        RageUI._Render.LastHash = hash
        RageUI._Render.PendingRefresh = false
        menu.Items = RageUI._Render.CurrentItems
        menu:Refresh()
    end
end)

RageUI._ComputeHash = LPH_NO_VIRTUALIZE(function(items)
    local parts = {}
    for i, item in ipairs(items) do
        parts[#parts + 1] = item.type or ""
        parts[#parts + 1] = item.label or ""
        parts[#parts + 1] = tostring(item.enabled)
        parts[#parts + 1] = tostring(item.value or "")
        parts[#parts + 1] = tostring(item.checked or "")
        parts[#parts + 1] = item.rightLabel or ""
        if item.items then
            for _, v in ipairs(item.items) do
                parts[#parts + 1] = tostring(v)
            end
        end
        if item.leftItems then
            for _, v in ipairs(item.leftItems) do
                parts[#parts + 1] = tostring(v)
            end
        end
        if item.rightItems then
            for _, v in ipairs(item.rightItems) do
                parts[#parts + 1] = tostring(v)
            end
        end
    end
    return table.concat(parts, "|")
end)

RageUI._AddRenderItem = LPH_NO_VIRTUALIZE(function(item)
    if RageUI._Render.Active then
        table.insert(RageUI._Render.CurrentItems, item)
    elseif RageUI.CurrentMenu ~= nil then
        RageUI.CurrentMenu:AddItem(item)
    end
end)

function RageUI.RequestRefresh()
    RageUI._Render.PendingRefresh = true
end

function RageUI.SetCursor(enabled)
    RageUI.CursorActive = enabled
    RageUI.SendNUI("setCursor", { enabled = enabled })
    SetNuiFocus(enabled, enabled)
    if enabled then
        SetNuiFocusKeepInput(true) 
    end
end

function RageUI.Popup(options)
    if options and options.message then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(options.message)
        else
            SetNotificationTextEntry("STRING")
            AddTextComponentString(options.message)
            DrawNotification(false, false)
        end
    end
end

-- Item Grid Panel
RageUI._itemGridCallback = nil
RageUI._itemGridOpen = false

function RageUI.OpenItemGrid(config)
    -- config = { items = {}, title = "", mode = "item"|"weapon"|"vehicle", callback = function(data) end }
    RageUI._itemGridCallback = config.callback
    RageUI._itemGridOpen = true
    RageUI.SendNUI("openItemGrid", {
        items = config.items,
        title = config.title or "Sélectionner",
        mode = config.mode or "item"
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
end

function RageUI.CloseItemGrid()
    RageUI._itemGridOpen = false
    RageUI._itemGridCallback = nil
    RageUI.SendNUI("closeItemGrid", {})
    if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu.Open then
        if RageUI.CursorActive then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
        else
            SetNuiFocus(false, false)
        end
    else
        SetNuiFocus(false, false)
    end
end

RegisterNUICallback('itemGridSelected', function(data, cb)
    local callback = RageUI._itemGridCallback
    RageUI._itemGridOpen = false
    RageUI._itemGridCallback = nil
    RageUI.SendNUI("closeItemGrid", {})
    if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu.Open then
        if RageUI.CursorActive then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
        else
            SetNuiFocus(false, false)
        end
    else
        SetNuiFocus(false, false)
    end
    if callback and data then
        local ok, err = pcall(callback, data)
        if not ok then
            print("^1[RageUI] Erreur dans itemGrid callback: " .. tostring(err) .. "^0")
        end
    end
    cb('ok')
end)

RegisterNUICallback('itemGridClosed', function(data, cb)
    RageUI._itemGridOpen = false
    RageUI._itemGridCallback = nil
    RageUI.SendNUI("closeItemGrid", {})
    if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu.Open then
        if RageUI.CursorActive then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)
        else
            SetNuiFocus(false, false)
        end
    else
        SetNuiFocus(false, false)
    end
    cb('ok')
end)

RMenu = {}
RMenu._Menus = {}

function RMenu.Add(namespace, name, menu)
    if not RMenu._Menus[namespace] then
        RMenu._Menus[namespace] = {}
    end
    RMenu._Menus[namespace][name] = menu
end

function RMenu:Get(namespace, name)
    if RMenu._Menus[namespace] and RMenu._Menus[namespace][name] then
        return RMenu._Menus[namespace][name]
    end
    return nil
end

function RMenu:GetAll(namespace)
    return RMenu._Menus[namespace] or {}
end

function RMenu:Delete(namespace, name)
    if RMenu._Menus[namespace] and RMenu._Menus[namespace][name] then
        RMenu._Menus[namespace][name] = nil
    end
end

function RMenu:DeleteAll(namespace)
    RMenu._Menus[namespace] = nil
end

function RMenu:DeleteType(name)
    for namespace, menus in pairs(RMenu._Menus) do
        for menuName, menu in pairs(menus) do
            if menuName == name or menu == name then
                RMenu._Menus[namespace][menuName] = nil
                if menu and type(menu) == "table" then
                    if menu.Open then
                        RageUI.Visible(menu, false)
                    end
                end
                return nil
            end
        end
    end
    return nil
end
