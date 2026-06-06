-- clp_tfp · client/clothing — Mehr-Slot-Kleidung mit Schutzwerten
-- Slots: Kopf/Oberkörper/Beine/Füße. Kleidungsstück aus dem Inventar BENUTZEN = anlegen,
-- /kleidung-Menü (F7) = ab-/umlegen. Werte summieren sich und wirken auf:
--   Isolierung -> Wärme (main.lua) · wasserdicht -> Nässe (main.lua)
--   Panzerung -> GTA-Rüstung + weniger Blutung (wounds.lua) · Tarnung -> Bedrohung (predators.lua)

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}
TFP.State = TFP.State or {}
TFP.State.clothing = TFP.State.clothing or {} -- [slot] = itemName

local CC = Config.Clothing or { enabled = false }

-- ── Summe einer Eigenschaft über alle getragenen Stücke ──────────────────────
function TFP.ClothingStat(stat)
    if not CC.enabled then return 0 end
    local sum = 0
    for _, item in pairs(TFP.State.clothing) do
        local def = CC.items[item]
        if def and def[stat] then sum = sum + def[stat] end
    end
    return sum
end

-- Blutungs-Reduktion durch Panzerung (0..armorBleedMax) — von wounds.lua genutzt
function TFP.ClothingArmorFactor()
    local a = TFP.ClothingStat('armor')
    if a <= 0 then return 0 end
    return math.min(CC.armorBleedMax or 0.6, a / (CC.armorBleedDiv or 100))
end

-- Nässe-Schutz in % (gekappt) — von main.lua genutzt
function TFP.ClothingWaterproof()
    return math.min(CC.waterproofCap or 90, TFP.ClothingStat('waterproof'))
end

local function statsText(def)
    local t = {}
    if def.insulation then t[#t + 1] = '🌡 +' .. def.insulation end
    if def.waterproof then t[#t + 1] = '💧 ' .. def.waterproof .. '%' end
    if def.armor then t[#t + 1] = '🛡 +' .. def.armor end
    if def.camo then t[#t + 1] = '🌿 +' .. def.camo end
    return table.concat(t, ' · ')
end

-- ── Anlegen: Item aus dem Inventar benutzen ──────────────────────────────────
exports('equipClothing', function(data)
    local item = data and data.name
    if not item or not (CC.items and CC.items[item]) then
        lib.notify({ description = 'Das kannst du nicht anziehen.', type = 'inform' }); return false
    end
    TriggerServerEvent('clp_tfp:equipClothing', item)
    return false -- ox_inventory NICHT auto-verbrauchen; der Server bewegt das Item
end)

-- ── Server-Sync: getragene Kleidung übernehmen + Rüstung sofort anlegen ──────
RegisterNetEvent('clp_tfp:syncClothing', function(set)
    TFP.State.clothing = set or {}
    local a = math.min(100, TFP.ClothingStat('armor'))
    if a > 0 then SetPedArmour(PlayerPedId(), math.max(GetPedArmour(PlayerPedId()), a)) end
end)

-- ── Menü: Slots ansehen, ab-/umlegen ─────────────────────────────────────────
local openSlotMenu
function TFP.OpenClothing()
    local opts = {}
    for _, slot in ipairs(CC.slots) do
        local equipped = TFP.State.clothing[slot]
        local def = equipped and CC.items[equipped]
        opts[#opts + 1] = {
            title = CC.slotLabels[slot] .. (def and (': ' .. def.label) or ': —'),
            description = def and statsText(def) or 'Leer',
            icon = CC.slotIcons[slot],
            arrow = true,
            onSelect = function() openSlotMenu(slot) end,
        }
    end
    opts[#opts + 1] = { title = 'Schutzwerte gesamt', icon = 'fa-solid fa-shield', disabled = true,
        description = ('🌡 Isolierung %d · 💧 wasserdicht %d%% · 🛡 Panzerung %d · 🌿 Tarnung %d'):format(
            TFP.ClothingStat('insulation'), TFP.ClothingWaterproof(),
            TFP.ClothingStat('armor'), TFP.ClothingStat('camo')) }
    lib.registerContext({ id = 'tfp_clothing', title = '🧥 Kleidung', options = opts })
    lib.showContext('tfp_clothing')
end

openSlotMenu = function(slot)
    local opts = {}
    local equipped = TFP.State.clothing[slot]
    if equipped then
        local def = CC.items[equipped]
        opts[#opts + 1] = { title = 'Ablegen', icon = 'fa-solid fa-xmark',
            description = (def and def.label or equipped) .. ' ausziehen',
            onSelect = function() TriggerServerEvent('clp_tfp:unequipClothing', slot) end }
    end
    -- anziehbare Stücke für diesen Slot im Inventar
    for item, def in pairs(CC.items) do
        if def.slot == slot and item ~= equipped then
            local have = exports.ox_inventory:Search('count', item) or 0
            if have > 0 then
                opts[#opts + 1] = { title = 'Anlegen: ' .. def.label, icon = 'fa-solid fa-shirt',
                    description = statsText(def), onSelect = function() TriggerServerEvent('clp_tfp:equipClothing', item) end }
            end
        end
    end
    if #opts == 0 then opts[1] = { title = 'Nichts für diesen Slot', description = 'Kein passendes Kleidungsstück im Inventar.', disabled = true } end
    lib.registerContext({ id = 'tfp_clothing_slot', title = '🧥 ' .. (CC.slotLabels[slot] or slot), menu = 'tfp_clothing', options = opts })
    lib.showContext('tfp_clothing_slot')
end

RegisterCommand('kleidung', function() TFP.OpenClothing() end, false)
if CC.enabled then
    lib.addKeybind({ name = 'tfp_clothing', description = 'Kleidung öffnen', defaultKey = 'F7', onPressed = function() TFP.OpenClothing() end })
end

-- ── Rüstung erholt sich langsam bis zum Kleidungs-Max (Weste „hält") ─────────
CreateThread(function()
    if not CC.enabled then return end
    while true do
        Wait(1000)
        if ESX.PlayerLoaded and TFP.State.ready then
            local ped = PlayerPedId()
            if not IsPedDeadOrDying(ped, true) then
                local maxA = math.min(100, TFP.ClothingStat('armor'))
                if maxA > 0 then
                    local cur = GetPedArmour(ped)
                    if cur < maxA then SetPedArmour(ped, math.min(maxA, cur + (CC.pedArmorRegen or 2))) end
                end
            end
        end
    end
end)
