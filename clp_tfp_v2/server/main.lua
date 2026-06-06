-- clp_tfp · server/main — Fundament: ESX, DB, globale Server-Helfer
-- Globals hier sind über ALLE Module nutzbar (TFP_RollGive/IsAdmin/QuestProgress).

local ESX = exports['es_extended']:getSharedObject()

-- ─── DB: Spieler-Tabelle (Basis; weitere Spalten ergänzen Module per ALTER) ──
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `tfp_player` (
            `identifier` VARCHAR(64) NOT NULL,
            `started` TINYINT(1) NOT NULL DEFAULT 0,
            `spawn_x` FLOAT NULL, `spawn_y` FLOAT NULL, `spawn_z` FLOAT NULL, `spawn_h` FLOAT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    TFP_OK('DB bereit (tfp_player).')
end)

-- ─── Admin-Check (Ace ODER ESX-Gruppe) ──────────────────────────────────────
local ADMIN_GROUPS = { admin = true, superadmin = true, mod = true }
function TFP_IsAdmin(src)
    if not src or src == 0 then return true end
    if IsPlayerAceAllowed(src, 'tfp.admin') then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    return (xPlayer and ADMIN_GROUPS[xPlayer.getGroup()]) and true or false
end

-- ─── Loot würfeln & geben ────────────────────────────────────────────────────
-- list = { { item='x', chance=0..100, min=1, max=3 }, ... }. Gibt true, wenn etwas fiel.
function TFP_RollGive(src, list)
    if type(list) ~= 'table' then return false end
    local gave = false
    for _, e in ipairs(list) do
        if e.item and math.random(100) <= (e.chance or 100) then
            local lo = e.min or 1
            local hi = e.max or lo
            local count = (hi > lo) and math.random(lo, hi) or lo
            if count > 0 and exports.ox_inventory:CanCarryItem(src, e.item, count) then
                exports.ox_inventory:AddItem(src, e.item, count)
                gave = true
                if TFP_QuestProgress then TFP_QuestProgress(src, 'item', e.item, count) end -- Quest-Hook (Holz/Schrott/Fisch …)
            end
        end
    end
    return gave
end

-- ─── Quest-Fortschritt-Hook (echte Logik kommt im quests-Modul) ─────────────
-- Module rufen TFP_QuestProgress(src, type, key, amount) auf; quests/ hängt sich
-- später per AddEventHandler('clp_tfp:questProgress', ...) ein.
function TFP_QuestProgress(src, ptype, key, amount)
    TriggerEvent('clp_tfp:questProgress', src, ptype, key, amount or 1)
end

-- ─── Diagnose ────────────────────────────────────────────────────────────────
RegisterCommand('tfpv2', function(src)
    if not TFP_IsAdmin(src) then return end
    TFP_Log('v2-Fundament aktiv. Phasen folgen laut REBUILD_PROMPT.md.')
end, true)
