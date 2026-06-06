-- clp_tfp · server/clothing — getragene Kleidung autoritativ + persistent
-- Anlegen entfernt das Item aus dem Inventar und legt es in den Slot (gespeichert
-- als JSON in tfp_player.clothing). Ablegen gibt es zurück. Swap tauscht Stücke.

local ESX = exports['es_extended']:getSharedObject()
local CC = Config.Clothing or { enabled = false }
local worn = {} -- [identifier] = { slot = item }

CreateThread(function()
    if not CC.enabled then return end
    MySQL.query.await("ALTER TABLE `tfp_player` ADD COLUMN IF NOT EXISTS `clothing` TEXT NULL")
end)

local function loadFor(xPlayer)
    local ident = xPlayer.getIdentifier()
    local row = MySQL.single.await('SELECT clothing FROM tfp_player WHERE identifier = ?', { ident })
    local set = {}
    if row and row.clothing and row.clothing ~= '' then
        local ok, decoded = pcall(json.decode, row.clothing)
        if ok and type(decoded) == 'table' then set = decoded end
    end
    worn[ident] = set
    TriggerClientEvent('clp_tfp:syncClothing', xPlayer.source, set)
end

local function save(ident)
    MySQL.update('UPDATE tfp_player SET clothing = ? WHERE identifier = ?', { json.encode(worn[ident] or {}), ident })
end

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not CC.enabled then return end
    -- nach spawn.lua (legt die tfp_player-Zeile an) laden
    SetTimeout(2500, function()
        if ESX.GetPlayerFromId(playerId) then loadFor(xPlayer) end
    end)
end)

RegisterNetEvent('clp_tfp:equipClothing', function(item)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local def = CC.items and CC.items[item]; if not def then return end
    local ident = xPlayer.getIdentifier()
    worn[ident] = worn[ident] or {}

    if (exports.ox_inventory:GetItem(src, item, nil, true) or 0) < 1 then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Du hast dieses Kleidungsstück nicht.', type = 'error' }); return
    end
    if not exports.ox_inventory:RemoveItem(src, item, 1) then return end

    -- Slot belegt? altes Stück zurück ins Inventar (Swap)
    local old = worn[ident][def.slot]
    if old then
        if not exports.ox_inventory:CanCarryItem(src, old, 1) then
            exports.ox_inventory:AddItem(src, item, 1) -- neues Stück zurückgeben, Abbruch
            TriggerClientEvent('ox_lib:notify', src, { description = 'Kein Platz, um das getragene Stück abzulegen.', type = 'error' }); return
        end
        exports.ox_inventory:AddItem(src, old, 1)
    end

    worn[ident][def.slot] = item
    save(ident)
    TriggerClientEvent('clp_tfp:syncClothing', src, worn[ident])
    TriggerClientEvent('ox_lib:notify', src, { title = 'Kleidung', description = ('%s angelegt.'):format(def.label), type = 'success' })
end)

RegisterNetEvent('clp_tfp:unequipClothing', function(slot)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src); if not xPlayer then return end
    local ident = xPlayer.getIdentifier()
    local set = worn[ident]
    if not set or not set[slot] then return end
    local item = set[slot]
    if not exports.ox_inventory:CanCarryItem(src, item, 1) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Kein Platz im Inventar.', type = 'error' }); return
    end
    exports.ox_inventory:AddItem(src, item, 1)
    set[slot] = nil
    save(ident)
    TriggerClientEvent('clp_tfp:syncClothing', src, set)
    local def = CC.items[item]
    TriggerClientEvent('ox_lib:notify', src, { description = ('%s abgelegt.'):format((def and def.label) or item), type = 'inform' })
end)

AddEventHandler('playerDropped', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then worn[xPlayer.getIdentifier()] = nil end
end)
