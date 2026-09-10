-- Studio Runtime: applique les customizations Studio (jobs, items, blips, shops) en live
-- Reçues via POST /studio/apply ou pull au boot depuis l'API.

local API_ENDPOINT = "https://api.null.fr"

local StudioRuntime = {
    customizations = {}, -- [type][slug] = { payload, version, label }
}
_G.StudioRuntime = StudioRuntime

local function ok(d) local r = d or {} r.success = true return r end
local function err(msg, code) return { success = false, error = msg, _status = code or 400 } end

-- ============================================
-- APPLICATEURS PAR TYPE
-- ============================================

local Appliers = {}

-- Job: insère/met à jour en DB
function Appliers.job(slug, payload, label)
    if not MySQL then return false, "MySQL non chargé" end
    -- Structure attendue: { type = 'legal'|'illegal', salary, grades = { { grade=0, label, salary } }, blip = { sprite, color, coords = {x,y,z} } }
    payload = payload or {}

    -- Job principal
    MySQL.query.await([[
        INSERT INTO jobs (name, label, whitelisted)
        VALUES (?, ?, 0)
        ON DUPLICATE KEY UPDATE label = VALUES(label)
    ]], { slug, label })

    -- Grades
    if payload.grades and #payload.grades > 0 then
        MySQL.query.await("DELETE FROM job_grades WHERE job_name = ?", { slug })
        for _, g in ipairs(payload.grades) do
            MySQL.query.await([[
                INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female)
                VALUES (?, ?, ?, ?, ?, '{}', '{}')
            ]], {
                slug,
                tonumber(g.grade) or 0,
                g.name or g.label or "grade_" .. (g.grade or 0),
                g.label or "Grade",
                tonumber(g.salary) or 0,
            })
        end
    end

    -- Notif staff
    if ESX and ESX.ShowAnnouncementToStaff then
        ESX.ShowAnnouncementToStaff(("[Studio] Job '%s' appliqué"):format(label), 5000, "Studio")
    end
    return true
end

-- MapPoint: blip global servi via event au client
function Appliers.mapPoint(slug, payload, label)
    -- payload = { coords = {x,y,z}, sprite, color, scale, label }
    TriggerClientEvent("null:studio:applyMapPoint", -1, slug, payload, label)
    return true
end

-- Item: insère en DB items
function Appliers.item(slug, payload, label)
    if not MySQL then return false, "MySQL non chargé" end
    payload = payload or {}
    MySQL.query.await([[
        INSERT INTO items (name, label, weight, rare, can_remove, type)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), weight = VALUES(weight)
    ]], {
        slug, label,
        tonumber(payload.weight) or 1,
        payload.rare and 1 or 0,
        payload.canRemove == false and 0 or 1,
        payload.type or "item_standard",
    })
    -- Reload items en mémoire si fct dispo
    if ESX and ESX.Items then
        ESX.Items[slug] = { name = slug, label = label, weight = tonumber(payload.weight) or 1 }
    end
    return true
end

-- Shop: stocké en mémoire, lecture côté markers
function Appliers.shop(slug, payload, label)
    -- payload = { coords, items = { { name, price } }, jobRestriction? }
    StudioRuntime.customizations.shop = StudioRuntime.customizations.shop or {}
    StudioRuntime.customizations.shop[slug] = { label = label, payload = payload }
    TriggerClientEvent("null:studio:applyShop", -1, slug, payload, label)
    return true
end

-- Vehicle: ajoute en vehicles (vente concessionnaire)
function Appliers.vehicle(slug, payload, label)
    if not MySQL then return false, "MySQL non chargé" end
    payload = payload or {}
    MySQL.query.await([[
        INSERT INTO vehicles (model, name, price, category, hash)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE price = VALUES(price), category = VALUES(category)
    ]], {
        slug,
        label,
        tonumber(payload.price) or 0,
        payload.category or "compacts",
        payload.hash or slug,
    })
    return true
end

-- ============================================
-- APPLY (un seul élément)
-- ============================================

function StudioRuntime.apply(type, slug, label, payload, version)
    if not Appliers[type] then return false, "Type non supporté: " .. tostring(type) end
    local success, errMsg = pcall(Appliers[type], slug, payload, label)
    if not success then
        print("^1[Studio] Apply error for " .. type .. "/" .. slug .. ": " .. tostring(errMsg) .. "^7")
        return false, errMsg
    end
    StudioRuntime.customizations[type] = StudioRuntime.customizations[type] or {}
    StudioRuntime.customizations[type][slug] = { label = label, payload = payload, version = version or 1 }
    print(("^2[Studio] Appliqué: %s/%s v%d^7"):format(type, slug, version or 1))
    return true
end

-- ============================================
-- ROUTE HTTP /studio/apply
-- ============================================

if null and null.api and null.api.registerRoute then
    null.api.registerRoute("POST", "/studio/apply", function(body)
        if not body or not body.type or not body.slug then
            return err("type et slug requis")
        end
        local success, errMsg = StudioRuntime.apply(body.type, body.slug, body.label, body.payload, body.version)
        if not success then return err(errMsg or "Erreur d'application", 500) end
        return ok({ message = "Customization appliquée" })
    end)
end

exports("ApplyStudioCustomization", StudioRuntime.apply)
exports("GetStudioCustomizations", function() return StudioRuntime.customizations end)
