function ReworkLogs(data, type, cancel1, data2)
    null.logs.send(data[1]["title"],data[1]["description"],type)
end


function getStaffReport(idU)
    if SaveData.Admin.Staffs.List[idU] ~= nil then
        return {
            Week = {
                Take = SaveData.Admin.Staffs.List[idU].nbrReport_take_week,
                Close = SaveData.Admin.Staffs.List[idU].nbrReport_close_week,
            },
            Total = SaveData.Admin.Staffs.List[idU].nbrReport,
        }
    else
        return {
            Week = {
                Take = 0,
                Close = 0,
            },
            Total = 0,
        }
    end
end

function notifStaff(msg, src)
    for k,v in pairs(ESX.Players) do
        local xPlayer = v
        if xPlayer == nil then goto continue end
        if xPlayer.getGroup() == "user" then goto continue end
        if (src == nil and not xPlayer.getStaffMode()) or (src ~= nil and v.source ~= src) then goto continue end
        if StreamersModeActive[xPlayer.getIdunique()] == true then goto continue end
        TriggerClientEvent("esx:showNotification", xPlayer.source, msg)
        ::continue::
    end
end

function WipeTable(targetId) -- Fonction qui vide la table des joueurs lors d'un wipe
    if targetId == nil then return end
    MySQL.Async.execute("DELETE FROM vclothes WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM vbackpacks WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM vkevlars WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM billing WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM starterpack WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM playerstattoos WHERE identifier = @identifier", {['@identifier'] = targetId})
    
    for k,v in pairs(SaveData.json["owned_vehicles"]) do 
        if v.owner == targetId then
            if not v.boutique then
                SaveData.json["owned_vehicles"][k] = nil
            end
        end
    end
    MySQL.Async.execute("DELETE FROM vbank WHERE identifier = @identifier", {['@identifier'] = targetId})
    MySQL.Async.execute("DELETE FROM user_licenses WHERE owner = @owner", {['@owner'] = targetId})

    MySQL.Async.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
		['@identifier'] = targetId
	}, function(result)
		if result[1] ~= nil then
            local listearmeperm = {}
            local oldLoadout = {}
            if result[1].loadout ~= nil then
                oldLoadout = json.decode(result[1].loadout)
            end
            for k,v in pairs(oldLoadout) do
                if v.permanent == true then
                    components = v.components or {}
                    table.insert(listearmeperm, v)
                end
            end
            MySQL.Async.execute("UPDATE users SET clothes=NULL,skin = NULL,inventory = NULL, job = NULL, job_grade = NULL, job2 = NULL, job2_grade = NULL, status = NULL, firstname = NULL, lastname = NULL, dateofbirth = NULL, sex = NULL, height = NULL WHERE identifier = @identifier", {["@identifier"] = targetId})
            MySQL.Async.execute("UPDATE `users` SET `accounts` = @accounts WHERE `identifier` = @identifier", {['@accounts'] = json.encode(
                {
                    {
                        money = Config.Accounts['cash'].starting or 0,
                        name = "cash"
                    },
                    {
                        money = Config.Accounts['bank'].starting or 0,
                        name = "bank"
                    },
                    {
                        money = Config.Accounts['dirtycash'].starting or 0,
                        name = "dirtycash"
                    },
                    {
                        money = 0,
                        name = "chip"
                    },
                }), ['@identifier'] = targetId}, function()  end)
            MySQL.Async.execute("UPDATE `users` SET `loadout` = @loadout WHERE `identifier` = @identifier", { ['@loadout'] = json.encode(listearmeperm), ['@identifier'] = targetId }, function()  end)
         end
	end)
end

function ReturnPlayerId(UniqueID)
	for _,p in pairs(ESX.PlayersByIdUnique) do
		if p.idunique == tonumber(UniqueID) then
			return p
		end
	end

	return false
end


function TeleportBlips()
    local entity = PlayerPedId()
    if IsPedInAnyVehicle(entity, false) then
        entity = GetVehiclePedIsUsing(entity)
    end
    local success = false
    local blipFound = false
    local blipIterator = GetBlipInfoIdIterator()
    local blip = GetFirstBlipInfoId(8)
    while DoesBlipExist(blip) do
        if GetBlipInfoIdType(blip) == 4 then
            cx, cy, cz = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ReturnResultAnyway(), Citizen.ResultAsVector()))
            blipFound = true
            break
        end
        blip = GetNextBlipInfoId(blipIterator)
        Wait(0)
    end
    if blipFound then
        local groundFound = false
        local yaw = GetEntityHeading(entity)
        for i = 0, 1000, 1 do
            SetEntityCoordsNoOffset(entity, cx, cy, ToFloat(i), false, false, false)
            SetEntityRotation(entity, 0, 0, 0, 0, 0)
            SetEntityHeading(entity, yaw)
            Wait(0)
            if GetGroundZFor_3dCoord(cx, cy, ToFloat(i), cz, false) then
                cz = ToFloat(i)
                groundFound = true
                break
            end
        end
        if not groundFound then
            cz = -300.0
        end
        success = true
    end
    if success then
        ESX.ShowNotification("~g~Vous avez été téléporter sur le marker avec succès")
        SetEntityCoordsNoOffset(entity, cx, cy, cz, false, false, true)
        if IsPedSittingInAnyVehicle(PlayerPedId()) then
            if GetPedInVehicleSeat(GetVehiclePedIsUsing(PlayerPedId()), -1) == PlayerPedId() then
                SetVehicleOnGroundProperly(GetVehiclePedIsUsing(PlayerPedId()))
            end
        end
    end
end

function CreateCamProps()
    camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(camera, -1267.07, -3025.49, -48.49)
    SetCamFov(camera, 45.0)
    AttachCamToEntity(SpawnProps, PlayerPedId())
    RenderScriptCams(1, 1, 1000, 1, 1)
end

function TeleportIPLProps()
    GetOldEntityCoord = GetEntityCoords(PlayerPedId())
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(PlayerPedId(), -1267.07, -3025.49, -48.49)
    TriggerServerEvent("cxDevTool:setPlayerToBucket")
    SetEntityVisible(PlayerPedId(), false)
    Wait(500)
    DoScreenFadeIn(1000)
    CreateCamProps()
end

function ReturnOldPosition()
    DoScreenFadeOut(1000)
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(camera, false)
    DeleteEntity(SpawnProps)
    Wait(1000)
    SetEntityCoords(PlayerPedId(), GetOldEntityCoord)
    TriggerServerEvent("cxDevTool:setPlayerToNormalBucket")
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(1000)
end