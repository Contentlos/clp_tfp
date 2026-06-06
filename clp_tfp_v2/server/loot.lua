-- clp_tfp · server/loot — zufälliger Loot aus Welt-Props (autoritativ)
-- Loot 2.0:
--   • Container-Persistenz: jeder Fundort (gerundete Koordinaten) bekommt einen
--     geteilten Cooldown → einmal geplündert ist der Behälter für ALLE leer,
--     bis der Respawn abläuft (überlebt Relogs, resettet erst bei Server-Neustart).
--   • Risiko = Belohnung: in Gefahrenzonen (AI-Zonen/Camps) zusätzliche Chance
--     auf seltene High-Tier-Beute.

local cooldown    = {} -- [src]      = GameTimer (Anti-Spam pro Spieler)
local lootedSpots = {} -- [coordKey] = os.time()  (geteilter Re-Loot-Cooldown)

-- Fundort-Schlüssel: ~1.5 m horizontal, ~2 m vertikal → ein Behälter = ein Schlüssel
local function spotKey(category, c)
    return ('%s|%d:%d:%d'):format(category,
        math.floor(c.x / 1.5 + 0.5), math.floor(c.y / 1.5 + 0.5), math.floor(c.z / 2.0 + 0.5))
end

-- liegt der Fundort in einer Gefahrenzone? (AI-Zonen + Camps)
local function inDanger(c)
    local p = vector3(c.x, c.y, c.z)
    for _, z in ipairs((Config.AI and Config.AI.zones) or {}) do
        if z.center and #(p - z.center) <= (z.radius or 0.0) then return true end
    end
    for _, camp in ipairs((Config.Camps and Config.Camps.list) or {}) do
        if camp.center and #(p - camp.center) <= (camp.radius or 0.0) then return true end
    end
    return false
end

RegisterNetEvent('clp_tfp:loot', function(category, coords)
    local src = source
    local t = Config.Loot.tables[category]
    if not t then return end

    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < (Config.Loot.cooldownPlayerMs or 800) then return end
    cooldown[src] = now

    -- Server-Plausibilität: Koordinaten in Reichweite des Spielers?
    local hasSpot = false
    if coords and coords.x then
        local pc = GetEntityCoords(GetPlayerPed(src))
        if pc and #(vector3(coords.x, coords.y, coords.z) - pc) <= 6.0 then
            hasSpot = true
        end
    end

    -- Container-Persistenz: schon geplündert? → leer bis Respawn
    if hasSpot then
        local key     = spotKey(category, coords)
        local respawn = (t.respawnMs or Config.Loot.respawnMs or 3600000) / 1000
        local last    = lootedSpots[key]
        if last and (os.time() - last) < respawn then
            local mins = math.ceil((respawn - (os.time() - last)) / 60)
            TriggerClientEvent('ox_lib:notify', src, {
                description = ('Schon durchsucht — leer für ~%d Min.'):format(mins), type = 'inform' })
            return
        end
        lootedSpots[key] = os.time()
    end

    local got = TFP_RollGive(src, t.items)

    -- Risiko = Belohnung: Bonus-Roll auf seltene Beute in Gefahrenzonen
    local db = Config.Loot.dangerBonus
    if hasSpot and db and inDanger(coords) and math.random(100) <= (db.chance or 0) then
        if TFP_RollGive(src, db.items) then
            got = true
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Wertvoller Fund', description = 'Etwas Brauchbares in der Gefahrenzone!',
                type = 'success', icon = 'box-open' })
        end
    end

    if not got then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nichts Brauchbares gefunden.', type = 'inform' })
    end
    if TFP_QuestProgress then TFP_QuestProgress(src, 'loot', 'any', 1) end
end)

-- Speicher-Hygiene: abgelaufene Fundorte aufräumen (alle 30 Min)
CreateThread(function()
    while true do
        Wait(1800000)
        local maxRespawn = (Config.Loot.respawnMs or 3600000) / 1000
        for _, t in pairs(Config.Loot.tables) do
            if t.respawnMs and t.respawnMs / 1000 > maxRespawn then maxRespawn = t.respawnMs / 1000 end
        end
        local now = os.time()
        for key, ts in pairs(lootedSpots) do
            if now - ts > maxRespawn then lootedSpots[key] = nil end
        end
    end
end)

AddEventHandler('playerDropped', function() cooldown[source] = nil end)
