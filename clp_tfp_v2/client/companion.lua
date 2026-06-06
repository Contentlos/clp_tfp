-- clp_tfp · client/companion — Wachhund: folgt, greift Feinde an (Hundepfeife)

local dog

exports('useDogWhistle', function()
    if dog and DoesEntityExist(dog) then
        DeleteEntity(dog); dog = nil
        lib.notify({ title = 'Begleiter', description = 'Du schickst deinen Hund weg.', type = 'inform' })
        return false
    end
    local model = joaat(Config.Companion.model)
    if not IsModelValid(model) or not lib.requestModel(model, 5000) then return false end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    dog = CreatePed(28, model, c.x + 1.0, c.y, c.z, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(dog, true, true)
    SetPedRelationshipGroupHash(dog, `PLAYER`) -- freundlich zum Spieler
    SetPedFleeAttributes(dog, 0, false)
    TaskFollowToOffsetOfEntity(dog, ped, 0.6, -0.8, 0.0, 2.0, -1, 2.0, true)
    lib.notify({ title = 'Begleiter', description = 'Dein Hund folgt dir.', type = 'success' })
    return false
end)

-- Wach-Verhalten: greift nahe TFP_HOSTILE-Peds an, folgt sonst
CreateThread(function()
    local hostile = `TFP_HOSTILE`
    while true do
        Wait(2000)
        if dog and DoesEntityExist(dog) and not IsEntityDead(dog) then
            local dc = GetEntityCoords(dog)
            local target
            for _, p in ipairs(GetGamePool('CPed')) do
                if p ~= dog and DoesEntityExist(p) and not IsEntityDead(p) and not IsPedAPlayer(p) then
                    if GetPedRelationshipGroupHash(p) == hostile and #(GetEntityCoords(p) - dc) < 18.0 then
                        target = p; break
                    end
                end
            end
            if target then
                TaskCombatPed(dog, target, 0, 16)
            elseif not IsPedInCombat(dog, 0) then
                TaskFollowToOffsetOfEntity(dog, PlayerPedId(), 0.6, -0.8, 0.0, 2.0, -1, 2.0, true)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and dog and DoesEntityExist(dog) then DeleteEntity(dog) end
end)
