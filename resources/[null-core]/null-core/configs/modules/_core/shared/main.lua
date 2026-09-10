Config = Config or {}

Config._core = Config._core or {}

--[[
    Armes bloquées (sauf pour certains jobs)
]]
Config._core.BlockedWeapons = {
    [`WEAPON_STUNGUN`] = true,
    [`WEAPON_FLASHLIGHT`] = true,
    -- Ajouter d'autres armes si nécessaire
}

--[[
    Jobs autorisés à utiliser les armes bloquées
]]
Config._core.PoliceJobs = {
    ["police"] = true,
    ["sheriff"] = true,
    ["fbi"] = true,
}

Config.Instance = {
    list = {
        [0] = "Roleplay Instance",
        [666] = "Cheateur Instance",
        [9201] = "Jail Instance",
        [75576] = "Zone Gunfight Instance",
    },
    GetName = function(instance)
        if instance == nil then return nil end
        instance = tostring(instance)
        local twoFirstChar = tonumber(string.sub(instance, 1, 2))
        if twoFirstChar == 32 then
            return "Laboratoire"
        elseif twoFirstChar == 21 then
            return "Propriétée"
        else
            return nil
        end
    end
}