-- ============================================================================
-- null-deps
-- Bundle unique des dépendances runtime de la base Null V4.
-- Contient : cron, sessionmanager, spawnmanager, PolyZone, httpmanager,
--           pma-voice, xsound, screenshot-basic, ox_lib, oxmysql.
-- webpack/yarn : satisfaits via provides{} (screenshot-basic pré-buildé).
-- ============================================================================

fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'
use_experimental_fxv2_oal 'yes'
node_version '22'

name        'null-deps'
author      'Null'
version "4.0.3"
description 'Null Core dependencies bundle (single-script).'

-- Démarrer cette ressource AVANT null-core.
-- null-core dépend directement de null-deps.

-- ox_lib + oxmysql nécessitent un FX server build récent.
dependencies {
    '/server:12913',
    '/onesync',
}

-- ============================================================================
-- EXPORTS — déclaration explicite pour compat Luraph / lookup rapide
-- ============================================================================
exports {
    -- PolyZone
    'TriggerZoneEvent',

    -- httpmanager
    'createHttpHandler',
    'getUrl',

    -- spawnmanager
    'isFirstSpawn',
    'switchFinished',

    -- pma-voice (client)
    'setVolume',
    'setRadioVolume',
    'getRadioVolume',
    'setCallVolume',
    'getCallVolume',
    'toggleMute',
    'toggleMutePlayer',
    'setVoiceProperty',
    'SetMumbleProperty',
    'SetTokoProperty',
    'setOverrideCoords',
    'setRadioChannel',
    'SetRadioChannel',
    'removePlayerFromRadio',
    'addPlayerToRadio',
    'setCallChannel',
    'SetCallChannel',
    'addPlayerToCall',
    'removePlayerFromCall',

    -- xsound (play)
    'PlayUrl',
    'PlayUrlPos',
    'TextToSpeech',
    'TextToSpeechPos',

    -- xsound (manipulation)
    'Position',
    'Distance',
    'Destroy',
    'Pause',
    'Resume',
    'setTimeStamp',
    'destroyOnFinish',
    'setVolumeMax',
    'setSoundLoop',
    'repeatSound',
    'setSoundDynamic',
    'setSoundURL',

    -- xsound (info)
    'getLink',
    'getPosition',
    'isLooped',
    'getInfo',
    'soundExists',
    'isPlaying',
    'isPaused',
    'getDistance',
    'getVolume',
    'isDynamic',
    'getTimeStamp',
    'getMaxDuration',
    'isPlayerInStreamerMode',
    'getAllAudioInfo',
    'isPlayerCloseToAnySound',

    -- xsound (effects)
    'fadeIn',
    'fadeOut',

    -- xsound (events)
    'onPlayStart',
    'onPlayEnd',
    'onLoading',
    'onPlayPause',
    'onPlayResume',

    -- screenshot-basic
    'requestScreenshot',
    'requestScreenshotUpload',

    -- ox_lib auto-exporte ses lib.* via le __newindex de resource/init.lua,
    -- pas besoin de les lister un par un ici.
    'hasLoaded',
    'cache',
    'notify',
}

server_exports {
    -- pma-voice (server)
    'updateRoutingBucket',
    'getPlayersInRadioChannel',
    'GetPlayersInRadioChannel',
    'setPlayerRadio',
    'setPlayerCall',

    -- screenshot-basic (server)
    'requestClientScreenshot',
}

-- Permet aux ressources tierces de continuer à déclarer leurs dépendances
-- par leur ancien nom (dependency 'pma-voice', etc.).
provides {
    'cron',
    'sessionmanager',
    'spawnmanager',
    'PolyZone',
    'httpmanager',
    'pma-voice',
    'xsound',
    'screenshot-basic',
    'webpack',
    'yarn',
    'ox_lib',
    'oxmysql',
    -- alias historiques de pma-voice
    'mumble-voip',
    'tokovoip',
    'toko-voip',
    'tokovoip_script',
    -- alias historiques d'oxmysql
    'mysql-async',
    'ghmattimysql',
}

-- ============================================================================
-- SHARED
-- ox_lib resource/init.lua DOIT être chargé en premier — définit `lib` et `cache`.
-- ============================================================================
shared_script 'modules/ox_lib/resource/init.lua'

shared_scripts {
    'modules/ox_lib/resource/**/shared.lua',
    'modules/pma-voice/shared.lua',
}

-- ============================================================================
-- SERVER
-- ============================================================================
server_scripts {
    -- ox_lib server (callback en premier car d'autres dépendent)
    'modules/ox_lib/imports/callback/server.lua',
    'modules/ox_lib/resource/**/server.lua',
    'modules/ox_lib/resource/**/server/*.lua',

    -- oxmysql server (Node bundle)
    'modules/oxmysql/dist/build.js',

    -- httpmanager (libs avant handler)
    'modules/httpmanager/url.lua',
    'modules/httpmanager/mime.lua',
    'modules/httpmanager/base64.lua',
    'modules/httpmanager/hash.lua',
    'modules/httpmanager/realms.lua',
    'modules/httpmanager/httphandler.lua',
    'modules/httpmanager/main.lua',

    -- cron
    'modules/cron/server/main.lua',

    -- sessionmanager (active EnableEnhancedHostSupport)
    'modules/sessionmanager/server/host_lock.lua',

    -- PolyZone creation server (config avant creation)
    'modules/polyzone/creation/server/config.lua',
    'modules/polyzone/creation/server/creation.lua',
    'modules/polyzone/server.lua',

    -- pma-voice (server.lua expose la state, modules ensuite)
    'modules/pma-voice/server/server.lua',
    'modules/pma-voice/server/module/radio.lua',
    'modules/pma-voice/server/module/phone.lua',

    -- xsound (config avant exports/emulator)
    'modules/xsound/config.lua',
    'modules/xsound/server/exports/play.lua',
    'modules/xsound/server/exports/manipulation.lua',
    'modules/xsound/server/emulator/interact_sound/server.lua',

    -- screenshot-basic (pré-buildé, JS direct)
    'modules/screenshot-basic/server.js',
}

-- ============================================================================
-- CLIENT
-- ============================================================================
client_scripts {
    -- ox_lib client
    'modules/ox_lib/resource/**/client.lua',
    'modules/ox_lib/resource/**/client/*.lua',

    -- oxmysql UI bridge
    'modules/oxmysql/ui.lua',

    -- PolyZone (client.lua expose les bases, puis les Zone helpers)
    'modules/polyzone/client.lua',
    'modules/polyzone/BoxZone.lua',
    'modules/polyzone/EntityZone.lua',
    'modules/polyzone/CircleZone.lua',
    'modules/polyzone/ComboZone.lua',
    'modules/polyzone/creation/client/utils.lua',
    'modules/polyzone/creation/client/PolyZone.lua',
    'modules/polyzone/creation/client/BoxZone.lua',
    'modules/polyzone/creation/client/CircleZone.lua',
    'modules/polyzone/creation/client/creation.lua',
    'modules/polyzone/creation/client/commands.lua',

    -- sessionmanager (registre les NetEvents callbacks)
    'modules/sessionmanager/client/empty.lua',

    -- spawnmanager (registre spawnmanager:spawnPlayer)
    'modules/spawnmanager/client/main.lua',

    -- pma-voice (main.lua expose la state, modules ensuite)
    'modules/pma-voice/client/main.lua',
    'modules/pma-voice/client/module/radio.lua',
    'modules/pma-voice/client/module/phone.lua',

    -- xsound (config avant tout, puis main, events, exports, effects, emulator)
    'modules/xsound/config.lua',
    'modules/xsound/client/main.lua',
    'modules/xsound/client/events.lua',
    'modules/xsound/client/commands.lua',
    'modules/xsound/client/exports/info.lua',
    'modules/xsound/client/exports/play.lua',
    'modules/xsound/client/exports/manipulation.lua',
    'modules/xsound/client/exports/events.lua',
    'modules/xsound/client/effects/main.lua',
    'modules/xsound/client/emulator/interact_sound/client.lua',

    -- screenshot-basic (pré-buildé, JS direct)
    'modules/screenshot-basic/client.js',
}

-- ============================================================================
-- NUI
-- Router multiplexeur : forward SendNUIMessage vers 5 iframes
-- (voice, audio, screenshot, oxmysql, oxlib).
-- ============================================================================
ui_page 'ui/index.html'

files {
    'ui/index.html',

    -- ox_lib (consumed via @null-deps/modules/ox_lib/init.lua)
    'modules/ox_lib/init.lua',
    'modules/ox_lib/imports/**/client.lua',
    'modules/ox_lib/imports/**/shared.lua',

    -- ox_lib UI (React, paths relatifs, GetParentResourceName dynamique)
    'modules/ox_lib/web/build/index.html',
    'modules/ox_lib/web/build/**/*',
    'modules/ox_lib/locales/*.json',
    'locales/*.json',

    -- oxmysql (consumed via @null-deps/modules/oxmysql/lib/MySQL.lua)
    'modules/oxmysql/lib/MySQL.lua',

    -- oxmysql UI debug
    'ui/oxmysql/index.html',
    'ui/oxmysql/vite.svg',
    'ui/oxmysql/assets/**/*',

    -- pma-voice UI (Vue.js compilé, inchangé)
    'ui/pma-voice/index.html',
    'ui/pma-voice/css/app.css',
    'ui/pma-voice/js/app.js',
    'ui/pma-voice/js/chunk-vendors.js',
    'ui/pma-voice/mic_click_on.ogg',
    'ui/pma-voice/mic_click_off.ogg',

    -- xsound UI (URLs $.post réécrites vers /null-deps/)
    'ui/xsound/index.html',
    'ui/xsound/scripts/config.js',
    'ui/xsound/scripts/functions.js',
    'ui/xsound/scripts/SoundPlayer.js',
    'ui/xsound/scripts/listener.js',

    -- screenshot-basic UI (URLs dynamiques via GetCurrentResourceName, inchangé)
    'ui/screenshot-basic/index.html',
}

-- ============================================================================
-- Convars oxmysql (alias des convars originaux conservés pour rétro-compat)
-- ============================================================================
convar_category 'OxMySQL' {
    'Configuration',
    {
        { 'Connection string', 'mysql_connection_string', 'CV_STRING', 'mysql://user:password@localhost/database' },
        { 'Debug', 'mysql_debug', 'CV_BOOL', 'false' }
    }
}

-- ============================================================================
-- PROTECTION
-- Dépendances publiques : aucun chiffrement (ni FXAP ni Luraph).
-- Tout est listé dans les deux ignore pour rester en clair.
-- ============================================================================
escrow_ignore {
    'modules/**',
    'ui/**',
    'locales/**',
}

luraph_ignore {
    'modules/**',
    'ui/**',
    'locales/**',
}
