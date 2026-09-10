-- ================================================================
-- Null Immo — lb-phone custom app (client)
-- ----------------------------------------------------------------
-- - Enregistre l'app dans lb-phone
-- - Bridge UI ↔ null-core (récupère les listings publics, pose
--   un waypoint sur la porte, etc.)
-- ================================================================

local IDENTIFIER = "Null_immo"

while GetResourceState("lb-phone") ~= "started" do
    Wait(500)
end

local function addApp()
    local ok, err = exports["lb-phone"]:AddCustomApp({
        identifier  = IDENTIFIER,
        name        = "Null Immo",
        description = "Le marché immobilier de Los Santos en direct sur ton téléphone. Vente, location, entrepôts.",
        developer   = "Null",
        size        = 18000,
        defaultApp  = false,       -- visible dans l'app store (gratuit)
        price       = 0,           -- gratuit
        ui          = GetCurrentResourceName() .. "/ui/index.html",
        icon        = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/icon.svg",
        images = {
            "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/assets/icon.svg",
        },
        fixBlur     = true,
    })
    if not ok then
        print("^1[null-IMMO] AddCustomApp a échoué : " .. tostring(err) .. "^0")
    else
        print("^2[null-IMMO] App enregistrée dans lb-phone^0")
    end
end

addApp()
AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then addApp() end
end)

-- ----------------------------------------------------------------
-- NUI bridge : the embedded UI fetches data through these routes
-- ----------------------------------------------------------------
RegisterNUICallback("getListings", function(_, cb)
    if not ESX or not ESX.TriggerServerCallback then
        cb({ ok = false, error = "ESX not ready" })
        return
    end
    ESX.TriggerServerCallback("realtor:getPublicListings", function(listings)
        cb({ ok = true, listings = listings or {} })
    end)
end)

RegisterNUICallback("setWaypoint", function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(data.x + 0.0, data.y + 0.0)
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification("~b~GPS mis à jour vers le bien")
        end
    end
    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    -- Lb-phone gère la fermeture via son propre UI; on accepte l'event
    -- pour de futures actions custom (sons, etc.)
    cb("ok")
end)
