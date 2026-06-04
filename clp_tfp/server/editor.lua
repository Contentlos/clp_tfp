-- clp_tfp · editor/ (Server) — In-Game Punkt-Editor: speichert Koords (DB tfp_points)
-- und überschreibt damit die Config-Platzhalter (Spawns, Zonen, Camps, Airdrops, Escape).

local ESX = exports['es_extended']:getSharedObject()
local isAdmin = TFP_IsAdmin

local function loadPoints()
    local rows = MySQL.query.await('SELECT category, ord, x, y, z, w FROM tfp_points ORDER BY category, ord') or {}
    local p = {}
    for _, r in ipairs(rows) do
        p[r.category] = p[r.category] or {}
        p[r.category][#p[r.category] + 1] = { x = r.x, y = r.y, z = r.z, w = r.w }
    end
    return p
end

local function applyToConfig(p)
    local function v3(t) return vector3(t.x, t.y, t.z) end
    if p.island_center then Config.World.islandCenter = v3(p.island_center[1]) end
    if p.safezone and Config.World.safezone then Config.World.safezone.center = v3(p.safezone[1]) end
    if p.radiation and Config.Radiation then
        Config.Radiation.zone.center = v3(p.radiation[1])
        if Config.Escape.steps[4] then Config.Escape.steps[4].escape = v3(p.radiation[1]) end
    end
    if p.camp1 and Config.Camps.list[1] then Config.Camps.list[1].center = v3(p.camp1[1]) end
    if p.camp2 and Config.Camps.list[2] then Config.Camps.list[2].center = v3(p.camp2[1]) end
    if p.aizone1 and Config.AI.zones[1] then Config.AI.zones[1].center = v3(p.aizone1[1]) end
    for i = 1, 4 do
        if p['escape' .. i] and Config.Escape.steps[i] then Config.Escape.steps[i].coords = v3(p['escape' .. i][1]) end
    end
    if p.spawn then
        local t = {}
        for _, pt in ipairs(p.spawn) do t[#t + 1] = vector4(pt.x, pt.y, pt.z, pt.w) end
        if #t > 0 then Config.Spawn.points = t end
    end
    if p.airdrop then
        local t = {}
        for _, pt in ipairs(p.airdrop) do t[#t + 1] = vector3(pt.x, pt.y, pt.z) end
        if #t > 0 then Config.Airdrop.points = t end
    end
    if p.wreck and Config.WreckEvent then
        local t = {}
        for _, pt in ipairs(p.wreck) do t[#t + 1] = { coords = vector3(pt.x, pt.y, pt.z), prop = 'prop_wreck_truck_01' } end
        if #t > 0 then Config.WreckEvent.points = t end
    end
    if p.dive and Config.Wrecks then
        local t = {}
        for _, pt in ipairs(p.dive) do t[#t + 1] = vector3(pt.x, pt.y, pt.z) end
        if #t > 0 then Config.Wrecks.spots = t end
    end
end

local function applyAll()
    local p = loadPoints()
    applyToConfig(p)
    TriggerClientEvent('clp_tfp:applyPoints', -1, p)
end

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tfp_points` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `category` VARCHAR(32) NOT NULL,
            `ord` INT NOT NULL DEFAULT 0,
            `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL, `w` FLOAT NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    Wait(800)
    applyToConfig(loadPoints())
end)

RegisterNetEvent('clp_tfp:editorSet', function(category, x, y, z, w, isList)
    local src = source
    if not isAdmin(src) then return end
    if not isList then MySQL.query.await('DELETE FROM tfp_points WHERE category = ?', { category }) end
    local ord = isList and (MySQL.scalar.await('SELECT COUNT(*) FROM tfp_points WHERE category = ?', { category }) or 0) or 0
    MySQL.insert.await('INSERT INTO tfp_points (category, ord, x, y, z, w) VALUES (?, ?, ?, ?, ?, ?)',
        { category, ord, x + 0.0, y + 0.0, z + 0.0, (w or 0) + 0.0 })
    applyAll()
    TriggerClientEvent('ox_lib:notify', src, { title = 'Editor', description = category .. ' gespeichert.', type = 'success' })
end)

RegisterNetEvent('clp_tfp:editorClear', function(category)
    local src = source
    if not isAdmin(src) then return end
    MySQL.query.await('DELETE FROM tfp_points WHERE category = ?', { category })
    applyAll()
    TriggerClientEvent('ox_lib:notify', src, { title = 'Editor', description = category .. ' geleert.', type = 'inform' })
end)

RegisterNetEvent('clp_tfp:editorRequest', function()
    TriggerClientEvent('clp_tfp:applyPoints', source, loadPoints())
end)
