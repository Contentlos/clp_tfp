-- clp_tfp · threat/ (Server) — Loot-Drop bei Tod, Downed-Sync, Revive, Tode-Log (12h)

local ESX = exports['es_extended']:getSharedObject()

-- ─── Tode-Log: Spieler-Tode erfassen, aber NUR begrenzt aufbewahren (Config.Threat.deathLogHours) ──
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_deaths` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `name` VARCHAR(64) NOT NULL DEFAULT '',
            `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
            `created` INT NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- regelmäßig alte Einträge löschen (kein „ewiges" Speichern)
    while true do
        local cutoff = os.time() - ((Config.Threat.deathLogHours or 12) * 3600)
        MySQL.query('DELETE FROM tfp_deaths WHERE created < ?', { cutoff })
        Wait(1800000) -- alle 30 Min aufräumen
    end
end)

local function logDeath(src)
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local c = GetEntityCoords(GetPlayerPed(src))
    MySQL.insert('INSERT INTO tfp_deaths (identifier, name, x, y, z, created) VALUES (?, ?, ?, ?, ?, ?)',
        { xPlayer.getIdentifier(), GetPlayerName(src) or '?', c.x, c.y, c.z, os.time() })
end

-- Admin: letzte Tode (nur innerhalb der Aufbewahrungszeit)
lib.callback.register('clp_tfp:getRecentDeaths', function(source)
    if not TFP_IsAdmin(source) then return {} end
    local cutoff = os.time() - ((Config.Threat.deathLogHours or 12) * 3600)
    local rows = MySQL.query.await('SELECT name, x, y, z, created FROM tfp_deaths WHERE created >= ? ORDER BY created DESC LIMIT 40', { cutoff }) or {}
    local now = os.time()
    for _, r in ipairs(rows) do r.ago = now - r.created end
    return rows
end)

RegisterNetEvent('clp_tfp:died', function()
    local src = source
    logDeath(src)  -- in den 12h-Log eintragen
    if not Config.Threat.dropInventoryOnDeath then return end
    -- gesamtes Inventar als lootbaren Beutel am Sterbeort
    pcall(function() exports.ox_inventory:CreateDropFromPlayer(src) end)
end)

-- Downed-Status an alle broadcasten (für Revive-Ziele)
RegisterNetEvent('clp_tfp:setDowned', function(state)
    TriggerClientEvent('clp_tfp:playerDowned', -1, source, state and true or false)
end)

-- Wiederbeleben: Reviver verbraucht das Item, Ziel wird geheilt
RegisterNetEvent('clp_tfp:revive', function(targetServerId)
    local src = source
    local cfg = Config.Threat.downed or {}
    if (exports.ox_inventory:GetItem(src, cfg.reviveItem, nil, true) or 0) < 1 then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du brauchst ein Erste-Hilfe-Set.', type = 'error' })
        return
    end
    exports.ox_inventory:RemoveItem(src, cfg.reviveItem, 1)
    TriggerClientEvent('clp_tfp:revived', targetServerId)
end)

-- Verbinden / Schienen (verbraucht Item autoritativ)
RegisterNetEvent('clp_tfp:useBandage', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, (Config.Injury and Config.Injury.bandageItem) or 'bandage', 1) then
        TriggerClientEvent('clp_tfp:bandaged', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast keinen Verband.', type = 'error' })
    end
end)

RegisterNetEvent('clp_tfp:useSplint', function()
    local src = source
    if exports.ox_inventory:RemoveItem(src, (Config.Injury and Config.Injury.splintItem) or 'splint', 1) then
        TriggerClientEvent('clp_tfp:splinted', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast keine Schiene.', type = 'error' })
    end
end)
