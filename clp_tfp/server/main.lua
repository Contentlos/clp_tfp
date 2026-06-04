-- clp_tfp · survival · server (Phase 1 / Slice 1)
-- Hunger/Durst + Persistenz aller Stats laufen über esx_basicneeds / esx_status
-- (users.status). Unsere Zusatz-Stats (temperature/wetness/stamina/sickness)
-- persistieren dadurch automatisch mit.
--
-- Platzhalter für Slice 2: Item-Konsum (Essen/Trinken/Medizin), Wasser abkochen,
-- Server-seitige Validierung/Anti-Cheat der Stat-Änderungen.

local ESX = exports['es_extended']:getSharedObject()

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if TFP_OK then TFP_OK('Alle Systeme online — die Insel erwacht.') end
end)

-- Zentrale Loot-Vergabe mit globalem Balance-Multiplikator (Config.LootMultiplier).
-- Gibt true zurück, wenn mindestens ein Item vergeben wurde.
function TFP_RollGive(src, list)
    local m = Config.LootMultiplier or { chance = 1.0, amount = 1.0 }
    local got = false
    for _, it in ipairs(list) do
        if math.random(100) <= ((it.chance or 100) * (m.chance or 1.0)) then
            local amt = math.floor(math.random(it.min or 1, it.max or 1) * (m.amount or 1.0) + 0.5)
            if amt > 0 then
                exports.ox_inventory:AddItem(src, it.item, amt)
                if TFP_QuestProgress then TFP_QuestProgress(src, 'item', it.item, amt) end
                got = true
            end
        end
    end
    return got
end

-- Zentrale Admin-Prüfung: ACE tfp.admin ODER ESX-Gruppe (admin/owner/superadmin/mod)
function TFP_IsAdmin(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, 'tfp.admin') then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.getGroup then
        local g = xPlayer.getGroup()
        return g == 'admin' or g == 'superadmin' or g == 'owner' or g == 'mod'
    end
    return false
end

-- ACE zur Laufzeit sicherstellen (greift auch ohne Server-Neustart / cfg-Reload)
CreateThread(function()
    for _, g in ipairs({ 'group.admin', 'group.owner', 'group.superadmin' }) do
        ExecuteCommand(('add_ace %s tfp.admin allow'):format(g))
    end
end)

-- ─── Slice 2: Item-Tausch (autoritativ über ox_inventory) ────────────────────

-- Leere Flasche -> dreckiges Wasser (nur wenn Flasche vorhanden)
RegisterNetEvent('clp_tfp:fillBottle', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, 'empty_bottle', 1) then
        exports.ox_inventory:AddItem(src, 'water_dirty', 1)
    end
end)

-- Dreckiges Wasser -> sauberes Wasser (am Lagerfeuer)
RegisterNetEvent('clp_tfp:boilWater', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, 'water_dirty', 1) then
        exports.ox_inventory:AddItem(src, 'water_clean', 1)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast kein dreckiges Wasser.', type = 'error' })
    end
end)

-- ─── Lagerfeuer (lokale Objekte pro Client, Server hält die Liste; DB-persistent) ───
local Campfires = {}

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `tfp_stations` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `kind` VARCHAR(16) NOT NULL,
            `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    local rows = MySQL.query.await("SELECT id, x, y, z, heading FROM tfp_stations WHERE kind = 'campfire'") or {}
    for _, r in ipairs(rows) do
        Campfires[r.id] = { coords = vec3(r.x + 0.0, r.y + 0.0, r.z + 0.0), heading = r.heading + 0.0 }
    end
    if TFP_Build then TFP_Build(('%d Lagerfeuer aus DB geladen.'):format(#rows)) end
end)

RegisterNetEvent('clp_tfp:placeCampfire', function(coords, heading)
    local src = source
    if not exports.ox_inventory:RemoveItem(src, 'campfire_kit', 1) then return end
    local id = MySQL.insert.await(
        "INSERT INTO tfp_stations (kind, x, y, z, heading) VALUES ('campfire', ?, ?, ?, ?)",
        { coords.x, coords.y, coords.z, heading or 0.0 })
    if not id then return end
    Campfires[id] = { coords = coords, heading = heading }
    TriggerClientEvent('clp_tfp:spawnCampfire', -1, id, coords, heading)
end)

RegisterNetEvent('clp_tfp:requestCampfires', function()
    TriggerClientEvent('clp_tfp:syncCampfires', source, Campfires)
end)
