NullGF = {
    zoneGf = {},
    myZoneGF = {},
    isLoad = false,
    InZone = false,
    CountPlayers = 0,
    myStats = {kills = 0,deaths = 0},
    allStats = {},
}

Citizen.CreateThread(function()
    TriggerServerEvent("null:zonegf:getallzone")
end)

RegisterNetEvent('null:zonegf:initzonegf')
AddEventHandler('null:zonegf:initzonegf', function(result)
    NullGF.zoneGf = result
    NullGF.isLoad = true
end)

RegisterNetEvent('null:zonegf:editOpen')
AddEventHandler('null:zonegf:editOpen', function(id, bool)
    NullGF.zoneGf[id].isOpen = bool
end)
 
RegisterNetEvent('null:zonegf:leave')
AddEventHandler('null:zonegf:leave', function()
    quitteZoneGF()
    HideInfo() 
end)

RegisterNetEvent('null:zonegf:refreshStats')
AddEventHandler('null:zonegf:refreshStats', function(type, value)
    if type == "death" then
        NullGF.myStats.deaths = NullGF.myStats.deaths + 1
    elseif type == "kill" then
        NullGF.myStats.kills = NullGF.myStats.kills + 1
    end
end)

RegisterCommand('gunfight', function()
    if NullGF.myZoneGF ~= nil then
        if NullGF.zoneGf[NullGF.myZoneGF] ~= nil then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed, false)
        
            local configPosGF = NullGF.zoneGf[NullGF.myZoneGF].position
            if #(configPosGF.xy - coords.xy) < 500 then
                quitteZoneGF()
                HideInfo()
            else
                ESX.ShowNotification("Vous n\'êtes pas en zone GunFight")
            end
        end
    end
end)

function enterZoneGF()
    showMenu()
end

function getInZoneGF()
    return NullGF.InZone
end

exports("getInZoneGF", function()
    return NullGF.InZone
end)

function quitteZoneGF()
    ESX.TriggerServerCallback('null:zonegf:join', function(result) 
        NullGF.zoneGf[NullGF.myZoneGF].nbrPlayers = result
        NullGF.CountPlayers = result
    end, NullGF.myZoneGF, 'Leave')
    NullGF.InZone = false
    HideInfo()
    RageUI.CloseAll()
end


function showMenu()
    local mainMenu = RageUI.CreateMenu('GunFight', 'Que souhaitez-vous faire ?')
    local subMenu = RageUI.CreateSubMenu(mainMenu, 'Gunfight', 'Que souhaitez-vous faire ?')
    local subMenu2 = RageUI.CreateSubMenu(mainMenu, 'Gunfight', 'Que souhaitez-vous faire ?')
    local subMenu3 = RageUI.CreateSubMenu(mainMenu, 'Gunfight', 'Que souhaitez-vous faire ?')

    ESX.TriggerServerCallback('null:gunfight:getAll', function(result) 
        NullGF.myStats = result
    end, 'myStats')
    ESX.TriggerServerCallback('null:gunfight:getAll', function(result) 
        NullGF.allStats = result
    end, 'allStats')

    if not NullGF.InZone then
        FreezeEntityPosition(PlayerPedId(), true)
    end

    RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
    while mainMenu do
        Citizen.Wait(0)
        RageUI.IsVisible(mainMenu, function()
            while not NullGF.isLoad do return RageUI.Separator("Chargement en cours..") end
            if not NullGF.InZone then

                for k,v in pairs(NullGF.zoneGf) do
                    RageUI.Button(v.label, nil, {RightLabel=v.nbrPlayers.."/"..v.maxPlayers}, v.isOpen, {
                        onSelected = function()
                            RageUI.CloseAll()
                            NullGF.myZoneGF = v.id
                            ESX.TriggerServerCallback('null:zonegf:join', function(result) 
                                NullGF.zoneGf[NullGF.myZoneGF].nbrPlayers = result
                            end, v.id, 'Join')
                            Citizen.Wait(500)
                            NullGF.InZone = true
                            PlayerInit()
                        end
                    })
                end

                RageUI.Button('Classement', nil, { RightLabel = nil }, true, {
                    onSelected = function()
                    end
                }, subMenu3)
            else
                RageUI.Button('Quitter la partie', nil, { RightLabel = ('%s~s~ Personne(s)'):format(NullGF.zoneGf[NullGF.myZoneGF].nbrPlayers) }, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback('null:zonegf:join', function(result) 
                            NullGF.zoneGf[NullGF.myZoneGF].nbrPlayers = result
                            NullGF.CountPlayers = result
                        end, NullGF.myZoneGF, 'Leave')
                        NullGF.InZone = false
                        HideInfo()
                        RageUI.CloseAll()
                    end
                })
            end
        end)
        RageUI.IsVisible(subMenu, function()
            RageUI.Button('FFA', nil, { LeftBadge = RageUI.BadgeStyle.Star, RightLabel = ('%s~s~ Personne(s)'):format(NullGF.CountPlayers) }, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    ESX.TriggerServerCallback('GF:GameMode:Party', function(result) 
                        NullGF.CountPlayers = result
                    end, 'FFA', 'Join')
                    Citizen.Wait(500)
                    NullGF.InZone = true
                    PlayerInit()
                end
            })
        end)

        RageUI.IsVisible(subMenu2, function()
            if not NullGF.myStats or NullGF.myStats == {} then
                RageUI.Separator('Vous n\'avez pas encore de stats.')
            else
                RageUI.Button('Stats Personnelles', nil, {}, true, {
                    onActive = function()
                        RageUI.Info("~y~Vos Stats~s~", {'Joueur(s) Tué(s)', 'Nombre de Mort(s)', 'Votre Ratio'}, {NullGF.myStats.kills, NullGF.myStats.deaths, ESX.Math.Round(null.fct.math.CalculateKD(NullGF.myStats), 1)})
                    end
                })
            end
        end)

        RageUI.IsVisible(subMenu3, function()
            for k,v in ipairs(NullGF.allStats) do
                local TopLabel = nil
                --local description = "Kill(s): "..v.kills.." Mort(s): "..v.deaths.." KD: "..ESX.Math.Round(null.fct.math.CalculateKD(v), 1)
                if k == 1 then
                    TopLabel = "~h~Top 1~s~"
                elseif k == 2 then
                    TopLabel = "Top 2"
                elseif k == 3 then
                    TopLabel = "Top 3"
                end
                RageUI.Button(v.name, Config.GunFightZone.label, {RightLabel=TopLabel}, true, {
                    onActive = function()
                        RageUI.Info(TopLabel == nil and v.name or TopLabel.." : "..v.name.."", {'Kill(s)', 'Mort(s)', 'KD'}, {v.kills, v.deaths, ESX.Math.Round(null.fct.math.CalculateKD({kills=v.kills,deaths=v.deaths}), 1)})
                    end
                })
            end
        end)

        if not RageUI.Visible(mainMenu) and not RageUI.Visible(subMenu) and not RageUI.Visible(subMenu2) and not RageUI.Visible(subMenu3) then
            mainMenu = RMenu:DeleteType("mainMenu", true)
            subMenu = RMenu:DeleteType("subMenu", true)
            subMenu2 = RMenu:DeleteType("subMenu2", true)
            subMenu3 = RMenu:DeleteType("subMenu3", true)
            if not NullGF.InZone then
                FreezeEntityPosition(PlayerPedId(), false)
            end
            break
        end
    end
end

function DrawMissionText(msg, time)
	ClearPrints()
	BeginTextCommandPrint('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandPrint(time, true)
end

function PlayerInit()
    local CD = false

    while not NullGF.InZone do
        Citizen.Wait(500)
    end
    Citizen.CreateThread(function()
        while NullGF.InZone do
            Citizen.Wait(0)
            if not NullGF.InZone then break end
            DrawMissionText("Utilisez la commande /gunfight pour quitter la zone.", 0)
        end
    end)
    while NullGF.InZone do
        Citizen.Wait(0)
        if not NullGF.InZone then break end
        if NullGF.myStats == nil then
            NullGF.myStats = {}
            NullGF.myStats.kills = 0
            NullGF.myStats.deaths = 0
        end
        ShowInfo(
            "Zone GunFight",  
            {
                {left = "Kill(s)", right = (NullGF.myStats.kills), color = "rgb(255, 255, 255)"},
                {left = "Mort(s)", right = (NullGF.myStats.deaths), color = "rgb(255, 255, 255)"},
                {left = "KD", right = (ESX.Math.Round(null.fct.math.CalculateKD(NullGF.myStats), 1)), color = "rgb(255, 255, 255)"},
            }
        )
        Citizen.Wait(500)
    end
    HideInfo()
end

RegisterNetEvent('null:gunfight:newStat')
AddEventHandler('null:gunfight:newStat', function(...)
    local Args = {...}
    if Args[1] and NullGF.InZone then
        if NullGF.myStats == nil then NullGF.myStats = {kills=0, deaths=0} end
        if Args[1] == 'd' then
            local canAction = ActionCooldown("zonegf-d", 1000)
            if not canAction then return end
            NullGF.myStats.deaths = NullGF.myStats.deaths + 1
        elseif Args[1] == 'k' then
            local canAction = ActionCooldown("zonegf-k", 1000)
            if not canAction then return end
            NullGF.myStats.Kills = NullGF.myStats.Kills + 1
        elseif Args[1] == 'p' then
            NullGF.CountPlayers = Args[2]
        end
    end
end)