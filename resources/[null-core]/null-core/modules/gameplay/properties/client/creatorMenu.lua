local function DestroyCam()
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
	SetCamActive(cam,  false)	
	FreezeEntityPosition(PlayerPedId(), false)
	RenderScriptCams(false,  false,  0,  false,  false)
    SetFocusEntity(PlayerPedId())
end

local function CreatCam(type)
    DestroyCam()
	local ped = PlayerPedId()
	if type == 'Low' then 
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(265.6078, -995.8491, -99.0086, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 265.9317, -999.4464, -99.0086)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 87.69)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)
	elseif type == 'Middle' then
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(-616.8566, 59.3575, 98.2000, 0.0, 0.0, 0.0)
		SetCamCoord(cam, -616.8566, 59.3575, 98.2000)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 195.59)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)	
	elseif type == 'High' then 
	    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(-1459.1700, -520.5855, 56.9247, 0.0, 0.0, 0.0)
		SetCamCoord(cam, -1459.1700, -520.5855, 56.9247)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 150.2664)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)	
	elseif type == 'Motel' then 
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(151.0994, -1007.8073, -98.9999, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 151.0994, -1007.8073, -98.9999)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 337.79)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)	
	elseif type == 'Entrepot1' then 
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(1026.8707, -3099.8710, -38.9998, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 1026.8707, -3099.8710, -38.9998)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 88.76)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)
	elseif type == 'Entrepot2' then 
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(1072.8447, -3100.0390, -38.9999, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 1072.8447, -3100.0390, -38.9999)
		SetCamActive(cam,  true)
		SetCamRot(cam, 0.0, 0.0, 91.85)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)	
	elseif type == 'Entrepot3'	then
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(1104.7231, -3100.0690, -38.9999, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 1104.7231, -3100.0690, -38.9999)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 85.68)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)
    elseif type == 'Bunker1' then
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(512.4276, 4842.775, -62.589, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 512.4276, 4842.775, -62.589)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 85.68)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)
    elseif type == 'Submarine1' then
		cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
		SetFocusArea(512.4276, 4842.775, -62.589, 0.0, 0.0, 0.0)
		SetCamCoord(cam, 512.4276, 4842.775, -62.589)
	    SetCamActive(cam,  true)
	  	SetCamRot(cam, 0.0, 0.0, 85.68)
		RenderScriptCams(true,  false,  0,  true,  true)
		FreezeEntityPosition(ped, true)
	end	
end

local RightLabelExit = "Non définis"
local isimmeuble = false
local function OpenMenu(staff)
    local menu = RageUI.CreateMenu('Création propriété', "Paramètre disponibles")

    isimmeuble = false
    RightLabelExit = "Non définis"
    local DATA = {
        NAME = "", 
        LABEL = "",
        PRICE = 0,
        INTERIORSELECTED = nil,
        immeuble = 0,
        POIDS = 0,
        POSITION = {
            ENTER = nil,
            EXIT = nil, 
            COFFRE = nil
        }
    }
    local MENU = {
        MAKEVISUAL = false,
        IMMEUBLE = false,
        LIST = {
            LIST = {
                { Name = "Petite maison", Value = "Low"},
                { Name = "Petite villa", Value = "Middle"},
                { Name = "Villa luxe", Value = "High"},
                { Name = "Motel", Value = "Motel"},
                { Name = "Entrepot (grand)", Value = "Entrepot1"},
                { Name = "Entrepot (moyen)", Value = "Entrepot2"},
                { Name = "Entrepot (petit)", Value = "Entrepot3"},
            },
            INDEX = 1
        },
        LIST2 = {
            LIST2 = {
                { Name = "Aucun immeuble", Value = 0},
                { Name = "Immeuble N°1", Value = 1, coords = vector3(-773.5578, 311.4858, 85.6981)},
                { Name = "Immeuble N°2", Value = 2, coords = vector3(-618.2738, 36.48872, 43.57004)},
                { Name = "Immeuble N°3", Value = 3, coords = vector3(-882.6196, -436.1918, 39.5999)},
                { Name = "Immeuble N°4", Value = 4, coords = vector3(-47.73304, -585.7634, 37.95544)},
                { Name = "Immeuble N°5", Value = 5, coords = vector3(-66.08768, -801.2214, 44.22728)},
                { Name = "Immeuble N°6", Value = 6, coords = vec3(288.377838, -1095.023804, 29.419659)},
                { Name = "Immeuble N°7", Value = 7, coords = vector3(-736.7746, -2275.542, 13.43744)}
            },
            INDEX2 = 1
        }
    }
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Wait(0)

        RageUI.IsVisible(menu, function()
            RageUI.Button('Nom de la propriété', nil, {RightLabel = DATA.LABEL or "~r~Indéfini~s~"}, true, {
                onSelected = function() 
                    local input = null.fct.input("Nom de la propriété")
                    if input and input ~= "" then 
                        DATA.LABEL = tostring(input)
                        DATA.NAME = string.lower(string.gsub(input, "%s+", "_"))
                    else 
                        ESX.ShowNotification("~r~Création de propriété~s~\nVous avez mal renseigné ce paramètre.")
                    end
                end
            })            
            RageUI.Button('Position de l\'entrée', RightLabelExit, {}, not isimmeuble, {
                onSelected = function() 
                    local pPed = PlayerPedId()
                    local pCoords = GetEntityCoords(pPed)
                    DATA.POSITION.EXIT = pCoords
                    RightLabelExit = DATA.POSITION.EXIT
                end
            })
            RageUI.Checkbox('Visualiser l\'intérieur', nil, MENU.MAKEVISUAL, {}, {
                onChecked = function()
                    MENU.MAKEVISUAL = true
                end,
                onUnChecked = function()
                    MENU.MAKEVISUAL = false
                    DestroyCam()
                end
            })
            RageUI.List("Intérieur", MENU.LIST.LIST, MENU.LIST.INDEX, nil, {}, true, {
                onListChange = function(Index, Item)
                    MENU.LIST.INDEX = Index;
                    if MENU.MAKEVISUAL then
                        CreatCam(Item.Value)
                    end
                    DATA.INTERIORSELECTED = Item.Value
                    DATA.PRICE = Config.Properties.List[Item.Value].prices.lifetime
                    DATA.PRICEPERMOUNT = Config.Properties.List[Item.Value].prices.permount
                    DATA.MaxWeight = Config.Properties.List[Item.Value].MaxWeight
                    DATA.POSITION.ENTER = Config.Properties.List[Item.Value].positions.inside
                    DATA.POSITION.COFFRE = Config.Properties.List[Item.Value].positions.cam_coords
                end
            })
            --[[RageUI.Checkbox('Immeuble', nil, MENU.IMMEUBLE, {}, {
                onChecked = function()
                    MENU.IMMEUBLE = true
                    isimmeuble = true
                end,
                onUnChecked = function()
                    MENU.IMMEUBLE = false
                    DATA.immeuble = "0"
                    isimmeuble = false
                end
            })
            if MENU.IMMEUBLE then
                RageUI.List("N° de l'immeuble", MENU.LIST2.LIST2, MENU.LIST2.INDEX2, "Appuyez sur entrée pour vous téléporter a l'immeuble", {}, true, {
                    onListChange = function(Index, Item)
                        MENU.LIST2.INDEX2 = Index;

                        DATA.immeuble = tostring(Item.Value)
                    end,
                    onSelected = function()
                        for k,v in pairs(MENU.LIST2.LIST2) do
                            if tostring(v.Value) == DATA.immeuble then
                                if v.coords ~= nil then
                                    SetEntityCoords(PlayerPedId(), v.coords)
                                end
                            end
                        end
                    end
                })
            end]]
            RageUI.Line()
            RageUI.Button('Valider', nil, {Color = { BackgroundColor = {50, 230, 50, 150} }}, true, {
                onSelected = function() 
                    if DATA.NAME ~= "" and DATA.MaxWeight ~= nil and DATA.POSITION.EXIT ~= nil and DATA.POSITION.ENTER ~= nil then
                        TriggerServerEvent("null:properties:CreatedProperties", DATA)
                        RageUI.CloseAll()
                        DestroyCam()
                    else
                        ESX.ShowNotification("Vous n'avez pas completer tous les champs")
                    end
                end
            })
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
            DestroyCam()
            if not staff then
                openRealestateagentMenu()
            else
                TriggerServerEvent("AdminMenu:checkIsAdmin")
            end
        end
    end
end

RegisterNetEvent("null:properties:createmenu")
AddEventHandler("null:properties:createmenu", function(staff)
    OpenMenu(staff)
end)