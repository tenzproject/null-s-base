fx_version "cerulean"
game "gta5"

title       "Null Immo - lb-phone app"
description "App immobilière publique : visualise les biens en vente et en location de l'agence."
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
