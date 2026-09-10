null.fct.utils.TimeToDisplay = function()
	hour = GetClockHours()
	minute = GetClockMinutes()

	if hour <= 9 then
		hour = "0" .. hour
	end
	if minute <= 9 then
		minute = "0" .. minute
	end
    return hour, minute
end