-- ============================================================================
-- TUTORIAL EVENT DETECTION SYSTEM (v2)
-- Hooks into existing functions to detect when players complete actions
-- ============================================================================

local tutorialActive = false
local originalFunctions = {}

-- ============================================================================
-- ENABLE/DISABLE HOOKS
-- ============================================================================

function EnableTutorialEventHooks()
    tutorialActive = true
    
    -- Hook driving school open
    if OpenDriveSchool and not originalFunctions.OpenDriveSchool then
        originalFunctions.OpenDriveSchool = OpenDriveSchool
        OpenDriveSchool = function()
            originalFunctions.OpenDriveSchool()
            if tutorialActive then
                TriggerEvent('null:tutorial:eventDetected', 'driveschool_opened')
            end
        end
    end
    
    -- Hook driving school close
    if CloseDriveSchool and not originalFunctions.CloseDriveSchool then
        originalFunctions.CloseDriveSchool = CloseDriveSchool
        CloseDriveSchool = function()
            originalFunctions.CloseDriveSchool()
            if tutorialActive then
                TriggerEvent('null:tutorial:eventDetected', 'driveschool_closed')
            end
        end
    end
end

function DisableTutorialEventHooks()
    tutorialActive = false
    
    if originalFunctions.OpenDriveSchool then
        OpenDriveSchool = originalFunctions.OpenDriveSchool
    end
    if originalFunctions.CloseDriveSchool then
        CloseDriveSchool = originalFunctions.CloseDriveSchool
    end
end

-- ============================================================================
-- LICENSE COMPLETION DETECTION
-- ============================================================================

RegisterNetEvent('null:driveschool:updateData', function(licenses)
    if not tutorialActive then return end
    
    for _, lic in ipairs(licenses) do
        if lic.id == 'drive' and lic.theory and lic.practice then
            TriggerEvent('null:tutorial:eventDetected', 'license_completed')
            break
        end
    end
end)

null.InitPrint('Tutorial event detection system loaded')
