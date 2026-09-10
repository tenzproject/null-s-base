local LesterZone = nil
local isPolice = false
local isSwat = false
local HaveReport = false


function MenuVente()
	TriggerServerEvent("null:lester:isswat")
	local vente = RageUI.CreateMenu("", "Lester")
	local braquagelist = RageUI.CreateSubMenu(vente,"", "Lester")
	RageUI.Visible(vente, not RageUI.Visible(vente))

	while vente do
		Citizen.Wait(0)
			RageUI.IsVisible(vente, function()
				if isSwat then
					RageUI.Separator("Désoler, je dois y aller.")
				else
					RageUI.Button('Vendre Bijoux', nil, {}, true, {
						onSelected = function() 
							local nbr = null.fct.input('Combien souhaitez vous vendre ? ', false, 9000000, "text")
							TriggerServerEvent('lester:vendeur', tonumber(nbr)) 
						end
					})
					RageUI.Button('Contacter un Hacker', nil, {}, true, {
						onSelected = function() 
							ESX.TriggerServerCallback('null:lester:phone', function(good)
								
							end)
						end
					})
				end
			end)
		if not RageUI.Visible(vente) and not RageUI.Visible(braquagelist) then
			vente = RMenu:DeleteType('vente', true)
		end
	end
end

local IsInside = false
Citizen.CreateThread(function ()
	ESX.addBlips({
        name = 'lester_blip',
        label = 'Lester',
        category = nil,
        position = vector3(706.5475, -966.1048, 30.41285),
        sprite = 77,
        display = 4,
        scale = 0.5,
        color = 0
    })
	TriggerServerEvent("null:lester:isswat")
	Wait(3000)
	LesterZone = PolyZone:Create({vec3(785.245178, -1000.775696, 26.134623),vec3(782.681458, -922.577148, 25.502480),vec3(681.193237, -930.628418, 22.574308),vec3(675.058533, -989.267517, 22.384171)}, {
		name = "lester_house"
	})
	while ESX.PlayerData.job == nil do Wait(10) end
	if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
		LesterZone:onPlayerInOut(function(isPointInside, point)
			if isPointInside and not IsInside then
				IsInside = true
				InitLesterSwat()
			else
				IsInside = false
			end
		end)

		isPolice = true
	end
end)

function InitLesterSwat()
	if not isPolice then return end
	if HaveReport then return end
	TriggerServerEvent("null:lester:swat")
	HaveReport = true
end


RegisterNetEvent('null:isswat:client')
AddEventHandler('null:isswat:client', function(bool)
	isSwat = bool
	if isSwat then
		ESX.removeBlip("lester_blip")
	end
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
		isPolice = true
	else
		isPolice = false
	end
end)


local GroupLester = CreateGroup()

function InitPedLester(ped, Leader, CoLeader)
	SetBlockingOfNonTemporaryEvents(ped, false)
	SetPedSeeingRange(ped, 0)
	SetPedFleeAttributes(ped, 0, 0)
	SetPedArmour(ped, 200)
	DisablePedPainAudio(storePed, true)
	TaskStartScenarioInPlace(storePed, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
	SetPedSuffersCriticalHits(ped, false)
	SetPedMaxHealth(ped, 200)
	SetPedDiesWhenInjured(ped, true)
	--SetPedAsEnemy(ped, true)
	
	if Leader or CoLeader then
		if Leader then
			SetPedAsGroupLeader(ped, GroupLester)
		else
			SetPedAsGroupMember(ped, GroupLester)
		end
		GiveWeaponToPed(ped, "WEAPON_PISTOL_MK2", 500, false, false)
		GiveWeaponToPed(ped, "WEAPON_CARBINERIFLE_MK2", 500, false, false)
		SetCurrentPedWeapon(ped, "WEAPON_PISTOL_MK2", false)
		SetPedAmmo(ped, "WEAPON_PISTOL_MK2", 500)
	else
		SetPedAsGroupMember(ped, GroupLester)
		GiveWeaponToPed(ped, "WEAPON_PISTOL_MK2", 500, false, false)
		GiveWeaponToPed(ped, "WEAPON_CARBINERIFLE_MK2", 500, false, false)
		SetCurrentPedWeapon(ped, "WEAPON_CARBINERIFLE_MK2", false)
		SetPedAmmo(ped, "WEAPON_CARBINERIFLE_MK2", 500)
	end
	SetPedNeverLeavesGroup(ped, true)
end

RegisterNetEvent('null:swat:client')
AddEventHandler('null:swat:client', function()
	ESX.Streaming.RequestModel("cs_lestercrest")
	ESX.Streaming.RequestModel("cs_siemonyetarian")
	ESX.Streaming.RequestModel("cs_terry")
	ESX.Streaming.RequestModel("cs_joeminuteman")
	ESX.Streaming.RequestModel("cs_johnnyklebitz")
	
	local Lester = CreatePed(4, "cs_lestercrest", 707.513550, -965.447510, 30.413174, 302.48529052734, false, false)
	InitPedLester(Lester, true)
	local Protector1 = CreatePed(4, "cs_siemonyetarian", 712.89978027344, -971.13348388672, 30.395332336426, 302.48529052734, false, false)
	InitPedLester(Protector1, false, true)
	local Protector2 = CreatePed(4, "cs_terry", 715.69873046875, -962.06591796875, 30.395332336426, false, false)
	InitPedLester(Protector2)
	local Protector3 = CreatePed(4, "cs_joeminuteman", 718.361328125, -973.21258544922, 30.395332336426, false, false)
	InitPedLester(Protector3)
	local Protector4 = CreatePed(4, "cs_johnnyklebitz", 707.61517333984, -960.88751220703, 30.395332336426, false, false)
	InitPedLester(Protector4)

	if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
		ESX.ShowNotification("Lester vous a vu, protégez-vous !")
	end
end)