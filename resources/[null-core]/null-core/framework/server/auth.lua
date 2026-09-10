local API_ENDPOINT = "https://api.null.fr"

local Figlet = require('lib/figlet')

local function printStat(count, label, loaded)
    local status = loaded and "^2OK^7" or "^1ERREUR^7"
    print(("     [%s] %s %s"):format(status, count or 0, label or "Element(s)"))
end

local function PrintServer()
    local fontPath = GetResourcePath(GetCurrentResourceName()) .. "/lib/fonts/Big.flf"
    Figlet.readfont(fontPath)
    local asciiArt = Figlet.getString(string.upper(null.getConvarKey("serverName")), true, true)
    print("")
    print("")
    print("")
    print(null.getConvarKey("jsColor")..asciiArt.."^7") -- Affiche dans la console serveur
    print("")
    print("     [^5AUTHOR^7] Base developped by Null, Veqta, Maisto and Nykz")
    print("     [^5DISCORD^7] discord.gg/null ^7")
    print("")
    print("")
    printStat(ESX.Table.SizeOf(SaveData.Players.Offline.List), "Joueur(s)", SaveData.Players.Offline.Loaded ~= false)
    printStat(ESX.Table.SizeOf(SaveData.Admin.Staffs.List), "Staff(s)", SaveData.Admin.Staffs.Load ~= false)
    printStat(ESX.Table.SizeOf(SaveData.SafeZone.List), "SafeZone(s)", SaveData.SafeZone.Load ~= false)
    printStat(ESX.Table.SizeOf(SaveData.World.Props), "Prop(s) (Monde)", SaveData.World.Props ~= nil)
    printStat(ESX.Table.SizeOf(SaveData.World.Vehicles), "Vehicule(s) (Monde)", SaveData.World.Vehicles ~= nil)
    printStat(ESX.Table.SizeOf(SaveData.json.owned_vehicles), "Vehicule(s) (Garage)", SaveData.json.owned_vehicles ~= nil)
    print("")
    print("")
    null.auth.visual = true
end

exports("showLicense", function()
    while (not null.auth.authorized) do Wait(10) end
    if not null.auth.authorized then return end

    null.auth.visual = false

    local success, err = pcall(function()
        PrintServer()
    end)
    if not success then
        null.DebugPrint("[Auth] Error while printing server info: "..tostring(err))
        return false
    end
    return true
end)
