-- clp_tfp · server/lore — gefundene Tagebuch-Seiten persistent + Vollständigkeits-Belohnung

local ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Wait(2000) -- tfp_player wird in spawn.lua angelegt
    MySQL.query("ALTER TABLE `tfp_player` ADD COLUMN IF NOT EXISTS `lore` TEXT NULL")
end)

local function getFound(ident)
    local row = MySQL.single.await('SELECT lore FROM tfp_player WHERE identifier = ?', { ident })
    if row and row.lore and row.lore ~= '' then
        local ok, d = pcall(json.decode, row.lore)
        if ok and type(d) == 'table' then return d end
    end
    return {}
end

local function count(found)
    local n = 0; for _ in pairs(found) do n = n + 1 end; return n
end

lib.callback.register('clp_tfp:getLore', function(source)
    local xp = ESX.GetPlayerFromId(source); if not xp then return {} end
    return getFound(xp.getIdentifier())
end)

RegisterNetEvent('clp_tfp:loreFound', function(noteId)
    local src = source
    local xp = ESX.GetPlayerFromId(src); if not xp then return end
    noteId = tonumber(noteId); if not noteId then return end
    local notes = (Config.Atmosphere and Config.Atmosphere.notes) or {}
    local total = #notes
    if noteId < 1 or noteId > total then return end

    local ident = xp.getIdentifier()
    local found = getFound(ident)
    local key = tostring(noteId)
    if found[key] then return end -- schon gefunden -> nichts tun

    found[key] = true
    MySQL.update('UPDATE tfp_player SET lore = ? WHERE identifier = ?', { json.encode(found), ident })

    local c = count(found)
    TriggerClientEvent('clp_tfp:loreAck', src, noteId, c, total)

    -- Vollständigkeits-Belohnung
    if c >= total and Config.Atmosphere.loreReward then
        for _, r in ipairs(Config.Atmosphere.loreReward) do
            exports.ox_inventory:AddItem(src, r.item, r.count or 1)
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Tagebuch vollständig', description = 'Du hast jede Seite gefunden — die Wahrheit über die Insel. (Belohnung erhalten)',
            type = 'success', duration = 9000 })
    end
end)
