-- clp_tfp · survival · spawn/ (Server)
-- Erstes Spawnen: Starter-Kit + verstreut an den Strand. Respawn-Punkt (Schlafsack
-- > zufälliger Strand). Persistenz in eigener Tabelle tfp_player.

local ESX = exports['es_extended']:getSharedObject()

-- DB-Tabelle sicherstellen (Auto-Create wie bei kq_propplacer)
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_player` (
            `identifier` VARCHAR(64) NOT NULL,
            `started` TINYINT(1) NOT NULL DEFAULT 0,
            `spawn_x` FLOAT NULL,
            `spawn_y` FLOAT NULL,
            `spawn_z` FLOAT NULL,
            `spawn_h` FLOAT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function randomPoint()
    return Config.Spawn.points[math.random(#Config.Spawn.points)]
end

-- Erstes Spawnen: Starter-Kit geben + verstreut an den Strand
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local ident = xPlayer.getIdentifier()
    local row = MySQL.single.await('SELECT started FROM tfp_player WHERE identifier = ?', { ident })
    if not row then
        MySQL.insert.await('INSERT INTO tfp_player (identifier, started) VALUES (?, 0)', { ident })
        row = { started = 0 }
    end

    if row.started == 0 then
        SetTimeout(1500, function() -- kurze Verzögerung, bis das Inventar bereit ist
            for _, it in ipairs(Config.Spawn.starterKit) do
                exports.ox_inventory:AddItem(playerId, it.name, it.count)
            end
            MySQL.update('UPDATE tfp_player SET started = 1 WHERE identifier = ?', { ident })
            TriggerClientEvent('clp_tfp:firstSpawn', playerId, randomPoint())
        end)
    end
end)

-- Respawn-Punkt liefern: Schlafsack, sonst zufälliger Strand
lib.callback.register('clp_tfp:getRespawn', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local row = MySQL.single.await(
            'SELECT spawn_x, spawn_y, spawn_z, spawn_h FROM tfp_player WHERE identifier = ?',
            { xPlayer.getIdentifier() })
        if row and row.spawn_x then
            return { x = row.spawn_x, y = row.spawn_y, z = row.spawn_z, h = row.spawn_h or 0.0 }
        end
    end
    local p = randomPoint()
    return { x = p.x, y = p.y, z = p.z, h = p.w or 0.0 }
end)

-- Schlafsack platzieren -> Respawn-Punkt setzen (autoritativ über ox_inventory)
RegisterNetEvent('clp_tfp:placeSleepingBag', function(coords, heading)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not exports.ox_inventory:RemoveItem(src, 'sleeping_bag', 1) then return end

    MySQL.update(
        'UPDATE tfp_player SET spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_h = ? WHERE identifier = ?',
        { coords.x, coords.y, coords.z, heading or 0.0, xPlayer.getIdentifier() })

    TriggerClientEvent('clp_tfp:spawnSleepingBag', src, coords, heading)
    TriggerClientEvent('clp_tfp:setHome', src, coords)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Überleben', description = 'Schlafsack ausgelegt — du respawnst jetzt hier.', type = 'success'
    })
end)

-- Home-Blip (Schlafplatz) abfragen — beim Join
lib.callback.register('clp_tfp:getHome', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    local row = MySQL.single.await('SELECT spawn_x, spawn_y, spawn_z FROM tfp_player WHERE identifier = ?', { xPlayer.getIdentifier() })
    if row and row.spawn_x then return { x = row.spawn_x, y = row.spawn_y, z = row.spawn_z } end
    return nil
end)
