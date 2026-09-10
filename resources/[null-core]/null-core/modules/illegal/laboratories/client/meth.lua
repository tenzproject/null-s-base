function SetupMethLabo(id)
	local data = null.data.illegals.laboratories.list[id]
	if data.type ~= "meth" then
		return
	end

	-- ========== CUVE SYSTEM ==========
	for cuveId, v in pairs(Config.laboratoire.type[data.type].cuves) do
		local idInteraction = "labo_" .. id .. "_inside_cuve_" .. cuveId
		if Exist3DInteraction(idInteraction) then
			Remove3DInteraction(idInteraction)
		end
		local coords = v.coords
		if data.upgrades["meth-upgrade"] then
			coords = v.coords2
		end

		Add3DInteraction({
			id = idInteraction,
			coords = vec3(coords.x, coords.y, coords.z),
			bucket = data.instance,
			type = "multi",
			text = {
				title = "Cuve de Mélange",
				lines = {
					-- Ingredient status line
					{
						left = "État de la cuve",
						rightAreFunction = true,
						right = function(cb)
							local result = GetLaboInfo(id)
							if not result or not result.treatementmeth or not result.treatementmeth.cuves then
								cb("Chargement...")
								return
							end
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve then cb("Inconnu") return end
							
							local ingCount = #(cuve.ingredients or {})
							local totalIng = #Config.laboratoire.type["meth"].cuveConfig.ingredients
							
							if cuve.state == "idle" then
								cb("Ajoutez ingrédients (" .. ingCount .. "/" .. totalIng .. ")")
							elseif cuve.state == "adding_ingredients" then
								cb("Ingrédients: " .. ingCount .. "/" .. totalIng)
							elseif cuve.state == "mixing" then
								local remaining = cuve.mixRemaining or Config.laboratoire.type["meth"].cuveConfig.mixTime
								cb("Mélange... (~" .. remaining .. " min)")
							elseif cuve.state == "waiting_solvant" then
								cb("Solvant requis")
							elseif cuve.state == "mixing_solvant" then
								local remaining = cuve.solvantRemaining or Config.laboratoire.type["meth"].cuveConfig.solvantMixTime
								cb("Cristallisation... (~" .. remaining .. " min)")
							elseif cuve.state == "ready" then
								cb((cuve.traysRemaining or 0) .. " plateaux prêts")
							else
								cb("Inactif")
							end
						end,
					}, 
					-- Add pseudo
					{
						left = "Ajouter Pseudoéphédrine",
						key = "E",
						action = function()
							TriggerServerEvent("null:labo:methCuveAddIngredient", data.id, cuveId, "pseudo")
						end,
						canSee = function(cb)
							local result = GetLaboInfo(id)
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve then cb(false) return end
							if cuve.state ~= "idle" and cuve.state ~= "adding_ingredients" then cb(false) return end
							-- Check if already added
							for _, v in ipairs(cuve.ingredients or {}) do
								if v == "pseudo" then cb(false) return end
							end
							-- Check inventory
							local inventory = exports["null-core"]:GetPlayerInventaire()
							local hasItem = false
							for _, item in pairs(inventory) do
								if item.name == Config.laboratoire.type["meth"].items["pseudo"] and item.count > 0 then
									hasItem = true
									break
								end
							end
							cb(hasItem, "Vous ne possedez pas de Pseudoéphédrine.")
						end,
					},
					-- Add acide
					{
						left = "Ajouter Acide",
						key = "F",
						action = function()
							TriggerServerEvent("null:labo:methCuveAddIngredient", data.id, cuveId, "acide")
						end,
						canSee = function(cb)
							local result = GetLaboInfo(id)
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve then cb(false) return end
							if cuve.state ~= "idle" and cuve.state ~= "adding_ingredients" then cb(false) return end
							for _, v in ipairs(cuve.ingredients or {}) do
								if v == "acide" then cb(false) return end
							end
							local inventory = exports["null-core"]:GetPlayerInventaire()
							local hasItem = false
							for _, item in pairs(inventory) do
								if item.name == Config.laboratoire.type["meth"].items["acide"] and item.count > 0 then
									hasItem = true
									break
								end
							end
							cb(hasItem, "Vous ne possedez pas d'Acide.")
						end,
					},
					-- Add phosphorus
					{
						left = "Ajouter Phosphore Rouge",
						key = "G",
						action = function()
							TriggerServerEvent("null:labo:methCuveAddIngredient", data.id, cuveId, "phosphorus")
						end,
						canSee = function(cb)
							local result = GetLaboInfo(id)
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve then cb(false) return end
							if cuve.state ~= "idle" and cuve.state ~= "adding_ingredients" then cb(false) return end
							for _, v in ipairs(cuve.ingredients or {}) do
								if v == "phosphorus" then cb(false) return end
							end
							local inventory = exports["null-core"]:GetPlayerInventaire()
							local hasItem = false
							for _, item in pairs(inventory) do
								if item.name == Config.laboratoire.type["meth"].items["phosphorus"] and item.count > 0 then
									hasItem = true
									break
								end
							end
							cb(hasItem, "Vous ne possedez pas de Phosphore Rouge.")
						end,
					},
					-- Add solvant
					{
						left = "Ajouter Solvant",
						key = "Y",
						action = function()
							TriggerServerEvent("null:labo:methCuveAddSolvant", data.id, cuveId)
						end,
						canSee = function(cb)
							local result = GetLaboInfo(id)
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve or cuve.state ~= "waiting_solvant" then cb(false) return end
							local inventory = exports["null-core"]:GetPlayerInventaire()
							local hasItem = false
							for _, item in pairs(inventory) do
								if item.name == Config.laboratoire.type["meth"].items["solvant"] and item.count > 0 then
									hasItem = true
									break
								end
							end
							cb(hasItem, "Vous ne possedez pas de Solvant.")
						end,
					},
					-- Retrieve tray
					{
						left = "Récupérer un plateau",
						key = "H",
						action = function()
							TriggerServerEvent("null:labo:methCuveRetrieveTray", data.id, cuveId)
						end,
						canSee = function(cb)
							local result = GetLaboInfo(id)
							local cuve = result.treatementmeth.cuves[cuveId]
							if not cuve or cuve.state ~= "ready" then cb(false) return end
							if (cuve.traysRemaining or 0) <= 0 then cb(false) return end
							cb(true)
						end,
					},
				},
			},
			canSee = function(cb)
				if not HasLaboPermissions(id, "mix_meth") then
					cb(false)
					return
				end
				cb(true)
			end,
			maxDistance = 3.5,
			maxDistance2 = 1.5,
			key = "E",
		})
	end

	-- ========== BREAKING METH (PropInteract) ==========
	for breakId, v in pairs(Config.laboratoire.type[data.type].breakpoints) do
		local idInteraction = "labo_" .. id .. "_inside_break_" .. breakId
		if Exist3DInteraction(idInteraction) then
			Remove3DInteraction(idInteraction)
		end

		Add3DInteraction({
			id = idInteraction,
			coords = vec3(v.coords.x, v.coords.y, v.coords.z),
			bucket = data.instance,
			text = "Casser la meth",
			Action = function()
				local result = exports["null-core"]:GetAreCuting()
				if result then return end
				if exports["null-core"]:IsSceneOpen() then return end

				ESX.TriggerServerCallback("null:labo:canBreakMeth", function(can)
					if not can then return end

					local origin = v.tableOrigin
					local laboId = data.id
					local numPiles = Config.laboratoire.type["meth"].breakConfig.crystalPiles

					-- Tray props (smashed states)
					local allProps = {
						{
							id = "meth_tray",
							model = "bkr_prop_meth_tray_02a",
							offset = vector3(0.0, 0.0, 0.02),
							rotation = vector3(0.0, 0.0, 0.0),
						},
					} 

					-- Crystal pile positions on tray
					local crystalOffsets = {
						vector3(-0.08, 0.25, 0.03),
						vector3(0.08, 0.14, 0.03),
						vector3(-0.10, 0.07, 0.03),
						vector3(0.18, 0.04, 0.03),
						vector3(0.12, -0.03, 0.03),
						vector3(-0.04, -0.12, 0.03),
						vector3(-0.15, -0.20, 0.03),
						vector3(0.10, -0.31, 0.03),
					}

					local allZones = {
						{
							id = "smash_zone",
							propId = "meth_tray",
							offset = vector3(0.0, 0.0, 0.05),
							label = "Casser le plateau",
							icon = "hammer",
							color = "#ffffff",
							state = "highlight",
							pulse = true,
							actions = {
								{
									id = "smash",
									label = "Casser",
									type = "hold",
									duration = 3000,
									animation = { dict = "amb@world_human_welding@male@base", name = "base", flags = 49 },
								},
							},
						},
					}

					local smashStage = 0
					local crystalsSpawned = false
 
					-- Bag offsets for meth packaging (accessible in both BuildCrystalPropsAndZones and onZoneDrop)
					local bagOffsets = {
						-- vector3(-0.35, -0.20, 0.05),
						-- vector3(-0.12, -0.20, 0.05),
						-- vector3(0.12, -0.20, 0.05),
						-- vector3(0.35, -0.20, 0.05),
						-- vector3(-0.23, -0.35, 0.05),
						-- vector3(0.00, -0.35, 0.05),
						-- vector3(0.23, -0.35, 0.05),

						vector3(-0.35, -0.3, 0.05),
						vector3(-0.35, -0.1, 0.05),
						vector3(-0.35, 0.1, 0.05),
						vector3(-0.35, 0.3, 0.05),

						-- vector3(0.35, -0.25, 0.05),
						-- vector3(0.35, -0.0, 0.05),
						-- vector3(0.35, 0.25, 0.05),

						vector3(0.35, -0.3, 0.05),
						vector3(0.35, -0.1, 0.05),
						vector3(0.35, 0.1, 0.05),
						vector3(0.35, 0.3, 0.05),
					}



					null.DisplayHud("3dinteractions", false)
					local saveCoords = GetEntityCoords(PlayerState.ped)
					FreezeEntityPosition(PlayerState.ped, true)
					SetEntityCoords(PlayerPedId(), vec3(v.coords.x, v.coords.y, v.coords.z - 1.0))
					SetEntityHeading(PlayerState.ped, v.heading)

					null.fct.game.RequestAndWaitModel("bkr_prop_meth_tray_01b")
					null.fct.game.RequestAndWaitModel("prop_custom_pooch_empty")
					null.fct.game.RequestAndWaitModel("prop_custom_methpile")

					local function BuildCrystalPropsAndZones()
						allProps = {}
						allZones = {}

						-- Empty tray
						allProps[#allProps + 1] = {
							id = "meth_tray",
							model = "bkr_prop_meth_tray_01b",
							offset = vector3(0.0, 0.0, 0.02),
							rotation = vector3(0.0, 0.0, 0.0),
						}

						local inventory = exports["null-core"]:GetPlayerInventaire()
						local poochCount = 0
						for _, item in pairs(inventory) do
							if item.name == Config.laboratoire.items["pooch"] then
								poochCount = item.count
								break
							end
							end

						-- Pooch bags (receivers)
						local numBags = math.min(poochCount, numPiles)
						for i = 1, numBags do
							allProps[#allProps + 1] = {
								id = "bag_prop_" .. i,
								model = "prop_custom_pooch_empty",
								offset = bagOffsets[i],
							}
							allZones[#allZones + 1] = {
								id = "bag_" .. i,
								propId = "bag_prop_" .. i,
								offset = vector3(0.0, 0.0, 0.12),
								rotation = vector3(0.0, 0.0, 0.0),
								label = "Pochon #" .. i,
								icon = "package",
								state = "idle",
								pulse = true,
								maxItems = 1,
								actions = {
									{
										id = "fill",
										label = "Remplir",
										type = "drag_receive",
										acceptItems = { "meth_crystal" },
										animation = { dict = "mp_common", name = "givetake1_a", flags = 49, duration = 800 },
									},
								},
							}
						end

						-- Crystal piles (draggables)
						for i = 1, numPiles do
							local pileModel = "prop_custom_methpile"
							-- if i == 2 then pileModel = "bkr_int_02_meth_pile002"
							-- elseif i == 3 then pileModel = "bkr_int_02_meth_pile003"
							-- elseif i == 4 then pileModel = "bkr_int_02_meth_pile004"
							-- elseif i == 5 then pileModel = "bkr_int_02_meth_pile005"
							-- elseif i == 6 then pileModel = "bkr_int_02_meth_pile006"
							-- elseif i == 7 then pileModel = "bkr_int_02_meth_pile007" end


							allProps[#allProps + 1] = {
								id = "crystal_" .. i,
								model = pileModel,
								offset = crystalOffsets[i],
								rotation = vector3(0, 0.0, 0.0),
								placeOnGround = false,
							}
							allZones[#allZones + 1] = {
								id = "crystal_zone_" .. i,
								propId = "crystal_" .. i,
								offset = vector3(0.0, 0.0, 0.05),
								label = "Pile de cristaux",
								icon = "gem",
								state = "idle",
								draggable = true,
								dragItemId = "meth_crystal",
								actions = {},
							}
						end

						return numBags
					end

					exports["null-core"]:OpenPropScene({
						id = "meth_breaking_labo_" .. breakId,
						title = "Casser la Meth",
						subtitle = "Cassez le plateau et remplissez les pochons",
						color = "#3b82f6",
						origin = origin,

						idleAnim = { dict = "timetable@ron@ig_3_couch", name = "base", flags = 51 },

						allowOrbit = true,
						allowZoom = true,

						camera = {
							lookAt = vector3(origin.x, origin.y, origin.z + 0.05),
							distance = 0.75,
							minDistance = 0.5,
							maxDistance = 0.75,
							angle = math.rad(-90),
							heightOffset = 0.5,
							lookAtHeightOffset = 0.0,
							fov = 50.0,
						},

						props = allProps,
						tools = {},
						zones = allZones,
						items = {},

						onZoneAction = function(zoneId, actionId, actionType, toolId)
							if actionType == "hold_complete" and actionId == "smash" and zoneId == "smash_zone" then
								smashStage = smashStage + 1

								if smashStage == 1 then
									-- First smash - change to half broken
									exports["null-core"]:DeleteSceneProp("meth_tray")
									exports["null-core"]:AddSceneProp({
										id = "meth_tray",
										model = "tr_prop_meth_smashedtray_02",
										offset = vector3(0.0, 0.0, 0.02),
										rotation = vector3(0.0, 0.0, 0.0),
									})
									exports["null-core"]:SendSceneNotification("Premier coup! Continuez...", "info")
								elseif smashStage == 2 then
									-- Second smash - change to fully broken
									exports["null-core"]:DeleteSceneProp("meth_tray")
									exports["null-core"]:AddSceneProp({
										id = "meth_tray",
										model = "tr_prop_meth_smashedtray_01",
										offset = vector3(0.0, 0.0, 0.02),
										rotation = vector3(0.0, 0.0, 0.0),
									})
									exports["null-core"]:SendSceneNotification("Plateau cassé! Encore un coup...", "info")
								elseif smashStage >= 3 then
									-- Final smash - tray empty, crystals appear
									TriggerServerEvent("null:labo:methSmashTray", laboId)
									exports["null-core"]:DeleteSceneProp("meth_tray")
									exports["null-core"]:UpdateZoneState("smash_zone", "completed", false)
									exports["null-core"]:RemoveSceneZone("smash_zone")

									-- Rebuild scene with crystals and bags
									local numBags = BuildCrystalPropsAndZones()

									-- Refresh scene with new props/zones
									for _, prop in ipairs(allProps) do
										exports["null-core"]:AddSceneProp(prop)
									end
									for _, zone in ipairs(allZones) do
										exports["null-core"]:AddSceneZone(zone)
									end

									exports["null-core"]:SendSceneNotification("Cristaux révélés! Glissez-les dans les pochons", "success")
								end
							end
						end,

						onZoneDrop = function(zoneId, actionId, itemId, toolId, sourceType, sourceId)
							if zoneId:match("^bag_") and sourceId:match("^crystal_zone_") then
								-- Remove crystal
								local crystalIdx = tonumber(sourceId:match("crystal_zone_(%d+)"))
								local crystalPropId = "crystal_" .. crystalIdx
								exports["null-core"]:DeleteSceneProp(crystalPropId)
								exports["null-core"]:RemoveSceneZone(sourceId)

								-- Update bag
								local bagIdx = tonumber(zoneId:match("bag_(%d+)"))
								local bagPropId = "bag_prop_" .. bagIdx
								local bagOffset = bagOffsets[bagIdx]

								-- Change bag to closed
								exports["null-core"]:DeleteSceneProp(bagPropId)
								exports["null-core"]:AddSceneProp({
									id = bagPropId,
									model = "prop_custom_pooch_closed_meth",
									offset = bagOffset,
									rotation = vector3(0.0, 00.0, 90.0),
								})
								exports["null-core"]:UpdateZoneState(zoneId, "completed", false)

								-- Server: pack 1 crystal = 1 pooch
								TriggerServerEvent("null:labo:methPackCrystal", laboId)

								-- Check if all crystals are packaged
								local remainingCrystals = 0
								for i = 1, numPiles do
									if exports["null-core"]:GetSceneProp("crystal_" .. i) then
										remainingCrystals = remainingCrystals + 1
									end
								end

								if remainingCrystals <= 0 then
									Citizen.SetTimeout(1500, function()
										exports["null-core"]:SendSceneNotification("Tous les cristaux sont empaquetés!", "success")
										Citizen.SetTimeout(2000, function()
											exports["null-core"]:ClosePropScene()
											null.DisplayHud("3dinteractions", true)
										end)
									end)
								end
							end
						end,

						onClose = function()
							null.DisplayHud("3dinteractions", true)
							FreezeEntityPosition(PlayerState.ped, false)
							SetEntityCoords(PlayerPedId(), saveCoords)
						end,
					})
				end, data.id)
			end,
			canSee = function(cb)
				if not HasLaboPermissions(id, "break_meth") then
					cb(false)
					return
				end
				local inventory = exports["null-core"]:GetPlayerInventaire()
				local hasMeth, hasPooch = false, false
				for _, item in pairs(inventory) do
					if item.name == Config.laboratoire.type["meth"].items["meth_tray"] and item.count > 0 then
						hasMeth = true
						if hasPooch and hasMeth then break end
					end
					if item.name == Config.laboratoire.items["pooch"] and item.count > 0 then
						hasPooch = true
						if hasPooch and hasMeth then break end
					end
				end
				if hasPooch and hasMeth then
					cb(true)
				elseif not hasMeth and not hasPooch then
					cb(false, "Vous n'avez aucun plateau de meth et aucun pochon sur vous.")
				elseif not hasMeth and hasPooch then
					cb(false, "Vous n'avez pas de plateau de meth sur vous.")
				elseif hasMeth and not hasPooch then
					cb(false, "Vous n'avez pas de pochon vide sur vous.")
				else
					cb(false, "Merci de contacter le support du serveur (#5AZ0F).")
				end
			end,
			maxDistance = 3.5,
			maxDistance2 = 1.0,
			key = "E",
		})
	end

	-- ========== FOURS (keep existing) ==========
	for k, v in pairs(Config.laboratoire.type[data.type].fours) do
		local fourId = k
		local idInteraction = "labo_" .. id .. "_inside_four_" .. fourId
		if Exist3DInteraction(idInteraction) then
			Remove3DInteraction(idInteraction)
		end
		Add3DInteraction({
			id = idInteraction,
			coords = vector3(v.coords.x, v.coords.y, v.coords.z),
			bucket = data.instance,
			type = "multi",
			text = {
				title = "Fourneau",
				lines = {
					{
						left = "Plateau(x) au fourneau",
						rightAreFunction = true,
						right = function(cb)
							local result = GetLaboInfo(id)
							local nbr = 0
							local nbr = 0
							if
								result.treatementmeth
								and result.treatementmeth.fours
								and result.treatementmeth.fours[fourId]
								and result.treatementmeth.fours[fourId].inFour
							then
								for k, v in pairs(result.treatementmeth.fours[fourId].inFour) do
									nbr += 1
								end
							end
							cb(tostring(nbr) .. "/" .. v.numberMax)
						end,
					},
					{
						left = "Faire chauffer un plateau de Meth",
						key = "E",
						action = function()
							if inDeposeMethFour then
								return
							end
							inDeposeMethFour = true
							SetEntityHeading(PlayerPedId(), v.heading)
							RequestAnimDict("anim@amb@casino@valet_scenario@pose_b@")
							while not HasAnimDictLoaded("anim@amb@casino@valet_scenario@pose_b@") do
								Wait(0)
							end
							TaskPlayAnim(
								PlayerPedId(),
								"anim@amb@casino@valet_scenario@pose_b@",
								"base_a_m_y_vinewood_01",
								8.0,
								-8.0,
								-1,
								51,
								0,
								false,
								false,
								false
							)
							FreezeEntityPosition(PlayerPedId(), true)
							Wait(4000)
							ClearPedTasks(PlayerPedId())
							TriggerServerEvent("null:labo:setmethinfour", id, fourId)
							FreezeEntityPosition(PlayerPedId(), false)
							inDeposeMethFour = false
						end,
						canSee = function(cb)
							local result = exports["null-core"]:GetLaboInfo(id)
							local nbr = 0
							local nbr = 0
							if
								result.treatementmeth
								and result.treatementmeth.fours
								and result.treatementmeth.fours[fourId]
								and result.treatementmeth.fours[fourId].inFour
							then
								for k, v in pairs(result.treatementmeth.fours[fourId].inFour) do
									nbr += 1
								end
							end
							if nbr >= v.numberMax then
								cb(false, "Nombre maximum de plateaux atteint.")
							else
								local inventory = exports["null-core"]:GetPlayerInventaire()
								local found = false
								for k, v in pairs(inventory) do
									if v.name == Config.laboratoire.type["meth"].items["mixture"] and v.count >= 1 then
										found = true
									end
								end
								if found then
									cb(true)
								else
									cb(false, "Vous n'avez aucun plateau de meth sur vous.")
								end
							end
						end,
					},
					{
						left = (function()
							--local result = exports["null-core"]:GetLaboInfo(id)
							--local nbr = 0
							--if result.treatementmeth and result.treatementmeth.fours and result.treatementmeth.fours[fourId] and result.treatementmeth.fours[fourId].inFour then
							--    for k2,v2 in pairs(result.treatementmeth.fours[fourId].inFour) do
							--        if v2.finish then
							--            nbr += 1
							--        end
							--    end
							--end

							--return "Récupérer un plateau de meth ("..nbr.." prêts)"
							return "Récupérer un plateau de meth"
						end)(),
						key = "F",
						action = function()
							if inDeposeMethFour then
								return
							end
							inDeposeMethFour = true
							SetEntityHeading(PlayerPedId(), v.heading)
							RequestAnimDict("anim@amb@casino@valet_scenario@pose_b@")
							while not HasAnimDictLoaded("anim@amb@casino@valet_scenario@pose_b@") do
								Wait(0)
							end
							TaskPlayAnim(
								PlayerPedId(),
								"anim@amb@casino@valet_scenario@pose_b@",
								"base_a_m_y_vinewood_01",
								8.0,
								-8.0,
								-1,
								51,
								0,
								false,
								false,
								false
							)
							FreezeEntityPosition(PlayerPedId(), true)
							Wait(8000)
							ClearPedTasks(PlayerPedId())
							TriggerServerEvent("null:labo:recolteMethFour", id, fourId)
							FreezeEntityPosition(PlayerPedId(), false)
							inDeposeMethFour = false
						end,
						canSee = function(cb)
							local result = exports["null-core"]:GetLaboInfo(id)
							local nbr = 0
							if
								result.treatementmeth
								and result.treatementmeth.fours
								and result.treatementmeth.fours[fourId]
								and result.treatementmeth.fours[fourId].inFour
							then
								for k2, v2 in pairs(result.treatementmeth.fours[fourId].inFour) do
									if v2.finish then
										nbr += 1
									end
								end
							end
							if nbr > 0 then
								cb(true)
							else
								cb(false)
							end
						end,
					},
				},
			},
			canSee = function(cb)
				if not HasLaboPermissions(id, "process_meth") then
					cb(false)
					return
				end
				cb(true)
			end,
			maxDistance = 5.0,
			maxDistance2 = 1.2,
			key = "E",
		})
	end
end

RegisterNetEvent("null:labo:updatecuve", function(id, data)
    -- Ensure the lab data structure exists
    if not null.data.illegals.laboratories.list[id] then
        null.data.illegals.laboratories.list[id] = {}
    end
    if not null.data.illegals.laboratories.list[id].treatementmeth then
        null.data.illegals.laboratories.list[id].treatementmeth = {}
    end
    null.data.illegals.laboratories.list[id].treatementmeth.cuves = data
    -- Refresh all cuve interactions to update dynamic text
    for cuveId, _ in pairs(Config.laboratoire.type["meth"].cuves) do
        local interactionId = "labo_" .. id .. "_inside_cuve_" .. cuveId
        exports["null-core"]:Refresh3DInteraction(interactionId)
    end
end)

RegisterNetEvent("null:labo:updatefour", function(id, data)
    null.data.illegals.laboratories.list[id].treatementmeth.fours = data
end)