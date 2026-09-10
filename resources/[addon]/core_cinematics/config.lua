Config = {
    AcePerm = 'core_cinematics.use',

    Locale = 'en',

    DefaultFPS   = 30,   
    MaxDuration  = 600,  

    MoveSpeed       = 12.0,  
    MoveSpeedFast   = 60.0,  
    RotateSpeed     = 3.0,   
    RotateSpeedFast = 8.0,   
    FovMin          = 5.0,
    FovMax          = 120.0,
    DefaultFov      = 50.0,

    RecordRadius = 150.0,  

    PathDrawDistance = 150.0,

    DisableTutorialByDefault = false,

    AutosaveInterval = 30000,

    CinematicBucket = 69,

    DriftSmoke = {
        Enabled          = true,    
        PlayerThreadOn   = false,   
        Density          = 7,       
        Scale            = 0.12,    
        BackOnly         = true,    
        
        PlaybackMinSpeed = 3.0,     
        PlaybackCosLimit = 0.94,    
        BurnoutRpmHi     = 0.85,    
        BurnoutSpeed     = 12.0,    
        RedlineRpm       = 0.97,    
    },

    DefaultInterpolationMode = 'eased',

    DefaultKeyframeEasing = 'ease',

    RecordingStopKey = 177,

    WeatherConflictPatterns = {
        'weathersync', 'weather%-sync', 'weather_sync',
        'easytime',    'easyweather',
        'vsync',       'vsyncr',
        'cd_easytime', 'cd_easyweather',
        'wasabi_weathersync',
        'qb%-weathersync', 'qbx%-weathersync',
        'es_extended_weather', 'rprogress_weathersync',
    },

    ShakeTypes = {
        { id = 'HAND_SHAKE',                 label = 'Hand Shake' },
        { id = 'SMALL_EXPLOSION_SHAKE',      label = 'Small Explosion' },
        { id = 'MEDIUM_EXPLOSION_SHAKE',     label = 'Medium Explosion' },
        { id = 'LARGE_EXPLOSION_SHAKE',      label = 'Large Explosion' },
        { id = 'JOLT_SHAKE',                 label = 'Jolt' },
        { id = 'VIBRATE_SHAKE',              label = 'Vibrate' },
        { id = 'DRUNK_SHAKE',                label = 'Drunk' },
        { id = 'SKY_DIVING_SHAKE',           label = 'Skydiving' },
        { id = 'FAMILY5_DRUG_TRIP_SHAKE',    label = 'Drug Trip' },
        { id = 'DEATH_FAIL_IN_EFFECT_SHAKE', label = 'Death Fail' },
        { id = 'ROAD_VIBRATION_SHAKE',       label = 'Road Vibration' },
        { id = 'MOTORBIKE_SHAKE',            label = 'Motorbike' },
    },

    Fonts = {
        
        { label = 'Arial',               family = 'Arial' },
        { label = 'Impact',              family = 'Impact' },
        { label = 'Georgia',             family = 'Georgia' },
        { label = 'Courier New',         family = "'Courier New'" },
        { label = 'Verdana',             family = 'Verdana' },
        
        { label = 'Bebas Neue',          family = "'Bebas Neue'",            url = 'https://fonts.googleapis.com/css2?family=Bebas+Neue&display=swap' },
        { label = 'Anton',               family = "'Anton'",                 url = 'https://fonts.googleapis.com/css2?family=Anton&display=swap' },
        { label = 'Russo One',           family = "'Russo One'",             url = 'https://fonts.googleapis.com/css2?family=Russo+One&display=swap' },
        { label = 'Oswald',              family = "'Oswald'",                url = 'https://fonts.googleapis.com/css2?family=Oswald:wght@400;600;700&display=swap' },
        { label = 'Big Shoulders',       family = "'Big Shoulders Display'", url = 'https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@700;900&display=swap' },
        { label = 'Archivo Black',       family = "'Archivo Black'",         url = 'https://fonts.googleapis.com/css2?family=Archivo+Black&display=swap' },
        { label = 'Alfa Slab One',       family = "'Alfa Slab One'",         url = 'https://fonts.googleapis.com/css2?family=Alfa+Slab+One&display=swap' },
        { label = 'Fjalla One',          family = "'Fjalla One'",            url = 'https://fonts.googleapis.com/css2?family=Fjalla+One&display=swap' },
        { label = 'Black Ops One',       family = "'Black Ops One'",         url = 'https://fonts.googleapis.com/css2?family=Black+Ops+One&display=swap' },
        
        { label = 'Marcellus',           family = "'Marcellus'",             url = 'https://fonts.googleapis.com/css2?family=Marcellus&display=swap' },
        { label = 'Cinzel',              family = "'Cinzel'",                url = 'https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700;900&display=swap' },
        { label = 'Cinzel Decorative',   family = "'Cinzel Decorative'",     url = 'https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&display=swap' },
        { label = 'Staatliches',         family = "'Staatliches'",           url = 'https://fonts.googleapis.com/css2?family=Staatliches&display=swap' },
        { label = 'Unica One',           family = "'Unica One'",             url = 'https://fonts.googleapis.com/css2?family=Unica+One&display=swap' },
        { label = 'Six Caps',            family = "'Six Caps'",              url = 'https://fonts.googleapis.com/css2?family=Six+Caps&display=swap' },
        
        { label = 'Playfair Display',    family = "'Playfair Display'",      url = 'https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&display=swap' },
        { label = 'Cormorant Garamond',  family = "'Cormorant Garamond'",    url = 'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@700&display=swap' },
        { label = 'Abril Fatface',       family = "'Abril Fatface'",         url = 'https://fonts.googleapis.com/css2?family=Abril+Fatface&display=swap' },
        { label = 'Yeseva One',          family = "'Yeseva One'",            url = 'https://fonts.googleapis.com/css2?family=Yeseva+One&display=swap' },
        { label = 'Philosopher',         family = "'Philosopher'",           url = 'https://fonts.googleapis.com/css2?family=Philosopher:wght@400;700&display=swap' },
        
        { label = 'Orbitron',            family = "'Orbitron'",              url = 'https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap' },
        { label = 'Exo 2',               family = "'Exo 2'",                 url = 'https://fonts.googleapis.com/css2?family=Exo+2:wght@400;700;900&display=swap' },
        { label = 'Rajdhani',            family = "'Rajdhani'",              url = 'https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;700&display=swap' },
        { label = 'Montserrat',          family = "'Montserrat'",            url = 'https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700;900&display=swap' },
        { label = 'Teko',                family = "'Teko'",                  url = 'https://fonts.googleapis.com/css2?family=Teko:wght@500;700&display=swap' },
        { label = 'Audiowide',           family = "'Audiowide'",             url = 'https://fonts.googleapis.com/css2?family=Audiowide&display=swap' },
        { label = 'Monoton',             family = "'Monoton'",               url = 'https://fonts.googleapis.com/css2?family=Monoton&display=swap' },
        
        { label = 'Special Elite',       family = "'Special Elite'",         url = 'https://fonts.googleapis.com/css2?family=Special+Elite&display=swap' },
        { label = 'UnifrakturMaguntia',  family = "'UnifrakturMaguntia'",    url = 'https://fonts.googleapis.com/css2?family=UnifrakturMaguntia&display=swap' },
        { label = 'Pirata One',          family = "'Pirata One'",            url = 'https://fonts.googleapis.com/css2?family=Pirata+One&display=swap' },
        
        { label = 'Racing Sans One',     family = "'Racing Sans One'",       url = 'https://fonts.googleapis.com/css2?family=Racing+Sans+One&display=swap' },
        { label = 'Permanent Marker',    family = "'Permanent Marker'",      url = 'https://fonts.googleapis.com/css2?family=Permanent+Marker&display=swap' },
    },

    PredefinedAnimations = {
        
        { label = 'Lean Wall',       dict = 'amb@world_human_leaning@male@wall@back@hands_together@idle_a', anim = 'idle_a' },
        { label = 'Smoke',           dict = 'amb@world_human_smoking@male@male_a@idle_a',                   anim = 'idle_a' },
        { label = 'Clipboard',       dict = 'amb@world_human_clipboard@male@idle_a',                        anim = 'idle_a' },
        { label = 'Drinking',        dict = 'amb@world_human_drinking@coffee@male@idle_a',                  anim = 'idle_a' },
        { label = 'Phone Call',      dict = 'cellphone@',                                                   anim = 'cellphone_call_listen_base' },
        { label = 'Cheering',        dict = 'amb@world_human_cheering@male_a',                              anim = 'base' },
        { label = 'Push-ups',        dict = 'amb@world_human_push_ups@male@idle_a',                         anim = 'idle_a' },
        { label = 'Sit Ground',      dict = 'amb@world_human_picnic@male@idle_a',                           anim = 'idle_a' },
        { label = 'Guard Stand',     dict = 'amb@world_human_guard_stand@male@base',                        anim = 'base' },
        { label = 'Sweeping',        dict = 'amb@world_human_janitor@male@idle_a',                          anim = 'idle_a' },
        
        { label = 'Wave',            dict = 'friends@frj@ig_1',                                             anim = 'wave_a' },
        { label = 'Hands Up',        dict = 'missminuteman_1ig_2',                                          anim = 'handsup_base' },
        { label = 'Point Forward',   dict = 'gestures@m@standing@casual',                                   anim = 'gesture_point' },
        
        { label = 'Mechanic',        dict = 'mini@repair',                                                  anim = 'fixing_a_ped' },
        { label = 'Salute',          dict = 'anim@mp_player_intcelebrationmale@salute',                     anim = 'salute' },
        { label = 'Fishing',         dict = 'amb@world_human_stand_fishing@idle_a',                         anim = 'idle_a' },
        { label = 'Cop Idle',        dict = 'amb@world_human_cop_idles@male@idle_a',                        anim = 'idle_a' },
    },

    CommonWeapons = {
        { label = 'Unarmed',         hash = `WEAPON_UNARMED` },
        { label = 'Pistol',          hash = `WEAPON_PISTOL` },
        { label = 'Combat Pistol',   hash = `WEAPON_COMBATPISTOL` },
        { label = 'Heavy Pistol',    hash = `WEAPON_HEAVYPISTOL` },
        { label = 'SMG',             hash = `WEAPON_SMG` },
        { label = 'Assault Rifle',   hash = `WEAPON_ASSAULTRIFLE` },
        { label = 'Carbine Rifle',   hash = `WEAPON_CARBINERIFLE` },
        { label = 'Pump Shotgun',    hash = `WEAPON_PUMPSHOTGUN` },
        { label = 'Sniper Rifle',    hash = `WEAPON_SNIPERRIFLE` },
        { label = 'RPG',             hash = `WEAPON_RPG` },
        { label = 'Baseball Bat',    hash = `WEAPON_BAT` },
        { label = 'Knife',           hash = `WEAPON_KNIFE` },
        { label = 'Flashlight',      hash = `WEAPON_FLASHLIGHT` },
    },

    ColorFilters = {
        { id = 'none',           label = 'None',              timecycle = '' },
        { id = 'desat',          label = 'Desaturated',       timecycle = 'hud_def_desat_cult' },
        { id = 'sepia',          label = 'Sepia',             timecycle = 'int_lesters' },
        { id = 'bw',             label = 'Black & White',     timecycle = 'NG_blackout' },
        { id = 'warm',           label = 'Warm',              timecycle = 'DRUG_flying_base' },
        { id = 'cold',           label = 'Cold',              timecycle = 'MP_corona_heist_DOF' },
        { id = 'cinematic',      label = 'Cinematic',         timecycle = 'cinema' },
        { id = 'bloom',          label = 'Bloom',             timecycle = 'Bloom' },
        { id = 'drug',           label = 'Drug Trip',         timecycle = 'drug_wobbly' },
        { id = 'damage',         label = 'Damage',            timecycle = 'damage' },
        { id = 'dying',          label = 'Dying',             timecycle = 'dying' },
        { id = 'nightvision',    label = 'Night Vision',      timecycle = 'NVG' },
        { id = 'securitycam',    label = 'Security Cam',      timecycle = 'scanline_cam_cheap' },
        { id = 'spectator',      label = 'Spectator',         timecycle = 'spectator1' },
        { id = 'stunt',          label = 'Stunt',             timecycle = 'stunt_cam_base' },
        { id = 'introblue',      label = 'Intro Blue',        timecycle = 'NG_filmic01' },
        { id = 'introgreen',     label = 'Intro Green',       timecycle = 'NG_filmic02' },
        { id = 'introyellow',    label = 'Intro Yellow',      timecycle = 'NG_filmic03' },
        { id = 'pulse',          label = 'Pulse',             timecycle = 'WeaponDarkIn' },
        { id = 'underwater',     label = 'Underwater',        timecycle = 'art_underwater' },
        { id = 'michealdark',    label = 'Dark Moody',        timecycle = 'prologue_ending_fog' },
        { id = 'explosion',      label = 'Explosion Flash',   timecycle = 'ExplosionJosh' },
    },

}

local _localeData = {}

do
    local name = Config.Locale or 'en'
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. name .. '.json')
    if raw then
        _localeData = json.decode(raw) or {}
    end
end

function GetLocaleData()
    return _localeData
end

function _L(key, params)
    local parts = {}
    for part in string.gmatch(key, '[^%.]+') do
        parts[#parts + 1] = part
    end

    local val = _localeData
    for i = 1, #parts do
        if type(val) ~= 'table' then return key end
        val = val[parts[i]]
    end

    if type(val) ~= 'string' then return key end

    if params then
        val = val:gsub('{(%w+)}', function(k)
            return tostring(params[k] or ('{' .. k .. '}'))
        end)
    end

    return val
end

