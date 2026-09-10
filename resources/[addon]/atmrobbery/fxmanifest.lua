fx_version 'cerulean'
game "gta5"
lua54 'yes'

dependency 'null-core'

shared_scripts {
    "shared/*.lua"
}

client_scripts {
    '@null-core/init/shared/configs_loader.lua',
    '@ox_lib/init.lua',

    "client/mhacking.lua",
    "client/sequentialhack.lua",
    "client/main.lua",
}

server_scripts {
    '@null-core/init/shared/configs_loader.lua',
    "server/*.lua"
}

ui_page 'html/hack.html'
files {
    'html/phone.png',
    'html/snd/beep.ogg',
    'html/snd/correct.ogg',
    'html/snd/fail.ogg', 
    'html/snd/start.ogg',
    'html/snd/finish.ogg',
    'html/snd/wrong.ogg',
    'html/hack.html'
}

dependencies {
	'ox_lib'
}
