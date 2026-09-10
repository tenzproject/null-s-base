local Animations = {}
Animations.isOpen = false

local animationsLoaded = false
local favoriteAnimations = {}
 
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        if Animations.isOpen then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 135, true) -- VehicleSubDescend
            DisableControlAction(0, 223, true) -- VehicleExit
            DisableControlAction(0, 257, true) -- AttackAlternate
            DisableControlAction(0, 18, true)  -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim

            Wait(0)
        else
            Wait(500)
        end
    end
end))

Citizen.CreateThread(function()
    while GetResourceState('Animations') ~= 'started' do
        Citizen.Wait(100)
    end
    while not exports.Animations:AreAnimationsLoaded() do
        Citizen.Wait(100)
    end
    animationsLoaded = true
end)

Citizen.CreateThread(function()
    local saved = GetResourceKvpString('animation_favorites')
    if saved then
        favoriteAnimations = json.decode(saved) or {}
    else
        favoriteAnimations = {}
    end
end)

local function SaveFavorites()
    SetResourceKvp('animation_favorites', json.encode(favoriteAnimations))
end

local function SendAnimationsData()
    local animsData = exports.Animations:GetAllAnimations()
    if not animsData then return end

    SendNUIMessage({
        action = 'updateAnimationsData',
        favorites = favoriteAnimations,
        emotes = animsData.emotes or {},
        dances = animsData.dances or {},
        shared = animsData.shared or {},
        props = animsData.props or {},
        walks = animsData.walks or {},
        expressions = animsData.expressions or {},
        animals = animsData.animals or {}
    })
end

function Animations.Open()
    if Animations.isOpen then return end
    if not animationsLoaded then
        while not animationsLoaded do
            Citizen.Wait(100)
        end
    end

    Animations.isOpen = true
    DisableChat(true)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = 'animations:open'
    })
    Citizen.Wait(100)
    SendAnimationsData()
end

function Animations.Close()
    if not Animations.isOpen then return end
    Animations.isOpen = false
    DisableChat(false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'animations:close'
    })
end

RegisterNUICallback('animations:getData', function(data, cb)
    SendAnimationsData()
    cb('ok')
end)

RegisterNUICallback('animations:play', function(data, cb)
    local animKey = data.animation
    if animKey then
        exports.Animations:PlayAnimation(animKey)
    end
    cb('ok')
end)

RegisterNUICallback('animations:stop', function(data, cb)
    exports.Animations:CancelAnimation()
    cb('ok')
end)

RegisterNUICallback('animations:updateFavorites', function(data, cb)
    favoriteAnimations = data.favorites or {}
    SaveFavorites()
    cb('ok')
end)

RegisterNUICallback('animations:close', function(data, cb)
    Animations.Close()
    cb('ok')
end)

RegisterCommand('animations', function()
    if Animations.isOpen then
        Animations.Close()
    else
        Animations.Open()
    end
end, false)

RegisterKeyMapping('animations', 'Ouvrir le menu d\'animations', 'keyboard', 'F3')

exports('OpenAnimationsMenu', Animations.Open)
exports('CloseAnimationsMenu', Animations.Close)
