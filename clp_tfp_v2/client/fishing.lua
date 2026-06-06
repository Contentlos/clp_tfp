-- clp_tfp · client/fishing — Angeln am/im Wasser (ox_inventory client.export)

local function nearWater(ped)
    if IsEntityInWater(ped) then return true end
    local c = GetEntityCoords(ped)
    local f = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.5, 0.0)
    for _, p in ipairs({ c, f }) do
        local found, h = GetWaterHeight(p.x, p.y, p.z)
        if found and math.abs(h - p.z) < 4.0 then return true end
    end
    return false
end

local function startFishing()
    local ped = PlayerPedId()
    if (exports.ox_inventory:Search('count', Config.Fishing.rodItem) or 0) <= 0 then
        lib.notify({ title = 'Angeln', description = 'Du brauchst eine Angel.', type = 'error' })
        return false
    end
    if not nearWater(ped) then
        lib.notify({ title = 'Angeln', description = 'Hier ist kein Wasser — geh näher ans Ufer/Meer.', type = 'error' })
        return false
    end
    if lib.progressBar({
        duration = Config.Fishing.time, label = 'Angeln…', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = Config.Fishing.anim,
    }) then
        TriggerServerEvent('clp_tfp:fish')
    end
    return false  -- Angel wird nicht verbraucht
end

exports('useFishingRod', startFishing)
TFP = TFP or {}
TFP.Fish = startFishing
TFP.HasRod = function() return (exports.ox_inventory:Search('count', Config.Fishing.rodItem) or 0) > 0 end
