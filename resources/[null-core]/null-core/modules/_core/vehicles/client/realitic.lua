local isDynamicFovActive = false
local dynamicCam = nil
local baseFov = GetGameplayCamFov()
local isShaking = false

local fovMultiplier = 0.10
local maxFov = 110.0

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        if PlayerState.realisticDrive then
            if PlayerState.isInVehicle and PlayerState.vehicle ~= 0 then
                wait = 0
                if GetFollowVehicleCamViewMode() ~= 4 then
                    local speed = GetEntitySpeed(PlayerState.vehicle) * 3.6 

                    if not isDynamicFovActive then
                        EnableDynamicCam()
                    end

                    local targetFov = baseFov + (speed * fovMultiplier)
                    if targetFov > maxFov then targetFov = maxFov end
                    
                    UpdateCamera(targetFov, speed)
                else
                    if isDynamicFovActive then DisableDynamicCam() end
                end
            else
                if isDynamicFovActive then DisableDynamicCam() end
            end
        end
        Citizen.Wait(wait)
    end
end)

function EnableDynamicCam()
    if not DoesCamExist(dynamicCam) then
        dynamicCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end
    
    -- On snap la position au démarrage pour éviter un saut visuel
    local startPos = GetGameplayCamCoord()
    local startRot = GetGameplayCamRot(2)
    SetCamCoord(dynamicCam, startPos)
    SetCamRot(dynamicCam, startRot, 2)

    SetCamActive(dynamicCam, true)
    RenderScriptCams(true, false, 0, true, true)
    isDynamicFovActive = true
    baseFov = GetGameplayCamFov()
    isShaking = false
end

function DisableDynamicCam()
    if DoesCamExist(dynamicCam) then
        StopCamShaking(dynamicCam, true)
        SetCamActive(dynamicCam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(dynamicCam, false)
    end
    dynamicCam = nil
    isDynamicFovActive = false
    isShaking = false
end

function UpdateCamera(targetFov, speed)
    if DoesCamExist(dynamicCam) then
        local targetPos = GetGameplayCamCoord()
        local targetRot = GetGameplayCamRot(2)
        
        local currentPos = GetCamCoord(dynamicCam)
        local currentRot = GetCamRot(dynamicCam, 2)

        ----------------------------------------------------------
        -- 1. CALCUL DU FACTEUR DE LISSAGE (Le cœur du système)
        ----------------------------------------------------------
        
        -- positionLerp : Plus c'est proche de 1.0, plus c'est instantané (pas de lag).
        -- Plus c'est bas (0.1), plus c'est fluide mais "en retard".
        
        local posLerp = 1.0 -- Par défaut : Instantané (pour l'arrêt)
        local rotLerp = 1.0 -- Par défaut : Instantané (pour l'arrêt)

        if speed > 85.0 then
            -- Dès qu'on roule, on active le lissage de position pour éviter les micro-tp
            posLerp = 0.2 
            
            -- Effet de "Résistance/Stiffness" sur la rotation
            -- Plus on va vite, plus rotLerp diminue, rendant la caméra "lourde"
            -- À 200km/h, la caméra sera plus dure à tourner qu'à 50km/h
            rotLerp = 1.0 - ( (speed - 10.0) / 400.0 )
            if rotLerp < 0.1 then rotLerp = 0.1 end -- Sécurité min
        end

        ----------------------------------------------------------
        -- 2. APPLICATION POSITION & ROTATION
        ----------------------------------------------------------

        -- Interpolation de la Position (Règle les micro-tp)
        local newPos = currentPos + (targetPos - currentPos) * posLerp
        SetCamCoord(dynamicCam, newPos)

        -- Interpolation de la Rotation (Crée l'effet de rigidité/retour au centre)
        -- C'est ici que la magie opère pour ton effet "dur à déplacer"
        local newRotX = currentRot.x + (targetRot.x - currentRot.x) * rotLerp
        local newRotY = currentRot.y + (targetRot.y - currentRot.y) * rotLerp
        local newRotZ = currentRot.z + (targetRot.z - currentRot.z) * rotLerp
        -- Note: Pour la rotation Z (Heading), il faut gérer le passage 360->0 degrés, 
        -- mais GetGameplayCamRot gère généralement ça bien en relatif.
        
        SetCamRot(dynamicCam, newRotX, newRotY, newRotZ, 2)

        ----------------------------------------------------------
        -- 3. FOV & SHAKE
        ----------------------------------------------------------
        
        local currentFov = GetCamFov(dynamicCam)
        local newFov = currentFov + (targetFov - currentFov) * 0.05
        SetCamFov(dynamicCam, newFov)

        if speed > 150.0 then
            if not isShaking then
                ShakeCam(dynamicCam, "ROAD_VIBRATION_SHAKE", 0.5)
                isShaking = true
            end
            SetCamShakeAmplitude(dynamicCam, (speed - 150.0) / 300.0)
        else
            if isShaking then
                StopCamShaking(dynamicCam, true)
                isShaking = false
            end
        end
    end
end