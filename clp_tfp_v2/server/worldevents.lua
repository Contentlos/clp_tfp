-- clp_tfp · server/worldevents — dynamische, angekündigte Ereignisse
-- Ein Event gleichzeitig: Scheduler wählt gewichtet, broadcastet an alle Clients,
-- validiert Kisten-Loot (first come, Nähe), Hinterhalt-Spawn, Despawn per Timer.

local ESX = exports['es_extended']:getSharedObject()
local WE = Config.WorldEvents or { enabled = false }
local active = nil   -- { id, key, coords, crates = { [i]=looted } }
local nextId = 0

local function pickEvent()
    local total = 0
    for _, e in ipairs(WE.events) do total = total + (e.weight or 1) end
    local r = math.random() * total
    for _, e in ipairs(WE.events) do r = r - (e.weight or 1); if r <= 0 then return e end end
    return WE.events[1]
end

local function defOf(key) for _, e in ipairs(WE.events) do if e.key == key then return e end end end

local function lootList(key)
    if Config.Loot.tables[key] then return Config.Loot.tables[key].items end
    if Config.Camps and Config.Camps.loot and Config.Camps.loot[key] then return Config.Camps.loot[key] end
    return nil
end

local function endEvent()
    if not active then return end
    TriggerClientEvent('clp_tfp:worldEventEnd', -1, active.id)
    active = nil
end

local function startEvent()
    if active or not WE.enabled or #(WE.events or {}) == 0 then return end
    local e = pickEvent()
    local pt = e.points[math.random(#e.points)]
    nextId = nextId + 1
    local crates = {}
    for i = 1, #(e.crates or {}) do crates[i] = false end
    active = { id = nextId, key = e.key, coords = pt, crates = crates }
    TriggerClientEvent('clp_tfp:worldEventStart', -1, nextId, e.key, pt)
    if e.announce and WE.announceAll then
        TriggerClientEvent('ox_lib:notify', -1, { title = '◢ ' .. (e.label or 'Ereignis'), description = e.announce, type = 'inform', duration = 9000 })
    end
    local thisId = nextId
    SetTimeout(WE.despawnMs or 420000, function() if active and active.id == thisId then endEvent() end end)
end

CreateThread(function()
    if not WE.enabled then return end
    Wait(WE.firstDelayMs or 240000)
    while true do
        if not active then startEvent() end
        Wait((WE.intervalMs or 540000) + math.random(0, WE.jitterMs or 0))
    end
end)

RegisterNetEvent('clp_tfp:requestWorldEvent', function()
    if active then TriggerClientEvent('clp_tfp:worldEventStart', source, active.id, active.key, active.coords, active.crates) end
end)

RegisterNetEvent('clp_tfp:worldEventLoot', function(id, idx)
    local src = source
    if not active or active.id ~= id then return end
    idx = tonumber(idx)
    if not idx or active.crates[idx] == nil or active.crates[idx] then return end
    local pc = GetEntityCoords(GetPlayerPed(src))
    if not pc or #(pc - active.coords) > 60.0 then return end

    local edef = defOf(active.key)
    local crateDef = edef and edef.crates and edef.crates[idx]
    local list = crateDef and lootList(crateDef.loot)
    if list and TFP_RollGive then TFP_RollGive(src, list) end
    active.crates[idx] = true
    TriggerClientEvent('clp_tfp:worldEventCrateLooted', -1, id, idx)

    -- Hinterhalt: Kannibalen beim Plündern
    if edef and edef.ambush and math.random(100) <= (edef.ambush.chance or 0) then
        TriggerClientEvent('clp_tfp:spawnWave', src)
    end

    local allLooted, n = true, 0
    for _, v in pairs(active.crates) do n = n + 1; if not v then allLooted = false end end
    if allLooted and n > 0 then endEvent() end
end)

-- späte Joiner / Resource-Restart: aktives Event nachliefern
AddEventHandler('esx:playerLoaded', function(pid)
    if active then TriggerClientEvent('clp_tfp:worldEventStart', pid, active.id, active.key, active.coords, active.crates) end
end)

-- Admin/Debug: Event sofort auslösen
RegisterCommand('tfpevent', function(src)
    if src == 0 or (TFP_IsAdmin and TFP_IsAdmin(src)) then endEvent(); startEvent() end
end, true)
