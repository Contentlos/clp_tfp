fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'clp_tfp'
author 'CLP'
description 'TFP — Hardcore Insel-Survival auf Cayo Perico (Phase 1: survival/)'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'branding.lua',
    'config.lua',
}

client_scripts {
    'client/hud.lua',
    'client/main.lua',
    'client/consume.lua',
    'client/spawn.lua',
    'client/world.lua',
    'client/gathering.lua',
    'client/crafting.lua',
    'client/building.lua',
    'client/tribe.lua',
    'client/threat.lua',
    'client/ai.lua',
    'client/loot.lua',
    'client/airdrop.lua',
    'client/camps.lua',
    'client/weather.lua',
    'client/admin.lua',
    'client/radiation.lua',
    'client/escape.lua',
    'client/radio.lua',
    'client/vehicles.lua',
    'client/companion.lua',
    'client/editor.lua',
    'client/realism.lua',
    'client/menu.lua',
    'client/fishing.lua',
    'client/predators.lua',
    'client/events.lua',
    'client/atmosphere.lua',
    'client/trader.lua',
    'client/quests.lua',
    'client/hardcore.lua',
    'client/fx.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/tribe.lua',
    'server/spawn.lua',
    'server/gathering.lua',
    'server/crafting.lua',
    'server/building.lua',
    'server/threat.lua',
    'server/loot.lua',
    'server/airdrop.lua',
    'server/camps.lua',
    'server/weather.lua',
    'server/admin.lua',
    'server/radiation.lua',
    'server/escape.lua',
    'server/editor.lua',
    'server/fishing.lua',
    'server/events.lua',
    'server/trader.lua',
    'server/quests.lua',
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
