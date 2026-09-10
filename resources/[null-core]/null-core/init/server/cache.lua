if SaveData == nil then
    local timeout = 0
    while SaveData == nil and timeout < 1000 do
        timeout = timeout + 1
        Wait(1)
    end
    if SaveData == nil then
        null.DebugPrint("SaveData not init after timeout delay.")
        SaveData = {}
    end
end

local RESOURCE_NAME = 'null-core'
local CACHE_FOLDER = 'cache'
local BACKUP_FOLDER = 'cache/backups'
local AUTO_SAVE_INTERVAL = 3 * 60 * 1000 -- 3 minutes
local BACKUP_HOURS = { 8, 20 }
local FRAGMENT_THRESHOLD = 5000 -- Fragmenter si > 5000 éléments
local FRAGMENT_SIZE = 2500 -- Taille de chaque fragment
local FRAGMENTABLE_CACHES = { -- Caches qui peuvent être fragmentés
    ['deco-reco'] = true,
    ['owned_vehicles'] = true,
    ['logs'] = true,
}

SaveData.cacheLoad = false
SaveData.cacheAutoSave = true

SaveData.json = {}

Cache = {}

local DefaultCache = {
    data = {},
    
    entreprises = {
        ["Mécano"] = {},
        ["Farm"] = {},
        ["Police"] = {},
        ["Restaurant"] = {},
        ["Ambulance"] = {},
        ["Bar"] = {},
    },
    
    -- Territoires & Zones
    territories = {},
    ascenceurs = {},
    zonegf = {},
    
    -- Logs & Tracking
    ["deco-reco"] = {},
    logs = {},
    tracks = {},
    staffsnotes = {},
    
    -- Véhicules
    fourrieres = {},
    owned_vehicles = {},
    
    -- Braquages
    robbery = {
        fleeca = {},
    },
    
    -- Utilisateurs
    users = {},
    
    -- Synchronisation temps/météo
    vsync = {
        time = { h = 18, m = 0 },
        freeze = { time = false, weather = false },
        weather = "extrasunny"
    },
    
    -- Whitelist
    whitelist = {
        players = {},
        status = false
    },
    
    -- Illégaux
    illegals = {
        plants = {},
        laboratorys = {},
    },
    
    -- Divers
    posters = {},
    repair = {},
    
    -- Boutique
    boutique = {
        crates = {},
        vehicles = {},
        boosts = {},
        packs = {},
        weapons = {},
        custom_weapon = 250,
        unique_veh = {},
    },

    -- NightMarket
    nightmarket = {
        active = false,
        cards = {},
        expiresAt = 0,
        startedBy = nil,
    },

    dealerships = {},
    
    -- Taxes
    taxes = {
        retrait = 10,
        gains = 5,
        tva = 15,
        salaire = 10,
    },
    taxed = {},
    
    -- Stats groupes
    ["groupes-stats"] = {},
    
    -- Commandes labo
    LaboOrders = {
        DeliveryOrders = {},
        LastOrderId = 0,
    },
}


Citizen.CreateThread(function()
    while Config == nil or Config.Society == nil or Config.Society.Economy == nil do Wait(10) end
    Cache.Init("salary", {
        ["Mensuel"] = {
            min = Config.Society.Economy.Salary["Mensuel"].min,
            max = Config.Society.Economy.Salary["Mensuel"].max,
        },
        ["Pour 30 Min"] = {
            min = Config.Society.Economy.Salary["Pour 30 Min"].min,
            max = Config.Society.Economy.Salary["Pour 30 Min"].max,
        },
        ["Primes"] = {
            min = 0,
            max = 10000,
        },
    })
end)

local function GetFragmentIndex(name)
    local filePath = CACHE_FOLDER .. '/' .. name .. '.json'
    local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
    if rawData then
        local data = json.decode(rawData)
        if data and data.fragmented == true then
            return data
        end
    end
    return nil
end

function Cache.Init(name, defaultValue)
    if defaultValue == nil then defaultValue = {} end
    
    null.DebugPrint('^3Initializing cache:^7 ' .. name)
    
    local filePath = CACHE_FOLDER .. '/' .. name .. '.json'
    local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
    local data = rawData and json.decode(rawData) or nil
    
    if data and data.fragmented == true then
        SaveData.json[name] = data
        null.DebugPrint(('^3Cache %s is fragmented (%d elements in %d files)^7'):format(name, data.totalElements, data.fragmentCount))
        return
    end
    
    if data == nil or (type(data) == 'table' and #data == 0 and type(defaultValue) == 'table' and #defaultValue > 0) then
        SaveResourceFile(RESOURCE_NAME, filePath, json.encode(defaultValue), -1)
        SaveData.json[name] = defaultValue
    else
        SaveData.json[name] = data
    end
end

function Cache.Get(name, searchKey)
    name = name or 'data'
    local data = SaveData.json[name]
    
    if not data or not data.fragmented then
        if searchKey and data then
            if #data > 0 then
                for _, entry in ipairs(data) do
                    for k, v in pairs(entry) do
                        if v == searchKey then
                            return entry
                        end
                    end
                end
                return nil
            else
                return data[searchKey]
            end
        end
        return data
    end
    
    local fragmentCount = data.fragmentCount
    
    if searchKey then
        for i = 1, fragmentCount do
            local fragmentName = name .. '_frag_' .. i
            local filePath = CACHE_FOLDER .. '/' .. fragmentName .. '.json'
            local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
            
            if rawData then
                local fragmentData = json.decode(rawData)
                if fragmentData then
                    if #fragmentData > 0 then
                        for _, entry in ipairs(fragmentData) do
                            for k, v in pairs(entry) do
                                if v == searchKey then
                                    return entry
                                end
                            end
                        end
                    else
                        if fragmentData[searchKey] then
                            return fragmentData[searchKey]
                        end
                    end
                end
            end
        end
        return nil
    end
    
    null.DebugPrint(('^3[WARN] Loading all fragments for %s - this is expensive!^7'):format(name))
    return Cache.LoadFragmented(name, data)
end

function Cache.GetAll()
    return SaveData.json
end

function Cache.Set(name, value)
    name = name or 'data'
    SaveData.json[name] = value
    Cache.SaveOne(name)
end

function Cache.Edit(name, value)
    name = name or 'data'
    SaveData.json[name] = value
end

function Cache.SaveOne(name)
    if SaveData.json[name] then
        local filePath = CACHE_FOLDER .. '/' .. name .. '.json'
        SaveResourceFile(RESOURCE_NAME, filePath, json.encode(SaveData.json[name]), -1)
    end
end

function Cache.SaveAll()
    for name, data in pairs(SaveData.json) do
        local filePath = CACHE_FOLDER .. '/' .. name .. '.json'
        SaveResourceFile(RESOURCE_NAME, filePath, json.encode(data), -1)
    end
    null.DebugPrint('^2All caches saved^7')
end

function Cache.Reload(name)
    local filePath = CACHE_FOLDER .. '/' .. name .. '.json'
    local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
    
    if rawData then
        SaveData.json[name] = json.decode(rawData)
        null.DebugPrint('^3Cache reloaded:^7 ' .. name)
    end
end

function Cache.ReloadAll()
    SaveData.cacheLoad = false
    
    for name, defaultValue in pairs(DefaultCache) do
        Cache.Init(name, defaultValue)
    end
    
    SaveData.cacheLoad = true
    null.DebugPrint('^2All caches reloaded^7')
end

function Cache.IsLoaded()
    return SaveData.cacheLoad
end

function Cache.SetAutoSave(enabled)
    SaveData.cacheAutoSave = enabled
end

function Cache.IsAutoSaveEnabled()
    return SaveData.cacheAutoSave
end

for name, defaultValue in pairs(DefaultCache) do
    Cache.Init(name, defaultValue)
end
    
SaveData.cacheLoad = true
null.DebugPrint('^2Cache system ready^7')

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(AUTO_SAVE_INTERVAL)
        
        if SaveData.cacheAutoSave then
            Cache.SaveAll()
        end
    end
end))

AddEventHandler('onResourceStop', function(resource)
    if resource == RESOURCE_NAME then
        Cache.SaveAll()
    end
end)

local lastBackupHour = -1

function Cache.Backup()
    local date = os.date('%Y-%m-%d_%H-%M')
    local backupSubFolder = BACKUP_FOLDER .. '/' .. date

    for name, data in pairs(SaveData.json) do
        local filePath = backupSubFolder .. '/' .. name .. '.json'
        SaveResourceFile(RESOURCE_NAME, filePath, json.encode(data), -1)
    end
    
    print(('^2[null-core]^7 Backup créé: ^3%s^7'):format(date))
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(60000) 
        
        local currentHour = tonumber(os.date('%H'))
        
        for _, backupHour in ipairs(BACKUP_HOURS) do
            if currentHour == backupHour and lastBackupHour ~= currentHour then
                lastBackupHour = currentHour
                Cache.Backup()
                break
            end
        end
        
        if currentHour == 0 then
            lastBackupHour = -1
        end
    end
end))

local function CountElements(data)
    if type(data) ~= 'table' then return 0 end
    local count = 0
    for _ in pairs(data) do
        count = count + 1
    end
    return count
end

function Cache.Fragment(name)
    local data = SaveData.json[name]
    if not data or type(data) ~= 'table' then return false end
    
    local count = CountElements(data)
    if count <= FRAGMENT_THRESHOLD then return false end
    
    print(('^3[null-core]^7 Fragmentation de ^3%s^7 (%d éléments)...'):format(name, count))
    
    local isArray = #data > 0
    local items = {}
    
    if isArray then
        items = data
    else
        for k, v in pairs(data) do
            table.insert(items, { key = k, value = v })
        end
    end
    
    local fragmentIndex = 1
    local currentFragment = {}
    local currentCount = 0
    
    for i, item in ipairs(items) do
        if isArray then
            table.insert(currentFragment, item)
        else
            currentFragment[item.key] = item.value
        end
        currentCount = currentCount + 1
        
        if currentCount >= FRAGMENT_SIZE or i == #items then
            local fragmentName = name .. '_frag_' .. fragmentIndex
            local filePath = CACHE_FOLDER .. '/' .. fragmentName .. '.json'
            SaveResourceFile(RESOURCE_NAME, filePath, json.encode(currentFragment), -1)
            
            fragmentIndex = fragmentIndex + 1
            currentFragment = {}
            currentCount = 0
        end
    end
    
    local indexData = {
        fragmented = true,
        fragmentCount = fragmentIndex - 1,
        totalElements = count,
        fragmentedAt = os.date('%Y-%m-%d %H:%M:%S')
    }
    local indexPath = CACHE_FOLDER .. '/' .. name .. '.json'
    SaveResourceFile(RESOURCE_NAME, indexPath, json.encode(indexData), -1)
    
    print(('^2[null-core]^7 ^3%s^7 fragmenté en %d parties'):format(name, fragmentIndex - 1))
    return true
end

function Cache.LoadFragmented(name, indexData)
    local allData = {}
    
    for i = 1, indexData.fragmentCount do
        local fragmentName = name .. '_frag_' .. i
        local filePath = CACHE_FOLDER .. '/' .. fragmentName .. '.json'
        local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
        
        if rawData then
            local fragmentData = json.decode(rawData)
            if fragmentData then
                if #fragmentData > 0 then -- Array
                    for _, item in ipairs(fragmentData) do
                        table.insert(allData, item)
                    end
                else -- Table
                    for k, v in pairs(fragmentData) do
                        allData[k] = v
                    end
                end
            end
        end
    end
    
    return allData
end

function Cache.Append(name, entry)
    local data = SaveData.json[name]
    
    if data and data.fragmented then
        local lastFragmentIndex = data.fragmentCount
        local fragmentName = name .. '_frag_' .. lastFragmentIndex
        local filePath = CACHE_FOLDER .. '/' .. fragmentName .. '.json'
        local rawData = LoadResourceFile(RESOURCE_NAME, filePath)
        
        local fragmentData = rawData and json.decode(rawData) or {}
        
        local fragmentSize = #fragmentData > 0 and #fragmentData or CountElements(fragmentData)
        
        if fragmentSize >= FRAGMENT_SIZE then
            lastFragmentIndex = lastFragmentIndex + 1
            fragmentName = name .. '_frag_' .. lastFragmentIndex
            filePath = CACHE_FOLDER .. '/' .. fragmentName .. '.json'
            fragmentData = {}
            
            data.fragmentCount = lastFragmentIndex
            data.totalElements = data.totalElements + 1
            SaveData.json[name] = data
            
            local indexPath = CACHE_FOLDER .. '/' .. name .. '.json'
            SaveResourceFile(RESOURCE_NAME, indexPath, json.encode(data), -1)
        else
            data.totalElements = data.totalElements + 1
            SaveData.json[name] = data
            
            local indexPath = CACHE_FOLDER .. '/' .. name .. '.json'
            SaveResourceFile(RESOURCE_NAME, indexPath, json.encode(data), -1)
        end
        
        table.insert(fragmentData, entry)
        SaveResourceFile(RESOURCE_NAME, filePath, json.encode(fragmentData), -1)
        
        return true
    end
    
    if not data then
        data = {}
        SaveData.json[name] = data
    end
    
    table.insert(data, entry)
    
    if FRAGMENTABLE_CACHES[name] and #data > FRAGMENT_THRESHOLD then
        Cache.Fragment(name)
        SaveData.json[name] = GetFragmentIndex(name)
    end
    
    return true
end

function Cache.CheckAndFragment()
    for name, _ in pairs(FRAGMENTABLE_CACHES) do
        local data = SaveData.json[name]
        if data and type(data) == 'table' then
            local count = CountElements(data)
            if count > FRAGMENT_THRESHOLD then
                Cache.Fragment(name)
            end
        end
    end
end

function Cache.Cleanup(name, daysToKeep)
    daysToKeep = daysToKeep or 30
    local data = SaveData.json[name]
    if not data or type(data) ~= 'table' or #data == 0 then return 0 end
    
    local cutoffTime = os.time() - (daysToKeep * 24 * 60 * 60)
    local removed = 0
    local newData = {}
    
    for _, entry in ipairs(data) do
        if entry.date then
            local year, month, day = entry.date:match('(%d+)/(%d+)/(%d+)')
            if year and month and day then
                local entryTime = os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) })
                if entryTime >= cutoffTime then
                    table.insert(newData, entry)
                else
                    removed = removed + 1
                end
            else
                table.insert(newData, entry)
            end
        else
            table.insert(newData, entry)
        end
    end
    
    if removed > 0 then
        SaveData.json[name] = newData
        Cache.SaveOne(name)
        print(('^2[null-core]^7 Nettoyage ^3%s^7: %d entrées supprimées (> %d jours)'):format(name, removed, daysToKeep))
    end
    
    return removed
end

RegisterCommand('cache', function(source, args)
    if source ~= 0 then return end
    
    if not args[1] then
        print([[^2[null-core]^7 Cache commands:
    ^3cache autosave^7 <enable|disable|status> - Toggle auto-save
    ^3cache save^7 [name] - Save cache(s)
    ^3cache reload^7 [name] - Reload cache(s)
    ^3cache list^7 - List all caches
    ^3cache get^7 <name> - Show cache content
    ^3cache backup^7 - Create manual backup
    ^3cache cleanup^7 <name> [days] - Remove old entries (default: 30 days)
    ^3cache fragment^7 <name> - Force fragmentation
    ^3cache stats^7 - Show cache statistics]])
        return
    end
    
    local cmd = args[1]
    
    if cmd == 'autosave' then
        local action = args[2]
        if action == 'enable' then
            Cache.SetAutoSave(true)
            print('^2[null-core]^7 Auto-save ^2enabled^7')
        elseif action == 'disable' then
            Cache.SetAutoSave(false)
            print('^2[null-core]^7 Auto-save ^1disabled^7')
        else
            local status = Cache.IsAutoSaveEnabled() and '^2enabled^7' or '^1disabled^7'
            print('^2[null-core]^7 Auto-save is ' .. status)
        end
        
    elseif cmd == 'save' then
        if args[2] then
            Cache.SaveOne(args[2])
            print('^2[null-core]^7 Cache ^3' .. args[2] .. '^7 saved')
        else
            Cache.SaveAll()
        end
        
    elseif cmd == 'reload' then
        if args[2] then
            Cache.Reload(args[2])
        else
            Cache.ReloadAll()
        end
        
    elseif cmd == 'list' then
        print('^2[null-core]^7 Loaded caches:')
        for name, _ in pairs(SaveData.json) do
            print('  ^3- ' .. name .. '^7')
        end
        
    elseif cmd == 'get' then
        if args[2] and SaveData.json[args[2]] then
            print('^2[null-core]^7 Cache ^3' .. args[2] .. '^7:')
            print(json.encode(SaveData.json[args[2]], { indent = true }))
        else
            print('^2[null-core]^7 Cache not found')
        end
        
    elseif cmd == 'backup' then
        Cache.Backup()
        
    elseif cmd == 'cleanup' then
        if args[2] then
            local days = tonumber(args[3]) or 30
            local removed = Cache.Cleanup(args[2], days)
            if removed == 0 then
                print('^2[null-core]^7 Aucune entrée à supprimer')
            end
        else
            print('^2[null-core]^7 Usage: cache cleanup <name> [days]')
        end
    elseif cmd == 'fragment' then
        if args[2] then
            if FRAGMENTABLE_CACHES[args[2]] then
                local success = Cache.Fragment(args[2])
                if success then
                    SaveData.json[args[2]] = GetFragmentIndex(args[2])
                else
                    print('^2[null-core]^7 Cache trop petit pour être fragmenté (< ' .. FRAGMENT_THRESHOLD .. ' éléments)')
                end
            else
                print('^2[null-core]^7 Ce cache ne peut pas être fragmenté')
            end
        else
            print('^2[null-core]^7 Usage: cache fragment <name>')
        end
        
    elseif cmd == 'stats' then
        print('^2[null-core]^7 Cache statistics:')
        local totalElements = 0
        for name, data in pairs(SaveData.json) do
            local count = 0
            local status = ''
            
            if data and data.fragmented then
                count = data.totalElements or 0
                status = (' ^2[FRAGMENTED: %d files]^7'):format(data.fragmentCount or 0)
            else
                count = CountElements(data)
                if FRAGMENTABLE_CACHES[name] and count > FRAGMENT_THRESHOLD then
                    status = ' ^1[SHOULD FRAGMENT]^7'
                elseif count > 1000 then
                    status = ' ^3[LARGE]^7'
                end
            end
            
            totalElements = totalElements + count
            print(('  ^3%s^7: %d éléments%s'):format(name, count, status))
        end
        print(('  ^2Total^7: %d éléments'):format(totalElements))
        
    else
        print('^2[null-core]^7 Unknown command. Use ^3cache^7 for help.')
    end
end, true)

exports('InitCacheData', Cache.Init)
exports('GetCacheData', Cache.Get)
exports('GetCache', Cache.GetAll)
exports('SetCacheData', Cache.Set)
exports('EditCacheData', Cache.Edit)
exports('AppendCacheData', Cache.Append)
exports('SaveCacheData', Cache.SaveOne)
exports('SaveAllCacheData', Cache.SaveAll)
exports('ReloadCacheData', Cache.Reload)
exports('ReloadAllCacheData', Cache.ReloadAll)
exports('IsCacheLoaded', Cache.IsLoaded)
exports('FragmentCache', Cache.Fragment)
exports('CleanupCache', Cache.Cleanup)
exports('UpdateCacheData', function(name, value)
    if value then
        Cache.Set(name, value)
    else
        Cache.SaveOne(name)
    end
end)

null.InitPrint('^2Cache module loaded^7')