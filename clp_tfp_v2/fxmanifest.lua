fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'clp_tfp'
author 'CLP'
description 'TFP — Hardcore Insel-Survival auf Cayo Perico (Neuaufbau v2)'
version '2.0.0'

-- ════════════════════════════════════════════════════════════════════════════
--  Neuaufbau nach REBUILD_PROMPT.md (liegt in ../clp_tfp/REBUILD_PROMPT.md).
--  Skript-Listen wachsen pro Build-Phase. Aktuell: PHASE 1 — Fundament.
-- ════════════════════════════════════════════════════════════════════════════

shared_scripts {
    '@ox_lib/init.lua',
    'branding.lua',
    'config.lua',
}

client_scripts {
    'client/hud.lua',
    'client/main.lua',
    'client/world.lua',
    'client/spawn.lua',
    'client/consume.lua',
    'client/gathering.lua',
    'client/crafting.lua',
    'client/realism.lua',
    'client/wounds.lua',
    'client/threat.lua',
    'client/tribe.lua',
    'client/building.lua',
    'client/loot.lua',
    'client/ai.lua',
    'client/camps.lua',
    'client/radiation.lua',
    'client/predators.lua',
    'client/clothing.lua',
    'client/hardcore.lua',
    'client/quests.lua',
    'client/weather.lua',
    'client/fishing.lua',
    'client/airdrop.lua',
    'client/vehicles.lua',
    'client/radio.lua',
    'client/companion.lua',
    'client/fx.lua',
    'client/atmosphere.lua',
    'client/escape.lua',
    'client/events.lua',
    'client/worldevents.lua',
    'client/survivors.lua',
    'client/trader.lua',
    'client/menu.lua',
    'client/admin.lua',
    'client/editor.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/spawn.lua',
    'server/consume.lua',
    'server/gathering.lua',
    'server/crafting.lua',
    'server/threat.lua',
    'server/tribe.lua',
    'server/building.lua',
    'server/loot.lua',
    'server/camps.lua',
    'server/radiation.lua',
    'server/clothing.lua',
    'server/quests.lua',
    'server/weather.lua',
    'server/fishing.lua',
    'server/airdrop.lua',
    'server/lore.lua',
    'server/escape.lua',
    'server/events.lua',
    'server/worldevents.lua',
    'server/survivors.lua',
    'server/trader.lua',
    'server/admin.lua',
    'server/editor.lua',
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'es_extended',
    'esx_status',
    'esx_basicneeds',
    'ox_lib',
    'ox_target',
    'ox_inventory',
}
