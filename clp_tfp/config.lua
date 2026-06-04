Config = {}

-- Debug aktiviert Test-Befehle (/tfpset, /tfpfire), Zonen-Anzeige und Prints
-- false = saubere Konsole/keine sichtbaren Debug-Zonen. /tfppos & /tfpmodel bleiben verfügbar.
Config.Debug = false

Config.TickMs = 1000            -- nur informativ; echtes Tick-Intervall steuert esx_status (Config.TickTime)
Config.StatusMax = 1000000      -- MUSS mit esx_status/esx_basicneeds übereinstimmen
Config.WarnCooldownMs = 20000   -- Mindestabstand gleicher Warn-Notifications

-- Globale Loot-Balance ("großzügig"): gilt für alle Server-Loot-Rolls (TFP_RollGive)
Config.LootMultiplier = { chance = 1.35, amount = 1.6 }

-- Wetter-Typen, die als "Regen" zählen (für Nässe/Temperatur)
Config.RainyWeathers = { 'RAIN', 'THUNDER', 'CLEARING' }

-- Feuer-Erkennung (Slice 1: Nähe zu vorhandenen Feuer-Props = Wärmequelle)
Config.FireRadius = 4.5
Config.FireModels = {
    'prop_beach_fire', 'prop_fire_logs_01', 'prop_fire_logs_02', 'prop_fire_logs_03',
    'prop_bbq_3', 'prop_bbq_4', 'prop_bbq_5',
    'bzzz_blocks_fireplace_1a', 'bzzz_blocks_fireplace_1b',
}

-- ─── Slice 2: Items / Konsum ─────────────────────────────────────────────────
Config.DirtyWaterSicknessChance = 35    -- % Chance auf Cholera beim Trinken von dreckigem Wasser
Config.MedkitHeal = 40                  -- HP-Heilung durch Erste-Hilfe-Set
Config.CampfireModel = 'prop_beach_fire'

-- ─── spawn/ : Verstreutes Spawnen + Starter-Kit + Schlafsack-Respawn ─────────
Config.Spawn = {
    respawnDelayMs   = 5000,                       -- Wartezeit nach Tod bis Respawn
    sleepingBagModel = 'prop_skid_sleepbag_1',

    -- Starter-Kit (Entscheidung #13). Lumpen-Kleidung = appearance (separat).
    starterKit = {
        { name = 'WEAPON_FLASHLIGHT', count = 1 }, -- Fackel-Ersatz (Licht bei Nacht)
        { name = 'WEAPON_HATCHET',    count = 1 }, -- Steinaxt-Ersatz (bis Crafting steht)
        { name = 'empty_bottle',      count = 1 },
        { name = 'bandage',           count = 2 },
        { name = 'canned_food',       count = 1 },
    },

    -- ⚠️ PLATZHALTER-Strandpunkte auf Cayo Perico! In-Game mit /tfpaddspawn (oder
    --    clp_coordcopy) echte Punkte erfassen & ersetzen. Cayo muss via world/ +
    --    bob74_ipl aktiv sein, sonst landet man im Wasser/Void.
    points = {
        vec4(4895.0, -5160.0, 2.0, 200.0),
        vec4(5060.0, -5130.0, 2.0, 250.0),
        vec4(5189.0, -4924.0, 2.0, 300.0),
        vec4(4530.0, -4500.0, 3.0, 130.0),
        vec4(4360.0, -4760.0, 3.0,  90.0),
        vec4(4720.0, -5760.0, 2.0,   0.0),
    },
}

-- ─── world/ : Cayo Perico aktivieren + Lore-Safezone ─────────────────────────
Config.World = {
    enableIsland = true,
    islandName   = 'HeistIsland',
    islandCenter = vec3(4840.0, -5174.0, 2.0),  -- grober Insel-Mittelpunkt (Minimap-Umschaltung)
    islandRadius = 1800.0,
    safezone = {
        enabled = true,
        center  = vec3(4895.0, -5160.0, 2.0),    -- mit /tfpaddspawn am Strandlager exakt erfassen
        radius  = 45.0,
        label   = 'Strandlager',
    },
}

-- ─── gathering/ : Ressourcen an Welt-Props sammeln (ox_target) ────────────────
Config.Gathering = {
    cooldownMs = 1500,  -- Server-Spam-Schutz pro Spieler
    toolDurabilityLoss = 5,  -- Werkzeug-Abnutzung pro Einsatz (0..100; bei 0 zerbricht es)
    nodes = {
        tree = {
            label = 'Baum fällen', icon = 'fa-solid fa-tree', usetime = 4500,
            global = true,   -- ox_target an JEDEM passenden Objekt (auch Map-Bäumen), nicht nur Skript-Props
            tool = 'WEAPON_HATCHET',
            emote = 'axe2',  -- rpemotes-reborn: Axt-Schlag in Schleife (mit Feueraxt-Prop)
            anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },  -- Fallback ohne rpemotes
            yields = {
                { item = 'wood',    min = 2, max = 4 },
                { item = 'coconut', min = 1, max = 1, chance = 40 },
            },
            -- Umfassende Baum-/Palmen-Liste (GTA + Cayo). Mit global=true wird JEDES
            -- Objekt mit einem dieser Modelle erkannt — auch Map-eingebettete Bäume.
            -- Bleibt ein Baum unerkannt: Config.Debug=true + /tfpmodel anvisieren → Hash hier ergänzen.
            models = {
                -- Palmen (Cayo/Strand)
                'prop_palm_huge_01a','prop_palm_huge_01b',
                'prop_palm_med_01a','prop_palm_med_01b','prop_palm_med_01c','prop_palm_med_01d',
                'prop_palm_sm_01a','prop_palm_sm_01b','prop_palm_sm_01c','prop_palm_sm_01d','prop_palm_sm_01e','prop_palm_sm_01f',
                'prop_palm_fan_02_a','prop_palm_fan_02_b',
                'prop_palm_fan_03_a','prop_palm_fan_03_b','prop_palm_fan_03_c','prop_palm_fan_03_d',
                'prop_palm_fan_04_a','prop_palm_fan_04_b','prop_palm_fan_04_c','prop_palm_fan_04_d',
                'prop_fan_palm_01a','prop_palm2_xmas','prop_desert_palm_01','prop_lt_palm_01',
                'prop_palmdead_01_b','prop_palmdead_02_b','prop_palmdead_03_b','prop_palmdead_04_b','prop_palmdead_05_b','prop_palmdead_03_c',
                -- Laub-/Nadelbäume (Festland + Insel)
                'prop_tree_birch_01','prop_tree_birch_02','prop_tree_birch_03','prop_tree_birch_03b','prop_tree_birch_04','prop_tree_birch_05',
                'prop_tree_cedar_02','prop_tree_cedar_03','prop_tree_cedar_04','prop_tree_cedar_s_01','prop_tree_cedar_s_04','prop_tree_cedar_s_05','prop_tree_cedar_s_06',
                'prop_tree_cypress_01','prop_tree_eng_oak_01','prop_tree_eucalip_01','prop_tree_fallen_pine_01',
                'prop_tree_jacada_01','prop_tree_jacada_02','prop_tree_lficus_02','prop_tree_lficus_03','prop_tree_lficus_05','prop_tree_lficus_06',
                'prop_tree_maple_02','prop_tree_maple_03','prop_tree_mquite_01','prop_tree_oak_01','prop_tree_olive_01',
                'prop_tree_pine_01','prop_tree_pine_02','prop_tree_stump_01','prop_s_pine_dead_01',
                'prop_w_r_cedar_01','prop_w_r_cedar_dead','prop_rio_tree_01','prop_rio_tree_02','prop_rio_tree_03',
                'prop_bushytree_01','prop_veg_crop_tr_01','prop_veg_crop_tr_02',
                'test_tree_cedar_trunk_001','test_tree_forest_trunk_01','test_tree_forest_trunk_04','test_tree_forest_trunk_base_01',
            },
        },
        rock = {
            label = 'Stein abbauen', icon = 'fa-solid fa-gem', usetime = 4000,
            emote = 'dig',  -- rpemotes-reborn: Graben/Hacken mit Schaufel-Prop
            anim = { dict = 'random@burial', clip = 'a_burial' },
            yields = { { item = 'stone', min = 1, max = 3 } },
            models = {
                'prop_rock_1_a','prop_rock_1_b','prop_rock_1_c','prop_rock_2_a','prop_rock_2_b',
                'prop_rock_3_a','prop_rock_4_a','prop_rock_4_b','prop_rock_4_c','prop_rock_5_a',
                'prop_rock_5_b','prop_rock_6_a','prop_rock_7_a','prop_rock_7_b',
            },
        },
        bush = {
            label = 'Pflanzen sammeln', icon = 'fa-solid fa-seedling', usetime = 2500,
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            yields = { { item = 'plant_fiber', min = 1, max = 3 } },
            models = {
                'prop_bush_lrg_04b','prop_bush_lrg_04c','prop_bush_lrg_04d','prop_bush_med_05',
                'prop_bush_med_07','prop_bush_neat_01','prop_bush_dst_01','prop_bush_dst_03',
            },
        },
        berry = {
            label = 'Beeren/Früchte sammeln', icon = 'fa-solid fa-apple-whole', usetime = 2500,
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            yields = {
                { item = 'berries',     min = 1, max = 3 },
                { item = 'plant_fiber', min = 1, max = 1, chance = 30 },
            },
            models = {
                'prop_bush_med_02','prop_bush_med_03','prop_bush_med_04',
                'prop_bush_lrg_01b','prop_bush_lrg_02b','prop_bush_lrg_03b',
            },
        },
        scrap = {
            label = 'Schrott bergen', icon = 'fa-solid fa-screwdriver-wrench', usetime = 3500,
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
            yields = { { item = 'scrap_metal', min = 1, max = 2 } },
            -- Modelle aus dem vorhandenen kq_propplacer 'Trash'-Katalog (real existent)
            models = {
                'prop_rub_tyre_01','prop_rub_washer_01','prop_rub_couch01','prop_rub_generator',
                'prop_rub_cabinet','prop_rub_boxpile_02',
            },
        },
    },
}

-- ─── crafting/ : Rezepte (Stationen: hand, campfire, workbench) + Blueprints ──
Config.Crafting = {
    recipes = {
        campfire_kit       = { station = 'hand',      label = 'Lagerfeuer-Set',  time = 4000, output = { item = 'campfire_kit', count = 1 }, ingredients = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },
        stone_axe          = { station = 'hand',      label = 'Steinaxt',        time = 5000, output = { item = 'WEAPON_HATCHET', count = 1 }, ingredients = { { item = 'stone', count = 3 }, { item = 'plant_fiber', count = 2 } } }, -- bootstrap: Stein+Faser brauchen KEIN Werkzeug

        craft_bandage      = { station = 'hand',      label = 'Verband',         time = 3000, output = { item = 'bandage', count = 1 }, ingredients = { { item = 'plant_fiber', count = 3 } } },
        craft_bottle       = { station = 'hand',      label = 'Leere Flasche',   time = 2500, output = { item = 'empty_bottle', count = 1 }, ingredients = { { item = 'scrap_metal', count = 1 } } },
        workbench_kit      = { station = 'campfire',  label = 'Werkbank-Set',    time = 6000, output = { item = 'workbench_kit', count = 1 }, ingredients = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 4 } } },
        cook_meat          = { station = 'campfire',  label = 'Fleisch braten',  time = 4000, output = { item = 'cooked_meat', count = 1 }, ingredients = { { item = 'raw_meat', count = 1 } } },
        craft_hammer       = { station = 'workbench', label = 'Hammer',          time = 4000, output = { item = 'hammer', count = 1 }, ingredients = { { item = 'wood', count = 4 }, { item = 'scrap_metal', count = 2 } } },
        craft_sleeping_bag = { station = 'workbench', label = 'Schlafsack',      time = 5000, output = { item = 'sleeping_bag', count = 1 }, ingredients = { { item = 'plant_fiber', count = 8 }, { item = 'wood', count = 2 } } },
        craft_warm_clothing = { station = 'workbench', label = 'Fellkleidung (Wärme)', time = 6000, output = { item = 'warm_clothing', count = 1 }, ingredients = { { item = 'leather', count = 2 }, { item = 'plant_fiber', count = 4 } } },
        craft_firstaid     = { station = 'workbench', label = 'Erste-Hilfe-Set', time = 6000, blueprint = 'blueprint_tools', output = { item = 'firstaid_kit', count = 1 }, ingredients = { { item = 'bandage', count = 2 }, { item = 'plant_fiber', count = 3 } } },
        craft_radio        = { station = 'workbench', label = 'Funkgerät',      time = 5000, output = { item = 'radio', count = 1 }, ingredients = { { item = 'scrap_metal', count = 4 }, { item = 'radio_part', count = 1 } } },
        craft_boat         = { station = 'workbench', label = 'Boots-Bausatz',  time = 8000, output = { item = 'boat_kit', count = 1 }, ingredients = { { item = 'wood', count = 25 }, { item = 'scrap_metal', count = 12 }, { item = 'engine_part', count = 1 } } },
        craft_whistle      = { station = 'workbench', label = 'Hundepfeife',    time = 3000, output = { item = 'dog_whistle', count = 1 }, ingredients = { { item = 'scrap_metal', count = 2 } } },
        craft_splint       = { station = 'hand',      label = 'Schiene',        time = 3000, output = { item = 'splint', count = 1 }, ingredients = { { item = 'wood', count = 2 }, { item = 'plant_fiber', count = 2 } } },
        craft_fishing_rod  = { station = 'hand',      label = 'Angel',          time = 4000, output = { item = 'fishing_rod', count = 1 }, ingredients = { { item = 'wood', count = 2 }, { item = 'plant_fiber', count = 3 } } },
        craft_suture       = { station = 'workbench', label = 'Nähset',         time = 4000, output = { item = 'suture_kit', count = 1 }, ingredients = { { item = 'plant_fiber', count = 3 }, { item = 'scrap_metal', count = 1 } } },
        -- ── Progression: Gerben (Fell→Leder) & Schmelzen (Schrott→Barren) ──
        tan_leather        = { station = 'workbench', label = 'Leder gerben',   time = 4500, output = { item = 'leather', count = 1 }, ingredients = { { item = 'animal_hide', count = 2 } } },
        smelt_ingot        = { station = 'forge',     label = 'Metallbarren schmelzen', time = 6000, output = { item = 'metal_ingot', count = 1 }, ingredients = { { item = 'scrap_metal', count = 3 } } },
        -- ── Tier 2 (Forschung nötig): Lederpanzer aus Leder + Barren ──
        craft_armor        = { station = 'workbench', label = 'Lederpanzer',    time = 7000, blueprint = 'blueprint_metalwork', output = { item = 'armour', count = 1 }, ingredients = { { item = 'leather', count = 4 }, { item = 'metal_ingot', count = 2 } } },
    },
}

Config.Blueprints = {
    blueprint_tools     = { label = 'Bauplan: Werkzeuge & Medizin', recipes = { 'craft_firstaid' } },
    blueprint_metalwork = { label = 'Bauplan: Metallverarbeitung',  recipes = { 'craft_armor' } },
}

-- ─── building/ : Vollwertiger Freeform-Builder (Phase 2 "Sesshaft") ──────────
Config.Building = {
    limitPerTribe    = 250,     -- Bau-Limit pro Stamm (Entscheidung #20)
    limitPerPlayer   = 80,      -- Limit für Solo-Spieler ohne Stamm
    decaySeconds     = 604800,  -- 7 Tage Verfall (außer im Cupboard-Radius)
    noBuildRadius    = 50.0,    -- kein Bauen nahe Safezone-Center
    maxPlaceDistance = 8.0,     -- max. Reichweite der Platzierung
    cupboardRadius   = 40.0,    -- Schutz-/Territorien-Radius des Versorgungs-Kerns
    -- Upkeep: Kern muss mit Material gefüttert werden, sonst verfällt die Basis (Rust-Style)
    upkeep = {
        startSeconds     = 86400,    -- frischer Kern hält 24 h
        maxSeconds       = 604800,   -- max. 7 Tage Vorrat
        secondsPerItem   = 3600,     -- jedes eingelagerte Material = +1 h
        items            = { 'wood', 'stone', 'scrap_metal' },
    },
    rotateStep       = 45.0,    -- Mausrad-Drehschritt (Grad)
    snapGrid         = 2.5,     -- Raster im Snap-Modus (ALT) — an bzzz_blocks-Maße anpassen

    -- ── Bau-Tiers (HP) & Verstärken (Holz→Stein→Metall) ──
    tiers = {
        wood  = { hp = 350,  label = 'Holz' },
        stone = { hp = 1000, label = 'Stein',  next = 'metal', upgradeCost = { { item = 'stone', count = 10 } } },
        metal = { hp = 2500, label = 'Metall', upgradeCost = nil },  -- höchste Stufe
    },
    -- Reihenfolge der Verstärkung + Kosten je Schritt
    upgradePath = {
        wood  = { to = 'stone', cost = { { item = 'stone', count = 10 } } },
        stone = { to = 'metal', cost = { { item = 'metal_ingot', count = 4 }, { item = 'scrap_metal', count = 6 } } },
    },

    -- ── Raid: Bauten beschädigen/zerstören (server-autoritativ) ──
    raid = {
        enabled        = true,
        noRaidInSafezone = true,
        reportCooldownMs = 150,   -- Spam-Schutz pro Spieler
        maxHitDamage   = 350,     -- Obergrenze pro gemeldetem Treffer (Anti-Cheat)
        -- Schaden je Waffenklasse pro Treffer
        damage = { melee = 8, hatchet = 25, pistol = 4, smg = 5, rifle = 9, shotgun = 14, sniper = 40, explosive = 600 },
    },
    categories = { 'Modular', 'Wände & Cover', 'Dach', 'Türen', 'Lager', 'Stationen', 'Schlafen', 'Licht', 'Verteidigung', 'Möbel & Deko', 'Kern' },
    -- cat: structure | shelter | door | storage | station_campfire | station_workbench | bed | light | cupboard
    catalog = {
        wall_wood    = { label = 'Holzzaun-Wand',     model = 'prop_ch2_wdfence_01', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 3 } } },
        wall_log     = { label = 'Baumstamm-Barriere', model = 'prop_fnclog_01b',    cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 4 } } },
        wall_fence   = { label = 'Bauzaun',            model = 'prop_const_fence02a', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 2 } } },
        wall_conc    = { label = 'Beton-Wandstück',    model = 'prop_wallchunk_01',   cat = 'structure', menu = 'Wände & Cover', tier = 'stone', cost = { { item = 'stone', count = 4 } } },
        barrier_work = { label = 'Absperrung',         model = 'prop_barrier_work06a', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 1 } } },
        pallet       = { label = 'Palette (Cover)',    model = 'prop_pallet_01a',     cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'wood', count = 2 } } },

        parasol      = { label = 'Sonnensegel',        model = 'prop_beach_parasol_01', cat = 'shelter', menu = 'Dach', cost = { { item = 'plant_fiber', count = 4 }, { item = 'wood', count = 2 } } },

        gate_door    = { label = 'Tor (öffenbar)',     model = 'prop_gatecom_01',     cat = 'door', menu = 'Türen', cost = { { item = 'wood', count = 5 }, { item = 'scrap_metal', count = 1 } } },

        box_small    = { label = 'Kleine Kiste',       model = 'prop_box_wood01a',    cat = 'storage', menu = 'Lager', slots = 10, weight = 50000,  cost = { { item = 'wood', count = 6 } } },
        crate_large  = { label = 'Große Kiste',        model = 'prop_crate_02a',      cat = 'storage', menu = 'Lager', slots = 25, weight = 150000, cost = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 2 } } },
        locker       = { label = 'Spind',              model = 'prop_toolchest_01',   cat = 'storage', menu = 'Lager', slots = 15, weight = 80000,  cost = { { item = 'scrap_metal', count = 6 } } },

        b_campfire   = { label = 'Lagerfeuer',         model = 'prop_beach_fire',     cat = 'station_campfire',  menu = 'Stationen', cost = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },
        b_workbench  = { label = 'Werkbank',           model = 'prop_tool_bench02',   cat = 'station_workbench', menu = 'Stationen', cost = { { item = 'wood', count = 10 }, { item = 'scrap_metal', count = 4 } } },
        b_forge      = { label = 'Schmelzofen (Esse)', model = 'imp_prop_impexp_anvil_01b', cat = 'station_forge', menu = 'Stationen', cost = { { item = 'stone', count = 12 }, { item = 'scrap_metal', count = 6 }, { item = 'wood', count = 6 } } },

        bed          = { label = 'Schlafplatz',        model = 'prop_skid_sleepbag_1', cat = 'bed', menu = 'Schlafen', cost = { { item = 'plant_fiber', count = 8 }, { item = 'wood', count = 2 } } },

        worklight    = { label = 'Arbeitslampe',       model = 'prop_worklight_03a',  cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 3 } } },
        light_lamp   = { label = 'Standlampe',         model = 'prop_worklight_01a',  cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 2 } } },
        light_flood  = { label = 'Flutlicht',          model = 'prop_worklight_02a',  cat = 'light', menu = 'Licht', cost = { { item = 'scrap_metal', count = 5 } } },

        -- ── Wände & Cover (mehr) ──
        wall_sandbag = { label = 'Betonbarriere',      model = 'prop_barier_conc_02a', cat = 'structure', menu = 'Wände & Cover', tier = 'stone', cost = { { item = 'stone', count = 5 } } },
        wall_chain   = { label = 'Maschendraht',       model = 'prop_fnclink_03crnr1', cat = 'structure', menu = 'Wände & Cover', cost = { { item = 'scrap_metal', count = 3 } } },

        -- ── Dach / Schlafen (mehr) ──
        roof_parasol2 = { label = 'Sonnensegel (groß)', model = 'prop_beach_parasol_02', cat = 'shelter', menu = 'Dach', cost = { { item = 'plant_fiber', count = 6 }, { item = 'wood', count = 2 } } },
        bed_tent     = { label = 'Zelt (Schlafplatz)', model = 'prop_skid_tent_01',   cat = 'bed', menu = 'Schlafen', cost = { { item = 'plant_fiber', count = 10 }, { item = 'wood', count = 4 } } },

        -- ── Lager (mehr) ──
        store_barrel = { label = 'Fass (Lager)',       model = 'prop_barrel_02a',     cat = 'storage', menu = 'Lager', slots = 8,  weight = 40000,  cost = { { item = 'scrap_metal', count = 3 } } },
        store_safe   = { label = 'Tresor',             model = 'prop_ld_int_safe_01', cat = 'storage', menu = 'Lager', slots = 20, weight = 120000, cost = { { item = 'metal_ingot', count = 2 }, { item = 'scrap_metal', count = 6 } } },

        -- ── Verteidigung ──
        trap_strip   = { label = 'Stachelband',        model = 'p_ld_stinger_s',      cat = 'trap', menu = 'Verteidigung', cost = { { item = 'scrap_metal', count = 4 } } },
        def_barrier  = { label = 'Stahl-Absperrung',   model = 'prop_barrier_work05', cat = 'structure', menu = 'Verteidigung', tier = 'stone', cost = { { item = 'scrap_metal', count = 4 } } },

        -- ── Möbel & Deko ──
        furn_table   = { label = 'Tisch',              model = 'prop_table_03',       cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'wood', count = 4 } } },
        furn_chair   = { label = 'Stuhl',              model = 'prop_chair_01a',      cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'wood', count = 2 } } },
        furn_chest   = { label = 'Werkzeugkiste',      model = 'prop_toolchest_04',   cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'scrap_metal', count = 3 } } },
        deco_barrel  = { label = 'Ölfass',             model = 'prop_barrel_02a',     cat = 'structure', menu = 'Möbel & Deko', cost = { { item = 'scrap_metal', count = 1 } } },

        -- Modular (bzzz_blocks — escrow-Resource, gestreamte Bauteile, snap-fähig)
        m_floor_s    = { label = 'Boden (klein)',  model = 'bzzz_blocks_floor_5a',     cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 4 } } },
        m_floor_l    = { label = 'Boden (groß)',   model = 'bzzz_blocks_floor_10a',    cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 8 } } },
        m_wall       = { label = 'Wand (Holz)',    model = 'bzzz_blocks_wall_1a',      cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 4 } } },
        m_wall_metal = { label = 'Wand (Metall)',  model = 'bzzz_blocks_wall_10a',     cat = 'structure',        menu = 'Modular', cost = { { item = 'scrap_metal', count = 4 } } },
        m_window     = { label = 'Fenster-Wand',   model = 'bzzz_blocks_window_1a',    cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 3 }, { item = 'scrap_metal', count = 1 } } },
        m_roof       = { label = 'Dach',           model = 'bzzz_blocks_roof_16a',     cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 6 } } },
        m_steps      = { label = 'Treppe',         model = 'bzzz_blocks_steps_5',      cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 5 } } },
        m_fence      = { label = 'Zaun',           model = 'bzzz_blocks_fence_1a',     cat = 'structure',        menu = 'Modular', cost = { { item = 'wood', count = 2 } } },
        m_fireplace  = { label = 'Kamin (Wärme)',  model = 'bzzz_blocks_fireplace_1a', cat = 'station_campfire', menu = 'Modular', cost = { { item = 'wood', count = 5 }, { item = 'stone', count = 3 } } },

        cupboard     = { label = 'Versorgungs-Kern',   model = 'prop_toolchest_05',   cat = 'cupboard', menu = 'Kern', tier = 'stone', cost = { { item = 'wood', count = 20 }, { item = 'stone', count = 10 }, { item = 'scrap_metal', count = 5 } } },
        trap_spike   = { label = 'Stachelfalle',       model = 'prop_mp_spikes_01',   cat = 'trap', menu = 'Kern', cost = { { item = 'wood', count = 4 }, { item = 'scrap_metal', count = 3 } } },
    },
}

-- ─── tribe/ : Stämme, Ränge, geteilter Zugriff, Marker ───────────────────────
Config.Tribe = {
    maxMembers  = 10,
    blipSprite  = 1,
    blipColor   = 2,   -- grün
    stashSlots  = 50,
    stashWeight = 500000,  -- 500 kg geteilter Stamm-Stash
}

-- ─── threat/ : Tod, Loot-Drop ────────────────────────────────────────────────
Config.Threat = {
    dropInventoryOnDeath = true,  -- gesamtes Inventar als lootbaren Beutel fallen lassen
    deathLogHours        = 12,    -- Spieler-Tode nur so lange im Admin-Log behalten (dann auto-gelöscht)
    downed = {
        enabled         = true,
        bleedoutSeconds = 120,    -- Zeit im Downed-Zustand bis zum endgültigen Tod
        reviveItem      = 'firstaid_kit',
        reviveSeconds   = 6,
    },
}

-- ─── ai/ : wilde Tiere + Aggro-NPCs in Gefahrenzonen ─────────────────────────
-- ⚠️ Zonen-Koords sind PLATZHALTER — mit /tfpaddspawn auf Cayo erfassen.
Config.AI = {
    spawnDistance     = 70.0,
    despawnDistance   = 140.0,
    maxActive         = 14,        -- gleichzeitige Aggro-Feinde
    relationshipGroup = 'TFP_HOSTILE',
    -- Ambient-Wildtiere ÜBERALL (außer Safezone) — belebt die Insel, jagdbar
    ambient = {
        enabled = true,
        max     = 8,
        minDist = 30.0,
        maxDist = 95.0,
        models  = { 'a_c_boar', 'a_c_coyote', 'a_c_rabbit_01', 'a_c_chickenhawk', 'a_c_hen', 'a_c_pig' },
    },
    zones = {
        { name = 'Dschungel', center = vec3(4870.0, -5000.0, 5.0),  radius = 360.0, kind = 'animal',
          models = { 'a_c_boar', 'a_c_coyote' }, count = 5 },
        -- NPC-Gefahr (Lager/Compound) übernimmt jetzt camps/ (Config.Camps)
    },
}

-- ─── loot/ : Welt-Props durchsuchen (ox_target) ──────────────────────────────
Config.Loot = {
    cooldownPlayerMs = 800,        -- Server-Spam-Schutz pro Spieler
    reLootCooldownMs = 600000,     -- 10 Min bis dasselbe Objekt erneut etwas gibt
    searchTime       = 3000,
    searchAnim       = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    tables = {
        trash = {
            label = 'Durchsuchen', icon = 'fa-solid fa-magnifying-glass',
            models = { 'prop_dumpster_01a','prop_dumpster_02a','prop_dumpster_3a','prop_dumpster_4a',
                       'prop_bin_01a','prop_bin_02a','prop_bin_03a','prop_bin_04a','prop_bin_05a',
                       'prop_bin_06a','prop_bin_07a','prop_bin_07b','prop_bin_07c','prop_bin_07d',
                       'prop_bin_08a','prop_bin_08open','prop_bin_09a','prop_bin_10a','prop_bin_10b',
                       'prop_bin_11a','prop_bin_11b','prop_bin_12a','prop_bin_13a','prop_bin_14a',
                       'prop_bin_beach_01a','prop_bin_beach_01d','prop_recyclebin_03_a','prop_recyclebin_04_a',
                       'prop_rub_binbag_01','prop_rub_binbag_03','prop_rub_binbag_05','prop_rub_binbag_sd_01',
                       'prop_cs_street_binbag_01','prop_rub_trash_pile_01','prop_rub_pile_01','prop_rub_pile_04' },
            items = {
                { item = 'scrap_metal',  chance = 45, min = 1, max = 2 },
                { item = 'plant_fiber',  chance = 35, min = 1, max = 2 },
                { item = 'wood',         chance = 20, min = 1, max = 2 },
                { item = 'empty_bottle', chance = 20 },
                { item = 'water_dirty',  chance = 15 },
            },
        },
        container = {
            label = 'Durchsuchen', icon = 'fa-solid fa-box-open',
            models = { 'prop_box_wood02a','prop_box_wood04a','prop_cardbordbox_01a','prop_cardbordbox_03a',
                       'prop_mil_crate_01','v_ind_cs_box01','prop_crate_07a',
                       'prop_ld_int_locker_lrg','v_ind_cm_lockerc' },
            items = {
                { item = 'scrap_metal',     chance = 40, min = 1, max = 3 },
                { item = 'canned_food',     chance = 35 },
                { item = 'bandage',         chance = 25 },
                { item = 'painkillers',     chance = 18 },
                { item = 'disinfectant',    chance = 14 },
                { item = 'antibiotics',     chance = 8 },
                { item = 'suture_kit',      chance = 10 },
                { item = 'firstaid_kit',    chance = 6 },
                { item = 'blueprint_tools', chance = 4 },
            },
        },
        ammo = {
            label = 'Munition durchsuchen', icon = 'fa-solid fa-bolt',
            models = { 'prop_box_ammo07a', 'prop_box_ammo04a', 'prop_box_ammo01a', 'prop_box_ammo02a', 'prop_box_ammo05a', 'prop_box_ammo08a' },
            items = {
                { item = 'ammo-9',       chance = 50, min = 8, max = 20 },
                { item = 'ammo-shotgun', chance = 35, min = 4, max = 10 },
                { item = 'ammo-rifle',   chance = 30, min = 6, max = 15 },
                { item = 'ammo-45',      chance = 25, min = 6, max = 14 },
            },
        },
        military = {  -- High-Tier (Compound / Waffenkisten)
            label = 'Waffenkiste durchsuchen', icon = 'fa-solid fa-gun',
            models = { 'prop_box_guncase_01a', 'prop_box_guncase_02a', 'prop_gun_case_01', 'hei_prop_hei_ammo_pile' },
            items = {
                { item = 'ammo-rifle',          chance = 50, min = 10, max = 30 },
                { item = 'ammo-sniper',         chance = 20, min = 4,  max = 10 },
                { item = 'WEAPON_PISTOL',       chance = 15 },
                { item = 'WEAPON_PUMPSHOTGUN',  chance = 8 },
                { item = 'WEAPON_ASSAULTRIFLE', chance = 5 },
                { item = 'firstaid_kit',        chance = 20 },
                { item = 'antibiotics',         chance = 12 },
                { item = 'blood_bag',           chance = 12 },
                { item = 'suture_kit',          chance = 14 },
                { item = 'painkillers',         chance = 20 },
                { item = 'blueprint_tools',     chance = 8 },
                { item = 'blueprint_metalwork', chance = 8 },
                { item = 'fuel',                chance = 20 },
                { item = 'radio_part',          chance = 15 },
                { item = 'engine_part',         chance = 10 },
                { item = 'geiger_counter',      chance = 12 },
                { item = 'hazmat_suit',         chance = 7  },
            },
        },
        vehicle = {  -- geparkte/verlassene Fahrzeuge durchsuchen (ox_target global)
            label = 'Fahrzeug durchsuchen', icon = 'fa-solid fa-car-burst',
            models = {},  -- leer = global über ox_target:addGlobalVehicle (siehe loot.lua)
            items = {
                { item = 'scrap_metal',  chance = 45, min = 1, max = 3 },
                { item = 'engine_part',  chance = 12 },
                { item = 'empty_bottle', chance = 20 },
                { item = 'canned_food',  chance = 18 },
                { item = 'bandage',      chance = 15 },
                { item = 'ammo-9',       chance = 18, min = 4, max = 10 },
                { item = 'radio_part',   chance = 6  },
                { item = 'fuel',         chance = 30 },
            },
        },
        wreck = {  -- Wrack-Event & Unterwasser-Tauch-Spots (High-Tier maritim)
            label = 'Wrack durchsuchen', icon = 'fa-solid fa-anchor',
            models = {},
            items = {
                { item = 'scrap_metal',         chance = 60, min = 2, max = 5 },
                { item = 'engine_part',         chance = 30, min = 1, max = 2 },
                { item = 'radio_part',          chance = 25 },
                { item = 'ammo-rifle',          chance = 30, min = 8, max = 20 },
                { item = 'firstaid_kit',        chance = 25, min = 1, max = 2 },
                { item = 'antibiotics',         chance = 20 },
                { item = 'blood_bag',           chance = 18 },
                { item = 'suture_kit',          chance = 18 },
                { item = 'canned_food',         chance = 40, min = 1, max = 3 },
                { item = 'WEAPON_PUMPSHOTGUN',  chance = 10 },
                { item = 'blueprint_tools',     chance = 12 },
                { item = 'hazmat_suit',         chance = 10 },
                { item = 'fuel',                chance = 30 },
            },
        },
    },
}

-- ─── Jagd & Phase 3 (Airdrop, Downed) ────────────────────────────────────────
Config.RawMeatSicknessChance = 40   -- % Lebensmittelvergiftung bei rohem Fleisch
Config.BerrySicknessChance   = 10   -- % bei (unreifen) Beeren
Config.SpoiledThreshold      = 15   -- Haltbarkeit (%) ab der ein degrade-Item als "verdorben" gilt → krank

Config.Hunt = {
    cooldownMs = 1500,
    -- Knien & am Körper/Kadaver arbeiten (statt "Ped reparieren") — deutlich realistischer
    anim = { dict = 'amb@medic@standing@tendtodead@base', clip = 'base' },
    animalYields = { { item = 'raw_meat', min = 1, max = 3 }, { item = 'animal_hide', min = 1, max = 2, chance = 70 } },
    npcYields    = { { item = 'scrap_metal', min = 1, max = 2, chance = 60 }, { item = 'ammo-9', min = 3, max = 10, chance = 40 }, { item = 'bandage', chance = 25 } },
}

Config.Airdrop = {
    enabled     = true,
    useKqAirdrop = true,   -- wenn kq_airdrop läuft: dessen Flugzeug/Fallschirm nutzen (sonst eingebauter Fallback)
    intervalMs  = 1800000, -- alle 30 Minuten
    warnSeconds = 30,
    model       = 'prop_box_ammo07a',
    blipTimeMs  = 600000,
    -- Abwurfpunkte (PLATZHALTER — mit /tfpaddspawn echte Cayo-Punkte erfassen)
    points = {
        vec3(4900.0, -5160.0, 30.0),
        vec3(5000.0, -5760.0, 40.0),
        vec3(4540.0, -4500.0, 30.0),
    },
    loot = { -- Top-Tier
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

-- ─── camps/ : NPC-Lager (verwilderte Kartell-Wachen) + Compound als POI ──────
-- ⚠️ center-Koords sind PLATZHALTER — mit /tfpaddspawn auf Cayo erfassen.
Config.Camps = {
    activationDistance = 160.0, -- ab hier werden Wachen + Loot-Kisten gespawnt
    crateModel  = 'prop_box_ammo07a',
    guardModels = { 'g_m_m_armboss_01', 'g_m_y_armgoon_01', 'g_m_m_armlieut_01', 'g_m_y_armgoon_02' },
    list = {
        {
            name = 'Verlassenes Lager (Dschungel)',
            center = vec3(4870.0, -5000.0, 5.0), radius = 35.0,
            guards = 4, weapon = 'WEAPON_MACHETE', accuracy = 20,
            crates = 2, loot = 'camp',
            blip = { sprite = 84, color = 1, label = 'Verwildertes Lager' },
        },
        {
            name = 'El Rubios Compound',
            center = vec3(5000.0, -5760.0, 15.0), radius = 60.0,
            guards = 8, weapon = 'WEAPON_CARBINERIFLE', accuracy = 30,
            crates = 4, loot = 'compound',
            blip = { sprite = 84, color = 1, label = 'Compound (Hochrisiko)' },
        },
        {
            -- Premium Loot-Hotspot (Endgame): schwer bewacht, beste Beute
            name = 'Landebahn-Depot',
            center = vec3(4480.0, -4480.0, 4.0), radius = 55.0,  -- PLATZHALTER (Cayo-Airstrip) — /tfppos
            guards = 7, weapon = 'WEAPON_ASSAULTRIFLE', accuracy = 32,
            crates = 4, loot = 'compound',
            blip = { sprite = 90, color = 1, label = 'Landebahn-Depot (Hochrisiko)' },
        },
    },
    loot = {
        camp = {
            { item = 'scrap_metal',     chance = 60, min = 1, max = 3 },
            { item = 'ammo-9',          chance = 50, min = 5, max = 15 },
            { item = 'canned_food',     chance = 40 },
            { item = 'bandage',         chance = 35 },
            { item = 'WEAPON_PISTOL',   chance = 12 },
            { item = 'blueprint_tools', chance = 6 },
        },
        compound = { -- Top-Tier
            { item = 'ammo-rifle',          chance = 60, min = 15, max = 40 },
            { item = 'ammo-sniper',         chance = 25, min = 5,  max = 12 },
            { item = 'WEAPON_ASSAULTRIFLE', chance = 25 },
            { item = 'WEAPON_PUMPSHOTGUN',  chance = 20 },
            { item = 'WEAPON_SNIPERRIFLE',  chance = 8 },
            { item = 'firstaid_kit',        chance = 40, min = 1, max = 2 },
            { item = 'antibiotics',         chance = 30 },
            { item = 'blueprint_tools',     chance = 20 },
        },
    },
}

-- ─── weather/ : eigenes Wetter- & Zeitsystem (ersetzt clp_weather) ────────────
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

-- ─── radiation/ : verstrahlte Festland-Zone (Phase 5) ────────────────────────
-- ⚠️ zone.center = PLATZHALTER (Festland-Küste) — mit /tfpaddspawn erfassen.
Config.Radiation = {
    enabled       = true,
    zone          = { center = vec3(1090.0, -3000.0, 6.0), radius = 260.0 }, -- LS-Hafen/Festland-Küste
    hotzones      = 3,                     -- Loot-Kisten in der Zone
    crateModel    = 'prop_box_ammo07a',
    damagePerTick = 4,                     -- HP/Sekunde ohne Schutz
    hazmatItem    = 'hazmat_suit',         -- Besitz schützt
    geigerItem    = 'geiger_counter',      -- Besitz warnt in der Nähe
    fx            = 'DrugsMichaelAliensFightIn',
    loot = { -- bestes Loot im Spiel
        { item = 'ammo-rifle',          chance = 60, min = 20, max = 50 },
        { item = 'WEAPON_ASSAULTRIFLE', chance = 35 },
        { item = 'WEAPON_SNIPERRIFLE',  chance = 15 },
        { item = 'firstaid_kit',        chance = 50, min = 1, max = 3 },
        { item = 'antibiotics',         chance = 40, min = 1, max = 2 },
        { item = 'blueprint_tools',     chance = 30 },
        { item = 'engine_part',         chance = 20 },
    },
}

-- ─── escape/ : mehrstufige Festland-Flucht-Quest (Phase 5) ───────────────────
-- ⚠️ coords = PLATZHALTER (Cayo) — mit /tfpaddspawn erfassen.
Config.Escape = {
    enabled    = true,
    blipSprite = 309,
    steps = {
        { id = 1, label = 'Funkturm reparieren', coords = vec3(5189.0, -4924.0, 10.0),
          need = { { item = 'scrap_metal', count = 15 }, { item = 'radio_part', count = 1 } },
          done = 'Funkturm läuft — besorge nun Treibstoff für das Boot.' },
        { id = 2, label = 'Treibstoff bunkern', coords = vec3(4970.0, -5120.0, 2.0),
          need = { { item = 'fuel', count = 4 } },
          done = 'Treibstoff verstaut — jetzt das Boot herrichten.' },
        { id = 3, label = 'Boot vorbereiten', coords = vec3(5050.0, -5150.0, 1.0),
          need = { { item = 'wood', count = 20 }, { item = 'scrap_metal', count = 10 }, { item = 'engine_part', count = 1 } },
          done = 'Das Boot ist startklar — doch das Kartell bewacht den Strand!' },
        { id = 4, label = 'Strandwache durchbrechen & ablegen', coords = vec3(5055.0, -5155.0, 1.0),
          guards = { count = 6, weapon = 'WEAPON_CARBINERIFLE', accuracy = 28, radius = 50.0,
                     models = { 'g_m_y_armgoon_02', 'g_m_m_armboss_01' } },
          need = {}, escape = vec3(1090.0, -3000.0, 6.0) },
    },
}

-- ─── Schwarzmarkt-Händler (Tausch-NPC, kein Geld — reiner Barter) ────────────
-- ⚠️ coords = PLATZHALTER (z. B. nahe der Safezone) — mit /tfppos erfassen.
Config.Trader = {
    enabled = true,
    ped     = 'mp_m_shopkeep_01',
    coords  = vec4(4895.0, -5165.0, 2.0, 200.0),
    blip    = { sprite = 52, color = 2, label = 'Schwarzmarkt' },
    offers = {
        { label = '3 Tierfell → 2 Konserven',        give = { { item = 'animal_hide', count = 3 } },                              get = { item = 'canned_food', count = 2 } },
        { label = '10 Schrott → 24× 9mm',            give = { { item = 'scrap_metal', count = 10 } },                            get = { item = 'ammo-9', count = 24 } },
        { label = '3 gegart. Fleisch → Antibiotika',  give = { { item = 'cooked_meat', count = 3 } },                             get = { item = 'antibiotics', count = 1 } },
        { label = '2 Metallbarren → 1 Treibstoff',    give = { { item = 'metal_ingot', count = 2 } },                             get = { item = 'fuel', count = 1 } },
        { label = '4 Leder → Pistole',               give = { { item = 'leather', count = 4 } },                                 get = { item = 'WEAPON_PISTOL', count = 1 } },
        { label = '15 Schrott + 4 Leder → Schrotflinte', give = { { item = 'scrap_metal', count = 15 }, { item = 'leather', count = 4 } }, get = { item = 'WEAPON_PUMPSHOTGUN', count = 1 } },
        { label = '1 Metallbarren → Verband ×3',      give = { { item = 'metal_ingot', count = 1 } },                             get = { item = 'bandage', count = 3 } },
        { label = '5 Kokosnuss → sauberes Wasser ×3', give = { { item = 'coconut', count = 5 } },                                 get = { item = 'water_clean', count = 3 } },
    },
}

-- ─── Aufgaben / Quests (Hardcore-Survival: immer was zu tun) ─────────────────
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

-- ─── Zusatz-Features: Funk, Fahrzeuge, Companion, Fallen ─────────────────────
Config.Radio = { item = 'radio', minChannel = 1, maxChannel = 99 }

Config.Vehicles = {
    boat = { item = 'boat_kit', model = 'dinghy' }, -- wird am/über Wasser gespawnt
}

Config.Companion = {
    item = 'dog_whistle', model = 'a_c_shepherd',
}

Config.Trap = {
    radius = 2.2, damage = 25, intervalMs = 1500, -- schädigt Feinde/Spieler im Umkreis
}

-- ─── Realismus-Ausbau (A Verletzungen · B Sinne · C Hardcore · D Welt) ───────
Config.Hardcore = {
    noPassiveRegen = true,   -- KEINE passive HP-Regeneration (nur Medizin/Essen)
}

-- ─── Müdigkeit / Schlaf ──────────────────────────────────────────────────────
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

-- ─── Partikel-FX & Sound (SOTF-Juice) ────────────────────────────────────────
Config.FX = {
    enabled        = true,
    gather         = true,   -- Holzspäne/Steinstaub beim Sammeln
    campfireLight  = true,   -- warmes Licht + Glut am Lagerfeuer
    campfireRange  = 14.0,   -- ab welcher Distanz Feuer-FX gerendert werden
    waterSplash    = true,   -- Spritzer beim Eintauchen
    bloodDrips     = true,   -- Bluttropfen am Boden bei starker Blutung
    footDust       = true,   -- Staub beim Sprinten an Land
}

-- Sounds über xsound (installiert). URLs/lokale Dateien eintragen → sofort aktiv.
-- Leer = stumm (kein Fehler). Beispiel lokal: 'https://.../chop.ogg' oder 'nui://...'.
Config.Sounds = {
    chop   = '',   -- Axt am Baum
    mine   = '',   -- Stein/Schrott
    gather = '',   -- Pflanzen/Beeren
    fire   = '',   -- Lagerfeuer-Knistern (Loop, am Feuer)
    splash = '',   -- Wasser-Eintauchen
    craft  = '',   -- Handwerk fertig
    fireVolume = 0.35,
}

Config.Injury = {
    bleedHpPerTick   = 2,        -- HP/Sek pro 25 Blutungs-Punkte
    bleedClotPerTick = 0.4,      -- minimale Eigen-Gerinnung/Sek (kleine Wunden)
    bleedFromHit     = 16,       -- Blutung pro Treffer (× Schadensfaktor)
    fallFractureMin  = 7.5,      -- ab dieser Sturzhöhe (m) droht ein Bruch
    fractureChance   = 70,       -- % Bruch-Chance bei hartem Sturz
    fractureClipset  = 'move_m@injured',
    bandageItem      = 'bandage',
    splintItem       = 'splint',
    infectBleedMin   = 35,       -- ab diesem Blutungs-Wert kann sich die Wunde infizieren
    infectChance     = 5,        -- %/Sek Chance auf Wundinfektion bei starker Blutung
    armFractureChance = 22,      -- % dass ein Nahkampf-/Schlag-Treffer einen ARM-Bruch verursacht
}

-- ─── Blut-System (Verlust senkt Max-HP, Transfusion heilt) ───────────────────
Config.Blood = {
    enabled       = true,
    default       = 100,
    lossPerTick   = 1.2,    -- Blutverlust/Tick je 25 Blutungs-Punkte
    regenPerTick  = 0.15,   -- langsame natürliche Erholung (satt & nicht blutend)
    regenNeedPct  = 40,     -- nur wenn Hunger & Durst über diesem Wert
    criticalLow   = 18,     -- ab hier: Schock (HP-Verlust) + Schwäche + woozy Sicht
    shockHpLoss   = 2,      -- HP/Tick bei kritischem Blutverlust
    minMaxHp      = 100,    -- Max-HP bei Blut 0
    maxMaxHp      = 200,    -- Max-HP bei Blut 100
}

-- ─── Medizin-Tiefe: Verband/Nähset/Schmerzmittel/Desinfektion/Symptome ───────
Config.Medical = {
    bandageReduce  = 55,     -- Verband senkt Blutung um X (leichte Wunden)
    sutureHealHp   = 12,     -- Nähset: stoppt Blutung KOMPLETT + kleine Heilung
    bloodBagRestore = 45,    -- Blutbeutel-Transfusion
    transfuseTime  = 8000,
    painkillerMs   = 90000,  -- Schmerzmittel-Wirkdauer (unterdrückt Schmerz-FX, lindert Humpeln)
    disinfectMs    = 150000, -- Desinfektion: in diesem Fenster KEIN Infektionsrisiko
    items = { bloodBag = 'blood_bag', painkillers = 'painkillers', suture = 'suture_kit', disinfectant = 'disinfectant' },
    symptomMinSeverity = 35, -- ab dieser Krankheits-Schwere werden Symptome sichtbar
    -- Symptome je Krankheit: tcMod = Sicht-Timecycle, thirstDrain = extra Durst/Tick, painFlash = roter Flash
    symptoms = {
        cold      = { tcMod = nil,           thirstDrain = 0, msg = 'Du hustest und zitterst…' },
        food      = { tcMod = 'drug_wobbly', thirstDrain = 0, msg = 'Dir ist übel…' },
        infection = { tcMod = nil,           thirstDrain = 0, painFlash = true, msg = 'Die Wunde pocht heiß…' },
        cholera   = { tcMod = 'drug_wobbly', thirstDrain = 2, msg = 'Krämpfe und Schwindel…' },
    },
}

Config.Senses = {
    coldBreath     = true,       -- sichtbarer Atem bei Kälte
    coldBreathTemp = 35,         -- ab Wärme < diesem Wert
    painFlash      = true,       -- kurzer roter Flash bei Treffer
}

-- HUD nur bei Bedarf (D): Kern-Stats erst ab diesem Wert sichtbar (sonst aus)
Config.HudShowBelow = 65

-- ─── Survival-Stats (alle Werte in PROZENT 0..100) ───────────────────────────
-- "Fordernd"-Tuning: Vernachlässigung wird über die Verkettung in Minuten spürbar,
-- Tod kommt durch Verkettung (kalt+nass -> krank -> schwach), nicht durch einen Balken.
Config.Stats = {
    -- Eigen-Zehrung von Hunger/Durst pro Sekunde (in %), da esx_status-Tick auf manchen Builds tot ist
    hungerDrain = 0.042,     -- ~40 Min bis leer (Rust/Forest-Pace, nicht Dauerstrafe)
    thirstDrain = 0.066,     -- ~25 Min bis leer
    starveHpLoss = 1,        -- HP/Sek wenn Hunger ODER Durst auf 0 (echte Konsequenz)
    temperature = {
        default      = 78,
        baseTarget   = 78,      -- tropische Grundwärme (Tag, trocken, an Land)
        nightDrop    = 34,      -- nachts kälter (trockene Nacht knapp über „kalt", nass = gefährlich)
        rainDrop     = 48,      -- * Regenstärke (0..1), nur wenn ungeschützt
        waterDrop    = 55,      -- im Wasser
        wetFactor    = 0.45,    -- je % Nässe -> Wärme runter
        fireBoost    = 70,      -- Nähe zu Feuer
        clothingBoost = 8,      -- Grund-Isolierung (leichte Kleidung)
        clothingBoostWarm = 34, -- Isolierung MIT Fellkleidung (warm_clothing) im Inventar
        warmItem      = 'warm_clothing',
        approachRate = 0.08,    -- wie schnell sich Temp dem Ziel nähert (pro Tick)
        warn         = 40,      -- "dir wird kalt"
        slow         = 30,      -- Bewegung verlangsamt + Krankheits-Risiko-Schwelle
        critical     = 14,      -- HP-Verlust (Erfrieren)
        slowMoveRate = 0.80,    -- Bewegungstempo bei Kälte
        criticalHpLoss = 3,     -- HP/Tick bei extremer Kälte
    },
    wetness = {
        default     = 0,
        swimGain    = 25,       -- /Tick im Wasser
        rainGain    = 9,        -- /Tick * Regenstärke (ungeschützt)
        dryBase     = 4,        -- /Tick trocknen
        dryFireBonus = 12,      -- zusätzlich am Feuer
        drySunBonus = 3,        -- zusätzlich in Mittagshitze
        warn        = 60,
    },
    stamina = {
        default     = 100,
        sprintDrain = 3,        -- /Tick beim Sprinten (~33 s Sprint statt 14 s)
        swimDrain   = 3,        -- /Tick beim Schwimmen
        regen       = 6,        -- /Tick Erholung
        lowRegen    = 2,        -- Erholung bei Hunger/Durst < lowNeedPct
        lowNeedPct  = 25,
    },
    sickness = {
        default     = 0,
        coldWetRisk = 4,        -- Risiko/Tick bei kalt (<temp.slow) UND nass (>=50) — ~25 s bis krank
        riskThreshold = 100,    -- ab hier wird man krank
        riseCold    = 0.9,      -- Schwere steigt, wenn krank & weiterhin kalt
        fallWarm    = 0.7,      -- Schwere fällt, wenn krank & warm (langsamer)
        warmTemp    = 55,       -- ab dieser Wärme heilt es langsam
        hpThreshold = 60,       -- ab dieser Schwere: HP-Verlust + halbe Stamina-Regen
        hpLoss      = 2,
    },
}

-- Krankheitstypen (vielfältig). Slice 1 erreicht 'cold' über die Umwelt;
-- 'food'/'infection'/'cholera' werden in Slice 2/3 über Items/Wunden ausgelöst.
Config.Diseases = {
    cold      = { label = 'Erkältung/Fieber',          cure = 'medkit' },
    food      = { label = 'Lebensmittelvergiftung',    cure = 'medkit' },
    infection = { label = 'Wundinfektion',             cure = 'antibiotics' },
    cholera   = { label = 'Magen-Darm (Cholera)',      cure = 'antibiotics' },
}

-- ════════════════════════════════════════════════════════════════════════════
-- NAHRUNG-LOOP: Kochen am Feuer · Fischen
-- ════════════════════════════════════════════════════════════════════════════
Config.Cooking = {
    time = 5000,
    anim = { dict = 'amb@world_human_cook@male@base', clip = 'base' },
    -- rohes Item -> gegartes Item (am Lagerfeuer/Kamin)
    recipes = {
        raw_meat = 'cooked_meat',
        raw_fish = 'cooked_fish',
    },
}

Config.Fishing = {
    rodItem = 'fishing_rod',
    time    = 9000,
    anim    = { dict = 'amb@world_human_stand_fishing@idle_a', clip = 'idle_c' },
    -- braucht Wasser in der Nähe; server-autoritativer Ertrag
    yields = {
        { item = 'raw_fish',    min = 1, max = 2, chance = 70 },
        { item = 'raw_fish',    min = 1, max = 1, chance = 25 }, -- zweiter Wurf-Bonus
        { item = 'plant_fiber', min = 1, max = 1, chance = 15 }, -- Seetang/Treibgut
        { item = 'scrap_metal', min = 1, max = 1, chance = 8  }, -- alter Müll
    },
}

-- ════════════════════════════════════════════════════════════════════════════
-- GEGNER & TIERE: Hai (Wasser) · Raubtier (Land) · Kannibalen (Nacht)
-- (client-lokal wie ai/, populationsgedeckelt)
-- ════════════════════════════════════════════════════════════════════════════
Config.Predators = {
    relationshipGroup = 'TFP_PRED',
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
        chance   = 12,            -- % pro Check, nur in Gefahrenzonen (Config.AI.zones)
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
        nightFrom = 20, nightTo = 6,  -- Stunden (nachts aggressiv — Forest-Style)
        noiseThreshold = 60,      -- ab diesem Lärm (Schüsse/Sprinten) kommen sie AUCH tagsüber
        spawnMin  = 45.0, spawnMax = 95.0,
        accuracy  = 22,
        harvest   = 'npc',        -- ausschlachtbar wie NPC
    },
}

-- ════════════════════════════════════════════════════════════════════════════
-- LOOT & WELT-EVENTS: dynamisches Wrack · Tauch-Spots · Fahrzeuge
-- ════════════════════════════════════════════════════════════════════════════
Config.WreckEvent = {
    enabled     = true,
    firstDelayMs = 120000,  -- erstes Wrack schon ~2 Min nach Start (Testbarkeit)
    intervalMs  = 1200000,  -- danach alle 20 Min
    despawnMs   = 900000,   -- 15 Min sichtbar
    blipSprite = 455, blipColor = 5,
    -- PLATZHALTER-Koords (mit /tfpaddspawn echte Cayo-Punkte erfassen)
    points = {
        { coords = vec3(4960.0, -5360.0, 2.0), prop = 'prop_wreck_truck_01' },
        { coords = vec3(4640.0, -4620.0, 3.0), prop = 'prop_wreck_van' },
        { coords = vec3(5180.0, -5020.0, 2.0), prop = 'prop_byard_wreck01' },
    },
    crateProp = 'prop_box_ammo07a',
    loot = 'wreck',  -- nutzt Config.Loot.tables.wreck (first come, einmalig)
}

Config.Wrecks = {
    enabled = true,
    -- statische Unterwasser-Tauch-Spots: tauche hin & durchsuche die Kiste
    -- PLATZHALTER-Koords (echte Cayo-Riff/Wrack-Punkte mit Editor setzen)
    spots = {
        vec3(5300.0, -5500.0, -18.0),
        vec3(4500.0, -5700.0, -22.0),
        vec3(5600.0, -5100.0, -15.0),
    },
    crateProp = 'prop_box_ammo04a',
    reLootCooldownMs = 900000,  -- 15 Min bis derselbe Spot wieder was gibt
    loot = 'wreck',
}

-- ════════════════════════════════════════════════════════════════════════════
-- ATMOSPHÄRE: Lore-Notizen, Aufwärm-Emote, Herzschlag, (optional) xsound-Ambient
-- ════════════════════════════════════════════════════════════════════════════
Config.Atmosphere = {
    warmEmote      = 'crossarms',  -- rpemotes: am Feuer aufwärmen
    heartbeatHpPct = 25,           -- ab dieser HP% pulsiert der Bildschirm (Herzschlag)
    noteProp       = 'prop_cs_documents_01',  -- sichtbarer Papier-Prop an Notiz-Fundorten

    -- Optionaler Hintergrund-Sound über xsound (AUS by default — URL/Datei nötig).
    -- enabled=true + url='https://.../jungle.mp3' setzen, um Insel-Ambiente zu hören.
    ambient = { enabled = false, url = '', volume = 0.25 },

    -- Lore-Fundstücke: anvisieren & lesen. ⚠️ Koords PLATZHALTER (mit Editor/Best-Guess setzen).
    notes = {
        { coords = vec3(4905.0, -5158.0, 2.1), title = 'Verwittertes Tagebuch — Tag 3',
          text = 'Das Boot ist fort. Funk tot. Ich habe Rauch im Inneren der Insel gesehen — aber kein Mensch winkt dort.\n\nIch bleibe am Strand. Wer das findet: bleib ebenfalls. Geh nicht ins Dickicht.' },
        { coords = vec3(4760.0, -5085.0, 6.0), title = 'Zerfetzte Seite',
          text = 'Sie kommen nur nachts aus den Lagern. Tagsüber sind es nur die Tiere und das Kartell.\n\nMach KEIN Feuer im Dunkeln, wenn du sie nicht anlocken willst. Wärme oder Leben — manchmal beides nicht.' },
        { coords = vec3(5180.0, -4930.0, 9.0), title = 'Notiz am Funkturm',
          text = 'Der Turm lässt sich reparieren — Schrott und ein Funk-Bauteil. Dann ein Boot, Motorteil, ablegen.\n\nDoch das Festland ist verseucht. Ohne Schutzanzug verbrennst du von innen. Erst rüsten, dann fliehen.' },
        { coords = vec3(4980.0, -5360.0, 2.0), title = 'Letzter Eintrag',
          text = 'Wenn du das liest, war ich nicht schnell genug. Vertrau niemandem, der dir nachts „Hilfe" zuruft.\n\nDie Insel will, dass du bleibst. Geh trotzdem.' },
    },
}
