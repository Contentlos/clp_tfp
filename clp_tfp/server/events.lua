-- clp_tfp · events/ (Server) : dynamisches Wrack-Event (Timer) + Wrack-Loot (first come)

local current = nil  -- { id, coords, prop, looted }
local wreckId = 0

local function spawnWreck()
    if not Config.WreckEvent.enabled then return end
    local pick = Config.WreckEvent.points[math.random(#Config.WreckEvent.points)]
    wreckId = wreckId + 1
    current = { id = wreckId, coords = pick.coords, prop = pick.prop, looted = false }
    TriggerClientEvent('clp_tfp:wreckSpawn', -1, current.id, pick.coords, pick.prop)
    if TFP_Loot then TFP_Loot(('Wrack gesichtet #%d @ %.0f, %.0f — die See gibt etwas frei.'):format(wreckId, pick.coords.x, pick.coords.y)) end
    local thisId = wreckId
    SetTimeout(Config.WreckEvent.despawnMs or 900000, function()
        if current and current.id == thisId then
            TriggerClientEvent('clp_tfp:wreckDespawn', -1, thisId)
            current = nil
        end
    end)
end

CreateThread(function()
    Wait(Config.WreckEvent.firstDelayMs or 120000)  -- erstes Wrack bald nach Start
    spawnWreck()
    while true do
        Wait(Config.WreckEvent.intervalMs or 1200000)
        spawnWreck()
    end
end)

RegisterNetEvent('clp_tfp:requestWreck', function()
    if current and not current.looted then
        TriggerClientEvent('clp_tfp:wreckSpawn', source, current.id, current.coords, current.prop)
    end
end)

RegisterNetEvent('clp_tfp:wreckLoot', function(id)
    local src = source
    if not current or current.id ~= id or current.looted then return end
    local pc = GetEntityCoords(GetPlayerPed(src))
    if #(pc - current.coords) > 8.0 then return end  -- grober Anti-Cheat
    current.looted = true
    local t = Config.Loot.tables[Config.WreckEvent.loot]
    if t then TFP_RollGive(src, t.items) end
    TriggerClientEvent('clp_tfp:wreckDespawn', -1, id)
    current = nil
end)

-- Admin/Debug
RegisterNetEvent('clp_tfp:adminWreck', function()
    if TFP_IsAdmin(source) then spawnWreck() end
end)

RegisterCommand('tfpwreck', function(src)
    if src == 0 or IsPlayerAceAllowed(src, 'tfp.admin') then spawnWreck() end
end, true)
