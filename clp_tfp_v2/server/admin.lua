-- clp_tfp · server/admin — Panel-Befehl + Wipe-Steuerung (ace: tfp.admin)

local isAdmin = TFP_IsAdmin

-- Client fragt vor dem Öffnen des Panels, ob er Admin ist
lib.callback.register('clp_tfp:isAdmin', function(source) return TFP_IsAdmin(source) end)

-- Admin: Item geben (autoritativ)
RegisterNetEvent('clp_tfp:adminGive', function(item, count)
    local src = source
    if not TFP_IsAdmin(src) then return end
    if type(item) ~= 'string' then return end
    exports.ox_inventory:AddItem(src, item, math.max(1, math.floor(tonumber(count) or 1)))
end)

RegisterNetEvent('clp_tfp:adminWipe', function(scope)
    local src = source
    if not isAdmin(src) then return end

    if scope == 'map' or scope == 'full' then
        MySQL.query('DELETE FROM tfp_builds')
        TriggerEvent('clp_tfp:buildsWiped') -- Statik-Cache in building.lua leeren
        TriggerClientEvent('clp_tfp:wipeAllBuilds', -1)
    end
    if scope == 'blueprints' or scope == 'full' then
        MySQL.query('DELETE FROM tfp_blueprints')
        TriggerEvent('clp_tfp:clearAllBlueprints')
    end
    if scope == 'full' then
        MySQL.query('DELETE FROM tfp_player') -- Reset: nächster Join = Starter-Kit + verstreutes Spawnen
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Wipe', type = 'success',
        description = ('Wipe ausgeführt: %s. (Voll-Wipe wirkt für Spieler beim nächsten Join.)'):format(scope)
    })
    if TFP_Warn then TFP_Warn(('ADMIN-WIPE: scope=%s durch %s (id %s)'):format(scope, GetPlayerName(src), src)) end
end)
