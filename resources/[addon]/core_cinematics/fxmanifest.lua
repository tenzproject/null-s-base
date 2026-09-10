fx_version 'cerulean'
game 'gta5'

description 'Core Cinematics - In-Game Cinematic Editor'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/c8recinematics.png',
    'html/script.js',
    'html/textdui/text.html',
    'locales/*.json',
}

client_scripts {
    'config.lua',
    'client/modules/text_placement.lua',
    'client/modules/drift_smoke.lua',
    'client/main.lua',
}

server_scripts {
    'config.lua',
    'server/main.lua',
}

