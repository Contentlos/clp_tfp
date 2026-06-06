-- clp_tfp · server/crafting — Rezept-Validierung (Blueprint + Zutaten) + Blueprint-Lernen
local ESX = exports['es_extended']:getSharedObject()
local known = {} -- [src] = { recipeId = true }

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `tfp_blueprints` (
            `identifier` VARCHAR(64) NOT NULL, `recipe` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`identifier`, `recipe`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function loadKnown(src)
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return {} end
    local rows = MySQL.query.await('SELECT recipe FROM tfp_blueprints WHERE identifier = ?', { xPlayer.getIdentifier() }) or {}
    local set = {}; for _, r in ipairs(rows) do set[r.recipe] = true end
    known[src] = set; return set
end

AddEventHandler('esx:playerLoaded', function(playerId) loadKnown(playerId) end)
AddEventHandler('playerDropped', function() known[source] = nil end)
AddEventHandler('clp_tfp:clearAllBlueprints', function() for k in pairs(known) do known[k] = nil end end)

lib.callback.register('clp_tfp:getKnown', function(source) return known[source] or loadKnown(source) end)

RegisterNetEvent('clp_tfp:craft', function(recipeId)
    local src = source
    local rec = Config.Crafting.recipes[recipeId]; if not rec then return end
    if rec.blueprint then
        local set = known[src] or loadKnown(src)
        if not set[recipeId] then TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlt der Bauplan.', type = 'error' }); return end
    end
    for _, ing in ipairs(rec.ingredients) do
        if (exports.ox_inventory:GetItem(src, ing.item, nil, true) or 0) < ing.count then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlen Materialien.', type = 'error' }); return
        end
    end
    for _, ing in ipairs(rec.ingredients) do exports.ox_inventory:RemoveItem(src, ing.item, ing.count) end
    exports.ox_inventory:AddItem(src, rec.output.item, rec.output.count or 1)
    if TFP_QuestProgress then TFP_QuestProgress(src, 'craft', 'any', 1) end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Handwerk', description = 'Hergestellt: ' .. rec.label, type = 'success' })
end)

RegisterNetEvent('clp_tfp:learnBlueprint', function(name)
    local src = source
    local bp = name and Config.Blueprints[name]; if not bp then return end
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    known[src] = known[src] or {}
    for _, rid in ipairs(bp.recipes) do
        MySQL.insert('INSERT IGNORE INTO tfp_blueprints (identifier, recipe) VALUES (?, ?)', { ident, rid })
        known[src][rid] = true
    end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Forschung', description = 'Gelernt: ' .. bp.label, type = 'success' })
end)
