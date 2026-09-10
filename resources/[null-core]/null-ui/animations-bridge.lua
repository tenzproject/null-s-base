-- -- Bridge between null-ui and Animations resource
-- -- This file handles the communication between the new UI and the existing animation system

-- local isAnimationsMenuOpen = false
-- local favoriteAnimations = {}
-- local animationsLoaded = false

-- -- Wait for Animations resource to be loaded
-- Citizen.CreateThread(function()
--     while GetResourceState('Animations') ~= 'started' do
--         Citizen.Wait(100)
--     end
    
--     -- Wait for animations to be available via export
--     while not exports.Animations:AreAnimationsLoaded() do
--         Citizen.Wait(100)
--     end
    
--     animationsLoaded = true
-- end)

-- -- Load favorites from KVP
-- Citizen.CreateThread(function()
--     local saved = GetResourceKvpString('animation_favorites')
--     if saved then
--         favoriteAnimations = json.decode(saved) or {}
--     else
--         favoriteAnimations = {}
--     end
-- end)

-- -- Save favorites to KVP
-- function SaveFavorites()
--     SetResourceKvp('animation_favorites', json.encode(favoriteAnimations))
-- end

-- -- Open animations menu
-- function OpenAnimationsMenu()
--     if isAnimationsMenuOpen then return end
    
--     -- Wait for animations to be loaded
--     if not animationsLoaded then
--         while not animationsLoaded do
--             Citizen.Wait(100)
--         end
--     end
    
--     isAnimationsMenuOpen = true
    
--     SetNuiFocus(true, true)
--     SetNuiFocusKeepInput(false)
--     SendNUIMessage({
--         type = "open",
--         category = "animations"
--     })
    
--     -- Send animations data to NUI
--     Citizen.Wait(100)
--     SendAnimationsData()
-- end

-- -- Close animations menu
-- function CloseAnimationsMenu()
--     isAnimationsMenuOpen = false
--     SetNuiFocus(false, false)
--     SetNuiFocusKeepInput(true)
--     SendNUIMessage({
--         type = "close"
--     })
-- end

-- -- Send all animations data to NUI
-- function SendAnimationsData()
--     -- Get all animations from the Animations resource export
--     local animsData = exports.Animations:GetAllAnimations()
    
--     if not animsData then
--         print("[Animations Bridge] ERROR: Failed to get animations data from export!")
--         return
--     end
    
--     -- Count animations for logging
--     local counts = {
--         emotes = animsData.emotes and #animsData.emotes or 0,
--         dances = animsData.dances and #animsData.dances or 0,
--         shared = animsData.shared and #animsData.shared or 0,
--         props = animsData.props and #animsData.props or 0,
--         walks = animsData.walks and #animsData.walks or 0,
--         expressions = animsData.expressions and #animsData.expressions or 0,
--         animals = animsData.animals and #animsData.animals or 0
--     }

--     -- Prepare data for NUI
--     local data = {
--         action = "updateAnimationsData",
--         favorites = favoriteAnimations,
--         emotes = animsData.emotes or {},
--         dances = animsData.dances or {},
--         shared = animsData.shared or {},
--         props = animsData.props or {},
--         walks = animsData.walks or {},
--         expressions = animsData.expressions or {},
--         animals = animsData.animals or {}
--     }
    
--     SendNUIMessage(data)
-- end

-- -- NUI Callbacks
-- RegisterNUICallback('getAnimationsData', function(data, cb)
--     SendAnimationsData()
--     cb('ok')
-- end)

-- RegisterNUICallback('playAnimation', function(data, cb)
--     local animKey = data.animation
--     local category = data.category
    
--     -- Use the export from Animations resource
--     local success = exports.Animations:PlayAnimation(animKey)
    
--     if not success then
--         print("[Animations Bridge] ERROR: Failed to play animation " .. animKey)
--     end
    
--     cb('ok')
-- end)

-- RegisterNUICallback('stopAnimation', function(data, cb)
--     -- Use the export from Animations resource
--     local success = exports.Animations:CancelAnimation()
    
--     if not success then
--         print("[Animations Bridge] ERROR: Failed to cancel animation")
--     end
    
--     cb('ok')
-- end)

-- RegisterNUICallback('updateFavorites', function(data, cb)
--     favoriteAnimations = data.favorites or {}
--     SaveFavorites()
--     cb('ok')
-- end)

-- RegisterNUICallback('closeAnimations', function(data, cb)
--     CloseAnimationsMenu()
--     SetNuiFocus(false, false)
--     cb('ok')
-- end)

-- -- Command to open animations menu
-- RegisterCommand('anims', function()
--     OpenAnimationsMenu()
-- end, false)

-- -- Keybind for animations menu (F3 by default, same as old menu)
-- RegisterKeyMapping('anims', 'Ouvrir le menu d\'animations', 'keyboard', 'F3')

-- -- Export functions
-- exports('OpenAnimationsMenu', OpenAnimationsMenu)
-- exports('CloseAnimationsMenu', CloseAnimationsMenu)
