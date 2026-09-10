fx_version 'cerulean'
game 'gta5'

name 'null-crimenet'
description 'CrimeNet - lb-phone app for illegal network, contacts, messaging & missions'
author 'Null'
version '2.0.0'

dependencies {
    'lb-phone',
    'null-core',
}

shared_scripts {
    'shared.lua',
    'config.lua',
}

client_scripts {
    "@null-core/init/shared/configs_loader.lua",
    'client.lua',
}

server_scripts {
    "@null-core/init/shared/configs_loader.lua",
    "@mysql-async/lib/MySQL.lua",
    'server/main.lua',
    'server/network.lua',
    'server/commands.lua',
}

ui_page 'ui/index.html'

files {
    'ui/**/*',
}

lua54 'yes'
