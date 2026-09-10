RegisterNetEvent("contextmenu:me_response")
AddEventHandler("contextmenu:me_response", function(msg, peds)
    displayText(peds, Config.me_color .. Config.me_prefix .. " " .. msg)
end)

RegisterNetEvent("contextmenu:NetworkOverrideClockTime_response")
AddEventHandler("contextmenu:NetworkOverrideClockTime_response", function(time)
    NetworkOverrideClockTime(time, 0, 0)
end)

RegisterNetEvent("contextmenu:SetWeatherType_response")
AddEventHandler("contextmenu:SetWeatherType_response", function(type)
    SetWeatherTypePersist(type)
    SetWeatherTypeNow(type)
    SetWeatherTypeNowPersist(type)
end)


function GetPlayerMoneyDirty()
    local money = 'dirtycash'
    for i = 1, #ESX.GetPlayerData().accounts do 
        if ESX.GetPlayerData().accounts[i].name == money then
            return ESX.GetPlayerData().accounts[i].money
        end
    end
end

function GetPlayerMoneym()
    local money = 'cash'
    for i = 1, #ESX.GetPlayerData().accounts do
        if ESX.GetPlayerData().accounts[i].name == money then
            return ESX.GetPlayerData().accounts[i].money
        end
    end
end

OptimizationMode = false


RegisterCommand("fps", function()
    if OptimizationMode then 
        OptimizationMode = false
     --print("Optimization mode disabled")
    else
        OptimizationMode = true
     --print("Optimization mode enabled")
    end
end)




SetOptimizationMode = function(toggle)
    if OptimizationMode == toggle then return end
    OptimizationMode = toggle

    CreateThread((function()
        while OptimizationMode do
         --print("Optimization mode enabled")
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            DisableOcclusionThisFrame()
            SetDisableDecalRenderingThisFrame()
           -- OverrideLodscaleThisFrame(0.0)
            Wait(0)
        end
    end))

    CreateThread((function()
        while true do
            SetWeatherTypePersist("CLEAR")
            SetWeatherTypeNowPersist("CLEAR")
            SetWeatherTypeNow("CLEAR")
            SetOverrideWeather("CLEAR")
            local veh_pool = GetGamePool('CVehicle')
            RemoveParticleFxInRange(GetEntityCoords(PlayerPedId()), 50.0)
            for k,v in pairs(veh_pool) do
                if #(GetEntityCoords(PlayerPedId(), false) - GetEntityCoords(v, false)) < 100 then
                    local driver = GetPedInVehicleSeat(v, -1)
                    if not IsPedAPlayer(driver) and driver ~= 0 then
                        SetPedAlertness(driver, true)
                        SetPedAllowVehiclesOverride(driver, true)
                        SetPedAsEnemy(driver, true)
                        SetPedCombatAttributes(driver, 52)
                        SetPedEnableWeaponBlocking(driver, true)
                        SetPedSeeingRange(driver, 1000000.0)
                        SetPedHearingRange(driver, 1000000.0)
                        SetVehicleCanBeUsedByFleeingPeds(v, true)
                        SetVehicleIsRacing(v,true)
                        SetVehicleMaxSpeed(v,500.0)
                        StopPedSpeaking(driver, true)
                        SetDriverRacingModifier(driver,100.0)
                        SetDriverAbility(driver, 100.0)        -- values between 0.0 and 1.0 are allowed.
                        SetDriverAggressiveness(driver, 100.0) -- values between 0.0 and 1.0 are allowed.
                        SetDriveTaskMaxCruiseSpeed(driver,500.0)
                        SetVehicleLodMultiplier(v,0.0)
                        RemoveVehicleHighDetailModel(v)
                        SetVehicleEnveffScale(v,0.0)
                        SetDisableSuperdummyMode(v)
                        SetDisableVehicleUnk(v,true)
                        SetDisableVehicleUnk_2(v,true)
                        SetVehicleShadowEffect(v,-1,-1)
                        SetFarDrawVehicles(false)
                        TaskVehicleTempAction(driver,v,32,10)
                        TaskVehicleDriveToCoordLongrange(driver, v, GetEntityCoords(v, false)+vec3(100.0,100.0,100.0), 400.0, 787260, 10.0)
                        SetDriveTaskCruiseSpeed(PlayerPedId(),300.0)
                        SetDriveTaskMaxCruiseSpeed(true,300.0)
                        SetVehicleHandlingField(v, "CHandlingData", "AIHandling", "SPORTS_CAR")
                    end
                end
            end
            Wait(2000)
        end
    end))

    CreateThread((function()
        while true do
            local ped = PlayerPedId()
            for k,v in pairs(GetGamePool('CPed')) do
                if v ~= ped and #(GetEntityCoords(ped) - GetEntityCoords(v)) > 100 then
                    if not IsEntityAMissionEntity(v) then
                        SetEntityAsNoLongerNeeded(v)
                    end
                elseif v ~= ped then
                    StopPedSpeaking(v, true)
                    SetPedAoBlobRendering(v,false)
                end
            end

            for k,v in pairs(GetGamePool('CObject')) do
                if #(GetEntityCoords(ped) - GetEntityCoords(v)) > 100 then
                    if not IsEntityAMissionEntity(v) then
                        SetObjectAsNoLongerNeeded(v)
                    end
                    SetEntityAlpha(v,0,false)
                    SetEntityLodDist(v,10)
                else
                    ResetEntityAlpha(v)
                    SetEntityVisible(v, true)
                    SetEntityLodDist(v,100)
                end
            end

            for k,v in pairs(GetGamePool('CVehicle')) do
                Wait(11)
                if #(GetEntityCoords(ped) - GetEntityCoords(v)) > 150 then
                    SetEntityAlpha(v,0,false)
                    SetEntityVisible(v, false)
                    SetEntityLodDist(v,10)
                else
                    ResetEntityAlpha(v)
                    SetEntityVisible(v, true)
                    SetEntityLodDist(v,150)
                end
            end

            SetBackfaceculling(true)
            DisableVehicleDistantlights(true)
            SetDistantCarsEnabled(false)
            SetSnowLevel(1.0)
            SetTimeScale(1.0)
            ShouldUseMetricMeasurements()
            DisableHeadBlendPaletteColor(ped)
            SetRainLevel(0.0)
            SetWindSpeed(0.0)
            for k,v in pairs(GetGamePool('CPed')) do
                SetPedLodMultiplier(v,0.0)
                SetEntityAlpha(v,255,false)
                if not IsPedAPlayer(v) and IsPedInAnyVehicle(v) then
                elseif GetVehiclePedIsIn(v) == 0 then
                    SetBlockingOfNonTemporaryEvents(v, true)
                end
                SetPedAoBlobRendering(v,false)
            end

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
            ClearPedBloodDamage(PlayerPedId())
            ClearPedWetness(PlayerPedId())
            ClearPedEnvDirt(PlayerPedId())
            ResetPedVisibleDamage(PlayerPedId())
            ClearExtraTimecycleModifier()
            ClearTimecycleModifier()
            ClearOverrideWeather()
            ClearHdArea()
            DisableVehicleDistantlights(false)
            DisableScreenblurFade()
            SetRainLevel(0.0)
            SetWindSpeed(0.0)
            Wait(1000)
        end
    end))
end
