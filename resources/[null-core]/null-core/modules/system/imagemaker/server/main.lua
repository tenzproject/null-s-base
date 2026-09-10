-- ============================================================================
-- IMAGE MAKER - Server Module
-- Scans game data and coordinates with null-image-maker resource
-- ============================================================================

-- Known GTA V weapon hashes for scanning
local WEAPON_LIST = {
    'WEAPON_KNIFE', 'WEAPON_NIGHTSTICK', 'WEAPON_HAMMER', 'WEAPON_BAT',
    'WEAPON_GOLFCLUB', 'WEAPON_CROWBAR', 'WEAPON_BOTTLE', 'WEAPON_SWITCHBLADE',
    'WEAPON_MACHETE', 'WEAPON_FLASHLIGHT', 'WEAPON_DAGGER', 'WEAPON_HATCHET',
    'WEAPON_KNUCKLE', 'WEAPON_WRENCH', 'WEAPON_BATTLEAXE', 'WEAPON_POOLCUE',
    'WEAPON_STONE_HATCHET', 'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2',
    'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_STUNGUN', 'WEAPON_PISTOL50',
    'WEAPON_SNSPISTOL', 'WEAPON_SNSPISTOL_MK2', 'WEAPON_HEAVYPISTOL',
    'WEAPON_VINTAGEPISTOL', 'WEAPON_FLAREGUN', 'WEAPON_MARKSMANPISTOL',
    'WEAPON_REVOLVER', 'WEAPON_REVOLVER_MK2', 'WEAPON_DOUBLEACTION',
    'WEAPON_RAYPISTOL', 'WEAPON_CERAMICPISTOL', 'WEAPON_NAVYREVOLVER',
    'WEAPON_GADGETPISTOL', 'WEAPON_STUNGUN_MP', 'WEAPON_PISTOLXM3',
    'WEAPON_TECPISTOL', 'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_SMG_MK2',
    'WEAPON_ASSAULTSMG', 'WEAPON_COMBATPDW', 'WEAPON_MACHINEPISTOL',
    'WEAPON_MINISMG', 'WEAPON_RAYCARBINE', 'WEAPON_PUMPSHOTGUN',
    'WEAPON_PUMPSHOTGUN_MK2', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
    'WEAPON_BULLPUPSHOTGUN', 'WEAPON_MUSKET', 'WEAPON_HEAVYSHOTGUN',
    'WEAPON_DBSHOTGUN', 'WEAPON_AUTOSHOTGUN', 'WEAPON_COMBATSHOTGUN',
    'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2', 'WEAPON_CARBINERIFLE',
    'WEAPON_CARBINERIFLE_MK2', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE',
    'WEAPON_SPECIALCARBINE_MK2', 'WEAPON_BULLPUPRIFLE', 'WEAPON_BULLPUPRIFLE_MK2',
    'WEAPON_COMPACTRIFLE', 'WEAPON_MILITARYRIFLE', 'WEAPON_HEAVYRIFLE',
    'WEAPON_TACTICALRIFLE', 'WEAPON_MG', 'WEAPON_COMBATMG', 'WEAPON_COMBATMG_MK2',
    'WEAPON_GUSENBERG', 'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER',
    'WEAPON_HEAVYSNIPER_MK2', 'WEAPON_MARKSMANRIFLE', 'WEAPON_MARKSMANRIFLE_MK2',
    'WEAPON_PRECISIONRIFLE', 'WEAPON_RPG', 'WEAPON_GRENADELAUNCHER',
    'WEAPON_GRENADELAUNCHER_SMOKE', 'WEAPON_MINIGUN', 'WEAPON_FIREWORK',
    'WEAPON_RAILGUN', 'WEAPON_HOMINGLAUNCHER', 'WEAPON_COMPACTLAUNCHER',
    'WEAPON_RAYMINIGUN', 'WEAPON_EMPLAUNCHER', 'WEAPON_RAILGUNXM3',
    'WEAPON_GRENADE', 'WEAPON_BZGAS', 'WEAPON_SMOKEGRENADE',
    'WEAPON_FLARE', 'WEAPON_MOLOTOV', 'WEAPON_STICKYBOMB', 'WEAPON_PROXMINE',
    'WEAPON_SNOWBALL', 'WEAPON_PIPEBOMB', 'WEAPON_BALL', 'WEAPON_PETROLCAN',
    'WEAPON_FIREEXTINGUISHER', 'WEAPON_PARACHUTE', 'WEAPON_HAZARDCAN',
    'WEAPON_FERTILIZERCAN', 'WEAPON_GLOCK',
}

-- Known ped models
local PED_LIST = {
    'a_c_boar', 'a_c_cat_01', 'a_c_chickenhawk', 'a_c_chimp', 'a_c_chop',
    'a_c_cormorant', 'a_c_cow', 'a_c_coyote', 'a_c_crow', 'a_c_deer',
    'a_c_dolphin', 'a_c_fish', 'a_c_hen', 'a_c_husky', 'a_c_killerwhale',
    'a_c_mtlion', 'a_c_panther', 'a_c_pig', 'a_c_pigeon', 'a_c_poodle',
    'a_c_pug', 'a_c_rabbit_01', 'a_c_rat', 'a_c_retriever', 'a_c_rhesus',
    'a_c_rottweiler', 'a_c_seagull', 'a_c_sharkhammer', 'a_c_sharktiger',
    'a_c_shepherd', 'a_c_stingray', 'a_c_westy',
    'a_f_m_beach_01', 'a_f_m_bevhills_01', 'a_f_m_bevhills_02',
    'a_f_m_bodybuild_01', 'a_f_m_business_02', 'a_f_m_downtown_01',
    'a_f_m_eastsa_01', 'a_f_m_eastsa_02', 'a_f_m_fatbla_01',
    'a_f_m_fatcult_01', 'a_f_m_fatwhit_01', 'a_f_m_ktown_01',
    'a_f_m_ktown_02', 'a_f_m_prolhost_01', 'a_f_m_salton_01',
    'a_f_m_skidrow_01', 'a_f_m_soucent_01', 'a_f_m_soucent_02',
    'a_f_m_soucentmc_01', 'a_f_m_tourist_01', 'a_f_m_tramp_01',
    'a_f_m_trampbeac_01',
    'a_f_o_genstreet_01', 'a_f_o_indian_01', 'a_f_o_ktown_01',
    'a_f_o_salton_01', 'a_f_o_soucent_01', 'a_f_o_soucent_02',
    'a_f_y_beach_01', 'a_f_y_bevhills_01', 'a_f_y_bevhills_02',
    'a_f_y_bevhills_03', 'a_f_y_bevhills_04', 'a_f_y_business_01',
    'a_f_y_business_02', 'a_f_y_business_03', 'a_f_y_business_04',
    'a_f_y_eastsa_01', 'a_f_y_eastsa_02', 'a_f_y_eastsa_03',
    'a_f_y_epsilon_01', 'a_f_y_fitness_01', 'a_f_y_fitness_02',
    'a_f_y_genhot_01', 'a_f_y_golfer_01', 'a_f_y_hiker_01',
    'a_f_y_hippie_01', 'a_f_y_hipster_01', 'a_f_y_hipster_02',
    'a_f_y_hipster_03', 'a_f_y_hipster_04', 'a_f_y_indian_01',
    'a_f_y_juggalo_01', 'a_f_y_runner_01', 'a_f_y_rurmeth_01',
    'a_f_y_scdressy_01', 'a_f_y_skater_01', 'a_f_y_soucent_01',
    'a_f_y_soucent_02', 'a_f_y_soucent_03', 'a_f_y_tennis_01',
    'a_f_y_topless_01', 'a_f_y_tourist_01', 'a_f_y_tourist_02',
    'a_f_y_vinewood_01', 'a_f_y_vinewood_02', 'a_f_y_vinewood_03',
    'a_f_y_vinewood_04', 'a_f_y_yoga_01',
    'a_m_m_afriamer_01', 'a_m_m_beach_01', 'a_m_m_beach_02',
    'a_m_m_bevhills_01', 'a_m_m_bevhills_02', 'a_m_m_business_01',
    'a_m_m_eastsa_01', 'a_m_m_eastsa_02', 'a_m_m_farmer_01',
    'a_m_m_fatlatin_01', 'a_m_m_genfat_01', 'a_m_m_genfat_02',
    'a_m_m_golfer_01', 'a_m_m_hasjew_01', 'a_m_m_hillbilly_01',
    'a_m_m_hillbilly_02', 'a_m_m_indian_01', 'a_m_m_ktown_01',
    'a_m_m_malibu_01', 'a_m_m_mexcntry_01', 'a_m_m_mexlabor_01',
    'a_m_m_og_boss_01', 'a_m_m_paparazzi_01', 'a_m_m_polynesian_01',
    'a_m_m_prolhost_01', 'a_m_m_rurmeth_01', 'a_m_m_salton_01',
    'a_m_m_salton_02', 'a_m_m_salton_03', 'a_m_m_salton_04',
    'a_m_m_skater_01', 'a_m_m_skidrow_01', 'a_m_m_socenlat_01',
    'a_m_m_soucent_01', 'a_m_m_soucent_02', 'a_m_m_soucent_03',
    'a_m_m_soucent_04', 'a_m_m_stlat_02', 'a_m_m_tennis_01',
    'a_m_m_tourist_01', 'a_m_m_tramp_01', 'a_m_m_trampbeac_01',
    'a_m_m_tranvest_01', 'a_m_m_tranvest_02',
    'a_m_o_acult_01', 'a_m_o_acult_02', 'a_m_o_beach_01',
    'a_m_o_genstreet_01', 'a_m_o_ktown_01', 'a_m_o_salton_01',
    'a_m_o_soucent_01', 'a_m_o_soucent_02', 'a_m_o_soucent_03',
    'a_m_o_tramp_01',
    'a_m_y_beach_01', 'a_m_y_beach_02', 'a_m_y_beach_03',
    'a_m_y_beachvesp_01', 'a_m_y_beachvesp_02', 'a_m_y_bevhills_01',
    'a_m_y_bevhills_02', 'a_m_y_breakdance_01', 'a_m_y_busicas_01',
    'a_m_y_business_01', 'a_m_y_business_02', 'a_m_y_business_03',
    'a_m_y_cyclist_01', 'a_m_y_dhill_01', 'a_m_y_downtown_01',
    'a_m_y_eastsa_01', 'a_m_y_eastsa_02', 'a_m_y_epsilon_01',
    'a_m_y_epsilon_02', 'a_m_y_gay_01', 'a_m_y_gay_02',
    'a_m_y_genstreet_01', 'a_m_y_genstreet_02', 'a_m_y_golfer_01',
    'a_m_y_hasjew_01', 'a_m_y_hiker_01', 'a_m_y_hippy_01',
    'a_m_y_hipster_01', 'a_m_y_hipster_02', 'a_m_y_hipster_03',
    'a_m_y_indian_01', 'a_m_y_jetski_01', 'a_m_y_juggalo_01',
    'a_m_y_ktown_01', 'a_m_y_ktown_02', 'a_m_y_latino_01',
    'a_m_y_methhead_01', 'a_m_y_mexthug_01', 'a_m_y_motox_01',
    'a_m_y_motox_02', 'a_m_y_musclbeac_01', 'a_m_y_musclbeac_02',
    'a_m_y_polynesian_01', 'a_m_y_roadcyc_01', 'a_m_y_runner_01',
    'a_m_y_runner_02', 'a_m_y_salton_01', 'a_m_y_skater_01',
    'a_m_y_skater_02', 'a_m_y_soucent_01', 'a_m_y_soucent_02',
    'a_m_y_soucent_03', 'a_m_y_soucent_04', 'a_m_y_stbla_01',
    'a_m_y_stbla_02', 'a_m_y_stlat_01', 'a_m_y_stwhi_01',
    'a_m_y_stwhi_02', 'a_m_y_sunbathe_01', 'a_m_y_surfer_01',
    'a_m_y_vindouche_01', 'a_m_y_vinewood_01', 'a_m_y_vinewood_02',
    'a_m_y_vinewood_03', 'a_m_y_vinewood_04', 'a_m_y_yoga_01',
    'csb_anita', 'csb_anton', 'csb_ballasog', 'csb_bride',
    'csb_burgerdrug', 'csb_car3guy1', 'csb_car3guy2', 'csb_chef',
    'csb_chin_goon', 'csb_cletus', 'csb_cop', 'csb_customer',
    'csb_denise_friend', 'csb_fos_rep', 'csb_g', 'csb_groom',
    'csb_grove_str_dlr', 'csb_hao', 'csb_hugh', 'csb_imran',
    'csb_janitor', 'csb_maude', 'csb_mweather', 'csb_ortega',
    'csb_oscar', 'csb_porndudes', 'csb_prologuedriver', 'csb_prolsec',
    'csb_ramp_gang', 'csb_ramp_hic', 'csb_ramp_hipster', 'csb_ramp_marine',
    'csb_ramp_mex', 'csb_reporter', 'csb_roccopelosi', 'csb_screen_writer',
    'csb_stripper_01', 'csb_stripper_02', 'csb_tonya', 'csb_trafficwarden',
    'g_f_y_ballas_01', 'g_f_y_families_01', 'g_f_y_lost_01',
    'g_f_y_vagos_01', 'g_m_m_armboss_01', 'g_m_m_armgoon_01',
    'g_m_m_armlieut_01', 'g_m_m_chemwork_01', 'g_m_m_chiboss_01',
    'g_m_m_chicold_01', 'g_m_m_chigoon_01', 'g_m_m_chigoon_02',
    'g_m_m_korboss_01', 'g_m_m_mexboss_01', 'g_m_m_mexboss_02',
    'g_m_y_armgoon_02', 'g_m_y_azteca_01', 'g_m_y_ballaeast_01',
    'g_m_y_ballaorig_01', 'g_m_y_ballasout_01', 'g_m_y_famca_01',
    'g_m_y_famdnf_01', 'g_m_y_famfor_01', 'g_m_y_korean_01',
    'g_m_y_korean_02', 'g_m_y_korlieut_01', 'g_m_y_lost_01',
    'g_m_y_lost_02', 'g_m_y_lost_03', 'g_m_y_mexgang_01',
    'g_m_y_mexgoon_01', 'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03',
    'g_m_y_pologoon_01', 'g_m_y_pologoon_02', 'g_m_y_salvaboss_01',
    'g_m_y_salvagoon_01', 'g_m_y_salvagoon_02', 'g_m_y_salvagoon_03',
    'g_m_y_strpunk_01', 'g_m_y_strpunk_02',
    'ig_abigail', 'ig_amandatownley', 'ig_andreas', 'ig_ashley',
    'ig_ballasog', 'ig_bankman', 'ig_barry', 'ig_bestmen',
    'ig_beverly', 'ig_brad', 'ig_bride', 'ig_car3guy1',
    'ig_casey', 'ig_chef', 'ig_claypain', 'ig_clay',
    'ig_cletus', 'ig_dale', 'ig_davenorton', 'ig_denise',
    'ig_devin', 'ig_dom', 'ig_dreyfuss', 'ig_drfriedlander',
    'ig_fabien', 'ig_fbisuit_01', 'ig_floyd', 'ig_groom',
    'ig_hao', 'ig_hunter', 'ig_janet', 'ig_jay_norris',
    'ig_jewelass', 'ig_jimmyboston', 'ig_jimmydisanto', 'ig_joeminuteman',
    'ig_johnnyklebitz', 'ig_josef', 'ig_josh', 'ig_kerrymcintosh',
    'ig_lamardavis', 'ig_lazlow', 'ig_lestercrest', 'ig_lifeinvad_01',
    'ig_lifeinvad_02', 'ig_magenta', 'ig_manuel', 'ig_marnie',
    'ig_maryann', 'ig_maude', 'ig_michelle', 'ig_milton',
    'ig_molly', 'ig_mrk', 'ig_mrsphillips', 'ig_mrs_thornhill',
    'ig_natalia', 'ig_nervousron', 'ig_nigel', 'ig_old_man1a',
    'ig_old_man2', 'ig_omega', 'ig_oneil', 'ig_orleans',
    'ig_ortega', 'ig_paper', 'ig_patricia', 'ig_priest',
    'ig_prolsec_02', 'ig_ramp_gang', 'ig_ramp_hic', 'ig_ramp_hipster',
    'ig_ramp_mex', 'ig_roccopelosi', 'ig_russiandrunk', 'ig_screen_writer',
    'ig_siemonyetarian', 'ig_solomon', 'ig_stevehains', 'ig_stretch',
    'ig_talina', 'ig_tanisha', 'ig_taocheng', 'ig_taostranslator',
    'ig_tenniscoach', 'ig_terry', 'ig_tomepsilon', 'ig_tonya',
    'ig_tracydisanto', 'ig_tylerdix', 'ig_wade', 'ig_zimbor',
    'mp_f_boatstaff_01', 'mp_f_deadhooker', 'mp_f_freemode_01',
    'mp_f_misty_01', 'mp_f_stripperlite',
    'mp_g_m_pros_01', 'mp_m_claude_01', 'mp_m_exarmy_01',
    'mp_m_famdd_01', 'mp_m_fibsec_01', 'mp_m_freemode_01',
    'mp_m_marston_01', 'mp_m_niko_01', 'mp_m_shopkeep_01',
    'mp_s_m_armoured_01',
    's_f_m_fembarber', 's_f_m_maid_01', 's_f_m_shop_high',
    's_f_m_sweatshop_01', 's_f_y_airhostess_01', 's_f_y_bartender_01',
    's_f_y_baywatch_01', 's_f_y_cop_01', 's_f_y_factory_01',
    's_f_y_hooker_01', 's_f_y_hooker_02', 's_f_y_hooker_03',
    's_f_y_migrant_01', 's_f_y_movprem_01', 's_f_y_ranger_01',
    's_f_y_scrubs_01', 's_f_y_sheriff_01', 's_f_y_shop_low',
    's_f_y_shop_mid', 's_f_y_stripper_01', 's_f_y_stripper_02',
    's_f_y_sweatshop_01',
    's_m_m_ammucountry', 's_m_m_armoured_01', 's_m_m_armoured_02',
    's_m_m_autoshop_01', 's_m_m_autoshop_02', 's_m_m_bouncer_01',
    's_m_m_chemsec_01', 's_m_m_ciasec_01', 's_m_m_cntrybar_01',
    's_m_m_dockwork_01', 's_m_m_doctor_01', 's_m_m_fiboffice_01',
    's_m_m_fiboffice_02', 's_m_m_gaffer_01', 's_m_m_gardener_01',
    's_m_m_gentransport', 's_m_m_hairdress_01', 's_m_m_highsec_01',
    's_m_m_highsec_02', 's_m_m_janitor', 's_m_m_lathandy_01',
    's_m_m_lifeinvad_01', 's_m_m_linecook', 's_m_m_lsmetro_01',
    's_m_m_mariachi_01', 's_m_m_marine_01', 's_m_m_marine_02',
    's_m_m_migrant_01', 's_m_m_movalien_01', 's_m_m_movprem_01',
    's_m_m_movspace_01', 's_m_m_paramedic_01', 's_m_m_pilot_01',
    's_m_m_pilot_02', 's_m_m_postal_01', 's_m_m_postal_02',
    's_m_m_prisguard_01', 's_m_m_scientist_01', 's_m_m_security_01',
    's_m_m_snowcop_01', 's_m_m_strperf_01', 's_m_m_strpreach_01',
    's_m_m_strvend_01', 's_m_m_trucker_01', 's_m_m_ups_01',
    's_m_m_ups_02',
    's_m_o_busker_01',
    's_m_y_airworker', 's_m_y_ammucity_01', 's_m_y_armymech_01',
    's_m_y_autopsy_01', 's_m_y_barman_01', 's_m_y_baywatch_01',
    's_m_y_blackops_01', 's_m_y_blackops_02', 's_m_y_blackops_03',
    's_m_y_busboy_01', 's_m_y_chef_01', 's_m_y_clown_01',
    's_m_y_construct_01', 's_m_y_construct_02', 's_m_y_cop_01',
    's_m_y_dealer_01', 's_m_y_devinsec_01', 's_m_y_dockwork_01',
    's_m_y_doorman_01', 's_m_y_dwservice_01', 's_m_y_dwservice_02',
    's_m_y_factory_01', 's_m_y_fireman_01', 's_m_y_garbage',
    's_m_y_grip_01', 's_m_y_hwaycop_01', 's_m_y_marine_01',
    's_m_y_marine_02', 's_m_y_marine_03', 's_m_y_mime',
    's_m_y_pestcont_01', 's_m_y_pilot_01', 's_m_y_prismuscl_01',
    's_m_y_prisoner_01', 's_m_y_ranger_01', 's_m_y_robber_01',
    's_m_y_sheriff_01', 's_m_y_shop_mask', 's_m_y_strvend_01',
    's_m_y_surfer_01', 's_m_y_swat_01', 's_m_y_uscg_01',
    's_m_y_valet_01', 's_m_y_waiter_01', 's_m_y_winclean_01',
    's_m_y_xmech_01', 's_m_y_xmech_02',
    'u_f_m_corpse_01', 'u_f_m_miranda', 'u_f_m_promourn_01',
    'u_f_o_moviestar', 'u_f_o_prolhost_01', 'u_f_y_bikerchic',
    'u_f_y_comjane', 'u_f_y_corpse_01', 'u_f_y_corpse_02',
    'u_f_y_hotposh_01', 'u_f_y_jewelass_01', 'u_f_y_mistress',
    'u_f_y_poppymich', 'u_f_y_princess', 'u_f_y_spyactress',
    'u_m_m_aldinapoli', 'u_m_m_bankman', 'u_m_m_bikehire_01',
    'u_m_m_fibarchitect', 'u_m_m_filmdirector', 'u_m_m_glenstank_01',
    'u_m_m_griff_01', 'u_m_m_jesus_01', 'u_m_m_jewelsec_01',
    'u_m_m_jewelthief', 'u_m_m_markfost', 'u_m_m_partytarget',
    'u_m_m_prolsec_01', 'u_m_m_promourn_01', 'u_m_m_rivalpap',
    'u_m_m_spyactor', 'u_m_m_willyfist',
    'u_m_o_finguru_01', 'u_m_o_taphillbilly', 'u_m_o_tramp_01',
    'u_m_y_abner', 'u_m_y_antonb', 'u_m_y_babyd', 'u_m_y_baygor',
    'u_m_y_burgerdrug_01', 'u_m_y_chip', 'u_m_y_cyclist_01',
    'u_m_y_fibmugger_01', 'u_m_y_guido_01', 'u_m_y_gunvend_01',
    'u_m_y_hippie_01', 'u_m_y_imporage', 'u_m_y_justin',
    'u_m_y_mani', 'u_m_y_militarybum', 'u_m_y_paparazzi',
    'u_m_y_party_01', 'u_m_y_pogo_01', 'u_m_y_prisoner_01',
    'u_m_y_proldriver_01', 'u_m_y_rsranger_01', 'u_m_y_sbike',
    'u_m_y_staggrm_01', 'u_m_y_tattoo_01', 'u_m_y_zombie_01',
}

-- Clothing component categories
local CLOTHING_CATEGORIES = {
    { id = 'mask_1',     component = 1,  type = 'CLOTHING', label = 'Masques' },
    { id = 'arms',       component = 3,  type = 'CLOTHING', label = 'Bras' },
    { id = 'pants_1',    component = 4,  type = 'CLOTHING', label = 'Pantalons' },
    { id = 'bags_1',     component = 5,  type = 'CLOTHING', label = 'Sacs' },
    { id = 'shoes_1',    component = 6,  type = 'CLOTHING', label = 'Chaussures' },
    { id = 'chain_1',    component = 7,  type = 'CLOTHING', label = 'Accessoires' },
    { id = 'tshirt_1',   component = 8,  type = 'CLOTHING', label = 'Sous-vêtements' },
    { id = 'bproof_1',   component = 9,  type = 'CLOTHING', label = 'Gilets' },
    { id = 'decals_1',   component = 10, type = 'CLOTHING', label = 'Décals' },
    { id = 'torso_1',    component = 11, type = 'CLOTHING', label = 'Hauts' },
    { id = 'helmet_1',   component = 0,  type = 'PROPS',    label = 'Chapeaux' },
    { id = 'glasses_1',  component = 1,  type = 'PROPS',    label = 'Lunettes' },
    { id = 'ears_1',     component = 2,  type = 'PROPS',    label = 'Oreilles' },
    { id = 'watches_1',  component = 6,  type = 'PROPS',    label = 'Montres' },
    { id = 'bracelets_1',component = 7,  type = 'PROPS',    label = 'Bracelets' },
}

-- Utils categories (character customization)
--   Pour les overlays (sourcils/barbe/etc.), `componentId` est l'ID du head
--   overlay GTA (cf. SetPedHeadOverlay). Pour 'hair' c'est l'ID du composant
--   ped (component 2). Pour 'tattoos', c'est un cas spécial, sans componentId
--   utile (la liste est gérée à part via `tattoosList`).
local UTILS_CATEGORIES = {
    { id = 'hair',      label = 'Cheveux',             componentId = 2,  colorId = 0,  highlightId = 1 },
    { id = 'eyebrows',  label = 'Sourcils',            componentId = 2,  opacityId = 3, colorId = 1 },
    { id = 'beard',     label = 'Barbe',               componentId = 1,  opacityId = 2, colorId = 1 },
    { id = 'chesthair', label = 'Pilosité corporelle', componentId = 10, opacityId = 11, colorId = 1 },
    { id = 'lipstick',  label = 'Rouge à lèvres',      componentId = 8,  opacityId = 9, colorId = 2 },
    { id = 'makeup',    label = 'Maquillage',          componentId = 4,  opacityId = 5, colorId = 2 },
    { id = 'blush',     label = 'Blush',               componentId = 5,  opacityId = 6, colorId = 2 },
    { id = 'tattoos',   label = 'Tatouages',           componentId = -1 },
}

-- ============================================================================
-- TATTOO LIST BUILDER
--   Aplatit `Config.Tattoo.TattooList` en deux listes (male / female) où
--   chaque entrée est `{ collection, nameHash, zone }`. Le client utilise ça
--   pour appliquer le tatouage et cadrer la caméra sur la bonne zone.
--
--   Détection :
--     - genre   → suffixe `_M`/`_F` (insensible casse) — sinon les deux
--     - zone    → mots-clés dans le nameHash (Hair/Neck/Chest/Stom/Back/
--                 LArm/RArm/LLeg/RLeg/Award/...). Si rien ne matche on
--                 retombe sur "torso" (cadre poitrine large).
-- ============================================================================
local function detectTattooGender(name)
    local n = name or ''
    if n:match('_M_') or n:match('_M$') or n:match('_M%d') then return 'male' end
    if n:match('_F_') or n:match('_F$') or n:match('_F%d') then return 'female' end
    return 'both'
end

local function detectTattooZone(name)
    local n = string.lower(name or '')
    if n:find('hair')                                      then return 'hair'    end
    if n:find('neck')                                      then return 'neck'    end
    if n:find('back')                                      then return 'back'    end
    if n:find('chest') or n:find('bust')                   then return 'chest'   end
    if n:find('stom')                                      then return 'stomach' end
    if n:find('larm') or n:find('leftarm')  or n:find('l_arm')  then return 'larm' end
    if n:find('rarm') or n:find('rightarm') or n:find('r_arm')  then return 'rarm' end
    if n:find('lleg') or n:find('leftleg')  or n:find('l_leg')  then return 'lleg' end
    if n:find('rleg') or n:find('rightleg') or n:find('r_leg')  then return 'rleg' end
    return 'torso'
end

local function buildTattooLists()
    local male, female = {}, {}
    if not (Config and Config.Tattoo and Config.Tattoo.TattooList) then
        return { male = male, female = female }
    end
    for collection, items in pairs(Config.Tattoo.TattooList) do
        for _, item in ipairs(items) do
            local nameHash = item.nameHash
            if nameHash then
                local g = detectTattooGender(nameHash)
                local entry = {
                    collection = collection,
                    nameHash   = nameHash,
                    zone       = detectTattooZone(nameHash),
                }
                if g == 'male'   or g == 'both' then table.insert(male, entry)   end
                if g == 'female' or g == 'both' then table.insert(female, entry) end
            end
        end
    end
    return { male = male, female = female }
end

local TATTOO_LISTS = buildTattooLists()

-- Camera settings per component (from original config.json)
local CAMERA_SETTINGS = {
    CLOTHING = {
        [1]  = { fov = 30, zPos = 0.65,  rotation = { x = 0, y = 0, z = 300 } },
        [3]  = { fov = 55, zPos = 0.3,   rotation = { x = 0, y = 0, z = 335 } },
        [4]  = { fov = 60, zPos = -0.46,  rotation = { x = 0, y = 0, z = 335 } },
        [5]  = { fov = 40, zPos = 0.3,   rotation = { x = 0, y = 0, z = 155 } },
        [6]  = { fov = 40, zPos = -0.85,  rotation = { x = 0, y = 0, z = 300 } },
        [7]  = { fov = 45, zPos = 0.3,   rotation = { x = 0, y = 0, z = 335 } },
        [8]  = { fov = 45, zPos = 0.3,   rotation = { x = 0, y = 0, z = 335 } },
        [9]  = { fov = 45, zPos = 0.3,   rotation = { x = 0, y = 0, z = 335 } },
        [10] = { fov = 65, zPos = 0.25,  rotation = { x = 0, y = 0, z = 340 } },
        [11] = { fov = 55, zPos = 0.26,  rotation = { x = 0, y = 0, z = 335 } },
    },
    PROPS = {
        [0] = { fov = 30, zPos = 0.75,   rotation = { x = 0, y = 0, z = 300 } },
        [1] = { fov = 20, zPos = 0.7,    rotation = { x = 0, y = 0, z = 300 } },
        [2] = { fov = 20, zPos = 0.675,  rotation = { x = 0, y = 0, z = 57.5 } },
        [6] = { fov = 20, zPos = 0.03,   rotation = { x = 0, y = 0, z = 239 } },
        [7] = { fov = 20, zPos = 0.03,   rotation = { x = 0, y = 0, z = 70 } },
    },
}

-- Green screen positions
local GREEN_SCREEN = {
    position = vector3(-1289.02, -3409.83, 20.91),
    rotation = vector3(0.0, 0.0, 330.0),
    vehiclePosition = vector3(-1269.58, -3383.08, 14.13),
    vehicleRotation = vector3(0.0, 0.0, 254.03),
    hiddenSpot = vector3(-1224.22, -3349.63, 13.96),
}

-- Provide config data to client
ESX.RegisterServerCallback('null:imagemaker:getConfig', function(source, cb)
    cb({
        weaponList = WEAPON_LIST,
        pedList = PED_LIST,
        clothingCategories = CLOTHING_CATEGORIES,
        utilsCategories = UTILS_CATEGORIES,
        cameraSettings = CAMERA_SETTINGS,
        greenScreen = GREEN_SCREEN,
        tattoosList = TATTOO_LISTS, -- { male = {...}, female = {...} }
    })
end)

RegisterNetEvent('null:imagemaker:restart:cache', function()
    local src = source
    if src ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer.getPermission("dev") then return end
    end
    ExecuteCommand('ensure null-cache')
end)

null.InitPrint("ImageMaker Server Module Loaded")
