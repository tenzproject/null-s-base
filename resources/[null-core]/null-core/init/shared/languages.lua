if not languages then languages = {} end
if not languages["fr"] then languages["fr"] = {} end
if not languages["en"] then languages["en"] = {} end

function _(str, ...)  -- Translate string
	if Config.Language == nil then
		Config.Language = "fr"
	end

	if languages[Config.Language] ~= nil then
		if languages[Config.Language][str] ~= nil then
			return string.format(languages[Config.Language][str], ...)
		else
			return '' .. Config.Language .. ': [' .. str .. '] n\'existe pas/plus.'
		end

	else
		return str..' : Locale [' .. Config.Locale .. '] does not exist'
	end

end

function _U(str, ...)
	return tostring(_(str, ...):gsub("^%l", string.upper))
end 