RageUI._CollapsibleStates = {}

RageUI.SetCollapsibleState = LPH_NO_VIRTUALIZE(function(Label, Collapsed)
    if RageUI.CurrentMenu ~= nil then
        local menu = RageUI.CurrentMenu
        local stateKey = menu.Title .. "_" .. Label
        RageUI._CollapsibleStates[stateKey] = Collapsed
        menu._lastHash = nil
        menu:Refresh()
    end
end)

RageUI.ToggleCollapsibleState = LPH_NO_VIRTUALIZE(function(Label)
    if RageUI.CurrentMenu ~= nil then
        local menu = RageUI.CurrentMenu
        local stateKey = menu.Title .. "_" .. Label
        RageUI._CollapsibleStates[stateKey] = not RageUI._CollapsibleStates[stateKey]
        menu._lastHash = nil
        menu:Refresh()
    end
end)

RageUI.SetAllCollapsibleStates = LPH_NO_VIRTUALIZE(function(Collapsed)
    if RageUI.CurrentMenu ~= nil then
        local menu = RageUI.CurrentMenu
        for key, _ in pairs(RageUI._CollapsibleStates) do
            if string.sub(key, 1, #menu.Title + 1) == menu.Title .. "_" then
                RageUI._CollapsibleStates[key] = Collapsed
            end
        end
        menu._lastHash = nil
        menu:Refresh()
    end
end)

RageUI.Collapsible = LPH_NO_VIRTUALIZE(function(Label, Description, Collapsed, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local menu = RageUI.CurrentMenu
        if not menu then return end
        
        local stateKey = menu.Title .. "_" .. Label
        
        if RageUI._CollapsibleStates[stateKey] == nil then
            RageUI._CollapsibleStates[stateKey] = Collapsed or false
        end
        
        local isCollapsed = RageUI._CollapsibleStates[stateKey]
        local currentItemIndex = #RageUI._Render.CurrentItems + 1
        
        local headerItem = {
            type = "collapsible",
            label = Label or "",
            description = Description or "",
            rightLabel = "",
            enabled = true,
            collapsed = isCollapsed,
            collapsibleItems = {},
            _isHeader = true,
            _stateKey = stateKey,
            onSelected = function()
                RageUI._CollapsibleStates[stateKey] = not RageUI._CollapsibleStates[stateKey]
                menu._lastHash = nil
                menu:Refresh()
            end
        }
        
        RageUI._AddRenderItem(headerItem)
        
        if not isCollapsed and Callback and type(Callback) == "function" then
            local previousRenderState = RageUI._Render.Active
            local previousItems = RageUI._Render.CurrentItems
            local collapsibleItems = {}
            
            RageUI._Render.CurrentItems = collapsibleItems
            RageUI._Render.Active = true
            RageUI._Render._InsideCollapsible = true
            
            Callback()
            
            RageUI._Render._InsideCollapsible = false
            RageUI._Render.Active = previousRenderState
            
            for _, item in ipairs(collapsibleItems) do
                item._isCollapsibleChild = true
                item._parentIndex = currentItemIndex
                table.insert(previousItems, item)
            end
            
            RageUI._Render.CurrentItems = previousItems
        end
    end
end)