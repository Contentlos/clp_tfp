-- clp_tfp · client/survivors — Überlebende finden & helfen → Begleiter
-- Begleiter folgt dir und kämpft gegen feindliche Peds (wie der Wachhund, aber Mensch + Waffe).

local ESX = exports['es_extended']:getSharedObject()
local S = Config.Survivors or { enabled = false }
TFP = TFP or {}

local survivors = {}     -- [spawnIndex] = ped (noch nicht gerettet)
local rescuedAt = {}     -- [spawnIndex] = GameTimer (Respawn-Cooldown)
local companion = nil    -- aktueller menschlicher Begleiter

local HOSTILE = { [`TFP_HOSTILE`] = true, [`TFP_EVENT_HOSTILE`] = true, [`TFP_ESCAPE_GUARD`] = true }

local function snap(x, y, z) local f, gz = GetGroundZFor_3dCoord(x, y, z + 20.0, false); return f and gz or z end

-- ── Begleiter ───────────────────────────────────────────────────────────────
local function dismissCompanion()
    if companion and DoesEntityExist(companion) then
        exports.ox_target:removeLocalEntity(companion)
        SetPedAsNoLongerNeeded(companion)
        TaskSmartFleeCoord(companion, GetEntityCoords(companion), 80.0, -1, false, false)
    end
    companion = nil
    lib.notify({ title = 'Begleiter', description = 'Du schickst deinen Begleiter weg.', type = 'inform' })
end
TFP.DismissCompanion = dismissCompanion

local function makeCompanion(ped)
    companion = ped
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, `PLAYER`)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanRagdoll(ped, true)
    SetPedAccuracy(ped, 30)
    if S.companionWeapon then GiveWeaponToPed(ped, joaat(S.companionWeapon), 250, false, true) end
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 1.0, -1.2, 0.0, 2.0, -1, 3.0, true)
    exports.ox_target:addLocalEntity(ped, { {
        name = 'tfp_companion_dismiss', icon = 'fa-solid fa-person-walking-arrow-right',
        label = 'Begleiter wegschicken', distance = 2.5, onSelect = dismissCompanion,
    } })
end

-- ── Überlebenden retten ──────────────────────────────────────────────────────
local function rescue(idx, ped)
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    if lib.progressBar({ duration = S.rescueTime or 3500, label = 'Du hilfst dem Überlebenden…',
            canCancel = true, disable = { move = true, car = true, combat = true },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } }) then
        exports.ox_target:removeLocalEntity(ped)
        ClearPedTasksImmediately(ped)
        rescuedAt[idx] = GetGameTimer()
        survivors[idx] = nil
        TriggerServerEvent('clp_tfp:survivorRescued')
        if companion and DoesEntityExist(companion) and not IsEntityDead(companion) then
            SetPedAsNoLongerNeeded(ped)
            TaskSmartFleeCoord(ped, GetEntityCoords(ped), 100.0, -1, false, false)
            lib.notify({ title = 'Überlebender', description = '„Danke! Ich schlag mich allein durch." (Du führst schon jemanden.)', type = 'success' })
        else
            makeCompanion(ped)
            lib.notify({ title = 'Begleiter', description = 'Der Überlebende schließt sich dir an — er folgt und kämpft mit.', type = 'success' })
        end
    end
end

local function spawnSurvivor(idx, coords)
    local model = joaat(S.models[math.random(#S.models)])
    if not (IsModelValid(model) and lib.requestModel(model, 3000)) then return end
    local ped = CreatePed(4, model, coords.x, coords.y, snap(coords.x, coords.y, coords.z), math.random(0, 359) + 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_COWER', 0, true)
    survivors[idx] = ped
    exports.ox_target:addLocalEntity(ped, { {
        name = 'tfp_survivor_' .. idx, icon = 'fa-solid fa-hand-holding-heart', label = 'Überlebenden helfen', distance = 2.0,
        canInteract = function() return survivors[idx] == ped and not IsEntityDead(ped) end,
        onSelect = function() rescue(idx, ped) end,
    } })
end

-- ── Hauptthread: spawnen/prunen + Begleiter-Verhalten ───────────────────────
CreateThread(function()
    if not S.enabled then return end
    while true do
        Wait(2500)
        if ESX.PlayerLoaded and not IsPedDeadOrDying(PlayerPedId(), true) then
            local pc = GetEntityCoords(PlayerPedId())

            -- entfernte (nicht-Begleiter) Überlebende abräumen
            for idx, ped in pairs(survivors) do
                if not DoesEntityExist(ped) or #(GetEntityCoords(ped) - pc) > (S.despawnDist or 130.0) then
                    if DoesEntityExist(ped) then exports.ox_target:removeLocalEntity(ped); DeleteEntity(ped) end
                    survivors[idx] = nil
                end
            end

            -- in Reichweite spawnen (Cooldown beachten)
            for idx, coords in ipairs(S.spawns) do
                local cd = rescuedAt[idx]
                if not survivors[idx] and (not cd or GetGameTimer() - cd > (S.respawnCooldown or 1800000))
                   and #(pc - coords) < (S.activateDist or 65.0) then
                    spawnSurvivor(idx, coords)
                end
            end

            -- Begleiter: kämpfen oder folgen
            if companion and DoesEntityExist(companion) and not IsEntityDead(companion) then
                local cc = GetEntityCoords(companion)
                local target
                for _, p in ipairs(GetGamePool('CPed')) do
                    if p ~= companion and DoesEntityExist(p) and not IsEntityDead(p) and not IsPedAPlayer(p) then
                        if HOSTILE[GetPedRelationshipGroupHash(p)] and #(GetEntityCoords(p) - cc) < 22.0 then target = p; break end
                    end
                end
                if target then TaskCombatPed(companion, target, 0, 16)
                elseif not IsPedInCombat(companion, 0) and #(cc - pc) > 4.5 then
                    TaskFollowToOffsetOfEntity(companion, PlayerPedId(), 1.0, -1.2, 0.0, 2.0, -1, 3.0, true)
                end
            elseif companion then
                if DoesEntityExist(companion) then exports.ox_target:removeLocalEntity(companion) end
                companion = nil
                lib.notify({ title = 'Begleiter', description = 'Dein Begleiter ist gefallen.', type = 'error' })
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in pairs(survivors) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    if companion and DoesEntityExist(companion) then DeleteEntity(companion) end
end)
