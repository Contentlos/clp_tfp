-- clp_tfp · config.lua (shared) — zentrale Konfiguration
-- ════════════════════════════════════════════════════════════════════════════
--  Neuaufbau v2. Sektionen wachsen pro Build-Phase (siehe REBUILD_PROMPT.md).
--  PHASE 1 — Fundament: globale Schalter, Stats-Kern, Welt/Safezone, Spawn.
-- ════════════════════════════════════════════════════════════════════════════

Config = {}

Config.Debug          = false
Config.StatusMax      = 1000000   -- MUSS mit esx_status & esx_basicneeds übereinstimmen
Config.TickMs         = 1000       -- Survival-Sim-Takt
Config.WarnCooldownMs = 8000       -- Min-Abstand gleicher Warn-Notifications

-- ─── Stats (alle Werte in PROZENT 0..100) ───────────────────────────────────
-- ⚠️ LEKTION (REBUILD_PROMPT.md §2.1): Hunger/Durst GEHÖREN esx_basicneeds.
-- Die Sim darf sie nur LESEN — niemals selbst zehren oder zurückschreiben
-- (sonst Snapback nach dem Essen → Hunger gegen 0 → Tod-Schleife).
-- Pace ändern: NUR in [esx_addons]/esx_basicneeds/config.lua → Needs.*.drainMinutes.
Config.Stats = {
    hungerDrain  = 0,    -- bleibt 0 — esx_basicneeds besitzt den Hunger-Drain
    thirstDrain  = 0,    -- bleibt 0 — esx_basicneeds besitzt den Durst-Drain
    starveHpLoss = 0,    -- 0 — esx_basicneeds macht bei 0 % bereits Schaden (kein Doppel-Schaden)

    temperature = {
        default = 78, baseTarget = 78,
        nightDrop = 34, rainDrop = 48, waterDrop = 55, wetFactor = 0.45,
        fireBoost = 70, clothingBoost = 8, clothingBoostWarm = 34, warmItem = 'warm_clothing',
        approachRate = 0.08,
        warn = 40, slow = 30, critical = 14,
        slowMoveRate = 0.80, criticalHpLoss = 3,
    },
    wetness = { default = 0, swimGain = 9, rainGain = 5, dryBase = 1.2, dryFireBonus = 4, drySunBonus = 1.5 },
    stamina = { default = 100, sprintDrain = 3, swimDrain = 3, regen = 6, lowRegen = 2, lowNeedPct = 20 },
    sickness = { default = 0, coldWetRisk = 4, riskThreshold = 100, riseCold = 1, fallWarm = 2,
                 warmTemp = 60, hpThreshold = 70, hpLoss = 1 },
}

-- ─── Welt / Safezone ─────────────────────────────────────────────────────────
-- ⚠️ LEKTION (§2.9): Safezone = unverwundbar + KEINE Gegner-/Raubtier-Spawns.
Config.World = {
    enableIsland = true,
    islandName   = 'HeistIsland',
    islandCenter = vec3(4840.0, -5174.0, 2.0),
    islandRadius = 2200.0,
    safezone = {
        enabled = true,
        label   = 'Strandlager',
        center  = vec3(4895.0, -5160.0, 2.0),  -- mit /tfppos am Strandlager exakt setzen
        radius  = 45.0,
        predatorBuffer = 25.0,                 -- zusätzlicher Puffer für Spawn-Verbot
    },
}

-- ─── Spawn ────────────────────────────────────────────────────────────────────
Config.Spawn = {
    sleepingBagModel = 'prop_skid_sleepbag_1',
    starterKit = {
        { name = 'water_clean', count = 1 },
        { name = 'canned_food', count = 1 },
        { name = 'bandage',     count = 1 },
    },
    -- verstreute Strand-Spawnpunkte (vec4: x,y,z,heading) — mit /tfpaddspawn erfassen
    points = {
        vec4(4895.0, -5160.0, 2.0, 200.0),
    },
}

-- ─── Blut-System (Max-HP an Blutstand gekoppelt) ────────────────────────────
Config.Blood = {
    enabled = true, default = 100,
    lossPerTick = 1.2, regenPerTick = 0.15, regenNeedPct = 50,
    criticalLow = 18, shockHpLoss = 2,
    minMaxHp = 100, maxMaxHp = 200,
}

-- ─── Verletzungen (Skalar-Basis; Wunden-Liste folgt in Phase 3) ─────────────
Config.Injury = {
    bleedHpPerTick = 2, bleedClotPerTick = 0.4, bleedFromHit = 16,
    fallFractureMin = 7.5, fractureChance = 70, fractureClipset = 'move_m@injured',
    bandageItem = 'bandage', splintItem = 'splint',
    infectBleedMin = 35, infectChance = 5, armFractureChance = 22,
}

Config.Medical = {
    bandageReduce = 55, sutureHealHp = 12, bloodBagRestore = 45, salineRestore = 30, burnHeal = 25,
    transfuseTime = 8000, painkillerMs = 90000, disinfectMs = 150000,
    symptomMinSeverity = 35,
    symptoms = {
        cold      = { tcMod = nil,           thirstDrain = 0, msg = 'Du hustest und zitterst…' },
        food      = { tcMod = 'drug_wobbly', thirstDrain = 0, msg = 'Dir ist übel…' },
        infection = { tcMod = nil,           thirstDrain = 0, painFlash = true, msg = 'Die Wunde pocht heiß…' },
        cholera   = { tcMod = 'drug_wobbly', thirstDrain = 2, msg = 'Krämpfe und Schwindel…' },
    },
}

-- ─── Wunden-System (Liste: Zone · Art · Schwere · Infektion; /wounds) ────────
Config.Wounds = {
    enabled = true, maxWounds = 8,
    clotPerTick = 0.4, bandageClotMult = 3.0, bandageReduce = 45,
    infectRisePerTick = 0.35, infectBandageMult = 0.4, infectSicknessAt = 60, sutureHealHp = 12,
    kinds = {
        cut      = { label = 'Schnittwunde', bleed = 14, infectRisk = 1.0, severity = 1 },
        gunshot  = { label = 'Schusswunde',  bleed = 30, infectRisk = 1.4, severity = 2, sutureFloor = 9 },
        bite     = { label = 'Bisswunde',    bleed = 18, infectRisk = 2.6, severity = 2 },
        burn     = { label = 'Brandwunde',   bleed = 4,  infectRisk = 1.2, severity = 2, isBurn = true },
        fracture = { label = 'Knochenbruch', bleed = 6,  infectRisk = 0.0, severity = 3, isFracture = true },
    },
    zones = {
        head  = { label = 'Kopf',         bleedMult = 1.6, weight = 0  },
        torso = { label = 'Oberkörper',   bleedMult = 1.3, weight = 40 },
        larm  = { label = 'Linker Arm',   bleedMult = 0.9, weight = 15, arm = true },
        rarm  = { label = 'Rechter Arm',  bleedMult = 0.9, weight = 15, arm = true },
        lleg  = { label = 'Linkes Bein',  bleedMult = 1.0, weight = 15, leg = true },
        rleg  = { label = 'Rechtes Bein', bleedMult = 1.0, weight = 15, leg = true },
    },
    legMoveRate = 0.85,
}

-- ─── Threat: Downed-Zustand, Tod, Revive, Tode-Log ──────────────────────────
Config.Threat = {
    dropInventoryOnDeath = false,   -- true = ganzes Inventar als Beutel am Sterbeort
    deathLogHours = 12,             -- letzte Tode nur 12 h aufbewahren
    downed = { enabled = true, bleedoutSeconds = 120, reviveItem = 'firstaid_kit', reviveSeconds = 6 },
}

Config.Diseases = {
    cold      = { label = 'Erkältung / Fieber',     cure = 'antibiotics' },
    food      = { label = 'Lebensmittelvergiftung', cure = 'antibiotics' },
    infection = { label = 'Wundinfektion',          cure = 'antibiotics' },
    cholera   = { label = 'Cholera',                cure = 'antibiotics' },
}

Config.Senses = { coldBreath = true, coldBreathTemp = 35, painFlash = true }

-- Wetter-Hashes, die als „Regen" zählen (Nässe/Temp)
Config.RainyWeathers = { 'RAIN', 'THUNDER', 'CLEARING', 'SLEET', 'BLIZZARD' }

-- Wärmequellen (für „nahe Feuer")
Config.CampfireModel = 'prop_beach_fire'
Config.FireRadius    = 6.0
Config.FireModels    = { 'prop_beach_fire', 'prop_bonfire_01', 'prop_bbq_3', 'prop_beach_fire_03' }

Config.Hardcore = { noPassiveRegen = true }  -- nur Medizin/Essen heilen

-- ─── Konsum-Risiken ──────────────────────────────────────────────────────────
Config.RawMeatSicknessChance    = 40
Config.BerrySicknessChance      = 10
Config.DirtyWaterSicknessChance = 35
Config.SpoiledThreshold         = 15   -- Haltbarkeit (%) ab der ein Item verdorben ist
Config.MedkitHeal               = 40
Config.Atmosphere               = { warmEmote = 'crossarms' }  -- voll ausgebaut in Phase 7

-- ─── Sammeln (ox_target addModel — §2.5: kein GetEntityModel-Crash) ─────────
Config.Gathering = {
    cooldownMs = 1500, toolDurabilityLoss = 5,
    nodes = {
        tree = {
            label = 'Baum fällen', icon = 'fa-solid fa-tree', usetime = 4500,
            tool = 'WEAPON_HATCHET', emote = 'axe2',
            anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
            yields = { { item = 'wood', min = 2, max = 4 }, { item = 'coconut', min = 1, max = 1, chance = 40 } },
            models = {
                'prop_palm_huge_01a','prop_palm_huge_01b','prop_palm_med_01a','prop_palm_med_01b','prop_palm_med_01c','prop_palm_med_01d',
                'prop_palm_sm_01a','prop_palm_sm_01b','prop_palm_sm_01c','prop_palm_sm_01d','prop_palm_sm_01e','prop_palm_sm_01f',
                'prop_palm_fan_02_a','prop_palm_fan_02_b','prop_palm_fan_03_a','prop_palm_fan_03_b','prop_palm_fan_03_c','prop_palm_fan_03_d',
                'prop_palm_fan_04_a','prop_palm_fan_04_b','prop_palm_fan_04_c','prop_palm_fan_04_d',
                'prop_fan_palm_01a','prop_palm2_xmas','prop_desert_palm_01','prop_lt_palm_01',
                'prop_palmdead_01_b','prop_palmdead_02_b','prop_palmdead_03_b','prop_palmdead_04_b','prop_palmdead_05_b','prop_palmdead_03_c',
                'prop_tree_birch_01','prop_tree_birch_02','prop_tree_birch_03','prop_tree_birch_03b','prop_tree_birch_04','prop_tree_birch_05',
                'prop_tree_cedar_02','prop_tree_cedar_03','prop_tree_cedar_04','prop_tree_cedar_s_01','prop_tree_cedar_s_04','prop_tree_cedar_s_05','prop_tree_cedar_s_06',
                'prop_tree_cypress_01','prop_tree_eng_oak_01','prop_tree_eucalip_01','prop_tree_fallen_pine_01',
                'prop_tree_jacada_01','prop_tree_jacada_02','prop_tree_lficus_02','prop_tree_lficus_03','prop_tree_lficus_05','prop_tree_lficus_06',
                'prop_tree_maple_02','prop_tree_maple_03','prop_tree_mquite_01','prop_tree_oak_01','prop_tree_olive_01',
                'prop_tree_pine_01','prop_tree_pine_02','prop_tree_stump_01','prop_s_pine_dead_01',
                'prop_bushytree_01','prop_veg_crop_tr_01','prop_veg_crop_tr_02',
            },
        },
        rock = {
            label = 'Stein abbauen', icon = 'fa-solid fa-gem', usetime = 4000, emote = 'dig',
            anim = { dict = 'random@burial', clip = 'a_burial' },
            yields = { { item = 'stone', min = 1, max = 3 } },
            models = { 'prop_rock_1_a','prop_rock_1_b','prop_rock_1_c','prop_rock_2_a','prop_rock_2_b','prop_rock_3_a','prop_rock_4_a','prop_rock_4_b','prop_rock_4_c','prop_rock_5_a','prop_rock_5_b','prop_rock_6_a','prop_rock_7_a','prop_rock_7_b' },
        },
        bush = {
            label = 'Pflanzen sammeln', icon = 'fa-solid fa-seedling', usetime = 2500,
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            yields = { { item = 'plant_fiber', min = 1, max = 3 } },
            models = { 'prop_bush_lrg_04b','prop_bush_lrg_04c','prop_bush_lrg_04d','prop_bush_med_05','prop_bush_med_07','prop_bush_neat_01','prop_bush_dst_01','prop_bush_dst_03' },
        },
        berry = {
            label = 'Beeren/Früchte sammeln', icon = 'fa-solid fa-apple-whole', usetime = 2500,
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            yields = { { item = 'berries', min = 1, max = 3 }, { item = 'plant_fiber', min = 1, max = 1, chance = 30 } },
            models = { 'prop_bush_med_02','prop_bush_med_03','prop_bush_med_04','prop_bush_lrg_01b','prop_bush_lrg_02b','prop_bush_lrg_03b' },
        },
        scrap = {
            label = 'Schrott bergen', icon = 'fa-solid fa-screwdriver-wrench', usetime = 3500,
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
            yields = { { item = 'scrap_metal', min = 1, max = 2 } },
            models = { 'prop_rub_tyre_01','prop_rub_washer_01','prop_rub_couch01','prop_rub_generator','prop_rub_cabinet','prop_rub_boxpile_02' },
        },
    },
}

-- ─── Handwerk: Stationen hand/campfire/workbench/forge + Blueprints ─────────
Config.Crafting = {
    recipes = {
        campfire_kit  = { station = 'hand', label = 'Lagerfeuer-Set', time = 4000, output = { item = 'campfire_kit', count = 1 }, ingredients = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },
        stone_axe     = { station = 'hand', label = 'Steinaxt',       time = 5000, output = { item = 'WEAPON_HATCHET', count = 1 }, ingredients = { { item = 'stone', count = 3 }, { item = 'plant_fiber', count = 2 } } },
        craft_bandage = { station = 'hand', label = 'Verband',        time = 3000, output = { item = 'bandage', count = 1 }, ingredients = { { item = 'plant_fiber', count = 3 } } },
        craft_bottle  = { station = 'hand', label = 'Leere Flasche',  time = 2500, output = { item = 'empty_bottle', count = 1 }, ingredients = { { item = 'scrap_metal', count = 1 } } },
        craft_splint  = { station = 'hand', label = 'Schiene',        time = 3000, output = { item = 'splint', count = 1 }, ingredients = { { item = 'wood', count = 2 }, { item = 'plant_fiber', count = 2 } } },
        craft_rod     = { station = 'hand', label = 'Angel',          time = 4000, output = { item = 'fishing_rod', count = 1 }, ingredients = { { item = 'wood', count = 2 }, { item = 'plant_fiber', count = 3 } } },

        workbench_kit = { station = 'campfire', label = 'Werkbank-Set', time = 6000, output = { item = 'workbench_kit', count = 1 }, ingredients = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 4 } } },

        craft_hammer       = { station = 'workbench', label = 'Hammer',          time = 4000, output = { item = 'hammer', count = 1 }, ingredients = { { item = 'wood', count = 4 }, { item = 'scrap_metal', count = 2 } } },
        craft_sleeping_bag = { station = 'workbench', label = 'Schlafsack',      time = 5000, output = { item = 'sleeping_bag', count = 1 }, ingredients = { { item = 'plant_fiber', count = 8 }, { item = 'wood', count = 2 } } },
        craft_warm_clothing= { station = 'workbench', label = 'Fellkleidung',    time = 6000, output = { item = 'warm_clothing', count = 1 }, ingredients = { { item = 'leather', count = 2 }, { item = 'plant_fiber', count = 4 } } },
        craft_radio        = { station = 'workbench', label = 'Funkgerät',       time = 5000, output = { item = 'radio', count = 1 }, ingredients = { { item = 'scrap_metal', count = 4 }, { item = 'radio_part', count = 1 } } },
        craft_whistle      = { station = 'workbench', label = 'Hundepfeife',     time = 3000, output = { item = 'dog_whistle', count = 1 }, ingredients = { { item = 'scrap_metal', count = 2 } } },
        craft_suture       = { station = 'workbench', label = 'Nähset',          time = 4000, output = { item = 'suture_kit', count = 1 }, ingredients = { { item = 'plant_fiber', count = 3 }, { item = 'scrap_metal', count = 1 } } },
        tan_leather        = { station = 'workbench', label = 'Leder gerben',    time = 4500, output = { item = 'leather', count = 1 }, ingredients = { { item = 'animal_hide', count = 2 } } },
        craft_firstaid     = { station = 'workbench', label = 'Erste-Hilfe-Set', time = 6000, blueprint = 'blueprint_tools', output = { item = 'firstaid_kit', count = 1 }, ingredients = { { item = 'bandage', count = 2 }, { item = 'plant_fiber', count = 3 } } },

        smelt_ingot        = { station = 'forge', label = 'Metallbarren schmelzen', time = 6000, output = { item = 'metal_ingot', count = 1 }, ingredients = { { item = 'scrap_metal', count = 3 } } },
        -- weitere Rezepte (Kleidung/Boot/Panzer) folgen in Phase 6/7
    },
}

Config.Blueprints = {
    blueprint_tools     = { label = 'Bauplan: Werkzeuge & Medizin', recipes = { 'craft_firstaid' } },
    blueprint_metalwork = { label = 'Bauplan: Metallverarbeitung',  recipes = {} },  -- Rezepte ab Phase 6
}

Config.Cooking = {
    time = 5000, anim = { dict = 'amb@world_human_cook@male@base', clip = 'base' },
    recipes = { raw_meat = 'cooked_meat', raw_fish = 'cooked_fish' },
}

-- ─── Stamm ───────────────────────────────────────────────────────────────────
Config.Tribe = { maxMembers = 10, blipSprite = 1, blipColor = 2, stashSlots = 50, stashWeight = 500000 }

-- ─── Fallen (schädigen im Umkreis) ──────────────────────────────────────────
Config.Trap = { radius = 2.2, damage = 25, intervalMs = 1500 }

-- ─── Bauen (Freeform-Builder) ───────────────────────────────────────────────
Config.Building = {
    limitPerTribe = 250, limitPerPlayer = 80, decaySeconds = 604800,
    noBuildRadius = 50.0, maxPlaceDistance = 8.0, cupboardRadius = 40.0,
    upkeep = { startSeconds = 86400, maxSeconds = 604800, secondsPerItem = 3600, items = { 'wood', 'stone', 'scrap_metal' } },
    rotateStep = 45.0, snapGrid = 2.5,
    tiers = {
        wood  = { hp = 350,  label = 'Holz' },
        stone = { hp = 1000, label = 'Stein',  next = 'metal' },
        metal = { hp = 2500, label = 'Metall' },
    },
    upgradePath = {
        wood  = { to = 'stone', cost = { { item = 'stone', count = 10 } } },
        stone = { to = 'metal', cost = { { item = 'metal_ingot', count = 4 }, { item = 'scrap_metal', count = 6 } } },
    },
    raid = {
        enabled = true, noRaidInSafezone = true, reportCooldownMs = 150, maxHitDamage = 350,
        damage = { melee = 8, hatchet = 25, pistol = 4, smg = 5, rifle = 9, shotgun = 14, sniper = 40, explosive = 600 },
        offline = { protected = false, damageMult = 0.25, notifyOwner = true, log = true, logKeepDays = 7 },
        window  = { enabled = false, from = 18, to = 24 },
    },
    integrity = { enabled = true, groundTolerance = 1.4, supportRadius = 3.2, supportDrop = 3.4, lateralTol = 1.2, collapseGraceMs = 6000, sweepMs = 2500 },
    categories = { 'Modular', 'Wände & Cover', 'Dach', 'Türen', 'Lager', 'Stationen', 'Schlafen', 'Licht', 'Verteidigung', 'Möbel & Deko', 'Kern' },
    -- cat: structure | shelter | door | storage | station_campfire | station_workbench | station_forge | bed | light | cupboard | trap
    catalog = {
        wall_wood    = { label = 'Holzzaun-Wand',      model = 'prop_ch2_wdfence_01',  cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 3 } } },
        wall_log     = { label = 'Baumstamm-Barriere', model = 'prop_fnclog_01b',      cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 4 } } },
        wall_fence   = { label = 'Bauzaun',            model = 'prop_const_fence02a',  cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 2 } } },
        wall_conc    = { label = 'Beton-Wandstück',    model = 'prop_wallchunk_01',    cat = 'structure', menu = 'Wände & Cover', tier = 'stone', cost = { { item = 'stone', count = 4 } } },
        barrier_work = { label = 'Absperrung',         model = 'prop_barrier_work06a', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 1 } } },
        pallet       = { label = 'Palette (Cover)',    model = 'prop_pallet_01a',      cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 2 } } },
        wall_sandbag = { label = 'Betonbarriere',      model = 'prop_barier_conc_02a', cat = 'structure', menu = 'Wände & Cover', tier = 'stone', cost = { { item = 'stone', count = 5 } } },
        wall_chain   = { label = 'Maschendraht',       model = 'prop_fnclink_03crnr1', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 3 } } },
        parasol      = { label = 'Sonnensegel',        model = 'prop_beach_parasol_01', cat = 'shelter', menu = 'Dach', cost = { { item = 'plant_fiber', count = 4 }, { item = 'wood', count = 2 } } },
        roof_parasol2= { label = 'Sonnensegel (groß)', model = 'prop_beach_parasol_02', cat = 'shelter', menu = 'Dach', cost = { { item = 'plant_fiber', count = 6 }, { item = 'wood', count = 2 } } },
        gate_door    = { label = 'Tor (öffenbar)',     model = 'prop_gatecom_01',      cat = 'door', menu = 'Türen', cost = { { item = 'wood', count = 5 }, { item = 'scrap_metal', count = 1 } } },
        box_small    = { label = 'Kleine Kiste',       model = 'prop_box_wood01a',     cat = 'storage', menu = 'Lager', slots = 10, weight = 50000,  cost = { { item = 'wood', count = 6 } } },
        crate_large  = { label = 'Große Kiste',        model = 'prop_crate_02a',       cat = 'storage', menu = 'Lager', slots = 25, weight = 150000, cost = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 2 } } },
        locker       = { label = 'Spind',              model = 'prop_toolchest_01',    cat = 'storage', menu = 'Lager', slots = 15, weight = 80000,  cost = { { item = 'scrap_metal', count = 6 } } },
        store_barrel = { label = 'Fass (Lager)',       model = 'prop_barrel_02a',      cat = 'storage', menu = 'Lager', slots = 8,  weight = 40000,  cost = { { item = 'scrap_metal', count = 3 } } },
        store_safe   = { label = 'Tresor',             model = 'prop_ld_int_safe_01',  cat = 'storage', menu = 'Lager', slots = 20, weight = 120000, cost = { { item = 'metal_ingot', count = 2 }, { item = 'scrap_metal', count = 6 } } },
        b_campfire   = { label = 'Lagerfeuer',         model = 'prop_beach_fire',      cat = 'station_campfire',  menu = 'Stationen', cost = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },
        b_workbench  = { label = 'Werkbank',           model = 'prop_tool_bench02',    cat = 'station_workbench', menu = 'Stationen', cost = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 4 } } },
        b_forge      = { label = 'Schmelzofen',        model = 'imp_prop_impexp_anvil_01b', cat = 'station_forge', menu = 'Stationen', cost = { { item = 'stone', count = 12 }, { item = 'scrap_metal', count = 6 }, { item = 'wood', count = 6 } } },
        bed          = { label = 'Schlafplatz',        model = 'prop_skid_sleepbag_1', cat = 'bed', menu = 'Schlafen', cost = { { item = 'plant_fiber', count = 8 }, { item = 'wood', count = 2 } } },
        bed_tent     = { label = 'Zelt (Schlafplatz)', model = 'prop_skid_tent_01',    cat = 'bed', menu = 'Schlafen', cost = { { item = 'plant_fiber', count = 10 }, { item = 'wood', count = 4 } } },
        worklight    = { label = 'Arbeitslampe',       model = 'prop_worklight_03a',   cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 3 } } },
        light_lamp   = { label = 'Standlampe',         model = 'prop_worklight_01a',   cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 2 } } },
        light_flood  = { label = 'Flutlicht',          model = 'prop_worklight_02a',   cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 5 } } },
        trap_strip   = { label = 'Stachelband',        model = 'p_ld_stinger_s',       cat = 'trap', menu = 'Verteidigung', cost = { { item = 'scrap_metal', count = 4 } } },
        def_barrier  = { label = 'Stahl-Absperrung',   model = 'prop_barrier_work05',  cat = 'structure', menu = 'Verteidigung', tier = 'stone', cost = { { item = 'scrap_metal', count = 4 } } },
        furn_table   = { label = 'Tisch',              model = 'prop_table_03',        cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'wood', count = 4 } } },
        furn_chair   = { label = 'Stuhl',              model = 'prop_chair_01a',       cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'wood', count = 2 } } },
        furn_chest   = { label = 'Werkzeugkiste',      model = 'prop_toolchest_04',    cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'scrap_metal', count = 3 } } },
        deco_barrel  = { label = 'Ölfass',             model = 'prop_barrel_02a',      cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'scrap_metal', count = 1 } } },
        -- Modular (bzzz_blocks — separate Streaming-Resource nötig; sonst „Modell nicht verfügbar")
        m_floor_s    = { label = 'Boden (klein)',  model = 'bzzz_blocks_floor_5a',     cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 4 } } },
        m_floor_l    = { label = 'Boden (groß)',   model = 'bzzz_blocks_floor_10a',    cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 8 } } },
        m_wall       = { label = 'Wand (Holz)',    model = 'bzzz_blocks_wall_1a',      cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 4 } } },
        m_wall_metal = { label = 'Wand (Metall)',  model = 'bzzz_blocks_wall_10a',     cat = 'structure', menu = 'Modular', cost = { { item = 'scrap_metal', count = 4 } } },
        m_window     = { label = 'Fenster-Wand',   model = 'bzzz_blocks_window_1a',    cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 3 }, { item = 'scrap_metal', count = 1 } } },
        m_roof       = { label = 'Dach',           model = 'bzzz_blocks_roof_16a',     cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 6 } } },
        m_steps      = { label = 'Treppe',         model = 'bzzz_blocks_steps_5',      cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 5 } } },
        m_fence      = { label = 'Zaun',           model = 'bzzz_blocks_fence_1a',     cat = 'structure', menu = 'Modular', cost = { { item = 'wood', count = 2 } } },
        m_fireplace  = { label = 'Kamin (Wärme)',  model = 'bzzz_blocks_fireplace_1a', cat = 'station_campfire', menu = 'Modular', cost = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },
        cupboard     = { label = 'Versorgungs-Kern', model = 'prop_toolchest_05',     cat = 'cupboard', menu = 'Kern', tier = 'stone', cost = { { item = 'wood', count = 20 }, { item = 'stone', count = 10 }, { item = 'scrap_metal', count = 5 } } },
        trap_spike   = { label = 'Stachelfalle',     model = 'prop_mp_spikes_01',     cat = 'trap', menu = 'Kern', cost = { { item = 'wood', count = 4 }, { item = 'scrap_metal', count = 3 } } },
    },
}

-- ─── KI / Wildtiere ──────────────────────────────────────────────────────────
Config.AI = {
    spawnDistance = 70.0, despawnDistance = 140.0, maxActive = 14, relationshipGroup = 'TFP_HOSTILE',
    ambient = { enabled = true, max = 8, minDist = 30.0, maxDist = 95.0, models = { 'a_c_boar', 'a_c_coyote', 'a_c_rabbit_01', 'a_c_chickenhawk', 'a_c_hen', 'a_c_pig' } },
    zones = { { name = 'Dschungel', center = vec3(4870.0, -5000.0, 5.0), radius = 360.0, kind = 'animal', models = { 'a_c_boar', 'a_c_coyote' }, count = 5 } },
}

-- ─── Jagd / Ausnehmen ────────────────────────────────────────────────────────
Config.Hunt = {
    cooldownMs = 1500, anim = { dict = 'amb@medic@standing@tendtodead@base', clip = 'base' },
    animalYields = { { item = 'raw_meat', min = 1, max = 3 }, { item = 'animal_hide', min = 1, max = 2, chance = 70 } },
    npcYields    = { { item = 'scrap_metal', min = 1, max = 2, chance = 60 }, { item = 'ammo-9', min = 3, max = 10, chance = 40 }, { item = 'bandage', chance = 25 } },
}

Config.LootMultiplier = { chance = 1.35, amount = 1.6 }

-- ─── Loot 2.0 (Welt-Props durchsuchen; Container-Persistenz + Gefahren-Bonus) ─
Config.Loot = {
    cooldownPlayerMs = 800, reLootCooldownMs = 600000, respawnMs = 3600000, searchTime = 3000,
    searchAnim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    dangerBonus = { chance = 45, items = {
        { item = 'blueprint_metalwork', chance = 18 }, { item = 'hazmat_suit', chance = 10 },
        { item = 'metal_ingot', chance = 30, min = 1, max = 2 }, { item = 'ammo-rifle', chance = 35, min = 8, max = 18 },
        { item = 'antibiotics', chance = 25 }, { item = 'fuel', chance = 20 },
    } },
    tables = {
        trash = { label = 'Durchsuchen', icon = 'fa-solid fa-magnifying-glass', respawnMs = 1200000,
            models = { 'prop_dumpster_01a','prop_dumpster_02a','prop_dumpster_3a','prop_dumpster_4a','prop_bin_01a','prop_bin_02a','prop_bin_03a','prop_bin_04a','prop_bin_05a','prop_bin_06a','prop_bin_07a','prop_bin_08a','prop_bin_09a','prop_bin_10a','prop_bin_11a','prop_bin_beach_01a','prop_rub_binbag_01','prop_rub_pile_01' },
            items = { { item = 'scrap_metal', chance = 45, min = 1, max = 2 }, { item = 'plant_fiber', chance = 35, min = 1, max = 2 }, { item = 'wood', chance = 20, min = 1, max = 2 }, { item = 'empty_bottle', chance = 20 }, { item = 'water_dirty', chance = 15 } } },
        container = { label = 'Durchsuchen', icon = 'fa-solid fa-box-open',
            models = { 'prop_box_wood02a','prop_box_wood04a','prop_cardbordbox_01a','prop_cardbordbox_03a','prop_mil_crate_01','v_ind_cs_box01','prop_crate_07a','prop_ld_int_locker_lrg' },
            items = { { item = 'scrap_metal', chance = 40, min = 1, max = 3 }, { item = 'canned_food', chance = 35 }, { item = 'bandage', chance = 25 }, { item = 'painkillers', chance = 18 }, { item = 'disinfectant', chance = 14 }, { item = 'antibiotics', chance = 8 }, { item = 'suture_kit', chance = 10 }, { item = 'tourniquet', chance = 12 }, { item = 'burn_ointment', chance = 10 }, { item = 'firstaid_kit', chance = 6 }, { item = 'blueprint_tools', chance = 4 } } },
        ammo = { label = 'Munition durchsuchen', icon = 'fa-solid fa-bolt',
            models = { 'prop_box_ammo07a','prop_box_ammo04a','prop_box_ammo01a','prop_box_ammo02a','prop_box_ammo05a','prop_box_ammo08a' },
            items = { { item = 'ammo-9', chance = 50, min = 8, max = 20 }, { item = 'ammo-shotgun', chance = 35, min = 4, max = 10 }, { item = 'ammo-rifle', chance = 30, min = 6, max = 15 }, { item = 'ammo-45', chance = 25, min = 6, max = 14 } } },
        military = { label = 'Waffenkiste durchsuchen', icon = 'fa-solid fa-gun', respawnMs = 7200000,
            models = { 'prop_box_guncase_01a','prop_box_guncase_02a','prop_gun_case_01','hei_prop_hei_ammo_pile' },
            items = { { item = 'ammo-rifle', chance = 50, min = 10, max = 30 }, { item = 'ammo-sniper', chance = 20, min = 4, max = 10 }, { item = 'WEAPON_PISTOL', chance = 15 }, { item = 'WEAPON_PUMPSHOTGUN', chance = 8 }, { item = 'WEAPON_ASSAULTRIFLE', chance = 5 }, { item = 'firstaid_kit', chance = 20 }, { item = 'antibiotics', chance = 12 }, { item = 'blood_bag', chance = 12 }, { item = 'suture_kit', chance = 14 }, { item = 'tourniquet', chance = 14 }, { item = 'iv_saline', chance = 12 }, { item = 'painkillers', chance = 20 }, { item = 'blueprint_tools', chance = 8 }, { item = 'blueprint_metalwork', chance = 8 }, { item = 'fuel', chance = 20 }, { item = 'radio_part', chance = 15 }, { item = 'engine_part', chance = 10 }, { item = 'geiger_counter', chance = 12 }, { item = 'hazmat_suit', chance = 7 } } },
        vehicle = { label = 'Fahrzeug durchsuchen', icon = 'fa-solid fa-car-burst', models = {},
            items = { { item = 'scrap_metal', chance = 45, min = 1, max = 3 }, { item = 'engine_part', chance = 12 }, { item = 'empty_bottle', chance = 20 }, { item = 'canned_food', chance = 18 }, { item = 'bandage', chance = 15 }, { item = 'ammo-9', chance = 18, min = 4, max = 10 }, { item = 'radio_part', chance = 6 }, { item = 'fuel', chance = 30 } } },
        wreck = { label = 'Wrack durchsuchen', icon = 'fa-solid fa-anchor', respawnMs = 900000, models = {},
            items = { { item = 'scrap_metal', chance = 60, min = 2, max = 5 }, { item = 'engine_part', chance = 30, min = 1, max = 2 }, { item = 'radio_part', chance = 25 }, { item = 'ammo-rifle', chance = 30, min = 8, max = 20 }, { item = 'firstaid_kit', chance = 25, min = 1, max = 2 }, { item = 'antibiotics', chance = 20 }, { item = 'blood_bag', chance = 18 }, { item = 'suture_kit', chance = 18 }, { item = 'canned_food', chance = 40, min = 1, max = 3 }, { item = 'WEAPON_PUMPSHOTGUN', chance = 10 }, { item = 'blueprint_tools', chance = 12 }, { item = 'hazmat_suit', chance = 10 }, { item = 'fuel', chance = 30 } } },
    },
}

-- ─── Camps / Compounds (Wachen + Loot-Kisten) ────────────────────────────────
Config.Camps = {
    activationDistance = 160.0, crateModel = 'prop_box_ammo07a',
    guardModels = { 'g_m_m_armboss_01', 'g_m_y_armgoon_01', 'g_m_m_armlieut_01', 'g_m_y_armgoon_02' },
    list = {
        { name = 'Verlassenes Lager', center = vec3(4870.0, -5000.0, 5.0), radius = 35.0, guards = 4, weapon = 'WEAPON_MACHETE', accuracy = 20, crates = 2, loot = 'camp', blip = { sprite = 84, color = 1, label = 'Verwildertes Lager' } },
        { name = 'Compound',          center = vec3(5000.0, -5760.0, 15.0), radius = 60.0, guards = 8, weapon = 'WEAPON_CARBINERIFLE', accuracy = 30, crates = 4, loot = 'compound', blip = { sprite = 84, color = 1, label = 'Compound (Hochrisiko)' } },
        { name = 'Landebahn-Depot',   center = vec3(4480.0, -4480.0, 4.0), radius = 55.0, guards = 7, weapon = 'WEAPON_ASSAULTRIFLE', accuracy = 32, crates = 4, loot = 'compound', blip = { sprite = 90, color = 1, label = 'Landebahn-Depot (Hochrisiko)' } },
    },
    loot = {
        camp = { { item = 'scrap_metal', chance = 60, min = 1, max = 3 }, { item = 'ammo-9', chance = 50, min = 5, max = 15 }, { item = 'canned_food', chance = 40 }, { item = 'bandage', chance = 35 }, { item = 'WEAPON_PISTOL', chance = 12 }, { item = 'blueprint_tools', chance = 6 }, { item = 'boots', chance = 14 }, { item = 'rain_jacket', chance = 10 } },
        compound = { { item = 'ammo-rifle', chance = 60, min = 15, max = 40 }, { item = 'ammo-sniper', chance = 25, min = 5, max = 12 }, { item = 'WEAPON_ASSAULTRIFLE', chance = 25 }, { item = 'WEAPON_PUMPSHOTGUN', chance = 20 }, { item = 'WEAPON_SNIPERRIFLE', chance = 8 }, { item = 'firstaid_kit', chance = 40, min = 1, max = 2 }, { item = 'antibiotics', chance = 30 }, { item = 'blueprint_tools', chance = 20 }, { item = 'armor_vest', chance = 14 }, { item = 'metal_helmet', chance = 12 }, { item = 'ghillie_top', chance = 8 } },
    },
}

-- ─── Verstrahlte Festland-Zone ───────────────────────────────────────────────
Config.Radiation = {
    enabled = true, zone = { center = vec3(1090.0, -3000.0, 6.0), radius = 260.0 }, hotzones = 3,
    crateModel = 'prop_box_ammo07a', damagePerTick = 4, hazmatItem = 'hazmat_suit', geigerItem = 'geiger_counter', fx = 'DrugsMichaelAliensFightIn',
    loot = { { item = 'ammo-rifle', chance = 60, min = 20, max = 50 }, { item = 'WEAPON_ASSAULTRIFLE', chance = 35 }, { item = 'WEAPON_SNIPERRIFLE', chance = 15 }, { item = 'firstaid_kit', chance = 50, min = 1, max = 3 }, { item = 'antibiotics', chance = 40, min = 1, max = 2 }, { item = 'blueprint_tools', chance = 30 }, { item = 'engine_part', chance = 20 } },
}

-- ─── Bedrohungslevel (0..100): Nacht + Lärm + Blutung + Isolation ────────────
Config.Dread = {
    enabled         = true,
    nightWeight     = 30,    -- volle Nacht treibt das Bedrohungslevel
    noiseWeight     = 30,    -- Schießen/Sprinten
    bleedWeight     = 15,    -- offene Blutung (Geruch zieht an)
    isolationWeight = 25,    -- weit weg von der Safezone (allein im Dschungel)
    isolationDist   = 250.0,
    spawnScaleMax   = 2.2,   -- bei Threat 100: bis 2,2× Kannibalen-Chance/Anzahl
    dreadMinThreat  = 55,    -- ab hier nächtliche „Schritte im Gebüsch"
    dreadIntervalMs = 22000, -- wie oft ein Dread-Cue kommen kann
}

-- ─── Raubtiere: Hai (Wasser) · Berglöwe (aus) · Kannibalen (Nacht/Lärm) ──────
Config.Predators = {
    relationshipGroup = 'TFP_HOSTILE',  -- gleiche Gruppe wie AI/Camps (konsistente Feindschaft)
    despawnDistance   = 150.0,
    checkIntervalMs   = 3000,

    shark = {
        enabled  = true,
        models   = { 'a_c_sharktiger', 'a_c_sharkhammer' },
        chance   = 22,            -- % pro Check, wenn im tiefen Wasser
        max      = 1,
        minDepth = 1.4,           -- Spieler muss schwimmen
        spawnMin = 18.0, spawnMax = 35.0,
        accuracy = 50,
    },
    land = {
        enabled  = false,         -- Berglöwen DEAKTIVIERT (nervten zu sehr)
        models   = { 'a_c_mtlion' },
        chance   = 12,
        max      = 2,
        spawnMin = 30.0, spawnMax = 70.0,
        accuracy = 30,
    },
    cannibals = {
        enabled   = true,
        models    = { 'a_m_m_hillbilly_01', 'a_m_m_hillbilly_02', 'g_m_y_armgoon_02' },
        weapons   = { 'WEAPON_MACHETE', 'WEAPON_BAT', 'WEAPON_KNIFE' },
        chance    = 40,           -- % pro Check, NUR nachts
        max       = 3,
        nightFrom = 20, nightTo = 6,
        noiseThreshold = 60,      -- ab diesem Lärm kommen sie AUCH tagsüber
        spawnMin  = 45.0, spawnMax = 95.0,
        accuracy  = 22,
        harvest   = 'npc',
    },
}

-- ─── Mehr-Slot-Kleidung mit Schutzwerten ────────────────────────────────────
Config.Clothing = {
    enabled            = true,
    slots              = { 'head', 'torso', 'legs', 'feet' },
    slotLabels         = { head = 'Kopf', torso = 'Oberkörper', legs = 'Beine', feet = 'Füße' },
    slotIcons          = { head = 'fa-solid fa-hat-cowboy', torso = 'fa-solid fa-shirt',
                           legs = 'fa-solid fa-person', feet = 'fa-solid fa-shoe-prints' },
    insulationToWarmth = 0.6,    -- jeder Isolations-Punkt -> Temperatur-Ziel
    waterproofCap      = 90,     -- max % Nässe-Schutz
    armorBleedMax      = 0.6,    -- max Blutungs-Reduktion durch Panzerung (Treffer-Wunden)
    armorBleedDiv      = 100,    -- Panzerung / diesem Wert = Reduktionsfaktor (gekappt auf armorBleedMax)
    pedArmorRegen      = 2,      -- GTA-Panzerung erholt sich/Sek bis zum Kleidungs-Max
    camoThreatFactor   = 0.5,    -- jeder Tarnungspunkt senkt das Bedrohungslevel
    -- Kleidungsstücke (müssen identisch in [ox]/ox_inventory/data/items.lua existieren)
    items = {
        -- Kopf
        fur_hat      = { slot = 'head',  label = 'Fellmütze',        insulation = 18, waterproof = 10 },
        metal_helmet = { slot = 'head',  label = 'Metallhelm',       armor = 25, insulation = 4 },
        camo_hood    = { slot = 'head',  label = 'Tarnkapuze',       camo = 20, insulation = 6 },
        -- Oberkörper
        rain_jacket  = { slot = 'torso', label = 'Regenjacke',       waterproof = 55, insulation = 10 },
        fur_coat     = { slot = 'torso', label = 'Fellmantel',       insulation = 34, waterproof = 10 },
        armor_vest   = { slot = 'torso', label = 'Schutzweste',      armor = 45, insulation = 6 },
        ghillie_top  = { slot = 'torso', label = 'Ghillie-Oberteil', camo = 45, insulation = 12 },
        -- Beine
        fur_pants    = { slot = 'legs',  label = 'Fellhose',         insulation = 20, waterproof = 10 },
        rain_pants   = { slot = 'legs',  label = 'Regenhose',        waterproof = 45 },
        armor_legs   = { slot = 'legs',  label = 'Beinpanzer',       armor = 20 },
        -- Füße
        boots        = { slot = 'feet',  label = 'Stiefel',          insulation = 12, waterproof = 35 },
        camo_boots   = { slot = 'feet',  label = 'Tarnstiefel',      camo = 10, waterproof = 20 },
    },
}

-- ─── Müdigkeit & Schlaf ──────────────────────────────────────────────────────
Config.Fatigue = {
    enabled      = true,
    tickMs       = 30000,    -- alle 30 s
    risePerTick  = 1.0,      -- Müdigkeit +X pro Tick (~50 Min bis voll)
    capStaminaAbove = 60,    -- ab dieser Müdigkeit sinkt das Stamina-Limit
    healOnSleep  = 25,       -- HP-Erholung beim Schlafen
    sleepToHour  = 6,        -- Aufwachzeit nach dem Schlafen
}

-- ─── Tauchen / Sauerstoff ────────────────────────────────────────────────────
Config.Oxygen = {
    enabled     = true,
    drainPerSec = 12,        -- Luft/Sek unter Wasser
    regainPerSec = 35,       -- Erholung über Wasser
    dmgPerSec   = 6,         -- HP/Sek bei 0 Luft (Ertrinken)
}

-- ─── Waffen-Realismus ────────────────────────────────────────────────────────
Config.WeaponRealism = {
    noCrosshair = true,      -- kein Fadenkreuz (hardcore zielen)
    swayOnTired = true,      -- Zittern beim Zielen wenn erschöpft / Armbruch
    swayStamina = 25,        -- unter dieser Ausdauer beginnt das Zittern
}

-- ─── Eigenes Wetter-/Zeitsystem (autoritativ, ersetzt clp_weather) ───────────
Config.Weather = {
    enabled       = true,
    syncTime      = true,
    minutesPerDay = 48,    -- reale Minuten für einen 24h-Zyklus
    startHour     = 8,
    holdMinSec    = 300,   -- ein Wetter hält 5–12 Min
    holdMaxSec    = 720,
    transitionSec = 25,
    types = {              -- gewichtete Auswahl
        { w = 'EXTRASUNNY', weight = 18 },
        { w = 'CLEAR',      weight = 20 },
        { w = 'CLOUDS',     weight = 18 },
        { w = 'OVERCAST',   weight = 14 },
        { w = 'FOGGY',      weight = 8 },
        { w = 'RAIN',       weight = 12 },
        { w = 'THUNDER',    weight = 6 },
        { w = 'CLEARING',   weight = 4 },
    },
}

-- ─── Wiederholbare Survival-Aufgaben (TFP_QuestProgress-Hook) ────────────────
Config.QuestRepeat = true  -- nach Abschluss zurücksetzen → wiederholbar
Config.Quests = {
    { id = 'wood',  label = 'Holzfäller',  desc = 'Sammle 20 Holz',         type = 'item',    key = 'wood',        target = 20, reward = { { item = 'canned_food', count = 2 } } },
    { id = 'scrap', label = 'Sammler',     desc = 'Sammle 25 Schrott',      type = 'item',    key = 'scrap_metal', target = 25, reward = { { item = 'firstaid_kit', count = 1 } } },
    { id = 'fish',  label = 'Fischer',     desc = 'Fange 5 Fische',         type = 'item',    key = 'raw_fish',    target = 5,  reward = { { item = 'water_clean', count = 3 } } },
    { id = 'hunt',  label = 'Jäger',       desc = 'Schlachte 5 Tiere aus',  type = 'harvest', key = 'animal',      target = 5,  reward = { { item = 'cooked_meat', count = 3 } } },
    { id = 'loot',  label = 'Plünderer',   desc = 'Durchsuche 8 Behälter',  type = 'loot',    key = 'any',         target = 8,  reward = { { item = 'bandage', count = 3 } } },
    { id = 'craft', label = 'Handwerker',  desc = 'Stelle 5 Dinge her',     type = 'craft',   key = 'any',         target = 5,  reward = { { item = 'blueprint_tools', count = 1 } } },
    { id = 'build', label = 'Siedler',     desc = 'Platziere 5 Bauten',     type = 'build',   key = 'any',         target = 5,  reward = { { item = 'metal_ingot', count = 2 } } },
}

-- ─── Angeln (braucht Angel + Wasser; server-autoritativer Ertrag) ────────────
Config.Fishing = {
    rodItem = 'fishing_rod',
    time    = 9000,
    anim    = { dict = 'amb@world_human_stand_fishing@idle_a', clip = 'idle_c' },
    yields = {
        { item = 'raw_fish',    min = 1, max = 2, chance = 70 },
        { item = 'raw_fish',    min = 1, max = 1, chance = 25 }, -- zweiter Wurf-Bonus
        { item = 'plant_fiber', min = 1, max = 1, chance = 15 }, -- Seetang/Treibgut
        { item = 'scrap_metal', min = 1, max = 1, chance = 8  }, -- alter Müll
    },
}

-- ─── Versorgungsabwürfe (Timer; kq_airdrop bevorzugt, sonst Fallback) ────────
Config.Airdrop = {
    enabled     = true,
    useKqAirdrop = true,   -- wenn kq_airdrop läuft: dessen Flugzeug/Fallschirm nutzen
    intervalMs  = 1800000, -- alle 30 Minuten
    warnSeconds = 30,
    model       = 'prop_box_ammo07a',
    blipTimeMs  = 600000,
    points = {  -- ⚠️ PLATZHALTER — mit /tfpaddspawn echte Cayo-Punkte erfassen
        vec3(4900.0, -5160.0, 30.0),
        vec3(5000.0, -5760.0, 40.0),
        vec3(4540.0, -4500.0, 30.0),
    },
    loot = {  -- Top-Tier
        { item = 'ammo-rifle',          min = 20, max = 40 },
        { item = 'WEAPON_ASSAULTRIFLE', chance = 40 },
        { item = 'WEAPON_PUMPSHOTGUN',  chance = 30 },
        { item = 'firstaid_kit',        min = 1, max = 2 },
        { item = 'antibiotics',         chance = 50, min = 1, max = 2 },
        { item = 'blueprint_tools',     chance = 25 },
        { item = 'canned_food',         min = 2, max = 4 },
        { item = 'geiger_counter',      chance = 30 },
        { item = 'hazmat_suit',         chance = 18 },
        { item = 'fuel',                chance = 35 },
    },
}

-- ─── Funk, Fahrzeuge, Begleiter ──────────────────────────────────────────────
Config.Radio     = { item = 'radio', minChannel = 1, maxChannel = 99 }
Config.Vehicles  = { boat = { item = 'boat_kit', model = 'dinghy' } } -- wird am/über Wasser gespawnt
Config.Companion = { item = 'dog_whistle', model = 'a_c_shepherd' }

-- ─── Partikel-FX & Sound (SOTF-Juice) ───────────────────────────────────────
Config.FX = {
    enabled        = true,
    gather         = true,   -- Holzspäne/Steinstaub beim Sammeln
    campfireLight  = true,   -- warmes Licht + Glut am Lagerfeuer
    campfireRange  = 14.0,   -- ab welcher Distanz Feuer-FX gerendert werden
    waterSplash    = true,   -- Spritzer beim Eintauchen
    bloodDrips     = true,   -- Bluttropfen am Boden bei starker Blutung
    footDust       = true,   -- Staub beim Sprinten an Land
}

-- Sounds über xsound. URLs/lokale Dateien eintragen → sofort aktiv. Leer = stumm.
Config.Sounds = {
    chop   = '',   -- Axt am Baum
    mine   = '',   -- Stein/Schrott
    gather = '',   -- Pflanzen/Beeren
    fire   = '',   -- Lagerfeuer-Knistern (Loop, am Feuer)
    splash = '',   -- Wasser-Eintauchen
    craft  = '',   -- Handwerk fertig
    whisper = '',  -- nächtliches Flüstern/Stimmen (Dread)
    rustle  = '',  -- Schritte/Rascheln im Gebüsch (Dread)
    collapse = '', -- Bau stürzt ein (Integrität/Raid)
    fireVolume = 0.35,
}

-- ─── Atmosphäre: Lore-Tagebuch + optionaler Insel-Ambient ────────────────────
Config.Atmosphere = {
    warmEmote      = 'crossarms',  -- rpemotes: am Feuer aufwärmen
    heartbeatHpPct = 25,           -- ab dieser HP% pulsiert der Bildschirm (Herzschlag)
    noteProp       = 'prop_cs_documents_01',  -- sichtbarer Papier-Prop an Notiz-Fundorten
    ambient = { enabled = false, url = '', volume = 0.25 },  -- Insel-Ambient (AUS by default)
    loreReward = { { item = 'blueprint_metalwork', count = 1 }, { item = 'metal_ingot', count = 3 } },
    -- Lore-Fundstücke: anvisieren & lesen, im Tagebuch gesammelt (/tagebuch).
    -- ⚠️ Koords teils PLATZHALTER — mit /tfppos an echte Fundorte setzen.
    notes = {
        { coords = vec3(4905.0, -5158.0, 2.1), title = 'Verwittertes Tagebuch — Tag 3',
          text = 'Das Boot ist fort. Funk tot. Ich habe Rauch im Inneren der Insel gesehen — aber kein Mensch winkt dort.\n\nIch bleibe am Strand. Wer das findet: bleib ebenfalls. Geh nicht ins Dickicht.' },
        { coords = vec3(4760.0, -5085.0, 6.0), title = 'Zerfetzte Seite',
          text = 'Sie kommen nur nachts aus den Lagern. Tagsüber sind es nur die Tiere und das Kartell.\n\nMach KEIN Feuer im Dunkeln, wenn du sie nicht anlocken willst. Wärme oder Leben — manchmal beides nicht.' },
        { coords = vec3(5180.0, -4930.0, 9.0), title = 'Notiz am Funkturm',
          text = 'Der Turm lässt sich reparieren — Schrott und ein Funk-Bauteil. Dann ein Boot, Motorteil, ablegen.\n\nDoch das Festland ist verseucht. Ohne Schutzanzug verbrennst du von innen. Erst rüsten, dann fliehen.' },
        { coords = vec3(4980.0, -5360.0, 2.0), title = 'Letzter Eintrag',
          text = 'Wenn du das liest, war ich nicht schnell genug. Vertrau niemandem, der dir nachts „Hilfe" zuruft.\n\nDie Insel will, dass du bleibst. Geh trotzdem.' },
        { coords = vec3(4870.0, -5000.0, 5.5), title = 'Abgefangener Kartell-Funk',
          text = '„…Steg im Süden bleibt besetzt. Keiner verlässt die Insel ohne unsere Erlaubnis."\n\nWenn du fliehen willst, musst du an der Strandwache vorbei. Sie sind zu sechst, schwer bewaffnet.' },
        { coords = vec3(5010.0, -5210.0, 3.0), title = 'Zerkratzte Karte',
          text = 'Ich habe Sprit in den Wracks und alten Fahrzeugen gefunden — vier Kanister reichen fürs Boot.\n\nDie Militärkisten im Compound haben das beste Zeug. Aber dafür musst du an den Wachen vorbei.' },
        { coords = vec3(5055.0, -5150.0, 1.5), title = 'Notiz des Mechanikers',
          text = 'Das Wrack am Strand schwimmt wieder — mit Holz, Metall und einem Motorteil.\n\nIch hatte fast alles zusammen. Dann kam die Nacht. Beeil dich, Fremder. Mach meinen Fehler nicht.' },
        { coords = vec3(4640.0, -4620.0, 4.0), title = 'Die Wahrheit (vergrabener Brief)',
          text = 'Das hier war nie ein Rettungsort. Das Kartell lässt uns überleben, damit wir ihre Lager bewachen — und wer flieht, dient als Warnung.\n\nDer Funkturm ruft keine Rettung. Er ruft DICH zum Boot. Nimm es. Verschwinde. Schau nicht zurück.' },
    },
}

-- ─── Story-Flucht: mehrstufig (tfp_player.escape_step), On-Screen Ziel-Tracker ─
Config.Escape = {
    enabled    = true,
    blipSprite = 309,
    -- einmalige Einleitung beim allerersten Spawn (Story-Aufhänger)
    intro = 'Im Funk nur Rauschen. Irgendwo auf der Insel steht ein alter Funkturm — dein einziger Draht nach draußen. Bring ihn zum Laufen, besorg ein Boot und einen Weg an der Strandwache vorbei. Dein Ziel siehst du oben links (Taste K oder /ziel zum Ein-/Ausblenden).',
    steps = {
        { id = 1, label = 'Funkturm reparieren', coords = vec3(5189.0, -4924.0, 10.0),
          story = 'Der Funkmast ist verrottet — mit Schrott und einem Funkteil kriegst du ihn ans Netz.',
          hint  = 'Sammle Schrott (Wracks/Fahrzeuge) und ein Funkteil, dann zum Funkturm.',
          need = { { item = 'scrap_metal', count = 15 }, { item = 'radio_part', count = 1 } },
          done = 'Der Turm summt. Eine Stimme im Rauschen: „…schaff dir ein Boot — und Sprit." ' },
        { id = 2, label = 'Treibstoff bunkern', coords = vec3(4970.0, -5120.0, 2.0),
          story = 'Ohne Sprit kommst du keine Meile weit. Fahrzeuge, Wracks und Militärkisten haben welchen.',
          hint  = 'Beschaffe 4 Treibstoff und bring sie zum Hafen.',
          need = { { item = 'fuel', count = 4 } },
          done = 'Treibstoff verstaut — jetzt das Boot herrichten.' },
        { id = 3, label = 'Boot herrichten', coords = vec3(5050.0, -5150.0, 1.0),
          story = 'Am Strand liegt ein altes Wrack. Mit Holz, Metall und einem Motor wird daraus ein seetüchtiges Boot.',
          hint  = 'Bring 20 Holz, 10 Schrott und ein Motorteil zum Wrack.',
          need = { { item = 'wood', count = 20 }, { item = 'scrap_metal', count = 10 }, { item = 'engine_part', count = 1 } },
          done = 'Das Boot ist startklar — doch das Kartell riegelt den Strand ab!' },
        { id = 4, label = 'Strandwache durchbrechen & ablegen', coords = vec3(5055.0, -5155.0, 1.0),
          story = 'Letzte Hürde: bewaffnete Kartell-Wachen am Steg. Kämpf dich durch — und leg ab.',
          hint  = 'Schalte die Strandwache aus, dann am Boot ablegen.',
          guards = { count = 6, weapon = 'WEAPON_CARBINERIFLE', accuracy = 28, radius = 50.0,
                     models = { 'g_m_y_armgoon_02', 'g_m_m_armboss_01' } },
          need = {}, escape = vec3(1090.0, -3000.0, 6.0) },
    },
}

-- ─── Dynamisches Wrack-Event (Timer) + Unterwasser-Tauch-Spots ──────────────
Config.WreckEvent = {
    enabled     = true,
    firstDelayMs = 120000,  -- erstes Wrack ~2 Min nach Start
    intervalMs  = 1200000,  -- danach alle 20 Min
    despawnMs   = 900000,   -- 15 Min sichtbar
    blipSprite = 455, blipColor = 5,
    points = {  -- ⚠️ PLATZHALTER (mit /tfpaddspawn echte Cayo-Punkte erfassen)
        { coords = vec3(4960.0, -5360.0, 2.0), prop = 'prop_wreck_truck_01' },
        { coords = vec3(4640.0, -4620.0, 3.0), prop = 'prop_wreck_van' },
        { coords = vec3(5180.0, -5020.0, 2.0), prop = 'prop_byard_wreck01' },
    },
    crateProp = 'prop_box_ammo07a',
    loot = 'wreck',  -- nutzt Config.Loot.tables.wreck (first come, einmalig)
}

Config.Wrecks = {
    enabled = true,
    spots = {  -- ⚠️ PLATZHALTER (echte Cayo-Riff/Wrack-Punkte mit Editor setzen)
        vec3(5300.0, -5500.0, -18.0),
        vec3(4500.0, -5700.0, -22.0),
        vec3(5600.0, -5100.0, -15.0),
    },
    crateProp = 'prop_box_ammo04a',
    reLootCooldownMs = 900000,  -- 15 Min bis derselbe Spot wieder was gibt
    loot = 'wreck',
}

-- ─── Dynamische Welt-Events (eins gleichzeitig, gewichteter Scheduler) ───────
Config.WorldEvents = {
    enabled      = true,
    firstDelayMs = 240000,   -- erstes Event ~4 Min nach Start
    intervalMs   = 540000,   -- danach ~9 Min
    jitterMs     = 180000,   -- + 0..3 Min Zufall
    despawnMs    = 420000,   -- Event bleibt ~7 Min
    announceAll  = true,
    events = {
        {
            key = 'distress', weight = 40, label = 'Notsignal',
            announce = 'Ein Notsignal steigt auf — dort wartet ein Vorrat. Aber du bist vielleicht nicht allein.',
            blip = { sprite = 161, color = 1, scale = 1.0 },
            crates = { { loot = 'military' } },
            ambush = { chance = 55 },  -- Kannibalen-Hinterhalt beim Plündern
            points = { vec3(4980.0, -5360.0, 2.0), vec3(4760.0, -5085.0, 6.0), vec3(5010.0, -5210.0, 3.0), vec3(4905.0, -5158.0, 2.1) },
        },
        {
            key = 'cargo', weight = 30, label = 'Frachtabsturz',
            announce = 'Ein Frachtflugzeug ist abgestürzt — Vorräte! Aber das Kartell sichert die Trümmer bereits.',
            blip = { sprite = 90, color = 5, scale = 1.1 },
            crates = { { loot = 'compound' }, { loot = 'compound' } },
            guards = { count = 4, weapon = 'WEAPON_CARBINERIFLE', accuracy = 26 },
            points = { vec3(4480.0, -4480.0, 4.0), vec3(4640.0, -4620.0, 4.0), vec3(5000.0, -5760.0, 15.0) },
        },
        {
            key = 'pack', weight = 30, label = 'Kannibalen-Rudel',
            announce = 'Schreie im Dickicht — ein Rudel streift in der Nähe. Bleib wachsam.',
            noBlip = true, pack = true,
            points = { vec3(4870.0, -5000.0, 5.0), vec3(4760.0, -5085.0, 6.0) },
        },
    },
}

-- ─── Überlebende: finden, helfen → werden Begleiter (folgen & kämpfen) ──────
Config.Survivors = {
    enabled         = true,
    models          = { 'a_m_y_hiker_01', 'a_m_m_hillbilly_01', 'a_f_y_hiker_01', 'a_m_m_farmer_01', 'a_m_y_beach_01' },
    activateDist    = 65.0,
    despawnDist     = 130.0,
    rescueTime      = 3500,
    respawnCooldown = 1800000, -- 30 Min, bis derselbe Fundort wieder jemanden hat
    companionWeapon = 'WEAPON_PISTOL',
    reward          = { { item = 'canned_food', count = 2 }, { item = 'bandage', count = 1 } },
    spawns = {  -- ⚠️ PLATZHALTER (mit /tfppos an stimmungsvolle Spots setzen)
        vec3(4760.0, -5085.0, 6.0), vec3(5010.0, -5210.0, 3.0), vec3(4870.0, -5000.0, 5.0),
        vec3(4980.0, -5360.0, 2.0), vec3(5180.0, -4930.0, 9.0), vec3(4905.0, -5158.0, 2.1),
    },
}

-- ─── Schwarzmarkt-Händler (Tausch-NPC, kein Geld — reiner Barter) ────────────
Config.Trader = {
    enabled = true,
    ped     = 'mp_m_shopkeep_01',
    coords  = vec4(4895.0, -5165.0, 2.0, 200.0),  -- ⚠️ PLATZHALTER (mit /tfppos erfassen)
    blip    = { sprite = 52, color = 2, label = 'Schwarzmarkt' },
    offers = {
        { label = '3 Tierfell → 2 Konserven',            give = { { item = 'animal_hide', count = 3 } },                                 get = { item = 'canned_food', count = 2 } },
        { label = '10 Schrott → 24× 9mm',                give = { { item = 'scrap_metal', count = 10 } },                                get = { item = 'ammo-9', count = 24 } },
        { label = '3 gegart. Fleisch → Antibiotika',     give = { { item = 'cooked_meat', count = 3 } },                                 get = { item = 'antibiotics', count = 1 } },
        { label = '2 Metallbarren → 1 Treibstoff',       give = { { item = 'metal_ingot', count = 2 } },                                 get = { item = 'fuel', count = 1 } },
        { label = '4 Leder → Pistole',                   give = { { item = 'leather', count = 4 } },                                     get = { item = 'WEAPON_PISTOL', count = 1 } },
        { label = '15 Schrott + 4 Leder → Schrotflinte', give = { { item = 'scrap_metal', count = 15 }, { item = 'leather', count = 4 } }, get = { item = 'WEAPON_PUMPSHOTGUN', count = 1 } },
        { label = '1 Metallbarren → Verband ×3',         give = { { item = 'metal_ingot', count = 1 } },                                 get = { item = 'bandage', count = 3 } },
        { label = '5 Kokosnuss → sauberes Wasser ×3',    give = { { item = 'coconut', count = 5 } },                                     get = { item = 'water_clean', count = 3 } },
    },
}

-- ════════════════════════════════════════════════════════════════════════════
--  Ab PHASE 8: menu (F5 + Radial), admin (+server), editor (Koords-Helfer),
--  Politur (Theme/HUD-Feinschliff, clp_loading).
-- ════════════════════════════════════════════════════════════════════════════
