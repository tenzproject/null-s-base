null.fct.format.SecondsToStringClock = function(seconds)
	seconds = tonumber(seconds)
	if seconds <= 0 then
		return "00:00"
	else
		local mins = string.format("%02.f", math.floor(seconds / 60))
		local secs = string.format("%02.f", math.floor(seconds - mins * 60))
		return string.format("%s:%s", mins, secs)
	end
end

null.fct.format.SecondsToDetailedString = function(seconds)
	local days = seconds / 86400
	local hours = (days - math.floor(days)) * 24
	local minutes = (hours - math.floor(hours)) * 60
	seconds = (minutes - math.floor(minutes)) * 60
    if math.floor(days) == 0 then
        return ('%sH, %sM, %sS'):format(math.floor(hours), math.floor(minutes), math.floor(seconds))
    else
        return ('%sJ, %sH, %sM, %sS'):format(math.floor(days), math.floor(hours), math.floor(minutes), math.floor(seconds)) 
    end
end

null.fct.format.SecondsToClock = function(seconds)
	if seconds == -1 then
		return {0,0,0}
	end
    local timerValue = {}
    local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0
    if seconds <= 0 then
        return 0, 0, 0
    else
        local hours = string.format('%02.f', math.floor(seconds / 3600))
        local mins = string.format('%02.f', math.floor(seconds / 60 - (hours * 60)))
        local secs = string.format('%02.f', math.floor(seconds - hours * 3600 - mins * 60))
        timerValue = {hours, mins, secs}
        return timerValue
    end
end