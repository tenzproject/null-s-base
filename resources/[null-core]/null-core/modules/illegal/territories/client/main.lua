TerritoriesLoaded = false
territories = nil
local zones = {}
local zonesMinMax = {}

local insideZone = false
local insideZoneAttack = false
local currentZone = nil
local currentZoneSave = nil
local currentZoneAttack = nil
local isSelling = false
local isProcessingPoint = false

Citizen.CreateThread(function()
    TriggerServerEvent('Null:initTerritories')
end)
local createdPeds = {}

RegisterNetEvent('Null:RecevieTerritories', function(data)
    territories = data
    TerritoriesLoaded = true
    Wait(1000)
    for k,v in pairs(createdPeds) do 
        if DoesEntityExist(v.ped) then DeleteEntity(v.ped) end
    end
    for k,v in pairs(data) do
        ESX.Streaming.RequestModel(GetHashKey(v.PNJ.model))
        local storePed = CreatePed(4, GetHashKey(v.PNJ.model), v.PNJ.pos.x, v.PNJ.pos.y, v.PNJ.pos.z-0.98, v.PNJ.heading, false, false)
        --SetPedRandomComponentVariation(storePed)
        SetCurrentPedWeapon(storePed, `WEAPON_MG`, true)
        SetEntityHeading(storePed, v.PNJ.heading)
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
        SetAmbientVoiceName(storePed, v.PNJ.voice)
        TaskStartScenarioInPlace(storePed, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
        SetModelAsNoLongerNeeded(GetHashKey(v.PNJ.model))
        table.insert(createdPeds, { ped = storePed, id=v.id, name = v.PNJ.floatingText.text }) 

        local polyzone = PolyZone:Create(v.points, {
            name = ("territories_%s"):format(v.id),
            data = {
                id = v.id,
                name = v.name,
                pos = v.position,
                owner = v.owner,
            }
        })
        table.insert(zones, polyzone)

		polyzone:onPlayerInOut(function(isPointInside, point)
            if not insideZone then
                if isPointInside then
                    insideZone = true
                    timetocheck = 10000
                    currentZone = v
                    currentZoneSave = v
                    TriggerServerEvent("Null:territories:enterZone", v.id)
                end
            else
                if currentZone ~= nil and not isPointInside then
                    insideZone = false
                    timetocheck = 2500
                    TriggerServerEvent("Null:territories:exitZone", currentZone.id)
                    currentZone = nil
                end
            end
		end)

        local tpts = v.territoryPoints and #v.territoryPoints > 0 and v.territoryPoints or v.points
        local areaZone = PolyZone:Create(tpts, {
            name = ("territories_area_%s"):format(v.id),
            data = {
                id = v.id,
                name = v.name,
                pos = v.position,
                owner = v.owner,
            }
        })
        table.insert(zones, areaZone)

        -- areaZone:onPlayerInOut(function(isPointInside, point)
        --     SendNUIMessage({ action = "indicator:update", data = {
        --         id = "dangerous-zone",
        --         show = isPointInside,
        --         label = isPointInside and ("%s - Zone dangereuse"):format(v.name) or nil,
        --         icon = isPointInside and "dangerous" or nil,
        --     }})
        -- end)

        polyzone:onPlayerInOut(function(isPointInside, point)
            SendNUIMessage({ action = "indicator:update", data = {
                id = "dangerous-zone",
                show = isPointInside,
                label = isPointInside and ("%s - Zone dangereuse"):format(v.name) or nil,
                icon = isPointInside and "dangerous" or nil,
            }})
        end)
    end
end)

local shop = {}
function TerritoireShop(id)
    ESX.TriggerServerCallback("territories:getTerritoriesShop", function(data)
        shop = data
    end, id)

	local main = RageUI.CreateMenu("", "Actions disponible :")
	RageUI.Visible(main, not RageUI.Visible(main))
	while main do
		Citizen.Wait(0)
			RageUI.IsVisible(main, function()
                for _, v in pairs(shop) do
                    -- ("Coût en points: %s"):format(v.points)
                    RageUI.Button(("%s"):format(v.label), nil, { RightLabel = ("~r~%s~s~ $"):format(ESX.Math.Round(v.price)) }, true, {
                        onSelected = function ()
                            -- local type = null.fct.input("Avec quoi voulez-vous payer", true, {
                            --     {type = 'select', label = 'Type de job : ', default = "dirtycash",description="Avec quoi voulez-vous payer",
                            --     options={{value="dirtycash", label="Argent Sale"},{value="points", label="Points"}}
                            --     },
                            -- })
                            local type = "dirtycash"
                            TriggerServerEvent("null:territories:buyShop", id, v.id, type)
                        end
                    })
                end
			end)
		if not RageUI.Visible(main) then
			main = RMenu:DeleteType('main', true)
		end
	end
end

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(100)
			for _, v in pairs(createdPeds) do
				if IsPedFleeing(v.ped) then
					ClearPedTasks(v.ped)
					TaskStartScenarioInPlace(v.ped, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
				end
			end
		end
	end
)

local gamerTags = {}
local isProche = false
Citizen.CreateThread(function()
    while true do
        isProche = false
        local plyPed = PlayerPedId()
        for k,v in pairs(createdPeds) do
            local distance = #(GetEntityCoords(plyPed, false) - GetEntityCoords(v.ped, false))
            if distance < 1.3 then
                isProche = true
                if currentZoneSave and ESX.PlayerData.job2.name == currentZoneSave.owner then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour intéragir avec l'individu")
                    if IsControlPressed(0, 38) then
                        if currentZoneSave ~= nil then
                            if ESX.PlayerData.job2.name == currentZoneSave.owner then
                                TerritoireShop(v.id)
                            end
                        end
                    end
                else
                    ESX.ShowHelpNotification("~r~Vous n'avez pas accès à ce shop.")
                end
            end
            if distance < 5.0 then
                isProche = true
                gamerTags[v.ped] = CreateFakeMpGamerTag(v.ped, v.name, false, false, "", 0)
                SetMpGamerTagAlpha(gamerTags[v.ped], 0, 255)
                SetMpGamerTagAlpha(gamerTags[v.ped], 14, 255)
                SetMpGamerTagVisibility(gamerTags[v.ped], 0, true)
                SetMpGamerTagVisibility(gamerTags[v.ped], 14, true)
            else
                RemoveMpGamerTag(gamerTags[v.ped])
                gamerTags[v.ped] = nil
            end
        end
        if isProche then
			Citizen.Wait(1)
		else
			Citizen.Wait(750)
		end
    end
    for k,v in pairs(gamerTags) do
        RemoveMpGamerTag(v)
    end
gamerTags = {}
end)

local cooldown = false
function drugsCooldown(time)
    cooldown = true
    Citizen.SetTimeout(time,function()
        cooldown = false
    end)
end
local InAnim = false
local CreatedSellerPed = {}

function DeleteSellerPed()
    local pedsToDelete = CreatedSellerPed
    CreatedSellerPed = {}
    for k,v in pairs(pedsToDelete) do 
        if DoesEntityExist(v.ped) then
            FreezeEntityPosition(v.ped, false)
            Citizen.CreateThread(function()
                TaskGoToCoordAnyMeans(v.ped, v.originalCoords.x, v.originalCoords.y, v.originalCoords.z, 1.0, 0, 0, 786603, 0)
                Wait(20000)
                DeleteEntity(v.ped)
            end)
        end
    end
    ESX.removeBlip("drugSelling_blip")
    ESX.removeBlip("drugSelling_blip_ped")
end

RobSelledPed = nil
local bagSeller = nil
function StartSelledPedReply(ped)
    TriggerServerEvent("null:territories:startSelledPedReply", ped)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetPedAsEnemy(ped, true)
    SetPedMaxHealth(ped, 200)
    SetPedArmour(ped, 200)
    SetBlockingOfNonTemporaryEvents(ped, false)
    
    Citizen.CreateThread(function()
        local pedDropSac = false 
        while true do
            if not DoesEntityExist(ped) then break end
            if PlayerIsDead then
                ClearPedTasks(ped)
                RemoveAllPedWeapons(ped, 1)
            end
            if GetEntityHealth(ped) <= 0 and not pedDropSac then
                ClearPedTasks(ped)
                RemoveAllPedWeapons(ped, 1)
                bagSeller = CreateObject(GetHashKey("prop_poly_bag_01"), 0.0, 0.0, 0.0, 1, 1, 0)
                AttachEntityToEntity(bagSeller, ped, GetPedBoneIndex(ped, 60309), 0.1, -0.11, 0.08, 0.0, -75.0, -75.0, 1, 1, 0, 0, 2, 1)
                pedDropSac = true
            end
            if pedDropSac then
                local pedCoords = GetEntityCoords(ped)
                local bagCoords = GetEntityCoords(bagSeller)
                local coords = GetEntityCoords(PlayerPedId())
                local distance = #(bagCoords - coords)
                if distance < 2.0 then
                    null.fct.draw.Text3DBar(bagCoords.x, bagCoords.y, bagCoords.z, "[~y~E~s~] Récupérer le sac.")
                    if IsControlJustReleased(0, 51) then
                        local dict, anim = "random@domestic", "pickup_low"
                        ESX.Streaming.RequestAnimDict(dict)
                        TaskPlayAnim(PlayerPedId(), dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                        Wait(1200)
                        TriggerServerEvent("null:territories:takeMoney", ped, "kill")
                        isSelling = false
                        isProcessingPoint = false
                        DeleteObject(bagSeller)
                        bagSeller = nil
                        Citizen.CreateThread(function()
                            Wait(10000)
                            DeleteEntity(ped)
                        end)
                        Citizen.CreateThread(function()
                            Wait(4000)
                            TriggerServerEvent("Null:territories:enterZone", currentZone.id)
                        end)
                        break
                    end
                end
            end
            Wait(0)
        end
        RobSelledPed = nil
    end)

    GiveWeaponToPed(ped, GetHashKey(Config.Territories.weaponToReply[math.random(1, #Config.Territories.weaponToReply)]), 0, 1, 1)
    TaskAimGunAtEntity(ped, PlayerPedId(), 2000, false)
    Wait(2000)
    TaskShootAtEntity(ped, PlayerPedId(), 6000, -957453492)
    Wait(6500)
    RemoveAllPedWeapons(ped, 1)
    ClearPedTasks(ped)
    DeleteSellerPed()
end

RegisterNetEvent('null:territories:addPoint')
AddEventHandler('null:territories:addPoint', function(point,z, PointID, confianceMult)
    if currentZone == nil then 
        null.DebugPrint("currentZone == nil")
        return 
    end
    if isSelling or isProcessingPoint then
        null.DebugPrint("already selling or processing, ignoring addPoint")
        return
    end
    isProcessingPoint = true
    while cooldown do
        FreezeEntityPosition(PlayerPedId(), true)
        if not InAnim then
            InAnim = true 
            local dict, anim = "mp_common", "givetake1_a" 
            ESX.Streaming.RequestAnimDict(dict)
            TaskPlayAnim(PlayerPedId(), dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)

            if CreatedSellerPed then
                for k,v in pairs(CreatedSellerPed) do
                    TaskPlayAnim(v.ped, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                end
            end
        end
        Wait(100)
    end
    InAnim = false

    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local _, z = GetGroundZFor_3dCoord_2(point.x, point.y, pedCoords.z + 100.0, true)
    if (z - GetEntityCoords(PlayerState.ped).z) > 4.0 then
        TriggerServerEvent("Null:territories:retryPoint", currentZone.id)
        null.DebugPrint("point to high, respawn")
        isProcessingPoint = false
        return
    end
    local coords = vector3(point.x, point.y, z)
    for k,v in pairs(zones) do
        if v.id == PointID then
            break
        end
    end
    DeleteSellerPed()
    
    ESX.ShowNotification('⏱️ Vous êtes en attente d\'acheteur.')
    local mult = confianceMult or 1.0
    local waitMin = math.floor(Config.Territories.timeToWait.min * mult)
    local waitMax = math.floor(Config.Territories.timeToWait.max * mult)
    Wait(math.random(waitMin, waitMax))

    local pedModel = Config.AllPedModel[math.random(1, #Config.AllPedModel)]
    RequestModel(pedModel)    
    while not HasModelLoaded(pedModel) do
        Citizen.Wait(100)
    end    
    local id = #CreatedSellerPed+1
    local headingPed = 0.0
    local spawnRadius = 50.0
    local spawnCoords = null.fct.GenerateRandomCoordAroundPoint(coords, spawnRadius)
    ESX.ShowNotification('⏱️ Un acheteur arrive sur vous, veuillez patienter.')
    local PlayerCoords = GetEntityCoords(PlayerPedId())
    CreatedSellerPed[id] = {
        originalCoords = spawnCoords,
        ped = nil,
    }
    CreatedSellerPed[id].ped = CreatePed(0, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, false, false) 
    SetBlockingOfNonTemporaryEvents(CreatedSellerPed[id].ped, true)
    SetEntityInvincible(CreatedSellerPed[id].ped, true)
    FreezeEntityPosition(CreatedSellerPed[id].ped, false)
    SetPedCanRagdoll(CreatedSellerPed[id].ped, false)
    
    ESX.addBlips({
        name = 'drugSelling_blip_ped',
        label = '[DROGUE] Acheteur',
        category = nil,
        position = spawnCoords,
        sprite = 126,
        display = 4,
        scale = 0.75,
        color = 1
    })

    TaskGoToCoordAnyMeans(CreatedSellerPed[id].ped, coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 0)
    
    local arrived = false
    local timePassed = 0
    while not arrived and (CreatedSellerPed[id] ~= nil and CreatedSellerPed[id].ped ~= nil and DoesEntityExist(CreatedSellerPed[id].ped)) do
        local pedCoords = GetEntityCoords(CreatedSellerPed[id].ped)
        local distance = #(pedCoords - coords)
        ESX.updateBlipCoords('drugSelling_blip_ped', pedCoords)
        if distance < 1.5 then
            arrived = true
            TaskTurnPedToFaceCoord(CreatedSellerPed[id].ped, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
            TaskLookAtEntity(CreatedSellerPed[id].ped, PlayerPedId(), -1, 2048, 3)
            Wait(1000)
            FreezeEntityPosition(CreatedSellerPed[id].ped, true)
        end
        
        Citizen.Wait(500)
        timePassed = timePassed + 500
        if timePassed > 60000 then
            arrived = true
            SetEntityCoords(CreatedSellerPed[id].ped, coords.x, coords.y, coords.z)
            TaskTurnPedToFaceCoord(CreatedSellerPed[id].ped, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
            TaskLookAtEntity(CreatedSellerPed[id].ped, PlayerPedId(), -1, 2048, 3)
            Wait(1000)
            FreezeEntityPosition(CreatedSellerPed[id].ped, true)
        end
    end
    ESX.removeBlip("drugSelling_blip_ped")
    ESX.addBlips({
        name = 'drugSelling_blip',
        label = '[DROGUE] Vente',
        category = nil,
        position = coords,
        sprite = 280,
        display = 4,
        scale = 0.75,
        color = 17
    })

    isSelling = true
    isProcessingPoint = false

    Citizen.CreateThread(function ()
        while isSelling do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local pedCoords = GetEntityCoords(CreatedSellerPed[id].ped)
            if (IsPlayerFreeAiming(PlayerId()) or IsPedInMeleeCombat(PlayerPedId())) and RobSelledPed == nil then
                local isPedWantReply = math.random(1, 100)
                if isPedWantReply <= Config.Territories.ChanceToPedReply or IsPedInMeleeCombat(PlayerPedId()) or GetSelectedPedWeapon(PlayerPedId()) == GetHashKey('WEAPON_KNIFE') then
                    RobSelledPed = "robbed"
                    StartSelledPedReply(CreatedSellerPed[id].ped)
                    break
                else
                    RobSelledPed = "rob"
                    ESX.Streaming.RequestAnimDict("random@mugging3")
                    TaskPlayAnim(CreatedSellerPed[id].ped, "random@mugging3", "handsup_standing_base", 8.0, -8, -1, 49, 0, 0, 0, 0)
                    TriggerServerEvent("null:territories:startSelledPedReply", CreatedSellerPed[id].ped)
                end
            end
            if RobSelledPed == "rob" then
                local distance = #(pedCoords - playerCoords)
                if distance < 1.0 then
                    null.fct.draw.Text3DBar(pedCoords.x, pedCoords.y, pedCoords.z, "[~y~E~s~] Récupérer son argent.")
                    if IsControlJustReleased(0, 51) then
                        RobSelledPed = nil
                        PlayerCoords = GetEntityCoords(PlayerPedId())
                        TaskTurnPedToFaceCoord(PlayerPedId(), pedCoords.x, pedCoords.y, pedCoords.z, 1000)
                        TaskTurnPedToFaceCoord(CreatedSellerPed[id].ped, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
                        Wait(1200)
                        FreezeEntityPosition(CreatedSellerPed[id].ped, true)
                        FreezeEntityPosition(PlayerPedId(), true)
                        ClearPedTasks(CreatedSellerPed[id].ped)
                        
                        local dict, anim = "mp_common", "givetake1_a" 
                        ESX.Streaming.RequestAnimDict(dict)
                        TaskPlayAnim(PlayerPedId(), dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
            
                        if CreatedSellerPed then
                            for k,v in pairs(CreatedSellerPed) do
                                TaskPlayAnim(v.ped, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
                            end
                        end
                        TriggerServerEvent("null:territories:takeMoney", CreatedSellerPed[id].ped, "rob")
                        isSelling = false
                        isProcessingPoint = false
                        Citizen.CreateThread(function()
                            Wait(2000)
                            ClearPedTasks(CreatedSellerPed[id].ped)
                            SetBlockingOfNonTemporaryEvents(CreatedSellerPed[id].ped, false)
                            DeleteSellerPed()
                            Wait(4000)
                            TriggerServerEvent("Null:territories:enterZone", currentZone.id)
                        end)
                    end
                end
            end

            if #(pedCoords - playerCoords) < 1.5 and RobSelledPed == nil then
                null.fct.draw.Text3DBar(pedCoords.x, pedCoords.y, pedCoords.z, "[~y~E~s~] Lui vendre de la drogue.")

                if IsControlJustReleased(0, 51) then
                    if GetSelectedPedWeapon(PlayerPedId()) ~= GetHashKey('WEAPON_UNARMED') then
                        ESX.ShowNotification("❌ Vous devez ranger votre arme.")
                    else
                        if not IsEntityInAir(PlayerPedId()) then
                            FreezeEntityPosition(PlayerPedId(), true)
                            FreezeEntityPosition(CreatedSellerPed[id].ped, true)
                            drugsCooldown(5500)
                            Wait(500)
                            PlayerCoords = GetEntityCoords(PlayerPedId())
                            FreezeEntityPosition(CreatedSellerPed[id].ped, false)
                            FreezeEntityPosition(PlayerPedId(), false)
                            TaskTurnPedToFaceCoord(PlayerPedId(), pedCoords.x, pedCoords.y, pedCoords.z, 1000)
                            TaskTurnPedToFaceCoord(CreatedSellerPed[id].ped, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1000)
                            Wait(1200)
                            FreezeEntityPosition(CreatedSellerPed[id].ped, true)
                            FreezeEntityPosition(PlayerPedId(), true)
                            TriggerServerEvent("territories:sellDrugs", PointID)
                            ESX.removeBlip("drugSelling_blip_ped")
                            ESX.removeBlip("drugSelling_blip")
                            isSelling = false
                            isProcessingPoint = false
                        end
                    end
                end
            end

            Citizen.Wait(0)
        end
    end) 
end)

RegisterNetEvent("null:territories:clearPoint", function ()
    isSelling = false
    isProcessingPoint = false
    DeleteSellerPed()
    FreezeEntityPosition(PlayerPedId(), false)
end)