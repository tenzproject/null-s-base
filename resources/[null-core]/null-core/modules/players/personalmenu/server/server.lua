local AdminsDontWantInfiniteWeight = {}

function getMaximumGrade(jobname)
    local queryDone, queryResult = false, nil

    MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
        ['@jobname'] = jobname
    }, function(result)
        queryDone, queryResult = true, result
    end)

    while not queryDone do
        Wait(10)
    end

    if queryResult[1] then
        return queryResult[1].grade
    end

    return nil
end

function getAdminCommand(name)
    for i = 1, #Config.Admin, 1 do
        if Config.Admin[i].name == name then
            return i
        end
    end

    return false
end

function isAuthorized(index, group)
    for i = 1, #Config.Admin[index].groups, 1 do
        if Config.Admin[index].groups[i] == group then
            return true
        end
    end

    return false
end

function isEmployed(jobName)
    return (jobName ~= "unemployed" and jobName ~= "unemployed2")
end


ESX.RegisterServerCallback('Null:personalmenu:Admin_getUsergroup', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local plyGroup = xPlayer.getGroup()

    if plyGroup ~= nil then
        cb(plyGroup)
    else
        cb('user')
    end
end)

ESX.RegisterServerCallback('Null:getFactures', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local bills = {}

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		for i = 1, #result, 1 do
			table.insert(bills, {
				id = result[i].id,
				label = result[i].label,
				amount = result[i].amount,
                date = result[i].date,
			})
		end

		cb(bills)
	end)
end)

RegisterNetEvent('Null:personalmenu:Boss_promouvoirplayer', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if (targetXPlayer.job.grade == tonumber(getMaximumGrade(sourceXPlayer.job.name)) - 1) then
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous devez demander une autorisation du ~r~Gouvernement~s~.')
    else
        if source ~= target and sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
            targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) + 1)

            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~promu ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~promu par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_destituerplayer', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)
			
    if (targetXPlayer.job.grade == 0) then
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous ne pouvez pas ~r~rétrograder~s~ davantage.')
    else
        if source ~= target and sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
            targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) - 1)

            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~rétrogradé ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~r~rétrogradé par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_recruterplayer', function(target, job)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if source ~= target and sourceXPlayer.job.grade_name == 'boss' or sourceXPlayer.job.grade_name == 'responsable' or sourceXPlayer.job.grade_name == 'captain' or sourceXPlayer.job.grade_name == 'lieutenant' then
        if not isEmployed(targetXPlayer.job.name) then
            targetXPlayer.setJob(sourceXPlayer.job.name, 0)
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~recruté ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous ne pouvez pas recruter quelqu\'un déjà embauché.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_virerplayer', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)
			
    if source ~= target and sourceXPlayer.job.grade_name == 'boss' or sourceXPlayer.job.grade_name == 'captain' or sourceXPlayer.job.grade_name == 'lieutenant' or sourceXPlayer.job.grade_name == 'responsable' and targetXPlayer.job.grade_name ~= 'boss' and targetXPlayer.job.grade_name ~= 'responsable' and targetXPlayer.job.grade_name ~= 'captain' and targetXPlayer.job.grade_name ~= 'lieutenant'  then
        if source ~= target and sourceXPlayer.job.name == targetXPlayer.job.name then
        targetXPlayer.setJob('unemployed', 0)
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~viré ' .. targetXPlayer.name .. '~s~.')
        TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~s~.')
        else
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    else
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
    end
end)





RegisterNetEvent('Null:personalmenu:Boss_promouvoirplayer2', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)
    if (targetXPlayer.job2.grade == tonumber(getMaximumGrade(sourceXPlayer.job2.name)) - 1) then
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous devez demander une autorisation du ~r~Gouvernement~s~.')
    else
        if source ~= target and sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
            targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) + 1)

            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~promu ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~promu par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_destituerplayer2', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if (targetXPlayer.job2.grade == 0) then
        TriggerClientEvent('esx:showNotification', _source, 'Vous ne pouvez pas ~r~rétrograder~s~ davantage.')
    else
        if ssource ~= target and sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
            targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) - 1)

            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~rétrogradé ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~r~rétrogradé par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_recruterplayer2', function(target, job2)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)
			
    if source ~= target and sourceXPlayer.job2.grade_name == 'boss' or sourceXPlayer.job2.grade_name == 'gerant' then
        if not isEmployed(targetXPlayer.job2.name) then
            targetXPlayer.setJob2(sourceXPlayer.job2.name, 0)
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~recruté ' .. targetXPlayer.name .. '~s~.')
            TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~s~.')
        else
            TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous ne pouvez pas recruter quelqu\'un déjà embauché.')
        end
    end
end)

RegisterNetEvent('Null:personalmenu:Boss_virerplayer2', function(target)
    if target == -1 then return end
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if source ~= target and sourceXPlayer.job2.grade_name == 'boss' or sourceXPlayer.job2.grade_name == 'gerant' and targetXPlayer.job2.grade_name ~= 'boss' and targetXPlayer.job2.grade_name ~= 'gerant' then
        if source ~= target and sourceXPlayer.job2.name == targetXPlayer.job2.name then
        targetXPlayer.setJob2('unemployed2', 0)
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~viré ' .. targetXPlayer.name .. '~s~.')
        TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~s~.')
        else
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
        end
    else
        TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~s~.')
    end
end)

RegisterNetEvent('Admin:ActionTeleport', function(action, id)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer.getGroup() ~= "user" then 
        if action == "teleportto" then 
            local ped = GetPlayerPed(id)
            local coord = GetEntityCoords(ped)
            TriggerClientEvent("Admin:ActionTeleport", _source, "teleportto", coord)
        elseif action == "teleportme" then 
            local ped = GetPlayerPed(_source)
            local coord = GetEntityCoords(ped)
            TriggerClientEvent("Admin:ActionTeleport", id, "teleportme", coord)
        elseif action == "teleportpc" then
            local coord = vector3(215.76, -810.12, 30.73)
            TriggerClientEvent("Admin:ActionTeleport", id, "teleportpc", coord)
        end
    else
        TriggerEvent("BanSql:ICheatServer", source, "Le Cheat n'est pas autorisé sur notre serveur [téléportation]")
    end
end)

RegisterNetEvent('Null:leavejob',function(type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if type == "job" then
        if xPlayer.getJob().name == "unemployed" then return end
        xPlayer.setJob("unemployed", 0)
    elseif type == "job2" then
        if xPlayer.getJob2().name == "unemployed2" then return end
        xPlayer.setJob2("unemployed2", 0)
    end
end)
 

RegisterNetEvent('Null:ChangeWeightInventory',function(sex, type, weight)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (xPlayer) then
        if xPlayer.getPermission("infinite_max_weight") and AdminsDontWantInfiniteWeight[source] == nil then
            xPlayer.setMaxWeight(99999)
        else
            if type == 'vnobag' then 
                if GetVIP(xPlayer.identifier) then 
                    local maxWeight = GetVIPMaxWeight(xPlayer.identifier)
                    if maxWeight ~= xPlayer.maxWeight then
                        xPlayer.setMaxWeight(maxWeight)
                        xPlayer.showNotification('Le poids de votre inventaire a été changé à '..maxWeight..'kg.')
                    end
                elseif xPlayer.maxWeight ~= Config.MaxWeight then
                    xPlayer.setMaxWeight(Config.MaxWeight)
                    xPlayer.showNotification('Le poids de votre inventaire a été changé à '..Config.MaxWeight..'kg.')
                end
            elseif type == 'vbag' then 
                -- Plus de systeme de sac qui modifie le poid max
                -- cheateur = true
                -- for k,v in pairs(Config.ListBags[sex]) do
                --     if v.weight == weight then
                --         cheateur = false
                --     end
                -- end
                -- if cheateur then
                --     ExecuteCommand("ban "..source.." 0 Tentative de triche personalmenu (0)")
                -- end
                -- if GetVIP(xPlayer.identifier) then 
                --     xPlayer.setMaxWeight(weight)
                --     xPlayer.showNotification('Le poids de votre inventaire a été changé à '..weight..'kg.')
                -- else
                --     xPlayer.setMaxWeight(weight)
                --     xPlayer.showNotification('Le poids de votre inventaire a été changé à '..weight..'.')
                -- end
            else
                ExecuteCommand("ban " .. source .. " 0 Tentative de triche personalmenu (1)")
            end
        end
    end
end)
 
local isHandsup = {}
RegisterNetEvent('Null:handsup', function(value)
    if not isHandsup[source] then 
        isHandsup[source] = value
    else 
        isHandsup[source] = value
    end
end)

RegisterNetEvent("null:admin:desactivateInfiteMaxWeight", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("infinite_max_weight") then return end
    if AdminsDontWantInfiniteWeight[source] then
        AdminsDontWantInfiniteWeight[source] = nil
    else
        AdminsDontWantInfiniteWeight[source] = os.time()
    end
end)

ESX.RegisterServerCallback('Null:personalmenu:getHandsUp', function(source, cb, target)
    if isHandsup[target] then 
        cb(isHandsup[target])
    else
        isHandsup[target] = false
        cb(isHandsup[target])
    end
end)


--[[RegisterNetEvent('Null:Annonce', function(annonce)
	local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.job.grade_name == 'boss' then
        TriggerClientEvent('esx:showNotification', -1, annonce)
    end
end)]]