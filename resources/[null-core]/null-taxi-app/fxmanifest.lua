fx_version "cerulean"
game "gta5"

title       "Null Taxi - lb-phone app"
description "App pour appeler un taxi : liste les chauffeurs en service et envoie une demande aux taxis."
author      "Null"
version     "1.0.0"

client_scripts {
    "@null-core/init/shared/configs_loader.lua",
    "client.lua",
}

file "ui/**/*"
ui_page "ui/index.html"

dependencies {
    "null-core",
    "lb-phone",
}
