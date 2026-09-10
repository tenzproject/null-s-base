RageUI.List = LPH_NO_VIRTUALIZE(function(Label, Items, Index, Description, Style, Enabled, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local listItems = {}
        for i, v in ipairs(Items) do
            if type(v) == "table" then
                table.insert(listItems, v.Name or tostring(v))
            else
                table.insert(listItems, tostring(v))
            end
        end
        
        local item = {
            type = "list",
            label = Label or "",
            description = Description or "",
            rightLabel = Style and Style.RightLabel or "",
            leftBadge = Style and Style.LeftBadge or nil,
            rightBadge = Style and Style.RightBadge or nil,
            enabled = Enabled ~= false,
            items = listItems,
            value = Index or 1,
            onChanged = function(newIndex)
                if Callback and Callback.onListChange then
                    Callback.onListChange(newIndex, Items[newIndex])
                end
            end,
            onSelected = function(newIndex)
                if Callback and Callback.onSelected then
                    Callback.onSelected(newIndex, Items[newIndex])
                end
            end,
            onActive = function()
                if Callback and type(Callback) == "table" and Callback.onActive then
                    Callback.onActive()
                end
            end
        }

        RageUI._AddRenderItem(item)

        if RageUI.CurrentMenu ~= nil then
            local ItemIndex = 0
            if RageUI._Render.Active then
                ItemIndex = #RageUI._Render.CurrentItems
            else
                ItemIndex = #RageUI.CurrentMenu.Items
            end
            
            if RageUI.CurrentMenu.Index == ItemIndex then
                if Callback and type(Callback) == "table" and Callback.onActive then
                    Callback.onActive()
                end
            end
        end
    end
end)
