-- ================================================================
-- Null REALTORS — Burglary (client)
-- ================================================================

local CFG = Config and Config.Realtors
if not CFG or not CFG.Burglary or not CFG.Burglary.Enabled then return end
local BCFG = CFG.Burglary

local burglaryActive  = false
local activeSession   = nil    -- { sessionId, propKey, interior, propData }
local burgInsideProperty = false  -- true une fois téléporté dans la propriété

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------
local function sendNui(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function findNearbyDoor()
    local pcoords = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, sp in ipairs(CFG.SpawnPool or {}) do
        local d = #(vector3(sp.door.x, sp.door.y, sp.door.z) - pcoords)
        if d <= (BCFG.DoorRange or 2.5) then
            if not bestDist or d < bestDist then
                best, bestDist = sp, d
            end
        end
    end
    return best
end

local function setNuiFocusBurglary(focus)
    SetNuiFocus(focus, focus)
end

-- ----------------------------------------------------------------
-- Anim helpers
-- ----------------------------------------------------------------
local function startAnim()
    local a = BCFG.Anim
    if not a or not a.dict then return end
    RequestAnimDict(a.dict)
    local timeout = 0
    while not HasAnimDictLoaded(a.dict) and timeout < 50 do
        Wait(20); timeout = timeout + 1
    end
    if HasAnimDictLoaded(a.dict) then
        TaskPlayAnim(PlayerPedId(), a.dict, a.name, 8.0, 1.0, -1, a.flag or 49, 0, false, false, false)
    end
end
local function stopAnim() ClearPedTasks(PlayerPedId()) end

-- ----------------------------------------------------------------
-- Alarm sound (3D at door)
-- ----------------------------------------------------------------
local alarmSoundId
local function startAlarm(door)
    if alarmSoundId then return end
    alarmSoundId = GetSoundId()
    -- Generic FiveM alarm hash
    PlaySoundFromCoord(alarmSoundId, "Bunker_Alarm",
        door.x + 0.0, door.y + 0.0, (door.z or 0.0) + 0.0,
        "GTAO_FM_Events_Soundset", false, 30, false)
    -- Auto-stop after 25s
    SetTimeout(25000, function()
        if alarmSoundId then
            StopSound(alarmSoundId); ReleaseSoundId(alarmSoundId); alarmSoundId = nil
        end
    end)
end

-- ----------------------------------------------------------------
-- Server pushed: usable item used → look for nearby door
-- ----------------------------------------------------------------
RegisterNetEvent("realtor:burglary:tryUse")
AddEventHandler("realtor:burglary:tryUse", function(itemName)
    if burglaryActive then return end

    local sp = findNearbyDoor()
    if not sp then
        ESX.ShowNotification("~r~Aucune porte de propriété à proximité")
        return
    end

    -- Ask server to validate + start session
    ESX.TriggerServerCallback("realtor:burglary:start", function(res)
        if not res or not res.ok then
            local reasons = {
                no_player          = "Erreur joueur",
                global_cd          = "Vous avez tenté un cambriolage récemment",
                unknown_prop       = "Propriété introuvable",
                prop_cd            = "Cette propriété a déjà été cambriolée récemment",
                not_breakable      = "Cette porte n'est pas crochetable",
                missing_tool       = ("Il vous faut un %s"):format(res and res.required or "lockpick"),
                wrong_tool         = ("Cette porte nécessite un %s"):format(res and res.required or "outil"),
                no_difficulty      = "Configuration manquante",
                time_window        = "Les cambriolages ne sont pas autorisés à cette heure",
                not_enough_police  = ("Il faut au moins %d policier(s) en service"):format(res and res.required or 2),
            }
            ESX.ShowNotification("~r~" .. (reasons[res and res.reason] or "Échec"))
            return
        end

        burglaryActive = true
        activeSession  = { propKey = res.propKey, interior = res.interior, toolUsed = res.toolUsed }

        -- Close inventory UI properly before starting minigame
        -- This also handles the ped animation cleanup
        local pcallOk, pcallErr = pcall(function()
            exports["null-core"]:closeInventory()
        end)
        if not pcallOk then
            -- Fallback: try to close via NUI message if export fails
            sendNui("newInventory:close", {})
        end

        -- Small delay to ensure inventory ped is fully cleaned up
        Wait(150)

        startAnim()
        setNuiFocusBurglary(true)
        sendNui("burglary:openMinigame", {
            interior   = res.interior,
            difficulty = res.difficulty,
            propKey    = res.propKey,
        })
    end, sp.key, itemName)
end)

-- ----------------------------------------------------------------
-- Teleport helpers (réutilise le pipeline properties existant)
-- ----------------------------------------------------------------
local function burgEnterProperty(propData)
    burgInsideProperty = true
    local pPed = PlayerPedId()
    Citizen.CreateThread(function()
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do Wait(0) end

        TriggerServerEvent("null:properties:SetBucket", "solo", propData.bucketID)
        SetEntityCoords(pPed, vector3(
            propData.positions.ENTER.x,
            propData.positions.ENTER.y,
            propData.positions.ENTER.z
        ))
        DoScreenFadeIn(800)
        Wait(600)
        ESX.ShowNotification("~y~Cambriolage~s~\nMarchez jusqu'au coffre pour voler.")
    end)
end

local function burgExitProperty()
    if not burgInsideProperty then return end
    burgInsideProperty = false
    local propData = activeSession and activeSession.propData
    if not propData then return end

    -- Unregister burglary markers
    if null and null.data and null.data.markers then
        null.data.markers.unregister("burglaryCoffre")
        null.data.markers.unregister("burglaryExit")
    end

    local pPed = PlayerPedId()
    Citizen.CreateThread(function()
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do Wait(0) end

        TriggerServerEvent("null:properties:SetBucket", "remettre")
        SetEntityCoords(pPed, vector3(
            propData.positions.EXIT.x,
            propData.positions.EXIT.y,
            propData.positions.EXIT.z
        ))
        DoScreenFadeIn(800)
        Wait(600)
    end)
end

-- ----------------------------------------------------------------
-- NUI callbacks (UI React → client → server)
-- ----------------------------------------------------------------
RegisterNUICallback("burglary:result", function(data, cb)
    cb("ok")
    if not activeSession then return end

    local payload = {
        propKey  = activeSession.propKey,
        success  = data and data.success or false,
        toolUsed = activeSession.toolUsed,
    }

    ESX.TriggerServerCallback("realtor:burglary:finish", function(res)
        stopAnim()

        if not res or not res.ok then
            sendNui("burglary:close", {})
            setNuiFocusBurglary(false)
            burglaryActive = false; activeSession = nil
            return
        end

        if payload.success and res.sessionId then
            -- Store session data
            activeSession.sessionId = res.sessionId
            activeSession.propData  = res.propData

            -- Close lockpick UI first
            sendNui("burglary:close", {})
            setNuiFocusBurglary(false)

            -- Teleport into the property physically
            burgEnterProperty(res.propData)

            -- Register markers after teleport (wait for fade-in to complete)
            local capturedRes = res
            Citizen.CreateThread(function()
                Wait(1800)
                if not burgInsideProperty or not activeSession then return end
                if not (null and null.data and null.data.markers) then return end
                if not capturedRes.propData or not capturedRes.propData.positions then return end

                local coffrePos = capturedRes.propData.positions.COFFRE
                local lootOpened = false

                null.data.markers.register("burglaryCoffre", {
                    Position = vector3(coffrePos.x, coffrePos.y, coffrePos.z + 1),
                    Public   = true,
                    Job      = nil,
                    Blip     = false,
                    Action   = function()
                        if lootOpened then return end
                        lootOpened = true
                        -- Unregister coffre marker once activated
                        null.data.markers.unregister("burglaryCoffre")
                        -- Open the loot panel when player is at the chest
                        setNuiFocusBurglary(true)
                        sendNui("burglary:openLoot", {
                            items             = capturedRes.items,
                            timeLeft          = capturedRes.timeLeft,
                            maxItems          = capturedRes.maxItems,
                            maxQtyPerItem     = capturedRes.maxQtyPerItem,
                            interior          = activeSession and activeSession.interior,
                            isRealChest       = capturedRes.isRealChest,
                            minigameConfig    = capturedRes.minigameConfig,
                            attemptsPerItem   = capturedRes.attemptsPerItem,
                            itemStealCooldown = capturedRes.itemStealCooldown,
                        })
                    end,
                })
                -- Exit marker at entry point (fuite) — always works, even after UI closed
                local capturedPropData = capturedRes.propData
                null.data.markers.register("burglaryExit", {
                    Position = vector3(
                        capturedRes.propData.positions.ENTER.x,
                        capturedRes.propData.positions.ENTER.y,
                        capturedRes.propData.positions.ENTER.z
                    ),
                    Public   = true,
                    Job      = nil,
                    Blip     = false,
                    Action   = function()
                        null.data.markers.unregister("burglaryCoffre")
                        null.data.markers.unregister("burglaryExit")
                        -- Téléporter le joueur dehors
                        local pPed = PlayerPedId()
                        Citizen.CreateThread(function()
                            DoScreenFadeOut(800)
                            while not IsScreenFadedOut() do Wait(0) end
                            TriggerServerEvent("null:properties:SetBucket", "remettre")
                            SetEntityCoords(pPed, vector3(
                                capturedPropData.positions.EXIT.x,
                                capturedPropData.positions.EXIT.y,
                                capturedPropData.positions.EXIT.z
                            ))
                            DoScreenFadeIn(800)
                        end)
                        burgInsideProperty = false
                        burglaryActive = false; activeSession = nil
                        ESX.ShowNotification("~y~Vous avez fui la propriété.")
                    end,
                })
            end)
        else
            -- Failure path: close UI, alarm has already been triggered server-side
            sendNui("burglary:close", {})
            setNuiFocusBurglary(false)
            ESX.ShowNotification("~r~Vous avez raté votre coup. L'alarme s'est déclenchée !")
            burglaryActive = false; activeSession = nil
        end
    end, payload)
end)

-- Loot pickup
RegisterNUICallback("burglary:loot", function(data, cb)
    if not activeSession or not activeSession.sessionId then
        cb({ ok = false }); return
    end
    ESX.TriggerServerCallback("realtor:burglary:loot", function(res)
        cb(res or { ok = false })
        if res and res.ok then
            sendNui("burglary:lootUpdate", {
                items  = res.items,
                taken  = res.taken,
                max    = res.max,
                picked = res.picked,
            })
        end
    end, {
        sessionId       = activeSession.sessionId,
        lootKey         = data and data.lootKey,
        quantity        = data and data.quantity or 1,
        minigameSuccess = data and data.minigameSuccess,
    })
end)

-- Player closes the loot panel (via ESC / bouton)
RegisterNUICallback("burglary:close", function(_, cb)
    if activeSession and activeSession.sessionId then
        TriggerServerEvent("realtor:burglary:abort", activeSession.sessionId)
    end
    setNuiFocusBurglary(false)
    sendNui("burglary:close", {})
    -- Ferme simplement l'UI — le joueur doit sortir par lui-même via le marker EXIT
    -- (pas de téléportation forcée)
    burglaryActive = false; activeSession = nil
    cb("ok")
end)

-- Server forces loot end (timeout / max reached)
RegisterNetEvent("realtor:burglary:lootEnd")
AddEventHandler("realtor:burglary:lootEnd", function(payload)
    sendNui("burglary:lootEnd", payload or {})
    setNuiFocusBurglary(false)
    -- Pas de téléportation forcée — le joueur doit fuir par lui-même via le marker EXIT
    burglaryActive = false; activeSession = nil

    if payload and payload.reason == "timeout" then
        ESX.ShowNotification("~r~Temps écoulé — fuyez par la sortie !")
    elseif payload and payload.reason == "max" then
        ESX.ShowNotification("~y~Limite atteinte — fuyez par la sortie !")
    end
end)

-- Server tells client the alarm should start (after a failed minigame)
RegisterNetEvent("realtor:burglary:alarm")
AddEventHandler("realtor:burglary:alarm", function(data)
    if data and data.door then startAlarm(data.door) end
end)

-- Cancel on key during minigame (ESC)
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if burglaryActive then
            DisableControlAction(0, 199, true)   -- pause
            DisableControlAction(0, 200, true)
        else
            Wait(500)
        end
    end
end)