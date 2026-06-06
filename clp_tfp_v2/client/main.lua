-- clp_tfp · client/main — Survival-Sim & Zustand
-- §2.1: Hunger/Durst gehören esx_basicneeds → hier NUR lesen, nie zehren/zurückschreiben.
-- §2.2: eigener 1s-Thread treibt die Sim (nicht allein auf esx_status:onTick verlassen).
-- §2.3: ResetSurvival füllt Hunger/Durst auf + blendet HUD wieder ein (keine Tod-Schleife).

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}
TFP.State = {
    temperature = Config.Stats.temperature.default,
    wetness     = Config.Stats.wetness.default,
    stamina     = Config.Stats.stamina.default,
    sickness    = Config.Stats.sickness.default,
    sicknessType = nil, sicknessRisk = 0,
    bleeding = 0, blood = (Config.Blood and Config.Blood.default) or 100,
    fracture = false, fractureType = nil,
    painkillerUntil = 0, disinfectUntil = 0,
    forceFire = false, ready = false,
    hunger = 100, thirst = 100,
    env = { night = false, raining = false, rainLevel = 0, inWater = false, covered = false, nearFire = false, hot = false },
}

local SMAX = Config.StatusMax
local function u32(n) return n & 0xFFFFFFFF end
local function pctToVal(p) return math.floor(math.max(0, math.min(100, p)) / 100 * SMAX) end
local function clamp(v) return math.max(0, math.min(100, v)) end

local lastNotify = {}
local function warn(key, msg, typ)
    local now = GetGameTimer()
    if lastNotify[key] and now - lastNotify[key] < (Config.WarnCooldownMs or 8000) then return end
    lastNotify[key] = now
    lib.notify({ title = 'Überleben', description = msg, type = typ or 'inform' })
end

-- ─── Krankheit ────────────────────────────────────────────────────────────────
function TFP.AddSickness(stype, severity)
    TFP.State.sicknessType = stype
    TFP.State.sickness = math.max(TFP.State.sickness or 0, severity)
    TriggerEvent('esx_status:set', 'sickness', pctToVal(TFP.State.sickness))
    local label = (Config.Diseases[stype] and Config.Diseases[stype].label) or stype
    warn('sick', ('Du bist krank geworden (%s).'):format(label), 'error')
end
function TFP.HealSicknessBy(amount)
    TFP.State.sickness = math.max(0, (TFP.State.sickness or 0) - amount)
    if TFP.State.sickness < 1 then TFP.State.sicknessType = nil end
    TriggerEvent('esx_status:set', 'sickness', pctToVal(TFP.State.sickness))
end
function TFP.TryCure(cureKey)
    local t = TFP.State.sicknessType
    if t and Config.Diseases[t] and Config.Diseases[t].cure == cureKey then
        TFP.State.sickness = 0; TFP.State.sicknessType = nil
        TriggerEvent('esx_status:set', 'sickness', 0)
        lib.notify({ title = 'Überleben', description = 'Die Krankheit klingt ab.', type = 'success' }); return true
    end
    lib.notify({ title = 'Überleben', description = 'Das hilft gegen deine Krankheit nicht.', type = 'inform' }); return false
end

-- ─── Verletzungen (Skalar; Wunden-Modul aus Phase 3 überschreibt diese) ─────
function TFP.Bleed(amount)
    TFP.State.bleeding = math.min(100, (TFP.State.bleeding or 0) + amount)
    warn('bleed', 'Du blutest! Verbinde dich.', 'error')
end
function TFP.StopBleed() TFP.State.bleeding = 0; lib.notify({ title = 'Überleben', description = 'Blutung gestoppt.', type = 'success' }) end
function TFP.ReduceBleed(a) TFP.State.bleeding = math.max(0, (TFP.State.bleeding or 0) - a) end
function TFP.RestoreBlood(a) TFP.State.blood = math.min(100, (TFP.State.blood or 100) + a) end
function TFP.PainkillerActive() return (TFP.State.painkillerUntil or 0) > GetGameTimer() end

function TFP.Fracture(kind)
    if TFP.State.fracture then return end
    kind = kind or 'leg'
    TFP.State.fracture = true; TFP.State.fractureType = kind
    if kind == 'arm' then
        SetPlayerWeaponDamageModifier(PlayerId(), 0.65)
        warn('fracture', 'Armbruch! Waffenführung instabil — Schiene anlegen.', 'error')
    else
        local cs = Config.Injury.fractureClipset
        RequestClipSet(cs); local t = GetGameTimer()
        while not HasClipSetLoaded(cs) and GetGameTimer() - t < 2000 do Wait(10) end
        SetPedMovementClipset(PlayerPedId(), cs, 1.0)
        warn('fracture', 'Beinbruch! Du humpelst — Schiene anlegen.', 'error')
    end
    if TFP.OnFracture then TFP.OnFracture(kind) end -- Hook für Wunden-Modul (Phase 3)
end
function TFP.HealFracture()
    if TFP.State.fractureType == 'arm' then SetPlayerWeaponDamageModifier(PlayerId(), 1.0) end
    TFP.State.fracture = false; TFP.State.fractureType = nil
    ResetPedMovementClipset(PlayerPedId(), 0.0)
    if TFP.OnHealFracture then TFP.OnHealFracture() end
    lib.notify({ title = 'Überleben', description = 'Bruch geschient.', type = 'success' })
end

function TFP.ApplyMaxHealth()
    if not (Config.Blood and Config.Blood.enabled) then return end
    local ped = PlayerPedId()
    local b = clamp(TFP.State.blood or 100)
    local maxHp = math.floor(Config.Blood.minMaxHp + (Config.Blood.maxMaxHp - Config.Blood.minMaxHp) * (b / 100))
    SetEntityMaxHealth(ped, maxHp)
    if GetEntityHealth(ped) > maxHp then SetEntityHealth(ped, maxHp) end
end

-- ─── Reset (Respawn/Revive) — §2.3 ───────────────────────────────────────────
function TFP.ResetSurvival()
    local S = TFP.State
    if TFP.ClearWounds then TFP.ClearWounds() end
    S.bleeding, S.sickness, S.sicknessType, S.sicknessRisk = 0, 0, nil, 0
    S.wetness = Config.Stats.wetness.default
    S.temperature = Config.Stats.temperature.default
    S.stamina = Config.Stats.stamina.default
    S.blood = (Config.Blood and Config.Blood.default) or 100
    S.painkillerUntil, S.disinfectUntil = 0, 0
    if S.fracture then
        if S.fractureType == 'arm' then SetPlayerWeaponDamageModifier(PlayerId(), 1.0) end
        S.fracture, S.fractureType = false, nil
        ResetPedMovementClipset(PlayerPedId(), 0.0)
    end
    if TFP.ApplyMaxHealth then TFP.ApplyMaxHealth() end
    TriggerEvent('esx_status:set', 'sickness', 0)
    TriggerEvent('esx_status:set', 'wetness', pctToVal(Config.Stats.wetness.default))
    TriggerEvent('esx_status:set', 'temperature', pctToVal(Config.Stats.temperature.default))
    TriggerEvent('esx_status:set', 'stamina', pctToVal(Config.Stats.stamina.default))
    TriggerEvent('esx_status:set', 'hunger', pctToVal(80))   -- nicht leer & sofort sterbend erwachen
    TriggerEvent('esx_status:set', 'thirst', pctToVal(80))
    S.hunger, S.thirst = 80, 80
    if TFP.ShowHud then TFP.ShowHud() end
end

-- ─── Zusatz-Stats registrieren (kein Auto-Tick — wir steuern selbst) ─────────
AddEventHandler('esx_status:loaded', function()
    local function reg(name, defPct, color)
        TriggerEvent('esx_status:registerStatus', name, pctToVal(defPct), color, function() return true end, function() end)
    end
    reg('temperature', Config.Stats.temperature.default, '#7FB3FF')
    reg('wetness',     Config.Stats.wetness.default,     '#3A78C2')
    reg('stamina',     Config.Stats.stamina.default,     '#7FE07F')
    reg('sickness',    Config.Stats.sickness.default,    '#A05BD6')
end)

-- ─── Umwelt ──────────────────────────────────────────────────────────────────
local RAINY = {}
for _, w in ipairs(Config.RainyWeathers) do RAINY[u32(joaat(w))] = true end

local function isCovered(ped)
    if GetInteriorFromEntity(ped) ~= 0 then return true end
    local c = GetEntityCoords(ped)
    local h = StartShapeTestRay(c.x, c.y, c.z + 1.0, c.x, c.y, c.z + 30.0, 1, ped, 0)
    local _, hit = GetShapeTestResult(h)
    return hit == 1
end
local function isNearFire(ped)
    if TFP.State.forceFire then return true end
    local c = GetEntityCoords(ped)
    for _, m in ipairs(Config.FireModels) do
        if GetClosestObjectOfType(c.x, c.y, c.z, Config.FireRadius, joaat(m), false, false, false) ~= 0 then return true end
    end
    return false
end
local function updateEnv(ped)
    local hour = GetClockHours()
    local e = TFP.State.env
    e.night = (hour < 6 or hour >= 20)
    e.raining = RAINY[u32(GetPrevWeatherTypeHashName())] == true
    e.rainLevel = e.raining and 1.0 or 0.0
    e.inWater = IsEntityInWater(ped)
    e.covered = isCovered(ped)
    e.nearFire = isNearFire(ped)
    e.hot = (hour >= 11 and hour <= 15) and not e.covered and not e.inWater and not e.raining
end

-- ─── Zentrale Simulation ──────────────────────────────────────────────────────
local function runSim()
    if not ESX.PlayerLoaded then return end
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) then return end
    TFP.State.lastTick = GetGameTimer()

    updateEnv(ped)
    local e = TFP.State.env
    local cT, cW, cS, cK = Config.Stats.temperature, Config.Stats.wetness, Config.Stats.stamina, Config.Stats.sickness

    -- Hunger/Durst NUR lesen (esx_basicneeds besitzt den Drain)
    local hunger = clamp(TFP.State.hunger or 100)
    local thirst = clamp(TFP.State.thirst or 100)
    local temp = TFP.State.temperature or cT.default
    local wet  = TFP.State.wetness or 0
    local stam = TFP.State.stamina or 100
    local sick = TFP.State.sickness or 0

    -- Nässe (wasserdichte Kleidung verringert den Zuwachs — Phase 6)
    local wpf = (TFP.ClothingWaterproof and (1 - TFP.ClothingWaterproof() / 100)) or 1.0
    if e.inWater then wet = wet + cW.swimGain * wpf
    elseif e.raining and not e.covered then wet = wet + cW.rainGain * e.rainLevel * wpf
    else
        local dry = cW.dryBase
        if e.nearFire then dry = dry + cW.dryFireBonus end
        if e.hot then dry = dry + cW.drySunBonus end
        wet = wet - dry
    end
    wet = clamp(wet)

    -- Temperatur (Ziel + Annäherung)
    local target = cT.baseTarget
    if e.night then target = target - cT.nightDrop end
    if e.raining and not e.covered then target = target - cT.rainDrop * e.rainLevel end
    if e.inWater then target = target - cT.waterDrop end
    target = target - wet * cT.wetFactor
    if e.nearFire then target = target + cT.fireBoost end
    local clothing = cT.clothingBoost
    if cT.warmItem and (exports.ox_inventory:Search('count', cT.warmItem) or 0) > 0 then clothing = cT.clothingBoostWarm or clothing end
    target = target + clothing
    if TFP.ClothingStat then target = target + TFP.ClothingStat('insulation') * ((Config.Clothing and Config.Clothing.insulationToWarmth) or 0.6) end -- Kleidung (Phase 6)
    target = clamp(target)
    temp = clamp(temp + (target - temp) * cT.approachRate)

    -- Krankheit (kalt + nass → Erkältung)
    if temp <= cT.slow and wet >= 50 then
        TFP.State.sicknessRisk = TFP.State.sicknessRisk + cK.coldWetRisk
        if TFP.State.sicknessRisk >= cK.riskThreshold and sick < 1 then
            sick = 5; TFP.State.sicknessType = 'cold'; TFP.State.sicknessRisk = 0
            warn('sick', ('Dir wird übel — du wirst krank (%s).'):format(Config.Diseases.cold.label), 'error')
        end
    else
        TFP.State.sicknessRisk = math.max(0, TFP.State.sicknessRisk - cK.coldWetRisk)
    end
    if sick >= 1 then
        if temp <= cT.warn then sick = sick + cK.riseCold elseif temp >= cK.warmTemp then sick = sick - cK.fallWarm end
        sick = clamp(sick); if sick < 1 then TFP.State.sicknessType = nil end
    end

    -- Stamina
    if IsPedSprinting(ped) then stam = stam - cS.sprintDrain
    elseif IsPedSwimming(ped) then stam = stam - cS.swimDrain
    else
        local regen = cS.regen
        if hunger < cS.lowNeedPct or thirst < cS.lowNeedPct then regen = cS.lowRegen end
        if sick >= cK.hpThreshold then regen = math.floor(regen / 2) end
        stam = stam + regen
    end
    stam = clamp(stam)

    -- Effekte / HP
    local dmg = 0
    if temp <= cT.critical then dmg = dmg + cT.criticalHpLoss; warn('cold', 'Du erfrierst! Such Wärme.', 'error')
    elseif temp <= cT.warn then warn('coldwarn', 'Dir wird kalt — trockne dich, such Wärme.', 'inform') end
    if sick >= cK.hpThreshold then dmg = dmg + cK.hpLoss end
    if hunger <= 0 or thirst <= 0 then
        warn('starve', (hunger <= 0) and 'Du verhungerst — iss etwas!' or 'Du verdurstest — trink etwas!', 'error')
        dmg = dmg + (Config.Stats.starveHpLoss or 0)  -- 0: esx_basicneeds bestraft 0% selbst
    end

    -- Blutung (Wunden-Modul übernimmt in Phase 3; hier Skalar-Fallback)
    if TFP.WoundsTick then TFP.State.sickness = sick; TFP.WoundsTick(); sick = TFP.State.sickness or sick end
    if (TFP.State.bleeding or 0) > 0 then
        dmg = dmg + Config.Injury.bleedHpPerTick * (TFP.State.bleeding / 25)
        if not TFP.WoundsTick then
            TFP.State.bleeding = math.max(0, TFP.State.bleeding - Config.Injury.bleedClotPerTick)
            if sick < 1 and TFP.State.bleeding >= (Config.Injury.infectBleedMin or 35)
               and (TFP.State.disinfectUntil or 0) < GetGameTimer()
               and math.random(100) <= (Config.Injury.infectChance or 5) then
                TFP.AddSickness('infection', 8); sick = TFP.State.sickness
            end
        end
    end

    -- Blut
    if Config.Blood and Config.Blood.enabled then
        local cB = Config.Blood
        if (TFP.State.bleeding or 0) > 0 then
            TFP.State.blood = math.max(0, (TFP.State.blood or 100) - cB.lossPerTick * (TFP.State.bleeding / 25))
        elseif hunger >= cB.regenNeedPct and thirst >= cB.regenNeedPct then
            TFP.State.blood = math.min(100, (TFP.State.blood or 100) + cB.regenPerTick)
        end
        if (TFP.State.blood or 100) <= cB.criticalLow then dmg = dmg + cB.shockHpLoss; warn('blood', 'Schwerer Blutverlust!', 'error') end
        TFP.ApplyMaxHealth()
    end

    if dmg > 0 then SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - math.floor(dmg + 0.5))) end
    if e.hot then TriggerEvent('esx_status:remove', 'thirst', math.floor(SMAX * 0.0015)) end

    -- zurückschreiben (NICHT Hunger/Durst — §2.1)
    TriggerEvent('esx_status:set', 'temperature', pctToVal(temp))
    TriggerEvent('esx_status:set', 'wetness', pctToVal(wet))
    TriggerEvent('esx_status:set', 'stamina', pctToVal(stam))
    TriggerEvent('esx_status:set', 'sickness', pctToVal(sick))
    TFP.State.temperature, TFP.State.wetness, TFP.State.stamina, TFP.State.sickness = temp, wet, stam, sick
    TFP.State.hunger, TFP.State.thirst = hunger, thirst
    TFP.State.ready = true

    -- Vignetten
    if TFP.UpdateFx then
        local hpFrac = GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))
        local redFx = math.max(0.0, (0.5 - hpFrac) / 0.5, math.min(1.0, (TFP.State.bleeding or 0) / 60))
        if TFP.PainkillerActive() then redFx = redFx * 0.35 end
        local coldFx = (temp < cT.warn) and math.min(1.0, (cT.warn - temp) / cT.warn) or 0.0
        TFP.UpdateFx(redFx, coldFx)
    end
end

-- Treiber: 1s-Thread (Haupt) + onTick (falls vorhanden), entdoppelt
local lastSimRun = 0
local function driveSim()
    local now = GetGameTimer()
    if now - lastSimRun < 800 then return end
    lastSimRun = now
    runSim()
end

AddEventHandler('esx_status:onTick', function(data)
    if type(data) == 'table' then
        for _, s in ipairs(data) do
            if s.name == 'hunger' then TFP.State.hunger = s.percent
            elseif s.name == 'thirst' then TFP.State.thirst = s.percent end
        end
    end
    driveSim()
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    while true do
        TriggerEvent('esx_status:getStatus', 'hunger', function(s) if s and s.val then TFP.State.hunger = math.floor(s.val / SMAX * 100) end end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s) if s and s.val then TFP.State.thirst = math.floor(s.val / SMAX * 100) end end)
        driveSim()
        Wait(Config.TickMs or 1000)
    end
end)

-- Per-Frame: Sprint-Sperre bei leerer Stamina, Tempo bei Kälte/Bruch
CreateThread(function()
    while true do
        local wait = 500
        if TFP.State.ready and ESX.PlayerLoaded then
            local ped = PlayerPedId()
            local active = false
            if TFP.State.stamina <= 1 then DisableControlAction(0, 21, true); active = true end
            if TFP.State.temperature <= Config.Stats.temperature.slow then SetPedMoveRateOverride(ped, Config.Stats.temperature.slowMoveRate); active = true end
            if TFP.State.fracture then
                DisableControlAction(0, 21, true)
                if TFP.State.fractureType ~= 'arm' then SetPedMoveRateOverride(ped, TFP.PainkillerActive() and 0.9 or 0.7) end
                active = true
            elseif TFP.State.legWounded then
                SetPedMoveRateOverride(ped, TFP.PainkillerActive() and 0.95 or 0.85); active = true
            end
            if active then wait = 0 end
        end
        Wait(wait)
    end
end)

-- Keine passive HP-Regeneration
CreateThread(function()
    while true do Wait(2000); if Config.Hardcore and Config.Hardcore.noPassiveRegen then SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0) end end
end)

-- HUD-Thread: sendet IMMER (auch tot/downed) → HUD hängt nie
CreateThread(function()
    while true do
        Wait(1000)
        if ESX.PlayerLoaded and TFP.UpdateHud then
            local ped = PlayerPedId()
            TFP.UpdateHud({
                health = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100),
                blood = math.floor(TFP.State.blood or 100),
                hunger = math.floor(TFP.State.hunger or 100), thirst = math.floor(TFP.State.thirst or 100),
                temperature = math.floor(TFP.State.temperature or 100), wetness = math.floor(TFP.State.wetness or 0),
                stamina = math.floor(TFP.State.stamina or 100), sickness = math.floor(TFP.State.sickness or 0),
                bleeding = TFP.State.bleeding or 0, fracture = TFP.State.fracture and 100 or 0,
                fractureType = TFP.State.fractureType, sicknessType = TFP.State.sicknessType,
                fatigue = math.floor(TFP.State.fatigue or 0), oxygen = math.floor(TFP.State.oxygen or 100),
                wounds = #(TFP.State.wounds or {}),
            })
        end
    end
end)

-- ─── Selbst-Revive / Diagnose / Hilfe ────────────────────────────────────────
local function tfpRevive()
    local ped = PlayerPedId(); local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    ClearPedTasksImmediately(ped); ClearPedBloodDamage(ped); SetPlayerInvincible(PlayerId(), false)
    if TFP.SetDowned then TFP.SetDowned(false) end
    if TFP.ResetSurvival then TFP.ResetSurvival() end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    lib.notify({ title = 'TFP', description = 'Wiederbelebt & geheilt.', type = 'success' })
end
RegisterCommand('reviveme', tfpRevive, false)
RegisterCommand('tfprevive', tfpRevive, false)
TFP.SelfRevive = tfpRevive

RegisterCommand('tfppos', function()
    local c = GetEntityCoords(PlayerPedId())
    local s = ('vec3(%.1f, %.1f, %.1f),'):format(c.x, c.y, c.z)
    lib.setClipboard(s); lib.notify({ title = 'Position kopiert', description = s, type = 'success' })
end, false)

function TFP.Diag()
    local s = TFP.State; local ped = PlayerPedId()
    local hp = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100)
    local now = GetGameTimer()
    local tickAge = s.lastTick and (now - s.lastTick) or -1
    local tickLine = (tickAge < 0) and '**onTick:** NIE gefeuert ⚠️'
        or ('**onTick:** vor %d ms %s'):format(tickAge, tickAge > 4000 and '⚠️' or '✓')
    lib.alertDialog({ header = '🔧 TFP Diagnose', centered = true, size = 'md', content = ([[
%s
**HP** %d%% · **Blut** %s
**Hunger** %s · **Durst** %s
**Temp** %s · **Nässe** %s · **Ausdauer** %s · **Krank** %s · **Blutung** %s
**PlayerLoaded** %s · **HUD** %s
esx_status=%s · esx_basicneeds=%s · ox_target=%s · ox_inventory=%s]]):format(tickLine, hp,
        tostring(s.blood), tostring(s.hunger), tostring(s.thirst),
        tostring(s.temperature), tostring(s.wetness), tostring(s.stamina), tostring(s.sickness), tostring(s.bleeding),
        tostring(ESX.PlayerLoaded), tostring(TFP.UpdateHud ~= nil),
        GetResourceState('esx_status'), GetResourceState('esx_basicneeds'),
        GetResourceState('ox_target'), GetResourceState('ox_inventory')) })
end
RegisterCommand('tfpdiag', TFP.Diag, false)

function TFP.Help()
    lib.alertDialog({
        header = '🆘 TFP — Steuerung & Tipps',
        content = [[
**Menü:** `F5` (oder `/survival`) — Überleben, Handwerk, Bauen, Stamm, Admin.
**Sammeln:** Bäume/Felsen/Büsche anvisieren (ox_target). Bäume brauchen eine **Axt** (nutzt sich ab).
**Handwerk:** `/craft` (Hand) · an Werkbank/Lagerfeuer/Schmelzofen mehr Rezepte.
**Verletzung:** `/bandage` (`F9`) bei Blutung · `/splint` (`F10`) bei Bruch · Nähset/Blutbeutel/Schmerzmittel/Antibiotika aus dem Inventar.
**Essen/Trinken:** Items benutzen — rohes Fleisch/Fisch **am Feuer braten**, dreckiges Wasser **abkochen**.
**Kleidung:** `/kleidung` (`F7`) — Wärme · Nässe · Panzer · Tarnung.
**Stamm:** `/tribe` — Mitglieder, Ränge, gemeinsame Truhe.
**Flucht-Ziel:** Tracker oben links · `K` oder `/ziel` ein-/ausblenden · `/tagebuch` für Lore.
**Respawn:** Schlafsack auslegen oder ein Bett als Spawnpunkt setzen.
**Admin:** `/tfpadmin` · Koords erfassen: `/tfppos` (vec3) · `/tfpmodel` (Prop-Hash).]],
        centered = true, size = 'md',
    })
end
RegisterCommand('tfphelp', TFP.Help, false)
