-- ============================================================================
-- ⚠️  Module migré vers le nouveau ped-shop (mode "barber").
--   L'ancien menu RageUI complet est conservé ci-dessous en commentaire pour
--   référence, mais n'est plus utilisé : les markers `Config.Barber.List`
--   appellent maintenant `OpenShop("barber", brandId)` directement (cf.
--   `modules/_core/markers/client/setup.lua`).
--
--   La fonction globale `OpenMenuBarberShop()` est conservée comme alias
--   pour compatibilité avec d'éventuels appels externes.
-- ============================================================================

function OpenMenuBarberShop()
    if exports["null-core"] and exports["null-core"].OpenShop then
        exports["null-core"]:OpenShop("barber", nil)
    end
end

--[[ ANCIEN MENU RageUI (désactivé — gardé pour référence) :

Creator = {
    Indexsexe = 1,
    Motherindex = 1,
    DadIndex = 1,
    PeauCoulour = 5,
    PeauCoulour2 = 0.5;
    Ressemblance = 5,
    Ressemblance2 = 0.5,

    Hairindex = 1,
    Beardindex = 1,
    Indexeyebow = 1,
    EyexIndex = 1,
    NoseoneIndex = 1,

    Hairlist = {},
    BeardList = {},
    EyebowList = {},
    EyesColorList = {},
    NosoneList = {},

    ColorHair = {
        primary = {1, 1},
        secondary = {1, 1},
    },

    ColorBeard = {
        primary = {1, 1},
        secondary = {1, 1},
    },

    ColorEyebow = {
        primary = {1, 1},
        secondary = {1, 1},
    },

    OpaPercent = 0,
    OpePercentEyebow = 0,
    PercentLargenose = 0,
    PercentHauteurnose = 0,
    PercentCrochuNose = 0,
    PercentJoueHauteur = 0,
    PercentJoueCreux = 0,
    PercentJoueCreuxx = 0,
    PercentMacoire1 = 0,
    PercentMacoire2 = 0,
    PercentMentonHauteur = 0,
    PercentMentonLargeur = 0,
    DadList = {"Benjamin", "Daniel", "Joshua", "Noah", "Andrew", "Juan", "Alex", "Isaac", "Evan", "Ethan", "Vincent", "Angel", "Diego", "Adrian", "Gabriel", "Michael", "Santiago", "Kevin", "Louis", "Samuel", "Anthony", "Pierre", "Niko"},
    MotherList = {"Adelyn", "Emily", "Abigail", "Beverly", "Kristen", "Hailey", "June", "Daisy", "Elizabeth", "Addison", "Ava", "Cameron", "Samantha", "Madison", "Amber", "Heather", "Hillary", "Courtney", "Ashley", "Alyssa", "Mia", "Brittany"},
}

Citizen.CreateThread(function()
    for i = 1, 190 do
        table.insert(Creator.Hairlist, i)
    end
    for i = 1, 28 do 
        table.insert(Creator.BeardList, i)
    end
    for i = 1, 73 do 
        table.insert(Creator.EyebowList, i)
    end
    for i = 1, 31 do
        table.insert(Creator.EyesColorList, i)
    end
end)


local buy = false
Citizen.CreateThread(function()
    SetPlayerControl(PlayerId(), true, 12)
end)
function OpenMenuBarberShop()
    local menu = RageUI.CreateMenu("", "Changez votre coupe de cheveux")
    menu.EnableMouse = true 
    RageUI.Visible(menu, not RageUI.Visible(menu))
    SetPlayerControl(PlayerId(), false, 12)
	while menu do
		Citizen.Wait(0)
		RageUI.IsVisible(menu, function()
            RageUI.List("Cheveux", Creator.Hairlist, Creator.Hairindex, nil, nil, true, {
                onListChange = function(index)
                    Creator.Hairindex = index
                    TriggerEvent("Null:skinchanger:change", "hair_1", index)
                end
            })

            RageUI.List("Barbe", Creator.BeardList, Creator.Beardindex, nil, nil, true, {
                onListChange = function(index)
                    Creator.Beardindex = index 
                    TriggerEvent("Null:skinchanger:change", "beard_1", Creator.Beardindex)
                end
            })

            RageUI.List("Sourcil", Creator.EyebowList, Creator.Indexeyebow, nil, nil, true, {
                onListChange = function (index)
                    Creator.Indexeyebow = index 
                    TriggerEvent("Null:skinchanger:change", "eyebrows_1", Creator.Indexeyebow)
                end
            })

            RageUI.Button("Payer la coupe", nil, {RightLabel = "~g~100 $"}, true, {
                onSelected = function()
                    ESX.TriggerServerCallback("barber:getmoney", function(cb)
                        if cb == true then
                            buy = true
                            ESX.ShowAdvancedNotification("Information", "Barber Shop", "Vous avez payé votre coupe avec succès !\nA bientôt")
                            TriggerEvent('Null:skinchanger:getSkin', function(skin)
                                TriggerServerEvent('Null:esx_skin:save', skin)
                            end)
                            SetPlayerControl(PlayerId(), true, 12)
                            RageUI.CloseAll()
                        else
                            ESX.ShowAdvancedNotification("Information", "Barber Shop", "Vous ne disposez pas des fonds nécéssaires !")
                            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                                TriggerEvent('Null:skinchanger:loadSkin', skin)
                            end) 
                            SetPlayerControl(PlayerId(), true, 12)
                            RageUI.CloseAll()
                        end
                    end)
                end
            })
        end, function()
            RageUI.Separator('')
            RageUI.ColourPanel("Couleur Principale", RageUI.PanelColour.HairCut, Creator.ColorHair.primary[1], Creator.ColorHair.primary[2], {
                onColorChange = function(MinimumIndex, CurrentIndex)
                    Creator.ColorHair.primary[1] = MinimumIndex
                    Creator.ColorHair.primary[2] = CurrentIndex
                    TriggerEvent("Null:skinchanger:change", "hair_color_1" ,Creator.ColorHair.primary[2])
                end
            }, 1)

            RageUI.ColourPanel("Couleur secondaire", RageUI.PanelColour.HairCut, Creator.ColorHair.secondary[1], Creator.ColorHair.secondary[2], {
                onColorChange = function(MinimumIndex, CurrentIndex)
                    Creator.ColorHair.secondary[1] = MinimumIndex
                    Creator.ColorHair.secondary[2] = CurrentIndex
                    TriggerEvent("Null:skinchanger:change", "hair_color_2", Creator.ColorHair.secondary[2])
                end
            }, 1)

            RageUI.PercentagePanel(Creator.OpaPercent, 'Opacité', '0%', '100%', {
                onProgressChange = function(Percentage)
                    Creator.OpaPercent = Percentage
                    TriggerEvent('Null:skinchanger:change', 'beard_2', Percentage*10)
                end
            }, 2) 

            RageUI.ColourPanel("Couleur de la barbe", RageUI.PanelColour.HairCut, Creator.ColorBeard.secondary[1], Creator.ColorBeard.secondary[2], {
                onColorChange = function(MinimumIndex, CurrentIndex)
                    Creator.ColorBeard.secondary[1] = MinimumIndex
                    Creator.ColorBeard.secondary[2] = CurrentIndex
                    TriggerEvent("Null:skinchanger:change", "beard_3", Creator.ColorBeard.secondary[2])
                end
            }, 2)

            RageUI.PercentagePanel(Creator.OpePercentEyebow, 'Opacité', '0%', '100%', {
                onProgressChange = function(Percentage)
                    Creator.OpePercentEyebow = Percentage
                    TriggerEvent('Null:skinchanger:change', 'eyebrows_2', Percentage*10)
                end
            }, 3) 

            RageUI.ColourPanel("Couleur des sourcils", RageUI.PanelColour.HairCut, Creator.ColorEyebow.secondary[1], Creator.ColorEyebow.secondary[2], {
                onColorChange = function(MinimumIndex, CurrentIndex)
                    Creator.ColorEyebow.secondary[1] = MinimumIndex
                    Creator.ColorEyebow.secondary[2] = CurrentIndex
                    TriggerEvent("Null:skinchanger:change", "eyebrows_3", Creator.ColorEyebow.secondary[2])
                end
            }, 3)
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
            if not buy then
                ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('Null:skinchanger:loadSkin', skin) 
                end)
            else
                buy = false
            end
            SetPlayerControl(PlayerId(), true, 12)
        end
    end
end
]]--