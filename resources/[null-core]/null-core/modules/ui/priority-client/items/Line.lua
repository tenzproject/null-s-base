RageUI.Line = LPH_NO_VIRTUALIZE(function()
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local item = {
            type = "separator",
            label = "",
            description = "",
            enabled = false
        }
        RageUI._AddRenderItem(item)
    end
end)