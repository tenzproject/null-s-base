RegisterServerEvent('sBoutique:buyweapon')
AddEventHandler('sBoutique:buyweapon', function(weapon, price, label)
    local _src = source
    local source = source;
    local identifier = GetIdentifiers(source);
    local xPlayer = ESX.GetPlayerFromId(source)

    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE (`transaction` LIKE @transaction AND `identifiers` = @identifiers) ", {
            ['@identifiers'] = after,
            ['@transaction'] = "%"..label.."%"
        }, function(resultWeapon)
            if resultWeapon[1] then
                return xPlayer.showNotification('Vous avez déjà l\'arme')
            else
                local BoutiqueWeapon = nil
                local found = false
                for k,v in pairs(Config.Boutique.Weapons) do 
                    if v.name == weapon then
                        BoutiqueWeapon = v
                        found = true
                    end
                end
                if not found then return end
                OnProcessCheckout(xPlayer.source, BoutiqueWeapon.price, string.format("Achat de : %s", label), function()
                    xPlayer.addWeapon(
                        BoutiqueWeapon.name, 
                        250,
                        nil,
                        true,
                        0
                    )


                    xPlayer.showNotification("Vous avez acheter : " .. BoutiqueWeapon.label .. " sur la boutique !")
                    sendtoarme('LOGS', '[ARME-Boutique] \n' ..GetPlayerName(source).. '\nViens d\'acheter une arme\nArme : ' ..BoutiqueWeapon.name..'\nPrix : ' ..BoutiqueWeapon.price.. '', 3124441)
                end, function()
                    xPlayer.showNotification("Vous ne posséder pas les points nécessaires")
                    return
                end)
            end
        end)  
    end
end)

function sendtoarme (name,message,color)
	date_local1 = os.date('%H:%M:%S', os.time())
	local date_local = date_local1
	local DiscordWebHook = Config.Logs["boutique_weapon"]
    local embeds = {  
        {

            ["title"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] =  {
            ["text"] = "Heure: " ..date_local.. "",
		},
	}
}

	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end 


local function _U(name)
    return name
end

local WEAPON_CUSTOM_PRICE = {
    {name = 'WEAPON_VP9', label = _U('weapon_vp9'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_VP9_CLIP_01', point = 250, },
            {name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_VP9_FLSH'},
            {name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'}
        }
    },
    {name = 'WEAPON_G17C', label = _U('weapon_g17c'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_G17C_CLIP_01'}
        }
    },
    {name = 'WEAPON_G2', label = _U('weapon_g2'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_G2_CLIP_01'}
        }
    },

    {name = 'WEAPON_FM1_M16A4',label = _U('weapon_fm1_m16a4'),components = {}},

    { name = 'WEAPON_KNIFE', label = _U('weapon_knife'), components = {} },
    { name = 'WEAPON_NIGHTSTICK', label = _U('weapon_nightstick'), components = {} },
    { name = 'WEAPON_HAMMER', label = _U('weapon_hammer'), components = {} },
    { name = 'WEAPON_BAT', label = _U('weapon_bat'), components = {} },
    { name = 'WEAPON_GOLFCLUB', label = _U('weapon_golfclub'), components = {} },
    { name = 'WEAPON_CROWBAR', label = _U('weapon_crowbar'), components = {} },
    { name = 'WEAPON_CERAMICPISTOL', label = "CERAMIC PISTOL", components = {} },
    { name = 'WEAPON_CUSTOM', label = "UNK", components = {} },
    { name = 'WEAPON_GADGETPISTOL', label = "UNK", components = {} },
    { name = 'WEAPON_COMBATSHOTGUN', label = "UNK", components = {} },
    { name = 'WEAPON_MILITARYRIFLE', label = "UNK", components = {} },
    { name = 'WEAPON_NAVYREVOLVER', label = "UNK", components = {} },
    {
        name = 'WEAPON_PISTOL',
        label = _U('weapon_pistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_PISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_PISTOL_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PISTOL_VARMOD_LUXE0'}
        }
    },
    {
        name = 'WEAPON_ASSAULTRIFLE',
        label = _U('weapon_assaultrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_PISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_PISTOL_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PISTOL_VARMOD_LUXE0'}
        }
    },
    {
        name = 'WEAPON_COMBATPISTOL',
        label = _U('weapon_combatpistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATPISTOL_CLIP_01', point = 0 },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATPISTOL_CLIP_02', point = 0 },
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH', point = 0 },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP', point = 0 }
        }
    },
    {
        name = 'WEAPON_APPISTOL',
        label = _U('weapon_appistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_APPISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_APPISTOL_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_APPISTOL_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_PISTOL50',
        label = _U('weapon_pistol50'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_PISTOL50_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_PISTOL50_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PISTOL50_VARMOD_LUXE'}
        }
    },
    { name = 'WEAPON_REVOLVER', label = _U('weapon_revolver'), components = {} },
    {
        name = 'WEAPON_SNSPISTOL',
        label = _U('weapon_snspistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SNSPISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SNSPISTOL_CLIP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SNSPISTOL_VARMOD_LOWRIDER'}
        }
    },
    {
        name = 'WEAPON_HEAVYPISTOL',
        label = _U('weapon_heavypistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HEAVYPISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_HEAVYPISTOL_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_HEAVYPISTOL_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_VINTAGEPISTOL',
        label = _U('weapon_vintagepistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_VINTAGEPISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_VINTAGEPISTOL_CLIP_02'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'}
        }
    },
    {
        name = 'WEAPON_MICROSMG',
        label = _U('weapon_microsmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MICROSMG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MICROSMG_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_PI_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MICROSMG_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_SMG',
        label = _U('weapon_smg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SMG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SMG_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_SMG_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO_02'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SMG_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_ASSAULTSMG',
        label = _U('weapon_assaultsmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTSMG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTSMG_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER'}
        }
    },
    {
        name = 'WEAPON_MINISMG',
        label = _U('weapon_minismg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MINISMG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MINISMG_CLIP_02'}
        }
    },
    {
        name = 'WEAPON_MACHINEPISTOL',
        label = _U('weapon_machinepistol'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_MACHINEPISTOL_CLIP_03'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_PI_SUPP'}
        }
    },
    {
        name = 'WEAPON_COMBATPDW',
        label = _U('weapon_combatpdw'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATPDW_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATPDW_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_COMBATPDW_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL'}
        }
    },
    {
        name = 'WEAPON_PUMPSHOTGUN',
        label = _U('weapon_pumpshotgun'),
        components = {
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_SR_SUPP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER'}
        }
    },
    {
        name = 'WEAPON_SAWNOFFSHOTGUN',
        label = _U('weapon_sawnoffshotgun'),
        components = {
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_ASSAULTSHOTGUN',
        label = _U('weapon_assaultshotgun'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTSHOTGUN_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTSHOTGUN_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'}
        }
    },
    {
        name = 'WEAPON_BULLPUPSHOTGUN',
        label = _U('weapon_bullpupshotgun'),
        components = {
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'}
        }
    },
    {
        name = 'WEAPON_HEAVYSHOTGUN',
        label = _U('weapon_heavyshotgun'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_HEAVYSHOTGUN_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'}
        }
    },
    {
        name = 'WEAPON_ASSAULTRIFLE',
        label = _U('weapon_assaultrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_ASSAULTRIFLE_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MACRO'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ASSAULTRIFLE_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_CARBINERIFLE',
        label = _U('weapon_carbinerifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_CARBINERIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_CARBINERIFLE_CLIP_02'},
            { name = 'clip_box', label = _U('component_clip_box'), hash = 'COMPONENT_CARBINERIFLE_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_CARBINERIFLE_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_ADVANCEDRIFLE',
        label = _U('weapon_advancedrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_ADVANCEDRIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_ADVANCEDRIFLE_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_SPECIALCARBINE',
        label = _U('weapon_specialcarbine'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_SPECIALCARBINE_CLIP_03'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER'}
        }
    },

    {
        name = 'WEAPON_HK416B',
        label = _U('weapon_hk416b'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HK416B_CLIP_01'},
            {name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_HK416B_FLSH'},
            {name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_HK416B'},
            {name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_HK416B_SUPP'}
        }
    },

    {
        name = 'WEAPON_SCAR17FM',
        label = _U('weapon_scar17fm'),
        components = {
            {name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_SCAR_CLIP_01'},
            {name = 'clip_extended2', label = _U('component_clip_extended2'), hash = 'COMPONENT_SCAR_CLIP_02'},
            {name = 'clip_extended3', label = _U('component_clip_extended3'), hash = 'COMPONENT_SCAR_CLIP_03'},
            {name = 'clip_extended4', label = _U('component_clip_extended4'), hash = 'COMPONENT_SCAR_CLIP_04'},
            {name = 'clip_extended5', label = _U('component_clip_extended5'), hash = 'COMPONENT_SCAR_CLIP_05'},
            {name = 'clip_extended6', label = _U('component_clip_extended6'), hash = 'COMPONENT_SCAR_CLIP_06'},

            {name = 'scar_flsh1', label = _U('component_flashlight'), hash = 'COMPONENT_SCAR_FLSH_01'},
            {name = 'scar_flsh2', label = _U('component_flashlight2'), hash = 'COMPONENT_SCAR_FLSH_02'},
            {name = 'scar_flsh3', label = _U('component_flashlight3'), hash = 'COMPONENT_SCAR_FLSH_03'},
            {name = 'scar_flsh4', label = _U('component_flashlight4'), hash = 'COMPONENT_SCAR_FLSH_04'},
            {name = 'scar_flsh5', label = _U('component_flashlight5'), hash = 'COMPONENT_SCAR_FLSH_05'},
            {name = 'scar_flsh6', label = _U('component_flashlight6'), hash = 'COMPONENT_SCAR_FLSH_06'},
            {name = 'scar_flsh7', label = _U('component_flashlight7'), hash = 'COMPONENT_SCAR_FLSH_07'},
            {name = 'scar_flsh8', label = _U('component_flashlight8'), hash = 'COMPONENT_SCAR_FLSH_08'},
            {name = 'scar_flsh9', label = _U('component_flashlight9'), hash = 'COMPONENT_SCAR_FLSH_09'},
            {name = 'scar_flsh10', label = _U('component_flashlight10'), hash = 'COMPONENT_SCAR_FLSH_10'},

            {name = 'scarscope1', label = _U('component_scope'), hash = 'COMPONENT_SCAR_SCOPE_01'},
            {name = 'scarscope2', label = _U('component_scope2'), hash = 'COMPONENT_SCAR_SCOPE_02'},
            {name = 'scarscope3', label = _U('component_scope3'), hash = 'COMPONENT_SCAR_SCOPE_03'},
            {name = 'scarscope4', label = _U('component_scope4'), hash = 'COMPONENT_SCAR_SCOPE_04'},
            {name = 'scarscope5', label = _U('component_scope5'), hash = 'COMPONENT_SCAR_SCOPE_05'},
            {name = 'scarscope6', label = _U('component_scope6'), hash = 'COMPONENT_SCAR_SCOPE_06'},
            {name = 'scarscope7', label = _U('component_scope7'), hash = 'COMPONENT_SCAR_SCOPE_07'},
            {name = 'scarscope8', label = _U('component_scope8'), hash = 'COMPONENT_SCAR_SCOPE_08'},
            {name = 'scarscope9', label = _U('component_scope9'), hash = 'COMPONENT_SCAR_SCOPE_09'},
            {name = 'scarscope10', label = _U('component_scope10'), hash = 'COMPONENT_SCAR_SCOPE_10'},
            {name = 'scarscope11', label = _U('component_scope11'), hash = 'COMPONENT_SCAR_SCOPE_11'},
            {name = 'scarscope12', label = _U('component_scope12'), hash = 'COMPONENT_SCAR_SCOPE_12'},
            {name = 'scarscope13', label = _U('component_scope13'), hash = 'COMPONENT_SCAR_SCOPE_13'},
            {name = 'scarscope14', label = _U('component_scope14'), hash = 'COMPONENT_SCAR_SCOPE_14'},
            {name = 'scarscope15', label = _U('component_scope15'), hash = 'COMPONENT_SCAR_SCOPE_15'},
            {name = 'scarscope16', label = _U('component_scope16'), hash = 'COMPONENT_SCAR_SCOPE_16'},
            {name = 'scarscope17', label = _U('component_scope17'), hash = 'COMPONENT_SCAR_SCOPE_17'},
            {name = 'scarscope18', label = _U('component_scope18'), hash = 'COMPONENT_SCAR_SCOPE_18'},
            {name = 'scarscope19', label = _U('component_scope19'), hash = 'COMPONENT_SCAR_SCOPE_19'},
            {name = 'scarscope20', label = _U('component_scope20'), hash = 'COMPONENT_SCAR_SCOPE_20'},  

            {name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_SCAR_BARREL_01'},
            {name = 'suppressor2', label = _U('component_suppressor2'), hash = 'COMPONENT_SCAR_BARREL_02'},
            {name = 'suppressor3', label = _U('component_suppressor3'), hash = 'COMPONENT_SCAR_BARREL_03'},
            {name = 'suppressor4', label = _U('component_suppressor4'), hash = 'COMPONENT_SCAR_BARREL_04'},
            {name = 'suppressor5', label = _U('component_suppressor5'), hash = 'COMPONENT_SCAR_BARREL_05'},
            {name = 'suppressor6', label = _U('component_suppressor6'), hash = 'COMPONENT_SCAR_BARREL_06'},
            {name = 'suppressor7', label = _U('component_suppressor7'), hash = 'COMPONENT_SCAR_BARREL_07'},
            {name = 'suppressor8', label = _U('component_suppressor8'), hash = 'COMPONENT_SCAR_BARREL_08'},
            {name = 'suppressor9', label = _U('component_suppressor9'), hash = 'COMPONENT_SCAR_BARREL_09'},

            {name = 'scar_finish', label = _U('component_body'), hash = 'COMPONENT_SCAR_BODY_01'},
            {name = 'scar_finish2', label = _U('component_body2'), hash = 'COMPONENT_SCAR_BODY_02'}
        }
    },

    {
		name = 'WEAPON_HKUMP',
		label = _U('weapon_hkump'),
		components = {
			{name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_UMP_CLIP_01'},
			{name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_UMP_CLIP_02'},
			{name = 'umpmount', label = _U('component_mount'), hash = 'COMPONENT_UMP_MOUNT_01'},
			{name = 'umpmount2', label = _U('component_mount2'), hash = 'COMPONENT_UMP_MOUNT_02'},			
			{name = 'umpflashlight', label = _U('component_flashlight'), hash = 'COMPONENT_UMP_FLSH_01'},
			{name = 'umpflashlight2', label = _U('component_flashlight2'), hash = 'COMPONENT_UMP_FLSH_02'},
			{name = 'umpflashlight3', label = _U('component_flashlight3'), hash = 'COMPONENT_UMP_FLSH_03'},
			{name = 'umpflashlight4', label = _U('component_flashlight4'), hash = 'COMPONENT_UMP_FLSH_04'},
			{name = 'umpflashlight5', label = _U('component_flashlight5'), hash = 'COMPONENT_UMP_FLSH_05'},
			{name = 'umpflashlight6', label = _U('component_flashlight6'), hash = 'COMPONENT_UMP_FLSH_06'},
			{name = 'umpflashlight7', label = _U('component_flashlight7'), hash = 'COMPONENT_UMP_FLSH_07'},			
			{name = 'umpscope', label = _U('component_scope'), hash = 'COMPONENT_UMP_SCOPE_01'},
			{name = 'umpscope2', label = _U('component_scope2'), hash = 'COMPONENT_UMP_SCOPE_02'},
			{name = 'umpscope3', label = _U('component_scope3'), hash = 'COMPONENT_UMP_SCOPE_03'},
			{name = 'umpscope4', label = _U('component_scope4'), hash = 'COMPONENT_UMP_SCOPE_04'},
			{name = 'umpscope5', label = _U('component_scope5'), hash = 'COMPONENT_UMP_SCOPE_05'},
			{name = 'umpscope6', label = _U('component_scope6'), hash = 'COMPONENT_UMP_SCOPE_06'},
			{name = 'umpscope7', label = _U('component_scope7'), hash = 'COMPONENT_UMP_SCOPE_07'},
			{name = 'umpscope8', label = _U('component_scope8'), hash = 'COMPONENT_UMP_SCOPE_08'},
			{name = 'umpscope9', label = _U('component_scope9'), hash = 'COMPONENT_UMP_SCOPE_09'},
			{name = 'umpscope10', label = _U('component_scope10'), hash = 'COMPONENT_UMP_SCOPE_10'},			
			{name = 'umpsuppressor', label = _U('component_suppressor'), hash = 'COMPONENT_UMP_SUPP_01'},
			{name = 'umpsuppressor2', label = _U('component_suppressor2'), hash = 'COMPONENT_UMP_SUPP_02'},
			{name = 'umpsuppressor3', label = _U('component_suppressor3'), hash = 'COMPONENT_UMP_SUPP_03'},
			{name = 'umpsuppressor4', label = _U('component_suppressor4'), hash = 'COMPONENT_UMP_SUPP_04'},
			{name = 'umpsuppressor5', label = _U('component_suppressor5'), hash = 'COMPONENT_UMP_SUPP_05'},
			{name = 'umpsuppressor6', label = _U('component_suppressor6'), hash = 'COMPONENT_UMP_SUPP_06'},
			{name = 'umpstock', label = _U('component_stock'), hash = 'COMPONENT_UMP_STOCK_01'},
			{name = 'umpstock1', label = _U('component_stock1'), hash = 'COMPONENT_UMP_STOCK_02'},
			{name = 'umpgrip', label = _U('component_grip'), hash = 'COMPONENT_UMP_GRIP_01'},
			{name = 'umpgrip2', label = _U('component_grip2'), hash = 'COMPONENT_UMP_GRIP_02'},
			{name = 'umpgrip3', label = _U('component_grip3'), hash = 'COMPONENT_UMP_GRIP_03'},
			{name = 'umpgrip4', label = _U('component_grip4'), hash = 'COMPONENT_UMP_GRIP_04'},
			{name = 'umpgrip5', label = _U('component_grip5'), hash = 'COMPONENT_UMP_GRIP_05'},
			{name = 'umpgrip6', label = _U('component_grip6'), hash = 'COMPONENT_UMP_GRIP_06'},
			{name = 'umpgrip7', label = _U('component_grip7'), hash = 'COMPONENT_UMP_GRIP_07'},
			{name = 'umpgrip8', label = _U('component_grip8'), hash = 'COMPONENT_UMP_GRIP_08'},
			{name = 'umpgrip9', label = _U('component_grip9'), hash = 'COMPONENT_UMP_GRIP_09'},
			{name = 'umpgrip10', label = _U('component_grip10'), hash = 'COMPONENT_UMP_GRIP_10'},			
			{name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SMG_VARMOD_LUXE'}
		}
	},

    {
        name = 'WEAPON_DOUBLEBARRELFM', 
        label = 'DoubleBarrel', 
        components = {
            -- VISEUR
            {name = 'canon1', label = 'Canon', hash = 'COMPONENT_DOUBLEBARREL_BARREL_01'},
            {name = 'canon2', label = 'Canon', hash = 'COMPONENT_DOUBLEBARREL_BARREL_02'},
            {name = 'canon3', label = 'Canon', hash = 'COMPONENT_DOUBLEBARREL_BARREL_03'},
            {name = 'canon4', label = 'Canon', hash = 'COMPONENT_DOUBLEBARREL_BARREL_04'},
            {name = 'canon5', label = 'Canon', hash = 'COMPONENT_DOUBLEBARREL_BARREL_05'},
        }
    },

    {name = 'WEAPON_M6IC',label = _U('weapon_m6ic'),
        components = {
            {name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_M6IC_CLIP_01'},
            {name = 'clip_extended2', label = _U('component_clip_extended2'), hash = 'COMPONENT_M6IC_CLIP_02'},
            {name = 'clip_extended3', label = _U('component_clip_extended3'), hash = 'COMPONENT_M6IC_CLIP_03'},
            {name = 'clip_extended4', label = _U('component_clip_extended4'), hash = 'COMPONENT_M6IC_CLIP_04'},
            {name = 'clip_extended5', label = _U('component_clip_extended5'), hash = 'COMPONENT_M6IC_CLIP_05'},
            {name = 'clip_extended6', label = _U('component_clip_extended6'), hash = 'COMPONENT_M6IC_CLIP_06'},

            {name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_FMLITESCOPE_03'},
            {name = 'scope2', label = _U('component_scope2'), hash = 'COMPONENT_FMLITESCOPE_04'},
            {name = 'scope3', label = _U('component_scope3'), hash = 'COMPONENT_FMLITESCOPE_05'},
            {name = 'scope4', label = _U('component_scope4'), hash = 'COMPONENT_FMLITESCOPE_06'},
            {name = 'scope5', label = _U('component_scope5'), hash = 'COMPONENT_FMLITESCOPE_07'},
            {name = 'scope6', label = _U('component_scope6'), hash = 'COMPONENT_FMLITESCOPE_08'},
            {name = 'scope7', label = _U('component_scope7'), hash = 'COMPONENT_FMLITESCOPE_09'},

            {name = 'm6_flsh1', label = _U('component_flashlight'), hash = 'COMPONENT_M6IC_FLSH_01'},
            {name = 'm6_flsh2', label = _U('component_flashlight2'), hash = 'COMPONENT_M6IC_FLSH_02'},

            {name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_M6IC_SUPP_01'},
            {name = 'suppressor2', label = _U('component_suppressor2'), hash = 'COMPONENT_M6IC_SUPP_02'},
            {name = 'suppressor3', label = _U('component_suppressor3'), hash = 'COMPONENT_M6IC_SUPP_03'},

            {name = 'm6_stock1', label = _U('component_stock'), hash = 'COMPONENT_M6IC_STOCK_01'},
            {name = 'm6_stock2', label = _U('component_stock2'), hash = 'COMPONENT_M6IC_STOCK_02'},
            {name = 'm6_stock3', label = _U('component_stock3'), hash = 'COMPONENT_M6IC_STOCK_03'},
            {name = 'm6_stock4', label = _U('component_stock4'), hash = 'COMPONENT_M6IC_STOCK_04'},
            {name = 'm6_stock5', label = _U('component_stock5'), hash = 'COMPONENT_M6IC_STOCK_05'},
            {name = 'm6_stock6', label = _U('component_stock6'), hash = 'COMPONENT_M6IC_STOCK_06'},
            {name = 'm6_stock7', label = _U('component_stock7'), hash = 'COMPONENT_M6IC_STOCK_07'},
            {name = 'm6_stock8', label = _U('component_stock8'), hash = 'COMPONENT_M6IC_STOCK_08'},

            {name = 'm6_body', label = _U('component_body'), hash = 'COMPONENT_M6IC_FRAME_01'},
            {name = 'm6_body2', label = _U('component_body2'), hash = 'COMPONENT_M6IC_FRAME_02'}
        }
    },

    {
        name = 'WEAPON_MK47FM',
        label = _U('weapon_mk47fm'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HK416B_CLIP_01'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_MK47_CLIP_02'}
        }
    },

    {
        name = 'WEAPON_GLOCK20',
        label = _U('weapon_glock20'),
        components = {
            {name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_HK416B_CLIP_01'},
            {name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_GLOCK20_FLSH_01', point = 250},
            {name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_GLOCK20_CLIP_02'}
        }
    },

    {
        name = 'WEAPON_BULLPUPRIFLE',
        label = _U('weapon_bullpuprifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_BULLPUPRIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_BULLPUPRIFLE_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_BULLPUPRIFLE_VARMOD_LOW'}
        }
    },
    {
        name = 'WEAPON_COMPACTRIFLE',
        label = _U('weapon_compactrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_02'},
            { name = 'clip_drum', label = _U('component_clip_drum'), hash = 'COMPONENT_COMPACTRIFLE_CLIP_03'}
        }
    },
    {
        name = 'WEAPON_MG',
        label = _U('weapon_mg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MG_CLIP_02'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_SMALL_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MG_VARMOD_LOWRIDER'}
        }
    },
    {
        name = 'WEAPON_COMBATMG',
        label = _U('weapon_combatmg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_COMBATMG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_COMBATMG_CLIP_02'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_MEDIUM'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_COMBATMG_VARMOD_LOWRIDER'}
        }
    },
    {
        name = 'WEAPON_GUSENBERG',
        label = _U('weapon_gusenberg'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_GUSENBERG_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_GUSENBERG_CLIP_02'},
        }
    },
    {
        name = 'WEAPON_SNIPERRIFLE',
        label = _U('weapon_sniperrifle'),
        components = {
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE'},
            { name = 'scope_advanced', label = _U('component_scope_advanced'), hash = 'COMPONENT_AT_SCOPE_MAX'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP_02'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_SNIPERRIFLE_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_HEAVYSNIPER',
        label = _U('weapon_heavysniper'),
        components = {
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE'},
            { name = 'scope_advanced', label = _U('component_scope_advanced'), hash = 'COMPONENT_AT_SCOPE_MAX'}
        }
    },
    {
        name = 'WEAPON_MARKSMANRIFLE',
        label = _U('weapon_marksmanrifle'),
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_MARKSMANRIFLE_CLIP_01'},
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_MARKSMANRIFLE_CLIP_02'},
            { name = 'Adalight', label = _U('component_Adalight'), hash = 'COMPONENT_AT_AR_FLSH'},
            { name = 'scope', label = _U('component_scope'), hash = 'COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM'},
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_AR_SUPP'},
            { name = 'grip', label = _U('component_grip'), hash = 'COMPONENT_AT_AR_AFGRIP'},
            { name = 'luxary_finish', label = _U('component_luxary_finish'), hash = 'COMPONENT_MARKSMANRIFLE_VARMOD_LUXE'}
        }
    },
    {
        name = 'WEAPON_MIDASGUN',
        label = 'Midas Gun',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_ASSAULTRIFLE_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_ASSAULTRIFLE_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_ASSAULTRIFLE_CLIP_03' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_AR_FLSH' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_SCOPE_MACRO' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AR_SUPP_02' },
            { name = 'grip', label = "GRIP", hash = 'COMPONENT_AT_AR_AFGRIP' }
        }
    },
    {
        name = 'WEAPON_REDL',
        label = 'AK-REDL',
        components = {}
    },
    {
        name = 'WEAPON_AKORUS',
        label = 'AKORUS',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_AKORUS_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_AKORUS_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_AKORUS_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AKORUS_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_MILITARM4',
        label = 'MILITARM4',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_M4LEOSHOP_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_M4LEOSHOP_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_M4LEOSHOP_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_M4LEOSHOP_MEDIUM' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_M4LEOSHOP_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_GOLDM',
        label = 'GOLDM',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_GOLDM_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_GOLDM_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_GOLDM_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_GOLDM_SUPP' }
        }
    },
    {
        name = 'WEAPON_PREDATOR',
        label = 'PREDATOR',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_PREDATOR_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_PREDATOR_CLIP_02' },
            { name = 'clip_box', label = "DRUM CLIP", hash = 'COMPONENT_PREDATOR_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_PREDATOR_MEDIUM' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_PREDATOR_SUPP_02' },
            { name = 'grip', label = "GRIP", hash = 'COMPONENT_AT_PREDATOR_AFGRIP' }
        }
    },
    {
        name = 'WEAPON_KINETIC',
        label = 'KINETIC',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_KINETIC_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_KINETIC_CLIP_02' },
            { name = 'clip_box', label = "DRUM CLIP", hash = 'COMPONENT_KINETIC_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_KINETIC_MEDIUM' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_KINETIC_FLSH' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_KINETIC_SUPP_02' },
            { name = 'grip', label = "GRIP", hash = 'COMPONENT_AT_KINETIC_AFGRIP' }
        }
    },
    {
        name = 'WEAPON_SCARSC',
        label = 'SCARSC',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SCARSC_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SCARSC_CLIP_02' },
            { name = 'clip_box', label = "DRUM CLIP", hash = 'COMPONENT_SCARSC_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_SCOPE_SCARSC' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_SCARSC_FLSH' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_SCARSC_SUPP_02' },
            { name = 'grip', label = "GRIP", hash = 'COMPONENT_AT_SCARSC_AFGRIP' }
        }
    },
    {
        name = 'WEAPON_TEC9M',
        label = "TEC9M",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_TEC9M_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_TEC9M_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_TEC9M_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_TEC9M_SUPP' }
        }
    },
    {
        name = 'WEAPON_TEC9MF',
        label = "TEC9MF",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_TEC9MF_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_TEC9MF_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_TEC9MF_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_TEC9MF_SUPP' }
        }
    },
    {
        name = 'WEAPON_TEC9MB',
        label = "TEC9MB",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_TEC9MB_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_TEC9MB_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_TEC9MB_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_TEC9MB_SUPP' }
        }
    },
    {
        name = 'WEAPON_BLASTAK',
        label = 'BLASTAK',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_BLASTAK_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_BLASTAK_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_BLASTAK_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_BLASTAK_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_BLASTM4',
        label = 'BLASTM4',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_BLASTM4_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_BLASTM4_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_BLASTM4_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_BLASTM4_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_SIG550',
        label = 'SIG550',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SG550_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SG550_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_SG550_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_SG550_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_BLACKSNIPER',
        label = "BLACKSNIPER",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_BLACKLEOSHOP_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_BLACKLEOSHOP_CLIP_02' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_BLACKLEOSHOP_MAX' },
            { name = 'scope_advanced', label = "SCOPE", hash = 'COMPONENT_AT_BLACKLEOSHOP_MAX' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AR_SUPPBLACKLEOSHOP_02' }
        }
    },
    
    {
        name = 'WEAPON_SOVEREIGN',
        label = "SOVEREIGN",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SOVEREIGN_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SOVEREIGN_CLIP_02' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_SOVEREIGN_SUPP' }
        }
    },
    
    {
        name = 'WEAPON_GLOCK17',
        label = "GLOCK17",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_COMBATPISTOL_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_GLOCKLEOSHOP_CLIP_02' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_GLOCKLEOSHOP_FLSH' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_GLOCKLEOSHOP_SUPP' }
        }
    },
    
    {
        name = 'WEAPON_COACHGUN',
        label = "COACHGUN",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_COACHGUN_CLIP_01' }
        }
    },
    {
        name = 'WEAPON_SHOTGUNK',
        label = "SHOTGUNK",
        components = {
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_AR_SHOTGUNKLEOSHOPFLSH' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_SHOTGUNK_SUPP' }
        }
    },
    {
        name = 'WEAPON_VSCO',
        label = "VSCO",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_VSCO_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_VSCO_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_VSCO_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_VSCO_MAX' },
            { name = 'scope_advanced', label = "SCOPE", hash = 'COMPONENT_AT_VSCO_MAX2' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AR_VSCO_02' }
        }
    },
    {
        name = 'WEAPON_BLUERIOT',
        label = "BLUERIOT",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_BLUERIOT_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_BLUERIOT_CLIP_02' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_BLUERIOT_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_ANCIENT',
        label = 'ANCIENT',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_ANCIENT_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_ANCIENT_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_ANCIENT_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_ANCIENT_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_SNAKE',
        label = 'SNAKE',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SNAKE_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SNAKE_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_SNAKE_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_SNAKE_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_HELL',
        label = 'HELL',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_HELL_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_HELL_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_HELL_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_HELL_SUPP' }
        }
    },
    {
        name = 'WEAPON_OBLIVION',
        label = 'OBLIVION',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_OBLIVION_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_OBLIVION_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_OBLIVION_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_OBLIVION_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_ALIEN',
        label = 'ALIEN',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_ALIEN_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_ALIEN_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_ALIEN_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_ALIENAR_SUPP' }
        }
    },
    {
        name = 'WEAPON_MIDGARD',
        label = 'MIDGARD',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_MIDGARD_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_MIDGARD_CLIP_02' },
            { name = 'clip_box', label = "DRUM CLIP", hash = 'COMPONENT_MIDGARD_CLIP_03' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_MIDGARDSCOPE_MEDIUM' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_MIDGARDAR_SUPP' }
        }
    },
    {
        name = 'WEAPON_CHAINSAW',
        label = 'CHAINSAW',
        components = {}
    },
    {
        name = 'WEAPON_SPECIALHAMMER',
        label = 'SPECIALHAMMER',
        components = {}
    },
    {
        name = 'WEAPON_PENIS',
        label = 'PENIS',
        components = {}
    },
    {
        name = 'WEAPON_MAZE',
        label = 'MAZE',
        components = {}
    },
    {
        name = 'WEAPON_REVOLVERVAMP',
        label = 'REVOLVERVAMP',
        components = {}
    },
    {
        name = 'WEAPON_GUARD',
        label = 'AK_GUARD',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_GUARD_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_GUARD_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_GUARD_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_GUARD_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_GRAU',
        label = 'GRAU',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_GRAU_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_GRAU_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_GRAU_CLIP_03' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_GRAU_CLIP_03_V2' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_GRAU_CLIP_03_V3' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_GRAU_AR_FLSH' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_GRAU_SCOPE_MEDIUM' },
            { name = 'scope', label = "SCOPE 2", hash = 'COMPONENT_AT_GRAU_SCOPE_MEDIUM2' },
            { name = 'scope', label = "SCOPE 3", hash = 'COMPONENT_AT_GRAU_SCOPE_MEDIUM3' },
            { name = 'scope', label = "SCOPE LONG", hash = 'COMPONENT_AT_GRAU_SCOPE_LONG' },
            { name = 'scope', label = "SCOPE LONG X", hash = 'COMPONENT_AT_GRAU_SCOPE_LONGX' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AR_GRAU_SUPP_02' },
            { name = 'suppressor', label = "SUPPRESSOR 2", hash = 'COMPONENT_AT_AR_GRAU_SUPP_03' },
            { name = 'suppressor', label = "SUPPRESSOR 3", hash = 'COMPONENT_AT_AR_GRAU_SUPP_04' },
            { name = 'stock', label = "STOCK 1", hash = 'COMPONENT_GRAU_STOCK' },
            { name = 'stock', label = "STOCK 2", hash = 'COMPONENT_GRAU_STOCK2' },
            { name = 'stock', label = "STOCK 3", hash = 'COMPONENT_GRAU_STOCK3' },
            { name = 'stock', label = "STOCK 4", hash = 'COMPONENT_GRAU_STOCK4' },
            { name = 'stock', label = "STOCK 5", hash = 'COMPONENT_GRAU_STOCK1_V2' },
            { name = 'stock', label = "STOCK 6", hash = 'COMPONENT_GRAU_STOCK2_V3' },
            { name = 'grip', label = "GRIP 1", hash = 'COMPONENT_AT_GRAU_AR_AFGRIP' },
            { name = 'grip', label = "GRIP 2", hash = 'COMPONENT_AT_GRAU_AR_AFGRIP2' },
            { name = 'grip', label = "GRIP 3", hash = 'COMPONENT_AT_GRAU_AR_AFGRIP3' },
            { name = 'grip', label = "GRIP 4", hash = 'COMPONENT_AT_GRAU_AR_AFGRIP4' },
            { name = 'luxary_finish', label = "VARMOD5", hash = 'COMPONENT_GRAU_VARMOD_V5' },
            { name = 'luxary_finish', label = "VARMOD3", hash = 'COMPONENT_GRAU_VARMOD_V3' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_GRAU_VARMOD_V4' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_GRAU_VARMOD_V2F' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_GRAU_VARMOD_V3F' },
            { name = 'luxary_finish', label = "VARMOD2", hash = 'COMPONENT_GRAU_VARMOD_V2' }
        }
    },
    {
        name = 'WEAPON_SCAR17',
        label = 'SCAR17',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SCAR17_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SCAR17_CLIP_02' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SCAR17_V2_CLIP_02' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SCAR17_V3_CLIP_02' },
            { name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_SCAR17_CLIP_03' },
            { name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_SCAR17_V2_CLIP_03' },
            { name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_SCAR17_V3_CLIP_03' },
            { name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_SCAR17_V4_CLIP_03' },
            { name = 'flashlight', label = "FLASHLIGHT", hash = 'COMPONENT_AT_SCAR17_FLSH' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_SCAR17_MEDIUM' },
            { name = 'scope', label = "SCOPE 2", hash = 'COMPONENT_AT_SCAR17_V3_MEDIUM' },
            { name = 'scope', label = "SCOPE 3", hash = 'COMPONENT_AT_GRAU_SCOPE_MEDIUM3' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_AR_SCAR17_SUPP_02' },
            { name = 'suppressor', label = "SUPPRESSOR 2", hash = 'COMPONENT_AT_AR_SCAR17_SUPP_03' },
            { name = 'suppressor', label = "SUPPRESSOR 3", hash = 'COMPONENT_AT_AR_SCAR17_SUPP_04' },
            { name = 'stock', label = "STOCK 1", hash = 'COMPONENT_SCAR17_STOCK' },
            { name = 'stock', label = "STOCK 2", hash = 'COMPONENT_SCAR17_STOCK2' },
            { name = 'stock', label = "STOCK 3", hash = 'COMPONENT_SCAR17_STOCK3' },
            { name = 'stock', label = "STOCK 4", hash = 'COMPONENT_SCAR17_STOCK4' },
            { name = 'stock', label = "STOCK 5", hash = 'COMPONENT_SCAR17_STOCK5' },
            { name = 'stock', label = "STOCK 6", hash = 'COMPONENT_SCAR17_V2_STOCK3' },
            { name = 'stock', label = "STOCK 7", hash = 'COMPONENT_SCAR17_V3_STOCK' },
            { name = 'stock', label = "STOCK 8", hash = 'COMPONENT_SCAR17_V4_STOCK5' },
            { name = 'luxary_finish', label = "VARMOD2", hash = 'COMPONENT_SCAR17_VARMOD_V2' },
            { name = 'luxary_finish', label = "VARMOD3", hash = 'COMPONENT_SCAR17_VARMOD_V3' },
            { name = 'luxary_finish', label = "VARMOD SMALL", hash = 'COMPONENT_SCAR17_VARMOD_SMALL' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_SCAR17_VARMOD_V4' }
        }
    },
    {
        name = 'WEAPON_UZILS',
        label = 'UZI',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_UZILS_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_UZILS_CLIP_02' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_UZILS_CLIP_03' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_UZILS_CLIP_04' },
            { name = 'clip_extended', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_UZILS_CLIP_01v4' },
            { name = 'clip_extended', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_UZILS_CLIP_02v18' },
            { name = 'clip_extended', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_UZILS_CLIP_02v13' },
            { name = 'clip_extended', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_UZILS_CLIP_03v3' },
            { name = 'clip_extended', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_UZILS_CLIP_03v16' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_UZILS_SUPP_02' },
            { name = 'suppressor', label = "SUPPRESSOR 2", hash = 'COMPONENT_AT_UZILS_SUPP_02v3' },
            { name = 'stock', label = "STOCK 1", hash = 'COMPONENT_UZILS_STOCK' },
            { name = 'stock', label = "STOCK 2", hash = 'COMPONENT_UZILS_STOCK2' },
            { name = 'stock', label = "STOCK 3", hash = 'COMPONENT_UZILS_STOCK3' },
            { name = 'stock', label = "STOCK 4", hash = 'COMPONENT_UZILS_STOCK4' },
            { name = 'stock', label = "STOCK 5", hash = 'COMPONENT_UZILS_STOCK3v3' },
            { name = 'stock', label = "STOCK 6", hash = 'COMPONENT_UZILS_STOCKv13' },
            { name = 'stock', label = "STOCK 7", hash = 'COMPONENT_UZILS_STOCKv18' },
            { name = 'stock', label = "BARREL 1", hash = 'COMPONENT_UZILS_BARREL' },
            { name = 'stock', label = "BARREL 2", hash = 'COMPONENT_UZILS_BARREL2' },
            { name = 'stock', label = "BARREL 3", hash = 'COMPONENT_UZILS_BARREL3' },
            { name = 'stock', label = "BARREL 4", hash = 'COMPONENT_UZILS_BARREL4' },
            { name = 'stock', label = "BARREL 1 SKIN5", hash = 'COMPONENT_UZILS_BARRELv18' },
            { name = 'stock', label = "BARREL 1 SKIN3", hash = 'COMPONENT_UZILS_BARREL4v13' },
            { name = 'luxary_finish', label = "SKIN 1", hash = 'COMPONENT_UZILS_VARMOD_V3' },
            { name = 'luxary_finish', label = "SKIN 2", hash = 'COMPONENT_UZILS_VARMOD_V4' },
            { name = 'luxary_finish', label = "SKIN 3", hash = 'COMPONENT_UZILS_VARMOD_V13' },
            { name = 'luxary_finish', label = "SKIN 4", hash = 'COMPONENT_UZILS_VARMOD_V16' },
            { name = 'luxary_finish', label = "SKIN 5", hash = 'COMPONENT_UZILS_VARMOD_V18' }
        }
    },
    {
        name = 'WEAPON_M19',
        label = "M19",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_M19_CLIP_01' },
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_M19_CLIP_01V2' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_M19_CLIP_02' },
            { name = 'clip_drum', label = "EXTENDED 2 CLIP", hash = 'COMPONENT_M19_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR 2", hash = 'COMPONENT_AT_PI_M19_SUPP2' },
            { name = 'luxary_finish', label = "VARMOD2", hash = 'COMPONENT_M19_VARMOD_V2' },
            { name = 'luxary_finish', label = "VARMOD3", hash = 'COMPONENT_M19_VARMOD_V3' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_M19_VARMOD_V4' },
            { name = 'luxary_finish', label = "VARMOD5", hash = 'COMPONENT_M19_VARMOD_V5' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_PI_M19_SUPP' }
        }
    },
    {
        name = 'WEAPON_SPIDERAK',
        label = 'SPIDERAK',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_SPIDERAK_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_SPIDERAK_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_SPIDERAK_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_SPIDERAK_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_PUMPKIN',
        label = 'PUMPKIN',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_PUMPKIN_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_PUMPKIN_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_PUMPKIN_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_PUMPKIN_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_BONEPER',
        label = "BONEPER",
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_BONEPER_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_BONEPER_CLIP_02' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_AT_SCOPE_MAX' },
            { name = 'scope_advanced', label = "SCOPE", hash = 'COMPONENT_AT_SCOPE_MAX' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_BONEPER_AR_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_DESERTPURPLE',
        label = "DESERTPURPLE",
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_DESERT_CLIP_01' },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_DESERT_CLIP_02' },
            { name = 'flashlight', label = _U('component_flashlight'), hash = 'COMPONENT_AT_PI_FLSH' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_DESERT_SUPP' }
        }
    },
    {
        name = 'WEAPON_DESERTNIKE',
        label = "DESERT NIKE",
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_DESERTNIKE_CLIP_01' },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_DESERTNIKE_CLIP_02' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_DESERTNIKE_PI_SUPP' }
        }
    },
    {
        name = 'WEAPON_GLOCDKM',
        label = "GLOCDKM",
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_GLOCKDM_CLIP_01' },
            { name = 'clip_extended', label = _U('component_clip_extended'), hash = 'COMPONENT_GLOCKDM_CLIP_02' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_GLOCKDM_SUPP' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_GLOCKDMR_SUPP' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_GLOCKDMG_SUPP' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_GLOCKDMN_SUPP' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_GLOCKDMB_SUPP' },
            { name = 'luxary_finish', label = "VARMOD2", hash = 'COMPONENT_GLOCKDM_VARMOD2' },
            { name = 'luxary_finish', label = "VARMOD3", hash = 'COMPONENT_GLOCKDM_VARMOD3' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_GLOCKDM_VARMOD4' },
            { name = 'luxary_finish', label = "VARMOD5", hash = 'COMPONENT_GLOCKDM_VARMOD5' }
        }
    },
    {
        name = 'WEAPON_M4BEAST',
        label = 'M4BEAST',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_M4BEAST_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_M4BEAST_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_M4BEAST_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_M4BEAST_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_M4GOLDBEAST',
        label = 'M4GOLDBEAST',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_M4GOLDBEAST_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_M4GOLDBEAST_CLIP_02' },
            { name = 'clip_drum', label = "DRUM CLIP", hash = 'COMPONENT_M4GOLDBEAST_CLIP_03' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_M4GOLDBEAST_SUPP_02' }
        }
    },
    {
        name = 'WEAPON_HELLSNIPER',
        label = 'HELLSNIPER',
        components = {
            { name = 'clip_default', label = "CLIP DEFAULT", hash = 'COMPONENT_HELLSNIPER_CLIP_01' },
            { name = 'clip_extended', label = "EXTENDED CLIP", hash = 'COMPONENT_HELLSNIPER_CLIP_02' },
            { name = 'suppressor', label = "SUPPRESSOR", hash = 'COMPONENT_AT_HELLSNIPER_SUPP' },
            { name = 'scope', label = "SCOPE", hash = 'COMPONENT_HELLSNIPER_SCOPE_MAX' }
        }
    },
    {
        name = 'WEAPON_357',
        label = ".357",
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_357_CLIP_01' },
            { name = 'luxary_finish', label = "VARMOD2", hash = 'COMPONENT_REVOLVER_VARMOD4' },
            { name = 'luxary_finish', label = "VARMOD3", hash = 'COMPONENT_REVOLVER_VARMOD6' },
            { name = 'luxary_finish', label = "VARMOD4", hash = 'COMPONENT_REVOLVER_VARMOD17' },
            { name = 'luxary_finish', label = "VARMOD5", hash = 'COMPONENT_REVOLVER_VARMOD22' },
            { name = 'luxary_finish', label = "VARMOD6", hash = 'COMPONENT_REVOLVER_VARMOD23' }
        }
    },
    {
        name = 'WEAPON_REVOLVERULTRA',
        label = "REVOLVERULTRA",
        components = {
            { name = 'clip_default', label = _U('component_clip_default'), hash = 'COMPONENT_REVOLVERULTRA_CLIP_01' },
            { name = 'suppressor', label = _U('component_suppressor'), hash = 'COMPONENT_AT_REVOLVERLEOSHOP_SUPP' }
        }
    },
    { name = 'WEAPON_GRENADELAUNCHER', label = _U('weapon_grenadelauncher'), components = {} },
    { name = 'WEAPON_RPG', label = _U('weapon_rpg'), components = {} },
    { name = 'WEAPON_STINGER', label = _U('weapon_stinger'), components = {} },
    { name = 'WEAPON_MINIGUN', label = _U('weapon_minigun'), components = {} },
    { name = 'WEAPON_GRENADE', label = _U('weapon_grenade'), components = {} },
    { name = 'WEAPON_STICKYBOMB', label = _U('weapon_stickybomb'), components = {} },
    { name = 'WEAPON_SMOKEGRENADE', label = _U('weapon_smokegrenade'), components = {} },
    { name = 'WEAPON_BZGAS', label = _U('weapon_bzgas'), components = {} },
    { name = 'WEAPON_MOLOTOV', label = _U('weapon_molotov'), components = {} },
    { name = 'WEAPON_FIREEXTINGUISHER', label = _U('weapon_fireextinguisher'), components = {} },
    { name = 'WEAPON_PETROLCAN', label = _U('weapon_petrolcan'), components = {} },
    { name = 'WEAPON_DIGISCANNER', label = _U('weapon_digiscanner'), components = {} },
    { name = 'WEAPON_BALL', label = _U('weapon_ball'), components = {} },
    { name = 'WEAPON_BOTTLE', label = _U('weapon_bottle'), components = {} },
    { name = 'WEAPON_DAGGER', label = _U('weapon_dagger'), components = {} },
    { name = 'WEAPON_FIREWORK', label = _U('weapon_firework'), components = {} },
    { name = 'WEAPON_MUSKET', label = _U('weapon_musket'), components = {} },
    { name = 'WEAPON_STUNGUN', label = _U('weapon_stungun'), components = {} },
    { name = 'WEAPON_HOMINGLAUNCHER', label = _U('weapon_hominglauncher'), components = {} },
    { name = 'WEAPON_PROXMINE', label = _U('weapon_proxmine'), components = {} },
    { name = 'WEAPON_SNOWBALL', label = _U('weapon_snowball'), components = {} },
    { name = 'WEAPON_FLAREGUN', label = _U('weapon_flaregun'), components = {} },
    { name = 'WEAPON_GARBAGEBAG', label = _U('weapon_garbagebag'), components = {} },
    { name = 'WEAPON_HANDCUFFS', label = _U('weapon_handcuffs'), components = {} },
    { name = 'WEAPON_MARKSMANPISTOL', label = _U('weapon_marksmanpistol'), components = {} },
    { name = 'weapon_marksmanpistol', label = _U('weapon_marksmanpistol'), components = {} },
    { name = 'WEAPON_KNUCKLE', label = _U('weapon_knuckle'), components = {} },
    { name = 'WEAPON_HATCHET', label = _U('weapon_hatchet'), components = {} },
    { name = 'WEAPON_RAILGUN', label = _U('weapon_railgun'), components = {} },
    { name = 'WEAPON_MACHETE', label = _U('weapon_machete'), components = {} },
    { name = 'WEAPON_SWITCHBLADE', label = _U('weapon_switchblade'), components = {} },
    { name = 'WEAPON_DBSHOTGUN', label = _U('weapon_dbshotgun'), components = {} },
    { name = 'WEAPON_AUTOSHOTGUN', label = _U('weapon_autoshotgun'), components = {} },
    { name = 'WEAPON_BATTLEAXE', label = _U('weapon_battleaxe'), components = {} },
    { name = 'WEAPON_COMPACTLAUNCHER', label = _U('weapon_compactlauncher'), components = {} },
    { name = 'WEAPON_PIPEBOMB', label = _U('weapon_pipebomb'), components = {} },
    { name = 'WEAPON_POOLCUE', label = _U('weapon_poolcue'), components = {} },
    { name = 'WEAPON_WRENCH', label = _U('weapon_wrench'), components = {} },
    { name = 'WEAPON_AdaLIGHT', label = _U('weapon_Adalight'), components = {} },
    { name = 'GADGET_NIGHTVISION', label = _U('gadget_nightvision'), components = {} },
    { name = 'GADGET_PARACHUTE', label = _U('gadget_parachute'), components = {} },
    { name = 'WEAPON_FLARE', label = _U('weapon_flare'), components = {} },
    { name = 'WEAPON_DOUBLEACTION', label = _U('weapon_doubleaction'), components = {} },
    { name = 'WEAPON_SNSPISTOL_MK2', label = _U('weapon_snspistol_mk2') },
    { name = 'WEAPON_REVOLVER_MK2', label = _U('weapon_revolver_mk2') },
    { name = 'WEAPON_SPECIALCARBINE_MK2', label = _U('weapon_specialcarabine_mk2') },
    { name = 'WEAPON_BULLPUPRIFLE_MK2', label = _U('weapon_bullpruprifle_mk2') },
    { name = 'WEAPON_PUMPSHOTGUN_MK2', label = _U('weapon_pumpshotgun_mk2') },
    { name = 'WEAPON_MARKSMANRIFLE_MK2', label = _U('weapon_marksmanrifle_mk2') },
    { name = 'WEAPON_ASSAULTRIFLE_MK2', label = _U('weapon_assaultrifle_mk2') },
    { name = 'WEAPON_CARBINERIFLE_MK2', label = _U('weapon_carbinerifle_mk2') },
    { name = 'WEAPON_COMBATMG_MK2', label = _U('weapon_combatmg_mk2') },
    { name = 'WEAPON_HEAVYSNIPER_MK2', label = _U('weapon_heavysniper_mk2') },
    { name = 'WEAPON_PISTOL_MK2', label = _U('weapon_pistol_mk2') },
    { name = 'WEAPON_BLACKSNIPER', label = _U('weapon_blacksniper')},
    { name = 'WEAPON_SMG_MK2', label = _U('weapon_smg_mk2') }
}

local function CustomPrice(weaponName, customHash)
    for _, v in pairs(WEAPON_CUSTOM_PRICE) do
        if (v.name == weaponName) then
            for _, custom in pairs(v.components) do
                if (GetHashKey(custom.hash) == customHash) then
                    return custom
                end
            end
        end
    end
    return false;
end

RegisterServerEvent('tebex:on-process-checkout-weapon-custom')
AddEventHandler('tebex:on-process-checkout-weapon-custom', function(weaponName, customHash)
    local source = source;
    if (source) then
        local _src = source
        local source = source;
        local identifier = GetIdentifiers(source);
        local xPlayer = ESX.GetPlayerFromId(source)
        if (xPlayer) then
            local CUSTOM = CustomPrice(weaponName, customHash);
                OnProcessCheckout(source, 250, string.format("%s - %s", weaponName, customHash), function()
                    xPlayer.addWeaponComponent(weaponName, CUSTOM.name)
                    sendtoCustom('SBoutique - LOGS', '[ARME-Boutique] \n' ..GetPlayerName(source).. '\nViens d\'acheter une custom d\'arme\nArme : ' ..weaponName..'\nAccessoires : ' ..customHash.. '', 3124441)
                end, function()
                    xPlayer.showNotification("Vous ne posséder pas les points nécessaire (250 requis)")
                end)
        else
            print('[Exeception] Failed to retrieve ESX player')
        end
    else
        print('[Exeception] Failed to retrieve source')
    end
end)

RegisterServerEvent('tebex:on-process-checkout-weapon-custom-extra')
AddEventHandler('tebex:on-process-checkout-weapon-custom-extra', function(weaponName, customHash)
    local source = source;
    if (source) then
        local _src = source
        local source = source;
        local identifier = GetIdentifiers(source);
        local xPlayer = ESX.GetPlayerFromId(source)
        if (xPlayer) then
            local CUSTOM = CustomPrice(weaponName, customHash);
            OnProcessCheckout(source, 0, string.format("%s - %s", weaponName, customHash), function()
                xPlayer.addWeaponComponent(weaponName, CUSTOM.name)
                sendtoCustom('SBoutique - LOGS', '[ARME-Boutique] \n' ..GetPlayerName(source).. '\nViens d\'acheter une custom d\'arme\nArme : ' ..weaponName..'\nAccessoires : ' ..customHash.. '', 3124441)
            end, function()
                xPlayer.showNotification("Vous ne posséder pas les points nécessaires")
            end)
        else
            print('[Exeception] Failed to retrieve ESX player')
        end
    else
        print('[Exeception] Failed to retrieve source')
    end
end)


function sendtoCustom (name,message,color)
	date_local1 = os.date('%H:%M:%S', os.time())
	local date_local = date_local1
	local DiscordWebHook = Config.Logs["boutique_weaponcustom"]
    local embeds = {  
        {

            ["title"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] =  {
            ["text"] = "Heure: " ..date_local.. "",
		},
	}
}

	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end 

-- Export weapon custom data for null-core
exports('GetWeaponCustomPrice', function()
    return WEAPON_CUSTOM_PRICE
end)