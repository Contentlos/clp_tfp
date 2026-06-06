-- clp_tfp · client/realism — Verletzungen, Sinne, Behandlung
local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

local MELEE = {
    [`WEAPON_UNARMED`] = true, [`WEAPON_KNIFE`] = true, [`WEAPON_MACHETE`] = true, [`WEAPON_BAT`] = true,
    [`WEAPON_CROWBAR`] = true, [`WEAPON_HATCHET`] = true, [`WEAPON_HAMMER`] = true, [`WEAPON_BOTTLE`] = true,
    [`WEAPON_GOLFCLUB`] = true, [`WEAPON_NIGHTSTICK`] = true, [`WEAPON_WRENCH`] = true, [`WEAPON_BATTLEAXE`] = true,
    [`WEAPON_POOLCUE`] = true, [`WEAPON_KNUCKLE`] = true, [`WEAPON_DAGGER`] = true, [`WEAPON_SWITCHBLADE`] = true,
    [`WEAPON_STONE_HATCHET`] = true, [`WEAPON_FLASHLIGHT`] = true,
}
local BITE = { [`WEAPON_ANIMAL`] = true, [`WEAPON_BITE`] = true }
local FIRE = { [`WEAPON_FIRE`] = true, [`WEAPON_MOLOTOV`] = true, [`WEAPON_FLARE`] = true, [`WEAPON_PETROLCAN`] = true }

-- Treffer → zonenbasierte Wunde
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    if victim ~= PlayerPedId() or IsEntityDead(victim) then return end
    local weapon = args[7]
    if weapon == `WEAPON_FALL` then return end
    local kind = FIRE[weapon] and 'burn' or (BITE[weapon] and 'bite' or (MELEE[weapon] and 'cut' or 'gunshot'))
    if TFP.AddWound then TFP.AddWound(nil, kind) elseif TFP.Bleed then TFP.Bleed(Config.Injury.bleedFromHit or 16) end
    if MELEE[weapon] and not TFP.State.fracture and TFP.Fracture and math.random(100) <= (Config.Injury.armFractureChance or 22) then TFP.Fracture('arm') end
    if Config.Senses.painFlash and not (TFP.PainkillerActive and TFP.PainkillerActive()) then
        AnimpostfxPlay('MinigameTransitionIn'); SetTimeout(220, function() AnimpostfxStop('MinigameTransitionIn') end)
    end
end)

-- Sturz → Bruch
CreateThread(function()
    local airStart
    while true do
        Wait(150)
        local ped = PlayerPedId()
        if IsPedFalling(ped) then if not airStart then airStart = GetEntityCoords(ped).z end
        elseif airStart then
            local fell = airStart - GetEntityCoords(ped).z; airStart = nil
            if fell >= (Config.Injury.fallFractureMin or 7.5) and not IsEntityDead(ped) then
                if math.random(100) <= (Config.Injury.fractureChance or 70) and TFP.Fracture then TFP.Fracture('leg') end
                if TFP.AddWound then TFP.AddWound('lleg', 'cut', 1, 10) elseif TFP.Bleed then TFP.Bleed(10) end
            end
        end
    end
end)

-- Verbinden / Schienen (F9/F10)
local function tryBandage()
    if (TFP.State.bleeding or 0) <= 0 then lib.notify({ title = 'Überleben', description = 'Du blutest gerade nicht.', type = 'inform' }); return end
    if lib.progressBar({ duration = 4000, label = 'Verbinden…', canCancel = true, disable = { move = true, car = true, combat = true },
            anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 } }) then TriggerServerEvent('clp_tfp:useBandage') end
end
local function trySplint()
    if not TFP.State.fracture then lib.notify({ title = 'Überleben', description = 'Du hast keinen Knochenbruch.', type = 'inform' }); return end
    if lib.progressBar({ duration = 5000, label = 'Schiene anlegen…', canCancel = true, disable = { move = true, car = true, combat = true },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } }) then TriggerServerEvent('clp_tfp:useSplint') end
end
RegisterCommand('bandage', tryBandage, false); RegisterCommand('splint', trySplint, false)
lib.addKeybind({ name = 'tfp_bandage', description = 'Verbinden', defaultKey = 'F9', onPressed = tryBandage })
lib.addKeybind({ name = 'tfp_splint', description = 'Schiene anlegen', defaultKey = 'F10', onPressed = trySplint })
TFP.Bandage = tryBandage; TFP.Splint = trySplint

RegisterNetEvent('clp_tfp:bandaged', function()
    if TFP.QuickTreat then TFP.QuickTreat('bandage') elseif TFP.ReduceBleed then TFP.ReduceBleed(Config.Medical.bandageReduce or 55) end
end)
RegisterNetEvent('clp_tfp:splinted', function() if TFP.HealFracture then TFP.HealFracture() end end)

-- Sichtbarer Atem bei Kälte
CreateThread(function()
    if not Config.Senses.coldBreath then return end
    RequestNamedPtfxAsset('core'); while not HasNamedPtfxAssetLoaded('core') do Wait(50) end
    while true do
        Wait(2500)
        if TFP.State.ready and (TFP.State.temperature or 100) < (Config.Senses.coldBreathTemp or 35) then
            local b = GetPedBoneCoords(PlayerPedId(), 31086, 0.0, 0.08, 0.0)
            UseParticleFxAssetNextCall('core')
            local fx = StartParticleFxLoopedAtCoord('ent_amb_smoke_foundry', b.x, b.y, b.z, 0.0, 0.0, 0.0, 0.12, false, false, false, false)
            Wait(900); StopParticleFxLooped(fx, false)
        end
    end
end)

-- ── Medizin-Items (ox_inventory client.export) ──
local MED = Config.Medical
local CLINIC = { dict = 'amb@world_human_clipboard@male@base', clip = 'base' }

exports('useBloodBag', function()
    if (TFP.State.blood or 100) >= 99 then lib.notify({ title = 'Medizin', description = 'Blutvolumen bereits voll.', type = 'inform' }); return false end
    if lib.progressBar({ duration = MED.transfuseTime or 8000, label = 'Transfusion…', canCancel = true, disable = { move = true, car = true, combat = true }, anim = CLINIC }) then
        if TFP.RestoreBlood then TFP.RestoreBlood(MED.bloodBagRestore or 45) end
        if TFP.ApplyMaxHealth then TFP.ApplyMaxHealth() end
        lib.notify({ title = 'Medizin', description = 'Blut aufgefüllt.', type = 'success' }); return
    end
    return false
end)
exports('usePainkillers', function()
    TFP.State.painkillerUntil = GetGameTimer() + (MED.painkillerMs or 90000)
    lib.notify({ title = 'Medizin', description = 'Schmerzmittel wirken.', type = 'success' })
end)
exports('useSutureKit', function()
    if (TFP.State.bleeding or 0) <= 0 then lib.notify({ title = 'Medizin', description = 'Du blutest gerade nicht.', type = 'inform' }); return false end
    if lib.progressBar({ duration = 6000, label = 'Wunde nähen…', canCancel = true, disable = { move = true, car = true, combat = true }, anim = CLINIC }) then
        if TFP.QuickTreat then TFP.QuickTreat('suture') elseif TFP.StopBleed then TFP.StopBleed() end; return
    end
    return false
end)
exports('useDisinfectant', function()
    TFP.State.disinfectUntil = GetGameTimer() + (MED.disinfectMs or 150000); TFP.State.sicknessRisk = 0
    if TFP.State.sicknessType == 'infection' and TFP.HealSicknessBy then TFP.HealSicknessBy(40) end
    for _, w in ipairs(TFP.State.wounds or {}) do w.infection = 0 end
    lib.notify({ title = 'Medizin', description = 'Wunden desinfiziert.', type = 'success' })
end)
exports('useTourniquet', function()
    if (TFP.State.bleeding or 0) <= 0 then lib.notify({ title = 'Medizin', description = 'Du blutest gerade nicht.', type = 'inform' }); return false end
    if TFP.QuickTreat then TFP.QuickTreat('tourniquet') elseif TFP.StopBleed then TFP.StopBleed() end
end)
exports('useSaline', function()
    if lib.progressBar({ duration = 6000, label = 'Infusion legen…', canCancel = true, disable = { move = true, car = true, combat = true }, anim = CLINIC }) then
        if TFP.RestoreBlood then TFP.RestoreBlood(MED.salineRestore or 30) end
        if TFP.ApplyMaxHealth then TFP.ApplyMaxHealth() end
        local p = PlayerPedId(); SetEntityHealth(p, math.min(GetEntityMaxHealth(p), GetEntityHealth(p) + 8))
        lib.notify({ title = 'Medizin', description = 'Kreislauf stabilisiert.', type = 'success' }); return
    end
    return false
end)
exports('useBurnOintment', function()
    for _, w in ipairs(TFP.State.wounds or {}) do if w.kind == 'burn' then w.bleed = 0; w.treated = true end end
    local p = PlayerPedId(); SetEntityHealth(p, math.min(GetEntityMaxHealth(p), GetEntityHealth(p) + (MED.burnHeal or 25)))
    lib.notify({ title = 'Medizin', description = 'Brandsalbe aufgetragen.', type = 'success' })
end)

-- Symptom-FX je Krankheit
CreateThread(function()
    local applied, lastMsg = nil, 0
    while true do
        Wait(1500)
        local S = TFP.State
        local sym = S.sicknessType and MED.symptoms and MED.symptoms[S.sicknessType]
        if S.ready and sym and (S.sickness or 0) >= (MED.symptomMinSeverity or 35) then
            if sym.tcMod then
                if applied ~= sym.tcMod then if applied then ClearTimecycleModifier() end SetTimecycleModifier(sym.tcMod); applied = sym.tcMod end
                SetTimecycleModifierStrength(math.min(0.85, (S.sickness / 100) * 0.85))
            elseif applied then ClearTimecycleModifier(); applied = nil end
            if (sym.thirstDrain or 0) > 0 then TriggerEvent('esx_status:remove', 'thirst', math.floor((Config.StatusMax or 1000000) * 0.001 * sym.thirstDrain)) end
            local now = GetGameTimer()
            if now - lastMsg > 15000 then
                lastMsg = now
                lib.notify({ title = 'Symptome', description = sym.msg or 'Dir geht es schlecht…', type = 'inform' })
                if sym.painFlash and not (TFP.PainkillerActive and TFP.PainkillerActive()) then
                    AnimpostfxPlay('MinigameTransitionIn'); SetTimeout(200, function() AnimpostfxStop('MinigameTransitionIn') end)
                end
            end
        elseif applied then ClearTimecycleModifier(); applied = nil end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    ClearTimecycleModifier(); SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
end)
