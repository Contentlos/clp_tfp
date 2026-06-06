-- clp_tfp · server/spawn — Erst-Spawn (Starter-Kit), Respawn-Punkt, Schlafsack
-- tfp_player-Tabelle wird in server/main angelegt.

local ESX = exports['es_extended']:getSharedObject()

local function randomPoint() return Config.Spawn.points[math.random(#Config.Spawn.points)] end

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local ident = xPlayer.getIdentifier()
    local row = MySQL.single.await('SELECT started FROM tfp_player WHERE identifier = ?', { ident })
    if not row then
        MySQL.insert.await('INSERT INTO tfp_player (identifier, started) VALUES (?, 0)', { ident })
        row = { started = 0 }
    end
    if row.started == 0 then
        SetTimeout(1500, function()
            for _, it in ipairs(Config.Spawn.starterKit) do exports.ox_inventory:AddItem(playerId, it.name, it.count) end
            MySQL.update('UPDATE tfp_player SET started = 1 WHERE identifier = ?', { ident })
            TriggerClientEvent('clp_tfp:firstSpawn', playerId, randomPoint())
        end)
    end
end)

lib.callback.register('clp_tfp:getRespawn', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local row = MySQL.single.await('SELECT spawn_x, spawn_y, spawn_z, spawn_h FROM tfp_player WHERE identifier = ?', { xPlayer.getIdentifier() })
        if row and row.spawn_x then return { x = row.spawn_x, y = row.spawn_y, z = row.spawn_z, h = row.spawn_h or 0.0 } end
    end
    local p = randomPoint(); return { x = p.x, y = p.y, z = p.z, h = p.w or 0.0 }
end)

RegisterNetEvent('clp_tfp:placeSleepingBag', function(coords, heading)
    local src = source; local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    if not exports.ox_inventory:RemoveItem(src, 'sleeping_bag', 1) then return end
    MySQL.update('UPDATE tfp_player SET spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_h = ? WHERE identifier = ?',
        { coords.x, coords.y, coords.z, heading or 0.0, xPlayer.getIdentifier() })
    TriggerClientEvent('clp_tfp:spawnSleepingBag', src, coords, heading)
    TriggerClientEvent('clp_tfp:setHome', src, coords)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Überleben', description = 'Schlafsack ausgelegt — Respawn-Punkt gesetzt.', type = 'success' })
end)

lib.callback.register('clp_tfp:getHome', function(source)
    local xPlayer = ESX.GetPlayerFromId(source); if not xPlayer then return nil end
    local row = MySQL.single.await('SELECT spawn_x, spawn_y, spawn_z FROM tfp_player WHERE identifier = ?', { xPlayer.getIdentifier() })
    if row and row.spawn_x then return { x = row.spawn_x, y = row.spawn_y, z = row.spawn_z } end
    return nil
end)
