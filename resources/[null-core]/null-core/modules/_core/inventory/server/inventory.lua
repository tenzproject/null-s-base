local function addSlotEntry(entries, kind, ref, index)
    entries[#entries + 1] = {
        kind = kind,
        ref = ref,
        index = index,
    }
end

local slotMoveLocks = {}

local function buildPlayerSlotEntries(xPlayer)
    local entries = {}

    for index, account in ipairs(xPlayer.accounts or {}) do
        if (account.name == "cash" or account.name == "dirtycash") and (account.money or 0) > 0 then
            addSlotEntry(entries, "account", account, index)
        end
    end

    for index, item in ipairs(xPlayer.inventory or {}) do
        if (item.count or 0) > 0 then
            addSlotEntry(entries, "item", item, index)
        end
    end

    for index, weapon in ipairs(xPlayer.loadout or {}) do
        addSlotEntry(entries, "weapon", weapon, index)
    end

    return entries
end

local function getEntryIdentifiers(entry)
    local identifiers = {}
    if not entry then return identifiers end

    if entry.kind == "account" then
        identifiers[#identifiers + 1] = tostring(entry.ref.name) .. ":" .. tostring(entry.ref.name)
        return identifiers
    end

    if entry.kind == "weapon" then
        local serial = entry.ref.serialnumber or (entry.ref.metadata and entry.ref.metadata.serialnumber)
        identifiers[#identifiers + 1] = entry.kind .. ":" .. tostring(entry.ref.name) .. ":" .. tostring(entry.index)
        if serial then
            identifiers[#identifiers + 1] = entry.kind .. ":" .. tostring(entry.ref.name) .. ":" .. tostring(serial)
        end
        return identifiers
    end

    identifiers[#identifiers + 1] = entry.kind .. ":" .. tostring(entry.ref.name) .. ":" .. tostring(entry.index)

    local uniqueId = entry.ref.id or entry.ref.uniqueId or entry.ref.identifier
    if entry.ref.extra and type(entry.ref.extra) == "table" then
        uniqueId = uniqueId or entry.ref.extra.identifier or entry.ref.extra.id
    end
    if entry.ref.metadata and type(entry.ref.metadata) == "table" then
        uniqueId = uniqueId or entry.ref.metadata.identifier or entry.ref.metadata.id
    end

    if uniqueId then
        identifiers[#identifiers + 1] = entry.kind .. ":" .. tostring(entry.ref.name) .. ":" .. tostring(uniqueId)
    end

    return identifiers
end

local function entryMatchesIdentifier(entry, identifier)
    if not identifier then return true end

    for _, entryIdentifier in ipairs(getEntryIdentifiers(entry)) do
        if tostring(identifier) == tostring(entryIdentifier) then
            return true
        end
    end

    return false
end

local function normalizePlayerSlots(entries)
    local used = {}
    local nextSlot = 1

    for _, entry in ipairs(entries) do
        local slot = tonumber(entry.ref.slot)
        if slot and slot > 0 and not used[slot] then
            entry.ref.slot = slot
            used[slot] = true
        else
            while used[nextSlot] do
                nextSlot = nextSlot + 1
            end
            entry.ref.slot = nextSlot
            used[nextSlot] = true
        end
    end
end

local function buildSlotSnapshot(xPlayer)
    local snapshot = {
        accounts = {},
        inventory = {},
        loadout = {},
    }

    for index, account in ipairs(xPlayer.accounts or {}) do
        snapshot.accounts[#snapshot.accounts + 1] = {
            index = index,
            name = account.name,
            slot = tonumber(account.slot),
        }
    end

    for index, item in ipairs(xPlayer.inventory or {}) do
        snapshot.inventory[#snapshot.inventory + 1] = {
            index = index,
            name = item.name,
            slot = tonumber(item.slot),
            identifier = item.extra and item.extra.identifier or nil,
        }
    end

    for index, weapon in ipairs(xPlayer.loadout or {}) do
        snapshot.loadout[#snapshot.loadout + 1] = {
            index = index,
            name = weapon.name,
            slot = tonumber(weapon.slot),
            serialnumber = weapon.serialnumber,
        }
    end

    return snapshot
end

local function matchesDraggedItem(entry, item, fromSlot)
    if item.type == "cash" or item.type == "dirtycash" then
        return entry.kind == "account" and entry.ref.name == item.name
    end

    if entry.kind ~= item.type then return false end

    local itemId = tonumber(item.id)
    if itemId and entry.index == itemId and entry.ref.name == item.name then
        return true
    end

    return entry.ref.name == item.name and tonumber(entry.ref.slot) == fromSlot
end

RegisterNetEvent("null:inventory:moveSlot", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if slotMoveLocks[src] then
        if xPlayer then
            TriggerClientEvent("null:inventory:syncSlots", src, buildSlotSnapshot(xPlayer))
        end
        TriggerClientEvent("null:inventory:update", src)
        return
    end

    slotMoveLocks[src] = true

    if not xPlayer or type(data) ~= "table" or type(data.item) ~= "table" then
        slotMoveLocks[src] = nil
        return
    end
    if data.inventory ~= "left" then
        slotMoveLocks[src] = nil
        return
    end

    local fromSlot = tonumber(data.fromSlot)
    local toSlot = tonumber(data.toSlot)
    if not fromSlot or not toSlot or fromSlot < 1 or toSlot < 1 or toSlot > 200 then
        slotMoveLocks[src] = nil
        TriggerClientEvent("null:inventory:syncSlots", src, buildSlotSnapshot(xPlayer))
        TriggerClientEvent("null:inventory:update", src)
        return
    end

    if data.item.type == "accessory" then
        if data.item.type2 == "bag" and _G.InventoryBackpacks and _G.InventoryBackpacks.MoveSlot then
            _G.InventoryBackpacks.MoveSlot(src, data.item.name, fromSlot, toSlot, function(success)
                TriggerClientEvent("null:inventory:clearClothesCache", src)
                TriggerClientEvent("null:inventory:update", src)
                if ESX.ScheduleAdminRefresh then ESX.ScheduleAdminRefresh(src) end
                slotMoveLocks[src] = nil
            end)
        elseif _G.InventoryClothes and _G.InventoryClothes.MoveSlot then
            _G.InventoryClothes.MoveSlot(src, data.item.name, fromSlot, toSlot, function(success)
                TriggerClientEvent("null:inventory:clearClothesCache", src)
                TriggerClientEvent("null:inventory:update", src)
                if ESX.ScheduleAdminRefresh then ESX.ScheduleAdminRefresh(src) end
                slotMoveLocks[src] = nil
            end)
        else
            TriggerClientEvent("null:inventory:update", src)
            slotMoveLocks[src] = nil
        end
        return
    end

    local entries = buildPlayerSlotEntries(xPlayer)
    normalizePlayerSlots(entries)

    local fromEntry = nil
    local targetEntry = nil

    for _, entry in ipairs(entries) do
        if matchesDraggedItem(entry, data.item, fromSlot) then
            fromEntry = entry
        end

        if tonumber(entry.ref.slot) == toSlot then
            targetEntry = entry
        end
    end

    if not fromEntry or fromEntry == targetEntry then
        slotMoveLocks[src] = nil
        TriggerClientEvent("null:inventory:syncSlots", src, buildSlotSnapshot(xPlayer))
        TriggerClientEvent("null:inventory:update", src)
        return
    end

    local draggedIdentifier = data.slotKey or data.item.slotKey or data.item.uid or data.item.uniqueId
    if draggedIdentifier and not entryMatchesIdentifier(fromEntry, draggedIdentifier) then
        slotMoveLocks[src] = nil
        TriggerClientEvent("null:inventory:syncSlots", src, buildSlotSnapshot(xPlayer))
        TriggerClientEvent("null:inventory:update", src)
        return
    end

    local oldSlot = tonumber(fromEntry.ref.slot) or fromSlot
    fromEntry.ref.slot = toSlot

    if targetEntry then
        targetEntry.ref.slot = oldSlot
    end

    xPlayer.markDirty("accounts")
    xPlayer.markDirty("inventory")
    xPlayer.markDirty("loadout")

    if ESX.SavePlayer then ESX.SavePlayer(xPlayer) end
    TriggerClientEvent("null:inventory:syncSlots", src, buildSlotSnapshot(xPlayer))
    TriggerClientEvent("null:inventory:update", src)
    if ESX.ScheduleAdminRefresh then ESX.ScheduleAdminRefresh(src) end
    slotMoveLocks[src] = nil
end)

AddEventHandler("playerDropped", function()
    slotMoveLocks[source] = nil
end)
