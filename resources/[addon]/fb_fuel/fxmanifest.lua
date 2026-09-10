fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Leo'
name 'Fuel System style FB'
version '1.0'

dependency 'null-core'

client_scripts {
    '@null-core/init/shared/configs_loader.lua',
	'config.lua',
	'functions/functions_client.lua',
	'functions/dui.lua',
	'source/fuel_client.lua'
}

server_scripts { 
    '@null-core/init/shared/configs_loader.lua',
	'config.lua',
	'source/fuel_server.lua'
}


exports {
	'GetFuel', 
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/script.js',
    'ui/styles.css'
}
