Locales = {}

function Translate(str, ...) -- Translate string
    if not str then
        print(("[^1ERROR^7] Resource ^5%s^7 You did not specify a parameter for the Translate function or the value is nil!"):format(GetInvokingResource() or GetCurrentResourceName()))
        return "Given translate function parameter is nil!"
    end
    if Locales[Config.Animations.MenuLanguage] then
        if Locales[Config.Animations.MenuLanguage][str] then
            return string.format(Locales[Config.Animations.MenuLanguage][str], ...)
        elseif Config.Animations.MenuLanguage ~= "en" and Locales["en"] and Locales["en"][str] then
            return string.format(Locales["en"][str], ...)
        else
            return "Translation [" .. Config.Animations.MenuLanguage .. "][" .. str .. "] does not exist"
        end
    elseif Config.Animations.MenuLanguage ~= "en" and Locales["en"] and Locales["en"][str] then
        return string.format(Locales["en"][str], ...)
    else
        return "Locale [" .. Config.Animations.MenuLanguage .. "] does not exist"
    end
end

function TranslateCap(str, ...) -- Translate string first char uppercase
    return _(str, ...):gsub("^%l", string.upper)
end

_ = Translate
-- luacheck: ignore _U
_U = TranslateCap