RegisterNetEvent('gouv:handcuff')
  AddEventHandler('gouv:handcuff', function()
  
    IsHandcuffed    = not IsHandcuffed;
    local playerPed = GetPlayerPed(-1)
  
    Citizen.CreateThread(function()
  
      if IsHandcuffed then
  
          RequestAnimDict('mp_arresting')
          while not HasAnimDictLoaded('mp_arresting') do
              Citizen.Wait(100)
          end
  
        TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
        DisableControlAction(2, 37, true)
        SetEnableHandcuffs(playerPed, true)
        SetPedCanPlayGestureAnims(playerPed, false)
        FreezeEntityPosition(playerPed,  true)
        DisableControlAction(0, 24, true) -- Attack
        DisableControlAction(0, 257, true) -- Attack 2
        DisableControlAction(0, 25, true) -- Aim
        DisableControlAction(0, 263, true) -- Melee Attack 1
        DisableControlAction(0, 37, true) -- Select Weapon
        DisableControlAction(0, 47, true)  -- Disable weapon
        
  
      else
  
        ClearPedSecondaryTask(playerPed)
        SetEnableHandcuffs(playerPed, false)
        SetPedCanPlayGestureAnims(playerPed,  true)
        FreezeEntityPosition(playerPed, false)
  
      end
  
    end)
  end)
  
  
  RegisterNetEvent('gouv:putInVehicle')
  AddEventHandler('gouv:putInVehicle', function()
  
    local playerPed = GetPlayerPed(-1)
    local coords    = GetEntityCoords(playerPed)
  
    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
  
      local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  5.0,  0,  71)
  
      if DoesEntityExist(vehicle) then
  
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        local freeSeat = nil
  
        for i=maxSeats - 1, 0, -1 do
          if IsVehicleSeatFree(vehicle,  i) then
            freeSeat = i
            break
          end
        end
  
        if freeSeat ~= nil then
          TaskWarpPedIntoVehicle(playerPed,  vehicle,  freeSeat)
        end
  
      end
  
    end
  
  end)
  
  
  RegisterNetEvent("gouv:OutVehicle")
  AddEventHandler("gouv:OutVehicle", function()
      TaskLeaveAnyVehicle(GetPlayerPed(-1), 0, 0)
  end)
  
  
  local EnTrainEscorter = false
  local PolicierEscorte = nil
  RegisterNetEvent("gouv:drag")
  AddEventHandler("gouv:drag", function(player)
      EnTrainEscorter = not EnTrainEscorter
      PolicierEscorte = tonumber(player)
      if EnTrainEscorter then
          escort()
      end
  end)
  
  function escort()
      Citizen.CreateThread(function()
          local pPed = GetPlayerPed(-1)
          while EnTrainEscorter do
              Wait(1)
              pPed = GetPlayerPed(-1)
              local targetPed = GetPlayerPed(GetPlayerFromServerId(PolicierEscorte))
  
              if not IsPedSittingInAnyVehicle(targetPed) then
                  AttachEntityToEntity(pPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
              else
                  EnTrainEscorter = false
                  DetachEntity(pPed, true, false)
              end
  
              if IsPedDeadOrDying(targetPed, true) then
                  EnTrainEscorter = false
                  DetachEntity(pPed, true, false)
              end
          end
          DetachEntity(pPed, true, false)
      end)
  end