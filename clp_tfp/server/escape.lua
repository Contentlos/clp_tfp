-- clp_tfp · escape/ (Server) — Quest-Fortschritt + Anforderungen (autoritativ)

local ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    Wait(2000) -- tfp_player wird in server/spawn.lua angelegt — kurz warten, dann migrieren
    -- ohne langsame information_schema-Abfrage (MariaDB: ADD COLUMN IF NOT EXISTS)
    MySQL.query("ALTER TABLE `tfp_player` ADD COLUMN IF NOT EXISTS `escape_step` INT NOT NULL DEFAULT 1")
end)

local function getStep(ident)
    local row = MySQL.single.await('SELECT escape_step FROM tfp_player WHERE identifier = ?', { ident })
    return (row and row.escape_step) or 1
end

local function stepData(id)
    for _, st in ipairs(Config.Escape.steps) do if st.id == id then return st end end
    return nil
end

RegisterNetEvent('clp_tfp:escapeRequest', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    TriggerClientEvent('clp_tfp:escapeState', src, getStep(xPlayer.getIdentifier()))
end)

RegisterNetEvent('clp_tfp:escapeStep', function(stepId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    local cur = getStep(ident)
    if stepId ~= cur then return end

    local s = stepData(cur)
    if not s then return end

    for _, need in ipairs(s.need or {}) do
        if (exports.ox_inventory:GetItem(src, need.item, nil, true) or 0) < need.count then
            TriggerClientEvent('ox_lib:notify', src, { description = ('Dir fehlen: %dx %s'):format(need.count, need.item), type = 'error' })
            return
        end
    end
    for _, need in ipairs(s.need or {}) do exports.ox_inventory:RemoveItem(src, need.item, need.count) end

    MySQL.update('UPDATE tfp_player SET escape_step = ? WHERE identifier = ?', { cur + 1, ident })

    if s.escape then
        TriggerClientEvent('clp_tfp:escapeDone', src, s.escape, 'Du hast die Insel verlassen — willkommen auf dem Festland.')
    else
        TriggerClientEvent('ox_lib:notify', src, { description = s.done or 'Schritt abgeschlossen.', type = 'success' })
    end
    TriggerClientEvent('clp_tfp:escapeState', src, cur + 1)
end)
