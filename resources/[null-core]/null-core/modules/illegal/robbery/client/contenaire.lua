local function DrawMarkerCustom(coords)
    DrawMarker(25, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
end



local function loadPtfxAsset(dict)

    while not HasNamedPtfxAssetLoaded(dict) do

      RequestNamedPtfxAsset(dict)

      Wait(50)

    end

end



local function loadAnimDict(dict)

    while not HasAnimDictLoaded(dict) do

        RequestAnimDict(dict)

        Wait(50)

    end

end



local function loadModel(model)

    if type(model) == 'number' then

        model = model

    else

        model = GetHashKey(model)

    end

    while not HasModelLoaded(model) do

        RequestModel(model)

        Wait(0)

    end

end



local function ShowHelpNotification(text)

    SetTextComponentFormat("STRING")

    AddTextComponentString(text)

    DisplayHelpTextFromStringLabel(0, 0, 1, 50)

end



local function ShowNotification(msg)

    SetNotificationTextEntry('STRING')

    AddTextComponentString(msg)

    DrawNotification(0,1)

end







local function PlayCutscene(cut, coords)

    while not HasThisCutsceneLoaded(cut) do 

        RequestCutscene(cut, 8)

        Wait(0) 

    end

    CreateCutscene(false, coords)

    Finish(coords)

    RemoveCutscene()

    DoScreenFadeIn(500)

end



local function CreateCutscene(change, coords)

    local ped = PlayerPedId()   

    local clone = ClonePedEx(ped, 0.0, false, true, 1)

    local clone2 = ClonePedEx(ped, 0.0, false, true, 1)

    local clone3 = ClonePedEx(ped, 0.0, false, true, 1)

    local clone4 = ClonePedEx(ped, 0.0, false, true, 1)

    local clone5 = ClonePedEx(ped, 0.0, false, true, 1)



    SetBlockingOfNonTemporaryEvents(clone, true)

    SetEntityVisible(clone, false, false)

    SetEntityInvincible(clone, true)

    SetEntityCollision(clone, false, false)

    FreezeEntityPosition(clone, true)

    SetPedHelmet(clone, false)

    RemovePedHelmet(clone, true)

    

    if change then

        SetCutsceneEntityStreamingFlags('MP_2', 0, 1)

        RegisterEntityForCutscene(ped, 'MP_2', 0, GetEntityModel(ped), 64)



        SetCutsceneEntityStreamingFlags('MP_1', 0, 1)

        RegisterEntityForCutscene(clone2, 'MP_1', 0, GetEntityModel(clone2), 64)

    else

        SetCutsceneEntityStreamingFlags('MP_1', 0, 1)

        RegisterEntityForCutscene(ped, 'MP_1', 0, GetEntityModel(ped), 64)



        SetCutsceneEntityStreamingFlags('MP_2', 0, 1)

        RegisterEntityForCutscene(clone2, 'MP_2', 0, GetEntityModel(clone2), 64)

    end



    SetCutsceneEntityStreamingFlags('MP_3', 0, 1)

    RegisterEntityForCutscene(clone3, 'MP_3', 0, GetEntityModel(clone3), 64)



    SetCutsceneEntityStreamingFlags('MP_4', 0, 1)

    RegisterEntityForCutscene(clone4, 'MP_4', 0, GetEntityModel(clone4), 64)



    SetCutsceneEntityStreamingFlags('MP_5', 0, 1)

    RegisterEntityForCutscene(clone5, 'MP_5', 0, GetEntityModel(clone5), 64)



    Wait(10)

    if coords then

        StartCutsceneAtCoords(coords, 0)

    else

        StartCutscene(0)

    end

    Wait(10)

    ClonePedToTarget(clone, ped)

    Wait(10)

    DeleteEntity(clone)

    DeleteEntity(clone2)

    DeleteEntity(clone3)

    DeleteEntity(clone4)

    DeleteEntity(clone5)

    Wait(50)

    DoScreenFadeIn(250)

end



local function Finish(coords)

    if coords then

        local tripped = false

        repeat

            Wait(0)

            if (timer and (GetCutsceneTime() > timer))then

                DoScreenFadeOut(250)

                tripped = true

            end

            if (GetCutsceneTotalDuration() - GetCutsceneTime() <= 250) then

            DoScreenFadeOut(250)

            tripped = true

            end

        until not IsCutscenePlaying()

        if (not tripped) then

            DoScreenFadeOut(100)

            Wait(150)

        end

        return

    else

        Wait(18500)

        StopCutsceneImmediately()

    end

end



local function CT_GetReward()

    local item = ""

    local type_Reward = ""

    chance = math.random(1, 2)

    if chance == 1 then

        type_Reward = "cash"

    else

        type_Reward = "item"

    end 

    if type_Reward == "cash" then 

        chance_loot = math.random(1, 2) 

        if chance_loot == 1 then

            type_loot = "dirtycash"

        else

            type_loot = "money"

        end

        min = Config.Items["cash"][type_loot][1].min

        max = Config.Items["cash"][type_loot][1].max

        return type_Reward, type_loot, math.random(min, max)

    end 

    chance_loot = math.random(1, 100)   

    if chance_loot > 95 then

        item = "epique"

    elseif chance_loot < 10 then

        item = "rare"

    else

        item = "common"

    end

    chance_loot = math.random(1, 2) 

    if chance_loot == 1 then

        type_loot = "weapon"

    else

        type_loot = "item"

    end

    re = Config.Items["item"][item][type_loot][math.random(1, #Config.Items["item"][item][type_loot])]

    return type_Reward, type_loot, 1 , re

end



local function StartTakenConteneur()

    ClearPedTasks(PlayerPedId())

    loadAnimDict('mini@repair')

    TaskPlayAnim(PlayerPedId(), 'mini@repair', 'fixing_a_ped', 8.0, 8.0, -1, 1, 0, false, false, false)

    Citizen.Wait(25000)

    ClearPedTasks(PlayerPedId())

    type_item, type_loot, cb_togive, data = CT_GetReward()

    TriggerServerEvent('null:giveItem', type_item, type_loot, cb_togive, data)

end



AnimationListtt = {

    ['objects'] = {

        'tr_prop_tr_grinder_01a'

    },

    ['animations'] = {

        {'action', 'action_container', 'action_lock', 'action_angle_grinder', 'action_bag'}

    },

    ['sceneObjects'] = {}

}



Citizen.CreateThread(function()

    for k,v in pairs(Config.ContainerRobbery.Spawn_zones) do 

        props = "tr_prop_tr_container_01a"

        RequestModel(props)

        while not HasModelLoaded(props) do

            Wait(1)

        end

        local object = CreateObject(GetHashKey(props), v.pos.x, v.pos.y, v.pos.z-0.98, true, true, true)

        local box = CreateObject(GetHashKey("prop_boxpile_01a"), v.pos.x, v.pos.y, v.pos.z-0.98, true, true, true)

        SetEntityHeading(object, v.pos.w)

        FreezeEntityPosition(object, true)

        FreezeEntityPosition(box, true)

    end

end)





Citizen.CreateThread(function()

    while true do 

        xt = 1000

        for k,v in pairs(Config.ContainerRobbery.Spawn_zones) do 

            dist = #(GetEntityCoords(PlayerPedId()) - vector3(v.pos.x, v.pos.y, v.pos.z))

            if dist < 4 then

              xt = 1

              DrawMarkerCustom(v.pos)

                if dist < 1.2 then

                    xt = 1

                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour fouiller le conteneur")

                    if IsControlJustPressed(0, 51) then

                        TriggerServerEvent("null:conteneur:client:OpenC", v.id)

                    end

                end

            end

        end

        Citizen.Wait(xt)

    end

end)



RegisterNetEvent("null:conteneur:client:OpenC")

AddEventHandler("null:conteneur:client:OpenC", function(id, time)

    for k,v in pairs(Config.ContainerRobbery.Spawn_zones) do 

        if v.id == id then

            if time - v.last > Config.Interval then

                TriggerServerEvent("null:conteneur:server:take", v.id)

                StartTakenConteneur()

            else 

                ESX.ShowNotification("Ce conteneur a déjà été fouillé")

            end

        end

    end

end)



RegisterNetEvent("null:conteneur:client:take")

AddEventHandler("null:conteneur:client:take", function(ID, time)

    for k,v in pairs(Config.ContainerRobbery.Spawn_zones) do 

        if v.id == ID then

            v.last = time

        end

    end

end)





RegisterNetEvent("null:conteneur:client:dril")

AddEventHandler("null:conteneur:client:dril", function()

    local ped = PlayerPedId()

    local pedCo = GetEntityCoords(ped)

    local pedRotation = GetEntityRotation(ped)

    local animDict = 'anim@scripted@player@mission@tunf_train_ig1_container_p1@male@'

    sceneObject = GetClosestObjectOfType(pedCo, 2.5, GetHashKey('tr_prop_tr_container_01a'), 0, 0, 0)

    lockObject = GetClosestObjectOfType(pedCo, 2.5, GetHashKey('tr_prop_tr_lock_01a'), 0, 0, 0)



    dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(sceneObject))

    --dist2 = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(lockObject))

    if dist > 7.5 then

        ESX.ShowNotification("Vous devez être plus près du conteneur")

        return

    end

    loadAnimDict(animDict)

    loadPtfxAsset('scr_tn_tr')

    TriggerServerEvent('cfx-container:server:lockSync', index)

    for i = 1, #AnimationListtt['objects'] do

      loadModel(AnimationListtt['objects'][i])

      AnimationListtt['sceneObjects'][i] = CreateObject(GetHashKey(AnimationListtt['objects'][i]), pedCo, 1, 1, 0)

    end



    NetworkRegisterEntityAsNetworked(sceneObject)

    NetworkRegisterEntityAsNetworked(lockObject)

    scene = NetworkCreateSynchronisedScene(GetEntityCoords(sceneObject), GetEntityRotation(sceneObject), 2, true, false, 1065353216, 0, 1065353216)

    NetworkAddPedToSynchronisedScene(ped, scene, animDict, AnimationListtt['animations'][1][1], 4.0, -4.0, 1033, 0, 1000.0, 0)

    NetworkAddEntityToSynchronisedScene(sceneObject, scene, animDict, AnimationListtt['animations'][1][2], 1.0, -1.0, 1148846080)

    NetworkAddEntityToSynchronisedScene(lockObject, scene, animDict, AnimationListtt['animations'][1][3], 1.0, -1.0, 1148846080)

    NetworkAddEntityToSynchronisedScene(AnimationListtt['sceneObjects'][1], scene, animDict, AnimationListtt['animations'][1][4], 1.0, -1.0, 1148846080)

    NetworkAddEntityToSynchronisedScene(AnimationListtt['sceneObjects'][2], scene, animDict, AnimationListtt['animations'][1][5], 1.0, -1.0, 1148846080)

    SetEntityCoords(ped, GetEntityCoords(sceneObject))

    NetworkStartSynchronisedScene(scene)

    Wait(4000)

    UseParticleFxAssetNextCall('scr_tn_tr')

    sparks = StartParticleFxLoopedOnEntity("scr_tn_tr_angle_grinder_sparks", AnimationListtt['sceneObjects'][1], 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false, 1065353216, 1065353216, 1065353216, 1)

    Wait(1000)

    StopParticleFxLooped(sparks, 1)

    Wait(GetAnimDuration(animDict, 'action') * 1000 - 5000)

    DeleteObject(AnimationListtt['sceneObjects'][1])

    DeleteObject(AnimationListtt['sceneObjects'][2])

    TriggerServerEvent('cfx-container:server:containerSync', GetEntityCoords(sceneObject), GetEntityRotation(sceneObject))

    TriggerServerEvent('cfx-container:server:objectSync', NetworkGetNetworkIdFromEntity(sceneObject))

    TriggerServerEvent('cfx-container:server:objectSync', NetworkGetNetworkIdFromEntity(lockObject))

    ClearPedTasks(ped)

end)







RegisterNetEvent('cfx-container:client:containerSync')

AddEventHandler('cfx-container:client:containerSync', function(coords, rotation)

    animDict = 'anim@scripted@player@mission@tunf_train_ig1_container_p1@male@'

    loadAnimDict(animDict)

    clientContainer = CreateObject(GetHashKey('tr_prop_tr_container_01a'), coords, 0, 0, 0)

    clientScene = CreateSynchronizedScene(coords, rotation, 2, true, false, 1065353216, 0, 1065353216)

    PlaySynchronizedEntityAnim(clientContainer, clientScene, AnimationListtt['animations'][1][2], animDict, 1.0, -1.0, 0, 1148846080)

    ForceEntityAiAndAnimationUpdate(clientContainer)

    PlaySynchronizedEntityAnim(clientLock, clientScene, AnimationListtt['animations'][1][3], animDict, 1.0, -1.0, 0, 1148846080)

    SetSynchronizedScenePhase(clientScene, 0.99)

    SetEntityCollision(clientContainer, false, true)

    FreezeEntityPosition(clientContainer, true)

end)



RegisterNetEvent('cfx-container:client:objectSync')

AddEventHandler('cfx-container:client:objectSync', function(e)

  local entity = NetworkGetEntityFromNetworkId(e)

  DeleteEntity(entity)

  DeleteObject(entity)

end)