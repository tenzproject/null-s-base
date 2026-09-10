local HUDEditor = {
    isOpen = false,
    layoutKey = "Null_hud_layout",
    tutorialKey = "Null_hud_tutorial_done"
}
 
function HUDEditor.Open() 
    if HUDEditor.isOpen then return end
    
    HUDEditor.isOpen = true
    
    local savedLayout = HUDEditor.LoadLayout()
    
    local savedGlobalConfig = GetResourceKvpString("hud_global_config")
    
    local tutorialDone = GetResourceKvpString(HUDEditor.tutorialKey) == "true"

    SendNUIMessage({
        action = "openHUDEditor",
        tutorialDone = tutorialDone,
        devMode = devmode == true
    })

    TriggerScreenblurFadeIn(100)

    if savedLayout then
        SendNUIMessage({
            action = "loadHUDLayout",
            layout = savedLayout
        })
        SendNUIMessage({
            action = "saveHUDLayoutToStorage",
            layout = savedLayout
        })
    end
    
    if savedGlobalConfig then
        SendNUIMessage({
            action = "loadGlobalConfig",
            config = json.decode(savedGlobalConfig)
        })
    end
    
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    DisplayRadar(false)
end

function HUDEditor.Close(doSendNUI)
    if not HUDEditor.isOpen then return end
    
    HUDEditor.isOpen = false
    
    if doSendNUI ~= false then
        SendNUIMessage({
            action = "closeHUDEditor"
        })
    end
    
    DisplayRadar(true)
    TriggerScreenblurFadeOut(100)
    SetNuiFocus(false, false)
end

function HUDEditor.SaveLayout(layout)
    if not layout then
        null.DebugPrint("HUD Editor: Error: No layout provided")
        return false
    end
    
    local layoutJson = json.encode(layout)
    SetResourceKvp(HUDEditor.layoutKey, layoutJson)
 
    SendNUIMessage({
        action = "saveHUDLayoutToStorage",
        layout = layout
    })
    
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification("Layout HUD sauvegardé avec succès~s~")
    end
    
    return true
end

function HUDEditor.LoadLayout()
    local layoutJson = GetResourceKvpString(HUDEditor.layoutKey)
    
    if not layoutJson or layoutJson == "" then
        null.DebugPrint("HUD Editor: No saved layout found")
        return nil
    end
    
    local success, layout = pcall(json.decode, layoutJson)
    
    if not success then
        null.DebugPrint("HUD Editor: Error decoding saved layout")
        return nil
    end
  
    for _, module in ipairs(layout) do
        if module.id == "minimap" then 

            local mapType = "square"
            local vehicleOnly = false
            
            if module.colors then
                mapType = module.colors.mapType or "square"
                vehicleOnly = module.colors.vehicleOnly or false
            end
            
            TriggerEvent('null-hud:updateMapConfig', {
                mapType = mapType,
                vehicleOnly = vehicleOnly,
                anchor = module.anchor or "bottom-center",
                position = module.position or { x = 1, y = 83 }
            })
            break
        end
    end
    
    return layout
end

function HUDEditor.ResetLayout()
    DeleteResourceKvp(HUDEditor.layoutKey)
    
    null.DebugPrint("HUD Editor: Layout reset to defaults")
    
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification("Layout HUD réinitialisé")
    end
    
    if HUDEditor.isOpen then
        SendNUIMessage({
            action = "loadHUDLayout",
            layout = nil 
        })
    end
end

RegisterNUICallback("saveHUDLayout", function(data, cb)
    if data.layout then
        HUDEditor.SaveLayout(data.layout)
    end
    cb("ok")
end)

RegisterNUICallback("resetHUDLayout", function(data, cb)
    HUDEditor.ResetLayout()
    cb("ok")
end)

RegisterNUICallback("closeHUDEditor", function(data, cb)
    HUDEditor.Close(false)
    cb("ok")
end)

RegisterNUICallback("setStatusBarColors", function(data, cb)
    if data.colors then
        SendNUIMessage({
            action = "setStatusBarColors",
            data = {
                colors = data.colors
            }
        })
    end
    cb("ok")
end)

RegisterNUICallback("setSpeedometerColors", function(data, cb)
    if data.colors then
        SendNUIMessage({
            action = "setSpeedometerColors",
            data = {
                colors = data.colors
            }
        })
    end
    cb("ok")
end)

RegisterNUICallback("completeTutorial", function(data, cb)
    SetResourceKvp(HUDEditor.tutorialKey, "true")
    null.DebugPrint("HUD Tutorial: Marked as completed")
    cb("ok")
end)

RegisterNUICallback("saveGlobalConfig", function(data, cb)
    if data then
        local globalConfig = json.encode(data)
        SetResourceKvp("hud_global_config", globalConfig)
    end
    cb("ok")
end)

RegisterNUICallback("setMinimapConfig", function(data, cb)
    if data.config then
        local mapType = data.config.mapType or "square"
        local vehicleOnly = data.config.vehicleOnly or false
        local anchor = data.anchor or "bottom-left"
        local position = data.position or { x = 1, y = 83 }

        TriggerEvent('null-hud:updateMapConfig', {
            mapType = mapType,
            vehicleOnly = vehicleOnly,
            anchor = anchor,
            position = position
        })
        
        SendNUIMessage({
            action = "setMinimapConfig",
            data = {
                config = data.config
            }
        })
    end
    cb("ok")
end)

RegisterKeyMapping('hudedit', 'Ouvrir l\'éditeur de HUD', 'keyboard', "m")
RegisterCommand("hudedit", function()
    if HUDEditor.isOpen then
        HUDEditor.Close()
    else
        HUDEditor.Open()
    end
end, false)

RegisterCommand("hudreset_tutorial", function()
    DeleteResourceKvp(HUDEditor.tutorialKey)
    null.DebugPrint("HUD Tutorial: Reset")
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification("Tutoriel HUD réinitialisé. Il s'affichera à la prochaine ouverture de l'éditeur.")
    end
end, false)

TriggerEvent('chat:addSuggestion', '/hudedit', 'Ouvrir l\'éditeur de HUD pour personnaliser votre interface')
TriggerEvent('chat:addSuggestion', '/hudreset_tutorial', 'Réinitialiser le tutoriel de l\'éditeur HUD')

AddEventHandler('esx:playerLoaded', function(xPlayer)
    Citizen.Wait(2000)
    
    local savedLayout = HUDEditor.LoadLayout()
    
    if savedLayout then
        SendNUIMessage({
            action = "loadHUDLayout",
            layout = savedLayout
        })
    else
        SendNUIMessage({
            action = "loadDefaultLayout"
        })
    end
end)

exports('OpenHUDEditor', function()
    HUDEditor.Open()
end)

exports('CloseHUDEditor', function()
    HUDEditor.Close()
end)

exports('SaveHUDLayout', function(layout)
    return HUDEditor.SaveLayout(layout)
end)

exports('LoadHUDLayout', function()
    return HUDEditor.LoadLayout()
end)

exports('ResetHUDLayout', function()
    HUDEditor.ResetLayout()
end)

if not null.modules.ui then
    null.modules.ui = {}
end
if not null.modules.ui.interactions then
    null.modules.ui.interactions = {}
end
null.modules.ui.interactions.HUDEditor = HUDEditor

null.InitPrint("HUD Editor Loaded successfully")
