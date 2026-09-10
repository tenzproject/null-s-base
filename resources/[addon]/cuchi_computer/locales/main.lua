Locales = {}

function GetLocale(key)
    local locale = Locales[Config.Computer.Locale][key]
    if locale then
        return locale
    end

    return key + " doesn't exist"
end
