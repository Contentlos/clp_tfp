-- clp_tfp · client/editor — Punkt-Editor-Menü (im Admin-Panel) + Live-Patch der Config

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

-- Gespeicherte Punkte live in die Client-Config übernehmen (Loops lesen Config laufend)
RegisterNetEvent('clp_tfp:applyPoints', function(p)
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
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    TriggerServerEvent('clp_tfp:editorRequest')
end)

local function here(withHeading)
    local c = GetEntityCoords(PlayerPedId())
    return c.x, c.y, c.z, (withHeading and GetEntityHeading(PlayerPedId()) or 0.0)
end

function TFP.OpenEditor()
    local o = {}
    local function single(title, cat)
        o[#o + 1] = { title = title, icon = 'fa-solid fa-location-crosshairs',
            onSelect = function() local x, y, z = here(false); TriggerServerEvent('clp_tfp:editorSet', cat, x, y, z, 0.0, false) end }
    end
    single('Safezone hier setzen', 'safezone')
    single('Festland / Strahlung hier setzen', 'radiation')
    single('Insel-Zentrum hier setzen', 'island_center')
    single('Dschungel-Zone hier setzen', 'aizone1')
    single('Camp 1 hier setzen', 'camp1')
    single('Camp 2 hier setzen', 'camp2')
    single('Escape 1 – Funkturm hier', 'escape1')
    single('Escape 2 – Treibstoff hier', 'escape2')
    single('Escape 3 – Boot hier', 'escape3')
    single('Escape 4 – Strand/Ablegen hier', 'escape4')
    o[#o + 1] = { title = 'Spawnpunkt hinzufügen (hier)', icon = 'fa-solid fa-plus',
        onSelect = function() local x, y, z, w = here(true); TriggerServerEvent('clp_tfp:editorSet', 'spawn', x, y, z, w, true) end }
    o[#o + 1] = { title = 'Spawnpunkte löschen', icon = 'fa-solid fa-trash',
        onSelect = function() TriggerServerEvent('clp_tfp:editorClear', 'spawn') end }
    o[#o + 1] = { title = 'Airdrop-Punkt hinzufügen (hier)', icon = 'fa-solid fa-plus',
        onSelect = function() local x, y, z = here(false); TriggerServerEvent('clp_tfp:editorSet', 'airdrop', x, y, z, 0.0, true) end }
    o[#o + 1] = { title = 'Airdrop-Punkte löschen', icon = 'fa-solid fa-trash',
        onSelect = function() TriggerServerEvent('clp_tfp:editorClear', 'airdrop') end }
    o[#o + 1] = { title = 'Wrack-Event-Punkt hinzufügen (hier)', icon = 'fa-solid fa-plus',
        onSelect = function() local x, y, z = here(false); TriggerServerEvent('clp_tfp:editorSet', 'wreck', x, y, z, 0.0, true) end }
    o[#o + 1] = { title = 'Wrack-Event-Punkte löschen', icon = 'fa-solid fa-trash',
        onSelect = function() TriggerServerEvent('clp_tfp:editorClear', 'wreck') end }
    o[#o + 1] = { title = 'Tauch-Spot hinzufügen (hier)', icon = 'fa-solid fa-plus',
        onSelect = function() local x, y, z = here(false); TriggerServerEvent('clp_tfp:editorSet', 'dive', x, y, z, 0.0, true) end }
    o[#o + 1] = { title = 'Tauch-Spots löschen', icon = 'fa-solid fa-trash',
        onSelect = function() TriggerServerEvent('clp_tfp:editorClear', 'dive') end }
    o[#o + 1] = { title = '📋 /tfppos kopiert vec3 (für Notiz-/Config-Koords)', disabled = true }
    o[#o + 1] = { title = 'ℹ️ Blips/Zonen erst nach „/restart clp_tfp" aktualisiert', disabled = true }
    lib.registerContext({ id = 'tfp_editor', title = '📍 Punkt-Editor', menu = 'tfp_admin', options = o })
    lib.showContext('tfp_editor')
end
