fx_version "cerulean"
game "gta5"

title "LB Phone - App Template"
description "A template for creating apps for the LB Phone."
author "Breze & Loaf"

client_scripts {
    "@null-core/init/shared/configs_loader.lua",
    "client.lua",
    "devpanel_client.lua"
}
server_scripts {
    "@null-core/init/shared/configs_loader.lua",
    "server.lua",
    "devpanel_server.lua"
}

file "ui/**/*"

ui_page "ui/index.html"

shared_script "shared.lua"

dependency "null-core"
