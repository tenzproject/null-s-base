-- SYSTÈME DE SYNCHRONISATION DÉSACTIVÉ - Peds gérés 100% server-side
-- Voir: modules/illegal/laboratories/server/employee_animations.lua

--[[
local createdEmployees = {}

RegisterNetEvent("null:labo:syncEmployee", function(labId, employeeId, netId)
    null.DebugPrint("[EMPLOYEE SYNC] Received sync request - Lab: "..labId..", Employee: "..employeeId..", NetId: "..netId)
    
    if not createdEmployees[labId] then
        createdEmployees[labId] = {}
    end
    
    Citizen.CreateThread(function()
        local attempts = 0
        local maxAttempts = 50
        
        while attempts < maxAttempts do
            local ped = NetworkGetEntityFromNetworkId(netId)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                createdEmployees[labId][employeeId] = ped
                null.DebugPrint("[EMPLOYEE SYNC] SUCCESS - Employee "..employeeId.." synced (ped: "..ped..") after "..attempts.." attempts")
                
                -- Vérifier immédiatement que le ped existe toujours
                Wait(100)
                if DoesEntityExist(createdEmployees[labId][employeeId]) then
                    null.DebugPrint("[EMPLOYEE SYNC] Ped still exists after 100ms")
                else
                    null.DebugPrint("[EMPLOYEE SYNC] WARNING: Ped disappeared after sync!")
                    createdEmployees[labId][employeeId] = nil
                end
                return
            end
            attempts = attempts + 1
            Wait(100)
        end
        
        null.DebugPrint("[EMPLOYEE SYNC] ERROR: Could not sync employee "..employeeId.." (netId: "..netId..") after "..maxAttempts.." attempts")
    end)
end)

RegisterNetEvent("null:labo:removeEmployee", function(labId, employeeId)
    if createdEmployees[labId] and createdEmployees[labId][employeeId] then
        createdEmployees[labId][employeeId] = nil
    end
end)

function GetEmployeePed(labId, employeeId)
    if not createdEmployees or not createdEmployees[labId] then 
        return nil 
    end
    return createdEmployees[labId][employeeId]
end

exports("GetEmployeePed", GetEmployeePed)
--]]
