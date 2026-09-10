-- ============================================================================
-- Mode SHOWCASE (base de test / vitrine)
--   Activé via le convar `Null_showcase` dans le server.cfg :
--     setr Null_showcase "true"
--   Tout le module est inerte si le convar est absent → zéro impact sur les
--   serveurs normaux.
-- ============================================================================

Showcase = Showcase or {}

function Showcase.IsEnabled()
    return GetConvar('Null_showcase', 'false') == 'true'
end

-- Serveur : en mode showcase, une action sensible (ban/jail/bring/back/...) ne
-- peut viser QUE soi-même. Retourne true si l'action sur `targetSource` doit
-- être bloquée pour l'auteur `src`.
function Showcase.BlocksTarget(src, targetSource)
    if not Showcase.IsEnabled() then return false end
    if src == 0 then return false end -- console autorisée
    targetSource = tonumber(targetSource)
    if not targetSource then return true end -- pas de cible claire → on bloque
    return targetSource ~= tonumber(src)
end
