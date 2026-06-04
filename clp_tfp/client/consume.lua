-- clp_tfp · survival · Slice 2
-- Item-Konsum (ox_inventory client.export), Flasche füllen, Wasser abkochen,
-- platzierbares Lagerfeuer (lokale Objekte je Client, ox_target-Interaktion).

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

local SMAX = Config.StatusMax

-- verdorben? ox_inventory liefert bei degrade-Items die Haltbarkeit in data.metadata.durability (0..100)
local function isSpoiled(data)
    return data and data.metadata and type(data.metadata.durability) == 'number'
        and data.metadata.durability <= (Config.SpoiledThreshold or 15)
end

-- ─── Konsum-Effekte ───────────────────────────────────────────────────────────
exports('drinkClean', function()
    TriggerEvent('esx_status:add', 'thirst', math.floor(SMAX * 0.25))
end)

exports('drinkDirty', function()
    TriggerEvent('esx_status:add', 'thirst', math.floor(SMAX * 0.12))
    if math.random(100) <= Config.DirtyWaterSicknessChance and TFP.AddSickness then
        TFP.AddSickness('cholera', 8)
    end
end)

exports('eatFood', function(data)
    TriggerEvent('esx_status:add', 'hunger', math.floor(SMAX * 0.30))
    if isSpoiled(data) and TFP.AddSickness then TFP.AddSickness('food', 8) end
end)

exports('eatCoconut', function(data)
    TriggerEvent('esx_status:add', 'thirst', math.floor(SMAX * 0.10))
    TriggerEvent('esx_status:add', 'hunger', math.floor(SMAX * 0.08))
    if isSpoiled(data) and TFP.AddSickness then TFP.AddSickness('food', 5) end
end)

exports('eatRawMeat', function(data)
    TriggerEvent('esx_status:add', 'hunger', math.floor(SMAX * 0.15))
    -- rohes Fleisch/Fisch ist riskant; verdorben deutlich riskanter
    local chance = (Config.RawMeatSicknessChance or 40)
    if isSpoiled(data) then chance = math.min(100, chance + 45) end
    if math.random(100) <= chance and TFP.AddSickness then
        TFP.AddSickness('food', isSpoiled(data) and 9 or 6)
    end
end)

exports('eatCookedMeat', function(data)
    TriggerEvent('esx_status:add', 'hunger', math.floor(SMAX * 0.35))
    if isSpoiled(data) and TFP.AddSickness then TFP.AddSickness('food', 7) end
end)

exports('eatBerries', function(data)
    TriggerEvent('esx_status:add', 'hunger', math.floor(SMAX * 0.10))
    TriggerEvent('esx_status:add', 'thirst', math.floor(SMAX * 0.05))
    local chance = (Config.BerrySicknessChance or 10)
    if isSpoiled(data) then chance = math.min(100, chance + 35) end
    if math.random(100) <= chance and TFP.AddSickness then
        TFP.AddSickness('food', isSpoiled(data) and 7 or 4)  -- unreife/verdorbene Beeren
    end
end)

exports('useMedkit', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + Config.MedkitHeal))
    if TFP.TryCure then TFP.TryCure('medkit') end
end)

exports('useAntibiotics', function()
    if TFP.TryCure then TFP.TryCure('antibiotics') end
end)

-- ─── Leere Flasche füllen (nur an/in Wasser) ─────────────────────────────────
local function nearWater(ped)
    if IsEntityInWater(ped) then return true end
    local c = GetEntityCoords(ped)
    local f = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    for _, p in ipairs({ c, f }) do
        local found, h = GetWaterHeight(p.x, p.y, p.z)
        if found and math.abs(h - p.z) < 3.0 then return true end
    end
    return false
end

exports('fillBottle', function()
    if not nearWater(PlayerPedId()) then
        lib.notify({ title = 'Überleben', description = 'Hier ist kein Wasser zum Füllen.', type = 'error' })
        return false
    end
    TriggerServerEvent('clp_tfp:fillBottle')
    return false  -- Server tauscht das Item (autoritativ)
end)

-- ─── Lagerfeuer platzieren ───────────────────────────────────────────────────
exports('placeCampfire', function()
    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.4, 0.0)
    local found, gz = GetGroundZFor_3dCoord(fwd.x, fwd.y, fwd.z + 1.0, false)
    local coords = vec3(fwd.x, fwd.y, found and gz or fwd.z)
    local heading = GetEntityHeading(ped)
    if lib.progressBar({
        duration = 4000,
        label = 'Lagerfeuer aufbauen…',
        canCancel = true,
        useWhileDead = false,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
    }) then
        TriggerServerEvent('clp_tfp:placeCampfire', coords, heading)
    end
    return false  -- Server konsumiert das Set
end)

-- ─── Braten am Feuer (roh -> gegart) ─────────────────────────────────────────
local cookLabels = { raw_meat = 'Rohes Fleisch', raw_fish = 'Roher Fisch' }

local function openCook()
    local options = {}
    for raw, cooked in pairs(Config.Cooking.recipes) do
        local have = exports.ox_inventory:Search('count', raw) or 0
        if have > 0 then
            options[#options + 1] = {
                title = ('%s braten'):format(cookLabels[raw] or raw),
                description = ('Vorrat: %dx'):format(have),
                icon = 'fa-solid fa-fire-burner',
                onSelect = function()
                    if lib.progressBar({
                        duration = Config.Cooking.time, label = 'Braten…', canCancel = true,
                        disable = { move = true, combat = true }, anim = Config.Cooking.anim,
                    }) then
                        TriggerServerEvent('clp_tfp:cook', raw)
                    end
                end,
            }
        end
    end
    if #options == 0 then
        lib.notify({ title = 'Kochen', description = 'Du hast nichts zum Braten dabei (rohes Fleisch/Fisch).', type = 'inform' })
        return
    end
    lib.registerContext({ id = 'tfp_cook', title = '🔥 Am Feuer braten', options = options })
    lib.showContext('tfp_cook')
end

-- ─── Lagerfeuer-Objekte (lokal je Client) + Interaktion ──────────────────────
local campfires = {}

local function addCampfire(id, coords, heading)
    if campfires[id] then return end
    local model = joaat(Config.CampfireModel)
    if lib.requestModel(model, 5000) then
        local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(model)
        if heading then SetEntityHeading(obj, heading) end
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        campfires[id] = obj

        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'tfp_boil_' .. id,
                icon = 'fa-solid fa-mug-hot',
                label = 'Wasser abkochen',
                distance = 2.5,
                onSelect = function()
                    if lib.progressBar({
                        duration = 4000, label = 'Wasser abkochen…', canCancel = true,
                        disable = { move = true, combat = true },
                    }) then
                        TriggerServerEvent('clp_tfp:boilWater')
                    end
                end,
            },
            {
                name = 'tfp_cook_' .. id,
                icon = 'fa-solid fa-drumstick-bite',
                label = 'Fleisch/Fisch braten',
                distance = 2.5,
                onSelect = function() openCook() end,
            },
            {
                name = 'tfp_warm_' .. id,
                icon = 'fa-solid fa-fire',
                label = 'Aufwärmen',
                distance = 2.5,
                onSelect = function()
                    ExecuteCommand('e ' .. ((Config.Atmosphere and Config.Atmosphere.warmEmote) or 'crossarms'))
                    lib.notify({ title = 'Wärme', description = 'Du wärmst dich am Feuer.', type = 'inform' })
                end,
            },
            {
                name = 'tfp_camp_craft_' .. id,
                icon = 'fa-solid fa-hammer',
                label = 'Handwerk (Lagerfeuer)',
                distance = 2.5,
                onSelect = function() TriggerEvent('clp_tfp:openStation', 'campfire') end,
            },
        })
    end
end

RegisterNetEvent('clp_tfp:spawnCampfire', function(id, coords, heading)
    addCampfire(id, coords, heading)
end)

RegisterNetEvent('clp_tfp:syncCampfires', function(list)
    for id, cf in pairs(list) do addCampfire(id, cf.coords, cf.heading) end
end)

-- bestehende Lagerfeuer beim Beitritt anfordern
AddEventHandler('esx:playerLoaded', function()
    TriggerServerEvent('clp_tfp:requestCampfires')
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    TriggerServerEvent('clp_tfp:requestCampfires')
end)
