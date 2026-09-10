Config.WeatherType = {
    ["weathers"] = {
        "EXTRASUNNY",
        "RAIN",
        "CLOUDS",
        "FOGGY",
        "CLEAR",
        "THUNDER",
        "SMOG",
        "OVERCAST",
        "CLEARING",
        "NEUTRAL",
        "SNOW",
        "BLIZZARD",
        "SNOWLIGHT",
        "XMAS",
        "HALLOWEEN",
        "THUNDERSTORM",
        "SANDSTORM",
        "FOG",
        "HURRICANE"
    }
}

Config.Weather = {}
Config.Weather.snowEnabled = false -- Set to false if you do not want snow enabled.
Config.Weather.decemberSnowDays = {1, 2, 4, 6, 7, 9, 11, 12, 15, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31} -- Days that snow will appear during the month of December.
Config.Weather.ReAjustTime = true

--[[
Config.Weather.UseRealTime: 
- true : L'heure est mise à jour automatiquement en fonction de l'heure du serveur. Si l'heure est bloquée, vous pourrez alors la modifier en jeu (IG).

- false : L'heure est mise à jour automatiquement en fonction de Config.Weather.TimeToWait. Vous pouvez modifier l'heure à tout moment, même si elle n'est pas bloquée. L'heure est sauvegardée avant chaque redémarrage.
]]
Config.Weather.UseRealTime = false 
Config.Weather.TimeToWait = 5*1000 -- en miliseconde, actuellement toute les 5 secondes = 1 minute passe

Config.Weather.Debug = false -- Affiche le changement d'heure dans la console