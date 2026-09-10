local Keys = {
     ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
     ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
     ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
     ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
     ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
     ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
     ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
     ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
     ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local coordsX = {}
local coordsY = {}
local coordsZ = {}
local alerteEnCours = false

local AlertePrise = false
local blips = {}
 
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
     while true do
          interval = 2000
          local hassuppressor = false 
          for k, v in pairs(Config.SuppressorList) do
               if HasPedGotWeaponComponent(PlayerState.ped, PlayerState.weapon, GetHashKey(v.model)) then
                    hassuppressor = true
               end
          end 
          if IsPedArmed(PlayerState.ped, 4) then
               interval = 1
               if IsPedShooting(PlayerState.ped) and PlayerState.weapon ~= GetHashKey("WEAPON_PETROLCAN") and PlayerState.weapon ~= GetHashKey("WEAPON_PLASMAP") and PlayerState.weapon ~= GetHashKey("WEAPON_FIREEXTINGUISHER") and PlayerState.weapon ~= GetHashKey("WEAPON_APPISTOL") then
                    if hassuppressor then
                         shoot = math.random(1, Config.Police.Pourcent.withsupp.randommax)
                         if shoot == Config.Police.Pourcent.withsupp.thenbr then
                              local plyPos = GetEntityCoords(PlayerState.ped, true)
                              TriggerServerEvent('null:police:alert:firelisten', plyPos.x, plyPos.y, plyPos.z)
                              alerteEnCours = true
                         end
                    else
                         shoot = math.random(1, Config.Police.Pourcent.withoutsupp.randommax)
                         if shoot == Config.Police.Pourcent.withoutsupp.thenbr then
                              local plyPos = GetEntityCoords(PlayerState.ped, true)
                              TriggerServerEvent('null:police:alert:firelisten', plyPos.x, plyPos.y, plyPos.z)
                              alerteEnCours = true
                         end
                    end
               end
          end
          Wait(interval)
     end
end))

RegisterNetEvent('null:police:listen:fire:blips')
AddEventHandler('null:police:listen:fire:blips', function(gx, gy, gz)
     if null.data.jobs.polices.list[ESX.PlayerData.job.name] == nil then
          if AlertePrise then
               local blipId = AddBlipForCoord(gx, gy, gz)
               SetBlipSprite(blipId, 4)
               SetBlipScale(blipId, 2.0)
               SetBlipColour(blipId, 1)
               SetBlipRoute(blipId,  true)
               BeginTextCommandSetBlipName("STRING")
               AddTextComponentString('Coup de feu')
               EndTextCommandSetBlipName(blipId)
               SetBlipAsShortRange(blipId, true)
               table.insert(blips, blipId)
               Wait(60 * 1000)
               for i, blipId in pairs(blips) do 
                    RemoveBlip(blipId)
               end
          end
     end
end)
 
RegisterNetEvent('vPriseAppel')
AddEventHandler('vPriseAppel', function(name)
     if ESX.PlayerData.job ~= nil and (null.data.jobs.polices.list[ESX.PlayerData.job.name] == nil) then
          ESX.ShowAdvancedNotification('DISPATCH INFORMATION', 'CENTRAL', 'L\'agent ~g~'..name..'~s~ a prit l\'appel d\'un civil concernant des coups de feu.', 'CHAR_CALL911')
     end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        interval = 750
        if ESX.PlayerData.job ~= nil and null.data.jobs.polices.list[ESX.PlayerData.job.name] == nil and alerteEnCours then
            interval = 1
            if IsControlJustPressed(1, 246) and alerteEnCours then --Y
                TriggerServerEvent('null:police:alert:take')
                AlertePrise = true
                TriggerEvent('null:police:listen:fire:blips', coordsX, coordsY, coordsZ)
                alerteEnCours = false
            elseif IsControlJustPressed(1, 73) and alerteEnCours and (null.data.jobs.polices.list[ESX.PlayerData.job.name] == nil) then
                AlertePrise = false
                alerteEnCours = false
            end
         end
         Citizen.Wait(interval)
    end
end))