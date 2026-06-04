-- clp_tfp · survival · Phase 1 / Slice 1
-- Hybrid-Modell: Hunger/Durst laufen über esx_basicneeds/esx_status.
-- Wir registrieren die Zusatz-Stats temperature/wetness/stamina/sickness (persistieren
-- automatisch in users.status) und steuern ALLE Berechnungen zentral in esx_status:onTick.

local ESX = exports['es_extended']:getSharedObject()

TFP = TFP or {}
TFP.State = {
    temperature  = Config.Stats.temperature.default,
    wetness      = Config.Stats.wetness.default,
    stamina      = Config.Stats.stamina.default,
    sickness     = Config.Stats.sickness.default,
    sicknessType = nil,
    sicknessRisk = 0,
    bleeding     = 0,
    blood        = Config.Blood and Config.Blood.default or 100,
    fracture     = false,
    fractureType = nil,        -- 'leg' | 'arm'
    painkillerUntil = 0,       -- GetGameTimer() bis Schmerzmittel wirkt
    disinfectUntil  = 0,       -- GetGameTimer() bis Desinfektion-Schutz endet
    forceFire    = false,
    ready        = false,
    env = { night = false, raining = false, rainLevel = 0, inWater = false, covered = false, nearFire = false, hot = false },
}

local SMAX = Config.StatusMax
local function u32(n) return n & 0xFFFFFFFF end                 -- Hash-Vorzeichen normalisieren
local function pctToVal(p) return math.floor(math.max(0, math.min(100, p)) / 100 * SMAX) end
local function clamp(v) return math.max(0, math.min(100, v)) end

-- ─── Notify mit Cooldown ─────────────────────────────────────────────────────
local lastNotify = {}
local function warn(key, msg, typ)
    local now = GetGameTimer()
    if lastNotify[key] and now - lastNotify[key] < Config.WarnCooldownMs then return end
    lastNotify[key] = now
    lib.notify({ title = 'Überleben', description = msg, type = typ or 'inform' })
end

-- ─── Krankheit setzen / heilen (von consume.lua genutzt) ──────────────────────
function TFP.AddSickness(stype, severity)
    local nv = math.max(TFP.State.sickness or 0, severity)
    TFP.State.sicknessType = stype
    TFP.State.sickness = nv
    TriggerEvent('esx_status:set', 'sickness', pctToVal(nv))
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
        TFP.State.sickness = 0
        TFP.State.sicknessType = nil
        TriggerEvent('esx_status:set', 'sickness', 0)
        lib.notify({ title = 'Überleben', description = 'Die Krankheit klingt ab — du fühlst dich besser.', type = 'success' })
        return true
    end
    lib.notify({ title = 'Überleben', description = 'Das hilft gegen deine aktuelle Krankheit nicht.', type = 'inform' })
    return false
end

-- ─── Verletzungen (von realism.lua genutzt) ──────────────────────────────────
function TFP.Bleed(amount)
    TFP.State.bleeding = math.min(100, (TFP.State.bleeding or 0) + amount)
    warn('bleed', 'Du blutest! Verbinde dich (Verband).', 'error')
end

function TFP.StopBleed()
    TFP.State.bleeding = 0
    lib.notify({ title = 'Überleben', description = 'Blutung gestoppt.', type = 'success' })
end

function TFP.Fracture(kind)
    if TFP.State.fracture then return end
    kind = kind or 'leg'
    TFP.State.fracture = true
    TFP.State.fractureType = kind
    if kind == 'arm' then
        SetPlayerWeaponDamageModifier(PlayerId(), 0.65) -- zittrige, schwächere Waffenführung
        warn('fracture', 'Armbruch! Deine Waffenführung ist instabil — leg eine Schiene an.', 'error')
    else
        local cs = Config.Injury.fractureClipset
        RequestClipSet(cs)
        local t = GetGameTimer()
        while not HasClipSetLoaded(cs) and GetGameTimer() - t < 2000 do Wait(10) end
        SetPedMovementClipset(PlayerPedId(), cs, 1.0)
        warn('fracture', 'Beinbruch! Du humpelst — leg eine Schiene an.', 'error')
    end
end

function TFP.HealFracture()
    if TFP.State.fractureType == 'arm' then SetPlayerWeaponDamageModifier(PlayerId(), 1.0) end
    TFP.State.fracture = false
    TFP.State.fractureType = nil
    ResetPedMovementClipset(PlayerPedId(), 0.0)
    lib.notify({ title = 'Überleben', description = 'Bruch geschient — du kannst wieder normal agieren.', type = 'success' })
end

-- Schmerzmittel aktiv?
function TFP.PainkillerActive()
    return (TFP.State.painkillerUntil or 0) > GetGameTimer()
end

-- Blutung teilweise senken (Verband) / Blut auffüllen (Transfusion)
function TFP.ReduceBleed(amount)
    TFP.State.bleeding = math.max(0, (TFP.State.bleeding or 0) - amount)
end
function TFP.RestoreBlood(amount)
    TFP.State.blood = math.min(100, (TFP.State.blood or 100) + amount)
end

-- Max-HP an den Blutstand koppeln (Blut 0..100 -> Max-HP min..max)
function TFP.ApplyMaxHealth()
    if not (Config.Blood and Config.Blood.enabled) then return end
    local ped = PlayerPedId()
    local b = math.max(0, math.min(100, TFP.State.blood or 100))
    local maxHp = math.floor(Config.Blood.minMaxHp + (Config.Blood.maxMaxHp - Config.Blood.minMaxHp) * (b / 100))
    SetEntityMaxHealth(ped, maxHp)
    if GetEntityHealth(ped) > maxHp then SetEntityHealth(ped, maxHp) end
end

-- Survival-Zustand komplett zurücksetzen (nach Respawn/Revive).
-- Verhindert Todesschleifen durch weiterlaufende Blutung/Krankheit/Bruch/Kälte.
function TFP.ResetSurvival()
    local S = TFP.State
    S.bleeding     = 0
    S.sickness     = 0
    S.sicknessType = nil
    S.sicknessRisk = 0
    S.wetness      = Config.Stats.wetness.default
    S.temperature  = Config.Stats.temperature.default
    S.stamina      = Config.Stats.stamina.default
    S.blood        = (Config.Blood and Config.Blood.default) or 100
    S.painkillerUntil = 0
    S.disinfectUntil  = 0
    if S.fracture then
        if S.fractureType == 'arm' then SetPlayerWeaponDamageModifier(PlayerId(), 1.0) end
        S.fracture = false
        S.fractureType = nil
        ResetPedMovementClipset(PlayerPedId(), 0.0)
    end
    if TFP.ApplyMaxHealth then TFP.ApplyMaxHealth() end
    TriggerEvent('esx_status:set', 'sickness',    0)
    TriggerEvent('esx_status:set', 'wetness',     pctToVal(Config.Stats.wetness.default))
    TriggerEvent('esx_status:set', 'temperature', pctToVal(Config.Stats.temperature.default))
    TriggerEvent('esx_status:set', 'stamina',     pctToVal(Config.Stats.stamina.default))
end

-- ─── Stats registrieren (No-op-Tick; Logik zentral in onTick) ─────────────────
local RAINY = {}
for _, w in ipairs(Config.RainyWeathers) do RAINY[u32(joaat(w))] = true end

AddEventHandler('esx_status:loaded', function()
    local function reg(name, defPct, color)
        TriggerEvent('esx_status:registerStatus', name, pctToVal(defPct), color,
            function() return true end,   -- visible (esx_status-eigenes HUD ist deaktiviert)
            function() end)               -- kein Auto-Tick; wir steuern selbst
    end
    reg('temperature', Config.Stats.temperature.default, '#7FB3FF')
    reg('wetness',     Config.Stats.wetness.default,     '#3A78C2')
    reg('stamina',     Config.Stats.stamina.default,     '#7FE07F')
    reg('sickness',    Config.Stats.sickness.default,    '#A05BD6')
    if Config.Debug then print('^2[clp_tfp]^7 Survival-Stats registriert.') end
end)

-- ─── Umwelt erfassen ──────────────────────────────────────────────────────────
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
        if GetClosestObjectOfType(c.x, c.y, c.z, Config.FireRadius, joaat(m), false, false, false) ~= 0 then
            return true
        end
    end
    return false
end

local function updateEnv(ped)
    local hour = GetClockHours()
    local e = TFP.State.env
    e.night     = (hour < 6 or hour >= 20)
    e.raining   = RAINY[u32(GetPrevWeatherTypeHashName())] == true
    e.rainLevel = e.raining and 1.0 or 0.0
    e.inWater   = IsEntityInWater(ped)
    e.covered   = isCovered(ped)
    e.nearFire  = isNearFire(ped)
    e.hot       = (hour >= 11 and hour <= 15) and not e.covered and not e.inWater and not e.raining
end

-- ─── Zentrale Simulation ──────────────────────────────────────────────────────
-- WICHTIG: läuft über einen EIGENEN 1s-Thread (siehe unten), NICHT abhängig von
-- esx_status:onTick (feuert auf manchen Builds nie). Hunger/Durst werden selbst gezehrt.
local function runSim()
    if not ESX.PlayerLoaded then return end
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) then return end
    TFP.State.lastTick = GetGameTimer()

    updateEnv(ped)
    local e   = TFP.State.env
    local cT, cW, cS, cK = Config.Stats.temperature, Config.Stats.wetness, Config.Stats.stamina, Config.Stats.sickness

    -- Hunger/Durst: aktueller Wert (vom getStatus-Fetch im Thread) minus Eigen-Zehrung
    local hunger = clamp((TFP.State.hunger or 100) - (Config.Stats.hungerDrain or 0.15))
    local thirst = clamp((TFP.State.thirst or 100) - (Config.Stats.thirstDrain or 0.22))
    local temp   = TFP.State.temperature or cT.default
    local wet    = TFP.State.wetness     or 0
    local stam   = TFP.State.stamina     or 100
    local sick   = TFP.State.sickness    or 0

    -- ── Nässe ──
    if e.inWater then
        wet = wet + cW.swimGain
    elseif e.raining and not e.covered then
        wet = wet + cW.rainGain * e.rainLevel
    else
        local dry = cW.dryBase
        if e.nearFire then dry = dry + cW.dryFireBonus end
        if e.hot then dry = dry + cW.drySunBonus end
        wet = wet - dry
    end
    wet = clamp(wet)

    -- ── Temperatur: Zielwert + langsame Annäherung ──
    local target = cT.baseTarget
    if e.night then target = target - cT.nightDrop end
    if e.raining and not e.covered then target = target - cT.rainDrop * e.rainLevel end
    if e.inWater then target = target - cT.waterDrop end
    target = target - wet * cT.wetFactor
    if e.nearFire then target = target + cT.fireBoost end
    -- Isolierung: Fellkleidung (warm_clothing) im Inventar wärmt deutlich mehr
    local clothing = cT.clothingBoost
    if cT.warmItem and (exports.ox_inventory:Search('count', cT.warmItem) or 0) > 0 then
        clothing = cT.clothingBoostWarm or clothing
    end
    target = target + clothing
    target = clamp(target)
    temp = clamp(temp + (target - temp) * cT.approachRate)

    -- ── Krankheit (Slice 1: Erkältung aus kalt + nass) ──
    if temp <= cT.slow and wet >= 50 then
        TFP.State.sicknessRisk = TFP.State.sicknessRisk + cK.coldWetRisk
        if TFP.State.sicknessRisk >= cK.riskThreshold and sick < 1 then
            sick = 5
            TFP.State.sicknessType = 'cold'
            TFP.State.sicknessRisk = 0
            warn('sick', ('Dir wird übel — du wirst krank (%s).'):format(Config.Diseases.cold.label), 'error')
        end
    else
        TFP.State.sicknessRisk = math.max(0, TFP.State.sicknessRisk - cK.coldWetRisk)
    end
    if sick >= 1 then
        if temp <= cT.warn then
            sick = sick + cK.riseCold
        elseif temp >= cK.warmTemp then
            sick = sick - cK.fallWarm
        end
        sick = clamp(sick)
        if sick < 1 then TFP.State.sicknessType = nil end
    end

    -- ── Stamina ──
    if IsPedSprinting(ped) then
        stam = stam - cS.sprintDrain
    elseif IsPedSwimming(ped) then
        stam = stam - cS.swimDrain
    else
        local regen = cS.regen
        if hunger < cS.lowNeedPct or thirst < cS.lowNeedPct then regen = cS.lowRegen end
        if sick >= cK.hpThreshold then regen = math.floor(regen / 2) end
        stam = stam + regen
    end
    stam = clamp(stam)
    -- Müdigkeit senkt das Stamina-Limit
    if Config.Fatigue and Config.Fatigue.enabled then
        stam = math.min(stam, 100 - math.max(0, (TFP.State.fatigue or 0) - (Config.Fatigue.capStaminaAbove or 60)))
    end

    -- ── Effekte: HP / Warnungen ──
    local dmg = 0
    if temp <= cT.critical then
        dmg = dmg + cT.criticalHpLoss
        warn('cold', 'Du erfrierst! Suche sofort Wärme.', 'error')
    elseif temp <= cT.warn then
        warn('coldwarn', 'Dir wird kalt — trockne dich und such Wärme.', 'inform')
    end
    if sick >= cK.hpThreshold then dmg = dmg + cK.hpLoss end
    if hunger <= 0 or thirst <= 0 then
        dmg = dmg + (Config.Stats.starveHpLoss or 1)
        warn('starve', (hunger <= 0) and 'Du verhungerst — iss etwas!' or 'Du verdurstest — trink etwas!', 'error')
    end
    if TFP.State.bleeding > 0 then
        dmg = dmg + Config.Injury.bleedHpPerTick * (TFP.State.bleeding / 25)
        TFP.State.bleeding = math.max(0, TFP.State.bleeding - Config.Injury.bleedClotPerTick)
        -- starke, unbehandelte Blutung kann sich infizieren (außer frisch desinfiziert)
        if sick < 1 and TFP.State.bleeding >= (Config.Injury.infectBleedMin or 35)
           and (TFP.State.disinfectUntil or 0) < GetGameTimer()
           and math.random(100) <= (Config.Injury.infectChance or 5) then
            TFP.AddSickness('infection', 8)
            sick = TFP.State.sickness
        end
    end

    -- ── Blut-System: Verlust durch Blutung, langsame Erholung, Schock bei Tiefstand ──
    if Config.Blood and Config.Blood.enabled then
        local cB = Config.Blood
        if (TFP.State.bleeding or 0) > 0 then
            TFP.State.blood = math.max(0, (TFP.State.blood or 100) - cB.lossPerTick * (TFP.State.bleeding / 25))
        elseif hunger >= cB.regenNeedPct and thirst >= cB.regenNeedPct then
            TFP.State.blood = math.min(100, (TFP.State.blood or 100) + cB.regenPerTick)
        end
        if (TFP.State.blood or 100) <= cB.criticalLow then
            dmg = dmg + cB.shockHpLoss
            warn('blood', 'Schwerer Blutverlust — dir wird schwarz vor Augen!', 'error')
        end
        TFP.ApplyMaxHealth()
    end

    if dmg > 0 then
        SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - math.floor(dmg + 0.5)))
    end
    if e.hot then
        TriggerEvent('esx_status:remove', 'thirst', math.floor(SMAX * 0.004)) -- Hitze macht durstig
    end

    -- ── zurückschreiben + State spiegeln ──
    TriggerEvent('esx_status:set', 'temperature', pctToVal(temp))
    TriggerEvent('esx_status:set', 'wetness',     pctToVal(wet))
    TriggerEvent('esx_status:set', 'stamina',     pctToVal(stam))
    TriggerEvent('esx_status:set', 'sickness',    pctToVal(sick))
    TriggerEvent('esx_status:set', 'hunger',      pctToVal(hunger))
    TriggerEvent('esx_status:set', 'thirst',      pctToVal(thirst))
    TFP.State.temperature, TFP.State.wetness, TFP.State.stamina, TFP.State.sickness = temp, wet, stam, sick
    TFP.State.hunger, TFP.State.thirst = hunger, thirst  -- für HUD-Thread + nächste Runde
    TFP.State.ready = true

    -- ── Realismus-Vignetten: rot bei niedriger HP, blau bei Kälte ──
    if TFP.UpdateFx then
        local hpFrac = GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))
        local redFx = math.max(0.0, (0.5 - hpFrac) / 0.5, math.min(1.0, (TFP.State.bleeding or 0) / 60))
        if TFP.PainkillerActive and TFP.PainkillerActive() then redFx = redFx * 0.35 end -- Schmerzmittel dämpft
        local coldFx = (temp < cT.warn) and math.min(1.0, (cT.warn - temp) / cT.warn) or 0.0
        TFP.UpdateFx(redFx, coldFx)
    end

    -- ── HUD ──
    if TFP.UpdateHud then
        TFP.UpdateHud({
            health = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100),
            blood = math.floor(TFP.State.blood or 100),
            hunger = hunger, thirst = thirst, temperature = temp,
            wetness = wet, stamina = stam, sickness = sick,
            bleeding = TFP.State.bleeding, fracture = TFP.State.fracture and 100 or 0,
            fractureType = TFP.State.fractureType,
            sicknessType = TFP.State.sicknessType,
            fatigue = math.floor(TFP.State.fatigue or 0),
            oxygen = math.floor(TFP.State.oxygen or 100),
        })
    end
end

-- Treiber: eigener 1s-Thread (Hauptantrieb) + esx_status:onTick (falls vorhanden), entdoppelt
local lastSimRun = 0
local function driveSim()
    local now = GetGameTimer()
    if now - lastSimRun < 800 then return end  -- verhindert Doppel-Lauf, falls beide Treiber feuern
    lastSimRun = now
    runSim()
end

AddEventHandler('esx_status:onTick', function() driveSim() end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    while true do
        -- Hunger/Durst aus esx_status holen (fängt Essen/Trinken ab), dann Sim treiben
        TriggerEvent('esx_status:getStatus', 'hunger', function(s)
            if s and s.val then TFP.State.hunger = math.floor(s.val / SMAX * 100) end
        end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s)
            if s and s.val then TFP.State.thirst = math.floor(s.val / SMAX * 100) end
        end)
        driveSim()
        Wait(1000)
    end
end)

-- ─── Per-Frame-Effekte: Sprint sperren bei leerer Stamina, Tempo bei Kälte ────
CreateThread(function()
    while true do
        local wait = 500
        if TFP.State.ready and ESX.PlayerLoaded then
            local ped = PlayerPedId()
            local active = false
            if TFP.State.stamina <= 1 then
                DisableControlAction(0, 21, true) -- INPUT_SPRINT
                active = true
            end
            if TFP.State.temperature <= Config.Stats.temperature.slow then
                SetPedMoveRateOverride(ped, Config.Stats.temperature.slowMoveRate)
                active = true
            end
            if TFP.State.fracture then
                DisableControlAction(0, 21, true) -- kein Sprint mit Bruch
                if TFP.State.fractureType ~= 'arm' then
                    local pain = TFP.PainkillerActive and TFP.PainkillerActive()
                    SetPedMoveRateOverride(ped, pain and 0.9 or 0.7) -- Beinbruch: Humpeln (Schmerzmittel lindert)
                end
                active = true
            end
            if active then wait = 0 end
        end
        Wait(wait)
    end
end)

-- Hardcore: passive HP-Regeneration deaktivieren (nur Medizin/Essen heilen)
CreateThread(function()
    while true do
        Wait(2000)
        if Config.Hardcore and Config.Hardcore.noPassiveRegen then
            SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        end
    end
end)

-- HUD-Thread: sendet IMMER (entkoppelt von esx_status:onTick), auch tot/downed —
-- damit das HUD nie hängenbleibt. Liest die zwischengespeicherten State-Werte.
CreateThread(function()
    while true do
        Wait(1000)
        if ESX.PlayerLoaded and TFP.UpdateHud then
            local ped = PlayerPedId()
            TFP.UpdateHud({
                health       = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100),
                blood        = math.floor(TFP.State.blood or 100),
                hunger       = math.floor(TFP.State.hunger or 100),
                thirst       = math.floor(TFP.State.thirst or 100),
                temperature  = math.floor(TFP.State.temperature or 100),
                wetness      = math.floor(TFP.State.wetness or 0),
                stamina      = math.floor(TFP.State.stamina or 100),
                sickness     = math.floor(TFP.State.sickness or 0),
                bleeding     = TFP.State.bleeding or 0,
                fracture     = TFP.State.fracture and 100 or 0,
                fractureType = TFP.State.fractureType,
                sicknessType = TFP.State.sicknessType,
                fatigue      = math.floor(TFP.State.fatigue or 0),
                oxygen       = math.floor(TFP.State.oxygen or 100),
            })
        end
    end
end)

-- ─── Hilfe / Steuerung (immer verfügbar) ─────────────────────────────────────
function TFP.Help()
    lib.alertDialog({
        header = '🆘 TFP — Steuerung & Tipps',
        content = [[
**Menü:** `F5` (oder `/survival`) — Handwerk, Bauen, Stamm, Admin.
**Sammeln:** Bäume/Felsen/Büsche anvisieren (ox_target). Bäume brauchen eine **Axt** (nutzt sich ab).
**Handwerk:** `/craft` (Hand) · an Werkbank/Lagerfeuer/**Schmelzofen** mehr Rezepte.
**Verletzung:** `/bandage` (`F9`) bei Blutung · `/splint` (`F10`) bei Bruch · Nähset/Blutbeutel/Schmerzmittel/Antibiotika aus dem Inventar.
**Essen/Trinken:** Items benutzen — rohes Fleisch/Fisch **am Feuer braten**, dreckiges Wasser **abkochen**.
**Stamm:** `/tribe` — Mitglieder, Ränge, gemeinsame Truhe.
**Bauen & Raid:** Mit Hammer bauen → **Verstärken** (Holz→Stein→Metall), **Codeschloss** an Türen. Fremde Basen mit Werkzeug/Waffen/Sprengstoff **zerstören** (nicht in der Safezone).
**Respawn:** Schlafsack auslegen oder ein Bett als Spawnpunkt setzen.
**Admin:** `/tfpadmin` · Koords erfassen: `/tfppos` (vec3) · `/tfpmodel` (Prop-Hash).]],
        centered = true, size = 'md',
    })
end
RegisterCommand('tfphelp', TFP.Help, false)

-- ─── Wiederbeleben / Entstecken (immer verfügbar — ersetzt fehlendes /revive) ──
local function tfpRevive()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    SetPlayerInvincible(PlayerId(), false)
    TFP.downed = false
    AnimpostfxStop('DeathFailOut')
    if TFP.SetDowned then TFP.SetDowned(false) end
    if TFP.ResetSurvival then TFP.ResetSurvival() end  -- setzt auch Max-HP/Blut zurück
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    TriggerServerEvent('clp_tfp:setDowned', false)
    lib.notify({ title = 'TFP', description = 'Wiederbelebt & vollständig geheilt.', type = 'success' })
end
RegisterCommand('tfprevive', tfpRevive, false)
RegisterCommand('reviveme', tfpRevive, false)
TFP.SelfRevive = tfpRevive

-- ─── Diagnose: zeigt im Spiel (Dialog) + F8, ob der Survival-Tick feuert ──────
function TFP.Diag()
    local now = GetGameTimer()
    local s = TFP.State or {}
    local tickAge = s.lastTick and (now - s.lastTick) or -1
    local ped = PlayerPedId()
    local hp = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100)
    local tickLine = (tickAge < 0) and '**onTick:** NIE gefeuert ⚠️ (HUD-Ursache!)'
        or ('**onTick:** zuletzt vor %d ms %s'):format(tickAge, tickAge > 4000 and '⚠️ (zu langsam)' or '✓')

    local content = ([[
%s
**PlayerLoaded:** %s   **HUD-Bridge:** %s
**Werte:** HP %d%% · Blut %s · Hunger %s · Durst %s
Temp %s · Nass %s · Ausdauer %s · Krank %s · Blutung %s
**Resourcen:** esx_status=%s · esx_basicneeds=%s
ox_target=%s · ox_inventory=%s]]):format(
        tickLine, tostring(ESX.PlayerLoaded), tostring(TFP.UpdateHud ~= nil),
        hp, tostring(s.blood), tostring(s.hunger), tostring(s.thirst),
        tostring(s.temperature), tostring(s.wetness), tostring(s.stamina), tostring(s.sickness), tostring(s.bleeding),
        GetResourceState('esx_status'), GetResourceState('esx_basicneeds'),
        GetResourceState('ox_target'), GetResourceState('ox_inventory'))

    lib.alertDialog({ header = '🔧 TFP Diagnose', content = content, centered = true, size = 'md' })
    if TFP_Log then TFP_Log('DIAG ' .. content:gsub('\n', ' | '):gsub('%*%*', '')) end -- Kopie in F8
end
RegisterCommand('tfpdiag', TFP.Diag, false)

-- ─── Debug-Befehle ────────────────────────────────────────────────────────────
if Config.Debug then
    RegisterCommand('tfpset', function(_, args)
        local name, pct = args[1], tonumber(args[2])
        if not name or not pct then
            lib.notify({ description = 'Nutzung: /tfpset <hunger|thirst|temperature|wetness|stamina|sickness> <0-100>', type = 'inform' })
            return
        end
        TriggerEvent('esx_status:set', name, pctToVal(pct))
        if TFP.State[name] ~= nil then TFP.State[name] = pct end
        lib.notify({ description = ('%s = %d%%'):format(name, pct) })
    end, false)

    RegisterCommand('tfpfire', function()
        TFP.State.forceFire = not TFP.State.forceFire
        lib.notify({ description = 'Feuer-Debug (Wärmequelle): ' .. tostring(TFP.State.forceFire) })
    end, false)

    RegisterCommand('tfpenv', function()
        local e = TFP.State.env
        print(('^3[clp_tfp env]^7 night=%s rain=%s water=%s covered=%s fire=%s hot=%s | T=%.0f W=%.0f S=%.0f Sick=%.0f')
            :format(tostring(e.night), tostring(e.raining), tostring(e.inWater), tostring(e.covered),
                    tostring(e.nearFire), tostring(e.hot),
                    TFP.State.temperature, TFP.State.wetness, TFP.State.stamina, TFP.State.sickness))
    end, false)
end
