-- clp_tfp · crafting/ (Server)
-- Rezept-Validierung (Blueprint + Zutaten, autoritativ), Blueprint-Lernen,
-- Werkbank-Platzierung (Session).

local ESX = exports['es_extended']:getSharedObject()
local known = {} -- [src] = { recipeId = true }

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_blueprints` (
            `identifier` VARCHAR(64) NOT NULL,
            `recipe` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`identifier`, `recipe`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function loadKnown(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return {} end
    local rows = MySQL.query.await('SELECT recipe FROM tfp_blueprints WHERE identifier = ?', { xPlayer.getIdentifier() }) or {}
    local set = {}
    for _, r in ipairs(rows) do set[r.recipe] = true end
    known[src] = set
    return set
end

AddEventHandler('esx:playerLoaded', function(playerId) loadKnown(playerId) end)
AddEventHandler('playerDropped', function() known[source] = nil end)

lib.callback.register('clp_tfp:getKnown', function(source)
    return known[source] or loadKnown(source)
end)

-- Admin-Wipe (Blueprints): Cache aller Spieler leeren
AddEventHandler('clp_tfp:clearAllBlueprints', function()
    for k in pairs(known) do known[k] = nil end
end)

RegisterNetEvent('clp_tfp:craft', function(recipeId)
    local src = source
    local rec = Config.Crafting.recipes[recipeId]
    if not rec then return end

    if rec.blueprint then
        local set = known[src] or loadKnown(src)
        if not set[recipeId] then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlt der Bauplan.', type = 'error' })
            return
        end
    end

    for _, ing in ipairs(rec.ingredients) do
        if (exports.ox_inventory:GetItem(src, ing.item, nil, true) or 0) < ing.count then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlen Materialien.', type = 'error' })
            return
        end
    end
    for _, ing in ipairs(rec.ingredients) do
        exports.ox_inventory:RemoveItem(src, ing.item, ing.count)
    end
    exports.ox_inventory:AddItem(src, rec.output.item, rec.output.count or 1)
    if TFP_QuestProgress then TFP_QuestProgress(src, 'craft', 'any', 1) end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Handwerk', description = 'Hergestellt: ' .. rec.label, type = 'success' })
end)

RegisterNetEvent('clp_tfp:learnBlueprint', function(name)
    local src = source
    local bp = name and Config.Blueprints[name]
    if not bp then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    known[src] = known[src] or {}
    for _, rid in ipairs(bp.recipes) do
        MySQL.insert('INSERT IGNORE INTO tfp_blueprints (identifier, recipe) VALUES (?, ?)', { ident, rid })
        known[src][rid] = true
    end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Forschung', description = 'Gelernt: ' .. bp.label, type = 'success' })
end)

-- ─── Werkbänke (DB-persistent, Tabelle tfp_stations) ─────────────────────────
local Workbenches = {}

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
    local rows = MySQL.query.await("SELECT id, x, y, z, heading FROM tfp_stations WHERE kind = 'workbench'") or {}
    for _, r in ipairs(rows) do
        Workbenches[r.id] = { coords = vec3(r.x + 0.0, r.y + 0.0, r.z + 0.0), heading = r.heading + 0.0 }
    end
end)

RegisterNetEvent('clp_tfp:placeWorkbench', function(coords, heading)
    local src = source
    if not exports.ox_inventory:RemoveItem(src, 'workbench_kit', 1) then return end
    local id = MySQL.insert.await(
        "INSERT INTO tfp_stations (kind, x, y, z, heading) VALUES ('workbench', ?, ?, ?, ?)",
        { coords.x, coords.y, coords.z, heading or 0.0 })
    if not id then return end
    Workbenches[id] = { coords = coords, heading = heading }
    TriggerClientEvent('clp_tfp:spawnWorkbench', -1, id, coords, heading)
end)

RegisterNetEvent('clp_tfp:requestWorkbenches', function()
    TriggerClientEvent('clp_tfp:syncWorkbenches', source, Workbenches)
end)
