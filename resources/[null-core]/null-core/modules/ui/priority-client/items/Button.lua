RageUI.Button = LPH_NO_VIRTUALIZE(function(Label, Description, Style, Enabled, Callback, Submenu)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "button",
            label = Label or "",
            description = Description or "",
            rightLabel = Style and Style.RightLabel or "",
            leftBadge = Style and Style.LeftBadge or nil,
            rightBadge = Style and Style.RightBadge or nil,
            enabled = Enabled ~= false,
            onSelected = function()
                if Callback then
                    if type(Callback) == "function" then
                        Callback()
                    elseif type(Callback) == "table" and Callback.onSelected then
                        Callback.onSelected()
                    end
                end
                if Submenu then
                    RageUI.CurrentMenu.Open = false
                    RageUI.CurrentMenu._lastHash = nil
                    RageUI.OpenMenu(Submenu)
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