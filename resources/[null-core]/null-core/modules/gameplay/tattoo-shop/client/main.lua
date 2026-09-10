local Tatouage = {}
local playerTatoos = {}
local currentPreviewTatoo = nil
local cleaning = false
function ShowHelpNotification(msg)
    AddTextEntry('HelpNotification', msg)
	BeginTextCommandDisplayHelp('HelpNotification')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

RegisterNetEvent("Null1buyTattoo")
AddEventHandler("Null1buyTattoo", function(ok)
    if ok then
        RageUI.Popup({message = "~g~Tatouage acheté"})
    else
        RageUI.Popup({message = "~r~Vous n'avez pas assez d'argent!"})
    end
end)

RegisterNetEvent("null:tattoo:player:callback")
AddEventHandler("null:tattoo:player:callback", function(ok)
    if ok ~= nil then
        playerTatoos = json.decode(ok)
        ClearPedDecorations(PlayerPedId())
        for _,t in pairs(playerTatoos) do
            AddPedDecorationFromHashes(PlayerPedId(),t.cat,t.name) 
        end
    end
end)

local firstLoad = false

AddEventHandler("Null:skinchanger:loadSkin", function(skin)
	if not firstLoad then
		Citizen.CreateThread(function()
			while not GetEntityModel(PlayerPedId() == `mp_m_freemode_01` or GetEntityModel(PlayerPedId()) == `mp_f_freemode_01`) do
				Citizen.Wait(10)
			end
			Citizen.Wait(75)
			TriggerServerEvent("null:tattoo:player:request:tattoo")
		end)
		firstLoad = true
	else
		Citizen.Wait(75)
		for _,t in pairs(playerTatoos) do
			AddPedDecorationFromHashes(PlayerPedId(),t.cat,t.name) 
		end
	end
end)



RegisterNetEvent("null:tattoo:clean")
AddEventHandler("null:tattoo:clean", function(ok)
    if ok then
        playerTatoos = {}
        DoScreenFadeOut(1000)
        while not IsScreenFadedOut() do Citizen.Wait(10) end
        ClearPedDecorations(PlayerPedId())
        Citizen.Wait(200)
        DoScreenFadeIn(1000)
        cleaning = false
        RageUI.Popup({message = "~g~Tous vos Tatouages ont étés effacés"})
    else
        RageUI.Popup({message = "~r~Vous n'avez pas assez d'argent!"})
    end
end)

-- ============================================================================
-- ⚠️  Menu RageUI désactivé — migré vers le nouveau ped-shop (mode "tattoo").
--   Les markers tattoo appellent maintenant `OpenShop("tattoo", brandId)`.
--   Toute la logique de persistence ci-dessus (load au login,
--   `null:tattoo:player:callback`, `null:tattoo:clean`) reste active et
--   nécessaire au chargement des tattoos du joueur.
-- ============================================================================

function OpenTattooRageUIMenu()
    if exports["null-core"] and exports["null-core"].OpenShop then
        exports["null-core"]:OpenShop("tattoo", nil)
    end
end

--[[ ANCIEN MENU RageUI (désactivé — gardé pour référence) :

RMenu.Add('tattoo', "main", RageUI.CreateMenu("", "Que voulez-vous faire ?", nil, nil))
for k,v in pairs(Config.Tattoo.TattooCategories) do
    RMenu.Add('tattoo', 'part'..k, RageUI.CreateSubMenu(RMenu:Get('tattoo', 'main'), "", "Sélectionnez votre Tattoo"))
    RMenu:Get('tattoo', 'part'..k).Closed = function()
        ClearPedDecorations(PlayerPedId())
        for _,t in pairs(playerTatoos) do
            ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
        end
    end
end
RMenu:Get('tattoo', 'main').EnableMouse = false
RMenu:Get('tattoo', 'main').Closed = function()
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
        local isMale = skin.sex == 0
        TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadSkin', skin)
            TriggerEvent('esx:restoreLoadout')
            end)
        end)
    end)
    ClearPedDecorations(PlayerPedId())
    for _,t in pairs(playerTatoos) do
        ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
    end
    FreezeEntityPosition(GetPlayerPed(-1), false)
    Tatouage.Menu = false 
end

function OpenTattooRageUIMenu()
    null.DisplayHud(false)
    if Tatouage.Menu then
        Tatouage.Menu = false
    else
        Tatouage.Menu = true
        RageUI.Visible(RMenu:Get('tattoo', 'main'), true)

        Citizen.CreateThread(function()
			while Tatouage.Menu do
                FreezeEntityPosition(GetPlayerPed(-1), true)
                RageUI.IsVisible(RMenu:Get('tattoo', 'main'), function()
                    RageUI.Button("Supprimer vos Tatouages actuelles", nil, { RightLabel = "~g~50000 ~s~$" }, not cleaning, {
                        onSelected = function()
                            cleaning = true
                            TriggerServerEvent("null:tattoo:pay:clean")
                        end
                    })
                    for k,v in pairs(Config.Tattoo.TattooCategories) do
                        RageUI.Button(v.name, nil, {}, true, {
                            onSelected = function()
                                --cleaning = true
                                --TriggerServerEvent("null:tattoo:pay:clean")
                            end
                        }, RMenu:Get('tattoo', 'part'..k))
                    end
                end)
                for k,v in pairs(Config.Tattoo.TattooCategories) do
                    RageUI.IsVisible(RMenu:Get('tattoo', 'part'..k), function()
                        RageUI.Button("Supprimer la prévisualisation actuelle", nil, {}, true, {
                            onSelected = function()
                                ClearPedDecorations(PlayerPedId())
                                for _,t in pairs(playerTatoos) do
                                    ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
                                end
                            end
                        })
                        for index,tatoo in pairs(Config.Tattoo.TattooList[v.value]) do
                            RageUI.Button("Tatouage #"..index, nil, { RightLabel = "~g~"..tatoo.price.."~s~ $ →" }, true, {
                                onSelected = function()
                                    local needModif = true
                                    for _,t in pairs(playerTatoos) do
                                        if GetHashKey(Config.Tattoo.TattooCategories[k].value) == playerTatoos.cat and GetHashKey(tatoo.nameHash) == playerTatoos.name then
                                            needModif = false
                                        end
                                    end
                                    if needModif then
                                        table.insert(playerTatoos, {cat = GetHashKey(Config.Tattoo.TattooCategories[k].value), name = GetHashKey(tatoo.nameHash)})
                                        TriggerServerEvent("null:tattoo:pay", tatoo.price, playerTatoos)
                                    else
                                        ESX.showNotification('~r~Vous possédez déjà ce tatouage!')
                                    end
                                end,
                                onActive = function()
                                    if currentPreviewTatoo ~= GetHashKey(tatoo.nameHash) then 
                                        ClearPedDecorations(PlayerPedId())
                                        for _,t in pairs(playerTatoos) do
                                            ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
                                        end
                                        ApplyPedOverlay(PlayerPedId(),GetHashKey(Config.Tattoo.TattooCategories[k].value),GetHashKey(tatoo.nameHash)) 
                                    end
                                    currentPreviewTatoo = GetHashKey(tatoo.nameHash)
                                end
                            })
                        end
                    end)
                end
				Wait(0)
			end
            null.DisplayHud(true)
		end) 
	end
end
]]--