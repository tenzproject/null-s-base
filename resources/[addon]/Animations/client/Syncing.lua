local isRequestAnim = false
local requestedemote = ''
local targetPlayerId = ''

if Config.Animations.SharedEmotesEnabled then
    RegisterCommand('nearby', function(source, args, raw)
        if IsPedInAnyVehicle(PlayerPedId(), true) then
            return EmoteChatMessage(Translate('not_in_a_vehicle'))
        end

        if #args > 0 then
            local emotename = string.lower(args[1])
            target, distance = GetClosestPlayer()
            if (distance ~= -1 and distance < 3) then
                if RP.Shared[emotename] ~= nil then
                    dict, anim, ename = table.unpack(RP.Shared[emotename])
                    
                    local result = null.fct.confirm(Translate('are_you_sure_you_want_to_send_emote_to') .. " " .. GetPlayerName(target) .. " ~w~(~g~" .. ename .. "~w~)?")

                    if result then
                        TriggerServerEvent("ServerEmoteRequest", GetPlayerServerId(target), emotename)
                        SimpleNotify(Translate('sentrequestto') .. GetPlayerName(target) .. " ~w~(~g~" .. ename .. "~w~)")
                    else
                        SimpleNotify(Translate('emote_request_cancelled'))
                    end
                else
                    EmoteChatMessage("'" .. emotename .. "' " .. Translate('notvalidsharedemote') .. "")
                end
            else
                SimpleNotify(Translate('nobodyclose'))
            end
        else
            NearbysOnCommand()
        end
    end, false)
end


RegisterNetEvent("SyncPlayEmote", function(emote, player)
    EmoteCancel()
    Wait(300)
    targetPlayerId = player

    if IsPedInAnyVehicle(GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer()), true) then
        return EmoteChatMessage(Translate('not_in_a_vehicle'))
    end

    if RP.Shared[emote] ~= nil then
        if RP.Shared[emote].AnimationOptions and RP.Shared[emote].AnimationOptions.Attachto then
            local targetEmote = RP.Shared[emote][4]
            if not targetEmote or not RP.Shared[targetEmote] or not RP.Shared[targetEmote].AnimationOptions or not RP.Shared[targetEmote].AnimationOptions.Attachto then
                local plyServerId = GetPlayerFromServerId(player)
                local ply = PlayerPedId()
                local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())
                local bone = RP.Shared[emote].AnimationOptions.bone or -1
                local xPos = RP.Shared[emote].AnimationOptions.xPos or 0.0
                local yPos = RP.Shared[emote].AnimationOptions.yPos or 0.0
                local zPos = RP.Shared[emote].AnimationOptions.zPos or 0.0
                local xRot = RP.Shared[emote].AnimationOptions.xRot or 0.0
                local yRot = RP.Shared[emote].AnimationOptions.yRot or 0.0
                local zRot = RP.Shared[emote].AnimationOptions.zRot or 0.0
                AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot, false, false, false, true, 1, true)
            end
        end

        OnEmotePlay(RP.Shared[emote], emote)
        return
    elseif RP.Dances[emote] ~= nil then
        OnEmotePlay(RP.Dances[emote], emote)
        return
    else
        DebugPrint("SyncPlayEmote : Emote not found")
    end
end)

RegisterNetEvent("SyncPlayEmoteSource", function(emote, player)
    local ply = PlayerPedId()
    local plyServerId = GetPlayerFromServerId(player)
    local pedInFront = GetPlayerPed(plyServerId ~= 0 and plyServerId or GetClosestPlayer())

    if IsPedInAnyVehicle(ply, true) or IsPedInAnyVehicle(pedInFront, true) then
        return EmoteChatMessage(Translate('not_in_a_vehicle'))
    end

    local SyncOffsetFront = 1.0
    local SyncOffsetSide = 0.0
    local SyncOffsetHeight = 0.0
    local SyncOffsetHeading = 180.1

    local AnimationOptions = RP.Shared[emote] and RP.Shared[emote].AnimationOptions
    if AnimationOptions then
        if AnimationOptions.SyncOffsetFront then SyncOffsetFront = AnimationOptions.SyncOffsetFront + 0.0 end
        if AnimationOptions.SyncOffsetSide then SyncOffsetSide = AnimationOptions.SyncOffsetSide + 0.0 end
        if AnimationOptions.SyncOffsetHeight then SyncOffsetHeight = AnimationOptions.SyncOffsetHeight + 0.0 end
        if AnimationOptions.SyncOffsetHeading then SyncOffsetHeading = AnimationOptions.SyncOffsetHeading + 0.0 end

        if (AnimationOptions.Attachto) then
            local bone = AnimationOptions.bone or -1
            local xPos = AnimationOptions.xPos or 0.0
            local yPos = AnimationOptions.yPos or 0.0
            local zPos = AnimationOptions.zPos or 0.0
            local xRot = AnimationOptions.xRot or 0.0
            local yRot = AnimationOptions.yRot or 0.0
            local zRot = AnimationOptions.zRot or 0.0
            AttachEntityToEntity(ply, pedInFront, GetPedBoneIndex(pedInFront, bone), xPos, yPos, zPos, xRot, yRot, zRot, false, false, false, true, 1, true)
        end
    end
    local coords = GetOffsetFromEntityInWorldCoords(pedInFront, SyncOffsetSide, SyncOffsetFront, SyncOffsetHeight)
    local heading = GetEntityHeading(pedInFront)
    SetEntityHeading(ply, heading - SyncOffsetHeading)
    SetEntityCoordsNoOffset(ply, coords.x, coords.y, coords.z, 0)
    EmoteCancel()
    Wait(300)
    targetPlayerId = player
    if RP.Shared[emote] ~= nil then
        OnEmotePlay(RP.Shared[emote], emote)
        return
    elseif RP.Dances[emote] ~= nil then
        OnEmotePlay(RP.Dances[emote], emote)
        return
    end
end)

RegisterNetEvent("SyncCancelEmote", function(player)
    if targetPlayerId and targetPlayerId == player then
        targetPlayerId = nil
        EmoteCancel()
    end
end)

function CancelSharedEmote(ply)
    if targetPlayerId then
        TriggerServerEvent("ServerEmoteCancel", targetPlayerId)
        targetPlayerId = nil
    end
end

RegisterNetEvent("ClientEmoteRequestReceive", function(emotename, etype, target)
    isRequestAnim = true
    requestedemote = emotename

    if etype == 'Dances' then
        _, _, remote = table.unpack(RP.Dances[requestedemote])
    else
        _, _, remote = table.unpack(RP.Shared[requestedemote])
    end

    PlaySound(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 0, 0, 1)
    SimpleNotify(Translate('doyouwanna') .. remote .. "~w~)")
    local timer = 10 * 1000
    while isRequestAnim do
        Wait(5)
        timer = timer - 5
        if timer <= 0 then
            isRequestAnim = false
            SimpleNotify(Translate('refuseemote'))
        end

        if IsControlJustPressed(1, 246) then
            isRequestAnim = false
            if RP.Shared[requestedemote] ~= nil then
                _, _, _, otheremote = table.unpack(RP.Shared[requestedemote])
            elseif RP.Dances[requestedemote] ~= nil then
                _, _, _, otheremote = table.unpack(RP.Dances[requestedemote])
            end
            if otheremote == nil then otheremote = requestedemote end
            TriggerServerEvent("ServerValidEmote", target, requestedemote, otheremote)
        elseif IsControlJustPressed(1, 182) then
            isRequestAnim = false
            SimpleNotify(Translate('refuseemote'))
        end
    end
end)