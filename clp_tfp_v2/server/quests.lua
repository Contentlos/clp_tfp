-- clp_tfp · server/quests — Survival-Aufgaben: Fortschritt verfolgen + belohnen
-- Fortschritt session-basiert (im Speicher). Wiederholbar (Config.QuestRepeat).
-- Hängt sich an den Hook aus server/main (TFP_QuestProgress → 'clp_tfp:questProgress').

local progress = {}  -- [src] = { [questId] = count }

AddEventHandler('clp_tfp:questProgress', function(src, qtype, key, amount)
    if not src or src <= 0 or not Config.Quests then return end
    progress[src] = progress[src] or {}
    for _, q in ipairs(Config.Quests) do
        if q.type == qtype and (q.key == 'any' or q.key == key) then
            local p = (progress[src][q.id] or 0) + (amount or 1)
            if p >= q.target then
                for _, r in ipairs(q.reward or {}) do
                    exports.ox_inventory:AddItem(src, r.item, r.count or 1)
                end
                progress[src][q.id] = Config.QuestRepeat and 0 or q.target
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Aufgabe erfüllt ✔', description = q.label .. ' — Belohnung erhalten!', type = 'success' })
            else
                progress[src][q.id] = p
            end
        end
    end
end)

lib.callback.register('clp_tfp:getQuests', function(source)
    local p = progress[source] or {}
    local res = {}
    for _, q in ipairs(Config.Quests or {}) do
        res[#res + 1] = { label = q.label, desc = q.desc, cur = p[q.id] or 0, target = q.target }
    end
    return res
end)

AddEventHandler('playerDropped', function() progress[source] = nil end)
