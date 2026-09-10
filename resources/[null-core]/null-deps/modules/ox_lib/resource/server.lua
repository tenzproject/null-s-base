-- null-deps bundle : locales ox_lib vivent sous modules/ox_lib/locales/
local locales, localesN = lib.getFilesInDirectory('modules/ox_lib/locales', '%.json')

for i = 1, localesN do
    local key = locales[i]
    local value = key:gsub('%.json', '')
    local label = (json.decode(LoadResourceFile(lib.name, ('modules/ox_lib/locales/%s'):format(key)) or '') or '').language or value
    locales[i] = { label = label, value = value }
end

table.sort(locales, function(a, b)
    return a.label < b.label
end)

GlobalState['ox_lib:locales'] = locales
