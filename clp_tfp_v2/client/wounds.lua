-- clp_tfp · client/wounds — Wunden als LISTE (Zone/Art/Schwere/Infektion)
-- Quelle der Wahrheit für TFP.State.bleeding (Summe) + Bruch. Überschreibt die
-- Skalar-Fallbacks aus main.lua, sobald geladen. /wounds (F11) = gezielte Behandlung.

TFP = TFP or {}
TFP.State = TFP.State or {}
TFP.State.wounds = TFP.State.wounds or {}

local CW = Config.Wounds or { enabled = false }
if not CW.enabled then return end

local nextId = 1
local pendingTreat = {}
local CLINIC = { dict = 'amb@world_human_clipboard@male@base', clip = 'base' }
local BANDAGE = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 }
local REPAIR = { dict = 'mini@repair', clip = 'fixing_a_ped' }

local TREATMENTS = {
    bandage    = { label = 'Verbinden',       item = 'bandage',       time = 4000, anim = BANDAGE, icon = 'bandage' },
    suture     = { label = 'Wunde nähen',     item = 'suture_kit',    time = 6000, anim = CLINIC,  icon = 'staff-snake' },
    tourniquet = { label = 'Tourniquet legen', item = 'tourniquet',   time = 1800, anim = CLINIC,  icon = 'ban' },
    disinfect  = { label = 'Desinfizieren',   item = 'disinfectant',  time = 3000, anim = CLINIC,  icon = 'spray-can' },
    burn       = { label = 'Brandsalbe',      item = 'burn_ointment', time = 3000, anim = CLINIC,  icon = 'fire-flame-simple' },
    splint     = { label = 'Schiene anlegen', item = 'splint',        time = 5000, anim = REPAIR,  icon = 'bone' },
}

local function recompute()
    local total, arm, leg = 0, false, false
    for _, w in ipairs(TFP.State.wounds) do
        total = total + (w.bleed or 0)
        local zd = CW.zones and CW.zones[w.zone]
        if zd and not w.treated then
            if zd.arm and ((w.bleed or 0) > 5 or (w.severity or 1) >= 2) then arm = true end
            if zd.leg and (w.severity or 1) >= 2 and (w.bleed or 0) > 3 then leg = true end
        end
    end
    TFP.State.bleeding, TFP.State.armWounded, TFP.State.legWounded = math.min(100, total), arm, leg
end

local function pruneResolved()
    for i = #TFP.State.wounds, 1, -1 do
        local w = TFP.State.wounds[i]
        if not w.isFracture and (w.bleed or 0) <= 0.5 and (w.infection or 0) <= 1 then table.remove(TFP.State.wounds, i) end
    end
end
local function findWound(id) for _, w in ipairs(TFP.State.wounds) do if w.id == id then return w end end end
local function healHp(amt) local p = PlayerPedId(); SetEntityHealth(p, math.min(GetEntityMaxHealth(p), GetEntityHealth(p) + (amt or 0))) end

local function applyTreatment(w, method)
    if method == 'splint' then if TFP.HealFracture then TFP.HealFracture() end return end
    if not w then return end
    if method == 'bandage' then
        w.bandaged = true
        local floor = (CW.kinds[w.kind] and CW.kinds[w.kind].sutureFloor) or 0
        w.bleed = math.max(floor, (w.bleed or 0) - (CW.bandageReduce or 45))
        lib.notify({ title = 'Medizin', type = 'success', description = (floor > 0 and (w.bleed or 0) > 0) and 'Verband angelegt — die Wunde nässt durch, sie muss genäht werden.' or 'Verband angelegt.' })
    elseif method == 'suture' then
        w.bleed = 0; w.treated = true; healHp(CW.sutureHealHp or 12)
        lib.notify({ title = 'Medizin', description = 'Wunde genäht — Blutung gestoppt.', type = 'success' })
    elseif method == 'tourniquet' then
        w.bleed = 0; lib.notify({ title = 'Medizin', description = 'Tourniquet — Blutung sofort gestoppt.', type = 'success' })
    elseif method == 'disinfect' then
        w.infection = 0
        TFP.State.disinfectUntil = GetGameTimer() + ((Config.Medical and Config.Medical.disinfectMs) or 150000)
        if TFP.State.sicknessType == 'infection' and TFP.HealSicknessBy then TFP.HealSicknessBy(40) end
        lib.notify({ title = 'Medizin', description = 'Wunde desinfiziert.', type = 'success' })
    elseif method == 'burn' then
        w.bleed = 0; w.treated = true; healHp((Config.Medical and Config.Medical.burnHeal) or 25)
        lib.notify({ title = 'Medizin', description = 'Brandsalbe aufgetragen.', type = 'success' })
    end
    pruneResolved(); recompute()
end

function TFP.PickHitZone()
    local ped = PlayerPedId()
    local a, b = GetPedLastDamageBone(ped)
    local boneId = (type(b) == 'number') and b or a
    if boneId == 31086 then return 'head' end
    local total = 0
    for _, zd in pairs(CW.zones or {}) do total = total + (zd.weight or 0) end
    if total <= 0 then return 'torso' end
    local roll = math.random() * total
    for zname, zd in pairs(CW.zones) do roll = roll - (zd.weight or 0); if roll <= 0 then return zname end end
    return 'torso'
end

local lastWoundMsg = 0
function TFP.AddWound(zone, kind, severity, bleedOverride)
    if not CW.enabled then return end
    kind = kind or 'cut'
    local kd = CW.kinds[kind] or CW.kinds.cut
    zone = zone or TFP.PickHitZone()
    local zd = CW.zones[zone] or CW.zones.torso
    local add = (bleedOverride or kd.bleed or 10) * (zd.bleedMult or 1.0)
    if not kd.isFracture and not kd.isBurn and TFP.ClothingArmorFactor then add = add * (1 - TFP.ClothingArmorFactor()) end
    for _, w in ipairs(TFP.State.wounds) do
        if w.zone == zone and w.kind == kind and not w.isFracture then
            w.bleed = math.min(100, (w.bleed or 0) + add); w.bandaged = false; w.treated = false
            recompute(); return w
        end
    end
    if #TFP.State.wounds >= (CW.maxWounds or 8) then
        local w = TFP.State.wounds[1]; if w then w.bleed = math.min(100, (w.bleed or 0) + add) end
        recompute(); return
    end
    local w = { id = nextId, zone = zone, kind = kind, severity = severity or kd.severity or 1,
        bleed = math.min(100, add), infection = 0, bandaged = false, treated = false, isBurn = kd.isBurn, isFracture = kd.isFracture, t = GetGameTimer() }
    nextId = nextId + 1
    TFP.State.wounds[#TFP.State.wounds + 1] = w
    local now = GetGameTimer()
    if now - lastWoundMsg > 4000 then lastWoundMsg = now; lib.notify({ title = 'Verletzung', type = 'error', description = ('%s: %s'):format(zd.label or zone, kd.label or kind) }) end
    if zone == 'head' and not (TFP.PainkillerActive and TFP.PainkillerActive()) then
        AnimpostfxPlay('MinigameTransitionIn'); SetTimeout(420, function() AnimpostfxStop('MinigameTransitionIn') end)
        pcall(ShakeGameplayCam, 'JOLT_SHAKE', 0.45)
    end
    recompute(); return w
end

function TFP.WoundsTick()
    if not CW.enabled then return end
    local disinfected = (TFP.State.disinfectUntil or 0) > GetGameTimer()
    for _, w in ipairs(TFP.State.wounds) do
        if not w.isFracture then
            local kd = CW.kinds[w.kind] or {}
            local clot = (CW.clotPerTick or 0.4) * (w.bandaged and (CW.bandageClotMult or 3.0) or 1.0)
            local floor = w.treated and 0 or (kd.sutureFloor or 0)
            if (w.bleed or 0) > floor then w.bleed = math.max(floor, (w.bleed or 0) - clot) end
            if disinfected then w.infection = math.max(0, (w.infection or 0) - 1.0)
            elseif (w.bleed or 0) > 0 or (w.infection or 0) > 0 then
                local rise = (CW.infectRisePerTick or 0.35) * (kd.infectRisk or 1.0)
                if w.bandaged then rise = rise * (CW.infectBandageMult or 0.4) end
                w.infection = math.min(100, (w.infection or 0) + rise)
            end
            if (w.infection or 0) >= (CW.infectSicknessAt or 60) and TFP.AddSickness then
                local sev = math.floor((w.infection or 0) * 0.8)
                if (TFP.State.sickness or 0) < sev then TFP.AddSickness('infection', sev) end
            end
        end
    end
    pruneResolved(); recompute()
end

function TFP.Bleed(amount) TFP.AddWound(nil, 'cut', nil, amount) end
function TFP.StopBleed()
    for _, w in ipairs(TFP.State.wounds) do if not w.isFracture then w.bleed = 0; w.treated = true end end
    pruneResolved(); recompute(); lib.notify({ title = 'Überleben', description = 'Blutung gestoppt.', type = 'success' })
end
function TFP.ReduceBleed(amount)
    local left = amount or 0
    table.sort(TFP.State.wounds, function(a, b) return (a.bleed or 0) > (b.bleed or 0) end)
    for _, w in ipairs(TFP.State.wounds) do
        if not w.isFracture and left > 0 then
            local floor = (CW.kinds[w.kind] and CW.kinds[w.kind].sutureFloor) or 0
            local cut = math.min(left, (w.bleed or 0) - floor)
            if cut > 0 then w.bleed = w.bleed - cut; left = left - cut; w.bandaged = true end
        end
    end
    pruneResolved(); recompute()
end

function TFP.OnFracture(kind)
    if not CW.enabled then return end
    local zone = (kind == 'arm') and 'rarm' or 'rleg'
    for _, w in ipairs(TFP.State.wounds) do if w.isFracture and w.zone == zone then return end end
    if #TFP.State.wounds < (CW.maxWounds or 8) then
        TFP.State.wounds[#TFP.State.wounds + 1] = { id = nextId, zone = zone, kind = 'fracture', severity = 3, bleed = 0, infection = 0, bandaged = false, treated = false, isFracture = true, t = GetGameTimer() }
        nextId = nextId + 1
    end
    recompute()
end
function TFP.OnHealFracture()
    for i = #TFP.State.wounds, 1, -1 do if TFP.State.wounds[i].isFracture then table.remove(TFP.State.wounds, i) end end
    recompute()
end
function TFP.ClearWounds() TFP.State.wounds = {}; TFP.State.armWounded = false; TFP.State.legWounded = false; TFP.State.bleeding = 0 end

function TFP.QuickTreat(method)
    if method == 'splint' then
        if TFP.State.fracture and TFP.HealFracture then TFP.HealFracture(); return true end
        lib.notify({ title = 'Medizin', description = 'Du hast keinen Knochenbruch.', type = 'inform' }); return false
    end
    local target
    if method == 'disinfect' then
        for _, w in ipairs(TFP.State.wounds) do if not w.isFracture and (not target or (w.infection or 0) > (target.infection or 0)) then target = w end end
    elseif method == 'burn' then
        for _, w in ipairs(TFP.State.wounds) do if w.kind == 'burn' and (not target or (w.bleed or 0) > (target.bleed or 0)) then target = w end end
    else
        for _, w in ipairs(TFP.State.wounds) do if not w.isFracture and (w.bleed or 0) > 0 and (not target or (w.bleed or 0) > (target.bleed or 0)) then target = w end end
    end
    if not target then return false end
    applyTreatment(target, method); return true
end

local function methodsFor(w)
    if w.isFracture then return { 'splint' } end
    local m = {}
    if w.kind == 'burn' then m[#m + 1] = 'burn' end
    if (w.bleed or 0) > 0 then m[#m + 1] = 'bandage'; m[#m + 1] = 'suture'; m[#m + 1] = 'tourniquet' end
    m[#m + 1] = 'disinfect'
    return m
end

local function doTreat(w, method)
    local tr = TREATMENTS[method]; if not tr then return end
    if (exports.ox_inventory:Search('count', tr.item) or 0) < 1 then lib.notify({ title = 'Medizin', description = 'Dir fehlt das passende Mittel.', type = 'error' }); return end
    if lib.progressBar({ duration = tr.time, label = tr.label .. '…', canCancel = true, disable = { move = true, car = true, combat = true }, anim = tr.anim }) then
        pendingTreat[w.id] = method
        TriggerServerEvent('clp_tfp:treatWound', w.id, method)
    end
end

local function openTreatMenu(w)
    local opts = {}
    for _, method in ipairs(methodsFor(w)) do
        local tr = TREATMENTS[method]; local have = exports.ox_inventory:Search('count', tr.item) or 0
        opts[#opts + 1] = { title = tr.label, description = ('×%d im Inventar'):format(have), icon = tr.icon, disabled = have < 1, onSelect = function() doTreat(w, method) end }
    end
    if #opts == 0 then opts[1] = { title = 'Nichts anwendbar', disabled = true } end
    lib.registerContext({ id = 'tfp_wound_treat', title = 'Behandeln', menu = 'tfp_wounds', options = opts })
    lib.showContext('tfp_wound_treat')
end

function TFP.OpenWoundMenu()
    local opts = {}
    if #TFP.State.wounds == 0 then
        opts[1] = { title = 'Keine Wunden', description = 'Du bist unverletzt.', icon = 'heart-pulse', disabled = true }
    else
        for _, w in ipairs(TFP.State.wounds) do
            local zd = CW.zones[w.zone] or {}; local kd = CW.kinds[w.kind] or {}
            local st = {}
            if (w.bleed or 0) > 0 then st[#st + 1] = ('Blutung %d%%'):format(math.floor(w.bleed)) end
            if (w.infection or 0) > 1 then st[#st + 1] = ('Infektion %d%%'):format(math.floor(w.infection)) end
            if w.bandaged then st[#st + 1] = 'verbunden' end
            if w.treated then st[#st + 1] = 'versorgt' end
            if #st == 0 then st[1] = 'stabil' end
            opts[#opts + 1] = {
                title = ('%s · %s'):format(zd.label or w.zone, kd.label or w.kind),
                description = table.concat(st, ' · '),
                icon = w.isFracture and 'bone' or (w.kind == 'burn' and 'fire' or (w.kind == 'bite' and 'paw' or 'droplet')),
                iconColor = ((w.infection or 0) > 40) and '#9b59b6' or (((w.bleed or 0) > 20) and '#e74c3c' or nil),
                onSelect = function() openTreatMenu(w) end,
            }
        end
    end
    lib.registerContext({ id = 'tfp_wounds', title = '🩹 Wundversorgung', options = opts })
    lib.showContext('tfp_wounds')
end

RegisterNetEvent('clp_tfp:woundTreated', function(id, method)
    pendingTreat[id] = nil
    local w = findWound(id)
    if w then applyTreatment(w, method) elseif method == 'splint' then applyTreatment(nil, 'splint') end
    if #TFP.State.wounds > 0 then TFP.OpenWoundMenu() end
end)

RegisterCommand('wounds', function() TFP.OpenWoundMenu() end, false)
lib.addKeybind({ name = 'tfp_wounds', description = 'Wundversorgung öffnen', defaultKey = 'F11', onPressed = function() TFP.OpenWoundMenu() end })
