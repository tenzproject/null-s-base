fx_version 'bodacious'
game 'gta5'
lua54 'yes'

name 'null-ui'
description ''
author 'Null'

version "4.0.14"

ui_page {"web/index.html"}

files {
    "web/**",

    -- "_ignore/hologram/ui/**/*.*",
    -- "_ignore/hologram/ui/*.*",
}

dependency "null-core"

client_scripts {
    '@null-core/init/shared/configs_loader.lua',
    'client.lua',
    'creator.lua',
    'animations-bridge.lua',
    "notif.lua",
    "inventory/client.lua",
    "boutique/client/client.lua",

    -- '_ignore/hologram/config.lua',
    -- '_ignore/hologram/core/HologramCore.lua',
    -- '_ignore/hologram/modules/Interaction3D.lua',
    -- '_ignore/hologram/init.lua',
    -- '_ignore/hologram/debug.lua',
    -- '_ignore/hologram/client.js',
    'devpanel_client.lua',
}
 
server_scripts {
    "@null-deps/modules/oxmysql/lib/MySQL.lua",
    '@null-core/init/shared/configs_loader.lua',
    "server.lua",
    "main.js",
    "inventory/server.lua",
    "boutique/server/*.lua",
    "devpanel_server.lua",
}

escrow_ignore {
    "boutique/server/MySQL.lua",
    "server.lua",
    "inventory/server.lua",
    "boutique/server/*.lua",
}

luraph_ignore {
    "boutique/server/MySQL.lua",
    'client.lua',
    'creator.lua',
    "animations-bridge.lua",
    "notif.lua",
    "inventory/client.lua",
    "boutique/client/client.lua",
}

dependency '/assetpacks'
