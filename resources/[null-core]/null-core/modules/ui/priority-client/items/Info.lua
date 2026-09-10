RageUI.Info = LPH_NO_VIRTUALIZE(function(Title, LeftItems, RightItems)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "info",
            label = Title or "",
            description = "",
            leftItems = LeftItems or {},
            rightItems = RightItems or {},
            enabled = false
        }
        RageUI._AddRenderItem(item)
    end
end)
