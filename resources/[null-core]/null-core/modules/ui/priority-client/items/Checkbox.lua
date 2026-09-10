RageUI.Checkbox = LPH_NO_VIRTUALIZE(function(Label, Description, Checked, Style, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "checkbox",
            label = Label or "",
            description = Description or "",
            rightLabel = Style and Style.RightLabel or "",
            leftBadge = Style and Style.LeftBadge or nil,
            rightBadge = Style and Style.RightBadge or nil,
            enabled = true,
            checked = Checked or false,
            onSelected = function(newChecked)
                if newChecked then
                    if Callback and Callback.onChecked then
                        Callback.onChecked()
                    end
                else
                    if Callback and Callback.onUnChecked then
                        Callback.onUnChecked()
                    end
                end
                if Callback and Callback.onSelected then
                    Callback.onSelected(newChecked)
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