Config.AmmoType = {
	['default'] = 'ammo_pistol',
	['pistol'] = 'ammo_pistol',
	['smg'] = 'ammo_smg',
	['rifle'] = 'ammo_rifle',
	['shotgun'] = 'ammo_shotgun',
	['sniper'] = 'ammo_sniper',
}

Config.AmmoTypeDurability = {
	['pistol'] = 0.5,
	['smg'] = 0.25,
	['rifle'] = 0.1,
	['shotgun'] = 0.7,
	['sniper'] = 1.1,
}

Config.MagazineSize = {
	['pistol'] = 12,
	['smg'] = 30,
	['rifle'] = 30,
	['shotgun'] = 8,
	['sniper'] = 5,
}

Config.WeaponDefaultWeight = 1

Config.WeaponWeightPerType = { 
	['pistol'] = 1,
	['smg'] = 2,
	['rifle'] = 3,
	['shotgun'] = 4,
	['sniper'] = 5,
}

Config.WeaponCustomWeigh = { -- Poids des armes (pas encore implémenté)
	['WEAPON_KNIFE'] = 1,
}

Config.SuppressorList = { -- Liste des silencieux
     -- weapon_pistol/weapon_snspistol/...
     {name = "suppressor", model = "COMPONENT_AT_PI_SUPP"},
     {name = "suppressor", model = "COMPONENT_AT_PI_SUPP_02"},
     -- weapon_pistol50/weapon_minismg/weapon_microsmg/weapon_assaultrifle/weapon_assaultrifle_mk2/...
     {name = "suppressor", model = "COMPONENT_AT_AR_SUPP"},
     {name = "suppressor", model = "COMPONENT_AT_AR_SUPP_02"},
     -- weapon_m6ic
     {name = "suppressor", model = "COMPONENT_M6IC_SUPP_01"},
     {name = "suppressor", model = "COMPONENT_M6IC_SUPP_02"},
     {name = "suppressor", model = "COMPONENT_M6IC_SUPP_03"},
     -- weapon_hk416b
     {name = "suppressor", model = "COMPONENT_AT_HK416B_SUPP"},
     -- weapon_scar17fm
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_01"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_02"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_03"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_04"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_05"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_06"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_07"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_08"},
     {name = "suppressor", model = "COMPONENT_SCAR_BARREL_09"},
}

Config.Weapons = {
	{name = 'WEAPON_KNIFE', label = _U('weapon_knife'), components = {}},
	{name = 'WEAPON_NIGHTSTICK', label = _U('weapon_nightstick'), components = {}},
	{name = 'WEAPON_HAMMER', label = _U('weapon_hammer'), components = {}},
	{name = 'WEAPON_BAT', label = _U('weapon_bat'), components = {}},
	{name = 'WEAPON_GOLFCLUB', label = _U('weapon_golfclub'), components = {}},
	{name = 'WEAPON_CROWBAR', label = _U('weapon_crowbar'), components = {}},
	{name = 'WEAPON_NAVYREVOLVER', label = 'Navy Revolver', components = {}, ammoType = 'sniper'},
	{name = 'WEAPON_GADGETPISTOL', label = 'Pistolet Cayo', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_COMBATSHOTGUN', label = 'Fusil a pompe de Combat', components = {}, ammoType = 'shotgun'},
	{name = 'WEAPON_MILITARYRIFLE', label = 'Military Rifle', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_STONE_HATCHET', label = 'Hache en Pierre', components = {}},
	{
		name = 'WEAPON_SCAR17FM',
		label = "SCAR-17",
		ammoType = 'sniper',
		components = {
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SCAR_CLIP_01`},
			{name = 'clip_extended2', label = _U('component_clip_extended2'), hash = `COMPONENT_SCAR_CLIP_02`},
			{name = 'clip_extended3', label = _U('component_clip_extended3'), hash = `COMPONENT_SCAR_CLIP_03`},
			{name = 'clip_extended4', label = _U('component_clip_extended4'), hash = `COMPONENT_SCAR_CLIP_04`},
			{name = 'clip_extended5', label = _U('component_clip_extended5'), hash = `COMPONENT_SCAR_CLIP_05`},
			{name = 'clip_extended6', label = _U('component_clip_extended6'), hash = `COMPONENT_SCAR_CLIP_06`},

			{name = 'scar_flsh1', label = _U('component_flashlight'), hash = `COMPONENT_SCAR_FLSH_01`},
			{name = 'scar_flsh2', label = _U('component_flashlight2'), hash = `COMPONENT_SCAR_FLSH_02`},
			{name = 'scar_flsh3', label = _U('component_flashlight3'), hash = `COMPONENT_SCAR_FLSH_03`},
			{name = 'scar_flsh4', label = _U('component_flashlight4'), hash = `COMPONENT_SCAR_FLSH_04`},
			{name = 'scar_flsh5', label = _U('component_flashlight5'), hash = `COMPONENT_SCAR_FLSH_05`},
			{name = 'scar_flsh6', label = _U('component_flashlight6'), hash = `COMPONENT_SCAR_FLSH_06`},
			{name = 'scar_flsh7', label = _U('component_flashlight7'), hash = `COMPONENT_SCAR_FLSH_07`},
			{name = 'scar_flsh8', label = _U('component_flashlight8'), hash = `COMPONENT_SCAR_FLSH_08`},
			{name = 'scar_flsh9', label = _U('component_flashlight9'), hash = `COMPONENT_SCAR_FLSH_09`},
			{name = 'scar_flsh10', label = _U('component_flashlight10'), hash = `COMPONENT_SCAR_FLSH_10`},

			{name = 'scarscope1', label = _U('component_scope'), hash = `COMPONENT_SCAR_SCOPE_01`},
			{name = 'scarscope2', label = _U('component_scope2'), hash = `COMPONENT_SCAR_SCOPE_02`},
			{name = 'scarscope3', label = _U('component_scope3'), hash = `COMPONENT_SCAR_SCOPE_03`},
			{name = 'scarscope4', label = _U('component_scope4'), hash = `COMPONENT_SCAR_SCOPE_04`},
			{name = 'scarscope5', label = _U('component_scope5'), hash = `COMPONENT_SCAR_SCOPE_05`},
			{name = 'scarscope6', label = _U('component_scope6'), hash = `COMPONENT_SCAR_SCOPE_06`},
			{name = 'scarscope7', label = _U('component_scope7'), hash = `COMPONENT_SCAR_SCOPE_07`},
			{name = 'scarscope8', label = _U('component_scope8'), hash = `COMPONENT_SCAR_SCOPE_08`},
			{name = 'scarscope9', label = _U('component_scope9'), hash = `COMPONENT_SCAR_SCOPE_09`},
			{name = 'scarscope10', label = _U('component_scope10'), hash = `COMPONENT_SCAR_SCOPE_10`},
			{name = 'scarscope11', label = _U('component_scope11'), hash = `COMPONENT_SCAR_SCOPE_11`},
			{name = 'scarscope12', label = _U('component_scope12'), hash = `COMPONENT_SCAR_SCOPE_12`},
			{name = 'scarscope13', label = _U('component_scope13'), hash = `COMPONENT_SCAR_SCOPE_13`},
			{name = 'scarscope14', label = _U('component_scope14'), hash = `COMPONENT_SCAR_SCOPE_14`},
			{name = 'scarscope15', label = _U('component_scope15'), hash = `COMPONENT_SCAR_SCOPE_15`},
			{name = 'scarscope16', label = _U('component_scope16'), hash = `COMPONENT_SCAR_SCOPE_16`},
			{name = 'scarscope17', label = _U('component_scope17'), hash = `COMPONENT_SCAR_SCOPE_17`},
			{name = 'scarscope18', label = _U('component_scope18'), hash = `COMPONENT_SCAR_SCOPE_18`},
			{name = 'scarscope19', label = _U('component_scope19'), hash = `COMPONENT_SCAR_SCOPE_19`},
			{name = 'scarscope20', label = _U('component_scope20'), hash = `COMPONENT_SCAR_SCOPE_20`},	

			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_SCAR_BARREL_01`},
			{name = 'suppressor2', label = _U('component_suppressor2'), hash = `COMPONENT_SCAR_BARREL_02`},
			{name = 'suppressor3', label = _U('component_suppressor3'), hash = `COMPONENT_SCAR_BARREL_03`},
			{name = 'suppressor4', label = _U('component_suppressor4'), hash = `COMPONENT_SCAR_BARREL_04`},
			{name = 'suppressor5', label = _U('component_suppressor5'), hash = `COMPONENT_SCAR_BARREL_05`},
			{name = 'suppressor6', label = _U('component_suppressor6'), hash = `COMPONENT_SCAR_BARREL_06`},
			{name = 'suppressor7', label = _U('component_suppressor7'), hash = `COMPONENT_SCAR_BARREL_07`},
			{name = 'suppressor8', label = _U('component_suppressor8'), hash = `COMPONENT_SCAR_BARREL_08`},
			{name = 'suppressor9', label = _U('component_suppressor9'), hash = `COMPONENT_SCAR_BARREL_09`},

			{name = 'scar_finish', label = _U('component_body'), hash = `COMPONENT_SCAR_BODY_01`},
			{name = 'scar_finish2', label = _U('component_body2'), hash = `COMPONENT_SCAR_BODY_02`}
		}
	},
	
	{
		name = 'WEAPON_HKUMP',
		label = _U('weapon_hkump'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_UMP_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_UMP_CLIP_02`},
			{name = 'umpmount', label = _U('component_mount'), hash = `COMPONENT_UMP_MOUNT_01`},
			{name = 'umpmount2', label = _U('component_mount2'), hash = `COMPONENT_UMP_MOUNT_02`},			
			{name = 'umpflashlight', label = _U('component_flashlight'), hash = `COMPONENT_UMP_FLSH_01`},
			{name = 'umpflashlight2', label = _U('component_flashlight2'), hash = `COMPONENT_UMP_FLSH_02`},
			{name = 'umpflashlight3', label = _U('component_flashlight3'), hash = `COMPONENT_UMP_FLSH_03`},
			{name = 'umpflashlight4', label = _U('component_flashlight4'), hash = `COMPONENT_UMP_FLSH_04`},
			{name = 'umpflashlight5', label = _U('component_flashlight5'), hash = `COMPONENT_UMP_FLSH_05`},
			{name = 'umpflashlight6', label = _U('component_flashlight6'), hash = `COMPONENT_UMP_FLSH_06`},
			{name = 'umpflashlight7', label = _U('component_flashlight7'), hash = `COMPONENT_UMP_FLSH_07`},			
			{name = 'umpscope', label = _U('component_scope'), hash = `COMPONENT_UMP_SCOPE_01`},
			{name = 'umpscope2', label = _U('component_scope2'), hash = `COMPONENT_UMP_SCOPE_02`},
			{name = 'umpscope3', label = _U('component_scope3'), hash = `COMPONENT_UMP_SCOPE_03`},
			{name = 'umpscope4', label = _U('component_scope4'), hash = `COMPONENT_UMP_SCOPE_04`},
			{name = 'umpscope5', label = _U('component_scope5'), hash = `COMPONENT_UMP_SCOPE_05`},
			{name = 'umpscope6', label = _U('component_scope6'), hash = `COMPONENT_UMP_SCOPE_06`},
			{name = 'umpscope7', label = _U('component_scope7'), hash = `COMPONENT_UMP_SCOPE_07`},
			{name = 'umpscope8', label = _U('component_scope8'), hash = `COMPONENT_UMP_SCOPE_08`},
			{name = 'umpscope9', label = _U('component_scope9'), hash = `COMPONENT_UMP_SCOPE_09`},
			{name = 'umpscope10', label = _U('component_scope10'), hash = `COMPONENT_UMP_SCOPE_10`},			
			{name = 'umpsuppressor', label = _U('component_suppressor'), hash = `COMPONENT_UMP_SUPP_01`},
			{name = 'umpsuppressor2', label = _U('component_suppressor2'), hash = `COMPONENT_UMP_SUPP_02`},
			{name = 'umpsuppressor3', label = _U('component_suppressor3'), hash = `COMPONENT_UMP_SUPP_03`},
			{name = 'umpsuppressor4', label = _U('component_suppressor4'), hash = `COMPONENT_UMP_SUPP_04`},
			{name = 'umpsuppressor5', label = _U('component_suppressor5'), hash = `COMPONENT_UMP_SUPP_05`},
			{name = 'umpsuppressor6', label = _U('component_suppressor6'), hash = `COMPONENT_UMP_SUPP_06`},
			{name = 'umpstock', label = _U('component_stock'), hash = `COMPONENT_UMP_STOCK_01`},
			{name = 'umpstock1', label = _U('component_stock1'), hash = `COMPONENT_UMP_STOCK_02`},
			{name = 'umpgrip', label = _U('component_grip'), hash = `COMPONENT_UMP_GRIP_01`},
			{name = 'umpgrip2', label = _U('component_grip2'), hash = `COMPONENT_UMP_GRIP_02`},
			{name = 'umpgrip3', label = _U('component_grip3'), hash = `COMPONENT_UMP_GRIP_03`},
			{name = 'umpgrip4', label = _U('component_grip4'), hash = `COMPONENT_UMP_GRIP_04`},
			{name = 'umpgrip5', label = _U('component_grip5'), hash = `COMPONENT_UMP_GRIP_05`},
			{name = 'umpgrip6', label = _U('component_grip6'), hash = `COMPONENT_UMP_GRIP_06`},
			{name = 'umpgrip7', label = _U('component_grip7'), hash = `COMPONENT_UMP_GRIP_07`},
			{name = 'umpgrip8', label = _U('component_grip8'), hash = `COMPONENT_UMP_GRIP_08`},
			{name = 'umpgrip9', label = _U('component_grip9'), hash = `COMPONENT_UMP_GRIP_09`},
			{name = 'umpgrip10', label = _U('component_grip10'), hash = `COMPONENT_UMP_GRIP_10`},			
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SMG_VARMOD_LUXE`}
		}
	},
	{
        name = 'WEAPON_M4A1FM', 
        label = 'M4A1FM', 
        ammoType = 'rifle',
        components = {
            -- VISEUR
            {name = 'scop1', label = 'Viseur', hash = `COMPONENT_M4A1FM_SCOPE_01`},
            {name = 'scop2', label = 'Viseur', hash = `COMPONENT_M4A1FM_SCOPE_02`},
            {name = 'scop3', label = 'Viseur', hash = `COMPONENT_M4A1FM_SCOPE_03`},
            {name = 'scop4', label = 'Viseur', hash = `COMPONENT_M4A1FM_SCOPE_04`},
            -- SILENCIEUX & POIGNER
            {name = 'silencieuxpoigner1', label = 'Silencieux ou Poignée', hash = `COMPONENT_M4A1FM_BARREL_01`},
            {name = 'silencieuxpoigner2', label = 'Silencieux ou Poignée', hash = `COMPONENT_M4A1FM_BARREL_02`},
            {name = 'silencieuxpoigner3', label = 'Silencieux ou Poignée', hash = `COMPONENT_M4A1FM_BARREL_03`},
            {name = 'silencieuxpoigner4', label = 'Silencieux ou Poignée', hash = `COMPONENT_M4A1FM_BARREL_04`},
            -- Chargeur 
            {name = 'chargeur', label = 'Chargeur', hash = `COMPONENT_M4A1FM_CLIP_01`},
            {name = 'chargeur1', label = 'Chargeur', hash = `COMPONENT_M4A1FM_CLIP_02`},
            {name = 'chargeur2', label = 'Chargeur', hash = `COMPONENT_M4A1FM_CLIP_03`},
            {name = 'chargeur3', label = 'Chargeur', hash = `COMPONENT_M4A1FM_CLIP_04`},
            -- Flashlights & Lasers
            {name = 'lumierelazer1', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_01`},
            {name = 'lumierelazer2', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_02`},
            {name = 'lumierelazer3', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_03`},
            {name = 'lumierelazer4', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_04`},
            {name = 'lumierelazer5', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_05`},
            {name = 'lumierelazer6', label = 'Lumière ou Laser', hash = `COMPONENT_M4A1FM_FLSH_06`},
	    }
    }, 
    {
        name = 'WEAPON_GLOCK', 
        label = 'GLOCK-17', 
        ammoType = 'pistol',
        components = {
            -- VISEUR
            {name = 'scop1', label = 'Viseur', hash = `COMPONENT_SLIDE_01`},
            {name = 'scop2', label = 'Viseur', hash = `COMPONENT_SLIDE_02`},
            {name = 'scop3', label = 'Viseur', hash = `COMPONENT_SLIDE_03`},
            {name = 'scop4', label = 'Viseur', hash = `COMPONENT_SLIDE_04`},
            {name = 'scop5', label = 'Viseur', hash = `COMPONENT_SLIDE_05`},
            {name = 'scop6', label = 'Viseur', hash = `COMPONENT_SLIDE_06`},
            {name = 'scop7', label = 'Viseur', hash = `COMPONENT_SLIDE_07`},
            {name = 'scop8', label = 'Viseur', hash = `COMPONENT_SLIDE_08`},
            {name = 'scop9', label = 'Viseur', hash = `COMPONENT_SLIDE_09`},
            -- SILENCIEUX
            {name = 'silencieux1', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_01`},
            {name = 'silencieux2', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_02`},
            {name = 'silencieux3', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_03`},
            {name = 'silencieux4', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_04`},
            {name = 'silencieux5', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_05`},
            {name = 'silencieux6', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_06`},
            {name = 'silencieux7', label = 'Silencieux ou Poignée', hash = `COMPONENT_SUPP_07`},
            -- Chargeur 
            {name = 'chargeur', label = 'Chargeur', hash = `COMPONENT_CLIP_01`},
            {name = 'chargeur1', label = 'Chargeur', hash = `COMPONENT_CLIP_02`},
            {name = 'chargeur2', label = 'Chargeur', hash = `COMPONENT_CLIP_03`},
            {name = 'chargeur3', label = 'Chargeur', hash = `COMPONENT_CLIP_04`},
            -- Flashlights & Lasers
            {name = 'lumiere1', label = 'Lumière ou Laser', hash = `COMPONENT_GLOCK_FLSH_01`},
            {name = 'lumiere2', label = 'Lumière ou Laser', hash = `COMPONENT_GLOCK_FLSH_02`},
            {name = 'lumiere3', label = 'Lumière ou Laser', hash = `COMPONENT_GLOCK_FLSH_03`},
            {name = 'lumiere4', label = 'Lumière ou Laser', hash = `COMPONENT_GLOCK_FLSH_04`},
        }
	},
	{
        name = 'WEAPON_DOUBLEBARRELFM', 
        label = 'DoubleBarrel', 
        ammoType = 'shotgun',
        components = {
            -- VISEUR
            {name = 'canon1', label = 'Canon', hash = `COMPONENT_DOUBLEBARREL_BARREL_01`},
            {name = 'canon2', label = 'Canon', hash = `COMPONENT_DOUBLEBARREL_BARREL_02`},
            {name = 'canon3', label = 'Canon', hash = `COMPONENT_DOUBLEBARREL_BARREL_03`},
            {name = 'canon4', label = 'Canon', hash = `COMPONENT_DOUBLEBARREL_BARREL_04`},
            {name = 'canon5', label = 'Canon', hash = `COMPONENT_DOUBLEBARREL_BARREL_05`},
        }
    },
	{
		name = 'WEAPON_PISTOL',
		label = _U('weapon_pistol'),
		ammoType = 'pistol',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_PISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_PISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PISTOL_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_COMBATPISTOL',
		label = _U('weapon_combatpistol'),
		ammoType = 'pistol',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_APPISTOL',
		label = _U('weapon_appistol'),
		ammoType = 'smg',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_APPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_APPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_APPISTOL_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_PISTOL50',
		label = _U('weapon_pistol50'),
		ammoType = 'pistol',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_PISTOL50_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_PISTOL50_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PISTOL50_VARMOD_LUXE`}
		}
	},
	{name = 'WEAPON_REVOLVER', label = _U('weapon_revolver'), components = {}, ammoType = 'sniper'},
	{
		name = 'WEAPON_SNSPISTOL',
		label = _U('weapon_snspistol'),
		ammoType = 'pistol',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SNSPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SNSPISTOL_CLIP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SNSPISTOL_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_HEAVYPISTOL',
		label = _U('weapon_heavypistol'),
		ammoType = 'pistol',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_HEAVYPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_HEAVYPISTOL_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_HEAVYPISTOL_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_VINTAGEPISTOL',
		label = _U('weapon_vintagepistol'),
		ammoType = 'sniper',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_VINTAGEPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_VINTAGEPISTOL_CLIP_02`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`}
		}
	},
	{
		name = 'WEAPON_MICROSMG',
		label = _U('weapon_microsmg'),
		ammoType = 'smg',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MICROSMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MICROSMG_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_PI_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MICROSMG_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_SMG',
		label = _U('weapon_smg'),
		ammoType = 'smg',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SMG_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_SMG_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO_02`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SMG_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_ASSAULTSMG',
		label = _U('weapon_assaultsmg'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTSMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTSMG_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_MINISMG',
		label = _U('weapon_minismg'),
		ammoType = 'smg',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MINISMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MINISMG_CLIP_02`}
		}
	},
	{
		name = 'WEAPON_MACHINEPISTOL',
		label = _U('weapon_machinepistol'),
		ammoType = 'smg',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MACHINEPISTOL_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MACHINEPISTOL_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_MACHINEPISTOL_CLIP_03`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_PI_SUPP`}
		}
	},
	{
		name = 'WEAPON_COMBATPDW',
		label = _U('weapon_combatpdw'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATPDW_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATPDW_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_COMBATPDW_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`}
		}
	},	
	{
		name = 'WEAPON_PUMPSHOTGUN',
		label = _U('weapon_pumpshotgun'),
		ammoType = 'shotgun',
		components = {
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_SR_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_SAWNOFFSHOTGUN',
		label = _U('weapon_sawnoffshotgun'),
		ammoType = 'shotgun',
		components = {
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_ASSAULTSHOTGUN',
		label = _U('weapon_assaultshotgun'),
		ammoType = 'shotgun',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTSHOTGUN_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTSHOTGUN_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		}
	},
	{
		name = 'WEAPON_BULLPUPSHOTGUN',
		label = _U('weapon_bullpupshotgun'),
		ammoType = 'shotgun',
		components = {
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		}
	},
	{
		name = 'WEAPON_HEAVYSHOTGUN',
		label = _U('weapon_heavyshotgun'),
		ammoType = 'shotgun',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_HEAVYSHOTGUN_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`}
		}
	},
	{
		name = 'WEAPON_ASSAULTRIFLE',
		label = _U('weapon_assaultrifle'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_ASSAULTRIFLE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MACRO`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ASSAULTRIFLE_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_CARBINERIFLE',
		label = _U('weapon_carbinerifle'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_CARBINERIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_CARBINERIFLE_CLIP_02`},
			{name = 'clip_box', label = _U('component_clip_box'), hash = `COMPONENT_CARBINERIFLE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_CARBINERIFLE_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_ADVANCEDRIFLE',
		label = _U('weapon_advancedrifle'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_ADVANCEDRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_ADVANCEDRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_SPECIALCARBINE',
		label = _U('weapon_specialcarbine'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_SPECIALCARBINE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_SPECIALCARBINE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_SPECIALCARBINE_CLIP_03`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_BULLPUPRIFLE',
		label = _U('weapon_bullpuprifle'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_BULLPUPRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_BULLPUPRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_BULLPUPRIFLE_VARMOD_LOW`}
		}
	},
	{
		name = 'WEAPON_COMPACTRIFLE',
		label = _U('weapon_compactrifle'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMPACTRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMPACTRIFLE_CLIP_02`},
			{name = 'clip_drum', label = _U('component_clip_drum'), hash = `COMPONENT_COMPACTRIFLE_CLIP_03`}
		}
	},
	{
		name = 'WEAPON_MG',
		label = _U('weapon_mg'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MG_CLIP_02`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_SMALL_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MG_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_COMBATMG',
		label = _U('weapon_combatmg'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_COMBATMG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_COMBATMG_CLIP_02`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_MEDIUM`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_COMBATMG_VARMOD_LOWRIDER`}
		}
	},
	{
		name = 'WEAPON_GUSENBERG',
		label = _U('weapon_gusenberg'),
		ammoType = 'rifle',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_GUSENBERG_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_GUSENBERG_CLIP_02`},
		}
	},
	{
		name = 'WEAPON_SNIPERRIFLE',
		label = _U('weapon_sniperrifle'),
		ammoType = 'sniper',
		components = {
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE`},
			{name = 'scope_advanced', label = _U('component_scope_advanced'), hash = `COMPONENT_AT_SCOPE_MAX`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP_02`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_SNIPERRIFLE_VARMOD_LUXE`}
		}
	},
	{
		name = 'WEAPON_HEAVYSNIPER',
		label = _U('weapon_heavysniper'),
		ammoType = 'sniper',
		components = {
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE`},
			{name = 'scope_advanced', label = _U('component_scope_advanced'), hash = `COMPONENT_AT_SCOPE_MAX`}
		}
	},
	{
		name = 'WEAPON_MARKSMANRIFLE',
		label = _U('weapon_marksmanrifle'),
		ammoType = 'sniper',
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = `COMPONENT_MARKSMANRIFLE_CLIP_01`},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = `COMPONENT_MARKSMANRIFLE_CLIP_02`},
			{name = 'flashlight', label = _U('component_flashlight'), hash = `COMPONENT_AT_AR_FLSH`},
			{name = 'scope', label = _U('component_scope'), hash = `COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM`},
			{name = 'suppressor', label = _U('component_suppressor'), hash = `COMPONENT_AT_AR_SUPP`},
			{name = 'grip', label = _U('component_grip'), hash = `COMPONENT_AT_AR_AFGRIP`},
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = `COMPONENT_MARKSMANRIFLE_VARMOD_LUXE`}
		}
	},
	{name = 'WEAPON_GRENADELAUNCHER', label = _U('weapon_grenadelauncher'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_RPG', label = _U('weapon_rpg'), components = {},
	ammoType = 'infinite'},
	{
		name = 'WEAPON_MINIGUN', 
		label = _U('weapon_minigun'), 
		components = {},
		ammoType = 'rifle'
	},
	{name = 'WEAPON_GRENADE', label = _U('weapon_grenade'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_STICKYBOMB', label = _U('weapon_stickybomb'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_SMOKEGRENADE', label = _U('weapon_smokegrenade'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_BZGAS', label = _U('weapon_bzgas'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_MOLOTOV', label = _U('weapon_molotov'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_FIREEXTINGUISHER', label = _U('weapon_fireextinguisher'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_PETROLCAN', label = _U('weapon_petrolcan'), components = {}},
	{name = 'WEAPON_DIGISCANNER', label = _U('weapon_digiscanner'), components = {}},
	{name = 'WEAPON_BALL', label = _U('weapon_ball'), components = {}},
	{name = 'WEAPON_BOTTLE', label = _U('weapon_bottle'), components = {}},
	{name = 'WEAPON_DAGGER', label = _U('weapon_dagger'), components = {}},
	{name = 'WEAPON_FIREWORK', label = _U('weapon_firework'), components = {},
	ammoType = 'infinite'},
	{name = 'WEAPON_MUSKET', label = _U('weapon_musket'), components = {}},
	{name = 'WEAPON_STUNGUN', label = _U('weapon_stungun'), components = {}},
	{name = 'WEAPON_HOMINGLAUNCHER', label = _U('weapon_hominglauncher'), components = {}},
	{name = 'WEAPON_PROXMINE', label = _U('weapon_proxmine'), components = {}},
	{name = 'WEAPON_SNOWBALL', label = _U('weapon_snowball'), components = {}},
	{name = 'WEAPON_FLAREGUN', label = _U('weapon_flaregun'), components = {}},
	{name = 'WEAPON_GARBAGEBAG', label = _U('weapon_garbagebag'), components = {}},
	{name = 'WEAPON_HANDCUFFS', label = _U('weapon_handcuffs'), components = {}},
	{name = 'WEAPON_MARKSMANPISTOL', label = _U('weapon_marksmanpistol'), components = {}},
	{name = 'WEAPON_KNUCKLE', label = _U('weapon_knuckle'), components = {}},
	{name = 'WEAPON_HATCHET', label = _U('weapon_hatchet'), components = {}},
	{name = 'WEAPON_RAILGUN', label = _U('weapon_railgun'), components = {}},
	{name = 'WEAPON_MACHETE', label = _U('weapon_machete'), components = {}},
	{name = 'WEAPON_SWITCHBLADE', label = _U('weapon_switchblade'), components = {}},
	{name = 'WEAPON_DBSHOTGUN', label = _U('weapon_dbshotgun'), components = {}},
	{name = 'WEAPON_AUTOSHOTGUN', label = _U('weapon_autoshotgun'), components = {}},
	{name = 'WEAPON_BATTLEAXE', label = _U('weapon_battleaxe'), components = {}},
	{name = 'WEAPON_COMPACTLAUNCHER', label = _U('weapon_compactlauncher'), components = {}},
	{name = 'WEAPON_PIPEBOMB', label = _U('weapon_pipebomb'), components = {}},
	{name = 'WEAPON_POOLCUE', label = _U('weapon_poolcue'), components = {}},
	{name = 'WEAPON_WRENCH', label = _U('weapon_wrench'), components = {}},
	{name = 'WEAPON_FLASHLIGHT', label = _U('weapon_flashlight'), components = {}},
	{name = 'GADGET_NIGHTVISION', label = _U('gadget_nightvision'), components = {}},
	{name = 'GADGET_PARACHUTE', label = _U('gadget_parachute'), components = {}},
	{name = 'WEAPON_FLARE', label = _U('weapon_flare'), components = {}},
	{name = 'WEAPON_DOUBLEACTION', label = _U('weapon_doubleaction'), components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_SNSPISTOL_MK2', label = _U('weapon_snspistol_mk2')},
	{name = 'WEAPON_REVOLVER_MK2', label = _U('weapon_revolver_mk2')},
	{name = 'WEAPON_SPECIALCARBINE_MK2', label = _U('weapon_specialcarabine_mk2'), ammoType = 'rifle'},
	{name = 'WEAPON_BULLPUPRIFLE_MK2', label = _U('weapon_bullpruprifle_mk2')},
	{name = 'WEAPON_PUMPSHOTGUN_MK2', label = _U('weapon_pumpshotgun_mk2')},
	{name = 'WEAPON_MARKSMANRIFLE_MK2', label = _U('weapon_marksmanrifle_mk2')},
	{name = 'WEAPON_ASSAULTRIFLE_MK2', label = _U('weapon_assaultrifle_mk2')},
	{name = 'WEAPON_CARBINERIFLE_MK2', label = _U('weapon_carbinerifle_mk2')},
	{name = 'WEAPON_COMBATMG_MK2', label = _U('weapon_combatmg_mk2')},
	{name = 'WEAPON_HEAVYSNIPER_MK2', label = _U('weapon_heavysniper_mk2'), ammoType = 'sniper'},
	{name = 'WEAPON_PISTOL_MK2', label = _U('weapon_pistol_mk2')},
	{name = 'WEAPON_SMG_MK2', label = _U('weapon_smg_mk2')},
	{name = 'WEAPON_HEAVYREVOLVER_MK2', label = "heavyrevolver_mk2"},
	{name = 'WEAPON_HUNTSMAN', label = "huntsman"},
	{name = 'WEAPON_KATANA', label = "Katana"},
	{
		name = 'WEAPON_REDL',
		label = 'AK-REDL',
		ammoType = 'rifle',
		components = {}
	},
	{
		name = 'WEAPON_AKORUS',
		label = 'AKORUS',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_AKORUS_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_AKORUS_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_AKORUS_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_AKORUS_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_MILITARM4',
		label = 'MILITARM4',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_M4LEOSHOP_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_M4LEOSHOP_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_M4LEOSHOP_CLIP_03') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_M4LEOSHOP_MEDIUM') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_M4LEOSHOP_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_GOLDM',
		label = 'GOLDM',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_GOLDM_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_GOLDM_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_GOLDM_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_GOLDM_SUPP') }
		}
	},
	{
        name = 'WEAPON_PREDATOR',
        label = 'PREDATOR',
        ammoType = 'rifle',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_PREDATOR_CLIP_01') },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_PREDATOR_CLIP_02') },
            { name = 'clip_box', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_PREDATOR_CLIP_03') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_PREDATOR_MEDIUM') },
            { name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_PREDATOR_SUPP_02') },
            { name = 'grip', label = "GRIP", hash = GetHashKey('COMPONENT_AT_PREDATOR_AFGRIP') }
        }
    },
	{
        name = 'WEAPON_KINETIC',
        label = 'KINETIC',
        ammoType = 'rifle',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_KINETIC_CLIP_01') },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_KINETIC_CLIP_02') },
            { name = 'clip_box', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_KINETIC_CLIP_03') },
            { name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_KINETIC_MEDIUM') },
			{ name = 'flashlight', label = "FLASHLIGHT", hash = GetHashKey('COMPONENT_AT_KINETIC_FLSH') },
            { name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_KINETIC_SUPP_02') },
            { name = 'grip', label = "GRIP", hash = GetHashKey('COMPONENT_AT_KINETIC_AFGRIP') }
        }
    },
	{
        name = 'WEAPON_SCARSC',
        label = 'SCARSC',
        ammoType = 'rifle',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SCARSC_CLIP_01') },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SCARSC_CLIP_02') },
            { name = 'clip_box', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_SCARSC_CLIP_03') },
            { name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_SCOPE_SCARSC') },
			{ name = 'flashlight', label = "FLASHLIGHT", hash = GetHashKey('COMPONENT_AT_SCARSC_FLSH') },
            { name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_SCARSC_SUPP_02') },
            { name = 'grip', label = "GRIP", hash = GetHashKey('COMPONENT_AT_SCARSC_AFGRIP') }
        }
    },
	{
		name = 'WEAPON_TEC9M',
		label = "TEC9M",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_TEC9M_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_TEC9M_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_TEC9M_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_TEC9M_SUPP') }
		}
	},
	{
		name = 'WEAPON_TEC9MF',
		label = "TEC9MF",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_TEC9MF_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_TEC9MF_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_TEC9MF_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_TEC9MF_SUPP') }
		}
	},
	{
		name = 'WEAPON_TEC9MB',
		label = "TEC9MB",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_TEC9MB_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_TEC9MB_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_TEC9MB_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_TEC9MB_SUPP') }
		}
	},
	{
		name = 'WEAPON_BLASTAK',
		label = 'BLASTAK',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_BLASTAK_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_BLASTAK_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_BLASTAK_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_BLASTAK_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_BLASTM4',
		label = 'BLASTM4',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_BLASTM4_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_BLASTM4_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_BLASTM4_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_BLASTM4_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_SIG550',
		label = 'SIG550',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SG550_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SG550_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_SG550_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_SG550_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_BLACKSNIPER',
		label = "BLACKSNIPER",
		ammoType = 'sniper',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_BLACKLEOSHOP_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_BLACKLEOSHOP_CLIP_02') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_BLACKLEOSHOP_MAX') },
			{ name = 'scope_advanced', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_BLACKLEOSHOP_MAX') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_AR_SUPPBLACKLEOSHOP_02') }
		}
	},

	{
		name = 'WEAPON_SOVEREIGN',
		label = "SOVEREIGN",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SOVEREIGN_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SOVEREIGN_CLIP_02') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_SOVEREIGN_SUPP') }
		}
	},

	{
		name = 'WEAPON_GLOCK17',
		label = "GLOCK17",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_COMBATPISTOL_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_GLOCKLEOSHOP_CLIP_02') },
			{ name = 'flashlight', label = "FLASHLIGHT", hash = GetHashKey('COMPONENT_AT_GLOCKLEOSHOP_FLSH') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_GLOCKLEOSHOP_SUPP') }
		}
	},

	{
		name = 'WEAPON_COACHGUN',
		label = "COACHGUN",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_COACHGUN_CLIP_01') }
		}
	},
	{
		name = 'WEAPON_SHOTGUNK',
		label = "SHOTGUNK",
		ammoType = 'rifle',
		components = {
			{ name = 'flashlight', label = _U('component_flashlight'), hash = GetHashKey('COMPONENT_AT_AR_SHOTGUNKLEOSHOPFLSH') },
			{ name = 'suppressor', label = _U('component_suppressor'), hash = GetHashKey('COMPONENT_AT_SHOTGUNK_SUPP') }
		}
	},
	{
		name = 'WEAPON_VSCO',
		label = "VSCO",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_VSCO_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_VSCO_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_VSCO_CLIP_03') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_VSCO_MAX') },
			{ name = 'scope_advanced', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_VSCO_MAX2') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_AR_VSCO_02') }
		}
	},
	{
		name = 'WEAPON_BLUERIOT',
		label = "BLUERIOT",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_BLUERIOT_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_BLUERIOT_CLIP_02') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_BLUERIOT_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_ANCIENT',
		label = 'ANCIENT',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_ANCIENT_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_ANCIENT_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_ANCIENT_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_ANCIENT_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_SNAKE',
		label = 'SNAKE',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SNAKE_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SNAKE_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_SNAKE_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_SNAKE_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_HELL',
		label = 'HELL',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_HELL_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_HELL_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_HELL_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_HELL_SUPP') }
		}
	},
	{
		name = 'WEAPON_OBLIVION',
		label = 'OBLIVION',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_OBLIVION_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_OBLIVION_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_OBLIVION_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_OBLIVION_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_ALIEN',
		label = 'ALIEN',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_ALIEN_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_ALIEN_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_ALIEN_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_ALIENAR_SUPP') }
		}
	},
	{
        name = 'WEAPON_MIDGARD',
        label = 'MIDGARD',
        ammoType = 'rifle',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_MIDGARD_CLIP_01') },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_MIDGARD_CLIP_02') },
            { name = 'clip_box', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_MIDGARD_CLIP_03') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_MIDGARDSCOPE_MEDIUM') },
            { name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_MIDGARDAR_SUPP') }
        }
    },
	{
		name = 'WEAPON_CHAINSAW',
		label = 'CHAINSAW',
		ammoType = 'rifle',
		components = {}
	},
	{
		name = 'WEAPON_SPECIALHAMMER',
		label = 'SPECIALHAMMER',
		ammoType = 'rifle',
		components = {}
	},
	{
		name = 'WEAPON_PENIS',
		label = 'PENIS',
		ammoType = 'rifle',
		components = {}
	},
	{
		name = 'WEAPON_MAZE',
		label = 'MAZE',
		ammoType = 'rifle',
		components = {}
	},
	{
		name = 'WEAPON_REVOLVERVAMP',
		label = 'REVOLVERVAMP',
		ammoType = 'sniper',
		components = {}
	},
	{
		name = 'WEAPON_GUARD',
		label = 'AK_GUARD',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_GUARD_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_GUARD_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_GUARD_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_GUARD_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_GRAU',
		label = 'GRAU',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_GRAU_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_GRAU_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_GRAU_CLIP_03') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_GRAU_CLIP_03_V2') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_GRAU_CLIP_03_V3') },
			{ name = 'flashlight', label = "FLASHLIGHT", hash = GetHashKey('COMPONENT_AT_GRAU_AR_FLSH') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_MEDIUM') },
			{ name = 'scope', label = "SCOPE 2", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_MEDIUM2') },
			{ name = 'scope', label = "SCOPE 3", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_MEDIUM3') },
			{ name = 'scope', label = "SCOPE LONG", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_LONG') },
			{ name = 'scope', label = "SCOPE LONG X", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_LONGX') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_AR_GRAU_SUPP_02') },
			{ name = 'suppressor', label = "SUPPRESSOR 2", hash = GetHashKey('COMPONENT_AT_AR_GRAU_SUPP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR 3", hash = GetHashKey('COMPONENT_AT_AR_GRAU_SUPP_04') },
			{ name = 'stock', label = "STOCK 1", hash = GetHashKey('COMPONENT_GRAU_STOCK') },
			{ name = 'stock', label = "STOCK 2", hash = GetHashKey('COMPONENT_GRAU_STOCK2') },
			{ name = 'stock', label = "STOCK 3", hash = GetHashKey('COMPONENT_GRAU_STOCK3') },
			{ name = 'stock', label = "STOCK 4", hash = GetHashKey('COMPONENT_GRAU_STOCK4') },
			{ name = 'stock', label = "STOCK 5", hash = GetHashKey('COMPONENT_GRAU_STOCK1_V2') },
			{ name = 'stock', label = "STOCK 6", hash = GetHashKey('COMPONENT_GRAU_STOCK2_V3') },
			{ name = 'grip', label = "GRIP 1", hash = GetHashKey('COMPONENT_AT_GRAU_AR_AFGRIP') },
			{ name = 'grip', label = "GRIP 2", hash = GetHashKey('COMPONENT_AT_GRAU_AR_AFGRIP2') },
			{ name = 'grip', label = "GRIP 3", hash = GetHashKey('COMPONENT_AT_GRAU_AR_AFGRIP3') },
			{ name = 'grip', label = "GRIP 4", hash = GetHashKey('COMPONENT_AT_GRAU_AR_AFGRIP4') },
			{ name = 'luxary_finish', label = "VARMOD5", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V5') },
			{ name = 'luxary_finish', label = "VARMOD3", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V3') },
			{ name = 'luxary_finish', label = "VARMOD4", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V4') },
			{ name = 'luxary_finish', label = "VARMOD4", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V2F') },
			{ name = 'luxary_finish', label = "VARMOD4", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V3F') },
			{ name = 'luxary_finish', label = "VARMOD2", hash = GetHashKey('COMPONENT_GRAU_VARMOD_V2') }
		}
	},
	{
		name = 'WEAPON_SCAR17',
		label = 'SCAR17',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SCAR17_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SCAR17_CLIP_02') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SCAR17_V2_CLIP_02') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SCAR17_V3_CLIP_02') },
			{ name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = GetHashKey('COMPONENT_SCAR17_CLIP_03') },
			{ name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = GetHashKey('COMPONENT_SCAR17_V2_CLIP_03') },
			{ name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = GetHashKey('COMPONENT_SCAR17_V3_CLIP_03') },
			{ name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = GetHashKey('COMPONENT_SCAR17_V4_CLIP_03') },
			{ name = 'flashlight', label = "FLASHLIGHT", hash = GetHashKey('COMPONENT_AT_SCAR17_FLSH') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_SCAR17_MEDIUM') },
			{ name = 'scope', label = "SCOPE 2", hash = GetHashKey('COMPONENT_AT_SCAR17_V3_MEDIUM') },
			{ name = 'scope', label = "SCOPE 3", hash = GetHashKey('COMPONENT_AT_GRAU_SCOPE_MEDIUM3') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_AR_SCAR17_SUPP_02') },
			{ name = 'suppressor', label = "SUPPRESSOR 2", hash = GetHashKey('COMPONENT_AT_AR_SCAR17_SUPP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR 3", hash = GetHashKey('COMPONENT_AT_AR_SCAR17_SUPP_04') },
			{ name = 'stock', label = "STOCK 1", hash = GetHashKey('COMPONENT_SCAR17_STOCK') },
			{ name = 'stock', label = "STOCK 2", hash = GetHashKey('COMPONENT_SCAR17_STOCK2') },
			{ name = 'stock', label = "STOCK 3", hash = GetHashKey('COMPONENT_SCAR17_STOCK3') },
			{ name = 'stock', label = "STOCK 4", hash = GetHashKey('COMPONENT_SCAR17_STOCK4') },
			{ name = 'stock', label = "STOCK 5", hash = GetHashKey('COMPONENT_SCAR17_STOCK5') },
			{ name = 'stock', label = "STOCK 6", hash = GetHashKey('COMPONENT_SCAR17_V2_STOCK3') },
			{ name = 'stock', label = "STOCK 7", hash = GetHashKey('COMPONENT_SCAR17_V3_STOCK') },
			{ name = 'stock', label = "STOCK 8", hash = GetHashKey('COMPONENT_SCAR17_V4_STOCK5') },
			{ name = 'luxary_finish', label = "VARMOD2", hash = GetHashKey('COMPONENT_SCAR17_VARMOD_V2') },
			{ name = 'luxary_finish', label = "VARMOD3", hash = GetHashKey('COMPONENT_SCAR17_VARMOD_V3') },
			{ name = 'luxary_finish', label = "VARMOD SMALL", hash = GetHashKey('COMPONENT_SCAR17_VARMOD_SMALL') },
			{ name = 'luxary_finish', label = "VARMOD4", hash = GetHashKey('COMPONENT_SCAR17_VARMOD_V4') }
		}
	},
	{
		name = 'WEAPON_M19',
		label = "M19",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_M19_CLIP_01') },
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_M19_CLIP_01V2') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_M19_CLIP_02') },
			{ name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = GetHashKey('COMPONENT_M19_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR 2", hash = GetHashKey('COMPONENT_AT_PI_M19_SUPP2') },
			{ name = 'luxary_finish', label = "VARMOD2", hash = GetHashKey('COMPONENT_M19_VARMOD_V2') },
			{ name = 'luxary_finish', label = "VARMOD3", hash = GetHashKey('COMPONENT_M19_VARMOD_V3') },
			{ name = 'luxary_finish', label = "VARMOD4", hash = GetHashKey('COMPONENT_M19_VARMOD_V4') },
			{ name = 'luxary_finish', label = "VARMOD5", hash = GetHashKey('COMPONENT_M19_VARMOD_V5') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_PI_M19_SUPP') }
		}
	},
	{
		name = 'WEAPON_SPIDERAK',
		label = 'SPIDERAK',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_SPIDERAK_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_SPIDERAK_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_SPIDERAK_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_SPIDERAK_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_PUMPKIN',
		label = 'PUMPKIN',
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_PUMPKIN_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_PUMPKIN_CLIP_02') },
			{ name = 'clip_drum', label = "DRUM CLIP", hash = GetHashKey('COMPONENT_PUMPKIN_CLIP_03') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_AT_PUMPKIN_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_BONEPER',
		label = "BONEPER",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = "CLIP DEFAULT", hash = GetHashKey('COMPONENT_BONEPER_CLIP_01') },
			{ name = 'clip_extended', label = "EXTENDED CLIP", hash = GetHashKey('COMPONENT_BONEPER_CLIP_02') },
			{ name = 'scope', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_SCOPE_MAX') },
			{ name = 'scope_advanced', label = "SCOPE", hash = GetHashKey('COMPONENT_AT_SCOPE_MAX') },
			{ name = 'suppressor', label = "SUPPRESSOR", hash = GetHashKey('COMPONENT_BONEPER_AR_SUPP_02') }
		}
	},
	{
		name = 'WEAPON_DESERTPURPLE',
		label = "DESERTPURPLE",
		ammoType = 'sniper',
		components = {
			{ name = 'clip_default', label = _U('component_clip_default'), hash = GetHashKey('COMPONENT_DESERT_CLIP_01') },
			{ name = 'clip_extended', label = _U('component_clip_extended'), hash = GetHashKey('COMPONENT_DESERT_CLIP_02') },
			{ name = 'flashlight', label = _U('component_flashlight'), hash = GetHashKey('COMPONENT_AT_PI_FLSH') },
			{ name = 'suppressor', label = _U('component_suppressor'), hash = GetHashKey('COMPONENT_AT_DESERT_SUPP') }
		}
	},
	
	{
		name = 'WEAPON_REVOLVERULTRA',
		label = "REVOLVERULTRA",
		ammoType = 'sniper',
		components = {
			{ name = 'clip_default', label = _U('component_clip_default'), hash = GetHashKey('COMPONENT_REVOLVERULTRA_CLIP_01') },
			{ name = 'suppressor', label = _U('component_suppressor'), hash = GetHashKey('COMPONENT_AT_REVOLVERLEOSHOP_SUPP') }
		}
	},
	{
		name = 'WEAPON_AKS74U',
		label = "Ak74U",
		ammoType = 'rifle',
		components = {
			{ name = 'clip_default', label = _U('component_clip_default'), hash = GetHashKey('COMPONENT_REVOLVERULTRA_CLIP_01') },
			{ name = 'suppressor', label = _U('component_suppressor'), hash = GetHashKey('COMPONENT_AT_REVOLVERLEOSHOP_SUPP') }
		}
	},
	{name = 'WEAPON_3DGLOCK', label = '3D Printed G', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_300BO', label = '300 Blackout', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_357SNUB', label = 'S&W .357 Snubnose', components = {}, ammoType = 'sniper'},
	{name = 'WEAPON_AR15S', label = 'AR-15 Special', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_AKCATCHER', label = 'AK-47 CQC Shellcatcher', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_BAGGLOCK', label = 'Bagged G', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_SWPBLACKARP', label = 'ARP Black Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_BLACKKNIFE', label = 'Knife Black Flag', components = {}},
	{name = 'WEAPON_BLACKSWITCH', label = 'G18 Black Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_SWPBLUEARP', label = 'ARP Blue Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_BLUEKNIFE', label = 'Knife Blue Flag', components = {}},
	{name = 'WEAPON_BLUESWITCH', label = 'G18 Blue Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_FN57B', label = 'FN-57 Binary', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_FN509HUNT', label = 'FN-509 Hunting', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_GRAYARP', label = 'ARP Gray Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_GRAYKNIFE', label = 'Knife Gray Flag', components = {}},
	{name = 'WEAPON_GRAYSWITCH', label = 'G18 Gray Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_GREENARP', label = 'ARP Green Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_GREENKNIFE', label = 'Knife Green Flag', components = {}},
	{name = 'WEAPON_GREENSWITCH', label = 'G18 Green Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_G19BEAM', label = 'G19 with Beam', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_G22', label = 'G22', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_G22B', label = 'G22 Binary', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_G43X', label = 'G43X', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_GHOSTG30', label = 'G30 Ghost Custom', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_GP80C', label = 'GP80 Custom Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_KTECPLR', label = 'KT PLR-16', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_LILUZI', label = 'Uzi', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_MARP', label = 'Micro ARP', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_MDRACO', label = 'Micro Draco', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_MP5C', label = 'MP5 CQC', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_OPPSLUGGER', label = 'Opp Slugger Bat', components = {}},
	{name = 'WEAPON_ORANGEARP', label = 'ARP Orange Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_ORANGEKNIFE', label = 'Knife Orange Flag', components = {}},
	{name = 'WEAPON_ORANGESWITCH', label = 'G18 Orange Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_PTX22', label = 'TX22 Pink', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_PINKARP', label = 'ARP Pink Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_PINKKNIFE', label = 'Knife Pink Flag', components = {}},
	{name = 'WEAPON_SWPPINKSWITCH', label = 'G18 Pink Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_PURPLEARP', label = 'ARP Purple Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_PURPLEKNIFE', label = 'Knife Purple Flag', components = {}},
	{name = 'WEAPON_PURPLESWITCH', label = 'G18 Purple Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_SWPREDARP', label = 'ARP Red Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_REDKNIFE', label = 'Knife Red Flag', components = {}},
	{name = 'WEAPON_SWPREDSWITCH', label = 'G18 Red Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_R580', label = 'Remi 580', components = {}, ammoType = 'shotgun'},
	{name = 'WEAPON_SCORPIONX9', label = 'Scorpion X9 Evo', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_SCREWD', label = 'Rusty Screwdriver', components = {}},
	{name = 'WEAPON_SLEDGEH', label = 'Sledgehammer', components = {}},
	{name = 'WEAPON_STREETSWEEP', label = 'Street Sweeper', components = {}, ammoType = 'shotgun'},
	{name = 'WEAPON_SW357', label = 'S&W .357 Revolver', components = {}, ammoType = 'sniper'},
	{name = 'WEAPON_SWMP9', label = 'S&W M&P9', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_T247', label = 'Taurus 247', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_TANGLOCK', label = 'G17', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_UGLOCK', label = 'Unauthorized G', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_WHITEARP', label = 'ARP White Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_WHITEKNIFE', label = 'Knife White Flag', components = {}},
	{name = 'WEAPON_WHITESWITCH', label = 'G18 White Switch', components = {}, ammoType = 'pistol'},
	{name = 'WEAPON_WOODAXE', label = 'Wooden Axe', components = {}},
	{name = 'WEAPON_YELLOWARP', label = 'ARP Yellow Flag', components = {}, ammoType = 'rifle'},
	{name = 'WEAPON_YELLOWKNIFE', label = 'Knife Yellow Flag', components = {}},
	{name = 'WEAPON_YELLOWSWITCH', label = 'G18 Yellow Switch', components = {}, ammoType = 'pistol'},
}


Config.WeaponsHash = {
	[86711780] = "WEAPON_DEMHAMMER",
	[4068319937] = "WEAPON_DEMKNIFE",
	[2751692961] = "WEAPON_HERTZ",
	[2241839341] = "WEAPON_SLICE",
	[1615809174] = "WEAPON_STEIN",
	[184020396] = "WEAPON_UNICORN",
	[2460120199] = "WEAPON_DAGGER",
	[2508868239] = "WEAPON_BAT",
	[3441901897] = "WEAPON_BATTLEAXE",
	[3638508604] = "WEAPON_KNUCKLE",
	[4192643659] = "WEAPON_BOTTLE",
	[2227010557] = "WEAPON_CROWBAR",
	[2725352035] = "WEAPON_UNARMED",
	[2343591895] = "WEAPON_FLASHLIGHT",
	[1141786504] = "WEAPON_GOLFCLUB",
	[1317494643] = "WEAPON_HAMMER",
	[4191993645] = "WEAPON_HATCHET",
	[2578778090] = "WEAPON_KNIFE", 
	[3713923289] = "WEAPON_MACHETE", 
	[1737195953] = "WEAPON_NIGHTSTICK",
	[419712736] = "WEAPON_WRENCH",  
	[2484171525] = "WEAPON_POOLCUE", 
	[940833800] = "WEAPON_STONE_HATCHET",       
	[584646201] = "WEAPON_APPISTOL",
	[727643628] = "WEAPON_CERAMICPISTOL",
	[1593441988] = "WEAPON_COMBATPISTOL",
	[2548703416] = "WEAPON_DOUBLEACTION",
	[1198879012] = "WEAPON_FLAREGUN",
	[1470379660] = "WEAPON_GADGETPISTOL",       
	[3523564046] = "WEAPON_HEAVYPISTOL",  
	[3249783761] = "WEAPON_REVOLVER",
	[3415619887] = "WEAPON_REVOLVER_MK2",
	[3696079510] = "WEAPON_MARKSMANPISTOL",
	[2441047180] = "WEAPON_NAVYREVOLVER",    
	[453432689] = "WEAPON_PISTOL",
	[2578377531] = "WEAPON_PISTOL50",
	[3219281620] = "WEAPON_PISTOL_MK2",
	[3218215474] = "WEAPON_SNSPISTOL",
	[2285322324] = "WEAPON_SNSPISTOL_MK2",
	[911657153] = "WEAPON_STUNGUN",
	[2939590305] = "WEAPON_RAYPISTOL",
	[137902532] = "WEAPON_VINTAGEPISTOL",      
	[4024951519] = "WEAPON_ASSAULTSMG",
	[171789620] = "WEAPON_COMBATPDW",
	[3675956304] = "WEAPON_MACHINEPISTOL",      
	[324215364] = "WEAPON_MICROSMG",
	[3173288789] = "WEAPON_MINISMG", 
	[736523883] = "WEAPON_SMG",
	[2024373456] = "WEAPON_SMG_MK2",
	[1198256469] = "WEAPON_RAYCARBINE",
	[3800352039] = "WEAPON_ASSAULTSHOTGUN",
	[2640438543] = "WEAPON_BULLPUPSHOTGUN",
	[94989220] = "WEAPON_COMBATSHOTGUN",
	[4019527611] = "WEAPON_DBSHOTGUN",
	[984333226] = "WEAPON_HEAVYSHOTGUN",
	[2828843422] = "WEAPON_MUSKET",
	[487013001] = "WEAPON_PUMPSHOTGUN",
	[1432025498] = "WEAPON_PUMPSHOTGUN_MK2",
	[2017895192] = "WEAPON_SAWNOFFSHOTGUN",
	[317205821] = "WEAPON_AUTOSHOTGUN",
	[2937143193] = "WEAPON_ADVANCEDRIFLE",
	[3220176749] = "WEAPON_ASSAULTRIFLE",
	[961495388] = "WEAPON_ASSAULTRIFLE_MK2",
	[2132975508] = "WEAPON_BULLPUPRIFLE",
	[2228681469] = "WEAPON_BULLPUPRIFLE_MK2",
	[2210333304] = "WEAPON_CARBINERIFLE",
	[4208062921] = "WEAPON_CARBINERIFLE_MK2",
	[1649403952] = "WEAPON_COMPACTRIFLE",
	[2636060646] = "WEAPON_MILITARYRIFLE",
	[3231910285] = "WEAPON_SPECIALCARBINE",
	[2526821735] = "WEAPON_SPECIALCARBINE_MK2",
	[2144741730] = "WEAPON_COMBATMG",
	[3686625920] = "WEAPON_COMBATMG_MK2",
	[1627465347] = "WEAPON_GUSENBERG",
	[2634544996] = "WEAPON_MG",
	[205991906] = "WEAPON_HEAVYSNIPER",
	[177293209] = "WEAPON_HEAVYSNIPER_MK2",
	[3342088282] = "WEAPON_MARKSMANRIFLE",
	[1785463520] = "WEAPON_MARKSMANRIFLE_MK2",
	[100416529] = "WEAPON_SNIPERRIFLE",
	[125959754] = "WEAPON_COMPACTLAUNCHER",
	[2138347493] = "WEAPON_FIREWORK",
	[2726580491] = "WEAPON_GRENADELAUNCHER",
	[1305664] = "WEAPON_GRENADELAUNCHER_SMOKE",
	[1672152130] = "WEAPON_HOMINGLAUNCHER",
	[1119849093] = "WEAPON_MINIGUN",
	[1834241177] = "WEAPON_RAILGUN",
	[2982836145] = "WEAPON_RPG",   
	[3056410471] = "WEAPON_RAYMINIGUN",
	[600439132] = "WEAPON_BALL",
	[2694266206] = "WEAPON_BZGAS",
	[1233104067] = "WEAPON_FLARE", 
	[2481070269] = "WEAPON_GRENADE", 
	[615608432] = "WEAPON_MOLOTOV",
	[3125143736] = "WEAPON_PIPEBOMB",
	[2874559379] = "WEAPON_PROXMINE",
	[4256991824] = "WEAPON_SMOKEGRENADE",       
	[126349499] = "WEAPON_SNOWBALL",
	[741814745] = "WEAPON_STICKYBOMB",
	[101631238] = "WEAPON_FIREEXTINGUISHER",
	[3126027122] = "WEAPON_HAZARDCAN",
	[3215233542] = "WEAPON_PETROLCAN",
	[4222310262] = "GADGET_PARACHUTE",
	[165605215] = "WEAPON_SHOTGUNLETAL",
	[1846078594] = "WEAPON_HKUMP",
	[3055806197] = "WEAPON_KATANA",
	[3223555082] = "WEAPON_CHICKENM4",
	[1066585178] = "WEAPON_CAROTKNIFE",
	[373244404] = "WEAPON_EASTERSNIPER",
	[1914896182] = "WEAPON_M4GINGER",
	[352447046] = "WEAPON_SSGNOEL",
	[2762506346] = "WEAPON_SNOWHAMMER",
	[567827714] = "WEAPON_CANDYCROW",
	[763900850] = "WEAPON_CANDYAK",
	[2995803898] = "WEAPON_BATXMAS",
	[4206096469] = "WEAPON_AWMFROST",
	[4083458968] = "WEAPON_AKFROST",
	[617801310] = "WEAPON_REVOLVERVAMP",
	[3756226112] = "WEAPON_SWITCHBLADE",
	[824008140] = "WEAPON_CHAINSAW",
	[65005941] = "WEAPON_DESERTPURPLE",
	[1413043545] = "WEAPON_BONEPER",
	[111757749] = "WEAPON_SPIDERAK",
	[670259281] = "WEAPON_PUMPKIN",
	[3876691204] = "WEAPON_FM41",
	[3848064416] = "WEAPON_HK417",
	[1288551112] = "WEAPON_REDL",
	[2731176222] = "WEAPON_AKS74U",
	[537400970] = "WEAPON_M4A1FM",
	[233574806] = "WEAPON_SCAR17FM",
	[2813671403] = "WEAPON_PREDATOR",
	[1069898658] = "WEAPON_BLASTAK",
	[3406707129] = "WEAPON_DOUBLEBARRELFM",
	[4174788277] = "WEAPON_GLOCK",
	[1868336605] = "WEAPON_BLACKSNIPER",
	[3520460075] = "WEAPON_TACTICALRIFLE",
	[3028924312] = "WEAPON_BATAQ",
	[1228872246] = "WEAPON_AQAK",
	[3769995932] = "WEAPON_SLIMAQ",
	[1506951844] = "WEAPON_SPECTREAQ",
	[2491568940] = "WEAPON_TRIDENT",
	[3842020719] = "WEAPON_SANTAS",
	[855498692] = "WEAPON_SNIMAS",
	[2327207235] = "WEAPON_SHOTXMAS",
	[1608196558] = "WEAPON_DESERTSANTA",
	[1420433179] = "WEAPON_CANDYKNIFE",
	[3509916676] = "WEAPON_HATMAS",

	[2779004755] = "WEAPON_XMASRIFLE",
	[472986212] = "WEAPON_PISTOLXMAS",
	[3118640435] = "WEAPON_SNOWXMAS",
	[2376325869] = "WEAPON_MGXMAS",
	[3940281034] = "WEAPON_ASSAULTXMAS",

	-- LOVE
	[1942415196] = "WEAPON_VALHAM",
	[3108391129] = "WEAPON_VALKNIFE",
	[2731516527] = "WEAPON_AKBADBOY",
	[4203955038] = "WEAPON_AKBOMBON",
	[2178319488] = "WEAPON_AKCUPID",
	[3261546660] = "WEAPON_AKLOVENOTE",
	[3373594647] = "WEAPON_ROSE",
	[2219715438] = "WEAPON_M4ROSE", 
	[2858397035] = "WEAPON_M4LOVER",
	[182701449] = "WEAPON_AKLOVER",
	[2792963926] = "WEAPON_PVAL",
	[876980983] = "WEAPON_PBLACKVAL",
}

Citizen.CreateThread(function()
	for i = 1, #Config.Weapons do 
		Config.Weapons[i].hash = GetHashKey(Config.Weapons[i].name)
	end
end)