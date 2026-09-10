AdminMenu = {}
serverInteraction = false
--local NoClipSpeed = 0

function AdminMenu:checkPerm(PlayerRank, check)
    if Config.Admin.PermissionsGrade[check] ~= nil and PlayerRank >= Config.Admin.PermissionsGrade[check] then
        return true
    else
        return false
    end
end

function StaffHasPerm(perm)
    if perm == nil then return false end
    if ESX.PlayerData.group == nil then return false end
    perm = string.lower(perm)
    if Config.Admin.RolePermissions and Config.Admin.RolePermissions[ESX.PlayerData.group] then
        return Config.Admin.RolePermissions[ESX.PlayerData.group][perm] == true
    end

    local tempConfigPerm = {}
    for k,v in pairs(Config.Admin.PermissionsGrade) do tempConfigPerm[string.lower(k)] = v end

    if tempConfigPerm[perm] == nil then return false end
    if Config.GroupeGrade[ESX.PlayerData.group] == nil then return false end
    if Config.GroupeGrade[ESX.PlayerData.group].grade == nil then return false end
    if Config.GroupeGrade[ESX.PlayerData.group].grade >= tempConfigPerm[perm] then
        return true
    else
        return false
    end
end

RegisterNetEvent("null:staffroles:sync", function(data)
    if not data then return end

    Config.Admin.RankList = data.roles or Config.Admin.RankList
    Config.Admin.RolePermissions = data.rolePermissions or Config.Admin.RolePermissions
    Config.Admin.PermissionsGrade = data.permissionDefaults or Config.Admin.PermissionsGrade
    Config.Admin.RankListLabel = data.rankLabels or Config.Admin.RankListLabel
    Config.Admin.RankListGamerTag = data.rankGamertags or Config.Admin.RankListGamerTag
    Config.GroupeGrade = data.grades or Config.GroupeGrade
    Config.GroupeHighPerm = data.highPerm or Config.GroupeHighPerm
end)

function AdminMenu:strats(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function AdminMenu:rankTable(rank)
    if rank == "user" then
        return "Joueur~s~"
    else 
        local found = false
        for k,v in pairs(Config.Admin.RankList) do 
            if v.rank == rank then
                found = true
                local final = v.label
                if v.menuColor then
                    final = v.menuColor..final.."~s~"
                end
                return final
            end
        end
        if not found then
            return "~y~Rank non inscrit"
        end
    end
end

function AdminMenu:colorByState(bool)
    if bool then
        return "~r~"
    else
        return "~s~"
    end
end

function AdminMenu:staffByState(bool)
    if bool then
        return "~b~Désactiver le staff mode"
    else
        return "~b~Activer le staff mode"
    end
end

function AdminMenu:freezeByState(bool)
    if bool then
        return "Defreeze le joueur"
    else
        return "Freeze le joueur"
    end
end


function AdminMenu:freezevehicleByState(bool)
    if bool then
        return "Defreeze le véhicule"
    else
        return "Freeze le véhicule"
    end
end

function AdminMenu:tenueStaff(bool, group)
    if bool then
        --[[if group == "_dev" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueFonda.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueFonda.f)
                end
            end)
        elseif group == "superadmin" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueSuperAdmin.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueSuperAdmin.f)
                end
            end)
        elseif group == "admin" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueAdmin.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.StafftenueAdmin.f)
                end
            end)
        elseif group == "mod" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemod.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemod.f)
                end
            end)
        elseif group == "gerantlegal" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantlegal.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantlegal.f)
                end
            end)
        elseif group == "gerantillegal" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantillegal.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantillegal.f)
                end
            end)
        elseif group == "gerantstaff" then
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantstaff.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Stafftenuemodgerantstaff.f)
                end
            end)
        else]]
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if skin.sex == 0 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.m)
                elseif skin.sex == 1 then
                    TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.f)
                end
            end)
        --end
    else
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
            TriggerEvent('Null:skinchanger:loadSkin', skin)
        end)
    end
end 

function AdminMenu:tenueStaffExtra(bool)
    if bool then
        TriggerEvent("Null:skinchanger:getSkin", function(skin)
            if skin.sex == 0 then
                TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.m)
            elseif skin.sex == 1 then
                TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.f)
            end
        end)
    else
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
            if skin.sex == 0 then
                TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.m)
            elseif skin.sex == 1 then
                TriggerEvent("Null:skinchanger:loadClothes", skin, Config.Admin.StaffModeClothes.f)
            end
        end)
    end
end

local uniqueid = 0
local gamerTags = {}

function AdminMenu:showNames(bool, group)
    isNameShown = bool
    if isNameShown then
        CreateThread(function()
            while isNameShown do
                local plyPed = PlayerPedId()
                for _, player in pairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(player)
                    -- if ped ~= plyPed then
                    if #(GetEntityCoords(plyPed, false) - GetEntityCoords(ped, false)) < 5000.0 then
                        
                        ESX.TriggerServerCallback('null:GetIDUnique', function(IDUnique) 
                            uniqueid = IDUnique 
                        end, player)

                        gamerTags[player] = CreateFakeMpGamerTag(ped, ("[T %s | U %s] - %s"):format(GetPlayerServerId(player), uniqueid ,GetPlayerName(player), false, false, '', 0, 255, 0, 0))
                        SetMpGamerTagAlpha(gamerTags[player], 0, 255)
                        SetMpGamerTagAlpha(gamerTags[player], 2, 255)
                        SetMpGamerTagAlpha(gamerTags[player], 4, 255)
                        SetMpGamerTagAlpha(gamerTags[player], 7, 255)
                        SetMpGamerTagVisibility(gamerTags[player], 0, true)
                        SetMpGamerTagVisibility(gamerTags[player], 2, true)
                        SetMpGamerTagVisibility(gamerTags[player], 4, NetworkIsPlayerTalking(player))
                        --SetMpGamerTagVisibility(gamerTags[player], 7, false)

                        ESX.TriggerServerCallback('AdminMenu:getGroupForNotif', function(group)
                            if group == "_dev" then
                                SetMpGamerTagVisibility(gamerTags[player], 7, true)
                                SetMpGamerTagAlpha(gamerTags[player], 7, 255) -- mettre l'opac du WANTED_STARS a 255
                                SetMpGamerTagColour(gamerTags[player], 0, 6) -- mettre la couleur du GAME_NAME en rouge
                                SetMpGamerTagColour(gamerTags[player], 7, 12)
                            elseif group ~= "user" then
                                --SetMpGamerTagVisibility(gamerTags[player], 7, true)
                                --SetMpGamerTagAlpha(gamerTags[player], 7, 255) -- mettre l'opac du WANTED_STARS a 255
                                SetMpGamerTagColour(gamerTags[player], 0, 9) -- mettre la couleur du GAME_NAME en rouge
                                --SetMpGamerTagColour(gamerTags[player], 7, 6)
                            elseif NetworkIsPlayerTalking(player) then
                                SetMpGamerTagHealthBarColour(gamerTags[player], 211)
                                SetMpGamerTagColour(gamerTags[player], 4, 211)
                                SetMpGamerTagColour(gamerTags[player], 0, 211)
                            else
                                SetMpGamerTagHealthBarColour(gamerTags[player], 0)
                                SetMpGamerTagColour(gamerTags[player], 4, 0)
                                SetMpGamerTagColour(gamerTags[player], 0, 0)
                            end
                        end)
                        if DecorExistOn(ped, "staffl") then
                            SetMpGamerTagWantedLevel(ped, DecorGetInt(ped, "staffl"))
                        end
                        if mpDebugMode then
                            print(json.encode(DecorExistOn(ped, "staffl")).." - "..json.encode(DecorGetInt(ped, "staffl")))
                        end
                    else
                        RemoveMpGamerTag(gamerTags[player])
                        gamerTags[player] = nil
                    end
                    -- end
                end
                Wait(100)
            end
            for k,v in pairs(gamerTags) do
                RemoveMpGamerTag(v)
            end
            gamerTags = {}
        end)
    end
end


function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()
    local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
    local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

    if len ~= 0 then
        coords = coords / len
    end

    return coords
end

function AdminMenu:playerBlip(bool)
        if bool then
            while true do
                Wait(1)
                for _, player in pairs(GetActivePlayers()) do
                    local found = false
                    --if player ~= PlayerId() then
                        local ped = GetPlayerPed(player)
                        local blip = GetBlipFromEntity( ped )
                        if not DoesBlipExist( blip ) then
                            blip = AddBlipForEntity(ped)
                            SetBlipCategory(blip, 7)
                            SetBlipScale( blip,  0.85 )
                            ShowHeadingIndicatorOnBlip(blip, true)
                            SetBlipSprite(blip, 1)
                            SetBlipColour(blip, 0)
                        end

                        SetBlipNameToPlayerName(blip, player)

                        local veh = GetVehiclePedIsIn(ped, false)
                        local blipSprite = GetBlipSprite(blip)

                        if IsEntityDead(ped) then
                            if blipSprite ~= 303 then
                                SetBlipSprite( blip, 303 )
                                SetBlipColour(blip, 1)
                                ShowHeadingIndicatorOnBlip( blip, false )
                            end
                        elseif veh ~= nil then
                            if IsPedInAnyBoat( ped ) then
                                if blipSprite ~= 427 then
                                    SetBlipSprite( blip, 427 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            elseif IsPedInAnyHeli( ped ) then
                                if blipSprite ~= 43 then
                                    SetBlipSprite( blip, 43 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            elseif IsPedInAnyPlane( ped ) then
                                if blipSprite ~= 423 then
                                    SetBlipSprite( blip, 423 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            elseif IsPedInAnyPoliceVehicle( ped ) then
                                if blipSprite ~= 137 then
                                    SetBlipSprite( blip, 137 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            elseif IsPedInAnySub( ped ) then
                                if blipSprite ~= 308 then
                                    SetBlipSprite( blip, 308 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            elseif IsPedInAnyVehicle( ped ) then
                                if blipSprite ~= 225 then
                                    SetBlipSprite( blip, 225 )
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, false )
                                end
                            else
                                if blipSprite ~= 1 then
                                    SetBlipSprite(blip, 1)
                                    SetBlipColour(blip, 0)
                                    ShowHeadingIndicatorOnBlip( blip, true )
                                end
                            end
                        else
                            if blipSprite ~= 1 then
                                SetBlipSprite( blip, 1 )
                                SetBlipColour(blip, 0)
                                ShowHeadingIndicatorOnBlip( blip, true )
                            end
                        end
                        if veh then
                            SetBlipRotation( blip, math.ceil( GetEntityHeading( veh ) ) )
                        else
                            SetBlipRotation( blip, math.ceil( GetEntityHeading( ped ) ) )
                        end
                    --end
                end
            end
        else
            for _, player in pairs(GetActivePlayers()) do
                local blip = GetBlipFromEntity( GetPlayerPed(player) )
                if blip ~= nil then
                    RemoveBlip(blip)
                end
            end
        end
end


function AdminMenu:CreatePlate()
    local generatedPlate
    local doBreak = false

    generatedPlate = string.upper(GetRandomLetter(4) .. GetRandomNumber(4))

    return generatedPlate
end

local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

function AdminMenu:Invincible(bool)
    if bool then
        while true do
            SetEntityInvincible(PlayerPedId(), true)
            Wait(1)
        end
    else
        SetEntityInvincible(PlayerPedId(), false)
    end
end

function AdminMenu:setCoords(bool)
    CreateThread(function()
        if bool then
            while true do
                local pedPos = GetEntityCoords(PlayerPedId())
                local h = GetEntityHeading(PlayerPedId())
                Visual.Subtitle("~r~X: ~s~"..pedPos.x.."~o~ Y: ~s~"..pedPos.y..ESX.Config("serverColor").." Z:"..pedPos.z)
                Wait(1)
            end
        end
    end)
end


function generateTakenBy(reportID)
    if localReportsTable[reportID].taken then
        return "~s~ | Pris par : ~o~" .. localReportsTable[reportID].takenBy
    else
        return ""
    end
end

function getIsTakenDisplay(bool)
    if bool then
        return "~g~[PRIS EN CHARGE]"
    else
        return "~r~[EN ATTENTE]"
    end
end

function ClosetVehWithDisplay()
    local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(GetPlayerPed(-1)), nil)
    local vCoords = GetEntityCoords(veh)
    DrawMarker(2, vCoords.x, vCoords.y, vCoords.z + 1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 170, 0, 1, 2, 0, nil, nil, 0)
end

localReportsTable, reportCount, take = {},0,0

RegisterNetEvent("AdminMenu:cbReportTable")
AddEventHandler("AdminMenu:cbReportTable", function(table)
    reportCount = 0
    take = 0
    for source,report in pairs(table) do
        reportCount = reportCount + 1
        if report.taken then take = take + 1 end
    end
    localReportsTable = table
end)

function AdminMenu:input(TextEntry)
    local input = nil
    if isAdvanced then
        input = lib.inputDialog(TextEntry, table)
    else
        input = lib.inputDialog(TextEntry, {TextEntry})
    end

	if input == nil or input[1] == nil or #input[1] == 0 or input[1] == "" then
		return nil
	end

	return input[1]
end

function AdminMenu:input2(TextEntry, ExampleText, MaxStringLenght, isValueInt)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        if isValueInt then
            local isNumber = tonumber(result)
            if isNumber then
                return result
            else
                return nil
            end
        end

        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

RegisterCommand("staffchest", function(source, args, rawCommand)
	local src = source
    ESX.TriggerServerCallback('AdminMenu:getGroupForNotif', function(group)
        if (ESX.HasPermissions("coffre_staff")) then 
            ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                if data then
                    local inventory = data
                    inventory.weight = 0
                    inventory.id = id
                    inventory.maxWeight = -1
                    inventory.type = "DEBUG"
                    TriggerEvent("inventory:openTarget",inventory)
                end
            end, "staffchest")
        end
    end)
end)

RegisterCommand("itemlist", function(source, args, rawCommand)
    if ESX.HasPermissions("liste_items_armes") then 
        ESX.TriggerServerCallback('null:getCoffre2', function(data, id)
            if data then
                local inventory = data
                inventory.weight = 0
                inventory.id = id
                inventory.maxWeight = -1
                inventory.type = "DEBUG"
                TriggerEvent("inventory:openTarget",inventory)
            end
        end)
    end
end)
