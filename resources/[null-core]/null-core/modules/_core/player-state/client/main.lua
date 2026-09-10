PlayerState = {
    ped = 0,
    playerId = 0,
    serverId = 0,
    coords = vector3(0, 0, 0),
    heading = 0.0,
    
    -- États Player
    isDead = false,
    isSwimming = false,
    isFalling = false,
    isRunning = false,
    isCuffed = false,
    isInAction = false,
    isInSafeZone = false,

    -- Options
    WorldPropsInfo = false,

    -- Véhicule
    isInVehicle = false,
    vehicle = 0,
    vehicleSeat = -2,

    realisticDrive = true,
    
    -- Arme
    weapon = `WEAPON_UNARMED`,
    lastWeapon = `WEAPON_UNARMED`,
    isAiming = false,
    isShooting = false,
    
    -- Vêtements/Accessoires
    Clothes = {},

    -- Comptes
    accounts = {
        cash = 0,
        bank = 0,
        dirtycash = 0
    },
    
    -- Illégals
    Illegals = {
        laboratories = {
            inLabo = false,
        }
    },

    -- Menu pauseWe
    inPauseMenu = false,
    
    -- Sexe du personnage
    sex = "male",
    
    -- AFK
    inAfk = false,
    afkTimer = 0,
    afkPoint = 0,
    
    -- Zones
    inGangZone = false,
    gangZoneName = nil,
    
    -- Divers
    bucket = 0, -- instance
    safeZoneName = nil,
    
    -- VIP 
    vip = {
        isVip = false,
        type = nil,        -- "Basic", "Premium", etc.
        time = {
            days = 0,
            hours = 0,
            minutes = 0,
            remaining = 0  -- temps restant en minutes
        },
        loaded = false
    },
}

local lastPauseState = false

function GetPlayerState()
    return PlayerState
end

function GetPlayerStateKey(key)
    return PlayerState[key]
end

function SetPlayerStateKey(key, value)
    PlayerState[key] = value
end

exports('GetPlayerState', GetPlayerState)
exports('GetPlayerStateKey', GetPlayerStateKey)
exports('SetPlayerStateKey', SetPlayerStateKey)

function MyPlayerGet(value)
    return PlayerState[value]
end

function MyPlayerSet(index, value)
    PlayerState[index] = value
end

function GetPlayerKey(key)
    return PlayerState[key]
end

local function InitializePlayerIds()
    PlayerState.ped = PlayerPedId()
    PlayerState.playerId = PlayerId()
    PlayerState.serverId = GetPlayerServerId(PlayerState.playerId)
end

local function UpdateDynamic()
    InitializePlayerIds()
    local ped = PlayerState.ped
    
    PlayerState.isInVehicle = IsPedInAnyVehicle(ped, false)
    
    if PlayerState.isInVehicle then
        PlayerState.vehicle = GetVehiclePedIsIn(ped, false)
    else
        PlayerState.vehicle = 0
        PlayerState.vehicleSeat = -2
    end
    
    PlayerState.isDead = IsEntityDead(ped)
    PlayerState.isAiming = IsPlayerFreeAiming(PlayerState.playerId)
    PlayerState.isShooting = IsPedShooting(ped)
end

local function UpdateCoords()
    PlayerState.coords = GetEntityCoords(PlayerState.ped)
    PlayerState.heading = GetEntityHeading(PlayerState.ped)
end

local function UpdateSlow()
    local ped = PlayerState.ped
    local playerId = PlayerState.playerId
    
    PlayerState.isSwimming = IsPedSwimming(ped)
    PlayerState.isFalling = IsPedFalling(ped)
    PlayerState.isRunning = IsPedRunning(ped)
    
    if PlayerState.isInVehicle and PlayerState.vehicle ~= 0 then
        for i = -1, GetVehicleMaxNumberOfPassengers(PlayerState.vehicle) do
            if GetPedInVehicleSeat(PlayerState.vehicle, i) == ped then
                PlayerState.vehicleSeat = i
                break
            end
        end
    end
    
    SetEntityMaxHealth(ped, 200)
    SetPedCanLosePropsOnDamage(ped, false, 0)
    --ResetPlayerStamina(playerId)
    SetPlayerHealthRechargeMultiplier(playerId, 0.0)
end

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local isPaused = IsPauseMenuActive()
        
        if isPaused ~= lastPauseState then
            lastPauseState = isPaused
            PlayerState.inPauseMenu = isPaused
            TriggerEvent('null:player:pauseMenu', isPaused)
        end
        
        Wait(100)
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do 
        Wait(0)
        DisableControlAction(0, 37, true) -- weapon wheel
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    while not ESX or not ESX.PlayerLoaded do
        Wait(100)
    end
    
    InitializePlayerIds()
    
    while true do
        UpdateDynamic()
        
        if PlayerState.isInVehicle then
            Wait(Config._core.PlayerState.UpdateIntervalFast)
        else
            Wait(Config._core.PlayerState.UpdateIntervalNormal)
        end
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    while not ESX or not ESX.PlayerLoaded do
        Wait(100)
    end
    
    while true do
        UpdateCoords()
        Wait(Config._core.PlayerState.UpdateIntervalNormal)
    end
end))

CreateThread(LPH_NO_VIRTUALIZE(function()
    while not ESX or not ESX.PlayerLoaded do
        Wait(100)
    end
    
    while true do
        UpdateSlow()
        Wait(Config._core.PlayerState.UpdateIntervalSlow)
    end
end))

AddEventHandler('playerSpawned', function()
    Wait(100)
    InitializePlayerIds()
end)

local function SyncAccounts()
    if not ESX or not ESX.PlayerData or not ESX.PlayerData.accounts then return end
    
    for _, account in pairs(ESX.PlayerData.accounts) do
        if account.name == 'cash' then
            PlayerState.accounts.cash = account.money
            StatSetInt(`MP0_WALLET_BALANCE`, account.money)
        elseif account.name == 'bank' then
            PlayerState.accounts.bank = account.money
            StatSetInt(`BANK_BALANCE`, account.money)
        elseif account.name == 'dirtycash' then
            PlayerState.accounts.dirtycash = account.money
        end
    end
    
    RemoveMultiplayerBankCash()
    RemoveMultiplayerWalletCash()
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Wait(500)
    SyncAccounts()
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    if account.name == 'cash' then
        PlayerState.accounts.cash = account.money
        StatSetInt(`MP0_WALLET_BALANCE`, account.money)
    elseif account.name == 'bank' then
        PlayerState.accounts.bank = account.money
        StatSetInt(`BANK_BALANCE`, account.money)
    elseif account.name == 'dirtycash' then
        PlayerState.accounts.dirtycash = account.money
    end
    
    RemoveMultiplayerBankCash()
    RemoveMultiplayerWalletCash()

    null.DebugPrint("PlayerState Accounts Sync : "..account.name.." - "..account.money)

    SyncAccounts()
end)

RegisterNetEvent('Null:skinchanger:change', function(key, val)
    if key == "sex" then
        PlayerState.sex = (val == 1) and "female" or "male"
    end
end)

RegisterNetEvent('Null:esx:changeBucket', function(value)
    PlayerState.bucket = value
    TriggerEvent('null:player:bucketChanged', value)
end)

RegisterNetEvent('null:player:setWeapon', function(weaponHash)
    PlayerState.lastWeapon = PlayerState.weapon
    PlayerState.weapon = weaponHash
    
    if PlayerState.weapon ~= PlayerState.lastWeapon then
        TriggerEvent('null:player:weaponChanged', PlayerState.weapon, PlayerState.lastWeapon)
    end
end)

null.InitPrint('^2Player State module loaded^7')
