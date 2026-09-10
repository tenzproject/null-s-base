local promise = promise
local Await = Citizen.Await
local resourceName = GetCurrentResourceName()
local GetResourceState = GetResourceState

-- Configuration pour le logger de requêtes lourdes
local LoggerConfig = {
    enabled = true,
    -- Temps d'exécution (ms)
    slowQueryThreshold = 100,      -- Seuil pour une requête lente
    verySlowQueryThreshold = 500,  -- Seuil pour une requête très lente
    -- Taille des résultats
    largeResultThreshold = 100,    -- Nombre de lignes considéré comme gros résultat
    veryLargeResultThreshold = 500, -- Nombre de lignes considéré comme très gros
    -- Affichage
    printToConsole = true,         -- Afficher dans la console
    logStackTrace = true,          -- Afficher la stack trace de l'appel
    -- Filtrage
    minQueryLength = 25            -- Ignorer les requêtes trop courtes
}

-- Override config via convar: set mysql_logger_enabled true, set mysql_logger_slow_threshold 50
local function loadConvarConfig()
    local enabled = GetConvarInt("mysql_logger_enabled", -1)
    if enabled ~= -1 then LoggerConfig.enabled = enabled == 1 end
    
    local slowThreshold = GetConvarInt("mysql_logger_slow_threshold", -1)
    if slowThreshold > 0 then LoggerConfig.slowQueryThreshold = slowThreshold end
    
    local largeThreshold = GetConvarInt("mysql_logger_large_threshold", -1)
    if largeThreshold > 0 then LoggerConfig.largeResultThreshold = largeThreshold end
end
loadConvarConfig()

-- Fonction de logging pour les requêtes lourdes
local function logHeavyQuery(query, executionTime, rowCount, queryType, callerInfo)
    if not LoggerConfig.enabled then return end
    if not LoggerConfig.printToConsole then return end
    if not query or #query < LoggerConfig.minQueryLength then return end
    
    local isSlow = executionTime >= LoggerConfig.slowQueryThreshold
    local isVerySlow = executionTime >= LoggerConfig.verySlowQueryThreshold
    local isLarge = rowCount and rowCount >= LoggerConfig.largeResultThreshold
    local isVeryLarge = rowCount and rowCount >= LoggerConfig.veryLargeResultThreshold
    
    -- Ne log que si c'est lent ou volumineux
    if not isSlow and not isLarge then return end
    
    local severity = "INFO"
    local color = "^3" -- Jaune
    if isVerySlow or isVeryLarge then
        severity = "WARNING"
        color = "^1" -- Rouge
    end
    
    local msg = string.format(
        "%s[MySQL.%s][%s]^7 Requête %s | Temps: %.2fms | Lignes: %s%s^7",
        color,
        resourceName,
        severity,
        queryType or "UNKNOWN",
        executionTime,
        rowCount and tostring(rowCount) or "N/A",
        callerInfo and (" | Caller: " .. callerInfo) or ""
    )
    
    print(msg)
    
    -- Afficher la requête tronquée si très lente/volumineuse
    if isVerySlow or isVeryLarge then
        local truncatedQuery = query:sub(1, 200)
        if #query > 200 then truncatedQuery = truncatedQuery .. "..." end
        truncatedQuery = truncatedQuery:gsub("%s+", " ") -- Normaliser les espaces
        print(string.format("  ^8Query: %s^7", truncatedQuery))
    end
    
    -- Stack trace
    if LoggerConfig.logStackTrace and (isVerySlow or isVeryLarge) then
        local trace = debug.traceback("", 2)
        local lines = {}
        for line in trace:gmatch("[^\r\n]+") do
            if not line:match("MySQL%.lua") and not line:match("C%-function") then
                table.insert(lines, line:match("(.-)%s*$") or line)
                if #lines >= 5 then break end
            end
        end
        if #lines > 0 then
            print("  ^8Stack:^7")
            for _, line in ipairs(lines) do
                print(string.format("    %s", line:gsub("^%s+", "")))
            end
        end
    end
    
    -- Suggestions d'optimisation
    if isVerySlow then
        print("  ^3Suggestion: Vérifiez les INDEX sur les colonnes utilisées dans WHERE/JOIN^7")
    end
    if isVeryLarge then
        print("  ^3Suggestion: Utilisez LIMIT ou une pagination pour les gros résultats^7")
    end
end

-- Compter les lignes dans un résultat
local function countRows(result)
    if type(result) ~= "table" then return 0 end
    local count = 0
    if result[1] ~= nil then
        -- Tableau de résultats (SELECT)
        count = #result
    elseif result.affectedRows then
        -- Résultat d'UPDATE/DELETE/INSERT
        count = tonumber(result.affectedRows) or 0
    elseif result.insertId then
        count = 1
    end
    return count
end

-- Récupérer l'info du caller
local function getCallerInfo()
    local info = debug.getinfo(4, "Snl")
    if not info then return nil end
    return string.format("%s:%d", info.short_src or info.source or "?", info.currentline or 0)
end

local options = {
	return_callback_errors = false
}

for i = 1, GetNumResourceMetadata(resourceName, 'mysql_option') do
	local option = GetResourceMetadata(resourceName, 'mysql_option', i - 1)
	options[option] = true
end

local function await(fn, query, parameters)
	local p = promise.new()

	fn(nil, query, parameters, function(result, error)
		if error then
			return p:reject(error)
		end

		p:resolve(result)
	end, resourceName, true)

	return Await(p)
end

local type = type
local queryStore = {}

local function safeArgs(query, parameters, cb, transaction)
	local queryType = type(query)

	if queryType == 'number' then
		query = queryStore[query]
		assert(query, "First argument received invalid query store reference")
	elseif transaction then
		if queryType ~= 'table' then
			error(("First argument expected table, received '%s'"):format(query))
		end
	elseif queryType ~= 'string' then
		error(("First argument expected string, received '%s'"):format(query))
	end

	if parameters then
		local paramType = type(parameters)

		if paramType ~= 'table' and paramType ~= 'function' then
			error(("Second argument expected table or function, received '%s'"):format(parameters))
		end

		if paramType == 'function' or parameters.__cfx_functionReference then
			cb = parameters
			parameters = nil
		end
	end

	if cb and parameters then
		local cbType = type(cb)

		if cbType ~= 'function' and (cbType == 'table' and not cb.__cfx_functionReference) then
			error(("Third argument expected function, received '%s'"):format(cb))
		end
	end

	return query, parameters, cb
end

-- null-deps bundle : oxmysql vit dans la ressource null-deps.
local oxmysql = exports['null-deps']

local mysql_method_mt = {
	__call = function(self, query, parameters, cb)
		query, parameters, cb = safeArgs(query, parameters, cb, self.method == 'transaction')
		
		local startTime = GetGameTimer()
		local callerInfo = getCallerInfo()
		
		-- Wrapper du callback pour mesurer le temps et compter les lignes
		local wrappedCb = nil
		if cb then
			wrappedCb = function(result, error)
				local execTime = GetGameTimer() - startTime
				local rowCount = countRows(result)
				logHeavyQuery(query, execTime, rowCount, self.method, callerInfo)
				return cb(result, error)
			end
		end
		
		return oxmysql[self.method](nil, query, parameters, wrappedCb, resourceName, options.return_callback_errors)
	end
}

local MySQL = setmetatable(MySQL or {}, {
	__index = function(_, index)
		return function(query, parameters, cb)
			local startTime = GetGameTimer()
			local callerInfo = getCallerInfo()
			
			-- Wrapper du callback
			local wrappedCb = nil
			if cb and type(cb) == "function" then
				wrappedCb = function(result, error)
					local execTime = GetGameTimer() - startTime
					local rowCount = countRows(result)
					logHeavyQuery(query, execTime, rowCount, index, callerInfo)
					return cb(result, error)
				end
			end
			
			local result = oxmysql[index](nil, query, parameters, wrappedCb, resourceName, options.return_callback_errors)
			
			-- Si pas de callback (await), logger maintenant
			if not cb then
				local execTime = GetGameTimer() - startTime
				local rowCount = countRows(result)
				logHeavyQuery(query, execTime, rowCount, index, callerInfo)
			end
			
			return result
		end
	end
})

for _, method in pairs({
	'scalar', 'single', 'query', 'insert', 'update', 'prepare', 'transaction', 'rawExecute',
}) do
	MySQL[method] = setmetatable({
		method = method,
		await = function(query, parameters)
			query, parameters = safeArgs(query, parameters, nil, method == 'transaction')
			
			local startTime = GetGameTimer()
			local callerInfo = getCallerInfo()
			
			-- Exécuter la requête
			local result = await(oxmysql[method], query, parameters)
			
			-- Mesurer le temps et logger
			local execTime = GetGameTimer() - startTime
			local rowCount = countRows(result)
			logHeavyQuery(query, execTime, rowCount, method .. " (sync)", callerInfo)
			
			return result
		end
	}, mysql_method_mt)
end

local alias = {
	fetchAll = 'query',
	fetchScalar = 'scalar',
	fetchSingle = 'single',
	insert = 'insert',
	execute = 'update',
	transaction = 'transaction',
	prepare = 'prepare'
}

local alias_mt = {
	__index = function(self, key)
		if alias[key] then
			local method = MySQL[alias[key]]
			MySQL.Async[key] = method
			MySQL.Sync[key] = method.await
			alias[key] = nil
			return self[key]
		end
	end
}

local function addStore(query, cb)
	assert(type(query) == 'string', 'The SQL Query must be a string')

	local storeN = #queryStore + 1
	queryStore[storeN] = query

	return cb and cb(storeN) or storeN
end

MySQL.Sync = setmetatable({ store = addStore }, alias_mt)
MySQL.Async = setmetatable({ store = addStore }, alias_mt)

local function onReady(cb)
	-- null-deps bundle : check sur null-deps qui héberge oxmysql.
	while GetResourceState('null-deps') ~= 'started' do
		Wait(50)
	end

	oxmysql.awaitConnection()

	return cb and cb() or true
end

MySQL.ready = setmetatable({
	await = onReady
}, {
	__call = function(_, cb)
		Citizen.CreateThreadNow(function() onReady(cb) end)
	end,
})

function MySQL.startTransaction(cb)
	return oxmysql:startTransaction(cb, resourceName)
end

_ENV.MySQL = MySQL
