fx_version 'cerulean'
game 'gta5'

name 'null-cache'
author 'Null'
version '2.0.0'
description 'Image cache, screenshot capture & processing'

dependency "null-core"

dependencies {
    'screenshot-basic',
    'yarn'
}

files {
    'images/**/*.webp',
    'images/**/*.png',
    'images/**/*.jpg',
}

server_scripts {
    '@null-core/init/shared/configs_loader.lua',
    'server.lua',
    'server.js'
}
