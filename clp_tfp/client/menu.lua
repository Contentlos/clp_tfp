-- clp_tfp · menu/ — Hauptmenü (F5 / /survival / Radial) mit eigenen Untermenüs pro Bereich

TFP = TFP or {}

local function pct(v) return math.floor(v or 0) end

-- ─── Zustands-Übersicht ──────────────────────────────────────────────────────
local function showStatus()
    local s = TFP.State or {}
    local ped = PlayerPedId()
    local hp = math.floor((GetEntityHealth(ped) / math.max(1, GetEntityMaxHealth(ped))) * 100)
    local disease = '—'
    if s.sicknessType then
        disease = (Config.Diseases[s.sicknessType] and Config.Diseases[s.sicknessType].label) or s.sicknessType
        disease = disease .. (' (%d%%)'):format(pct(s.sickness))
    end
    local frac = s.fracture and ((s.fractureType == 'arm') and 'Armbruch' or 'Beinbruch') or '—'
    lib.alertDialog({
        header = '📊 Dein Zustand',
        content = ([[
**Leben:** %d%%   **Blut:** %d%%
**Hunger:** %d%%   **Durst:** %d%%
**Ausdauer:** %d%%   **Wärme:** %d%%
**Müdigkeit:** %d%%   **Nässe:** %d%%
**Blutung:** %d%%   **Bruch:** %s
**Krankheit:** %s]]):format(
            hp, pct(s.blood), pct(s.hunger), pct(s.thirst), pct(s.stamina),
            pct(s.temperature), pct(s.fatigue), pct(s.wetness), pct(s.bleeding), frac, disease),
        centered = true, size = 'sm',
    })
end

-- Untermenü registrieren (mit Zurück-Pfeil zum Hauptmenü)
local function sub(id, title, options)
    lib.registerContext({ id = id, title = title, menu = 'tfp_menu', options = options })
    lib.showContext(id)
end

-- ─── Bereiche ────────────────────────────────────────────────────────────────
local function openSurvival()
    local o = {}
    o[#o + 1] = { title = 'Zustand ansehen', icon = 'fa-solid fa-heart-pulse', onSelect = showStatus }
    if TFP.State and (TFP.State.bleeding or 0) > 0 then
        o[#o + 1] = { title = 'Verbinden', icon = 'fa-solid fa-bandage', description = 'Blutung stoppen',
            onSelect = function() if TFP.Bandage then TFP.Bandage() end end }
    end
    if TFP.State and TFP.State.fracture then
        o[#o + 1] = { title = 'Schiene anlegen', icon = 'fa-solid fa-bone', description = 'Knochenbruch',
            onSelect = function() if TFP.Splint then TFP.Splint() end end }
    end
    o[#o + 1] = { title = 'Wiederbeleben / Entstecken', icon = 'fa-solid fa-heart-circle-plus',
        description = 'Bei Tod/Downed festhängen', onSelect = function() if TFP.SelfRevive then TFP.SelfRevive() end end }
    sub('tfp_m_surv', '🧍 Überleben', o)
end

local function openCraftBuild()
    sub('tfp_m_cb', '🔨 Handwerk & Bauen', {
        { title = 'Handwerk (Hand)', icon = 'fa-solid fa-hammer', description = 'Per Hand herstellen',
            onSelect = function() if TFP.OpenCrafting then TFP.OpenCrafting() end end },
        { title = 'Bauen', icon = 'fa-solid fa-house', description = 'Bau-Menü öffnen',
            onSelect = function() if TFP.OpenBuild then TFP.OpenBuild() end end },
    })
end

local function openActivities()
    local o = {}
    o[#o + 1] = { title = 'Aufgaben', icon = 'fa-solid fa-list-check', description = 'Survival-Ziele & Belohnungen',
        onSelect = function() if TFP.OpenQuests then TFP.OpenQuests() end end }
    if TFP.HasRod and TFP.HasRod() then
        o[#o + 1] = { title = 'Angeln', icon = 'fa-solid fa-fish', description = 'Am Wasser angeln',
            onSelect = function() if TFP.Fish then TFP.Fish() end end }
    end
    sub('tfp_m_act', '🎒 Aktivitäten', o)
end

local function openSystem()
    sub('tfp_m_sys', '⚙️ System', {
        { title = 'Hilfe / Steuerung', icon = 'fa-solid fa-circle-question',
            onSelect = function() if TFP.Help then TFP.Help() end end },
        { title = 'Diagnose', icon = 'fa-solid fa-stethoscope', description = 'HUD/Tick prüfen',
            onSelect = function() if TFP.Diag then TFP.Diag() end end },
    })
end

-- ─── Hauptmenü ───────────────────────────────────────────────────────────────
local function openMenu()
    lib.registerContext({ id = 'tfp_menu', title = '🌴 Survival', options = {
        { title = 'Überleben',         icon = 'fa-solid fa-heart-pulse', description = 'Zustand · Erste Hilfe · Wiederbeleben', arrow = true, onSelect = openSurvival },
        { title = 'Handwerk & Bauen',  icon = 'fa-solid fa-hammer',      description = 'Herstellen & Basis bauen',             arrow = true, onSelect = openCraftBuild },
        { title = 'Aktivitäten',       icon = 'fa-solid fa-compass',     description = 'Aufgaben · Angeln',                    arrow = true, onSelect = openActivities },
        { title = 'Stamm',             icon = 'fa-solid fa-users',       description = 'Gründen · verwalten · Truhe',          onSelect = function() if TFP.OpenTribe then TFP.OpenTribe() end end },
        { title = 'System',            icon = 'fa-solid fa-gear',        description = 'Hilfe & Diagnose',                     arrow = true, onSelect = openSystem },
        { title = 'Admin',             icon = 'fa-solid fa-screwdriver-wrench', description = 'nur Berechtigte',              onSelect = function() if TFP.OpenAdmin then TFP.OpenAdmin() end end },
    } })
    lib.showContext('tfp_menu')
end

TFP.OpenMenu = openMenu
RegisterCommand('survival', openMenu, false)
lib.addKeybind({ name = 'tfp_menu', description = 'Survival-Menü', defaultKey = 'F5', onPressed = openMenu })

-- ─── Radial-Rad (Schnellzugriff) ─────────────────────────────────────────────
CreateThread(function()
    if not (lib.registerRadial and lib.addRadialItem) then return end
    local ok = pcall(function()
        lib.registerRadial({
            id = 'tfp_radial',
            items = {
                { label = 'Zustand', icon = 'heart-pulse', onSelect = showStatus },
                { label = 'Handwerk', icon = 'hammer', onSelect = function() if TFP.OpenCrafting then TFP.OpenCrafting() end end },
                { label = 'Bauen', icon = 'house', onSelect = function() if TFP.OpenBuild then TFP.OpenBuild() end end },
                { label = 'Aufgaben', icon = 'list-check', onSelect = function() if TFP.OpenQuests then TFP.OpenQuests() end end },
                { label = 'Stamm', icon = 'users', onSelect = function() if TFP.OpenTribe then TFP.OpenTribe() end end },
                { label = 'Menue', icon = 'bars', onSelect = openMenu },
            },
        })
        lib.addRadialItem({ id = 'tfp', icon = 'leaf', label = 'Survival', menu = 'tfp_radial' })
    end)
    if not ok and TFP_Warn then TFP_Warn('Radial-Menü übersprungen.') end
end)
