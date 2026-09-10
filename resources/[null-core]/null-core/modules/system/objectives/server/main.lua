--[[
    Objectives System — Server
    Manages objective states per player and provides server-side API.
    
    Usage from other server scripts:
        exports['null-core']:StartPlayerObjectives(playerId, id, title, steps, options)
        exports['null-core']:SetPlayerObjectiveStep(playerId, stepIndexOrId)
        exports['null-core']:NextPlayerObjectiveStep(playerId)
        exports['null-core']:CompletePlayerObjectives(playerId, delay)
        exports['null-core']:StopPlayerObjectives(playerId)
]]

local PlayerObjectives = {} -- playerId -> { id, title, steps, currentStep, color }

-- ============================================================
-- SERVER API
-- ============================================================

--- Start objectives for a player
--- @param playerId number Server ID
--- @param id string Unique identifier
--- @param title string Title displayed in header
--- @param steps table Array of { id, title, description }
--- @param options table|nil { color = "#hex", startStep = 0 }
function StartPlayerObjectives(playerId, id, title, steps, options)
    options = options or {}
    
    PlayerObjectives[playerId] = {
        id = id,
        title = title,
        steps = steps,
        currentStep = options.startStep or 0,
        color = options.color,
    }
    
    TriggerClientEvent('null:objectives:start', playerId, id, title, steps, options)
end

--- Set a specific step for a player
--- @param playerId number
--- @param stepIndexOrId number|string Step index (0-based) or step ID
function SetPlayerObjectiveStep(playerId, stepIndexOrId)
    local obj = PlayerObjectives[playerId]
    if not obj then return end
    
    if type(stepIndexOrId) == "number" then
        obj.currentStep = stepIndexOrId
    elseif type(stepIndexOrId) == "string" then
        for i, step in ipairs(obj.steps) do
            if step.id == stepIndexOrId then
                obj.currentStep = i - 1
                break
            end
        end
    end
    
    -- Auto-complete if past last step
    if obj.currentStep >= #obj.steps then
        CompletePlayerObjectives(playerId)
        return
    end
    
    TriggerClientEvent('null:objectives:setStep', playerId, stepIndexOrId)
end

--- Advance to next step
--- @param playerId number
function NextPlayerObjectiveStep(playerId)
    local obj = PlayerObjectives[playerId]
    if not obj then return end
    
    obj.currentStep = obj.currentStep + 1
    
    if obj.currentStep >= #obj.steps then
        CompletePlayerObjectives(playerId)
        return
    end
    
    TriggerClientEvent('null:objectives:nextStep', playerId)
end

--- Complete objectives for a player
--- @param playerId number
--- @param delay number|nil Delay in ms before hiding (default 3000)
function CompletePlayerObjectives(playerId, delay)
    PlayerObjectives[playerId] = nil
    TriggerClientEvent('null:objectives:complete', playerId, delay)
end

--- Stop/hide objectives immediately
--- @param playerId number
function StopPlayerObjectives(playerId)
    PlayerObjectives[playerId] = nil
    TriggerClientEvent('null:objectives:stop', playerId)
end

--- Get objectives data for a player
--- @param playerId number
--- @return table|nil
function GetPlayerObjectives(playerId)
    return PlayerObjectives[playerId]
end

--- Check if a player has active objectives
--- @param playerId number
--- @return boolean
function HasPlayerObjectives(playerId)
    return PlayerObjectives[playerId] ~= nil
end

--- Get current step index for a player
--- @param playerId number
--- @return number|nil
function GetPlayerObjectiveStep(playerId)
    local obj = PlayerObjectives[playerId]
    if not obj then return nil end
    return obj.currentStep
end

-- ============================================================
-- EXPORTS
-- ============================================================

exports('StartPlayerObjectives', StartPlayerObjectives)
exports('SetPlayerObjectiveStep', SetPlayerObjectiveStep)
exports('NextPlayerObjectiveStep', NextPlayerObjectiveStep)
exports('CompletePlayerObjectives', CompletePlayerObjectives)
exports('StopPlayerObjectives', StopPlayerObjectives)
exports('GetPlayerObjectives', GetPlayerObjectives)
exports('HasPlayerObjectives', HasPlayerObjectives)
exports('GetPlayerObjectiveStep', GetPlayerObjectiveStep)

-- ============================================================
-- CLEANUP on player drop
-- ============================================================

AddEventHandler('playerDropped', function()
    local src = source
    PlayerObjectives[src] = nil
end)
