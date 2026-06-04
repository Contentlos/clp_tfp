-- clp_tfp · camps/ (Server) — Loot aus Lager-/Compound-Kisten (autoritativ)

local cooldown = {}

RegisterNetEvent('clp_tfp:campLoot', function(lootKey)
    local src = source
    local t = Config.Camps.loot[lootKey]
    if not t then return end

    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < 800 then return end
    cooldown[src] = now

    if not TFP_RollGive(src, t) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nichts Brauchbares gefunden.', type = 'inform' })
    end
end)

AddEventHandler('playerDropped', function() cooldown[source] = nil end)
