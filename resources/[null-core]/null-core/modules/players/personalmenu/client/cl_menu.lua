local pma = exports["null-deps"]
local currentChannel = 0
local itemCooldown = false
local radioCheckCache = { value = nil, lastCheck = 0 }
local RADIO_CACHE_DURATION = 5000 -- 5 secondes de cache
local inPersoMenu = false
local phoneProp = 0
local phoneModel = "prop_cs_hand_radio"
local coupCrosse = false
local propsPropsList = {}
local propsPropsListCount = 0
RageUIStyleIndex = 1
RageUIStyleIndex2 = 1
local revealedbank = false
local packGraphiqueIndexs = 1
local packGraphique = GetResourceKvpString(ESX.Config("serverName")..":null:graphique:index")
if packGraphique == nil then 
    packGraphique = "default" 
    SetResourceKvp(ESX.Config("serverName")..":null:graphique:index", "default")
else
    --[[if packGraphique ~= "default" then
        SetTimecycleModifier(packGraphique)
        SetTimecycleModifierStrength(1.0)
        if packGraphique == "yell_tunnel_nodirect" then
            packGraphiqueIndexs = 2
        elseif packGraphique == "cinema" then
            packGraphiqueIndexs = 3
        else
            packGraphiqueIndexs = 1
        end
    end]]
end

RegisterNetEvent("Bipeur:DeleteInv")
AddEventHandler("Bipeur:DeleteInv", function()
    RageUI.CloseAll()
    mainf5 = false
end)

local cacheRemoveAccesories = {}
local cacheViewAccesories = {}

--local isload = exports["null-core"]:isload() local count = 0 while isload == false do count = count + 1 if count > 10 then break end Wait(1000) end if not isload then print("Probleme avec le chargement de l'API") while true do Wait(1000) end end

personalMenu = {
    Indexaccesories = 1,
    IndexgestionAccesories = 1,
    IndexClothes = 1,
    Indexinvetory = 1,
    IndexVetement = 1,
    Accesoires = 1,
    StyleMenu = 1,
    IndexAim = 1,
    IndexAim2 = 1,
    Indexdoor = 1,
    LimitateurIndex = 1,
    Item = true,
    Weapon = true,
    Radar = true,
    Vetement = true,
    AccesoiresMenu = true,
    Report = true,
    ui = true,
    Nullinterface = true,
    TickRadio = false,
    InfosRadio = false,
    Bruitages = true,
    Statut = "~g~Allumé",
    VolumeRadio = 1,

    DoorState = {
        FrontLeft = false,
        FrontRight = false,
        BackLeft = false,
        BackRight = false,
        Hood = false,
        Trunk = false
    },

    voiture_limite = {
        "50 km/h",
        "80 km/h",
        "130 km/h",
        "Personalisée",
        "Désactiver"
    },
}
Masque = true 


local selected = nil
local weaponCache = {}


Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    Wait(1000) 

    local weaponList = ESX.GetWeaponList()
    if weaponList then
        for _, v in pairs(weaponList) do

            if v and v.name then
                weaponCache[GetHashKey(v.name)] = v
            end
        end
    end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    Wait(2000) 
    
    local lastWeapon = 0
    local unarmedHash = GetHashKey("weapon_unarmed")
    
    while true do
        Citizen.Wait(500) 
        
        local weapon = GetSelectedPedWeapon(PlayerPedId())
        
        if weapon ~= lastWeapon then
            lastWeapon = weapon
            
            if weapon ~= unarmedHash and weapon ~= 966099553 and weapon ~= 0 then
                selected = weaponCache[weapon]
            else
                selected = nil
            end
        end
    end
end))


local Couldown = false
local canDelete = false

local pedmodel = { -- CONFIG PED NAME = AFFICHAGE / MODEL = MODEL DU PED POUR LE SPAWN / PICTUREMODEL = NOM DU STREAM DE LA PHOTO
    {name = "Personnage Homme #1", model = "a_m_y_downtown_01", picturemodel = 'tonton'},
    {name = "Personnage Homme #2", model = "u_m_y_babyd", picturemodel = 'BabyD'},
    {name = "Personnage Homme #3", model = "ig_priest", picturemodel = 'priest'},
    {name = "Personnage Homme #4", model = "u_m_y_prisoner_01", picturemodel = 'Prisoner01'},
    {name = "Personnage Homme #5", model = "s_m_y_prisoner_01", picturemodel = 'Prisoner01SMY'},
    {name = "Personnage Homme #6", model = "ig_rashcosvki", picturemodel = 'rashkovsky'},
    {name = "Personnage Homme #7", model = "u_m_y_militarybum", picturemodel = 'militarybum'},
    {name = "Personnage Homme #8", model = "mp_m_waremech_01", picturemodel = 'mp_m_waremech_01'},
    {name = "Personnage Homme #9", model = "mp_m_weapexp_01", picturemodel = 'Mp_m_weapexp_01'},
    {name = "Personnage Homme #10", model = "mp_m_weapwork_01", picturemodel = 'Mp_m_weapwork_01'},
    {name = "Personnage Homme #11", model = "ig_benny", picturemodel = 'Benny'},
    {name = "Personnage Homme #12", model = "s_m_y_dealer_01", picturemodel = 'Dealer01SMY'},
    {name = "Personnage Homme #13", model = "ig_lestercrest", picturemodel = 'lestercrest'},
    {name = "Personnage Homme #14", model = "g_m_m_chicold_01", picturemodel = 'BabyD'},
    {name = "Personnage Homme #15", model = "g_m_m_chicold_01", picturemodel = 'ChiCold01GMM'},
    {name = "Personnage Homme Ballas #1", model = "g_m_y_ballaeast_01", picturemodel = 'BallaEast01GMY'},
    {name = "Personnage Homme Ballas #2", model = "g_m_y_ballaorig_01", picturemodel = 'BallaOrig01GMY'},
    {name = "Personnage Homme Ballas #3", model = "ig_ballasog", picturemodel = 'BallasOG'},
    {name = "Personnage Homme Ballas #4", model = "g_m_y_ballasout_01", picturemodel = 'BallaSout01GMY'},
    {name = "Personnage Homme Families #1", model = "g_m_y_famca_01", picturemodel = 'famca01'},
    {name = "Personnage Homme Families #2", model = "g_m_y_famdnf_01", picturemodel = 'famdnf01'},
    {name = "Personnage Homme Families #3", model = "g_m_y_famfor_01", picturemodel = 'famfor01'},
    {name = "Personnage Femme Families #1", model = "g_f_y_families_01", picturemodel = 'families01'},
    {name = "Personnage Homme Marabunta #1", model = "g_m_y_salvaboss_01", picturemodel = 'SalvaBoss01'},
    {name = "Personnage Homme Marabunta #2", model = "g_m_y_salvagoon_01", picturemodel = 'SalvaGoon01'},
    {name = "Personnage Homme Marabunta #3", model = "g_m_y_salvagoon_02", picturemodel = 'SalvaGoon02'},
    {name = "Personnage Homme Marabunta #4", model = "g_m_y_salvagoon_03", picturemodel = 'SalvaGoon03'},
    {name = "Personnage Homme Vagos #1", model = "g_m_y_mexgoon_01", picturemodel = 'mexgoon01'},
    {name = "Personnage Homme Vagos #2", model = "g_m_y_mexgoon_02", picturemodel = 'mexgoon02'},
    {name = "Personnage Homme Vagos #3", model = "g_m_y_mexgoon_03", picturemodel = 'mexgoon03'},
    {name = "Personnage Homme #16", model = "a_m_m_mexlabor_01", picturemodel = 'mexlabor01'},
    {name = "Personnage Homme #17", model = "a_m_y_mexthug_01", picturemodel = 'mexthug01'},
    {name = "Personnage Homme #18", model = "g_m_m_mexboss_01", picturemodel = 'mexboss01'},
    {name = "Personnage Homme #19", model = "g_m_m_mexboss_02", picturemodel = 'mexboss02'},
    {name = "Personnage Homme #20", model = "a_m_m_mexcntry_01", picturemodel = 'mexcntry01'},
    {name = "Personnage Homme #21", model = "g_m_y_mexgang_01", picturemodel = 'mexgang01'},
    {name = "Personnage Homme #22", model = "ig_ramp_mex", picturemodel = 'rampmex'},
    {name = "Personnage Homme #23", model = "a_m_m_eastsa_01", picturemodel = 'EastSA01AMM'},
    {name = "Personnage Homme #24", model = "a_m_y_eastsa_01", picturemodel = 'Eastsa01AMY'},
    {name = "Personnage Homme #25", model = "a_m_m_eastsa_02", picturemodel = 'EastSa02AMM'},
    {name = "Personnage Femme #1", model = "a_f_y_eastsa_03", picturemodel = 'eastsa03afy'},
    {name = "Personnage Femme #2", model = "a_f_y_eastsa_02", picturemodel = 'EastSA02AFY'},
    {name = "Personnage Homme #26", model = "a_m_m_beach_01", picturemodel = 'Beach01AMM'},
    {name = "Personnage Homme #27", model = "a_m_m_beach_02", picturemodel = 'Beach02AMM'},
    {name = "Personnage Homme #28", model = "a_m_o_beach_01", picturemodel = 'Beach01AMO'},
    {name = "Personnage Homme #29", model = "a_m_y_beach_01", picturemodel = 'Beach01AMY'},
    {name = "Personnage Homme #30", model = "a_m_y_beach_02", picturemodel = 'Beach02AMY'},
    {name = "Personnage Femme #3", model = "s_f_y_baywatch_01", picturemodel = 'BayWatch01SFY'},
    {name = "Personnage Femme #4", model = "a_f_m_beach_01", picturemodel = 'Beach01AFM'},
    {name = "Personnage Homme #31", model = "s_m_y_doorman_01", picturemodel = 'Doorman01SMY'},
    {name = "Personnage Homme #32", model = "s_m_y_clown_01", picturemodel = 'Clown01SMY'},
    {name = "Personnage Femme #5", model = "a_f_m_bevhills_01", picturemodel = 'BevHills01AFM'},
    {name = "Personnage Femme #6", model = "mp_f_boatstaff_01", picturemodel = 'BoatStaff01F'},
    {name = "Personnage Femme #7", model = "a_f_y_bevhills_01", picturemodel = 'Bevhills01AFY'},
    {name = "Personnage Femme #8", model = "a_f_m_bevhills_02", picturemodel = 'BevHills02AFM'},
    {name = "Personnage Femme #9", model = "a_f_y_bevhills_02", picturemodel = 'BevHills02AFY'},
    {name = "Personnage Femme #10", model = "a_f_y_bevhills_03", picturemodel = 'Bevhills03AFY'},
    {name = "Personnage Femme #11", model = "a_f_y_bevhills_04", picturemodel = 'BevHills04AFY'},
    {name = "Personnage Femme #12", model = "u_f_y_bikerchic", picturemodel = 'BikerChic'},
    {name = "Bébé", model = "skin_baby", picturemodel = ''},
    {name = "Enfant", model = "skin_child", picturemodel = ''},
}

local itemIndex = 1

local legalprops = { ---- Props catégorie légal / nameprops = 'Nom visible par le joueur' / modelprops = 'Model_du_props'
    {nameprops = 'Chaise', modelprops = 'apa_mp_h_din_chair_12'},
    {nameprops = 'Carton', modelprops = 'prop_cardbordbox_04a'},
    {nameprops = 'Sac', modelprops = 'prop_cs_heist_bag_02'},
    {nameprops = 'Table 1', modelprops = 'prop_rub_table_02'},
    {nameprops = 'Table 2', modelprops = 'prop_table_04'},
    {nameprops = 'Table 3', modelprops = 'bkr_prop_weed_table_01b'},
    {nameprops = 'Chaise 1', modelprops = 'bkr_prop_clubhouse_chair_01'},
    {nameprops = 'Chaise 2', modelprops = 'bkr_prop_weed_chair_01a'},
    {nameprops = 'Chaise de Pêche', modelprops = 'hei_prop_hei_skid_chair'},
    {nameprops = 'Chaise de Bureau', modelprops = 'bkr_prop_clubhouse_offchair_01a'},
    {nameprops = 'Canapé', modelprops = 'v_tre_sofa_mess_c_s'},
    {nameprops = 'Canapé 2', modelprops = 'v_res_tre_sofa_mess_a'},
    {nameprops = 'Ordinateur', modelprops = 'bkr_prop_clubhouse_laptop_01a'},
    {nameprops = 'Lit', modelprops = 'gr_prop_bunker_bed_01'},
    {nameprops = 'Outils', modelprops = 'prop_cs_trolley_01'},
    {nameprops = 'Outils de mécanique', modelprops = 'prop_carcreeper'},
    {nameprops = 'Sac de sport', modelprops = 'prop_cs_heist_bag_02'},
    {nameprops = 'Trousse médical 2', modelprops = 'xm_prop_x17_bag_med_01a'},
    {nameprops = 'TV', modelprops = 'prop_tv_flat_01'},
    {nameprops = 'TV 2', modelprops = 'prop_tv_flat_michael'},
    {nameprops = 'TV 3', modelprops = 'prop_trev_tv_01'},
    {nameprops = 'TV 4', modelprops = 'prop_tv_flat_03b'},
    {nameprops = 'TV 5', modelprops = 'prop_tv_flat_03'},
    {nameprops = 'TV 6', modelprops = 'prop_tv_flat_02b'},
    {nameprops = 'TV 7', modelprops = 'prop_tv_flat_02'},
    
}

local illegalprops = { ---- Props catégorie illégal / nameprops = 'Nom visible par le joueur' / modelprops = 'Model_du_props'
    {nameprops = 'Bloque de cocaïne', modelprops = 'bkr_prop_coke_block_01a'},
    {nameprops = 'Bouteille de cocaïne', modelprops = 'bkr_prop_coke_bottle_01a'},
    {nameprops = 'Balance', modelprops = 'bkr_prop_coke_scale_01'},
    {nameprops = 'Table cocaine', modelprops = 'bkr_prop_coke_table01a'},
    {nameprops = 'Caisse', modelprops = 'bkr_prop_crate_set_01a'},
    {nameprops = 'Pot Weed 2', modelprops = 'bkr_prop_weed_bucket_01d'},
    {nameprops = 'Cocaine', modelprops = 'bkr_prop_coke_block_01a'},
    {nameprops = 'Acétone', modelprops = 'bkr_prop_meth_acetone'},
    {nameprops = 'Bidon', modelprops = 'bkr_prop_meth_ammonia'},
    {nameprops = 'Lithium', modelprops = 'bkr_prop_meth_lithium'},
    {nameprops = 'Packet de weed', modelprops = 'bkr_prop_weed_bigbag_03a'},
    {nameprops = 'Packet de weed Ouvert', modelprops = 'bkr_prop_weed_bigbag_open_01a'},
    {nameprops = 'Chanvre', modelprops = 'bkr_prop_weed_lrg_01b'},
    {nameprops =  'Weed séchée', modelprops = 'bkr_prop_weed_drying_01a'},
    {nameprops = 'Sac de weed', modelprops = 'bkr_prop_weed_bigbag_03a'},
    {nameprops = 'Block de coke', modelprops = 'bkr_prop_coke_cut_01'},
    {nameprops = 'Weed', modelprops = 'bkr_prop_weed_01_small_01b'},
    {nameprops = 'Malette d\'armes', modelprops = 'bkr_prop_biker_gcase_s'},
    {nameprops = 'Caisse d\'armes lourdes', modelprops = 'ex_office_swag_guns04'},
    {nameprops = 'Caisse Fermée', modelprops = 'ex_prop_adv_case_sm_03'},
    {nameprops = 'Caisse de chargeurs', modelprops = 'gr_prop_gr_crate_mag_01a'},
}

object = {}

local Options = {
    List1 = 1
}


local Customs = {
    List1 = 1,
    List2 = 1,
    List4 = 1,
    List5 = 1,
    List6 = 1,
    List7 = 1, 
    List8 = 1
}

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while not coupCrosse do
        local ped = PlayerPedId()
        local isArmed = IsPedArmed(ped, 6)
        
        if isArmed then
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
            Wait(0)  
        else
            Wait(500)  
        end
    end
end))

function getInPersoMenu()
    return inPersoMenu
end
RegisterNetEvent('Zetalife:recieveProps', function(table)
    propsPropsList = table

    propsPropsListCount = 0
    for k,v in pairs(propsPropsList) do
        propsPropsListCount = propsPropsListCount + 1
    end
end)

SocietyList = {}
entreprisecount = 0

Citizen.CreateThread(function()
    ESX.TriggerServerCallback("Core:GetSociety", function(result) 
        SocietyList = result
        DataLoaded = true
    end)
end)

local BillData = {}


function SpawnPed(pedname)
    if pedname == nil then return end
    local j1 = PlayerId()
    local p1 = GetHashKey(pedname)
    RequestModel(p1)
    while not HasModelLoaded(p1) do
        Wait(100)
        end
        SetPlayerModel(j1, p1)
        SetModelAsNoLongerNeeded(p1)
        TriggerEvent('esx:restoreLoadout')
        Citizen.Wait(500)
end

function InputPed()
    local j1 = PlayerId()
    local newped = null.fct.input("Noms Peds")
    if newped == nil then return end
    local p1 = GetHashKey(newped)
    RequestModel(p1)
    Citizen.Wait(200)
    while not HasModelLoaded(p1) do
        Wait(100)
        end
        SetPlayerModel(j1, p1)
        Citizen.Wait(200)
        SetModelAsNoLongerNeeded(p1)
        Wait(100)
        ESX.ShowNotification("~r~Ped changé avec succès !") 
        TriggerEvent('esx:restoreLoadout')
        Wait(100)
        RageUI.CloseAll()
end

function SetCus(ped, componentId, drawableId, textureId, paletteId)
    SetPedComponentVariation(ped, componentId, drawableId, textureId, paletteId)
end

function SetProp(ped,componentId,drawableId,TextureId,attach)
    SetPedPropIndex(ped,componentId,drawableId,TextureId,attach)
end


function Clear(ped,propId)
    ClearPedProp(ped,propId)
end

function ResetPed()
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
        local isMale = skin.sex == 0

        TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('Null:skinchanger:loadSkin', skin)
                TriggerEvent('esx:restoreLoadout')
                Citizen.Wait(200)
                ESX.ShowNotification("~r~Votre personnage a été rénitialisé ...") 
            end)
        end)
    end)
end
local indexxxx = 1


AddEventHandler("null:inventory:closeinv", function ()
    RageUI.CloseAll()
end)

local isvip, viptype = false, "Basic"
openMenuF5 = LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    if ESX.getIsDead() then return end
    if PlayerState.inSceneMortRP then return end

    if getInZoneGF() then return end

   -- RageUIStyleIndex = getRageUIStyleIndex()

    if not null.cooldown then
        null.fct.cooldown(5000)
        ESX.TriggerServerCallback("Core:GetSociety", function(result) 
            SocietyList = result
            entreprisecount = 0

            for k,v in pairs(result) do
                if not v.state == false then
                    entreprisecount = entreprisecount + 1
                end
            end
        end)
    end

    local mainf5 = RageUI.CreateMenu("", "Voici les actions disponibles")
    local streamerMenu = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local vipMenu = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local openVipPeds = RageUI.CreateSubMenu(vipMenu, "", "Voici les actions disponibles")
    local openVipPeds2 = RageUI.CreateSubMenu(streamerMenu, "", "Voici les actions disponibles")
    --Menu Principaux
    local invetory = RageUI.CreateSubMenu(mainf5, "", "Voici votre inventaire")
    local guideSubMenu = RageUI.CreateSubMenu(mainf5, '', "Voici les actions disponibles")
    local portefeuille = RageUI.CreateSubMenu(mainf5, "", "Voici votre portefeuille")
    local vehicle = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local vetmenu = RageUI.CreateSubMenu(mainf5, "", "Actions vêtements")
    local radio = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local diversmenu = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local preferenceSubMenu = RageUI.CreateSubMenu(diversmenu, "", "Voici les actions disponibles")
    local blipsGestion = RageUI.CreateSubMenu(preferenceSubMenu, "", "Voici les actions disponibles")
    local walksList = RageUI.CreateSubMenu(diversmenu, "", "Voici les actions disponibles")
    local weaponsBind = RageUI.CreateSubMenu(diversmenu, '', "Voici les actions disponibles")
    local weaponsBindList = RageUI.CreateSubMenu(weaponsBind, '', "Voici les actions disponibles")

    local statusentreprise = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")

    local esthetiquemenu = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")
    local PedsSubMenu = RageUI.CreateSubMenu(esthetiquemenu, "", "Voici les actions disponibles")
    local PropsSubMenu = RageUI.CreateSubMenu(esthetiquemenu, "", "Voici les actions disponibles")
    local DeletePropsSubMenu = RageUI.CreateSubMenu(esthetiquemenu, "", "Voici les actions disponibles")
    local PedsSubCusMenu = RageUI.CreateSubMenu(esthetiquemenu, "", "Voici les actions disponibles")

    
    local objets = RageUI.CreateSubMenu(mainf5, "", "Voici les actions disponibles")

    local actioninventory = RageUI.CreateSubMenu(invetory, "", "Voici les actions disponibles")
    local infojob = RageUI.CreateSubMenu(portefeuille, "", "Voici les informations sur votre travail")
    local infojob2 = RageUI.CreateSubMenu(portefeuille, "", "Voici les informations sur votre organisation")
    local gestionjob = RageUI.CreateSubMenu(mainf5, " ", "Voici les informations sur votre entreprise")
    local gestionjob3 = RageUI.CreateSubMenu(mainf5, " ", "Voici les informations sur votre entreprise")
    local gestionjob2 = RageUI.CreateSubMenu(mainf5, " ", "Voici les informations sur votre organisation")
    local gestionjob4 = RageUI.CreateSubMenu(mainf5, " ", "Voici les informations sur votre organisation")

    local billingmenu = RageUI.CreateSubMenu(portefeuille, "", "Voici vos factures")
    -- local weapons = RageUI.CreateSubMenu(mainf5, "Armes", "Gestions des armes")
    local actionweapon = RageUI.CreateSubMenu(invetory, "", "Voici les actions disponibles")
    local gestionlicense = RageUI.CreateSubMenu(portefeuille, "", "Voici vos licenses")
    local FidelCoinsMenu = RageUI.CreateSubMenu(mainf5, "", "Boutique Fidélité")
    local gestionaccesories = RageUI.CreateSubMenu(vetmenu, " Accessoires", "Voici vos accessoires")

    local uniqueID = nil
    local preferenceCategory = nil
    local weaponBindSelected = nil

    local selectedItem = nil
    local selectedWeapon = nil

    mainf5.Closed = function()end
    radio.Closed = function()
        --[[local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            if not IsPauseMenuActive() then
                deletePhone()
                ClearPedTasks(ped)
            end
        end ]]
    end 

    local countobjet = 0
    for k,v in pairs(null.data.world.props.propsSpawned) do
        countobjet = countobjet + 1
    end

    radio.EnableMouse = true
    inPersoMenu = true
    RageUI.Visible(mainf5, not RageUI.Visible(mainf5))
    
    if ESX.HasItem("radio") then
        personalMenu.InfosRadio = true
    else
        personalMenu.InfosRadio = false
    end
        
    while mainf5 do
        if NullInventory.isOpen then 
            return
        end
        Wait(0)

        RageUI.IsVisible(mainf5, function()
            --RageUI.Separator("UID: ~b~"..tostring(idunique).."~s~ | ID Temporaire: ~b~"..tostring(GetPlayerServerId(PlayerId())).."~s~")
            
            RageUI.InfoPanel({
                title = "~s~Bienvenue sur "..ESX.Config("serverColor")..ESX.Config("serverName").."~s~",
                items = {
                    { label = "ID / Unique", value = tostring(GetPlayerServerId(PlayerId())) .. " ∕ " .. tostring(ESX.PlayerData.idunique) },
                    { label = "Argent", value = ESX.Config("serverColor")..PlayerState.accounts.cash.."$~s~" },
                    { label = "Argent Sale", value = ESX.Config("serverColor")..PlayerState.accounts.dirtycash.."$~s~" },
                    { label = "Métier", value = ESX.Config("serverColor")..ESX.PlayerData.job.label.."~s~ ("..ESX.Config("serverColor")..ESX.PlayerData.job.grade_label.."~s~)" },
                    { label = "Faction", value = ESX.Config("serverColor")..ESX.PlayerData.job2.label.."~s~ ("..ESX.Config("serverColor")..ESX.PlayerData.job2.grade_label.."~s~)" },

                }
            })
            --RageUI.Separator("Argent: ~g~"..PlayerState.accounts.cash.."$~s~ Argent Sale: ~r~"..PlayerState.accounts.dirtycash.."$~s~ Banque: ~g~"..PlayerState.accounts.bank.."$")
            if not isUsingInterface() then
                RageUI.Button("Inventaire", "Accéder à votre inventaire", {}, true, {}, invetory)
            end
            RageUI.Button("Informations", nil, {}, true, {
                onSelected = function()
                end
            }, portefeuille)
           -- RageUI.Button("Mes Options", "Définissez vos options", {}, true, {}, diversmenu)


            if IsPedSittingInAnyVehicle(PlayerPedId()) then 
                RageUI.Button('Gestion véhicule', 'Actions sur le véhicule', {}, true, {}, vehicle)
            end

            if (null.data.world.props.propsSpawned) and countobjet > 0 then
                RageUI.Button('Objets', nil, {}, true, {
                    onSelected = function()
                    end
                }, objets)
            end

            RageUI.Button("Radio", "Accéder à la radio", {}, personalMenu.InfosRadio, {
                onSelected = function()
                    --PlayAnim()
                end
            }, radio)

            RageUI.Button("Animation", nil, {}, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    ExecuteCommand("anims")
                end
            })

            --[[RageUI.Button("Boutique Fidélité", nil, {}, true, {
                onSelected = function()
                end
            },FidelCoinsMenu)]]
            
            --[[RageUI.Button('Guide', nil, {}, true, {
                onSelected = function() 

                end
            }, guideSubMenu)]]
            RageUI.Button(('Statut des entreprises (%s)'):format(entreprisecount), nil, {}, true, {
                onSelected = function() 

                end
            }, statusentreprise)
            if GetVIP() then
                RageUI.Button('Menu Vip', "Merci de sountenir notre serveur ⭐\n", {}, GetVIP(), {
                    onSelected = function() 
                        isvip, viptype = GetVIP()

                        premiumAccess = false

                        if viptype == "Premium" then
                            premiumAccess = true
                        elseif viptype == "Basic" then
                            premiumAccess = false
                        end
                    end
                }, vipMenu)
            end
            if PlayerState.isStreamer then
                RageUI.Button('Menu Streamer', "Merci de sountenir notre serveur ⭐\n", {}, GetVIP(), {
                    onSelected = function() 
                        ESX.TriggerServerCallback("null:iStream", function(result) 
                            if result ~= nil then
                                PlayerState.inStream = true
                                PlayerState.streamData = result
                            else
                                PlayerState.inStream = false
                            end
                        end)
                    end
                }, streamerMenu)
            end
            
            RageUI.Button("Précharger les vêtements", nil, {}, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    TriggerEvent("null:streams:preload:open")
                end
            })

        end, function()
        end)
       
        RageUI.IsVisible(streamerMenu, function()
            if PlayerState.inStream then
                while PlayerState.streamData == nil do return RageUI.Separator("Chargement en cours") end
                local Heure = string.sub(PlayerState.streamData.started_at, 12, 19)
                RageUI.Separator("En stream: "..ESX.Config("serverColor").."Oui~s~, Heure de lancement: "..ESX.Config("serverColor")..Heure)
                RageUI.Separator("Titre du stream: "..ESX.Config("serverColor")..PlayerState.streamData.title.."~s~, Viewer: "..ESX.Config("serverColor")..PlayerState.streamData.viewer_count)
                RageUI.Button("Commandes", "Listes des commandes pour les Streamers", {RightLabel = ESX.Config("serverColor").."Voir"}, true, {
                    onActive = function() 
                        RageUI.Info("Commandes", {"/freecam :", "/report"}, {"Accés a la freecam, rayon max: 15m", "Report mis en priorité"})
                    end
                })
                RageUI.Button("Stopper le stream", nil, {}, true, {
                    onSelected = function()
                        sur = string.lower(null.fct.input("Êtes-vous sur ? (Y = oui)"))
                        if sur == "y" then 
                            TriggerServerEvent("null:stopStream")
                        end
                    end
                })
                RageUI.List("Pack Graphique", {"Par défault", "Très contrasté", "Tons plus sombres"}, packGraphiqueIndexs, nil, {}, true, {
                    onListChange = function(index)
                        packGraphiqueIndexs = index
                        if index == 1 then
                            ClearTimecycleModifier() 
                        else
                            if index == 2 then
                                SetTimecycleModifier("yell_tunnel_nodirect")
                                SetTimecycleModifierStrength(1.0)
                                --SetResourceKvp(ESX.Config("serverName")..":null:graphique:index", "yell_tunnel_nodirect")
                            elseif index == 3 then
                                SetTimecycleModifier("cinema")
                                SetTimecycleModifierStrength(1.0)
                                --SetResourceKvp(ESX.Config("serverName")..":null:graphique:index", "cinema")
                            end
                        end
                    end
                })
                RageUI.Checkbox('Mode drift', nil, driftmode, {}, {
                    onChecked = function()
                        driftmode = not driftmode
                    end,
                    onUnChecked = function()
                        driftmode = false
                    end,
                    onSelected = function(Index)
                        driftmode = Index
                    end
                }) 
                RageUI.Button('Reprendre personnage', nil, {}, true, {
                    onSelected = function()
                        local healthBeforePed = GetEntityHealth(PlayerPedId())
                        local maxHealth = GetPedMaxHealth(PlayerPedId())-1
    
                        if healthBeforePed < maxHealth then
                            ESX.ShowNotification("Vous devez a voir votre vie entière pour reprendre votre personnage")
                        else
                            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
                                local isMale = skin.sex == 0
        
                                TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
                                    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                                        TriggerEvent('Null:skinchanger:loadSkin', skin)
                                        TriggerEvent('esx:restoreLoadout')
                                    end)
                                end)
                            end)
                        end
                    end
                })
    
                RageUI.Button('Peds', nil, {}, true, {
                    onSelected = function() 
    
                    end
                }, openVipPeds2)
            else 
                RageUI.Separator("En stream: "..ESX.Config("serverColor").."Non")
                RageUI.Button("Demander une vérification de stream", "Si vous êtes en stream veuillez effectuer une demande\nVous pouvez faire une demande toute les 1H.", {}, true, {
                    onSelected = function()
                        username = null.fct.input("Qu'elle est votre nom twitch ? (Attention nous voyons votre requete, mettez votre username pas Pseudo !)")
                        if username ~= nil and username ~= "" and username ~= " " then
                            TriggerServerEvent("null:streamRequest", username)
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(vipMenu, function()
            isvip, viptype = GetVIP()
            if isvip then
                if viptype ~= nil then
                    RageUI.Separator("Votre Vip : "..ESX.Config("serverColor")..viptype)
                end

                RageUI.Button('Reprendre personnage', nil, {}, premiumAccess, {
                    onSelected = function()
                        local healthBeforePed = GetEntityHealth(PlayerPedId())
                        local maxHealth = GetPedMaxHealth(PlayerPedId())-1
    
                        if healthBeforePed < maxHealth then
                            ESX.ShowNotification("Vous devez a voir votre vie entière pour reprendre votre personnage")
                        else
                            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
                                local isMale = skin.sex == 0
        
                                TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
                                    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                                        TriggerEvent('Null:skinchanger:loadSkin', skin)
                                        TriggerEvent('esx:restoreLoadout')
                                    end)
                                end)
                            end)
                        end
                    end
                })
    
                RageUI.Button('Peds', nil, {}, premiumAccess, {
                    onSelected = function() 
    
                    end
                }, openVipPeds)
    
                RageUI.Checkbox('Mode drift', "Option VIP", driftmode, {}, {
                    onChecked = function()
                        if GetVIP() then
                            driftmode = not driftmode
                        else
                            driftmode = false 
                            ESX.ShowNotification('Vous devez être ~g~VIP ~s~afin d\'activer le mode drift')
                        end
                    end,
                    onUnChecked = function()
                        if GetVIP() then
                            driftmode = false
                        end
                    end,
                    onSelected = function(Index)
                        if GetVIP() then
                            driftmode = Index
                        end
                    end
                }) 
                -- if Config.RageUI ~= nil and Config.RageUI.ChangeUIForVIP then
                --     RageUI.List("Style Menu", {"Par défault", "Avancée", "Minimaliste"}, RageUIStyleIndex, nil, {}, true, {
                --         onListChange = function(index)
                --             RageUIStyleIndex = index 
                --             ChangeRageUIStyle(index)
                --         end
                --     })
                -- end
            end
        end)

        RageUI.IsVisible(openVipPeds, function()
            for i = 1, #pedmodel do 
                RageUI.Button(pedmodel[i].name, nil, {}, true, {
                    onActive = function()--              --   --
                        RenderSprite("vip", pedmodel[i].picturemodel, 550, 144, 260, 417, 500)
                    end,   
                    onSelected = function()
                        local healthBeforePed = GetEntityHealth(PlayerPedId())

                        if healthBeforePed < 50 then
                            ESX.ShowNotification("Vous devez a voir plus de la moitier de votre  vie  pour reprendre votre personnage")
                        else
                            Citizen.Wait(200)
                            SpawnPed(pedmodel[i].model)
                            local model = pedmodel[i].model
                            local _src = source
                            TriggerEvent('couldown')
                        end
                    end
                })
            end
        end)
        RageUI.IsVisible(openVipPeds2, function()
            for i = 1, #pedmodel do 
                RageUI.Button(pedmodel[i].name, nil, {}, true, {
                    onActive = function()--              --   --
                        RenderSprite("vip", pedmodel[i].picturemodel, 550, 144, 260, 417, 500)
                    end,   
                    onSelected = function()
                        local healthBeforePed = GetEntityHealth(PlayerPedId())

                        if healthBeforePed < 50 then
                            ESX.ShowNotification("Vous devez a voir plus de la moitier de votre  vie  pour reprendre votre personnage")
                        else
                            Citizen.Wait(200)
                            SpawnPed(pedmodel[i].model)
                            local model = pedmodel[i].model
                            local _src = source
                            TriggerEvent('couldown')
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(guideSubMenu, function()
            for i = 1, #Config.Guide do 
                local v = Config.Guide[i]
                RageUI.Button(v[1], v[3], {RightLabel = v[2]}, true, {})
            end
        end)
        RageUI.IsVisible(statusentreprise, function()
            for k,v in pairs(SocietyList) do
                if v.state == true then
                    if v.label ~= "Aucun" then
                        RageUI.Button(v.label, nil, {RightLabel = v.state == false and '~r~Fermé~s~' or '~g~Ouvert~s~'}, true, {
                            onSelected = function()
                                if v.position then
                                    SetNewWaypoint(vector3(v.position.x, v.position.y, v.position.z))
                                end
                            end
                        })
                    else
                        RageUI.Button(v.name, nil, {RightLabel = v.state == false and '~r~Fermé~s~' or '~g~Ouvert~s~'}, true, {
                            onSelected = function()
                                if v.position then
                                    SetNewWaypoint(vector3(v.position.x, v.position.y, v.position.z))
                                end
                            end
                        })
                    end
                end
            end
            for k,v in pairs(SocietyList) do
                if v.state == false then
                    if v.label ~= "Aucun" then
                        RageUI.Button(v.label, nil, {RightLabel = v.state == false and '~r~Fermé~s~' or '~g~Ouvert~s~'}, true, {
                            onSelected = function()
                                
                            end
                        })
                    else
                        RageUI.Button(v.name, nil, {RightLabel = v.state == false and '~r~Fermé~s~' or '~g~Ouvert~s~'}, true, {
                            onSelected = function()
                                
                            end
                        })
                    end
                end
            end
        end)

        RageUI.IsVisible(objets, function()
            for k,v in pairs(null.data.world.props.propsSpawned) do
                if v.owner.UniqueID == ESX.PlayerData.idunique then
                    RageUI.Button(v.label or "Objets", 
                    "Entrer pour mettre un point GPS.\n\nID de l'objet : "..v.propsId.."\nDate : "..v.owner.day.."/"..v.owner.month.."/"..v.owner.years.." à "..v.owner.hours..":"..v.owner.min.."H\nDistance : "..ESX.Math.Round(#(GetEntityCoords(PlayerPedId()) - vector3(v.position.x, v.position.y, v.position.z))).."m", 
                    {}, true, {
                        onActive = function()
                            
                        end,
                        onSelected = function()
                            SetNewWaypoint(vector3(v.position.x, v.position.y, v.position.z))
                        end
                    })
                end
            end
        end)

        RageUI.IsVisible(FidelCoinsMenu, function()
            for i = 1, #ESX.PlayerData.accounts, 1 do
                if ESX.PlayerData.accounts[i].name == 'fidelcoins'  then
                    RageUI.Button("Vos Points Fidélité", nil, {RightLabel = ESX.PlayerData.accounts[i].money,RightBadge = RageUI.BadgeStyle.Star}, true, {
                        onSelected = function()
                        end
                    })
                end
            end
            RageUI.Separator('Articles disponibles')
            RageUI.Button("Pass VIP ( 1 Mois ) ", nil, {RightLabel = 2500,RightBadge = RageUI.BadgeStyle.Star}, true, {
                onSelected = function()
                    if not GetVIP() or GetVIP() == 0 then
                        TriggerServerEvent('FidelCoins:BuyVIP')
                    else
                        ESX.ShowNotification("Vous avez déja le VIP !")
                    end
                end
            })
            RageUI.Button("250 Points boutique ", nil, {RightLabel = 1500,RightBadge = RageUI.BadgeStyle.Star}, true, {
                onSelected = function()
                    for i = 1, #ESX.PlayerData.accounts, 1 do
                        if ESX.PlayerData.accounts[i].name == 'fidelcoins'  then
                           if ESX.PlayerData.accounts[i].money >= 1500 then
                                TriggerServerEvent('NullBoutique:buycoins', 250, 1500)
                           end
                        end
                    end
                end
            })
        end)

        RageUI.IsVisible(invetory, function()
            ESX.PlayerData = ESX.GetPlayerData()

            RageUI.Separator('Poids > '.. ESX.GetCurrentWeight() + 0.0 .. '/' .. ESX.PlayerData.maxWeight + 0.0)

            RageUI.List("Filtre", {"Aucun", "Inventaire", "Armes", "Vêtements", "Accessoires"}, personalMenu.Indexinvetory, nil, {}, true, {
                onListChange = function(index)
                    personalMenu.Indexinvetory = index 
                    if index == 1 then 
                        personalMenu.Item, personalMenu.Weapon, personalMenu.Vetement, personalMenu.AccesoiresMenu = true, true, true, true
                    elseif index == 2 then 
                        personalMenu.Item, personalMenu.Weapon, personalMenu.Vetement, personalMenu.AccesoiresMenu = true, false, false, false
                    elseif index == 3 then 
                        personalMenu.Item, personalMenu.Weapon, personalMenu.Vetement, personalMenu.AccesoiresMenu = false, true, false, false
                    elseif index == 4 then 
                        personalMenu.Item, personalMenu.Weapon, personalMenu.Vetement, personalMenu.AccesoiresMenu = false, false, true, false
                    elseif index == 5 then 
                        personalMenu.Item, personalMenu.Weapon, personalMenu.Vetement, personalMenu.AccesoiresMenu = false, false, false, true
                    end
                end
            })

            if personalMenu.Item then 
                if #ESX.PlayerData.inventory > 0 then 
                    RageUI.Separator("Item(s)")
                    for k, v in pairs(ESX.PlayerData.inventory) do 
                        if v.count > 0 then 
                            RageUI.Button("> "..v.label.."", nil,  {RightLabel = "Quantité : x"..v.count..""}, not itemCooldown, {
                                onSelected = function()
                                    count = v.count 
                                    label  = v.label
                                    name = v.name
                                    remove = v.canRemove
                                    Wait(100)
                                end
                            }, actioninventory)
                        end
                    end
                else
                    RageUI.Separator("~r~Aucun Item")
                end
            end

            if personalMenu.Weapon then 
                if #ESX.PlayerData.loadout > 0 then 
                    RageUI.Separator("Arme(s)")
                    for i = 1, #ESX.PlayerData.loadout, 1 do
                        --if HasPedGotWeapon(PlayerPedId(), ESX.PlayerData.loadout[i].hash, false) then
                            --local ammo = GetAmmoInPedWeapon(PlayerPedId(), ESX.PlayerData.loadout[i].hash)
                            RageUI.Button("> "..ESX.PlayerData.loadout[i].label, nil,  {}, true, {
                                onSelected = function()
                                    ammoo = ammo 
                                    name = ESX.PlayerData.loadout[i].name 
                                    label = ESX.PlayerData.loadout[i].label
                                    weaponData = ESX.PlayerData.loadout[i]
                                end
                            }, actionweapon)
                        --end
                    end
                else
                    RageUI.Separator("~r~Aucune Armes")
                end
            end

            if personalMenu.Vetement then 
                if PlayerState.Clothes ~= nil  then 
                    RageUI.Separator("Vêtement(s)")
                    for k, v in pairs(PlayerState.Clothes) do 
                        if v.label ~= nil and v.type == "top" or v.type == "pants" or v.type == "shoes" then 
                            local labeltype = ""
                            local finalLabel = ""
                            if v.type == "top" then
                                labeltype = "Haut"
                            elseif v.type == "pants" then
                                labeltype = "Bas"
                            elseif v.type == "shoes" then
                                labeltype = "Chaussure"
                            end
                            if v.label ~= nil then
                                finalLabel = v.label
                            end
                            RageUI.List("> "..labeltype.." "..finalLabel, {"Equiper", "Renommer", "Supprimer", "Donner"}, personalMenu.IndexVetement, nil, {}, true, {
                                onListChange = function(Index)
                                    personalMenu.IndexVetement = Index
                                end,
                                onSelected = function(Index)
                                    if Index == 1 then 
                                        null.fct.game.startAnimAction('clothingtie', 'try_tie_neutral_a')
                                        Wait(1000)
                                        ExecuteCommand("me équipe une tenue")
                                        TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                            TriggerEvent("Null:skinchanger:loadClothes", skin, json.decode(v.skin))
                                        end)
                                        TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                            TriggerServerEvent("Null:esx_skin:save", skin)
                                        end)
                                    elseif Index == 2 then 
                                        local newname = null.fct.input('Nouveaux Nom :', false, 999, "text")
                                        if newname then 
                                            TriggerServerEvent("Null:RenameTenue", v.id, newname)
                                        end
                                    elseif Index == 3 then 
                                        TriggerServerEvent('Null:deletetenue', v.id)
                                    elseif Index == 4 then 
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestDistance ~= -1 and closestDistance <= 3 then
                                            local closestPed = GetPlayerPed(closestPlayer)
                                            TriggerServerEvent("Null:donnertenue", GetPlayerServerId(closestPlayer), v.id)
                                            RageUI.CloseAll()
                                        else
                                            ESX.ShowNotification("Personne aux alentours")
                                        end
                                    end
                                end,
                              
                            })
                        end
                    end
                else
                    RageUI.Separator("~r~Aucune Tenue")
                end
            end

            if personalMenu.AccesoiresMenu then 
                if PlayerState.Clothes ~= nil then 
                    RageUI.Separator("Accessoire(s)")
                    if not PlayerState.Clothes ~= nil then
                        for k, v in pairs(PlayerState.Clothes) do 
                            if v.label ~= nil and v.type ~= "vetement" then 
                                RageUI.List("> "..v.type..' '..v.label, {"Equiper", "Renommer", "Supprimer", "Donner"}, personalMenu.IndexVetement, nil, {}, true, {
                                    onListChange = function(Index)
                                        personalMenu.IndexVetement = Index
                                    end,
                                    onSelected = function(Index)
                                        if Index == 1 then 
                                            null.fct.game.startAnimAction('clothingtie', 'try_tie_neutral_a')
                                            Wait(1000)
                                            ExecuteCommand("me équipe un(e) "..v.type)
                                            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                                TriggerEvent("Null:skinchanger:loadClothes", skin, json.decode(v.skin))
                                            end)
                                            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                                TriggerServerEvent("Null:esx_skin:save", skin)
                                            end)
                                        elseif Index == 2 then 
                                            local newname = null.fct.input('Nouveaux Nom :', false, 999, "text")
                                            if newname then 
                                                TriggerServerEvent("Null:RenameTenue", v.id, newname)
                                            end
                                        elseif Index == 3 then 
                                            ExecuteCommand("me supprime le/la "..v.type.." ")
                                            TriggerServerEvent('Null:deletetenue', v.id)
                                        elseif Index == 4 then 
                                            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                            if closestDistance ~= -1 and closestDistance <= 3 then
                                                local closestPed = GetPlayerPed(closestPlayer)
                                                TriggerServerEvent("Null:donnertenue", GetPlayerServerId(closestPlayer), v.id)
                                                RageUI.CloseAll()
                                            else
                                                ESX.ShowNotification("Personne aux alentours")
                                            end
                                        end
                                    end
                                })
                            end
                        end
                    end
                else
                    RageUI.Separator("~r~Aucun Accésoire")
                end
            end

        end, function()
        end)

        RageUI.IsVisible(portefeuille, function()

            local player, closestplayer = ESX.Game.GetClosestPlayer()

            RageUI.Separator('Portefeuille')

            RageUI.Button('Argent en liquide:' , nil, {RightLabel = '~g~'..PlayerState.accounts.cash.."$"}, true, {
                onActive = function()
                   -- local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                   -- if closestDistance ~= -1 and closestDistance <= 3 then
                   --     PlayerMarker2(closestPlayer)
                 --   end
                end,
                onSelected = function()
                  ---  local check, quantity = CheckQuantity(null.fct.input('Montant :', false, 999, "number"))
                  --  if check then 
                    --    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                     --   if closestDistance ~= -1 and closestDistance <= 3 then
                      --      local closestPed = GetPlayerPed(closestPlayer)
                        --    if not IsPedSittingInAnyVehicle(closestPed) then
                         --       TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_account', "cash", quantity)
                         --       RageUI.GoBack()
                         --   else
                         --       ESX.ShowNotification("~r~Vous ne pouvez pas faire ceci dans un véhicule !")
                         --   end
                     --   else
                        --    ESX.ShowNotification('Aucun joueur proche !')
                       -- end
                  --  else
                     --   ESX.ShowNotification("Arguments Inssufisant")
                 --   end
                end
            })

            RageUI.Button('Argent non déclaré: ', nil, {RightLabel = "~r~"..PlayerState.accounts.dirtycash.."$"}, true, {
                onActive = function()
                  --  local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                   -- if closestDistance ~= -1 and closestDistance <= 3 then
                     --   PlayerMarker2(closestPlayer)
                 --   end
                end,
                onSelected = function()
                  --  local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                   -- local check, quantity = CheckQuantity(null.fct.input('Montant :', false, 999, "number"))
                   -- if check then 
                     --   if closestDistance ~= -1 and closestDistance <= 3 then
                       --     local closestPed = GetPlayerPed(closestPlayer)
                          --  if not IsPedSittingInAnyVehicle(closestPed) then
                            --    TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_account', "dirtycash", quantity)
                            --    RageUI.GoBack()
                           -- else
                           --     ESX.ShowNotification("~r~Vous ne pouvez pas faire ceci dans un véhicule !")
                         --   end
                     --   else
                        --    ESX.ShowNotification('Aucun joueur proche !')
                      --  end
                  --  else
                    --    ESX.ShowNotification("Arguments Inssufisant")
                  --  end
                end
            })

			
            AmontToReveal = AmontToReveal or 0
            if revealedbank == true then
                RageUI.Button('Argent en banque:', "[ENTRER] Pour rafraichir", {RightLabel = '~b~'..AmontToReveal.."$", Null = {id = "personalmenu-load-bank", LoadingOnSelect = 1500, description = "Récupération des informations auprès de votre banque."}}, true, {
                    onSelected = function()
                        AmontToReveal = PlayerState.accounts.bank
                        revealedbank = true
                        Citizen.CreateThread(function()
                            Wait(30000)
                            ctn = 0
                            while mainf5 and ctn < 100 do 
                                ctn += 1
                                Wait(100) 
                            end
                            revealedbank = false
                        end)
                    end,
                    onFirstSelected = function()
                        AmontToReveal = 0
                    end
                })
            elseif revealedbank == false then
                RageUI.Button("Vérifier votre compte en banque", nil, {RightLabel = "", Null = {id = "personalmenu-load-bank", LoadingOnSelect = 1500, description = "Récupération des informations auprès de votre banque."}}, true, {
                    onSelected = function()
                        AmontToReveal = PlayerState.accounts.bank
                        revealedbank = true
                        Citizen.CreateThread(function()
                            Wait(30000)
                            ctn = 0
                            while mainf5 and ctn < 100 do 
                                ctn += 1
                                Wait(100) 
                            end
                            revealedbank = false
                        end)
                    end
                })
            end


            RageUI.Button("Accéder à vos factures", nil, {}, true, {
                onSelected = function()
                    ESX.TriggerServerCallback('Null:getFactures', function(bills) BillData = bills end)
                end
            }, billingmenu)

            RageUI.Separator("License(s)")

            if ESX.PlayerData.job.name ~= "unemployed" then
                RageUI.Button("Quitter votre Métier", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("Null:leavejob", "job")
                    end
                })
            end

            if ESX.PlayerData.job2.name ~= "unemployed2" then
                RageUI.Button("Quitter votre Groupe Illégal", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("Null:leavejob", "job2")
                    end
                })
            end

            if ESX.PlayerData.smells == nil then ESX.PlayerData.smells = {} end
                RageUI.Separator("Odeur(s)")
                for k,v in pairs(ESX.PlayerData.smells) do
                    if v.hidden then
                        RageUI.Progress(Config.smells.allSmells[k].label.." (Cachée)", v.value, 100, Config.smells.allSmells[k].description, true, false, {})
                    else
                        RageUI.Progress(Config.smells.allSmells[k].label, v.value, 100, Config.smells.allSmells[k].description, true, false, {})
                    end
                end
            
        end, function()
        end)

        RageUI.IsVisible(vehicle, function()

            local pVeh = GetVehiclePedIsUsing(PlayerPedId())

            local vModel = GetEntityModel(pVeh)
            if IsPedInAnyVehicle(PlayerPedId(), true) then 
                local vPlate = GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId()), false)
                local vName = GetDisplayNameFromVehicleModel(vModel) --Avoir le nom du véhicule
                local Essence = GetVehicleFuelLevel(pVeh)
                local vMoteur = GetVehicleEngineHealth(pVeh)
                local vType = IsThisModelABoat(vModel) == true and "Bateau" or IsThisModelAPlane(vModel) == true and "Avion" or IsThisModelAHeli(vModel) == true and "Helico" or "Voiture"
                --RageUI.Separator('[Plaque]   '..vPlate ..'')
                --RageUI.Separator('[Modèle]   '..vName..'')
                --RageUI.Separator('[Moteur]   '..math.floor(ESX.Math.Round(vMoteur/10, 0)..'%'))
                --RageUI.Separator('[Essence]   '..math.floor(ESX.Math.Round(Essence, 0)..'%'))

                RageUI.InfoPanel({
                    title = "Info véhicule",
                    items = {
                        { label = "Classe", value = vType },
                        { label = "Plaque", value = vPlate },
                        { label = "Modèle", value = vName },
                        { label = "Moteur", value = math.floor(ESX.Math.Round(vMoteur/10, 0)).."%" },
                        { label = "Essence", value = math.floor(ESX.Math.Round(Essence, 0)).."%" },
                    }
                })
                SetPlayerCanDoDriveBy(PlayerId(), true)
            else
                -- RageUI.Separator('[Plaque]   '.."Non défini" ..'')
                -- RageUI.Separator('[Modèle]   '.."Non défini"..'')
                -- RageUI.Separator('[Essence]   '.."Non défini"..'')
                -- RageUI.Separator('[Moteur]    '.."Non défini")
                RageUI.InfoPanel({
                    title = "Info véhicule",
                    items = {
                        { label = "Classe", value = "Non défini" },
                        { label = "Plaque", value = "Non défini" },
                        { label = "Modèle", value = "Non défini" },
                        { label = "Moteur", value = "Non défini" },
                        { label = "Essence", value = "Non défini" },
                    }
                })
            end
            


            if IsThisModelABoat(vModel) then
                RageUI.Button("Mettre l'encre", nil, {RightLabel = personalMenu.Statut}, true, {
                    onSelected = function()
                        FreezeEntityPosition(pVeh, not IsEntityPositionFrozen(pVeh))
                    end
                })
            end

            RageUI.Button("Allumer / Eteindre le moteur", nil, {RightLabel = personalMenu.Statut}, true, {
                onSelected = function()
                    if GetIsVehicleEngineRunning(pVeh) then
                        personalMenu.Statut = "~r~Eteint"

                        SetVehicleEngineOn(pVeh, false, false, true)
                        SetVehicleUndriveable(pVeh, true)
                    elseif not GetIsVehicleEngineRunning(pVeh) then
                        personalMenu.Statut = "~g~Allumé"

                        SetVehicleEngineOn(pVeh, true, false, true)
                        SetVehicleUndriveable(pVeh, false)
                    end
                end
            })

            RageUI.List("Ouvrir / Fermer porte", {"Avant gauche", "Avant Droite", "Arrière Gauche", "Arrière Droite", "Capot", "Coffre"}, personalMenu.Indexdoor, nil, {}, true, {
                onListChange = function(index)
                    personalMenu.Indexdoor = index 
                end,
                onSelected = function(index)
                    
                    if index == 1 then
                        if not personalMenu.DoorState.FrontLeft then
                            personalMenu.DoorState.FrontLeft = true
                            SetVehicleDoorOpen(pVeh, 0, false, false)
                        elseif personalMenu.DoorState.FrontLeft then
                            personalMenu.DoorState.FrontLeft = false
                            SetVehicleDoorShut(pVeh, 0, false, false)
                        end
                    elseif index == 2 then
                        if not personalMenu.DoorState.FrontRight then
                            personalMenu.DoorState.FrontRight = true
                            SetVehicleDoorOpen(pVeh, 1, false, false)
                        elseif personalMenu.DoorState.FrontRight then
                            personalMenu.DoorState.FrontRight = false
                            SetVehicleDoorShut(pVeh, 1, false, false)
                        end
                    elseif index == 3 then
                        if not personalMenu.DoorState.BackLeft then
                            personalMenu.DoorState.BackLeft = true
                            SetVehicleDoorOpen(pVeh, 2, false, false)
                        elseif personalMenu.DoorState.BackLeft then
                            personalMenu.DoorState.BackLeft = false
                            SetVehicleDoorShut(pVeh, 2, false, false)
                        end
                    elseif index == 4 then
                        if not personalMenu.DoorState.BackRight then
                            personalMenu.DoorState.BackRight = true
                            SetVehicleDoorOpen(pVeh, 3, false, false)
                        elseif personalMenu.DoorState.BackRight then
                            personalMenu.DoorState.BackRight = false
                            SetVehicleDoorShut(pVeh, 3, false, false)
                        end
                    elseif index == 5 then 
                        if not personalMenu.DoorState.Hood then
                            personalMenu.DoorState.Hood = true
                            SetVehicleDoorOpen(pVeh, 4, false, false)
                        elseif personalMenu.DoorState.Hood then
                            personalMenu.DoorState.Hood = false
                            SetVehicleDoorShut(pVeh, 4, false, false)
                        end
                    elseif index == 6 then 
                        if not personalMenu.DoorState.Trunk then
                            personalMenu.DoorState.Trunk = true
                            SetVehicleDoorOpen(pVeh, 5, false, false)
                        elseif personalMenu.DoorState.Trunk then
                            personalMenu.DoorState.Trunk = false
                            SetVehicleDoorShut(pVeh, 5, false, false)
                        end
                    end
                end
            })

            RageUI.Button("Fermer toutes les portes", nil, {RightLabel =  ""}, true, {
                onSelected = function ()
                    for door = 0, 7 do
                        SetVehicleDoorShut(pVeh, door, false)
                    end
                end
            })

            RageUI.List("Limitateur", personalMenu.voiture_limite, personalMenu.LimitateurIndex, nil, {}, true, {
                onListChange = function(i, item)
                    personalMenu.LimitateurIndex = i
                end,

                onSelected = function(i, item)
                    --if GetLevel() >= 12 then
                        if i == 1 then
                            SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), 50.0/3.6)
                            ESX.ShowNotification("Limitateur de vitesse défini sur ~g~50 km/h")
                        elseif i == 2 then  
                            SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), 80.0/3.6)
                            ESX.ShowNotification("Limitateur de vitesse défini sur ~g~80 km/h")
                        elseif i == 3  then
                            SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), 130.0/3.6)
                            ESX.ShowNotification("Limitateur de vitesse défini sur ~g~130 km/h")
                        elseif i == 4 then
                            local speed = null.fct.input('Bloqué le compteur a :', false, 999, "number")
                            if speed ~= nil or speed ~= tostring("") then 
                                SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), ESX.Math.Round(speed, 1)/3.6)
                                ESX.ShowNotification("Limitateur de vitesse défini sur ~g~"..speed..'km/h')
                            else
                                return
                            end
                        elseif i == 5 then 
                            SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), 10000.0/3.6)    
                            ESX.ShowNotification("Limitateur de vitesse désactivé")
                        end
                    --else
                    --    ESX.ShowNotification('Vous n\'avez pas le niveau nécéssaire.')
                    --end
                end
            })

   
        
        end, function()
        end)

        RageUI.IsVisible(vetmenu, function()

            RageUI.List(" Vêtements", {"Haut", "Bas", "Chaussures", "Sac", "Giltet par balle"}, personalMenu.IndexClothes, nil, {LeftBadge = RageUI.BadgeStyle.Clothes}, true, {
                onListChange = function(index)
                    personalMenu.IndexClothes = index 
                end, 
                onSelected = function(index)
                    ESX.TriggerServerCallback("Null:esx_skin:getPlayerSkin", function(skin)
                        TriggerEvent("Null:skinchanger:getSkin", function(skina)
                            if index == 1 then 
                                if skin.torso_1 ~= skina.torso_1 then
                                    ExecuteCommand("me remet son haut")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["torso_1"] = skin.torso_1, ["torso_2"] = skin.torso_2, ["tshirt_1"] = skin.tshirt_1, ["tshirt_2"] = skin.tshirt_2, ["arms"] = skin.arms })
                                else
                                    ExecuteCommand("me retire son haut")
                                    if skin.sex == 0 then
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["torso_1"] = 15, ["torso_2"] = 0, ["tshirt_1"] = 15, ["tshirt_2"] = 0, ["arms"] = 15 })
                                    else
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["torso_1"] = 15, ["torso_2"] = 0, ["tshirt_1"] = 15, ["tshirt_2"] = 0, ["arms"] = 15 })
                                    end
                                end
                            elseif index == 2 then 
                                if skin.pants_1 ~= skina.pants_1 then
                                    ExecuteCommand("me remet son pantalon")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["pants_1"] = skin.pants_1, ["pants_2"] = skin.pants_2 })
                                else
                                    ExecuteCommand("me retire son pantalon")
                                    if skin.sex == 0 then
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["pants_1"] = 14, ["pants_2"] = 0 })
                                    else
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["pants_1"] = 15, ["pants_2"] = 0 })
                                    end
                                end
                            elseif index == 3 then 
                                if skin.shoes_1 ~= skina.shoes_1 then
                                    ExecuteCommand("me remet ses chaussures")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["shoes_1"] = skin.shoes_1, ["shoes_2"] = skin.shoes_2 })
                                else
                                    if skin.sex == 0 then
                                        ExecuteCommand("me enlève ses chaussures")
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["shoes_1"] = 80, ["shoes_2"] = 0 })
                                    else
                                        TriggerEvent("Null:skinchanger:loadClothes", skina, { ["shoes_1"] = 46, ["shoes_2"] = 0 })
                                    end
                                end
                            elseif index == 4 then
                                if skin.bags_1 ~= skina.bags_1 then
                                    ExecuteCommand("me retire son sac")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["bags_1"] = skin.bags_1, ["bags_2"] = skin.bags_2 })
                                else
                                    ExecuteCommand("me retire son sac")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["bags_1"] = 0, ["bags_2"] = 0 })
                                end
                            elseif index == 5 then 
                                if skin.bproof_1 ~= skina.bproof_1 then
                                    ExecuteCommand("me retire son gilet par balle")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["bproof_1"] = skin.bproof_1, ["bproof_2"] = skin.bproof_2 })
                                else
                                    ExecuteCommand("me retire son gilet par balle")
                                    TriggerEvent("Null:skinchanger:loadClothes", skina, { ["bproof_1"] = 0, ["bproof_2"] = 0 })
                                end
                            end
                        end)
                    end)
                end
            })

            RageUI.List(' Accessoires', {"Masque","Chapeau", "Lunette", "Boucle d'oreilles"}, personalMenu.Indexaccesories, nil, {LeftBadge = RageUI.BadgeStyle.Mask}, true, {
                onListChange = function(Index)
                    personalMenu.Indexaccesories = Index;
                end,

                onSelected = function(Index)
                    if Index == 1 then
                        playerPed = GetPlayerPed(-1)
                        TriggerEvent('Null:skinchanger:getSkin', function(skin)
                            local clothesSkin = { ['mask_1'] = 0,   ['mask_2'] = 0  }
                            TriggerEvent('Null:skinchanger:loadClothes', skin, clothesSkin)
                            TriggerServerEvent('Null:esx_skin:save', skin)
                        end)
                    elseif Index == 2 then
                        TriggerEvent('Null:skinchanger:getSkin', function(skin)
                            local clothesSkin = {
                            ['helmet_1'] = -1,   ['helmet_2'] = 0
                            }
                            TriggerEvent('Null:skinchanger:loadClothes', skin, clothesSkin)
                            TriggerServerEvent('Null:esx_skin:save', skin)
                        end)
                    elseif Index == 3 then
                        playerPed = GetPlayerPed(-1)
                        ClearPedProp(playerPed, 1)
                        TriggerEvent('Null:skinchanger:getSkin', function(skin)
                            local clothesSkin = {['glasses_1'] = 0,   ['glasses_2'] = 0 }
                            TriggerEvent('Null:skinchanger:loadClothes', skin, clothesSkin)
                            TriggerServerEvent('Null:esx_skin:save', skin)
                        end)
                    end
                end
            })

        end, function()
        end)

        RageUI.IsVisible(radio, function()
            RageUI.Checkbox("Allumer / Eteindre", "Vous permet d'allumer ou d'éteindre la radio", personalMenu.TickRadio, {}, {
                onChecked = function()
                    personalMenu.TickRadio = true 
                    pma:setVoiceProperty("radioEnabled", true)
                end,
                onUnChecked = function()
                    personalMenu.TickRadio = false
                    pma:setRadioChannel(0)
                    pma:setVoiceProperty("radioEnabled", false)
                end,
            })
            if personalMenu.TickRadio then
                RageUI.Button("Se connecter à une fréquence ", "Choissisez votre fréquence", {RightLabel = personalMenu.Frequence or ""}, true, {
                    onSelected = function()
                        local verif, Frequence = CheckQuantity(null.fct.input('Fréquence Radio :', false, 999, "number"))
                        if verif then
                            if Frequence then 
                                if Config.Radio[Frequence] ~= nil then
                                    local can = false
                                    for k,v in pairs(Config.Radio[Frequence]) do
                                        if k == ESX.PlayerData.job.name then
                                            can = true
                                        end
                                    end
                                    if not can then
                                        ESX.ShowNotification('Vous ne pouvez pas allez sur cette radio') 
                                    else
                                        personalMenu.Frequence = tostring(Frequence)
                                        pma:setRadioChannel(Frequence)
                                        ESX.ShowNotification("Fréquence définie sur "..Frequence.." MHZ")
                                    end
                                else
                                    personalMenu.Frequence = tostring(Frequence)
                                    pma:setRadioChannel(Frequence)
                                    ESX.ShowNotification("Fréquence définie sur "..Frequence.." MHZ")
                                end
                            end
                        end
                    end
                })

                RageUI.Button("Se déconnecter de la fréquence", "Vous permet de déconnecter de votre fréquence actuelle", {}, true, {
                    onSelected = function()
                        pma:setRadioChannel(0)
                        personalMenu.Frequence = nil
                        ESX.ShowNotification("Vous vous êtes déconnecter de la fréquence")
                    end
                })
                RageUI.Checkbox("Activer les bruitages", "Vous permet d'activer les bruitages", personalMenu.Bruitages, {}, {
                    onChecked = function()
                        personalMenu.Bruitages = true 
                        ESX.ShowNotification("Bruitages radio activés")
                        pma:setVoiceProperty("micClicks", true)
                    end,
                    onUnChecked = function()
                        personalMenu.Bruitages = false
                        pma:setVoiceProperty("micClicks", false)
                        ESX.ShowNotification("Bruitages radio désactives")
                    end,
                })
            end

        end, function()
            if personalMenu.Frequence ~= nil then
                RageUI.PercentagePanel(personalMenu.VolumeRadio, 'Volume', '0%', '100%', {
                    onProgressChange = function(Percentage)
                        personalMenu.VolumeRadio = Percentage
                        pma:setRadioVolume(Percentage)
                    end
                }, 2) 
            end
        end)

        RageUI.IsVisible(PedsSubCusMenu, function ()
            local ped = PlayerPedId()

            RageUI.List("Visage", {"1", "2", "3"}, Customs.List1, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List1 = i;
                end,
                onActive = function()
                    if Customs.List1 == 1 then
                        SetCus(ped, 0, 0, 0, 0)
                    end
                    if Customs.List1 == 2 then
                        SetCus(ped, 0, 0, 1, 0)
                    end
                    if Customs.List1 == 3 then
                        SetCus(ped, 0, 1, 1, 0)
                    end
                end, 
            })

            RageUI.List("Cheveux", {"1", "2", "3", "4"}, Customs.List2, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List2 = i;
                end,
                onActive = function()
                    if Customs.List2 == 1 then
                        SetCus(ped, 2, 0, 0, 0)
                    end
                    if Customs.List2 == 2 then
                        SetCus(ped, 2, 1, 1, 0)
                    end
                    if Customs.List2 == 3 then
                        SetCus(ped, 2, 2, 1, 0)
                    end
                    if Customs.List2 == 4 then
                        SetCus(ped, 2, 3, 1, 0)
                    end
                end, 
            })

            RageUI.List("Haut", {"1", "2", "3", "4", "5", "6"}, Customs.List4, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List4 = i;
                end,
                onActive = function()
                    if Customs.List4 == 1 then
                        SetCus(ped, 3, 0, 0, 0)
                    end
                    if Customs.List4 == 2 then
                        SetCus(ped, 3, 0, 1, 0)
                    end
                    if Customs.List4 == 3 then
                        SetCus(ped, 3, 0, 2, 0)
                    end
                    if Customs.List4 == 4 then
                        SetCus(ped, 3, 1, 0, 0)
                    end
                    if Customs.List4 == 5 then
                        SetCus(ped, 3, 1, 1, 0)
                    end
                    if Customs.List4 == 6 then
                        SetCus(ped, 3, 1, 2, 0)
                    end
                end, 
            })

            RageUI.List("Bas", {"1", "2", "3", "4"}, Customs.List5, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List5 = i;
                end,
                onActive = function()
                    if Customs.List5 == 1 then
                        SetCus(ped, 4, 0, 0, 0)
                    end
                    if Customs.List5 == 2 then
                        SetCus(ped, 4, 0, 1, 0)
                    end
                    if Customs.List5 == 3 then
                        SetCus(ped, 4, 1, 0, 0)
                    end
                    if Customs.List5 == 4 then
                        SetCus(ped, 4, 1, 1, 0)
                    end
                end, 
            })

            RageUI.List("Chapeau", {"1", "2", "3", "4", "5", "6"}, Customs.List8, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List8 = i;
                end,
                onActive = function()
                    if Customs.List8 == 1 then
                        Clear(ped, 0)
                    end
                    if Customs.List8 == 2 then
                        SetProp(ped, 0, 0, 0, 0)
                    end
                    if Customs.List8 == 3 then
                        SetProp(ped, 0, 0, 1, 0)
                    end
                    if Customs.List8 == 4 then
                        SetProp(ped, 0, 0, 2, 0)
                    end
                    if Customs.List8 == 5 then
                        SetProp(ped, 0, 1, 0, 0)
                    end
                    if Customs.List8 == 6 then
                        SetProp(ped, 0, 1, 1, 0)
                    end
                end, 
            })

            RageUI.List("Lunettes", {"1", "2", "3", "4"}, Customs.List7, nil, {}, true, {
                onListChange = function(i, Item)
                    Customs.List7 = i;
                end,
                onActive = function()
                    if Customs.List7 == 1 then
                        Clear(ped, 1)
                    end
                    if Customs.List7 == 2 then
                        SetProp(ped, 1, 0, 0, 0)
                    end
                    if Customs.List7 == 3 then
                        SetProp(ped, 1, 0, 1, 0)
                    end
                    if Customs.List7 == 4 then
                        SetProp(ped, 1, 1, 0, 0)
                    end
                end, 
            })
        end, function()
        end)

        RageUI.IsVisible(PedsSubMenu, function()
            for _, v in pairs (pedmodel) do

                RageUI.Button(v.name, nil, {RightBadge = RageUI.BadgeStyle.None}, not Couldown, {
                    onActive = function()--              --   --
                        RenderSprite("vip", v.picturemodel, 445, 344, 260, 417, 500)
                    end,   
                    onSelected = function()
                        ESX.ShowNotification("~r~Chargement en cours ...")
                        Citizen.Wait(200)
                        SpawnPed(v.model)
                        local model = v.model
                        local _src = source
                        TriggerEvent('couldown')
                    end 
                });
            end
        end, function()
        end)

        RageUI.IsVisible(PropsSubMenu, function()
            RageUI.List("Trier", {"~h~Props | ~r~Civil", "~h~Props | ~r~Illégal"}, itemIndex, nil, {}, true, {
                onListChange = function(Index, Items)
                    itemIndex = Index
                end,
                    onSelected = function()
                end,
            })
            if itemIndex == 1 then
                for _, v in pairs (legalprops) do
                    RageUI.Button(v.nameprops, nil, {RightBadge = RageUI.BadgeStyle.None}, true, {
                        onSelected = function()
                            local _src = source
                            SpawnObj(v.modelprops)
                            local nameprops = v.nameprops
                        end 
                    });
                end
            else
                for _, v in pairs (illegalprops) do
                    RageUI.Button(v.nameprops, nil, {RightBadge = RageUI.BadgeStyle.None}, true, {
                        onSelected = function()
                            local _src = source
                            SpawnObj(v.modelprops)
                            local nameprops = v.nameprops
                        end 
                    });
                end
            end 
        end, function()
        end)
                
        RageUI.IsVisible(DeletePropsSubMenu, function()
            for k,v in pairs(object) do
                if GoodName(GetEntityModel(NetworkGetEntityFromNetworkId(v))) == 0 then table.remove(object, k) end
                RageUI.Button("Props : "..GoodName(GetEntityModel(NetworkGetEntityFromNetworkId(v))).." ["..v.."]", nil, {}, true, {
                    onActive = function()
                        local entity = NetworkGetEntityFromNetworkId(v)
                        local ObjCoords = GetEntityCoords(entity)
                        DrawMarker(20, ObjCoords.x, ObjCoords.y, ObjCoords.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 33, 172, 235, 255, 1, 0, 2, 1, nil, nil, 0)
                    end,
                    onSelected = function()
                        RemoveObj(v, k)
                    end 
                });
            end
        end, function()
        end)

        RageUI.IsVisible(diversmenu, function()
            -- if Config.RageUI ~= nil and not Config.RageUI.ChangeUIForVIP and Config.RageUI.AdvancedStyle.Obligatoire ~= true then
            --     RageUI.List("Style des Menus", {"Par défaut", "Avancée", "Minimaliste"}, RageUIStyleIndex, "Le Style : Avancée peut consommer plus de resource que le Par défaut", {}, true, {
            --         onListChange = function(index)
            --             RageUIStyleIndex = index 
            --             ChangeRageUIStyle(index)
            --         end
            --     })
            --     --[[RageUI.List("Largeur du Menu", {"Par défaut", "Minimalise"}, RageUIStyleIndex2, nil, {RightLabel=ESX.Config("serverColor").."BETA"}, true, {
            --         onListChange = function(index)
            --             RageUIStyleIndex2 = index 
            --             if RageUIStyleIndex2 == 1 then
            --                 RageUILargeur = 99 
            --                 --SetResourceKvp("Null:preferences:RageUILargeur", 99)
            --                 print(GetResourceKvpString("Null:preferences:RageUILargeur"), "Print")
                            
            --                 RageUI.CloseAll()
            --             elseif RageUIStyleIndex2 == 2 then
            --                 RageUILargeur = 0 
            --                 --SetResourceKvp("Null:preferences:RageUILargeur", 1)
            --                 print(GetResourceKvpString("Null:preferences:RageUILargeur"), "Print")
            --                 RageUI.CloseAll()
            --             end
            --         end
            --     })]]
            -- end
            RageUI.Button("Raccourcis d'armes", nil, {RightLabel = ""}, true, {
            }, weaponsBind)

            if Config.PersonalMenu.ConfigHub then
                RageUI.Button("Configurer l'Hud", nil, {RightLabel = ""}, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        Config.PersonalMenu.ConfigHub()
                    end
                })
            end

            RageUI.Button("Configurer l'interface", nil, {RightLabel = ""}, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    exports["null-core"]:OpenHUDEditor()
                end
            })

            RageUI.Button('Démarche', nil, {RightLabel = getWalkStyle()}, true, {
                onSelected = function()
                end
            }, walksList)
            RageUI.Button("Gestion des blips", nil, {RightLabel = ""}, true, {
            }, blipsGestion)


            --[[RageUI.Button("Enlever son Kevlar", nil, {}, true, {
                onSelected = function()
                    TriggerEvent('ak_services:delKevlar')
                end
            })]]

            for k, v in pairs(Config.Prefer.Submenus) do
                RageUI.Button(v, nil, {RightLabel = ""}, true, {
                    onSelected = function()
                        preferenceCategory = k
                    end
                }, preferenceSubMenu)
            end

            for name, preference in pairs(Config.Prefer.Preferences) do
                if preference.submenu == nil then
                    RageUI.Checkbox(preference.label, preference.description, Config.Prefer.Enabled[name] and true or false, {}, {
                        onChecked = function()
                            setPreferData(name)
                        end,
                        onUnChecked = function()
                            setPreferData(name)
                        end,
                    })
                end
            end

            if null.data.world.props == nil then
                RageUI.Checkbox('Informations objets', nil, false, {}, {
                    onChecked = function()
                        --PlayerState.WorldPropsInfo = true
                    end,
                    onUnChecked = function()
                        --PlayerState.WorldPropsInfo = false
                    end
                })
            else
                RageUI.Checkbox('Informations objets', nil, PlayerState.WorldPropsInfo or false, {}, {
                    onChecked = function()
                        PlayerState.WorldPropsInfo = true
                    end,
                    onUnChecked = function()
                        PlayerState.WorldPropsInfo = false
                    end
                })
            end

            --[[RageUI.List("Style de la visée", {"Par défault", "Gang", "Mire dans l'oeil"}, personalMenu.IndexAim, "Option VIP", {}, true, {
                onListChange = function(index)
                    personalMenu.IndexAim = index 
                end,
                onSelected = function(index)
                    if index == 1 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("Default"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    elseif index == 2 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("Gang1H"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    elseif index == 3 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("FirstPersonAiming"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    end
                end
            })

            RageUI.List("Style pour tenir son arme", {"Par défault", "Gros", "Obése"}, personalMenu.IndexAim2, "Option VIP", {}, true, {
                onListChange = function(index)
                    personalMenu.IndexAim2 = index 
                end,
                onSelected = function(index)
                    if index == 1 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("Default"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    elseif index == 2 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("Fat"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    elseif index == 3 then
                        if GetVIP() then
                            SetWeaponAnimationOverride(GetPlayerPed(-1), GetHashKey("SuperFat"))
                        else
                            ESX.ShowNotification("~r~Vous devez être VIP pour cela !")
                        end
                    end
                end
            })]]

        end, function()
        end)
        RageUI.IsVisible(blipsGestion, function()
            for i = 1, #Config.Prefer.Blips do 
                RageUI.Checkbox(Config.Prefer.Blips[i].label, nil, MyPlayerGet(Config.Prefer.Blips[i].kvpName) == "true" and true or false, {}, {
                    onChecked = function()
                        if Config.Prefer.Blips[i].kvpName ~= nil then 
                            SetResourceKvp(Config.Prefer.Blips[i].kvpName, "true")
                        end
                        MyPlayerSet(Config.Prefer.Blips[i].kvpName, "true")
                        ESX.addAllBlipsFromCategory(Config.Prefer.Blips[i].category)
                    end,
                    onUnChecked = function()
                        MyPlayerSet(Config.Prefer.Blips[i].kvpName, "false")
                        if Config.Prefer.Blips[i].kvpName ~= nil then 
                            SetResourceKvp(Config.Prefer.Blips[i].kvpName, "false")
                        end
                        ESX.removeAllBlipsFromCategory(Config.Prefer.Blips[i].category)
                    end,
                })
            end
        end)

        RageUI.IsVisible(walksList, function()
            for k,v in pairs(Config.walksList) do 
                RageUI.Button(('%s'):format(k), nil, {}, true, {
                    onSelected = function()
                        RageUI.GoBack()
                        ExecuteCommand("walk "..k)
                        setNewWalkStyle(k)
                    end
                })
            end
        end)

        RageUI.IsVisible(preferenceSubMenu, function()
            if preferenceCategory == 'ui' then
                RageUI.Checkbox("Activer le radar", "Vous permet d'activer ou de désactiver la minimap", personalMenu.Radar, {}, {
                    onChecked = function()
                    end,
                    onUnChecked = function()
                    end,
                    onSelected = function(Index)
                        DisplayRadar(personalMenu.Radar)
                        personalMenu.Radar = Index
                    end
                })
                
                RageUI.Checkbox("Activer l'HUD", "Vous permet d'activer ou de désactiver l'HUD", personalMenu.ui, {}, {
                    onChecked = function()
                    end,
                    onUnChecked = function()
                    end,
                    onSelected = function(Index)
                        personalMenu.ui = Index
                        null.DisplayHud(personalMenu.ui)
                    end
                    
                })
    
                RageUI.Checkbox('Mode cinématique', nil, cinemamode, {}, {
                    onChecked = function()
                        ExecuteCommand('noir')
                        cinemamode = true
                    end,
                    onUnChecked = function()
                        ExecuteCommand('noir')
                        cinemamode = false
                    end,
                })
            end

            for name, preference in pairs(Config.Prefer.Preferences) do
                if preference.submenu ~= nil and preference.submenu == preferenceCategory then
                    RageUI.Checkbox(preference.label, preference.description, Config.Prefer.Enabled[name] and true or false, {}, {
                        onChecked = function()
                            setPreferData(name)
                        end,
                        onUnChecked = function()
                            setPreferData(name)
                        end,
                    })
                end
            end
        end)


        RageUI.IsVisible(weaponsBind, function()
            for i = 1, #Config.WeaponsBinds do
                RageUI.Button(('%s'):format(Config.WeaponsBinds[i].label), nil, {RightLabel = getWeaponKeybind(Config.WeaponsBinds[i].id).label}, true, {
                    onSelected = function()
                        weaponBindSelected = Config.WeaponsBinds[i].id
                    end
                }, weaponsBindList)
            end
        end)

        RageUI.IsVisible(weaponsBindList, function()
            RageUI.Button(('%s'):format('Supprimer le raccourci'), "Si vous ne voyez pas votre arme, veuillez attendre quelque secondes", {}, true, {
                onSelected = function()
                    setWeaponKeybind(weaponBindSelected, `WEAPON_UNARMED`, 'Aucun')
                    ESX.ShowNotification('Vous avez défini une nouvelle arme sur votre raccourci')
                    RageUI.GoBack()
                end
            })
            RageUI.Line()
            if #ESX.PlayerData.loadout >= 1 then 
                for k,v in pairs(ESX.PlayerData.loadout) do 
                    local label = v.label
                    local description = "Aucune description"
                    if v.metadata ~= nil then
                        if v.metadata.label ~= nil then
                            label = v.metadata.label
                        end
                        if v.metadata.description ~= nil then
                            description = v.metadata.description
                        end
                    end
                    RageUI.Button(('%s'):format(label), description.."\n\nSi vous ne voyez pas votre arme, veuillez attendre quelque secondes", {}, true, {
                        onSelected = function()
                            setWeaponKeybind(weaponBindSelected, v.name, label)
                            ESX.ShowNotification('Vous avez défini une nouvelle arme sur votre raccourci')
                            RageUI.GoBack()
                        end
                    })
                end
            else
                RageUI.Separator('Vous n\'avez pas d\'arme')
            end
        end)


        RageUI.IsVisible(gestionjob, function()
        
            if ESX.PlayerData.job.grade_name == "boss" then 
                RageUI.Separator("[Entreprise]")

                RageUI.Button("Recruter un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_recruterplayer", GetPlayerServerId(closestPlayer), ESX.PlayerData.job.name)
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Virer un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_virerplayer", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Promouvroir un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_promouvoirplayer", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Rétrograder un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_destituerplayer", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end
        end, function()
        end)

        RageUI.IsVisible(gestionjob3, function()
        
            if ESX.PlayerData.job.grade_name == "responsable" or ESX.PlayerData.job.grade_name == "lieutenant" or ESX.PlayerData.job.grade_name == "captain" then 
                RageUI.Separator("[Entreprise]")

                RageUI.Button("Recruter un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_recruterplayer", GetPlayerServerId(closestPlayer), ESX.PlayerData.job.name)
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                            
                            
                        end
                    end
                })

                RageUI.Button("Virer un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_virerplayer", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end
        end, function()
        end)



        RageUI.IsVisible(gestionjob2, function()

            if ESX.PlayerData.job2.grade_name == "boss" then 
                RageUI.Separator("[Organisation]")

                RageUI.Button("Recruter un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_recruterplayer2", GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name)
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Virer un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_virerplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Promouvroir un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_promouvoirplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Rétrograder un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_destituerplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end

        end, function()
        end)

        RageUI.IsVisible(gestionjob4, function()
        
            if ESX.PlayerData.job2.grade_name == "gerant" then 
                RageUI.Separator("[Organisation]")

                RageUI.Button("Recruter un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_recruterplayer2", GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name)
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })

                RageUI.Button("Virer un employé", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_virerplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end
        end, function()
        end)


        RageUI.IsVisible(actioninventory, function()

            RageUI.Separator("Nom : ~g~"..tostring(label).." ~s~/ Quantité : ~g~"..tostring(count).."")

            RageUI.Button("> Utiliser", nil, {}, not itemCooldown, {
                onSelected = function()
                    itemCooldown = true
                    TriggerServerEvent('esx:useItem', name)
                    ExecuteCommand("me utilise x1 "..label)
                    count = count - 1
                    if count < 0 then 
                        RageUI.GoBack()
                    end
                    Citizen.SetTimeout(1500, function() itemCooldown = false end)
                end
            })

            RageUI.Button("> Jeter", nil, {}, not itemCooldown, {
                onSelected = function()

                    local check, quantity = CheckQuantity(null.fct.input('Montant :', false, 999, "number"))
                    if check then 
                        if tonumber(quantity) > tonumber(count) then 
                            ESX.ShowNotification('Vous n\'en n\'avez pas assez')
                        else
                            itemCooldown = true
                            TriggerServerEvent('esx:dropInventoryItem', 'item_standard', name, tonumber(quantity))
                            RageUI.GoBack()
                            Citizen.SetTimeout(1500, function() itemCooldown = false end)
                        end
                    else
                        ESX.ShowNotification('Quantité invalide')
                    end
                end
            })

            RageUI.Button("> Donner", nil, {}, not itemCooldown, {
                onActive = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestDistance ~= -1 and closestDistance <= 3 then
                        PlayerMarker2(closestPlayer)
                    end
                end,
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    local check, quantity = CheckQuantity(null.fct.input('Montant :', false, 999, "number"))
                    if closestDistance ~= -1 and closestDistance <= 3 then
                        if check then 
                            local closestPed = GetPlayerPed(closestPlayer)
                            if tonumber(quantity) > tonumber(count) then 
                                ESX.ShowNotification('Vous n\'en n\'avez pas asser')
                            else
                                if not ESX.ContribItem(name) then 
                                    itemCooldown = true
                                    TriggerServerEvent('esx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_standard', name, quantity)
                                    ExecuteCommand("me donne un/une "..label.." à la personne")
                                    RageUI.GoBack()
                                    Citizen.SetTimeout(1500, function() itemCooldown = false end)
                                else
                                    ESX.ShowNotification('Vous ne pouvez pas donner cette objets')
                                end
                            end
                        else
                            ESX.ShowNotification('Arguments Manquants !')
                        end
                    end
                end
            })
            
        end , function()
        end)

        RageUI.IsVisible(actionweapon, function()
            while weaponData == nil do Wait(10) end
            RageUI.Separator("Nom : "..tostring(label).."")

            if weaponData.permanent == true then 
                RageUI.Separator("Vous ne pouvez pas donner cette arme")
            else
                RageUI.Button("> Donner", nil, {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end,
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            local closestPed = GetPlayerPed(closestPlayer)
                            TriggerServerEvent("esx:giveInventoryItem", GetPlayerServerId(closestPlayer), "item_weapon", name, nil)
                            RageUI.CloseAll()
                        else
                            ESX.ShowNotification("Personne aux alentours")
                        end
                    end
                })
            end

        end, function()
        end)


        RageUI.IsVisible(billingmenu, function()
            if #BillData ~= 0 then
                for i = 1, #BillData, 1 do
                    RageUI.Button(BillData[i].label, nil, {RightLabel = '$' .. ESX.Math.GroupDigits(BillData[i].amount)}, true, {
                        onSelected = function()
                            ESX.TriggerServerCallback('Null:esx_billing:payBill', function()
                                RageUI.GoBack()
                            end, BillData[i].id)
                        end,
                        onActive = function()
                            RageUI.Info(
                                "Facture #"..i, 
                                {
                                    "~s~Raison:", 
                                    "~s~Montant:",
                                    "~s~Date:",
                                },
                                {
                                    BillData[i].label,
                                    ESX.Math.GroupDigits(BillData[i].amount),
                                    BillData[i].date
                                }
                            )
                        end
                    })
                end
            else
                RageUI.Separator('')
                RageUI.Separator('Vous n\'avez aucune facture')
                RageUI.Separator('')
            end
        end, function()
        end)
        
        RageUI.IsVisible(gestionlicense, function()
            
            RageUI.Button("Montrer sa carte d'identité", nil, {RightLabel = '→'}, true, {
                onActive = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestDistance ~= -1 and closestDistance <= 3 then
                        PlayerMarker2(closestPlayer)
                    end
                end,
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestDistance ~= -1 and closestDistance <= 3.0 then
                        TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
                    else
                        ESX.ShowNotification("Aucun joueurs aux alentours")
                    end
                end
            })

            RageUI.Button("Regarder sa carte d'identité", nil, {}, true, {
                onSelected = function()
                    TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
                end
            })
            if PlayerState.myLicense["drive"] then
                RageUI.Button("Montrer son permis de conduire", nil, {RightLabel = '→'}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end,
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3.0 then
                            TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), "driver")
                        else
                            ESX.ShowNotification("Aucun joueurs aux alentours")
                        end
                    end
                })

                RageUI.Button("Regarder son permis de conduire", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), "driver")
                    end
                })
            end

            if PlayerState.myLicense["weapon"] or PlayerState.myLicense["weapon2"] then
                RageUI.Button("Montrer son permis de port d'armes", nil, {RightLabel = '→'}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end,
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3.0 then
                            TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), "weapon")
                        else
                            ESX.ShowNotification("Aucun joueurs aux alentours")
                        end
                    end
                })

                RageUI.Button("Regarder son permis de port d'armes", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), "weapon")
                    end
                })
            end
        
        
        end, function()
        end)
        if not RageUI.Visible(mainf5) and 
        not RageUI.Visible(invetory) and 
        not RageUI.Visible(portefeuille) and 
        not RageUI.Visible(guideSubMenu) and 
        not RageUI.Visible(streamerMenu) and 
        not RageUI.Visible(vipMenu) and 
        not RageUI.Visible(openVipPeds) and 
        not RageUI.Visible(openVipPeds2) and 
        not RageUI.Visible(vetmenu) and 
        not RageUI.Visible(vehicle) and
        not RageUI.Visible(radio) and
        not RageUI.Visible(esthetiquemenu) and
        not RageUI.Visible(diversmenu) and

        not RageUI.Visible(actioninventory) and 
        not RageUI.Visible(infojob) and 
        not RageUI.Visible(infojob2) and 
        not RageUI.Visible(gestionjob) and
        not RageUI.Visible(gestionjob3) and
        not RageUI.Visible(gestionjob2) and 
        not RageUI.Visible(gestionjob4) and 
        not RageUI.Visible(walksList) and 
        not RageUI.Visible(preferenceSubMenu) and 
        not RageUI.Visible(blipsGestion) and 
        not RageUI.Visible(weaponsBind) and 
        not RageUI.Visible(weaponsBindList) and 

        not RageUI.Visible(FidelCoinsMenu) and
        not RageUI.Visible(statusentreprise) and
        not RageUI.Visible(billingmenu) and 
        not RageUI.Visible(objets) and 

        not RageUI.Visible(weapons) and
        not RageUI.Visible(gestionaccesories) and
        not RageUI.Visible(actionweapon) and 
        not RageUI.Visible(gestionlicense) then 
            inPersoMenu = false
            mainf5 = RMenu:DeleteType("mainf5")
        end
    end
end)

RegisterKeyMapping("+menuf5", "Permet d'ouvir le menu F5", "keyboard", "F5")
RegisterCommand("+menuf5", function()
    if not ESX.getIsDead() then 
        openMenuF5()
    end
end)

local isadmin = false
local adminNbr = 0
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    Wait(5000)
    TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
    while true do
        Wait(5000)
        if ESX.PlayerData ~= nil and ESX.PlayerData.group ~= "user" and StaffHasPerm("INFINITE_MAX_WEIGHT") and nTable.infiniteMaxWeight then
            --TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
            NoCourir = false
        else 
            --[[TriggerEvent("Null:skinchanger:getSkin", function(skin)
                if Config.ListBags[PlayerState.playerSex][skin.bags_1] ~= nil then
                    if ESX.PlayerData.maxWeight ~= Config.ListBags[PlayerState.playerSex][skin.bags_1].weight then 
                        TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vbag',Config.ListBags[PlayerState.playerSex][skin.bags_1].weight)
                    end
                else
                    if ESX.PlayerData.maxWeight ~= 24 then 
                        TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
                    end
                end
            end)]]

            if ESX.GetCurrentWeight() > ESX.PlayerData.maxWeight then
                DrawMissionText('~r~Vous êtes trop lourd, Vous ne pouver plus courrir', 5000)
                NoCourir = true
            else
                NoCourir = false
            end
        end
    end
end))

RegisterNetEvent("Null:changeBag", function(newbag)
    if ESX.PlayerData ~= nil and ESX.PlayerData.group ~= "user" and StaffHasPerm("INFINITE_MAX_WEIGHT") and nTable.infiniteMaxWeight then
        TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
        NoCourir = false
    else
        -- if Config.ListBags[PlayerState.playerSex][newbag] ~= nil then
        --     if ESX.PlayerData.maxWeight ~= Config.ListBags[PlayerState.playerSex][newbag].weight then 
        --         TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vbag',Config.ListBags[PlayerState.playerSex][newbag].weight)
        --     end
        -- else 
        --     if ESX.PlayerData.maxWeight ~= Config.MaxWeight then 
        --         TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
        --     end
        -- end

        -- if (ESX.PlayerData.vip and ESX.PlayerData.vip.isVip and ESX.PlayerData.maxWeight ~= Config.MaxWeightVIP) or (ESX.PlayerData.vip and ESX.PlayerData.vip.isVip == false and ESX.PlayerData.maxWeight ~= Config.MaxWeight) then 
        --     TriggerServerEvent('Null:ChangeWeightInventory', PlayerState.playerSex, 'vnobag')
        -- end
    end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        if NoCourir then
            Citizen.Wait(10)
        else
            Wait(5000)
        end

        if NoCourir then
            DisableControlAction(0, 22, true) -- INPUT_JUMP
            DisableControlAction(0, 258, true) -- JUMP
            DisableControlAction(0, 259, true) -- JUMP
            DisableControlAction(0,21,true) -- disable sprint
            DisableControlAction(0,24,true) -- disable attack
            DisableControlAction(0,25,true) -- disable aim
            DisableControlAction(0,47,true) -- disable weapon
            DisableControlAction(0,58,true) -- disable weapon
            DisableControlAction(0,263,true) -- disable melee
            DisableControlAction(0,264,true) -- disable melee
            DisableControlAction(0,257,true) -- disable melee
            DisableControlAction(0,140,true) -- disable melee
            DisableControlAction(0,141,true) -- disable melee
            DisableControlAction(0,142,true) -- disable melee
            DisableControlAction(0,143,true) -- disable melee
            DisableControlAction(0, 22, true) -- INPUT_JUMP
            DisableControlAction(0, 44, true) -- INPUT_COVER
            DisableControlAction(0, 45, true) -- INPUT_RELOAD
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 143, true) -- INPUT_MELEE_BLOCK
            DisableControlAction(0, 144, true) -- PARACHUTE DEPLOY
            DisableControlAction(0, 145, true) -- PARACHUTE DETACH
            DisableControlAction(0, 243, true) -- INPUT_ENTER_CHEAT_CODE
            DisableControlAction(0, 257, true) -- INPUT_ATTACK2
            DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
            DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2
            DisableControlAction(0, 73, true) -- INPUT_X
        end
    end
end))

local function loadAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Citizen.Wait(0)
	end
end


function PlayAnim()
	local ped = PlayerPedId()
	deletePhone()
	if DoesEntityExist(ped) and not IsEntityDead(ped) then
		if not PlayerState.inPauseMenu then 
			loadAnimDict("cellphone@")
			RequestModel(phoneModel)
			while not HasModelLoaded(phoneModel) do
				Citizen.Wait(1)
			end
			phoneProp = CreateObject(phoneModel, 1.0, 1.0, 1.0, 0, 1, 0)
		
			local bone = GetPedBoneIndex(ped, 28422)
			AttachEntityToEntity(phoneProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
			if not IsPlayerFreeAiming(PlayerId()) then
				TaskPlayAnim(ped, "cellphone@", 'cellphone_text_to_call', 3.0, -1, -1, 50, 0, false, false, false)
			elseif IsPlayerFreeAiming(PlayerId()) then 
				TaskPlayAnim(ped, "cellphone@", 'cellphone_text_to_call', 3.0, -1, -1, 50, 0, false, false, false)
			end
			if IsEntityPlayingAnim(PlayerPedId(), 'cellphone@', 'cellphone_text_to_call', 3) then
				DisableActions(ped)
			elseif IsEntityPlayingAnim(PlayerPedId(), 'cellphone@', 'cellphone_text_to_call', 3) == true then
				DisableActions(ped)
			end
		end 
	end 
end


function deletePhone()
	if phoneProp ~= 0 then
		Citizen.InvokeNative(0xAE3CBE5BF394C9C9 , Citizen.PointerValueIntInitialized(phoneProp))
		phoneProp = 0
	end
end
cutseneStart = function(cutsceneName)
    local plyrId = PlayerPedId()
    local playerClone = ClonePed_2(plyrId, 0.0, false, true, 1)

        RequestCutscene(cutsceneName, 8) 
    
        while not (HasCutsceneLoaded()) do
            Wait(0)
        end

    SetBlockingOfNonTemporaryEvents(playerClone, true)
    SetEntityVisible(playerClone, false, false)
    SetEntityInvincible(playerClone, true)
    SetEntityCollision(playerClone, false, false)
    FreezeEntityPosition(playerClone, true)
    SetPedHelmet(playerClone, false)
    RemovePedHelmet(playerClone, true)

    SetCutsceneEntityStreamingFlags('MP_1', 0, 1)
    RegisterEntityForCutscene(plyrId, 'MP_1', 0, GetEntityModel(plyrId), 64)

    SetCutsceneEntityStreamingFlags('MP_2', 0, 1)
    RegisterEntityForCutscene(plyrId, 'MP_2', 3, GetEntityModel(plyrId), 64)

    SetCutsceneEntityStreamingFlags('MP_3', 0, 1)
    RegisterEntityForCutscene(plyrId, 'MP_3', 3, GetEntityModel(plyrId), 64)

    SetCutsceneEntityStreamingFlags('MP_4', 0, 1)
    RegisterEntityForCutscene(plyrId, 'MP_4', 3, GetEntityModel(plyrId), 64)
    
    RequestCollisionAtCoord(x, y, z)

    Wait(10)
    StartCutscene(0)
    Wait(10)
    ClonePedToTarget(playerClone, plyrId)
    Wait(10)
    DeleteEntity(playerClone)
    playerClone = nil
end