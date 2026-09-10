-- local PauseMenu = {}
-- PauseMenu.isOpen = false

-- local pedSceneHandle = nil
-- local pauseBlur = false

-- -- ─────────────────────────────────────────────────────────
-- -- Ped Clone System (via PedScene shared module)
-- -- ─────────────────────────────────────────────────────────

-- local PauseMenuPedConfig = {
--     screenX = 0.24,
--     screenY = 0.80,
--     depth = 3.0,
--     bgWidth = 3.0,
--     bgHeight = 6.0,
--     zOffset = -0.3,
--     rotationOffset = 200.0,
--     polyOffsetY = -0.35,
--     lightRange = 5.0,
--     lightIntensity = 2.5,
--     lightOffset = vector3(0.0, 1.5, 1.2),
--     fadeDuration = 200.0,
--     bgColor = { r = 12, g = 12, b = 14 },
--     targetAlpha = 235,
--     lightColor = { r = 195, g = 255, b = 209 },
--     cameraTilt = false,
--     isOpenFn = function() return PauseMenu.isOpen end,
--     nuiAction = 'pauseMenu',
-- }

-- local function CreatePauseMenuPed()
--     -- Always clean up old handle to prevent stale state
--     if pedSceneHandle then
--         if not pedSceneHandle.destroyed then
--             PedScene.Destroy(pedSceneHandle)
--         end
--         pedSceneHandle = nil
--     end
--     pedSceneHandle = PedScene.Create(PauseMenuPedConfig)
-- end

-- local function DestroyPauseMenuPed()
--     if pedSceneHandle then
--         PedScene.Destroy(pedSceneHandle)
--         pedSceneHandle = nil
--     end
-- end

-- -- ─────────────────────────────────────────────────────────
-- -- Gather player data for NUI
-- -- ─────────────────────────────────────────────────────────

-- local function GetPauseMenuData()
--     local xPlayer = ESX.PlayerData
--     if not xPlayer then return {} end

--     local firstName = xPlayer.firstname or "Inconnu"
--     local lastName = xPlayer.lastname or "Inconnu"
--     local uniqueId = xPlayer.idunique or "?"
--     local serverId = tostring(GetPlayerServerId(PlayerId()))

--     -- Job
--     local jobLabel = "Citoyen"
--     local jobGrade = ""
--     if xPlayer.job and xPlayer.job.name and xPlayer.job.name ~= "unemployed" then
--         jobLabel = xPlayer.job.label or xPlayer.job.name
--         if xPlayer.job.grade_label and xPlayer.job.grade_label ~= "" then
--             jobGrade = xPlayer.job.grade_label
--         end
--     end

--     -- Illegal group
--     local illegalLabel = ""
--     local illegalGrade = ""
--     local hasIllegalGroup = false
--     if xPlayer.job2 and xPlayer.job2.name and xPlayer.job2.name ~= "unemployed" and xPlayer.job2.name ~= "unemployed2" then
--         illegalLabel = xPlayer.job2.label or xPlayer.job2.name
--         hasIllegalGroup = true
--         if xPlayer.job2.grade_label and xPlayer.job2.grade_label ~= "" then
--             illegalGrade = xPlayer.job2.grade_label
--         end
--     end

--     -- Accounts
--     local cash = 0
--     local bank = 0
--     local dirtyCash = 0
--     if xPlayer.accounts then
--         for _, account in ipairs(xPlayer.accounts) do
--             if account.name == "cash" then
--                 cash = account.money
--             elseif account.name == "bank" then
--                 bank = account.money
--             elseif account.name == "dirtycash" then
--                 dirtyCash = account.money
--             end
--         end
--     end

--     -- Player count
--     local playerCount = 0
--     for i = 0, 255 do
--         if NetworkIsPlayerActive(i) then
--             playerCount = playerCount + 1
--         end
--     end
--     local maxPlayers = GetConvarInt('sv_maxclients', 64)

--     return {
--         firstName = firstName,
--         lastName = lastName,
--         uniqueId = uniqueId,
--         serverId = serverId,
--         job = jobLabel,
--         jobGrade = jobGrade,
--         illegalGroup = illegalLabel,
--         illegalGrade = illegalGrade,
--         hasIllegalGroup = hasIllegalGroup,
--         cash = cash,
--         bank = bank,
--         dirtyCash = dirtyCash,
--         playerCount = playerCount,
--         maxPlayers = maxPlayers,
--         vip = PlayerState.vip or { isVip = false },
--     }
-- end

-- -- ─────────────────────────────────────────────────────────
-- -- Open / Close
-- -- ─────────────────────────────────────────────────────────

-- function OpenPauseMenu()
--     if PauseMenu.isOpen then return end
--     if PlayerState.isDead then return end
--     if NullInventory and NullInventory.isOpen then return end

--     PauseMenu.isOpen = true

--     -- Screen blur
--     --TriggerScreenblurFadeIn(300)
--     pauseBlur = true

--     DisplayRadar(false)
--     null.DisplayHud(false)

--     Citizen.CreateThread(function()
--         local targetPitch = 0.0
--         local currentPitch = GetGameplayCamRelativePitch() 
--         if math.abs(currentPitch) < 4.5 then return end
        
--         while math.abs(currentPitch - targetPitch) > 0.5 do
--             Citizen.Wait(0)
            
--             currentPitch = currentPitch + (targetPitch - currentPitch) * 0.1
            
--             SetGameplayCamRelativePitch(currentPitch, 1.0)
--         end
--     end)

--     -- Clone ped
--     CreatePauseMenuPed()

--     -- Send data to NUI
--     local data = GetPauseMenuData()
--     SendNUIMessage({
--         action = 'pauseMenu:open',
--         data = data
--     })
--     SetNuiFocus(true, true)
-- end

-- function ClosePauseMenu()
--     if not PauseMenu.isOpen then return end

--     PauseMenu.isOpen = false

--     -- Remove blur
--     if pauseBlur then
--         --TriggerScreenblurFadeOut(300)
--         pauseBlur = false
--     end

--     SendNUIMessage({
--         action = 'pauseMenu:close'
--     })
--     SetNuiFocus(false, false)
--     DisplayRadar(true)
--     null.DisplayHud(true)
-- end

-- -- ─────────────────────────────────────────────────────────
-- -- ESC Key Interception
-- -- ─────────────────────────────────────────────────────────

-- CreateThread(function()
--     while true do
--         if PauseMenu.isOpen then
--             -- Disable controls while menu is open
--             DisableControlAction(0, 1, true)   -- LookLeftRight
--             DisableControlAction(0, 2, true)   -- LookUpDown
--             DisableControlAction(0, 142, true) -- MeleeAttackAlternate
--             DisableControlAction(0, 18, true)  -- Enter
--             DisableControlAction(0, 322, true) -- ESC (INPUT_FRONTEND_CANCEL)
--             DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE
--             DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
--             DisableControlAction(0, 24, true)  -- Attack
--             DisableControlAction(0, 25, true)  -- Aim

--             Wait(0)
--         else
--             -- Intercept ESC/P to open our menu instead of GTA's
--             DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE

--             if IsDisabledControlJustPressed(0, 200) then
--                 if ESX.PlayerLoaded and not PlayerState.isDead and not PlayerState.isInAction and not PlayerState.inPauseMenu then
--                     OpenPauseMenu()
--                 end
--             end

--             Wait(0)
--         end
--     end
-- end)

-- -- ─────────────────────────────────────────────────────────
-- -- NUI Callbacks
-- -- ─────────────────────────────────────────────────────────

-- RegisterNUICallback('pauseMenu:close', function(data, cb)
--     ClosePauseMenu()
--     cb('ok')
-- end)

-- RegisterNUICallback('pauseMenu:openMinimap', function(data, cb)
--     ClosePauseMenu()
--     Wait(100)
--     ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_MP_PAUSE'), false, -1)
--     cb('ok')
-- end)

-- RegisterNUICallback('pauseMenu:openGTASettings', function(data, cb)
--     ClosePauseMenu()
--     Wait(100)
--     ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, 117)
--     cb('ok')
-- end) 

-- RegisterNUICallback('pauseMenu:quitServer', function(data, cb)
--     ClosePauseMenu()
--     Wait(200)
--     TriggerServerEvent('null:player:disconnect')
--     cb('ok')
-- end)

-- RegisterNUICallback('pauseMenu:openModule', function(data, cb)
--     local module = data.module
--     ClosePauseMenu()
--     Wait(200)

--     if module == "hudEditor" then
--         SendNUIMessage({ action = 'openHUDEditor' })
--         SetNuiFocus(true, true)
--     elseif module == "rules" then
--         SendNUIMessage({ action = 'reglement:open' })
--         SetNuiFocus(true, true)
--     elseif module == "illegalTablet" then
--         TriggerEvent('null:tablet:open')
--     elseif module == "boutique" then
--         SendNUIMessage({ action = 'boutique:open' })
--         SetNuiFocus(true, true)
--     elseif module == "animations" then
--         SendNUIMessage({ action = 'animations:open' })
--         SetNuiFocus(true, true)
--     elseif module == "settings" then
--         -- Open settings (F5 menu)
--         TriggerEvent('null:settings:open')
--     end

--     cb('ok')
-- end)

-- -- ─────────────────────────────────────────────────────────
-- -- Export
-- -- ─────────────────────────────────────────────────────────

-- exports('OpenPauseMenu', OpenPauseMenu)
-- exports('ClosePauseMenu', ClosePauseMenu)
-- exports('IsPauseMenuOpen', function() return PauseMenu.isOpen end)

-- null.InitPrint("Pause Menu Loaded")
