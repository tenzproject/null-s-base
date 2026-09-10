null.fct.game.RequestAndWaitAnimDict = LPH_NO_VIRTUALIZE(function(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end)

null.fct.game.startAnimAction = LPH_NO_VIRTUALIZE(function(lib, anim)
	null.fct.game.RequestAndWaitAnimDict(lib)
	TaskPlayAnim(plyPed, lib, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
	RemoveAnimDict(lib)
end)

null.fct.game.PlayToggleEmote = LPH_NO_VIRTUALIZE(function(e, cb)
	local Ped = PlayerPedId()
	while not HasAnimDictLoaded(e.Dict) do RequestAnimDict(e.Dict) Wait(100) end
	if IsPedInAnyVehicle(Ped) then e.Move = 51 end
	TaskPlayAnim(Ped, e.Dict, e.Anim, 3.0, 3.0, e.Dur, e.Move, 0, false, false, false)
    RemoveAnimDict(e.Dict)
	local Pause = e.Dur-500 if Pause < 500 then Pause = 500 end
end)