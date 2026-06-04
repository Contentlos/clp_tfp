-- clp_tfp · tribe/ (Server) : Stämme, Ränge, geteilter Zugriff, Marker

local ESX = exports['es_extended']:getSharedObject()

local membersByIdent = {} -- [identifier] = { tribeId, rank, name }
local tribes = {}         -- [tribeId]   = { id, name, owner, members = { [identifier] = rank } }
local invites = {}        -- [identifier] = tribeId

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_tribes` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(48) NOT NULL,
            `owner` VARCHAR(64) NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_tribe_members` (
            `tribe_id` INT NOT NULL,
            `identifier` VARCHAR(64) NOT NULL,
            `rank` VARCHAR(16) NOT NULL DEFAULT 'member',
            `name` VARCHAR(48) NOT NULL DEFAULT '',
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    Wait(800)
    for _, t in ipairs(MySQL.query.await('SELECT * FROM tfp_tribes') or {}) do
        tribes[t.id] = { id = t.id, name = t.name, owner = t.owner, members = {} }
    end
    for _, m in ipairs(MySQL.query.await('SELECT * FROM tfp_tribe_members') or {}) do
        membersByIdent[m.identifier] = { tribeId = m.tribe_id, rank = m.rank, name = m.name }
        if tribes[m.tribe_id] then tribes[m.tribe_id].members[m.identifier] = m.rank end
    end
end)

-- von building/ genutzt
function TFP_AreSameTribe(a, b)
    if a == b then return true end
    local ma, mb = membersByIdent[a], membersByIdent[b]
    return (ma ~= nil and mb ~= nil and ma.tribeId == mb.tribeId)
end

-- von building/ genutzt: Stamm-ID eines Spielers (oder nil)
function TFP_GetTribeId(identifier)
    local m = membersByIdent[identifier]
    return m and m.tribeId or nil
end

local function tribeData(identifier)
    local m = membersByIdent[identifier]
    if not m then return nil end
    local t = tribes[m.tribeId]
    if not t then return nil end
    local list = {}
    for ident, rank in pairs(t.members) do
        local mi = membersByIdent[ident]
        list[#list + 1] = { identifier = ident, rank = rank, name = (mi and mi.name) or 'Unbekannt' }
    end
    return { id = t.id, name = t.name, owner = t.owner, myRank = m.rank, members = list }
end

lib.callback.register('clp_tfp:getMyTribe', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and tribeData(xPlayer.getIdentifier()) or nil
end)

RegisterNetEvent('clp_tfp:tribeCreate', function(name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    if membersByIdent[ident] then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du bist schon in einem Stamm.', type = 'error' }); return
    end
    name = (name or ''):sub(1, 48)
    if #name < 3 then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Name zu kurz.', type = 'error' }); return
    end
    local id = MySQL.insert.await('INSERT INTO tfp_tribes (name, owner) VALUES (?, ?)', { name, ident })
    tribes[id] = { id = id, name = name, owner = ident, members = { [ident] = 'leader' } }
    membersByIdent[ident] = { tribeId = id, rank = 'leader', name = GetPlayerName(src) }
    MySQL.insert('INSERT INTO tfp_tribe_members (tribe_id, identifier, rank, name) VALUES (?, ?, ?, ?)',
        { id, ident, 'leader', GetPlayerName(src) })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Stamm', description = 'Stamm "' .. name .. '" gegründet.', type = 'success' })
end)

RegisterNetEvent('clp_tfp:tribeInvite', function(targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local m = membersByIdent[xPlayer.getIdentifier()]
    if not m or (m.rank ~= 'leader' and m.rank ~= 'officer') then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Keine Berechtigung.', type = 'error' }); return
    end
    local t = tribes[m.tribeId]; if not t then return end
    local count = 0; for _ in pairs(t.members) do count = count + 1 end
    if count >= Config.Tribe.maxMembers then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Stamm ist voll.', type = 'error' }); return
    end
    local tx = ESX.GetPlayerFromId(targetId); if not tx then return end
    if membersByIdent[tx.getIdentifier()] then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Spieler ist schon in einem Stamm.', type = 'error' }); return
    end
    invites[tx.getIdentifier()] = m.tribeId
    TriggerClientEvent('clp_tfp:tribeInvited', targetId, t.name)
    TriggerClientEvent('ox_lib:notify', src, { description = 'Einladung gesendet.', type = 'success' })
end)

RegisterNetEvent('clp_tfp:tribeAccept', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    local tribeId = invites[ident]
    if not tribeId or not tribes[tribeId] then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Keine offene Einladung.', type = 'error' }); return
    end
    invites[ident] = nil
    tribes[tribeId].members[ident] = 'member'
    membersByIdent[ident] = { tribeId = tribeId, rank = 'member', name = GetPlayerName(src) }
    MySQL.insert('INSERT INTO tfp_tribe_members (tribe_id, identifier, rank, name) VALUES (?, ?, ?, ?)',
        { tribeId, ident, 'member', GetPlayerName(src) })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Stamm', description = 'Du bist "' .. tribes[tribeId].name .. '" beigetreten.', type = 'success' })
end)

RegisterNetEvent('clp_tfp:tribeLeave', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    local m = membersByIdent[ident]; if not m then return end
    local t = tribes[m.tribeId]
    membersByIdent[ident] = nil
    MySQL.update('DELETE FROM tfp_tribe_members WHERE identifier = ?', { ident })
    if t then
        t.members[ident] = nil
        if t.owner == ident then -- Anführer geht -> Stamm auflösen
            for mid in pairs(t.members) do
                membersByIdent[mid] = nil
                MySQL.update('DELETE FROM tfp_tribe_members WHERE identifier = ?', { mid })
            end
            tribes[t.id] = nil
            MySQL.update('DELETE FROM tfp_tribes WHERE id = ?', { t.id })
            TriggerClientEvent('ox_lib:notify', src, { description = 'Stamm aufgelöst.', type = 'inform' }); return
        end
    end
    TriggerClientEvent('ox_lib:notify', src, { description = 'Stamm verlassen.', type = 'inform' })
end)

-- ─── Rang-Verwaltung & Kick ──────────────────────────────────────────────────
local function srcByIdent(ident)
    for _, pid in ipairs(GetPlayers()) do
        local px = ESX.GetPlayerFromId(tonumber(pid))
        if px and px.getIdentifier() == ident then return tonumber(pid) end
    end
    return nil
end

local function setRank(tribeId, ident, rank)
    if tribes[tribeId] then tribes[tribeId].members[ident] = rank end
    if membersByIdent[ident] then membersByIdent[ident].rank = rank end
    MySQL.update('UPDATE tfp_tribe_members SET rank = ? WHERE identifier = ?', { rank, ident })
end

RegisterNetEvent('clp_tfp:tribePromote', function(targetIdent)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local m = membersByIdent[xPlayer.getIdentifier()]
    if not m or m.rank ~= 'leader' then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nur der Anführer kann befördern.', type = 'error' }); return
    end
    local t = tribes[m.tribeId]; if not t or t.members[targetIdent] ~= 'member' then return end
    setRank(m.tribeId, targetIdent, 'officer')
    TriggerClientEvent('ox_lib:notify', src, { description = 'Zum Offizier befördert.', type = 'success' })
    local ts = srcByIdent(targetIdent)
    if ts then TriggerClientEvent('ox_lib:notify', ts, { title = 'Stamm', description = 'Du bist jetzt Offizier.', type = 'inform' }) end
end)

RegisterNetEvent('clp_tfp:tribeDemote', function(targetIdent)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local m = membersByIdent[xPlayer.getIdentifier()]
    if not m or m.rank ~= 'leader' then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nur der Anführer kann herabstufen.', type = 'error' }); return
    end
    local t = tribes[m.tribeId]; if not t or t.members[targetIdent] ~= 'officer' then return end
    setRank(m.tribeId, targetIdent, 'member')
    TriggerClientEvent('ox_lib:notify', src, { description = 'Zum Mitglied herabgestuft.', type = 'success' })
    local ts = srcByIdent(targetIdent)
    if ts then TriggerClientEvent('ox_lib:notify', ts, { title = 'Stamm', description = 'Du bist jetzt einfaches Mitglied.', type = 'inform' }) end
end)

RegisterNetEvent('clp_tfp:tribeKick', function(targetIdent)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local meIdent = xPlayer.getIdentifier()
    local m = membersByIdent[meIdent]; if not m then return end
    local t = tribes[m.tribeId]; if not t then return end
    local targetRank = t.members[targetIdent]; if not targetRank then return end
    if targetIdent == meIdent or targetIdent == t.owner then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Das geht nicht.', type = 'error' }); return
    end
    local allowed = (m.rank == 'leader') or (m.rank == 'officer' and targetRank == 'member')
    if not allowed then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Keine Berechtigung.', type = 'error' }); return
    end
    t.members[targetIdent] = nil
    membersByIdent[targetIdent] = nil
    MySQL.update('DELETE FROM tfp_tribe_members WHERE identifier = ?', { targetIdent })
    TriggerClientEvent('ox_lib:notify', src, { description = 'Mitglied entfernt.', type = 'success' })
    local ts = srcByIdent(targetIdent)
    if ts then
        TriggerClientEvent('ox_lib:notify', ts, { title = 'Stamm', description = 'Du wurdest aus dem Stamm entfernt.', type = 'error' })
        TriggerClientEvent('clp_tfp:tribeKicked', ts)
    end
end)

-- ─── Geteilter Stamm-Stash (ox_inventory) ────────────────────────────────────
lib.callback.register('clp_tfp:getTribeStash', function(source)
    local xPlayer = ESX.GetPlayerFromId(source); if not xPlayer then return nil end
    local m = membersByIdent[xPlayer.getIdentifier()]; if not m then return nil end
    local t = tribes[m.tribeId]; if not t then return nil end
    local stashId = 'tfp_tribe_' .. t.id
    exports.ox_inventory:RegisterStash(stashId, ('Stamm: %s'):format(t.name),
        Config.Tribe.stashSlots or 50, Config.Tribe.stashWeight or 500000)
    return stashId
end)

-- Positionen der Stammmitglieder (für Karten-Blips)
lib.callback.register('clp_tfp:getTribePositions', function(source)
    local xPlayer = ESX.GetPlayerFromId(source); if not xPlayer then return {} end
    local me = xPlayer.getIdentifier()
    local m = membersByIdent[me]; if not m then return {} end
    local t = tribes[m.tribeId]; if not t then return {} end
    local res = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local px = ESX.GetPlayerFromId(pid)
        if px and px.getIdentifier() ~= me and t.members[px.getIdentifier()] then
            local c = GetEntityCoords(GetPlayerPed(pid))
            res[#res + 1] = { id = pid, name = membersByIdent[px.getIdentifier()].name, x = c.x, y = c.y, z = c.z }
        end
    end
    return res
end)
