
local CFG = Config.Taxi

local menuGarageOpen = false
local menuGarage = RageUI.CreateMenu("Garage Taxi", "Choisissez votre véhicule")
menuGarage.Display.Header = true
menuGarage.Closed = function() menuGarageOpen = false end

local menuRangerOpen = false
local menuRanger = RageUI.CreateMenu("Ranger Taxi", "Restitution du véhicule")
menuRanger.Display.Header = true
menuRanger.Closed = function() menuRangerOpen = false end

-- ============================================================
-- Helpers
-- ============================================================
local function rankIndex(key)
    for i, r in ipairs(CFG.Ranks) do if r.key == key then return i end end
    return 1
end

local function currentRankIdx()
    if TaxiClient and TaxiClient.State and TaxiClient.State.profile and TaxiClient.State.profile.rank then
        return rankIndex(TaxiClient.State.profile.rank.key)
    end
    return 1
end

local function spawnTaxiVehicle(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) then
        ESX.ShowNotification("~r~Modèle inconnu : "..modelName)
        return
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        ESX.ShowNotification("~r~Impossible de charger le modèle")
        return
    end
    local s = CFG.Positions.Spawn
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, true)
    SetVehicleNumberPlateText(veh, "TAXI"..math.random(100, 999))
    SetVehicleEngineOn(veh, true, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    ESX.ShowNotification("~g~Véhicule prêt — bonne course !")
end

-- ============================================================
-- Menu garage (sortir un véhicule)
-- ============================================================
function OpenGarageTaxi()
    if menuGarageOpen then
        menuGarageOpen = false
        RageUI.Visible(menuGarage, false)
        return
    end

    -- Refresh profile pour avoir le rang à jour
    if TaxiClient and TaxiClient.RefreshProfile then TaxiClient.RefreshProfile() end

    menuGarageOpen = true
    RageUI.Visible(menuGarage, true)

    Citizen.CreateThread(function()
        while menuGarageOpen do
            RageUI.IsVisible(menuGarage, function()
                local myRank = currentRankIdx()
                RageUI.Separator(("Rang actuel : ~b~%s"):format(
                    TaxiClient.State.profile and TaxiClient.State.profile.rank
                    and TaxiClient.State.profile.rank.label or "Apprenti"
                ))

                for _, v in ipairs(CFG.Vehicles) do
                    local req = rankIndex(v.rankReq or "novice")
                    local unlocked = myRank >= req
                    local right = unlocked and "Disponible" or ("Rang requis : "..(CFG.Ranks[req].label or ""))
                    RageUI.Button(v.label, nil, { RightLabel = right }, unlocked, {
                        onSelected = function()
                            if not unlocked then return end
                            RageUI.CloseAll()
                            spawnTaxiVehicle(v.model)
                        end,
                    })
                end
            end)
            Wait(0)
        end
    end)
end

-- ============================================================
-- Menu ranger
-- ============================================================
function OpenRangerTaxi()
    if menuRangerOpen then
        menuRangerOpen = false
        RageUI.Visible(menuRanger, false)
        return
    end

    menuRangerOpen = true
    RageUI.Visible(menuRanger, true)

    Citizen.CreateThread(function()
        while menuRangerOpen do
            RageUI.IsVisible(menuRanger, function()
                RageUI.Button("Ranger mon véhicule", "Le véhicule actuel sera supprimé.", { RightLabel = "" }, true, {
                    onSelected = function()
                        local ped = PlayerPedId()
                        if IsPedSittingInAnyVehicle(ped) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if GetPedInVehicleSeat(veh, -1) == ped then
                                ESX.ShowNotification("~g~Véhicule rangé au garage")
                                ESX.Game.DeleteVehicle(veh)
                            else
                                ESX.ShowNotification("~r~Vous devez être au volant")
                            end
                        else
                            local veh = ESX.Game.GetVehicleInDirection()
                            if DoesEntityExist(veh) then
                                ESX.ShowNotification("~g~Véhicule rangé au garage")
                                ESX.Game.DeleteVehicle(veh)
                            else
                                ESX.ShowNotification("~r~Aucun véhicule à proximité")
                            end
                        end
                        RageUI.CloseAll()
                    end,
                })
            end)
            Wait(0)
        end
    end)
end

-- ============================================================
-- Markers
-- ============================================================
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    null.data.markers.register("taxi_garage", {
        Position = CFG.Positions.Garage,
        Public   = false,
        Job      = "taxi",
        Action   = function() OpenGarageTaxi() end,
    })
    null.data.markers.register("taxi_ranger", {
        Position = CFG.Positions.Ranger,
        Public   = false,
        Job      = "taxi",
        Action   = function() OpenRangerTaxi() end,
    })
end)
