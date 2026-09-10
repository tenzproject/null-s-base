null.cooldown = false

function null.fct.cooldown(time)
    null.cooldown = true
    Citizen.SetTimeout(time,function()
        null.cooldown = false
    end)
end