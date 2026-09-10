-- ============================================================================
-- NullCore Weapon Ammo System (v2 - metadata persistence)
--
-- Principe:
--   - 1 item ammo_* dans l'inventaire = 1 chargeur plein
--   - weapon.metadata.ammo = nombre de balles actuelles dans le clip (persiste)
--   - Sur equip: restaure le clip depuis metadata (AUCUNE conso)
--   - Sur tir premier (clip=0) OU R: consume 1 item, charge 1 clip plein
--   - Reload prematuré = perte des balles restantes
--   - Sur unequip/switch: sauvegarde le clip actuel dans metadata
-- ============================================================================

local AMMO_DEBUG = true
local function AmmoLog(...)
	if AMMO_DEBUG then
		null.DebugPrint("^3[AMMO]^7", ...)
	end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function GetClipAmmo(ped, weapon)
	local ok, ammo = GetAmmoInClip(ped, weapon)
	if ok then return ammo end
	return 0
end

local function GetMagSize(ammoType)
	return Config.MagazineSize[ammoType] or Config.MagazineSize['default'] or 30
end

-- Set the logical clip ammo AND maintain a virtual reserve so GTA's reload works.
-- If hasMags = true, keeps reserve = magSize so GTA can play reload animation.
local function SetClipAmmo(ped, weapon, clip, magSize, hasMags)
	clip = math.max(0, math.floor(clip or 0))
	SetAmmoInClip(ped, weapon, clip)
	if hasMags and magSize then
		SetPedAmmo(ped, weapon, clip + magSize)
	else
		SetPedAmmo(ped, weapon, clip)
	end
end

-- Inventory magazines available for given ammoType
local function GetMagsAvailable(ammoType)
	local itemName = Config.AmmoType[ammoType]
	if not itemName then return 0, nil end
	local item = ESX.GetInventoryItem(itemName)
	return (item and item.count) or 0, item
end

-- Consume 1 magazine item + durability
local function ConsumeOneMag(weaponData, ammoType)
	local count, ammoItem = GetMagsAvailable(ammoType)
	if ammoItem and count > 0 then
		AmmoLog("^1MAG^7 consume 1x", ammoItem.name, "(had:", count, ")")
		TriggerServerEvent('null:ammoDelete', weaponData.index, ammoItem, 1)
	end
	if Config.AmmunationShop.repairSysteme and weaponData.data then
		local magSize = GetMagSize(ammoType)
		local durVal = (Config.AmmoTypeDurability[ammoType] or Config.AmmoTypeDurability['default'] or 0) * magSize
		if durVal > 0 then
			TriggerServerEvent("null:durability:add", weaponData.data.name, durVal)
		end
	end
end

-- Persist current clip ammo to weapon metadata (server-side)
local savePending = {}  -- throttle per-weapon
local function SaveClipAmmo(weaponName, clipAmmo, force)
	if not weaponName then return end
	local now = GetGameTimer()
	if not force and savePending[weaponName] and now - savePending[weaponName] < 1500 then
		return
	end
	savePending[weaponName] = now
	TriggerServerEvent("null:weapon:saveAmmo", weaponName, clipAmmo)
end

-- Read stored clip ammo from weapon metadata (returns nil if none)
local function GetStoredClipAmmo(weaponName)
	local w = ESX.GetMyWeapon(weaponName)
	if w and w.metadata and type(w.metadata.ammo) == 'number' then
		return w.metadata.ammo
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Main loop
-- ---------------------------------------------------------------------------

CreateThread(LPH_NO_VIRTUALIZE(function()
	null.fct.waitPlayerLoaded()
	Wait(3000)

	local currentWeaponData = nil   -- { data = weaponCfg, index = idx }
	local currentWeaponName = nil
	local currentAmmoType = nil
	local currentMagSize = 30
	local lastClipAmmo = 0
	local lastTrackedWeapon = nil
	local lastDurabilityWarn = 0
	local lastSaveClip = -1

	while true do
		if not NullGF.InZone then
			local ped = PlayerState.ped
			local selectedWeapon = PlayerState.weapon

			-- -----------------------------------------------------------------
			-- Weapon change detection
			-- -----------------------------------------------------------------
			if selectedWeapon ~= lastTrackedWeapon then
				-- Save old weapon clip ammo BEFORE switching state
				if currentWeaponName and currentAmmoType and currentAmmoType ~= 'infinite' then
					SaveClipAmmo(currentWeaponName, lastClipAmmo, true)
				end

				lastTrackedWeapon = selectedWeapon
				currentWeaponData = nil
				currentWeaponName = nil
				currentAmmoType = nil
				currentMagSize = 30
				lastClipAmmo = 0
				lastSaveClip = -1

				if selectedWeapon ~= unarmedHash then
					local weaponData, index = ESX.GetWeaponHash(selectedWeapon)
					if weaponData then
						currentWeaponData = { data = weaponData, index = index }
						currentWeaponName = weaponData.name
						currentAmmoType = ESX.GetAmmoType(weaponData.name)

						if currentAmmoType == 'infinite' then
							SetPedAmmo(ped, selectedWeapon, 9999)
						elseif currentAmmoType then
							currentMagSize = GetMagSize(currentAmmoType)
							-- Restore clip from metadata (default 0)
							local stored = GetStoredClipAmmo(currentWeaponName) or 0
							if stored > currentMagSize then stored = currentMagSize end
							local magsLeft = GetMagsAvailable(currentAmmoType)
							SetClipAmmo(ped, selectedWeapon, stored, currentMagSize, magsLeft > 0)
							lastClipAmmo = stored
							lastSaveClip = stored
							AmmoLog("^2EQUIP^7", currentWeaponName, "clip:", stored .. "/" .. currentMagSize, "mags:", magsLeft)
						else
							SetPedAmmo(ped, selectedWeapon, 0)
							null.DebugPrint("^1Arme sans ammoType:", weaponData.name)
						end
					end
				end
			end

			-- -----------------------------------------------------------------
			-- Active weapon tick
			-- -----------------------------------------------------------------
			if selectedWeapon ~= unarmedHash and currentAmmoType and currentAmmoType ~= 'infinite' and not PlayerState.isDead and not IsPedInAnyVehicle(ped, false) then
				local clipAmmo = GetClipAmmo(ped, selectedWeapon)
				local magsLeft = GetMagsAvailable(currentAmmoType)

				-- Prevent GTA auto weapon switch when empty
				if magsLeft <= 0 and clipAmmo <= 0 then
					DisableControlAction(0, 16, true)  -- WEAPON_WHEEL_NEXT
					DisableControlAction(0, 17, true)  -- WEAPON_WHEEL_PREV
					DisableControlAction(0, 37, true)  -- SELECT_WEAPON
				end

				-- Detect clip increase = reload (auto by GTA after shot, or manual R)
				if clipAmmo > lastClipAmmo then
					if magsLeft > 0 then
						ConsumeOneMag(currentWeaponData, currentAmmoType)
						local newMagsLeft = magsLeft - 1
						-- Force full magazine (premature reload = lose remaining, already applied by GTA)
						SetClipAmmo(ped, selectedWeapon, currentMagSize, currentMagSize, newMagsLeft > 0)
						lastClipAmmo = currentMagSize
						AmmoLog("^3RELOAD^7", currentWeaponName, "clip:", currentMagSize, "mags left:", newMagsLeft)
					else
						-- No mags left → revert clip to what it was before reload attempt
						SetClipAmmo(ped, selectedWeapon, lastClipAmmo, currentMagSize, false)
						AmmoLog("^1NO_MAG^7 revert clip to", lastClipAmmo)
					end
				else
					-- Normal shot / idle: just update tracker and refresh reserve if shot occurred
					if clipAmmo ~= lastClipAmmo then
						-- Clip decreased (shot): refresh virtual reserve so GTA can still reload
						SetClipAmmo(ped, selectedWeapon, clipAmmo, currentMagSize, magsLeft > 0)
					end
					lastClipAmmo = clipAmmo
				end

				-- Throttled save to metadata if clip changed significantly
				if lastClipAmmo ~= lastSaveClip then
					SaveClipAmmo(currentWeaponName, lastClipAmmo, false)
					lastSaveClip = lastClipAmmo
				end

				-- Surrender hook
				if getSurrenderStatus() and IsPedShooting(ped) then
					ExecuteCommand("+handsup")
				end

				-- Durability warning
				if Config.AmmunationShop.repairSysteme then
					local gt = GetGameTimer()
					if gt - lastDurabilityWarn > 2000 then
						lastDurabilityWarn = gt
						local weapon = ESX.GetMyWeapon(currentWeaponName)
						if weapon and weapon.durability and not IsPedInAnyVehicle(ped, false) then
							local dur = weapon.durability
							if dur > 95.0 then
								DrawMissionText("~r~Votre arme a moins de 5% de durabilité", 2000)
							elseif dur > 90.0 then
								DrawMissionText("Votre arme a moins de 10% de durabilité", 2000)
							elseif dur > 80.0 then
								DrawMissionText("Votre arme a moins de 20% de durabilité", 2000)
							end
						end
					end
				end

				if IsPedShooting(ped) then
					Wait(0)
				else
					Wait(150)
				end
			else
				Wait(500)
			end
		else
			if PlayerState.weapon ~= unarmedHash then
				SetPedAmmo(PlayerState.ped, PlayerState.weapon, 9999)
			end
			Wait(1000)
		end
	end
end))

-- Save clip ammo on resource stop (player quit / reload)
AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
end)