-- ================================================================
-- Null REALTORS — Public listings (consommé par null-immo-app)
-- ----------------------------------------------------------------
-- Expose les biens actuellement mis EN VENTE ou EN LOCATION par
-- l'agence (donc visibles publiquement par tous les civils via
-- l'app lb-phone "Null Immo").
-- ================================================================

local CFG = Config and Config.Realtors
if not CFG then return end

local function buildPublic()
    local out = {}
    if not _G.RealtorInternal or not _G.RealtorInternal.getOwnedProperties then
        return out
    end
    local owned = _G.RealtorInternal.getOwnedProperties()
    for _, p in ipairs(owned) do
        if p.listingMode == "sell" or p.listingMode == "rent" then
            local interior = CFG.InteriorTypes[p.interior] or {}
            local door     = (p.positions and p.positions["EXIT"]) or nil
            out[#out + 1] = {
                id            = p.name,
                interiorKey   = p.interior,
                interiorLabel = p.interiorLabel,
                neighborhood  = p.neighborhood,
                neighborhoodLabel = p.neighborhoodLabel,
                listingMode   = p.listingMode,
                salePrice     = (p.listingMode == "sell") and (p.salePrice or 0) or 0,
                rentPrice     = (p.listingMode == "rent") and (p.rentPrice or 0) or 0,
                photos        = interior.photos or 1,
                warehouse     = interior.warehouse or false,
                door = door and { x = door.x, y = door.y, z = door.z } or nil,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.listingMode ~= b.listingMode then return a.listingMode == "sell" end
        if a.listingMode == "sell" then return a.salePrice > b.salePrice end
        return a.rentPrice > b.rentPrice
    end)
    return out
end

ESX.RegisterServerCallback("realtor:getPublicListings", function(_source, cb)
    cb(buildPublic())
end)