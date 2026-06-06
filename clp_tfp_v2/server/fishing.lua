-- clp_tfp · server/fishing — autoritativer Fisch-Ertrag (braucht Angel im Inventar)

local fishCd = {}

RegisterNetEvent('clp_tfp:fish', function()
    local src = source
    local rod = Config.Fishing.rodItem
    if (exports.ox_inventory:GetItem(src, rod, nil, true) or 0) <= 0 then return end
    local now = GetGameTimer()
    if fishCd[src] and now - fishCd[src] < 1500 then return end
    fishCd[src] = now
    if not TFP_RollGive(src, Config.Fishing.yields) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Angeln', description = 'Kein Biss…', type = 'inform' })
    end
end)

AddEventHandler('playerDropped', function() fishCd[source] = nil end)
