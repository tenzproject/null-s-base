local scenariosToDisable = {
    'WORLD_VEHICLE_ATTRACTOR',
    'WORLD_VEHICLE_AMBULANCE',
    'WORLD_VEHICLE_BICYCLE_BMX',
    'WORLD_VEHICLE_BICYCLE_BMX_BALLAS',
    'WORLD_VEHICLE_BICYCLE_BMX_FAMILY',
    'WORLD_VEHICLE_BICYCLE_BMX_HARMONY',
    'WORLD_VEHICLE_BICYCLE_BMX_VAGOS',
    'WORLD_VEHICLE_BICYCLE_MOUNTAIN',
    'WORLD_VEHICLE_BICYCLE_ROAD',
    'WORLD_VEHICLE_BIKE_OFF_ROAD_RACE',
    'WORLD_VEHICLE_BIKER',
    'WORLD_VEHICLE_BOAT_IDLE',
    'WORLD_VEHICLE_BOAT_IDLE_ALAMO',
    'WORLD_VEHICLE_BOAT_IDLE_MARQUIS',
    'WORLD_VEHICLE_BROKEN_DOWN',
    'WORLD_VEHICLE_BUSINESSMEN',
    'WORLD_VEHICLE_HELI_LIFEGUARD',
    'WORLD_VEHICLE_CLUCKIN_BELL_TRAILER',
    'WORLD_VEHICLE_CONSTRUCTION_SOLO',
    'WORLD_VEHICLE_CONSTRUCTION_PASSENGERS',
    'WORLD_VEHICLE_DRIVE_PASSENGERS',
    'WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED',
    'WORLD_VEHICLE_DRIVE_SOLO',
    'WORLD_VEHICLE_FIRE_TRUCK',
    'WORLD_VEHICLE_EMPTY',
    'WORLD_VEHICLE_MARIACHI',
    'WORLD_VEHICLE_MECHANIC',
    'WORLD_VEHICLE_MILITARY_PLANES_BIG',
    'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
    'WORLD_VEHICLE_PARK_PARALLEL',
    'WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN',
    'WORLD_VEHICLE_PASSENGER_EXIT',
    'WORLD_VEHICLE_POLICE_BIKE',
    'WORLD_VEHICLE_POLICE_CAR',
    'WORLD_VEHICLE_POLICE',
    'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
    'WORLD_VEHICLE_QUARRY',
    'WORLD_VEHICLE_SALTON',
    'WORLD_VEHICLE_SALTON_DIRT_BIKE',
    'WORLD_VEHICLE_SECURITY_CAR',
    'WORLD_VEHICLE_STREETRACE',
    'WORLD_VEHICLE_TOURBUS',
    'WORLD_VEHICLE_TOURIST',
    'WORLD_VEHICLE_TANDL',
    'WORLD_VEHICLE_TRACTOR',
    'WORLD_VEHICLE_TRACTOR_BEACH',
    'WORLD_VEHICLE_TRUCK_LOGS',
    'WORLD_VEHICLE_TRUCKS_TRAILERS',
    'WORLD_VEHICLE_DISTANT_EMPTY_GROUND'
}

local npcEnabled = false


function EnableNPC(enable, pedBudget, vehBudget)
    npcEnabled = enable
    
    if enable then
        DisableVehicleDistantlights(false)
        SetPedPopulationBudget(pedBudget or 3)
        SetVehiclePopulationBudget(vehBudget or 3)
        SetRandomEventFlag(true)
        
        for _, scenario in ipairs(scenariosToDisable) do
            SetScenarioTypeEnabled(scenario, true)
        end
    else
        DisableVehicleDistantlights(true)
        SetPedPopulationBudget(0)
        SetVehiclePopulationBudget(0)
        SetRandomEventFlag(false)
        
        for _, scenario in ipairs(scenariosToDisable) do
            SetScenarioTypeEnabled(scenario, false)
        end
    end
end

exports('EnableNPC', EnableNPC)

CreateThread(LPH_NO_VIRTUALIZE(function()
    EnableNPC(not Config._core.World.DisableNPC)
    
    if Config._core.World.DisableNPC then
        while true do
            if not npcEnabled then
                for i = 1, 3 do
                    SetPedDensityMultiplierThisFrame(0.0)
                    SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                end
            end
            Wait(50) 
        end
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    if not Config._core.World.DisablePolice then return end

    StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
    SetAudioFlag("PoliceScannerDisabled", true)

    for i = 1, 12 do
        EnableDispatchService(i, false)
        Citizen.InvokeNative(0xDC0F817884CDD856, i, false) -- SetDispatchIdealSpawnDistance
    end
    
    while true do
        local playerId = PlayerId()
        local coords = GetEntityCoords(PlayerPedId())
        
        ClearAreaOfCops(coords.x, coords.y, coords.z, 400.0, 0)
        
        if GetPlayerWantedLevel(playerId) ~= 0 then
            SetPlayerWantedLevel(playerId, 0, false)
            SetPlayerWantedLevelNow(playerId, false)
            ClearPlayerWantedLevel(playerId)
            SetPlayerWantedLevelNoDrop(playerId, 0, false)
        end
        
        Wait(Config._core.World.ClearPoliceInterval)
    end
end))

local requestedIpl = {
    "h4_islandairstrip",
    "h4_islandairstrip_props",
    "h4_islandx_mansion",
    "h4_islandx_mansion_props",
    "h4_islandx_props",
    "h4_islandxdock",
    "h4_islandxdock_props",
    "h4_islandxdock_props_2",
    "h4_islandxtower",
    "h4_islandx_maindock",
    "h4_islandx_maindock_props",
    "h4_islandx_maindock_props_2",
    "h4_IslandX_Mansion_Vault",
    "h4_islandairstrip_propsb",
    "h4_beach",
    "h4_beach_props",
    "h4_beach_bar_props",
    "h4_islandx_barrack_props",
    "h4_islandx_checkpoint",
    "h4_islandx_checkpoint_props",
    "h4_islandx_Mansion_Office",
    "h4_islandx_Mansion_LockUp_01",
    "h4_islandx_Mansion_LockUp_02",
    "h4_islandx_Mansion_LockUp_03",
    "h4_islandairstrip_hangar_props",
    "h4_IslandX_Mansion_B",
    "h4_islandairstrip_doorsclosed",
    "h4_Underwater_Gate_Closed",
    "h4_mansion_gate_closed",
    "h4_aa_guns",
    "h4_IslandX_Mansion_GuardFence",
    "h4_IslandX_Mansion_Entrance_Fence",
    "h4_IslandX_Mansion_B_Side_Fence",
    "h4_IslandX_Mansion_Lights",
    "h4_islandxcanal_props",
    "h4_beach_props_party",
    "h4_islandX_Terrain_props_06_a",
    "h4_islandX_Terrain_props_06_b",
    "h4_islandX_Terrain_props_06_c",
    "h4_islandX_Terrain_props_05_a",
    "h4_islandX_Terrain_props_05_b",
    "h4_islandX_Terrain_props_05_c",
    "h4_islandX_Terrain_props_05_d",
    "h4_islandX_Terrain_props_05_e",
    "h4_islandX_Terrain_props_05_f",
    "H4_islandx_terrain_01",
    "H4_islandx_terrain_02",
    "H4_islandx_terrain_03",
    "H4_islandx_terrain_04",
    "H4_islandx_terrain_05",
    "H4_islandx_terrain_06",
    "h4_ne_ipl_00",
    "h4_ne_ipl_01",
    "h4_ne_ipl_02",
    "h4_ne_ipl_03",
    "h4_ne_ipl_04",
    "h4_ne_ipl_05",
    "h4_ne_ipl_06",
    "h4_ne_ipl_07",
    "h4_ne_ipl_08",
    "h4_ne_ipl_09",
    "h4_nw_ipl_00",
    "h4_nw_ipl_01",
    "h4_nw_ipl_02",
    "h4_nw_ipl_03",
    "h4_nw_ipl_04",
    "h4_nw_ipl_05",
    "h4_nw_ipl_06",
    "h4_nw_ipl_07",
    "h4_nw_ipl_08",
    "h4_nw_ipl_09",
    "h4_se_ipl_00",
    "h4_se_ipl_01",
    "h4_se_ipl_02",
    "h4_se_ipl_03",
    "h4_se_ipl_04",
    "h4_se_ipl_05",
    "h4_se_ipl_06",
    "h4_se_ipl_07",
    "h4_se_ipl_08",
    "h4_se_ipl_09",
    "h4_sw_ipl_00",
    "h4_sw_ipl_01",
    "h4_sw_ipl_02",
    "h4_sw_ipl_03",
    "h4_sw_ipl_04",
    "h4_sw_ipl_05",
    "h4_sw_ipl_06",
    "h4_sw_ipl_07",
    "h4_sw_ipl_08",
    "h4_sw_ipl_09",
    "h4_islandx_mansion",
    "h4_islandxtower_veg",
    "h4_islandx_sea_mines",
    "h4_islandx",
    "h4_islandx_barrack_hatch",
    "h4_islandxdock_water_hatch",
    "h4_beach_party"
}

CreateThread(function()
    for i = #requestedIpl, 1, -1 do
        RequestIpl(requestedIpl[i])
        requestedIpl[i] = nil
    end

    requestedIpl = nil
end)

CreateThread(function()
    Wait(2500)
    SetDeepOceanScaler(0.0)
end)

CreateThread(LPH_NO_VIRTUALIZE(function()
    local islandLoaded = false
    local islandCoords = vector3(4840.571, -5174.425, 2.0)

    while true do
        local pCoords = GetEntityCoords(PlayerPedId())

        if #(pCoords - islandCoords) < 2000.0 then
            if not islandLoaded then
                islandLoaded = true
                Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 1) -- island path nodes (from Disquse)
            end
        else
            if islandLoaded then
                islandLoaded = false
                Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 0)
            end
        end

        Wait(5000)
    end
end))


local _isCloseToCayo = false
local _isCayoMinimapLoaded = false

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local isCloseToCayo<const> = #(GetEntityCoords(PlayerPedId()) - vector3(4858.0, -5171.0, 2.0)) < 2200.0

        if _isCloseToCayo ~= isCloseToCayo then
            _isCloseToCayo = isCloseToCayo
            _isCayoMinimapLoaded = isCloseToCayo
            SetToggleMinimapHeistIsland(_isCloseToCayo)
        end

        Wait(5000)
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local wait = 500

        if IsPauseMenuActive() and not IsMinimapInInterior() then
            if _isCayoMinimapLoaded then
                _isCayoMinimapLoaded = false
                SetToggleMinimapHeistIsland(false)
            end
            SetRadarAsExteriorThisFrame()
            SetRadarAsInteriorThisFrame(GetHashKey("h4_fake_islandx"), 4700.0, -5145.0, 0, 0)
            wait = 0

        elseif not _isCayoMinimapLoaded and _isCloseToCayo then
            _isCayoMinimapLoaded = true
            SetToggleMinimapHeistIsland(true)
        end
        Wait(wait)
    end
end))


CreateThread(LPH_NO_VIRTUALIZE(function()
    Wait(Config._core.World.CleanupInterval)
    
    while true do
        ClearAllBrokenGlass()
        ClearAllHelpMessages()
        LeaderboardsReadClearAll()
        ClearBrief()
        ClearGpsFlags()
        ClearPrints()
        ClearSmallPrints()
        ClearReplayStats()
        LeaderboardsClearCacheData()
        ClearFocus()
        ClearHdArea()
        
        Wait(Config._core.World.CleanupInterval)
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    local gangs = {
        "AMBIENT_GANG_LOST",
        "AMBIENT_GANG_SALVA", 
        "AMBIENT_GANG_HILLBILLY",
        "AMBIENT_GANG_BALLAS",
        "AMBIENT_GANG_MEXICAN",
        "AMBIENT_GANG_FAMILY",
        "AMBIENT_GANG_MARABUNTE",
        "GANG_1",
        "GANG_2",
        "GANG_9",
        "GANG_10",
        "FIREMAN",
        "MEDIC",
        "COP"
    }
    
    local playerHash = GetHashKey('PLAYER')
    
    for _, gang in ipairs(gangs) do
        SetRelationshipBetweenGroups(1, GetHashKey(gang), playerHash)
    end
end))

local createdPeds = {}

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	for k, v in ipairs(Config.WorldPeds) do
		ESX.Streaming.RequestModel(GetHashKey(v.model))
		local storePed = CreatePed(4, GetHashKey(v.model), v.pos.x, v.pos.y, v.pos.z, v.pos.w, false, false)
		--SetPedRandomComponentVariation(storePed)
		--SetPedRandomProps(storePed)
		SetBlockingOfNonTemporaryEvents(storePed, false)
		FreezeEntityPosition(storePed, true)
		DisablePedPainAudio(storePed, true)
		SetPedSeeingRange(storePed, 0)
		SetPedFleeAttributes(storePed, 0, 0)
		SetPedArmour(storePed, 200)
		SetPedSuffersCriticalHits(storePed, false)
		SetPedMaxHealth(storePed, 200)
		SetPedDiesWhenInjured(storePed, true)
		SetEntityInvincible(storePed, true)
		SetAmbientVoiceName(storePed, v.voice)
		TaskStartScenarioInPlace(storePed, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
		SetModelAsNoLongerNeeded(GetHashKey(v.model))
		table.insert(createdPeds, { ped = storePed, name = v.label })
	end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
		while true do
			Citizen.Wait(100)
			for _, v in pairs(createdPeds) do
				if IsPedFleeing(v.ped) then
					ClearPedTasks(v.ped)
					TaskStartScenarioInPlace(v.ped, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
				end
			end
		end
end))

local function EnumerateVehicles()
    return coroutine.wrap(function()
        local iter, id = FindFirstVehicle()
        if not id or id == 0 then
            EndFindVehicle(iter)
            return
        end
        
        local next = true
        repeat
            coroutine.yield(id)
            next, id = FindNextVehicle(iter)
        until not next
        
        EndFindVehicle(iter)
    end)
end

function DeleteAllBrokenVehicles()
    local count = 0
    
    for vehicle in EnumerateVehicles() do
        if GetEntityHealth(vehicle) == 0 then
            SetEntityAsMissionEntity(vehicle, false, false)
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    return count
end

exports('DeleteAllBrokenVehicles', DeleteAllBrokenVehicles)

RegisterNetEvent('null:world:clearBrokenVehicles', function()
    local count = DeleteAllBrokenVehicles()
    ESX.ShowAdvancedNotification(
        "CASSE AUTOMOBILE", 
        "Informations", 
        count .. " épaves ont été ramassées !", 
        "CHAR_REDSIDE"
    )
end)

null.InitPrint('^2World module loaded^7')
