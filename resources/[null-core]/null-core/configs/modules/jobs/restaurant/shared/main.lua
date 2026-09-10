Restaurant = {}

-- ============================================================================
-- Supplier system config
-- ============================================================================
Restaurant.Supplier = {
    PedModel      = 'a_m_m_hillbilly_01', -- Supplier ped model
    PedCoords     = vector4(-112.4072, 1881.9626, 197.3333, 97.5860), -- Supplier position
    PaletteCoords = vector4(-86.0729, 1879.9510, 197.3089, 270.7534), -- Command spawn pos
    PaletteProp   = 'prop_boxpile_03a', -- Command prop model 
    DeliveryTime  = 50,  -- Seconds before delivery arrives
    BossOnly      = true,  -- Only boss grade can order
}