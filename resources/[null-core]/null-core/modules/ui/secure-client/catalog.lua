-- Catalog Tablet - Generic grid catalog with detail modal
-- Usage: exports["null-core"]:OpenCatalog(data)
-- data = {
--   title = "Titre",
--   subtitle = "Sous-titre" (optional),
--   items = {
--     { id = "labo_1", label = "Laboratoire Meth", description = "...", price = 50000, image = "url" (optional), options = { {value="ind", label="Pour vous"}, ... } (optional), metadata = {} (optional) },
--   },
--   imagePath = "nui://null-core/images/" (optional),
--   currency = "$" (optional, default "$"),
--   callbackEvent = "null:catalog:onBuy" -- server event triggered on purchase
-- }

local isCatalogOpen = false

function OpenCatalog(data)
    if isCatalogOpen then return end
    if not data or not data.items then return end

    isCatalogOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "catalog:open",
        data = {
            title = data.title or "Catalogue",
            subtitle = data.subtitle or nil,
            description = data.description or nil,
            items = data.items,
            imagePath = data.imagePath or nil,
            currency = data.currency or "$",
            callbackEvent = data.callbackEvent or "null:catalog:onBuy",
        }
    })
end

function CloseCatalog()
    if not isCatalogOpen then return end
    isCatalogOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "catalog:close" })
end

exports("OpenCatalog", OpenCatalog)
exports("CloseCatalog", CloseCatalog)

-- NUI Callback: close
RegisterNUICallback("catalog:close", function(data, cb)
    CloseCatalog()
    cb("ok")
end)

-- NUI Callback: buy
RegisterNUICallback("catalog:buy", function(data, cb)
    if not data or not data.callbackEvent then
        cb("ok")
        return
    end

    -- Trigger the server event with purchase data
    ESX.TriggerServerCallback(data.callbackEvent, function(result)
        if result and result.success then
            SendNUIMessage({
                action = "catalog:purchaseResult",
                data = { success = true, message = result.message or "Achat effectué !" }
            })
            -- Close catalog after successful purchase if specified
            if result.close then
                Wait(500)
                CloseCatalog()
            end
        else
            SendNUIMessage({
                action = "catalog:purchaseResult",
                data = { success = false, message = (result and result.message) or "Erreur lors de l'achat" }
            })
        end
    end, data.itemId, data.option, data.metadata)

    cb("ok")
end)
