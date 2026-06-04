-- clp_tfp · vehicles/ (Client) — Boot aus Bausatz am Wasser zusammenbauen

exports('useBoatKit', function()
    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, -0.5)
    local found, wz = GetWaterHeight(fwd.x, fwd.y, fwd.z + 2.0)
    if not found then
        lib.notify({ description = 'Ein Boot kannst du nur am/über Wasser zusammenbauen.', type = 'error' })
        return false
    end
    if lib.progressBar({ duration = 5000, label = 'Boot zusammenbauen…', canCancel = true,
            disable = { move = true, car = true, combat = true }, anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } }) then
        local model = joaat(Config.Vehicles.boat.model)
        if IsModelValid(model) and lib.requestModel(model, 5000) then
            local veh = CreateVehicle(model, fwd.x, fwd.y, wz, GetEntityHeading(ped), true, false)
            SetModelAsNoLongerNeeded(model)
            SetVehicleOnGroundProperly(veh)
            SetEntityAsMissionEntity(veh, true, true)
            lib.notify({ title = 'Boot', description = 'Das Boot ist startklar.', type = 'success' })
        end
        return -- ox konsumiert den Bausatz (consume = 1)
    end
    return false -- abgebrochen -> Bausatz behalten
end)
