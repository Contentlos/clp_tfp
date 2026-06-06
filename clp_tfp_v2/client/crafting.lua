-- clp_tfp · client/crafting — Rezepte an Stationen (hand/campfire/workbench/forge) + Blueprints
TFP = TFP or {}

local function itemCount(name) return exports.ox_inventory:Search('count', name) or 0 end
local function ingredientsText(rec)
    local t = {}
    for _, ing in ipairs(rec.ingredients) do t[#t + 1] = ('%s ×%d  (du: %d)'):format(ing.item, ing.count, itemCount(ing.item)) end
    return table.concat(t, '\n')
end
local function hasIngredients(rec)
    for _, ing in ipairs(rec.ingredients) do if itemCount(ing.item) < ing.count then return false end end
    return true
end

local function openStation(station)
    local known = lib.callback.await('clp_tfp:getKnown', false) or {}
    local options = {}
    for id, rec in pairs(Config.Crafting.recipes) do
        if rec.station == station then
            local locked = rec.blueprint and not known[id]
            options[#options + 1] = {
                title = rec.label .. (locked and '  🔒' or ''),
                description = locked and 'Bauplan erforderlich' or ingredientsText(rec),
                disabled = locked or not hasIngredients(rec),
                onSelect = function()
                    if lib.progressBar({ duration = rec.time or 4000, label = 'Herstellen: ' .. rec.label, canCancel = true,
                            disable = { move = true, car = true, combat = true }, anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } }) then
                        TriggerServerEvent('clp_tfp:craft', id)
                    end
                end,
            }
        end
    end
    if #options == 0 then lib.notify({ description = 'Hier kannst du gerade nichts herstellen.', type = 'inform' }); return end
    local titles = { hand = 'Handwerk (Hand)', campfire = 'Lagerfeuer', workbench = 'Werkbank', forge = 'Schmelzofen' }
    lib.registerContext({ id = 'tfp_craft_' .. station, title = titles[station] or 'Handwerk', options = options })
    lib.showContext('tfp_craft_' .. station)
end

AddEventHandler('clp_tfp:openStation', function(station) openStation(station) end)
RegisterCommand('craft', function() openStation('hand') end, false)
function TFP.OpenCrafting() openStation('hand') end

exports('learnBlueprint', function(data) TriggerServerEvent('clp_tfp:learnBlueprint', data and data.name) end)
