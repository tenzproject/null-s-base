fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

ui_page 'web/dist/index.html'

dependency 'null-core'

files {
    'web/dist/index.html',
    'web/dist/**/**',
    'web/dist/assets/**',
    'web/dist/assets/*.css',
    'web/dist/assets/*.js',
    'web/dist/assets/*.ttf',
    'web/dist/assets/*.woff',
    'web/dist/assets/*.woff2',
} 

client_scripts {
    '@null-core/init/shared/configs_loader.lua',
    'lua/client.lua'
}

server_scripts {
    '@null-core/init/shared/configs_loader.lua',
    'lua/server.lua',
}

shared_scripts {
    '@ox_lib/init.lua'
}
