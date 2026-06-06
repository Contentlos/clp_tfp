-- clp_tfp · server/radiation — Loot aus der verstrahlten Zone (autoritativ)

local cooldown = {}

RegisterNetEvent('clp_tfp:radLoot', function()
    local src = source
    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < 800 then return end
    cooldown[src] = now

    if not TFP_RollGive(src, Config.Radiation.loot) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Nichts Brauchbares gefunden.', type = 'inform' })
    end
    if TFP_QuestProgress then TFP_QuestProgress(src, 'loot', 'radiation', 1) end
end)

AddEventHandler('playerDropped', function() cooldown[source] = nil end)
