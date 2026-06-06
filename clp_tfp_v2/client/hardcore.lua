-- clp_tfp · client/hardcore — Müdigkeit & Schlaf, Tauchen/Sauerstoff, Waffen-Realismus

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}
TFP.State = TFP.State or {}
TFP.State.fatigue = TFP.State.fatigue or 0
TFP.State.oxygen  = TFP.State.oxygen or 100

local CF = Config.Fatigue or {}
local CO = Config.Oxygen or {}
local CW = Config.WeaponRealism or {}

-- ─── Müdigkeit steigt über Zeit ──────────────────────────────────────────────
if CF.enabled then
    CreateThread(function()
        while true do
            Wait(CF.tickMs or 30000)
            if ESX.PlayerLoaded and not TFP.State._sleeping and not IsPedDeadOrDying(PlayerPedId(), true) then
                TFP.State.fatigue = math.min(100, (TFP.State.fatigue or 0) + (CF.risePerTick or 1.0))
            end
        end
    end)
end

-- ─── Schlafen (vom Bett/Schlafsack) — Zeit vorspulen + erholen ───────────────
function TFP.Sleep()
    if TFP.State._sleeping then return end
    if not CF.enabled then lib.notify({ description = 'Schlafen ist deaktiviert.', type = 'inform' }); return end
    TFP.State._sleeping = true
    lib.notify({ title = 'Schlafen', description = 'Du legst dich schlafen…', type = 'inform' })
    DoScreenFadeOut(900); Wait(1100)
    NetworkOverrideClockTime((CF.sleepToHour or 6), 0, 0)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + (CF.healOnSleep or 25)))
    TFP.State.fatigue = 0
    Wait(2500); DoScreenFadeIn(1200)
    lib.notify({ title = 'Schlafen', description = 'Ausgeruht — ein neuer Tag auf der Insel.', type = 'success' })
    TFP.State._sleeping = false
end

-- ─── Tauchen / Sauerstoff ────────────────────────────────────────────────────
if CO.enabled then
    CreateThread(function()
        while true do
            Wait(1000)
            local ped = PlayerPedId()
            if ESX.PlayerLoaded and not IsPedDeadOrDying(ped, true) then
                if IsPedSwimmingUnderWater(ped) then
                    TFP.State.oxygen = math.max(0, (TFP.State.oxygen or 100) - (CO.drainPerSec or 12))
                    if TFP.State.oxygen <= 0 then
                        SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - (CO.dmgPerSec or 6)))
                    end
                else
                    TFP.State.oxygen = math.min(100, (TFP.State.oxygen or 100) + (CO.regainPerSec or 35))
                end
            end
        end
    end)
end

-- ─── Waffen-Realismus: kein Fadenkreuz + Zittern bei Erschöpfung/Armbruch ─────
CreateThread(function()
    local shaking = false
    while true do
        local w = 500
        if ESX.PlayerLoaded then
            local ped = PlayerPedId()
            -- nur bei gezogener Waffe per-Frame laufen (Performance)
            if GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED` then
                w = 0
                if CW.noCrosshair then HideHudComponentThisFrame(14) end -- Fadenkreuz/Reticle
                local want = false
                if CW.swayOnTired and IsPlayerFreeAiming(PlayerId()) then
                    local tired   = (TFP.State.stamina or 100) < (CW.swayStamina or 25)
                    local armhurt = (TFP.State.fracture and TFP.State.fractureType == 'arm') or TFP.State.armWounded
                    want = tired or armhurt
                end
                if want and not shaking then ShakeGameplayCam('HAND_SHAKE', 0.7); shaking = true
                elseif not want and shaking then StopGameplayCamShaking(true); shaking = false end
            elseif shaking then StopGameplayCamShaking(true); shaking = false end
        end
        Wait(w)
    end
end)
