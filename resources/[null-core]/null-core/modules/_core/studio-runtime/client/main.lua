-- Studio Runtime Client: applique les blips dynamiques (mapPoint) et shops Studio

local StudioBlips = {}   -- [slug] = blipHandle
local StudioShops = {}   -- [slug] = { label, payload }

local function removeBlip(slug)
    if StudioBlips[slug] then
        RemoveBlip(StudioBlips[slug])
        StudioBlips[slug] = nil
    end
end

local function applyBlip(slug, payload, label)
    removeBlip(slug)
    if not payload or not payload.coords then return end

    local c = payload.coords
    local blip = AddBlipForCoord(c.x or 0.0, c.y or 0.0, c.z or 0.0)
    SetBlipSprite(blip, tonumber(payload.sprite) or 1)
    SetBlipColour(blip, tonumber(payload.color) or 0)
    SetBlipScale(blip, tonumber(payload.scale) or 0.8)
    SetBlipAsShortRange(blip, payload.shortRange ~= false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label or payload.name or "Null Studio")
    EndTextCommandSetBlipName(blip)

    StudioBlips[slug] = blip
end

RegisterNetEvent("null:studio:applyMapPoint", function(slug, payload, label)
    applyBlip(slug, payload, label)
end)

RegisterNetEvent("null:studio:applyShop", function(slug, payload, label)
    StudioShops[slug] = { label = label, payload = payload }
    -- Tip: les shops Studio ne créent pas de markers GTA: on s'appuie sur l'event de marker existant si besoin.
end)

RegisterNetEvent("null:studio:remove", function(type, slug)
    if type == "mapPoint" then removeBlip(slug) end
    if type == "shop" then StudioShops[slug] = nil end
end)

-- Cleanup au resource stop
AddEventHandler("onResourceStop", function(r)
    if r ~= GetCurrentResourceName() then return end
    for slug, _ in pairs(StudioBlips) do removeBlip(slug) end
end)
