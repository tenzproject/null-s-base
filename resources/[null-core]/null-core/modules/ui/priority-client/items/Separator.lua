RageUI.Separator = LPH_NO_VIRTUALIZE(function(Label)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "separator",
            label = Label or "",
            description = "",
            enabled = false
        }
        RageUI._AddRenderItem(item)
    end
end)
