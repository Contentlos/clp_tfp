-- clp_tfp · server/gathering — Sammel-Validierung (Cooldown) + Werkzeug-Abnutzung
local cooldowns = {}

local function wearTool(src, item)
    local loss = Config.Gathering.toolDurabilityLoss or 0
    if loss <= 0 then return end
    local ok, slot = pcall(function() return exports.ox_inventory:GetSlotWithItem(src, item) end)
    if not ok or not slot then return end
    local dur = ((slot.metadata and slot.metadata.durability) or 100) - loss
    if dur <= 0 then
        exports.ox_inventory:RemoveItem(src, item, 1, nil, slot.slot)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Werkzeug', description = 'Dein Werkzeug ist zerbrochen.', type = 'error' })
    else
        pcall(function() exports.ox_inventory:SetDurability(src, slot.slot, dur) end)
    end
end

RegisterNetEvent('clp_tfp:gather', function(nodeType)
    local src = source
    local node = Config.Gathering.nodes[nodeType]; if not node then return end
    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < Config.Gathering.cooldownMs then return end
    cooldowns[src] = now
    TFP_RollGive(src, node.yields)
    if node.tool then wearTool(src, node.tool) end
end)

-- ─── Ausnehmen / Durchsuchen von Kadavern & toten NPCs (ai.lua, camps.lua, predators.lua) ─
local harvestCd = {}
RegisterNetEvent('clp_tfp:harvest', function(kind)
    local src = source
    local now = GetGameTimer()
    if harvestCd[src] and now - harvestCd[src] < (Config.Hunt.cooldownMs or 1500) then return end
    harvestCd[src] = now
    TFP_RollGive(src, (kind == 'npc') and Config.Hunt.npcYields or Config.Hunt.animalYields)
    if TFP_QuestProgress then TFP_QuestProgress(src, 'harvest', kind or 'animal', 1) end
end)

AddEventHandler('playerDropped', function() cooldowns[source] = nil; harvestCd[source] = nil end)
