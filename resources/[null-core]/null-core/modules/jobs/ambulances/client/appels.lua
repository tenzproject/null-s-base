Citizen.CreateThread(function()
    Wait(2500)
    while InCharSelector == nil do
        Wait(100)
    end
    while InCharSelector == true do
        Wait(100)
    end
    TriggerServerEvent('Null:RetreiveIsDead')
end)

RegisterNetEvent('Null:PlayerIsDead', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

ReportListTable = {}

--[[ReportListTable[1] = {
    position = vec3(-449.922577, -999.270081, 24.288784),
    status = 0,
    numbers = 1,
    heures = 18,
    minutes = 09,
    secondes = 30,
    src = 1,
    raison = 'Une personne est inconsciente'
}]]
    
RegisterNetEvent('Null:UpdateTableSignalEms', function(table)
    null.DebugPrint("recevie Signal EMS")
    ReportListTable = table
end)


AppelsSelected = 0
SrcSelected = 0
AppelEnCours = false
blip = nil

function OpenReportListEms()
    local menu = RageUI.CreateMenu('Emergency System', "Voici les appeles disponibles")
    local OpenSelectedAppel = RageUI.CreateSubMenu(menu, "Emergency System", 'Actions disponible')
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        if NullInventory.isOpen then 
            return
        end
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Separator('~s~↓ ~r~Appels en attente ~s~↓')
            for k,v in pairs(ReportListTable) do
                if v.status == 0 then
                    RageUI.Button('Appel N*'..v.numbers, 'Description : '..v.raison, {RightLabel = 'Fait à '..v.heures..'h'..v.minutes.. 'm'..v.secondes..'s'}, true, {
                        onSelected = function() 
                            SrcSelected = v.src
                            AppelsSelected = v.numbers
                        end
                    }, OpenSelectedAppel)
                end
            end
            RageUI.Separator('~s~↓ ~g~Appels en cours ~s~↓')
            for k,v in pairs(ReportListTable) do
                if v.status == 1 then
                    RageUI.Button('Appel N*'..v.numbers, 'Description : '..v.raison..'\nAppel pris par ~g~'..v.EMSName, {RightLabel = 'Fait à '..v.heures..'h'..v.minutes.. 'm'..v.secondes..'s'}, true, {
                        onSelected = function() 
                            SrcSelected = v.src
                            AppelsSelected = v.numbers
                        end
                    }, OpenSelectedAppel)
                end
            end
        end, function()
        end)
        RageUI.IsVisible(OpenSelectedAppel, function()
            RageUI.Separator('')
            RageUI.Separator('Appel N*~g~'..AppelsSelected)

            if ReportListTable[SrcSelected].status == 1 then
                StatusText = 'Pris par ~g~'..ReportListTable[SrcSelected].EMSName
            else 
                StatusText = '~r~En Attente'
            end

            RageUI.Separator('Status : '..StatusText)
            RageUI.Separator('')

            if ReportListTable[SrcSelected].status == 0 then
                RageUI.Button('Prendre l\'appel','Permet de prendre l\'appel, Vos collegues seront informer', {}, true, {
                    onSelected = function()
                        if not AppelEnCours then
                            AppelEnCours = true
                            blip = AddBlipForCoord(ReportListTable[SrcSelected].position)
                            SetBlipColour(blip, 60)
                            SetBlipRoute(blip, true)
                            ESX.ShowNotification('Tu as pris l\'appel N*'..AppelsSelected)
                            TriggerServerEvent('EMS:UpdateReport', SrcSelected, true) --> TRUE = PRENDRE
                        else
                            ESX.ShowNotification('Vous avez déjà un appel en cours\nCloture le pour en reprendre un.')
                        end
                    end
                })
            else
                if GetPlayerServerId(PlayerId()) == ReportListTable[SrcSelected].EMS_SRC then
                    RageUI.Button('Informer le patient de votre arriver',nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent('EMS:InformPatient', SrcSelected)
                        end
                    })
                    
                    RageUI.Button('Terminer l\'appel',nil, {}, true, {
                        onSelected = function()
                            AppelEnCours = false
                            RemoveBlip(blip)
                            ESX.ShowNotification('Vous avez terminer l\'intervention N*'..AppelsSelected)
                            TriggerServerEvent('EMS:UpdateReport', SrcSelected, false)
                        end
                    })
                end
            end
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(OpenSelectedAppel) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

RegisterNetEvent('EMS:ForceStopAppel', function()
    AppelEnCours = false
    RemoveBlip(blip)
end)