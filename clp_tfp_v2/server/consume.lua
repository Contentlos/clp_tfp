-- clp_tfp · server/consume — Flasche füllen, Wasser abkochen, Braten, Lagerfeuer (persistent)
local ESX = exports['es_extended']:getSharedObject()
local campfires = {} -- id -> { coords, heading }

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `tfp_stations` (
            `id` INT NOT NULL AUTO_INCREMENT, `identifier` VARCHAR(64) NULL, `kind` VARCHAR(24) NOT NULL,
            `model` VARCHAR(64) NULL, `x` FLOAT, `y` FLOAT, `z` FLOAT, `heading` FLOAT, PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    local rows = MySQL.query.await("SELECT id, x, y, z, heading FROM tfp_stations WHERE kind = 'campfire'") or {}
    for _, r in ipairs(rows) do campfires[r.id] = { coords = vec3(r.x, r.y, r.z), heading = r.heading } end
end)

RegisterNetEvent('clp_tfp:fillBottle', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, 'empty_bottle', 1) then exports.ox_inventory:AddItem(src, 'water_dirty', 1) end
end)

RegisterNetEvent('clp_tfp:boilWater', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, 'water_dirty', 1) then exports.ox_inventory:AddItem(src, 'water_clean', 1)
    else TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast kein dreckiges Wasser zum Abkochen.', type = 'inform' }) end
end)

local cookCd = {}
RegisterNetEvent('clp_tfp:cook', function(raw)
    local src = source
    local cooked = Config.Cooking and Config.Cooking.recipes[raw]; if not cooked then return end
    local now = GetGameTimer(); if cookCd[src] and now - cookCd[src] < 800 then return end; cookCd[src] = now
    if exports.ox_inventory:RemoveItem(src, raw, 1) then exports.ox_inventory:AddItem(src, cooked, 1) end
end)

RegisterNetEvent('clp_tfp:placeCampfire', function(coords, heading)
    local src = source; local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    if not exports.ox_inventory:RemoveItem(src, 'campfire_kit', 1) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast kein Lagerfeuer-Set.', type = 'error' }); return
    end
    local id = MySQL.insert.await('INSERT INTO tfp_stations (identifier, kind, model, x, y, z, heading) VALUES (?,?,?,?,?,?,?)',
        { xPlayer.getIdentifier(), 'campfire', Config.CampfireModel, coords.x, coords.y, coords.z, heading or 0.0 })
    if not id then return end
    campfires[id] = { coords = vec3(coords.x, coords.y, coords.z), heading = heading or 0.0 }
    TriggerClientEvent('clp_tfp:spawnCampfire', -1, id, coords, heading)
end)

RegisterNetEvent('clp_tfp:requestCampfires', function()
    local list = {}
    for id, cf in pairs(campfires) do list[id] = cf end
    TriggerClientEvent('clp_tfp:syncCampfires', source, list)
end)

AddEventHandler('playerDropped', function() cookCd[source] = nil end)
