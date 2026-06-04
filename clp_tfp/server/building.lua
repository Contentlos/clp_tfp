-- clp_tfp · building/ (Server) — Phase 2 "Sesshaft" komplett
-- Persistenz, Eigentum/Stamm, Limit pro Stamm, Versorgungs-Kern (Territorium +
-- Decay-Schutz), öffenbare stamm-gesicherte Türen, Bett setzt Respawn, Lager-Stash.

local ESX = exports['es_extended']:getSharedObject()

-- Admin-Bau-Modus: gratis, kein Limit, überall (pro Spieler, nur Admins)
local adminBuild = {}
RegisterNetEvent('clp_tfp:setAdminBuild', function(state)
    local src = source
    if not TFP_IsAdmin(src) then return end
    adminBuild[src] = state and true or nil
    TriggerClientEvent('ox_lib:notify', src, { title = 'Admin-Bau',
        description = state and 'AN — gratis, ohne Limit, überall.' or 'AUS.', type = 'inform' })
end)
AddEventHandler('playerDropped', function() adminBuild[source] = nil end)

local function tribeOf(ident) return (TFP_GetTribeId and TFP_GetTribeId(ident)) or nil end
local function allowed(me, ownerIdent)
    return me == ownerIdent or (TFP_AreSameTribe and TFP_AreSameTribe(me, ownerIdent)) or false
end

local function payload(r)
    return { id = r.id, build = r.build, model = r.model, x = r.x, y = r.y, z = r.z,
             heading = r.heading, cat = r.category, doorOpen = (r.door_open == 1),
             tier = r.tier or 'wood', hp = r.hp, maxhp = r.max_hp, locked = (r.code ~= nil and r.code ~= '') }
end

local function registerStash(id, entry)
    -- shared registriert; Zugriff via clp_tfp:canAccessBuild (Owner ODER Stamm)
    exports.ox_inventory:RegisterStash('tfp_build_' .. id, entry.label or 'Lager', entry.slots or 10, entry.weight or 50000, false)
end

local function setSpawn(ident, x, y, z, h)
    MySQL.update('UPDATE tfp_player SET spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_h = ? WHERE identifier = ?',
        { x, y, z, h or 0.0, ident })
end

-- ─── Tabelle + Migration + Laden ─────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `tfp_builds` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `tribe_id` INT NULL,
            `build` VARCHAR(48) NOT NULL,
            `model` VARCHAR(64) NOT NULL,
            `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
            `heading` FLOAT NOT NULL DEFAULT 0,
            `category` VARCHAR(24) NOT NULL DEFAULT 'structure',
            `door_open` TINYINT NOT NULL DEFAULT 0,
            `decay_at` INT NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- Migration ohne langsame information_schema-Abfragen (MariaDB: ADD COLUMN IF NOT EXISTS)
    MySQL.query.await([[
        ALTER TABLE `tfp_builds`
            ADD COLUMN IF NOT EXISTS `tribe_id` INT NULL,
            ADD COLUMN IF NOT EXISTS `door_open` TINYINT NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `tier` VARCHAR(8) NOT NULL DEFAULT 'wood',
            ADD COLUMN IF NOT EXISTS `hp` INT NOT NULL DEFAULT 350,
            ADD COLUMN IF NOT EXISTS `max_hp` INT NOT NULL DEFAULT 350,
            ADD COLUMN IF NOT EXISTS `code` VARCHAR(8) NULL
    ]])
    local rows = MySQL.query.await('SELECT * FROM tfp_builds') or {}
    for _, r in ipairs(rows) do
        local entry = Config.Building.catalog[r.build]
        if entry and r.category == 'storage' then registerStash(r.id, entry) end
        TriggerClientEvent('clp_tfp:spawnBuild', -1, payload(r))
    end
    if TFP_Build then TFP_Build(('%d Bauten geladen.'):format(#rows)) end
end)

RegisterNetEvent('clp_tfp:requestBuilds', function()
    local src = source
    local list = {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM tfp_builds') or {}) do
        list[#list + 1] = payload(r)
    end
    TriggerClientEvent('clp_tfp:syncBuilds', src, list)
end)

-- ─── Hilfen: Zonen / Territorium ─────────────────────────────────────────────
local function inNoBuildZone(coords)
    local sz = Config.World and Config.World.safezone
    return sz and sz.center and #(vector3(coords.x, coords.y, coords.z) - sz.center) < (Config.Building.noBuildRadius or 50.0)
end

local function foreignCupboardConflict(coords, me)
    local rows = MySQL.query.await("SELECT identifier FROM tfp_builds WHERE category = 'cupboard' AND ABS(x-?) < ? AND ABS(y-?) < ?",
        { coords.x, Config.Building.cupboardRadius, coords.y, Config.Building.cupboardRadius }) or {}
    for _, c in ipairs(rows) do
        if not allowed(me, c.identifier) then return true end
    end
    return false
end

-- ─── Platzieren ──────────────────────────────────────────────────────────────
RegisterNetEvent('clp_tfp:placeBuild', function(buildId, coords, heading)
    local src = source
    local entry = Config.Building.catalog[buildId]
    if not entry then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local me = xPlayer.getIdentifier()
    local tid = tribeOf(me)
    local free = (adminBuild[src] and TFP_IsAdmin(src)) or false  -- Admin-Bau-Modus: alles ignorieren

    if not free then
        if inNoBuildZone(coords) then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Hier darf nicht gebaut werden.', type = 'error' }); return
        end
        if foreignCupboardConflict(coords, me) then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Fremdes Territorium — hier darfst du nicht bauen.', type = 'error' }); return
        end

        local count, limit
        if tid then
            count = MySQL.scalar.await('SELECT COUNT(*) FROM tfp_builds WHERE tribe_id = ?', { tid })
            limit = Config.Building.limitPerTribe
        else
            count = MySQL.scalar.await('SELECT COUNT(*) FROM tfp_builds WHERE identifier = ? AND tribe_id IS NULL', { me })
            limit = Config.Building.limitPerPlayer
        end
        if (count or 0) >= limit then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Bau-Limit erreicht (' .. limit .. ').', type = 'error' }); return
        end

        for _, c in ipairs(entry.cost) do
            if (exports.ox_inventory:GetItem(src, c.item, nil, true) or 0) < c.count then
                TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlen Materialien.', type = 'error' }); return
            end
        end
        for _, c in ipairs(entry.cost) do exports.ox_inventory:RemoveItem(src, c.item, c.count) end
    end

    local decayAt = os.time() + ((entry.cat == 'cupboard')
        and ((Config.Building.upkeep and Config.Building.upkeep.startSeconds) or 86400)
        or (Config.Building.decaySeconds or 604800))
    local tier = entry.tier or 'wood'
    local thp = ((Config.Building.tiers or {})[tier] or {}).hp or 350
    local id = MySQL.insert.await(
        'INSERT INTO tfp_builds (identifier, tribe_id, build, model, x, y, z, heading, category, door_open, decay_at, tier, hp, max_hp) VALUES (?,?,?,?,?,?,?,?,?,0,?,?,?,?)',
        { me, tid, buildId, entry.model, coords.x, coords.y, coords.z, heading or 0.0, entry.cat, decayAt, tier, thp, thp })
    if not id then return end

    if entry.cat == 'storage' then registerStash(id, entry) end
    if entry.cat == 'bed' then
        setSpawn(me, coords.x, coords.y, coords.z, heading)
        TriggerClientEvent('clp_tfp:setHome', src, { x = coords.x, y = coords.y, z = coords.z })
    end

    TriggerClientEvent('clp_tfp:spawnBuild', -1, {
        id = id, build = buildId, model = entry.model, x = coords.x, y = coords.y, z = coords.z,
        heading = heading or 0.0, cat = entry.cat, doorOpen = false,
        tier = tier, hp = thp, maxhp = thp, locked = false,
    })
    if TFP_QuestProgress then TFP_QuestProgress(src, 'build', 'any', 1) end
end)

-- ─── Tür öffnen/schließen (synchron, stamm-gesichert) ────────────────────────
RegisterNetEvent('clp_tfp:toggleDoor', function(id, code)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await('SELECT identifier, door_open, code FROM tfp_builds WHERE id = ?', { id })
    if not row then return end
    if not allowed(xPlayer.getIdentifier(), row.identifier) then
        if row.code and row.code ~= '' then
            if code == nil then
                TriggerClientEvent('clp_tfp:doorNeedsCode', src, id); return
            elseif tostring(code) ~= row.code then
                TriggerClientEvent('ox_lib:notify', src, { description = 'Falscher Code.', type = 'error' }); return
            end
        else
            TriggerClientEvent('ox_lib:notify', src, { description = 'Verschlossen — gehört dir/deinem Stamm nicht.', type = 'error' }); return
        end
    end
    local newState = (row.door_open == 1) and 0 or 1
    MySQL.update('UPDATE tfp_builds SET door_open = ? WHERE id = ?', { newState, id })
    TriggerClientEvent('clp_tfp:setDoorState', -1, id, newState == 1)
end)

-- Codeschloss setzen/ändern (Owner/Stamm); leerer Code entfernt das Schloss
RegisterNetEvent('clp_tfp:setBuildCode', function(id, code)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await('SELECT identifier FROM tfp_builds WHERE id = ?', { id })
    if not row or not allowed(xPlayer.getIdentifier(), row.identifier) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Gehört dir/deinem Stamm nicht.', type = 'error' }); return
    end
    code = code and tostring(code):gsub('%s', ''):sub(1, 8) or ''
    MySQL.update('UPDATE tfp_builds SET code = ? WHERE id = ?', { code ~= '' and code or nil, id })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Codeschloss',
        description = code ~= '' and ('Code gesetzt: %s'):format(code) or 'Codeschloss entfernt.', type = 'success' })
end)

-- ─── Raid: Bau beschädigen/zerstören (server-autoritativ) ────────────────────
local raidCd = {}
RegisterNetEvent('clp_tfp:damageBuild', function(id, dmg)
    local src = source
    local raid = Config.Building.raid
    if not raid or not raid.enabled then return end
    local now = GetGameTimer()
    if raidCd[src] and now - raidCd[src] < (raid.reportCooldownMs or 150) then return end
    raidCd[src] = now
    dmg = math.floor(tonumber(dmg) or 0)
    if dmg <= 0 then return end
    if dmg > (raid.maxHitDamage or 350) then dmg = raid.maxHitDamage or 350 end
    local row = MySQL.single.await('SELECT x, y, z, hp FROM tfp_builds WHERE id = ?', { id })
    if not row then return end
    local bc = vector3(row.x, row.y, row.z)
    if #(GetEntityCoords(GetPlayerPed(src)) - bc) > 12.0 then return end -- Anti-Cheat: Nähe
    if raid.noRaidInSafezone then
        local sz = Config.World and Config.World.safezone
        if sz and sz.center and #(bc - sz.center) < (sz.radius or 0) then
            TriggerClientEvent('ox_lib:notify', src, { description = 'In der sicheren Zone kann nicht geraidet werden.', type = 'error' }); return
        end
    end
    local newHp = (row.hp or 350) - dmg
    if newHp <= 0 then
        MySQL.update('DELETE FROM tfp_builds WHERE id = ?', { id })
        TriggerClientEvent('clp_tfp:despawnBuild', -1, id)
        TriggerClientEvent('clp_tfp:buildDestroyed', -1, id, row.x, row.y, row.z)
    else
        MySQL.update('UPDATE tfp_builds SET hp = ? WHERE id = ?', { newHp, id })
    end
end)

-- ─── Verstärken (Holz→Stein→Metall) ──────────────────────────────────────────
RegisterNetEvent('clp_tfp:upgradeBuild', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await('SELECT identifier, tier FROM tfp_builds WHERE id = ?', { id })
    if not row then return end
    if not allowed(xPlayer.getIdentifier(), row.identifier) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Gehört dir/deinem Stamm nicht.', type = 'error' }); return
    end
    local path = (Config.Building.upgradePath or {})[row.tier or 'wood']
    if not path then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Höchste Stufe bereits erreicht.', type = 'inform' }); return
    end
    for _, c in ipairs(path.cost) do
        if (exports.ox_inventory:GetItem(src, c.item, nil, true) or 0) < c.count then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlen Materialien zum Verstärken.', type = 'error' }); return
        end
    end
    for _, c in ipairs(path.cost) do exports.ox_inventory:RemoveItem(src, c.item, c.count) end
    local newTier = path.to
    local hp = ((Config.Building.tiers or {})[newTier] or {}).hp or 1000
    MySQL.update('UPDATE tfp_builds SET tier = ?, hp = ?, max_hp = ? WHERE id = ?', { newTier, hp, hp, id })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Bau verstärkt',
        description = ('Jetzt %s — %d HP.'):format(((Config.Building.tiers or {})[newTier] or {}).label or newTier, hp), type = 'success' })
end)

AddEventHandler('playerDropped', function() raidCd[source] = nil end)

-- ─── Bett als Respawn setzen ─────────────────────────────────────────────────
RegisterNetEvent('clp_tfp:setBedSpawn', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await("SELECT identifier, x, y, z, heading FROM tfp_builds WHERE id = ? AND category = 'bed'", { id })
    if not row then return end
    if not allowed(xPlayer.getIdentifier(), row.identifier) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Das ist nicht dein Schlafplatz.', type = 'error' }); return
    end
    setSpawn(xPlayer.getIdentifier(), row.x, row.y, row.z, row.heading)
    TriggerClientEvent('clp_tfp:setHome', src, { x = row.x, y = row.y, z = row.z })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Schlafplatz', description = 'Respawn-Punkt gesetzt.', type = 'success' })
end)

-- ─── Lager-Zugriff (Owner ODER Stamm) ────────────────────────────────────────
lib.callback.register('clp_tfp:canAccessBuild', function(source, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    local row = MySQL.single.await('SELECT identifier FROM tfp_builds WHERE id = ?', { id })
    if not row then return false end
    return allowed(xPlayer.getIdentifier(), row.identifier)
end)

-- ─── Abreißen / Auffrischen (Owner ODER Stamm) ───────────────────────────────
RegisterNetEvent('clp_tfp:removeBuild', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await('SELECT identifier FROM tfp_builds WHERE id = ?', { id })
    if not row then return end
    if not allowed(xPlayer.getIdentifier(), row.identifier) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Das gehört dir/deinem Stamm nicht.', type = 'error' }); return
    end
    MySQL.update('DELETE FROM tfp_builds WHERE id = ?', { id })
    TriggerClientEvent('clp_tfp:despawnBuild', -1, id)
end)

RegisterNetEvent('clp_tfp:refreshBuild', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local row = MySQL.single.await('SELECT identifier FROM tfp_builds WHERE id = ?', { id })
    if not row or not allowed(xPlayer.getIdentifier(), row.identifier) then return end
    MySQL.update('UPDATE tfp_builds SET decay_at = ? WHERE id = ?', { os.time() + (Config.Building.decaySeconds or 604800), id })
    TriggerClientEvent('ox_lib:notify', src, { description = 'Bau aufgefrischt.', type = 'success' })
end)

-- Material in den Versorgungs-Kern einlagern -> verlängert dessen Vorrat (decay_at)
RegisterNetEvent('clp_tfp:cupboardUpkeep', function(id, item, count)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local up = Config.Building.upkeep or {}
    local okItem = false
    for _, it in ipairs(up.items or {}) do if it == item then okItem = true; break end end
    if not okItem then return end
    count = math.max(1, math.floor(count or 1))
    local row = MySQL.single.await("SELECT identifier, decay_at FROM tfp_builds WHERE id = ? AND category = 'cupboard'", { id })
    if not row then return end
    if not allowed(xPlayer.getIdentifier(), row.identifier) then return end
    local have = exports.ox_inventory:GetItem(src, item, nil, true) or 0
    if have < count then count = have end
    if count < 1 then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Kein Material zum Einlagern.', type = 'error' }); return
    end
    exports.ox_inventory:RemoveItem(src, item, count)
    local now = os.time()
    local base = math.max(row.decay_at, now)
    local newAt = math.min(base + count * (up.secondsPerItem or 3600), now + (up.maxSeconds or 604800))
    MySQL.update('UPDATE tfp_builds SET decay_at = ? WHERE id = ?', { newAt, id })
    TriggerClientEvent('ox_lib:notify', src, { title = 'Versorgungs-Kern', description = ('Vorrat: ~%dh'):format(math.floor((newAt - now) / 3600)), type = 'success' })
end)

-- ─── Verfall: aktiver Kern (Vorrat > 0) schützt Umkreis; Rest + leere Kerne verfallen ───
CreateThread(function()
    while true do
        Wait(600000) -- alle 10 Minuten
        local now = os.time()
        local r = Config.Building.cupboardRadius or 40.0
        local cupboards = MySQL.query.await("SELECT identifier, tribe_id, x, y, z, decay_at FROM tfp_builds WHERE category = 'cupboard'") or {}
        local others = MySQL.query.await("SELECT id, identifier, tribe_id, x, y, z FROM tfp_builds WHERE category != 'cupboard'") or {}
        for _, b in ipairs(others) do
            local protected = false
            for _, c in ipairs(cupboards) do
                if c.decay_at > now and #(vector3(b.x, b.y, b.z) - vector3(c.x, c.y, c.z)) < r then
                    if b.identifier == c.identifier or (b.tribe_id and c.tribe_id and b.tribe_id == c.tribe_id) then
                        protected = true; break
                    end
                end
            end
            if protected then
                MySQL.update('UPDATE tfp_builds SET decay_at = ? WHERE id = ?', { now + (Config.Building.decaySeconds or 604800), b.id })
            end
        end
        for _, r2 in ipairs(MySQL.query.await('SELECT id FROM tfp_builds WHERE decay_at < ?', { now }) or {}) do
            MySQL.update('DELETE FROM tfp_builds WHERE id = ?', { r2.id })
            TriggerClientEvent('clp_tfp:despawnBuild', -1, r2.id)
        end
    end
end)
