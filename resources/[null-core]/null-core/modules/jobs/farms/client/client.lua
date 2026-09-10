Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('Null:initFarmSociety')
end)

local FarmBlips = {}
local currentFarm = nil  

RegisterNetEvent('Null:SendEntrepriseFarmList', function(Table)
    for _, v in pairs(Table or {}) do
        null.data.markers.unregister("job_farm_vestiaire_"..v.name)
        null.data.markers.unregister("job_farm_boss_"..v.name)
    end
    null.data.jobs.farms.list = Table
    null.data.jobs.farms.loaded = true
    for _, v in pairs(Table or {}) do
        if v.type == "Farm" then
            null.data.markers.register("job_farm_vestiaire_"..v.name, {
                Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenVestiaire(ESX.PlayerData.job.name)
                end
            })
            null.data.markers.register("job_farm_boss_"..v.name, {
                Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z))
                end
            })
        end
    end
    if ESX and ESX.PlayerData and ESX.PlayerData.job then
        TriggerEvent('esx:setJob', ESX.PlayerData.job)
    end
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    -- Reset cache et blips
    currentFarm = nil
    for k,v in pairs(FarmBlips) do RemoveBlip(v) end
    FarmBlips = {}
    Wait(100)
    for k,v in pairs(null.data.jobs.farms.list) do
        -- Cache la farm du joueur
        if job.name == v.name then
            currentFarm = v
        end
        null.DebugPrint(job, v)
        null.DebugPrint(job.name, v.name)
        null.DebugPrint(currentFarm)
        if job.name == v.name and v.type == "Farm" then
            FarmBlips["recolte"] = AddBlipForCoord(v.PosRecolte.x, v.PosRecolte.y, v.PosRecolte.z)
            SetBlipSprite(FarmBlips["recolte"], 501)
            SetBlipDisplay(FarmBlips["recolte"], 4)
            SetBlipScale(FarmBlips["recolte"], 0.6)
            SetBlipColour(FarmBlips["recolte"], 43)
            SetBlipAsShortRange(FarmBlips["recolte"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Récolte "..v.label)
            EndTextCommandSetBlipName(FarmBlips["recolte"])

            FarmBlips["traitement"] = AddBlipForCoord(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z)
            SetBlipSprite(FarmBlips["traitement"], 501)
            SetBlipDisplay(FarmBlips["traitement"], 4)
            SetBlipScale(FarmBlips["traitement"], 0.6)
            SetBlipColour(FarmBlips["traitement"], 43)
            SetBlipAsShortRange(FarmBlips["traitement"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Traitement ".. v.label)
            EndTextCommandSetBlipName(FarmBlips["traitement"])
            
            FarmBlips["vente"] = AddBlipForCoord(v.PosVente.x, v.PosVente.y, v.PosVente.z)
            SetBlipSprite(FarmBlips["vente"], 501)
            SetBlipDisplay(FarmBlips["vente"], 4)
            SetBlipScale(FarmBlips["vente"], 0.6)
            SetBlipColour(FarmBlips["vente"], 43)
            SetBlipAsShortRange(FarmBlips["vente"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Vente ".. v.label)
            EndTextCommandSetBlipName(FarmBlips["vente"])
        elseif job.name == v.name and v.type == "Restaurant" then
            FarmBlips["stockage"] = AddBlipForCoord(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z)
            SetBlipSprite(FarmBlips["stockage"], 501)
            SetBlipDisplay(FarmBlips["stockage"], 4)
            SetBlipScale(FarmBlips["stockage"], 0.6)
            SetBlipColour(FarmBlips["stockage"], 43)
            SetBlipAsShortRange(FarmBlips["stockage"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Stockage "..v.label)
            EndTextCommandSetBlipName(FarmBlips["stockage"])
        end
        -- Break si on a trouvé la farm du joueur (pas besoin de continuer)
        if currentFarm then break end
    end
end)


AddTextEntry('BLIP_PROPCAT', 'Entreprise ')
Citizen.CreateThread(function()
    while not null.data.jobs.farms.loaded do 
        Wait(1)
    end
    null.fct.waitPlayerLoaded()
    for k,v in pairs(null.data.jobs.farms.list) do
        if v.type == 'Farm' then
            ESX.addBlips({
                name = 'entreprise_farm_'..v.name,
                label = v.label,
                category = 10,
                position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                sprite = 176,
                display = 4,
                scale = 0.6,
                color = 3,
                type = "farm_society",
            })

            null.data.markers.register("job_farm_vestiaire_"..v.name, {
                Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenVestiaire(ESX.PlayerData.job.name)
                end
            })
            null.data.markers.register("job_farm_boss_"..v.name, {
                Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z))
                end
            })
        end

        if ESX.PlayerData.job.name == v.name and v.type == "Farm" then 
            FarmBlips["recolte"] = AddBlipForCoord(v.PosRecolte.x, v.PosRecolte.y, v.PosRecolte.z)
            SetBlipSprite(FarmBlips["recolte"], 501)
            SetBlipDisplay(FarmBlips["recolte"], 4)
            SetBlipScale(FarmBlips["recolte"], 0.6)
            SetBlipColour(FarmBlips["recolte"], 43)
            SetBlipAsShortRange(FarmBlips["recolte"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Récolte "..v.label)
            EndTextCommandSetBlipName(FarmBlips["recolte"])

            FarmBlips["traitement"] = AddBlipForCoord(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z)
            SetBlipSprite(FarmBlips["traitement"], 501)
            SetBlipDisplay(FarmBlips["traitement"], 4)
            SetBlipScale(FarmBlips["traitement"], 0.6)
            SetBlipColour(FarmBlips["traitement"], 43)
            SetBlipAsShortRange(FarmBlips["traitement"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Traitement ".. v.label)
            EndTextCommandSetBlipName(FarmBlips["traitement"])

            FarmBlips["vente"] = AddBlipForCoord(v.PosVente.x, v.PosVente.y, v.PosVente.z)
            SetBlipSprite(FarmBlips["vente"], 501)
            SetBlipDisplay(FarmBlips["vente"], 4)
            SetBlipScale(FarmBlips["vente"], 0.6)
            SetBlipColour(FarmBlips["vente"], 43)
            SetBlipAsShortRange(FarmBlips["vente"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Vente ".. v.label)
            EndTextCommandSetBlipName(FarmBlips["vente"])
        elseif v.type == "Restaurant" and ESX.PlayerData.job.name == v.name then
            FarmBlips["stockage"] = AddBlipForCoord(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z)
            SetBlipSprite(FarmBlips["stockage"], 501)
            SetBlipDisplay(FarmBlips["stockage"], 4)
            SetBlipScale(FarmBlips["stockage"], 0.6)
            SetBlipColour(FarmBlips["stockage"], 43)
            SetBlipAsShortRange(FarmBlips["stockage"], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Stockage "..v.label)
            EndTextCommandSetBlipName(FarmBlips["stockage"])
        end
    end
end)

local farming = false
local WaitFarming = false

CreateThread(function()
    null.fct.waitPlayerLoaded()
    while not null.data.jobs.farms.loaded do Wait(100) end
    for _, v in pairs(null.data.jobs.farms.list) do
        if ESX.PlayerData.job.name == v.name then
            currentFarm = v
            null.DebugPrint("Set currentFarm", v.name, v.type)
            break
        end
    end
    if not currentFarm then
        null.DebugPrint("No currentFarm found")
    end
end)

local function StopFarming()
    if not farming then return end
    farming = false
    TriggerServerEvent('framework:stopActivity')
    Wait(5000)
    WaitFarming = false
end

local function StartActivity(pos, item, activityType, traitementItem, jobName, farmType)
    if PlayerState.isInVehicle then
        ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
        return
    end
    farming = true
    WaitFarming = true
    TriggerServerEvent('framework:startActivity', pos, item, activityType, traitementItem, jobName, farmType)
end

local function HandleFarmingInput(helpText, onStart)
    if not farming then
        if not WaitFarming then
            ESX.ShowHelpNotification(helpText)
            if IsControlJustPressed(1, 51) then
                onStart()
            end
        else
            ESX.ShowHelpNotification('Merci de ne pas allez trop vite')
        end
    else
        ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour arrêter l\'activité')
        if IsControlJustPressed(1, 51) then
            StopFarming()
        end
    end
end

CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    while not null.data.jobs.farms.loaded do Wait(500) end
    while not null.data.jobs.restaurants.loaded do Wait(500) end
    
    while true do
        local sleepTime = 2000
        if currentFarm then
            local v = currentFarm
            local coords = PlayerState.coords
            if v.type == "Restaurant" then
                local distTraitement = #(coords - vector3(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z))
                
                if distTraitement < 10.0 then
                    sleepTime = 0
                    HandleFarmingInput('Appuyez sur ~g~E ~s~pour commencer', function()
                        local optionlist = {}
                        for _, item in pairs(v.RecolteItem) do
                            table.insert(optionlist, {value = item.name, label = item.label .. " (" .. item.name .. ")"})
                        end
                        local result2 = null.fct.input("Votre choix", true, {
                            {type = 'select', label = 'Qu\'elle item veut tu récuperer ?', options = optionlist, searchable = true}
                        })
                        if result2 then
                            StartActivity(v.PosTraitement, result2, 1, '0', ESX.PlayerData.job.name, v.type)
                        end
                    end)
                elseif distTraitement > 15.0 and farming then
                    StopFarming()
                end
            elseif v.type == "Farm" then
                local distRecolte = #(coords - vector3(v.PosRecolte.x, v.PosRecolte.y, v.PosRecolte.z))
                local distTraitement = #(coords - vector3(v.PosTraitement.x, v.PosTraitement.y, v.PosTraitement.z))
                local distVente = #(coords - vector3(v.PosVente.x, v.PosVente.y, v.PosVente.z))
                
                if distRecolte < 100 or distTraitement < 100 or distVente < 100 then
                    sleepTime = 0
                end

                if distRecolte < 10 then
                    HandleFarmingInput('Appuyez sur ~g~E ~s~pour commencer la récolte', function()
                        StartActivity(v.PosRecolte, v.RecolteItem, 1, '0', ESX.PlayerData.job.name)
                    end)
                elseif distTraitement < 10 then
                    HandleFarmingInput('Appuyez sur ~g~E ~s~pour commencer le traitement', function()
                        StartActivity(v.PosTraitement, v.RecolteItem, 2, v.TraitementItem, ESX.PlayerData.job.name)
                    end)
                elseif distVente < 10 then
                    HandleFarmingInput('Appuyez sur ~g~E ~s~pour commencer la vente', function()
                        StartActivity(v.PosVente, '0', 3, v.TraitementItem, ESX.PlayerData.job.name)
                    end)
                elseif farming then
                    StopFarming()
                end                
            end
        end
        
        Wait(sleepTime)
    end
end))

RegisterNetEvent('framework:farmanimation', function(time)
	local dict, anim = 'random@domestic', 'pickup_low'
	local playerPed = PlayerPedId()
    ESX.Streaming.RequestAnimDict(dict)
    if time == nil then time = Config.Farming.VitesseAnimation end
	TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, time, 16, 0.0, false, false, false)
end)
