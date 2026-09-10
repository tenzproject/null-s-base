Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    for k,v in pairs(Config.blips) do
        ESX.addBlips({
            name = ("%s-%s"):format(v.name, k),
            label = v.name,
            category = nil,
            position = v.Position,
            sprite = v.id,
            display = 4,
            scale = v.scale ~= nil and v.scale or 0.75,
            color = v.color,
        })

        if v.ZoneBlip then
            local zoneblip = AddBlipForRadius(v.Position, 200.0)
            SetBlipSprite(zoneblip,1)
            SetBlipColour(zoneblip, v.color)
            SetBlipAlpha(zoneblip,100)
        end
    end
end)
