local currentJobs = {}

RegisterServerEvent("Null:jobs:startActivity", function()
	local playerSrc = source
	if (not playerSrc) then return end

	local playerSelected = ESX.GetPlayerFromId(playerSrc)
	if (not playerSelected) then return end

	if (not currentJobs[playerSrc]) then
		currentJobs[playerSrc] = true
	end
end)

AddEventHandler("playerDropped", function()
	currentJobs[source] = nil
end)

local MAX_FREEJOB_PAYOUT = 50000

RegisterServerEvent("Null:jobs:verifyJob", function(activity, money)
	local playerSrc = source
	if (not playerSrc) then return end

	local playerSelected = ESX.GetPlayerFromId(playerSrc)
	if (not playerSelected) then return end

	if (not currentJobs[playerSrc]) then return end

	money = tonumber(money)
	if (not money) or money <= 0 then return end

	local currentZone = nil
    if activity == 2 then currentZone = vector3(Config.FreeJobs.Entrepot.PedCoords.x, Config.FreeJobs.Entrepot.PedCoords.y, Config.FreeJobs.Entrepot.PedCoords.z) end  -- entrepot
    if activity == 4 then currentZone = vector3(Config.FreeJobs.Pool.PedCoords.x, Config.FreeJobs.Pool.PedCoords.y, Config.FreeJobs.Pool.PedCoords.z) end    -- pool
    if activity == 5 then currentZone = vector3(Config.FreeJobs.Bucheron.PedCoords.x, Config.FreeJobs.Bucheron.PedCoords.y, Config.FreeJobs.Bucheron.PedCoords.z) end    -- bucheron

	if (not currentZone) then return end

	if #(GetEntityCoords(GetPlayerPed(playerSrc)) - currentZone) < 40 then
		currentJobs[playerSrc] = nil
		money = math.min(math.floor(money), MAX_FREEJOB_PAYOUT)
		playerSelected.addAccountMoney("cash", money)
		TriggerClientEvent('esx:showNotification', playerSrc, "Votre travail vous a permis de gagner ~g~"..money.. " $ ~s~en liquide")
	else
		ExecuteCommand("ban " .. playerSrc .. " 0 Tentative de triche jobs (0)")
	end
end)