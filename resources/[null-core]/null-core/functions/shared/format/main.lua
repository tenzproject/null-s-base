local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

null.fct.format.GetNbrOfNumber = function(string)
	if type(string) == "number" then string = tostring(string) end

	local counter = 0
    for i = 1, #string do
        local caractere = string:sub(i, i) 
        if caractere:match("%d") then
            counter = counter + 1
        end
    end
	return counter
end

null.fct.format.isNumber = function(string)
	if null.fct.format.GetNbrOfNumber(string) == #string then 
		return true
	else
		return false
	end
end

null.fct.format.clearTableFunction = function(table)
	local newTable = {}
    for k, v in pairs(table) do
        local typeVal = type(v)
        if typeVal == "table" then
            newTable[k] = null.fct.format.clearTableFunction(v)
        elseif typeVal ~= "function" then
            newTable[k] = v
        end
    end
    return newTable
end