-- clp_tfp · crafting/ : Blueprint-Rezepte an Stationen (hand / campfire / workbench)

local ESX = exports['es_extended']:getSharedObject()

local function itemCount(name)
    return exports.ox_inventory:Search('count', name) or 0
end

local function ingredientsText(rec)
    local t = {}
    for _, ing in ipairs(rec.ingredients) do
        t[#t + 1] = ('%s ×%d  (du: %d)'):format(ing.item, ing.count, itemCount(ing.item))
    end
    return table.concat(t, '\n')
end

local function hasIngredients(rec)
    for _, ing in ipairs(rec.ingredients) do
        if itemCount(ing.item) < ing.count then return false end
    end
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
                    if lib.progressBar({
                        duration = rec.time or 4000, label = 'Herstellen: ' .. rec.label, canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
                    }) then
                        TriggerServerEvent('clp_tfp:craft', id)
                    end
                end,
            }
        end
    end
    if #options == 0 then
        lib.notify({ description = 'Hier kannst du gerade nichts herstellen.', type = 'inform' })
        return
    end
    local titles = { hand = 'Handwerk (Hand)', campfire = 'Lagerfeuer', workbench = 'Werkbank', forge = 'Schmelzofen (Esse)' }
    lib.registerContext({ id = 'tfp_craft_' .. station, title = titles[station] or 'Handwerk', options = options })
    lib.showContext('tfp_craft_' .. station)
end

AddEventHandler('clp_tfp:openStation', function(station) openStation(station) end)
RegisterCommand('craft', function() openStation('hand') end, false)
function TFP.OpenCrafting() openStation('hand') end

-- ─── Werkbank platzieren (Session-Objekte je Client) ─────────────────────────
exports('placeWorkbench', function()
    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.2, 0.0)
    local found, gz = GetGroundZFor_3dCoord(fwd.x, fwd.y, fwd.z + 1.0, false)
    local coords = vec3(fwd.x, fwd.y, found and gz or fwd.z)
    if lib.progressBar({ duration = 3000, label = 'Werkbank aufbauen…', canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' } }) then
        TriggerServerEvent('clp_tfp:placeWorkbench', coords, GetEntityHeading(ped))
    end
    return false
end)

local workbenches = {}
RegisterNetEvent('clp_tfp:spawnWorkbench', function(id, coords, heading)
    if workbenches[id] then return end
    local model = joaat('prop_tool_bench02')
    if lib.requestModel(model, 5000) then
        local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(model)
        if heading then SetEntityHeading(obj, heading) end
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        workbenches[id] = obj
        exports.ox_target:addLocalEntity(obj, {
            { name = 'tfp_wb_' .. id, icon = 'fa-solid fa-screwdriver-wrench', label = 'Werkbank — Handwerk',
              distance = 2.5, onSelect = function() openStation('workbench') end },
        })
    end
end)
RegisterNetEvent('clp_tfp:syncWorkbenches', function(list)
    for id, w in pairs(list) do TriggerEvent('clp_tfp:spawnWorkbench', id, w.coords, w.heading) end
end)
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    TriggerServerEvent('clp_tfp:requestWorkbenches')
end)

-- ─── Blueprint lernen ─────────────────────────────────────────────────────────
exports('learnBlueprint', function(data)
    TriggerServerEvent('clp_tfp:learnBlueprint', data and data.name)
end)
