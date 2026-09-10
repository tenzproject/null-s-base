Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Citizen.Wait(0)
        HideHudComponentThisFrame(1)
        HideHudComponentThisFrame(2)
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(13)
        HideHudComponentThisFrame(22)
    end
end))

null.fct.waitPlayerLoaded = LPH_NO_VIRTUALIZE(function(wait)
    while ESX == nil or not ESX.PlayerLoaded do
        Citizen.Wait(wait or 50)
    end
end)