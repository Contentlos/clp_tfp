-- clp_tfp · loot/ (Server) : zufälliger Loot aus Welt-Props (autoritativ)

local cooldown = {}

RegisterNetEvent('clp_tfp:loot', function(category)
    local src = source
    local t = Config.Loot.tables[category]
    if not t then return end

    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < (Config.Loot.cooldownPlayerMs or 800) then return end
    cooldown[src] = now

    if not TFP_RollGive(src, t.items) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nichts Brauchbares gefunden.', type = 'inform' })
    end
    if TFP_QuestProgress then TFP_QuestProgress(src, 'loot', 'any', 1) end
end)

AddEventHandler('playerDropped', function() cooldown[source] = nil end)
