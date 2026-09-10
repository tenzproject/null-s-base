Config = Config or {}

-- @dashboardLabel: Optimisation serveur
-- @dashboardDescription: Active/désactive certaines ressources pour gagner en performance.
-- @dashboardGroup: Performance
Config.Optimization = {
    ["screenshot-basic"] = {
        -- @dashboardLabel: Screenshot-basic activé
        -- @dashboardDescription: Active la ressource screenshot-basic (captures d'écran client). Désactivez pour gagner ~0.02-0.05ms en permanence. Nécessaire pour certains modules admin.
        -- @dashboardGroup: Performance
        -- @dashboardWidget: boolean
        Enable = true,
    }
}

-- Le flag Enable=false reste dispo pour les modules qui veulent skip les screenshots côté logique.
if not Config.Optimization["screenshot-basic"].Enable then
    print("[NullCore] Config.Optimization[\"screenshot-basic\"].Enable=false : la ressource reste chargée (bundlée dans null-deps) mais ne sera pas appelée par les modules qui respectent ce flag.")
end