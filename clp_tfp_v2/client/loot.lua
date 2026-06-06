-- clp_tfp · client/loot — Welt-Props durchsuchen (ox_target)

local looted = {} -- [entity] = GameTimer (lokaler Re-Loot-Cooldown)

local function search(category, entity)
    local now = GetGameTimer()
    if entity and entity ~= 0 and looted[entity] and now - looted[entity] < Config.Loot.reLootCooldownMs then
        lib.notify({ description = 'Hier gibt es gerade nichts mehr.', type = 'inform' })
        return
    end
    if lib.progressBar({
        duration = Config.Loot.searchTime, label = 'Durchsuchen…', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = Config.Loot.searchAnim,
    }) then
        local coords
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            looted[entity] = now
            coords = GetEntityCoords(entity)
        end
        TriggerServerEvent('clp_tfp:loot', category, coords) -- coords = geteilter Container-Cooldown
    end
end

CreateThread(function()
    for category, t in pairs(Config.Loot.tables) do
        if t.models and #t.models > 0 then
            local cat = category
            local ok, err = pcall(function()
                exports.ox_target:addModel(t.models, {
                    {
                        name = 'tfp_loot_' .. cat,
                        icon = t.icon or 'fa-solid fa-magnifying-glass',
                        label = t.label or 'Durchsuchen',
                        distance = 2.0,
                        onSelect = function(data) search(cat, data and data.entity or 0) end,
                    },
                })
            end)
            if not ok and TFP_Warn then TFP_Warn(('Loot-Target "%s" übersprungen: %s'):format(cat, tostring(err))) end
        end
    end

    -- Fahrzeuge: an JEDEM Fahrzeug durchsuchbar (eigener Re-Loot-Cooldown pro Fahrzeug)
    if Config.Loot.tables.vehicle then
        local ok, err = pcall(function()
            exports.ox_target:addGlobalVehicle({
                {
                    name = 'tfp_loot_vehicle',
                    icon = Config.Loot.tables.vehicle.icon or 'fa-solid fa-car-burst',
                    label = Config.Loot.tables.vehicle.label or 'Fahrzeug durchsuchen',
                    distance = 2.5,
                    onSelect = function(data) search('vehicle', data and data.entity or 0) end,
                },
            })
        end)
        if not ok and TFP_Warn then TFP_Warn('Fahrzeug-Loot (addGlobalVehicle) nicht verfügbar: ' .. tostring(err)) end
    end
end)
