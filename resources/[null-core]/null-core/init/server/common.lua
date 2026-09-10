local InitCommon = LPH_NO_VIRTUALIZE(function()
    ESX = {}
    ESX.DB = {}
    ESX.Players = {}
    ESX.PlayersByIdentifier = {}
    ESX.PlayersByIdUnique = {}
    ESX.Commands = {}
    ESX.CommandsSuggestions = {}
    ESX.Groups = {}
    ESX.Jobs = {}
    ESX.Items = {}
    ESX.UsableItemsCallbacks = {}
    ESX.ServerCallbacks = {}
    ESX.ServerCallbacksResourceName = {}
    ESX.TimeoutCount = -1
    ESX.CancelledTimeouts = {}
    ESX.Pickups = {}
    ESX.PickupId = 0

    null = {}
    -- Namespaces
    null.fct = {} -- Functions
    null.fct.format = {}
    null.fct.math = {}
    null.fct.utils = {}
    null.fct.instance = {}
    null.fct.sql = {} 
    null.fct.safe = {}

    null.auth = {
        key = nil,
        authorize = nil,
        authorized = nil,
        loaded = false,
        infos = {},
        visual = false,
    }

    null.players = {}
    null.players.instances = {}
    null.players.clothes = {}
    null.players.afk = {}

    null.loader = {
        resources = {},
    }
end)

InitCommon()


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= "null-core" then
      return
    end

    
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= "null-core" then
        return
    end
    if not devmode then
        null.stopServer(function()
            ExecuteCommand("quit")
        end)
    else
        null.stopServer()
    end
end)


local API = {}
null.api = null.api or { routes = {} }

function null.api.registerRoute(method, path, handler)
    null.api.routes[method .. " " .. path] = handler
end
local serverIp = nil

null.resources = {}

local playerLogs = {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    table.insert(playerLogs, {
        type = 'connect',
        idunique = xPlayer.idunique,
        name = xPlayer.getName(),
        identifiers = {
            license = xPlayer.identifier,
            steam = xPlayer.steam or nil,
            discord = xPlayer.discord or nil,
            fivem = xPlayer.fivem or nil
        },
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    })
    null.DebugPrint("[PlayerLog] Connexion: " .. xPlayer.getName() .. " (" .. xPlayer.idunique .. ")")
end)

AddEventHandler('playerDropped', function(reason)
	local src = source
	if ESX.Players[src] == nil then return end
    table.insert(playerLogs, {
        type = 'disconnect',
        idunique = ESX.Players[src].idunique,
        name = ESX.Players[src].getName(),
        reason = reason or 'Unknown',
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    })
    null.DebugPrint("[PlayerLog] Déconnexion: " .. ESX.Players[src].getName() .. " (" .. ESX.Players[src].idunique .. ") - Raison: " .. (reason or 'Unknown'))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if ESX and ESX.SavePlayers then ESX.SavePlayers() end
        if not ESX or not ESX.Players then return end
        for k,v in pairs(ESX.Players) do
			table.insert(playerLogs, {
				type = 'disconnect',
				idunique = v.idunique,
				name = v.getName(),
				reason = reason or 'Unknown',
				timestamp = os.date('%Y-%m-%d %H:%M:%S')
			})
			null.DebugPrint("[PlayerLog] Déconnexion: " .. v.getName() .. " (" .. v.idunique .. ") - Raison: Fermeture du serveur")
		end
    end
end)

function StopBase(reason, debugId)
    print("^1═══════════════════════════════════════════════════════════════^7")
    print("^1                    Null BASE - ARRÊT                        ^7")
    print("^1═══════════════════════════════════════════════════════════════^7")
    print("Raison : ^3"..(reason or "Aucune").."^7")
    print("Code : ^1"..(debugId or "0").."^7")
    print("^1═══════════════════════════════════════════════════════════════^7")
    if not LPH_OBFUSCATED then
        print("^1Arrêt automatique dans 5 secondes... (mode dev)^7")
        return
    end
    print("Arrêt automatique dans 5 secondes...")
    Wait(2500)
    Citizen.CreateThread(function() 
        pcall(function()
            if ESX and ESX.SyncPosition then ESX.SyncPosition() end
            if ESX and ESX.SavePlayers then ESX.SavePlayers() end
            if SaveAllSociety then SaveAllSociety() end
        end)
    end)
    Wait(2500)
    ExecuteCommand('quit '..reason..' '..debugId)
    Wait(1000)
	print("user try to bypass quit system")
	print("force exit... (a save has been done before the force crash, if you don't want to crash add 'add_acl resource.null-core command allow' to your server.cfg)")
    Wait(5000)
    -- while true do 
    --     print("force exit")
    -- end

	LPH_CRASH()

	Wait(1000)

    while true do 
        print("force exit")
    end
end

function BaseStopResource(resourceName, reason)
	Citizen.CreateThread(function()
		local try = 0
		while true do 
			local resourceStatus = GetResourceState(resourceName)
			if resourceStatus == "started" then 
				StopResource(resourceName)
				try = try + 1
			end
			if try >= 5 then 
				print("^1Arrêt de la ressource "..resourceName.." impossible.")
				print("^1Forcage par arrêt du serveur...")
				StopBase("Arrêt de la ressource "..resourceName.." impossible ("..reason.."). Forcage par arrêt du serveur.", "1")
				break
			end
			Wait(1000)
		end
	end)
end

exports("stop-resource", BaseStopResource)


local function GetPublicIPs(callback)
    local ipv4, ipv6 = nil, nil
    local completed = 0
    
    PerformHttpRequest("http://api.ipify.org/", function(err, responseIP, headers)
        if err == 200 and responseIP then
            ipv4 = responseIP
        end
        completed = completed + 1
    end, 'GET', '', {['Content-Type'] = 'application/json'})
    
    PerformHttpRequest("http://api6.ipify.org/", function(err, responseIP, headers)
        if err == 200 and responseIP then
            ipv6 = responseIP
        end
        completed = completed + 1
    end, 'GET', '', {['Content-Type'] = 'application/json'})

    while completed < 2 do 
        Wait(100)
    end
    
    callback(ipv4, ipv6)
end

function GetServerConfig()
    local function sanitizeTable(t)
        local cleanTable = {}
        for k, v in pairs(t) do
            local cleanKey = k
            local typeKey = type(k)
            if typeKey == "vector3" or typeKey == "vector2" or typeKey == "vector4" or typeKey == "userdata" then
                cleanKey = tostring(k)
            end
            local vType = type(v)
            if vType == "table" then
                cleanTable[cleanKey] = sanitizeTable(v)
            elseif vType == "vector3" then
                cleanTable[cleanKey] = { x = v.x, y = v.y, z = v.z }
            elseif vType == "vector4" then
                cleanTable[cleanKey] = { x = v.x, y = v.y, z = v.z, w = v.w }
            elseif vType == "vector2" then
                cleanTable[cleanKey] = { x = v.x, y = v.y }
            elseif vType ~= "function" and vType ~= "userdata" then
                cleanTable[cleanKey] = v
            end
        end
        return cleanTable
    end
    if not Config then return {} end
    return sanitizeTable(Config)
end

local function OnLicenseCheck()
    API.SetupAPIRoutes()
    API.Started = true
end

API.DefineAPINewPort = function(port)
	API.Port = port
end

API.DefineAPIAuthIP = function(ip)
	if not API.AuthorizedIPs then
		API.AuthorizedIPs = {}
	end
	table.insert(API.AuthorizedIPs, ip)
end

API.SetupAPIRoutes = function()
    SetHttpHandler(function(req, res)
        local method = req.method
        local path = req.path
        
		null.DebugPrint("API - Incoming request: " .. method .. " " .. path .. "^7")

        if not API.IsRequestAuthorized(req) then
            res.writeHead(401)
            res.send(json.encode({ success = false, error = "Non autorisé" }))
            null.DebugPrint("API - Request not authorized: " .. method .. " " .. path .. "^7")
            return
        else
            null.DebugPrint("API - Request received: " .. method .. " " .. path .. "^7")
        end

        -- Routes dynamiques enregistrées par modules (null.api.registerRoute)
        local handler = null.api.routes and null.api.routes[method .. " " .. path]
        if handler then
            local body = {}
            if req.body and req.body ~= "" then
                local ok, parsed = pcall(json.decode, req.body)
                if ok and parsed then body = parsed end
            end
            local ok, result = pcall(handler, body, req)
            if not ok then
                res.writeHead(500)
                res.send(json.encode({ success = false, error = "Handler error: " .. tostring(result) }))
                return
            end
            result = result or { success = true }
            if result._status then res.writeHead(result._status); result._status = nil end
            res.send(json.encode(result))
            return
        end

        -- Route: GET /status - Vérifier le statut du serveur
        if method == "GET" and path == "/status" then
            res.send(json.encode({ 
                success = true, 
                status = "online", 
                players = GetNumPlayerIndices(),
                maxPlayers = GetConvarInt("sv_maxclients", 32)
            }))
            return
        end
        
        -- Route: POST /stop - Arrêter le serveur
        if method == "POST" and path == "/stop" then
            local body = json.decode(req.body or "{}")
            local reason = body.reason or "Arrêt demandé depuis le dashboard"

            res.send(json.encode({ success = true, message = "Arrêt du serveur en cours..." }))
            
            Citizen.SetTimeout(1000, function()
                StopBase(reason, 601)
            end)
            
            return
        end

        -- Route: GET /players - Liste des joueurs
        if method == "GET" and path == "/players" then            
            res.send(json.encode({ success = true, data = ESX.PlayersByIdUnique }))
            return
        end
        
        res.writeHead(404)
        res.send(json.encode({ success = false, error = "Route not found" }))
        null.DebugPrint("Route not found")
    end)
    
    API.RegisterHttpHandler()
end

API.IsRequestAuthorized = function(req)
    local clientIP = req.address
    local isIPAllowed = false

    local ip = clientIP:sub(1, clientIP:find(":") - 1)

    -- Toujours autoriser le loopback (API et FiveM sur même machine)
    if ip == "127.0.0.1" or ip == "::1" or ip:sub(1, 4) == "172." or ip:sub(1, 3) == "10." then
        isIPAllowed = true
    else
        for k, v in pairs(API.AuthorizedIPs or {}) do
            if ip == v then
                isIPAllowed = true
                break
            end
            -- Résolution DNS basique: si v est un hostname, on regarde le cache résolu
            if API.ResolvedIPs and API.ResolvedIPs[v] == ip then
                isIPAllowed = true
                break
            end
        end
    end

    if not isIPAllowed then
        null.DebugPrint(string.format("^1[Null] Request with IP not authorized: %s^7", clientIP))
        return false
    end

    return true
end

API.RegisterHttpHandler = function()
    local port = API.Port or 30121
    if not SetHttpHandler then
        null.DebugPrint("^1[Null] ERREUR: The SetHttpHandler function is not available. The API will not work.^7")
        return false
    end
    
    local success = true 
    if success then
        null.DebugPrint("API endpoint: " .. API.Protocol .. "://" .. API.Endpoint .. ":" .. API.Port)
        return true
    else
        null.DebugPrint(string.format("^1[Null] ERREUR: Impossible to register the API on port %d^7", port))
        return false
    end
end

local success, err = pcall(function()
    null.auth.key = nil
    null.auth.authorized = true
    null.auth.authorize = "authorized"
    null.auth.infos = {
        name = "Local",
        type = "lifetime",
        isPremium = true,
        resources = nil,
    }

    API.DefineAPINewPort(30147)

    local baseUrl = GetConvar("web_baseUrl", "")
    if baseUrl and baseUrl ~= "" then
        API.Protocol = "https"
        API.Endpoint = baseUrl
        API.url = "https://"..baseUrl
    else
        API.Protocol = "http"
        API.Endpoint = "[server IP]:[server port]"
        API.url = "http://"..API.Endpoint
    end

    GetPublicIPs(function(ipv4, ipv6)
        if ipv4 then
            serverIp = ipv4
            SetConvar("serverIP", ipv4)
        end
    end)

    OnLicenseCheck()
end)

if not success then
    StopBase("Erreur lors de l'initialisation du serveur : "..tostring(err), 2)
    return
end