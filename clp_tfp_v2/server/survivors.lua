-- clp_tfp · server/survivors — Belohnung fürs Retten (autoritativ, Anti-Spam)

local cd = {} -- [src] = GameTimer

RegisterNetEvent('clp_tfp:survivorRescued', function()
    local src = source
    if not (Config.Survivors and Config.Survivors.enabled) then return end
    local now = GetGameTimer()
    if cd[src] and now - cd[src] < 30000 then return end -- max alle 30 s (Anti-Spam)
    cd[src] = now

    for _, r in ipairs(Config.Survivors.reward or {}) do
        exports.ox_inventory:AddItem(src, r.item, r.count or 1)
    end
    if TFP_QuestProgress then TFP_QuestProgress(src, 'rescue', 'any', 1) end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Überlebender', description = 'Er drückt dir etwas Vorrat in die Hand.', type = 'success' })
end)

AddEventHandler('playerDropped', function() cd[source] = nil end)
