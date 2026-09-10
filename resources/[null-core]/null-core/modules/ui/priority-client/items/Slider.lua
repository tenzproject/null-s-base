RageUI.Slider = LPH_NO_VIRTUALIZE(function(Label, Value, Max, Description, Divider, Style, Enabled, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "slider",
            label = Label or "",
            description = Description or "",
            rightLabel = Style and Style.RightLabel or "",
            leftBadge = Style and Style.LeftBadge or nil,
            rightBadge = Style and Style.RightBadge or nil,
            enabled = Enabled ~= false,
            value = Value or 1,
            min = 1,
            max = Max or 100,
            divider = Divider or false,
            onChanged = function(newValue)
                if Callback and Callback.onSliderChange then
                    Callback.onSliderChange(newValue)
                end
            end,
            onSelected = function(newValue)
                if Callback and Callback.onSelected then
                    Callback.onSelected(newValue)
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
