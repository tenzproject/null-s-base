local maintainedPeds = {}

Citizen.CreateThread(function()
    while true do
        if PlayerState.Illegals.laboratories.inLabo then
            for pedNetId, _ in pairs(maintainedPeds) do
                local ped = NetworkGetEntityFromNetworkId(pedNetId)
                
                if DoesEntityExist(ped) then
                    SetPedCombatAttributes(ped, 17, true) -- BF_CanFightArmedPedsWhenNotArmed
                    SetPedCombatAttributes(ped, 46, true) -- BF_AlwaysFight
                    SetPedFleeAttributes(ped, 0, false) -- Ne pas fuir
                    
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    
                    SetPedCanRagdoll(ped, false)
                    SetEntityInvincible(ped, true)
                    
                    SetPedConfigFlag(ped, 17, true) -- CPED_CONFIG_FLAG_BlockNonTemporaryEvents
                    SetPedConfigFlag(ped, 281, true) -- CPED_CONFIG_FLAG_DisableMelee
                    
                    SetPedRelationshipGroupHash(ped, GetHashKey("PLAYER"))
                else
                    maintainedPeds[pedNetId] = nil
                end
            end
            Wait(1000)
        else
            Wait(5000)
        end
    end
end)

RegisterNetEvent("null:labo:playEmployeeIdleAnim", function(pedNetId, dict, anim, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end

    if not DoesEntityExist(ped) then
        null.DebugPrint("[IDLE ANIM CLIENT] Ped not found")
        return
    end
    
    maintainedPeds[pedNetId] = true
    
    -- Freeze et désactiver les collisions pour le repos
    FreezeEntityPosition(ped, true)
    
    if dict == "scenario" then
        -- Scenario type (ex: WORLD_HUMAN_LEANING)
        FreezeEntityPosition(ped, false)
        TaskStartScenarioInPlace(ped, anim, 0, true)
    else
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasAnimDictLoaded(dict) then
            null.DebugPrint("[IDLE ANIM CLIENT] Failed to load anim dict:", dict)
            return
        end
        
        TaskPlayAnim(ped, dict, anim, 8.0, 8.0, duration, 1, 0, false, false, false)
    end
end)

RegisterNetEvent("null:labo:playEmployeeWaterAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[WATER ANIM CLIENT] Ped not found")
        return
    end
    
    Citizen.CreateThread(function()
        local coords = GetEntityCoords(ped)
        local model = `prop_wateringcan`
        
        RequestModel(model)
        RequestNamedPtfxAsset('core')
        RequestAnimDict('weapon@w_sp_jerrycan')
        
        local timeout = 0
        while (not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') or not HasAnimDictLoaded('weapon@w_sp_jerrycan')) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') or not HasAnimDictLoaded('weapon@w_sp_jerrycan') then
            null.DebugPrint("[WATER ANIM CLIENT] Failed to load resources")
            return
        end
        
        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
        
        SetPtfxAssetNextCall('core')
        local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
        
        
        FreezeEntityPosition(ped, true)
        --SetEntityCollision(ped, false, false)
        
        TaskPlayAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, duration, 1, 0, false, false, false)
        
        Wait(duration)
        
        StopParticleFxLooped(effect, 0)
        DeleteEntity(created_object)
        ClearPedTasks(ped)
        
        
        FreezeEntityPosition(ped, false)
        --SetEntityCollision(ped, true, true)
    end)
end)

RegisterNetEvent("null:labo:playEmployeeFertilizerAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[FERTILIZER ANIM CLIENT] Ped not found")
        return
    end
    
    Citizen.CreateThread(function()
        local coords = GetEntityCoords(ped)
        local model = `w_am_jerrycan_sf`
        
        RequestModel(model)
        RequestNamedPtfxAsset('core')
        RequestAnimDict('weapon@w_sp_jerrycan')
        
        local timeout = 0
        while (not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') or not HasAnimDictLoaded('weapon@w_sp_jerrycan')) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') or not HasAnimDictLoaded('weapon@w_sp_jerrycan') then
            null.DebugPrint("[FERTILIZER ANIM CLIENT] Failed to load resources")
            return
        end
        
        local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
        
        SetPtfxAssetNextCall('core')
        local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
        
        FreezeEntityPosition(ped, true)
        --SetEntityCollision(ped, false, false)

        TaskPlayAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, duration, 1, 0, false, false, false)
        
        Wait(duration)
        
        StopParticleFxLooped(effect, 0)
        DeleteEntity(created_object)
        ClearPedTasks(ped)
        
        FreezeEntityPosition(ped, false)
        --SetEntityCollision(ped, true, true)
    end)
end)

RegisterNetEvent("null:labo:playEmployeeSeedAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[SEED ANIM CLIENT] Ped not found")
        return
    end
    
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    
    local timeout = 0
    while (not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded('amb@medic@standing@kneel@base') then
        null.DebugPrint("[SEED ANIM CLIENT] Failed to load anim dict")
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeHarvestAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[HARVEST ANIM CLIENT] Ped not found")
        return
    end
    
    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    
    local timeout = 0
    while (not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded('amb@medic@standing@kneel@base') then
        null.DebugPrint("[HARVEST ANIM CLIENT] Failed to load anim dict")
        return
    end
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeDryAreaAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[DRY AREA ANIM CLIENT] Ped not found")
        return
    end
    
    RequestAnimDict('amb@medic@standing@kneel@base')
    
    local timeout = 0
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded('amb@medic@standing@kneel@base') then
        null.DebugPrint("[DRY AREA ANIM CLIENT] Failed to load anim dict")
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeTreatAnim", function(pedNetId, iterations)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[TREAT ANIM CLIENT] Ped not found")
        return
    end
    
    Citizen.CreateThread(function()
        RequestAnimDict('anim@amb@business@weed@weed_sorting_seated@')
        
        local timeout = 0
        while not HasAnimDictLoaded('anim@amb@business@weed@weed_sorting_seated@') and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not HasAnimDictLoaded('anim@amb@business@weed@weed_sorting_seated@') then
            null.DebugPrint("[TREAT ANIM CLIENT] Failed to load anim dict")
            return
        end
        
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        
        FreezeEntityPosition(ped, true)
        --SetEntityCollision(ped, false, false)
        
        for i = 1, iterations do
            if not DoesEntityExist(ped) then break end
            TaskPlayAnimAdvanced(ped, 'anim@amb@business@weed@weed_sorting_seated@', 'sorter_right_sort_v3_sorter02', coords.x, coords.y, coords.z, 0.0, 0.0, heading, 1.0, 1.0, 4750, 1, 0, false, false)
            Wait(4750)
        end
    end)
end)

RegisterNetEvent("null:labo:playEmployeeStorageAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[STORAGE ANIM CLIENT] Ped not found")
        return
    end
    
    RequestAnimDict('amb@medic@standing@kneel@base')
    
    local timeout = 0
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded('amb@medic@standing@kneel@base') then
        null.DebugPrint("[STORAGE ANIM CLIENT] Failed to load anim dict")
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 5.0, 5.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeMethCuveAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        return
    end
    
    local dict = 'amb@prop_human_bbq@male@idle_a'
    local anim = 'idle_a'
    
    RequestAnimDict(dict)
    
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded(dict) then
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeMethFourAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        return
    end
    
    local dict = 'amb@prop_human_bbq@male@idle_a'
    local anim = 'idle_a'
    
    RequestAnimDict(dict)
    
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded(dict) then
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, duration, 1, 0, false, false, false)
end)

RegisterNetEvent("null:labo:playEmployeeMethBreakAnim", function(pedNetId, duration)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not PlayerState.Illegals.laboratories.inLabo then
        return
    end
    
    if not DoesEntityExist(ped) then
        return
    end
    
    -- Use hammer/tool animation for breaking meth
    local dict = 'amb@prop_human_bum_bin@idle_a'
    local anim = 'idle_a'
    
    RequestAnimDict(dict)
    
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasAnimDictLoaded(dict) then
        return
    end
    
    
    FreezeEntityPosition(ped, true)
    --SetEntityCollision(ped, false, false)
    
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, duration, 1, 0, false, false, false)
end)

-- Unfreeze employee ped (called from server when animation ends)
RegisterNetEvent("null:labo:client:unfreezeEmployee", function(pedNetId)
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    
    if not DoesEntityExist(ped) then
        return
    end
    
    FreezeEntityPosition(ped, false)
    --SetEntityCollision(ped, true, true)
    ClearPedTasks(ped)
end)

--[[
local EmployeeAnimThreads = {}

RegisterNetEvent("null:labo:employeeAnim", function(labId, employeeId, animType, plantId)
    null.DebugPrint("[EMPLOYEE ANIM CLIENT] Animation request received - Lab: "..labId..", Employee: "..employeeId..", Type: "..animType)
    
    Citizen.CreateThread(function()
        local employeePed = nil
        local attempts = 0
        local maxAttempts = 50
        
        while attempts < maxAttempts do
            employeePed = exports["null-core"]:GetEmployeePed(labId, employeeId)
            if employeePed and DoesEntityExist(employeePed) then
                null.DebugPrint("[EMPLOYEE ANIM CLIENT] Found employee ped after "..attempts.." attempts")
                break
            end
            attempts = attempts + 1
            Wait(100)
        end
        
        if not employeePed or not DoesEntityExist(employeePed) then
            null.DebugPrint("[EMPLOYEE ANIM CLIENT] ERROR: Employee ped not found or doesn't exist (timeout 5000ms)")
            return
        end
        
        if EmployeeAnimThreads[labId] == nil then
            EmployeeAnimThreads[labId] = {}
        end
        
        if EmployeeAnimThreads[labId][employeeId] then
            null.DebugPrint("[EMPLOYEE ANIM CLIENT] Employee already animating, skipping")
            return
        end
        
        EmployeeAnimThreads[labId][employeeId] = true
        
        local pedCoords = GetEntityCoords(employeePed)
        local pedHeading = GetEntityHeading(employeePed)
        
        if animType == "water" or animType == "fertilize" then
            -- null.DebugPrint("[EMPLOYEE ANIM] Starting "..animType.." animation")
            local plantData = exports["null-core"]:GetPlantStats(plantId)
            if plantId and plantData then
                local plantCoords = plantData.coords
                -- null.DebugPrint("[EMPLOYEE ANIM] Plant coords: "..tostring(plantCoords))
                
                TaskGoToCoordAnyMeans(employeePed, plantCoords.x, plantCoords.y, plantCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                -- null.DebugPrint("[EMPLOYEE ANIM] Employee walking to plant")
                
                local timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - vector3(plantCoords.x, plantCoords.y, plantCoords.z))
                    if dist < 1.5 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                Wait(500)
                -- null.DebugPrint("[EMPLOYEE ANIM] Employee arrived at plant, playing animation")
                
                RequestAnimDict('amb@medic@standing@kneel@base')
                RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                
                TaskPlayAnim(employeePed, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                -- null.DebugPrint("[EMPLOYEE ANIM] Playing kneel animation for "..animType)
                Wait(3000)
                -- null.DebugPrint("[EMPLOYEE ANIM] Animation complete, returning to position")
                
                ClearPedTasks(employeePed)
                TaskGoToCoordAnyMeans(employeePed, pedCoords.x, pedCoords.y, pedCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                
                timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - pedCoords)
                    if dist < 1.5 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                SetEntityCoords(employeePed, pedCoords.x, pedCoords.y, pedCoords.z)
                SetEntityHeading(employeePed, pedHeading)
            end
            
        elseif animType == "harvest" then
            -- null.DebugPrint("[EMPLOYEE ANIM] Starting harvest animation")
            local plantData = exports["null-core"]:GetPlantStats(plantId)
            if plantId and plantData then
                local plantCoords = plantData.coords
                null.DebugPrint("[EMPLOYEE ANIM] Plant coords: "..tostring(plantCoords))
                
                TaskGoToCoordAnyMeans(employeePed, plantCoords.x, plantCoords.y, plantCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                -- null.DebugPrint("[EMPLOYEE ANIM] Employee walking to harvest plant")
                
                local timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - vector3(plantCoords.x, plantCoords.y, plantCoords.z))
                    if dist < 1.5 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                Wait(500)
                
                RequestAnimDict('amb@medic@standing@kneel@base')
                RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                
                TaskPlayAnim(employeePed, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                -- null.DebugPrint("[EMPLOYEE ANIM] Playing harvest animation (12.5s)")
                Wait(12500)
                -- null.DebugPrint("[EMPLOYEE ANIM] Harvest animation complete")
                
                ClearPedTasks(employeePed)
                TaskGoToCoordAnyMeans(employeePed, pedCoords.x, pedCoords.y, pedCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                
                timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - pedCoords)
                    if dist < 1.5 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                SetEntityCoords(employeePed, pedCoords.x, pedCoords.y, pedCoords.z)
                SetEntityHeading(employeePed, pedHeading)
            end
            
        elseif animType == "dry_weed" or animType == "collect_dry" or animType == "deposit_dry" then
            -- null.DebugPrint("[EMPLOYEE ANIM] Starting "..animType.." animation")
            local dryCoords = Config.laboratoire.type["weed"].treatmentequipment.dry
            -- null.DebugPrint("[EMPLOYEE ANIM] Dry area coords: "..tostring(dryCoords))
            
            TaskGoToCoordAnyMeans(employeePed, dryCoords.x, dryCoords.y, dryCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
            -- null.DebugPrint("[EMPLOYEE ANIM] Employee walking to dry area")
            
            local timeout = 0
            while timeout < 100 do
                local dist = #(GetEntityCoords(employeePed) - vector3(dryCoords.x, dryCoords.y, dryCoords.z))
                if dist < 2.0 then
                    break
                end
                Wait(100)
                timeout = timeout + 1
            end
            
            ClearPedTasks(employeePed)
            
            RequestAnimDict('amb@medic@standing@kneel@base')
            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do Wait(0) end
            
            TaskPlayAnim(employeePed, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
            -- null.DebugPrint("[EMPLOYEE ANIM] Playing "..animType.." animation")
            
            if animType == "dry_weed" then
                Wait(4000)
            else
                Wait(3000)
            end
            -- null.DebugPrint("[EMPLOYEE ANIM] "..animType.." animation complete")
            
            ClearPedTasks(employeePed)
            TaskGoToCoordAnyMeans(employeePed, pedCoords.x, pedCoords.y, pedCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
            
            timeout = 0
            while timeout < 100 do
                local dist = #(GetEntityCoords(employeePed) - pedCoords)
                if dist < 1.5 then
                    break
                end
                Wait(100)
                timeout = timeout + 1
            end
            
            ClearPedTasks(employeePed)
            SetEntityCoords(employeePed, pedCoords.x, pedCoords.y, pedCoords.z)
            SetEntityHeading(employeePed, pedHeading)
            
        elseif animType == "treat_weed" then
            -- null.DebugPrint("[EMPLOYEE ANIM] Starting treat_weed animation")
            local treatCoords = nil
            local treatConfig = nil
            
            for k, v in pairs(Config.laboratoire.type["weed"].treatmentequipment.cuts) do
                treatCoords = v.coords
                treatConfig = v
                break
            end
            
            if treatCoords then
                -- null.DebugPrint("[EMPLOYEE ANIM] Treatment coords: "..tostring(treatCoords))
                TaskGoToCoordAnyMeans(employeePed, treatCoords.x, treatCoords.y, treatCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                -- null.DebugPrint("[EMPLOYEE ANIM] Employee walking to treatment table")
                
                local timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - vector3(treatCoords.x, treatCoords.y, treatCoords.z))
                    if dist < 2.0 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                SetEntityCoords(employeePed, treatCoords.x, treatCoords.y, treatCoords.z)
                SetEntityHeading(employeePed, treatConfig.heading)
                
                RequestAnimDict("anim@amb@business@weed@weed_sorting_seated@")
                while not HasAnimDictLoaded('anim@amb@business@weed@weed_sorting_seated@') do 
                    Wait(100) 
                end
                
                local PropsTable1 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), treatConfig.props[1].coords.x, treatConfig.props[1].coords.y, treatConfig.props[1].coords.z, true)
                SetEntityRotation(PropsTable1, treatConfig.props[1].rotation.x, treatConfig.props[1].rotation.y, treatConfig.props[1].rotation.z)
                local PropsTable2 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), treatConfig.props[2].coords.x, treatConfig.props[2].coords.y, treatConfig.props[2].coords.z, true)
                SetEntityRotation(PropsTable2, treatConfig.props[2].rotation.x, treatConfig.props[2].rotation.y, treatConfig.props[2].rotation.z)
                local PropsTable3 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), treatConfig.props[3].coords.x, treatConfig.props[3].coords.y, treatConfig.props[3].coords.z, true)
                SetEntityRotation(PropsTable3, treatConfig.props[3].rotation.x, treatConfig.props[3].rotation.y, treatConfig.props[3].rotation.z)
                local PropsTable4 = CreateObject(GetHashKey('bkr_prop_weed_dry_01a'), treatConfig.props[4].coords.x, treatConfig.props[4].coords.y, treatConfig.props[4].coords.z, true)
                if treatConfig.props[4].rotation then
                    SetEntityRotation(PropsTable4, treatConfig.props[4].rotation.x, treatConfig.props[4].rotation.y, treatConfig.props[4].rotation.z)
                end
                
                -- null.DebugPrint("[EMPLOYEE ANIM] Employee seated at treatment table, creating props")
                
                local function TreatOneWeed()
                    TaskPlayAnimAdvanced(employeePed, 'anim@amb@business@weed@weed_sorting_seated@', 'sorter_right_sort_v3_sorter02', treatCoords.x, treatCoords.y, treatCoords.z, 0.0, 0.0, treatConfig.heading, 1.0, 1.0, -1)
                    Wait(3750)
                    local tempPropsWeedBud = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), 0.0, 0.0, 0.0, true)
                    AttachEntityToEntity(tempPropsWeedBud, employeePed, GetPedBoneIndex(employeePed, 18905), 0.12, -0.025, 0.045, 260.0, 0.0, 0.0, true, true, false, true, 1, true)
                    Wait(1000)
                    DeleteEntity(tempPropsWeedBud)
                end
                
                -- null.DebugPrint("[EMPLOYEE ANIM] Starting treatment sequence (5 iterations)")
                TreatOneWeed()
                TreatOneWeed()
                TreatOneWeed()
                TreatOneWeed()
                TreatOneWeed()
                -- null.DebugPrint("[EMPLOYEE ANIM] Treatment sequence complete")
                
                DeleteEntity(PropsTable1)
                DeleteEntity(PropsTable2)
                DeleteEntity(PropsTable3)
                DeleteEntity(PropsTable4)
                
                ClearPedTasks(employeePed)
                TaskGoToCoordAnyMeans(employeePed, pedCoords.x, pedCoords.y, pedCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                
                local timeout = 0
                while timeout < 100 do
                    local dist = #(GetEntityCoords(employeePed) - pedCoords)
                    if dist < 1.5 then
                        break
                    end
                    Wait(100)
                    timeout = timeout + 1
                end
                
                ClearPedTasks(employeePed)
                SetEntityCoords(employeePed, pedCoords.x, pedCoords.y, pedCoords.z)
                SetEntityHeading(employeePed, pedHeading)
            end
        end
        
        -- null.DebugPrint("[EMPLOYEE ANIM] Animation thread complete for "..animType)
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
end)
--]]
