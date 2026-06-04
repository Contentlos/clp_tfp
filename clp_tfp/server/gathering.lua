-- clp_tfp · gathering/ (Server)
-- Validiert Sammel-Anfragen (Cooldown pro Spieler) und gibt Erträge autoritativ.

local cooldowns = {}

-- Werkzeug abnutzen; zerbricht bei Haltbarkeit <= 0
local function wearTool(src, item)
    local loss = Config.Gathering.toolDurabilityLoss or 0
    if loss <= 0 then return end
    local ok, slot = pcall(function() return exports.ox_inventory:GetSlotWithItem(src, item) end)
    if not ok or not slot then return end
    local dur = (slot.metadata and slot.metadata.durability) or 100
    dur = dur - loss
    if dur <= 0 then
        exports.ox_inventory:RemoveItem(src, item, 1, nil, slot.slot)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Werkzeug', description = 'Dein Werkzeug ist zerbrochen.', type = 'error' })
    else
        pcall(function() exports.ox_inventory:SetDurability(src, slot.slot, dur) end)
    end
end

RegisterNetEvent('clp_tfp:gather', function(nodeType)
    local src = source
    local node = Config.Gathering.nodes[nodeType]
    if not node then return end

    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < Config.Gathering.cooldownMs then return end
    cooldowns[src] = now

    TFP_RollGive(src, node.yields)
    if node.tool then wearTool(src, node.tool) end
end)

-- ─── Jagd: Ausnehmen (Tier) / Durchsuchen (NPC) ──────────────────────────────
local harvestCd = {}
RegisterNetEvent('clp_tfp:harvest', function(kind)
    local src = source
    local now = GetGameTimer()
    if harvestCd[src] and now - harvestCd[src] < (Config.Hunt.cooldownMs or 1500) then return end
    harvestCd[src] = now
    TFP_RollGive(src, (kind == 'npc') and Config.Hunt.npcYields or Config.Hunt.animalYields)
    if TFP_QuestProgress then TFP_QuestProgress(src, 'harvest', kind or 'animal', 1) end
end)

-- ─── Braten am Feuer: roh -> gegart (autoritativ) ────────────────────────────
local cookCd = {}
RegisterNetEvent('clp_tfp:cook', function(raw)
    local src = source
    local cooked = Config.Cooking and Config.Cooking.recipes[raw]
    if not cooked then return end
    local now = GetGameTimer()
    if cookCd[src] and now - cookCd[src] < 800 then return end
    cookCd[src] = now
    if exports.ox_inventory:RemoveItem(src, raw, 1) then
        exports.ox_inventory:AddItem(src, cooked, 1)
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    harvestCd[source] = nil
    cookCd[source] = nil
end)
