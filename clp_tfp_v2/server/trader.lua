-- clp_tfp · server/trader — Schwarzmarkt-Tausch (autoritativ, kein Geld)

local cd = {}

RegisterNetEvent('clp_tfp:trade', function(offerId)
    local src = source
    local offer = (Config.Trader and Config.Trader.offers) and Config.Trader.offers[offerId]
    if not offer then return end

    local now = GetGameTimer()
    if cd[src] and now - cd[src] < 600 then return end
    cd[src] = now

    -- alle „Gibst"-Items vorhanden?
    for _, g in ipairs(offer.give) do
        if (exports.ox_inventory:GetItem(src, g.item, nil, true) or 0) < g.count then
            TriggerClientEvent('ox_lib:notify', src, { description = 'Dir fehlt: ' .. g.count .. 'x ' .. g.item, type = 'error' })
            return
        end
    end
    -- Platz für das „Bekommst"-Item?
    if not exports.ox_inventory:CanCarryItem(src, offer.get.item, offer.get.count or 1) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du kannst das nicht tragen (Platz/Gewicht).', type = 'error' })
        return
    end

    for _, g in ipairs(offer.give) do exports.ox_inventory:RemoveItem(src, g.item, g.count) end
    exports.ox_inventory:AddItem(src, offer.get.item, offer.get.count or 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Schwarzmarkt', description = 'Handel abgeschlossen.', type = 'success' })
    TriggerClientEvent('clp_tfp:tradeOk', src)
end)

AddEventHandler('playerDropped', function() cd[source] = nil end)
