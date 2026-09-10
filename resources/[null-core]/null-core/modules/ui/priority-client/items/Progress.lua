RageUI.Progress = LPH_NO_VIRTUALIZE(function(Label, Value, Max, Description, Divider, Enabled, Callback)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local currentValue = Value or 1
        
        local item = {
            type = "slider",
            label = Label or "",
            description = Description or "",
            enabled = Enabled ~= false,
            value = currentValue,
            min = 1,
            max = Max or 100,
            divider = Divider or false,
            onChanged = function(newValue)
                currentValue = newValue
                if Callback and Callback.onProgressChange then
                    Callback.onProgressChange(newValue)
                end
            end
        }
        RageUI._AddRenderItem(item)
        
        return true, true, true, currentValue
    end
    return false, false, false, Value
end)
