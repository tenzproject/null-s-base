--[[
    Objectives System — Client
    Displays step-by-step objectives on screen to guide players through complex systems.
    
    NUI Actions:
        objectives:start   — Show objectives with steps
        objectives:update  — Update current step
        objectives:complete — Mark as completed (auto-hides after delay)
        objectives:stop    — Immediately hide
]]

local currentObjectives = nil
local registeredSkipCommand = nil
local registeredSkipCommands = {}

-- ============================================================
-- NUI BRIDGE
-- ============================================================

local function SendObjectivesNUI(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

-- ============================================================
-- CLIENT API
-- ============================================================

--- Start a new objectives tracker
--- @param id string Unique identifier for this objectives set
--- @param title string Title displayed in the header
--- @param steps table Array of { id = "step1", title = "...", description = "..." }
--- @param options table|nil Optional: { color = "#hex", startStep = 0, skipCommand = "commandname" }
function StartObjectives(id, title, steps, options)
    options = options or {}
    
    registeredSkipCommand = nil
    
    currentObjectives = {
        id = id,
        title = title,
        steps = steps,
        currentStep = options.startStep or 0,
        color = options.color or nil,
        skipCommand = options.skipCommand or nil,
    }
    
    -- Register skip command if provided
    if options.skipCommand then
        registeredSkipCommand = options.skipCommand
        if not registeredSkipCommands[options.skipCommand] then
            registeredSkipCommands[options.skipCommand] = true
            RegisterCommand(options.skipCommand, function()
                if currentObjectives and currentObjectives.skipCommand == registeredSkipCommand then
                    CompleteObjectives(1000)
                    TriggerEvent('chat:addMessage', {
                        color = { 34, 197, 94 },
                        multiline = true,
                        args = { "Objectifs", "Tutoriel passé avec succès !" }
                    })
                end
            end, false)
        end
    end
    
    SendObjectivesNUI("objectives:start", {
        id = id,
        title = title,
        steps = steps,
        currentStep = currentObjectives.currentStep,
        color = options.color,
        skipCommand = options.skipCommand,
    })
end

--- Advance to a specific step (or next step if no index provided)
--- @param stepIndexOrId number|string|nil Step index (0-based) or step ID, or nil for next
function SetObjectiveStep(stepIndexOrId)
    if not currentObjectives then return end
    
    local newStep = nil
    
    if stepIndexOrId == nil then
        -- Next step
        newStep = currentObjectives.currentStep + 1
    elseif type(stepIndexOrId) == "number" then
        newStep = stepIndexOrId
    elseif type(stepIndexOrId) == "string" then
        -- Find by step ID
        for i, step in ipairs(currentObjectives.steps) do
            if step.id == stepIndexOrId then
                newStep = i - 1 -- Convert to 0-based
                break
            end
        end
    end
    
    if newStep == nil then return end
    
    -- Auto-complete if we go past the last step
    if newStep >= #currentObjectives.steps then
        CompleteObjectives()
        return
    end
    
    currentObjectives.currentStep = newStep
    
    SendObjectivesNUI("objectives:update", {
        currentStep = newStep,
    })
    null.DebugPrint("SetObjectiveStep",newStep)
end

--- Complete the current objectives (shows completion animation then auto-hides)
--- @param delay number|nil Delay in ms before hiding (default 3000)
function CompleteObjectives(delay)
    if not currentObjectives then return end
    
    registeredSkipCommand = nil
    
    SendObjectivesNUI("objectives:complete", {
        delay = delay or 3000,
    })

    null.DebugPrint("CompleteObjectives")
    
    currentObjectives = nil
end

--- Immediately stop/hide objectives without completion animation
function StopObjectives()
    if not currentObjectives then return end
    
    registeredSkipCommand = nil
    
    SendObjectivesNUI("objectives:stop", {})
    currentObjectives = nil
end

--- Get the current objectives data
--- @return table|nil
function GetCurrentObjectives()
    return currentObjectives
end

--- Check if objectives are active
--- @return boolean
function HasActiveObjectives()
    return currentObjectives ~= nil
end

--- Get current step index (0-based)
--- @return number|nil
function GetCurrentStep()
    if not currentObjectives then return nil end
    return currentObjectives.currentStep
end

--- Get current step id
--- @return string|nil
function GetCurrentStepId()
    if not currentObjectives then return nil end
    local currentId = nil
    for i, step in ipairs(currentObjectives.steps) do
        if (i - 1) == currentObjectives.currentStep then
            currentId = step.id
        end
    end
    return currentId
end

-- ============================================================
-- EXPORTS
-- ============================================================

exports('StartObjectives', StartObjectives)
exports('SetObjectiveStep', SetObjectiveStep)
exports('CompleteObjectives', CompleteObjectives)
exports('StopObjectives', StopObjectives)
exports('GetCurrentObjectives', GetCurrentObjectives)
exports('HasActiveObjectives', HasActiveObjectives)
exports('GetCurrentStep', GetCurrentStep)
exports('GetCurrentStepId', GetCurrentStepId)

-- ============================================================
-- EVENTS (for server → client communication)
-- ============================================================

RegisterNetEvent('null:objectives:start')
AddEventHandler('null:objectives:start', function(id, title, steps, options)
    StartObjectives(id, title, steps, options)
end)

RegisterNetEvent('null:objectives:setStep')
AddEventHandler('null:objectives:setStep', function(id, stepIndexOrId)
    if id and currentObjectives and currentObjectives.id == id then
        SetObjectiveStep(stepIndexOrId)
    end
end)

RegisterNetEvent('null:objectives:nextStep')
AddEventHandler('null:objectives:nextStep', function()
    SetObjectiveStep(nil)
end)

RegisterNetEvent('null:objectives:complete')
AddEventHandler('null:objectives:complete', function(delay)
    CompleteObjectives(delay)
end)

RegisterNetEvent('null:objectives:stop')
AddEventHandler('null:objectives:stop', function()
    StopObjectives()
end)

-- ============================================================
-- DEBUG COMMAND
-- ============================================================

RegisterCommand('testobjectives', function()
    StartObjectives("test_lab", "Laboratoire", {
        { id = "go_lab", title = "Se diriger vers le laboratoire", description = "Suivez le GPS jusqu'à votre laboratoire" },
        { id = "enter_lab", title = "Entrer dans le laboratoire", description = "Approchez-vous de la porte et appuyez sur E" },
        { id = "explore", title = "Explorer le laboratoire", description = "Voici votre laboratoire ! Il est vide pour l'instant mais vous pouvez l'améliorer." },
        { id = "upgrade", title = "Améliorer votre équipement", description = "Utilisez le menu pour acheter des améliorations" },
    }, { color = "#22c55e" })
    
    -- Auto-advance steps for demo
    Citizen.SetTimeout(30000, function() SetObjectiveStep(nil) end)
    Citizen.SetTimeout(60000, function() SetObjectiveStep(nil) end)
    Citizen.SetTimeout(90000, function() SetObjectiveStep(nil) end)
    Citizen.SetTimeout(120000, function() CompleteObjectives() end)
end, false)
