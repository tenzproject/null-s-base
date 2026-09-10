-- Système de pathfinding intelligent avec waypoints par pièce
-- Évite les murs en utilisant des chemins prédéfinis entre les pièces

-- Définition des waypoints (positions clés) par pièce
local LabWaypoints = {
    -- Bureau principal (où sont les employés par défaut)
    office = {
        pos = vector3(-318.782990, -1349.784180, 24.904272),
        name = "Bureau",
        connectedTo = {"lab_entrance"}
    },
    
    -- Entrée du labo (entre bureau et production)
    lab_entrance = {
        pos = vector3(-319.102631, -1355.442261, 24.904272),
        name = "Entrée Labo",
        connectedTo = {"office", "production_entrance"}
    },
    
    -- Entrée partie production
    production_entrance = {
        pos = vec3(-315.251007, -1354.124878, 24.309631),
        name = "Entrée Production",
        connectedTo = {"lab_entrance", "storage_entrance", "cuve1_path", "cuve2_path", "four_path"}
    },
    
    -- Chemin vers cuve 1
    cuve1_path = {
        pos = vec3(-311.386200, -1354.404175, 24.309628),
        name = "Chemin Cuve 1",
        connectedTo = {"production_entrance", "cuve1"}
    },
    
    -- Cuve 1
    cuve1 = {
        pos = vec3(-310.433746, -1357.485840, 24.805618),
        name = "Cuve 1",
        connectedTo = {"cuve1_path"}
    },
    
    -- Chemin vers cuve 2 (évite la table)
    cuve2_path = {
        pos = vec3(-308.590698, -1353.212769, 24.309652),
        name = "Chemin Cuve 2",
        connectedTo = {"production_entrance", "cuve2"}
    },
    
    -- Cuve 2
    cuve2 = {
        pos = vec3(-304.509735, -1350.923950, 24.817648),
        name = "Cuve 2",
        connectedTo = {"cuve2_path"}
    },
    
    -- Chemin vers les fours
    four_path = {
        pos = vec3(-313.294006, -1361.129883, 24.309652),
        name = "Chemin Fours",
        connectedTo = {"production_entrance", "four1", "four2", "four3"}
    },
    
    -- Four 1
    four1 = {
        pos = vec3(-314.925018, -1360.978516, 24.309652),
        name = "Four 1",
        connectedTo = {"four_path"}
    },
    
    -- Four 2
    four2 = {
        pos = vec3(-313.294006, -1361.129883, 24.309652),
        name = "Four 2",
        connectedTo = {"four_path"}
    },
    
    -- Four 3
    four3 = {
        pos = vec3(-311.640320, -1361.129639, 24.309652),
        name = "Four 3",
        connectedTo = {"four_path"}
    },
    
    -- Station de cassage meth (breakpoints)
    breakpoint_path = {
        pos = vec3(-313.442383, -1347.551514, 24.309658),
        name = "Chemin Cassage",
        connectedTo = {"production_entrance", "breakpoint1", "breakpoint2"}
    },
    
    -- Point de cassage 1
    breakpoint1 = {
        pos = vec3(-307.226959, -1346.851562, 24.309658),
        name = "Cassage 1",
        connectedTo = {"breakpoint_path"}
    },
    
    -- Point de cassage 2
    breakpoint2 = {
        pos = vec3(-308.708466, -1346.947510, 24.309658),
        name = "Cassage 2",
        connectedTo = {"breakpoint_path"}
    },
    
    -- Entrée stockage (accès direct au séchage)
    storage_entrance = {
        pos = vec3(-315.342407, -1359.996460, 24.309656),
        name = "Entrée Stockage",
        connectedTo = {"production_entrance", "storage"}
    },
    
    -- Stockage
    storage = {
        pos = vector3(-320.923187, -1359.961914, 24.309654),
        name = "Stockage",
        connectedTo = {"storage_entrance"}
    },
    
    -- Chemin partie gauche (accès aux chaises de traitement weed)
    left_path = {
        pos = vector3(-315.179626, -1348.034912, 24.309626),
        name = "Chemin Gauche",
        connectedTo = {"production_entrance", "treatment_chairs"}
    },
    
    -- Chaises de traitement des plantes
    treatment_chairs = {
        pos = vector3(-308.169006, -1347.978149, 24.309626),
        name = "Chaises Traitement",
        connectedTo = {"left_path"}
    }
}

-- Algorithme de pathfinding simple (BFS - Breadth First Search)
local function FindPath(startWaypoint, targetPos)
    -- Trouver le waypoint le plus proche de la position cible
    local closestWaypoint = nil
    local closestDist = math.huge
    
    for waypointId, waypoint in pairs(LabWaypoints) do
        local dist = #(waypoint.pos - targetPos)
        if dist < closestDist then
            closestDist = dist
            closestWaypoint = waypointId
        end
    end
    
    if not closestWaypoint then
        return nil
    end
    
    -- Si on est déjà au bon waypoint, retourner directement la cible
    if startWaypoint == closestWaypoint then
        return {targetPos}
    end
    
    -- BFS pour trouver le chemin le plus court
    local queue = {{waypoint = startWaypoint, path = {}}}
    local visited = {[startWaypoint] = true}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local currentWaypoint = current.waypoint
        local currentPath = current.path
        
        -- Si on a atteint le waypoint cible
        if currentWaypoint == closestWaypoint then
            -- Construire le chemin complet avec positions
            local fullPath = {}
            for _, wpId in ipairs(currentPath) do
                table.insert(fullPath, LabWaypoints[wpId].pos)
            end
            table.insert(fullPath, LabWaypoints[closestWaypoint].pos)
            table.insert(fullPath, targetPos) -- Ajouter la destination finale
            return fullPath
        end
        
        -- Explorer les waypoints connectés
        for _, connectedId in ipairs(LabWaypoints[currentWaypoint].connectedTo) do
            if not visited[connectedId] then
                visited[connectedId] = true
                local newPath = {}
                for i, v in ipairs(currentPath) do
                    newPath[i] = v
                end
                table.insert(newPath, currentWaypoint)
                table.insert(queue, {waypoint = connectedId, path = newPath})
            end
        end
    end
    
    -- Aucun chemin trouvé, retourner chemin direct
    return {targetPos}
end

-- Fonction pour trouver le waypoint le plus proche d'une position
local function GetClosestWaypoint(pos)
    local closestWaypoint = nil
    local closestDist = math.huge
    
    for waypointId, waypoint in pairs(LabWaypoints) do
        local dist = #(waypoint.pos - pos)
        if dist < closestDist then
            closestDist = dist
            closestWaypoint = waypointId
        end
    end
    
    return closestWaypoint
end

-- Fonction principale : faire marcher un ped d'un point A à un point B avec pathfinding
NavigatePedToPosition = LPH_NO_VIRTUALIZE(function(ped, targetPos, timeout)
    if not DoesEntityExist(ped) then 
        return false 
    end
    
    FreezeEntityPosition(ped, false)

    local startPos = GetEntityCoords(ped)
    local startWaypoint = GetClosestWaypoint(startPos)
    
    if not startWaypoint then
        --null.DebugPrint("[PATHFINDING] Could not find start waypoint")
        return false
    end
    
    -- Trouver le chemin
    local path = FindPath(startWaypoint, targetPos)
    
    if not path or #path == 0 then
        --null.DebugPrint("[PATHFINDING] No path found")
        return false
    end
    
    -- Suivre le chemin waypoint par waypoint
    for i, waypointPos in ipairs(path) do
        local retryCount = 0
        local maxRetries = 5
        local waypointReached = false
        
        while retryCount < maxRetries and not waypointReached do
            ClearPedTasks(ped)
            Wait(50)
            
            -- Utiliser TaskGoStraightToCoord (fonctionne server-side!)
            TaskGoStraightToCoord(ped, waypointPos.x, waypointPos.y, waypointPos.z, 1.0, -1, 0.0, 0.0)
            
            -- Attendre que le ped arrive au waypoint
            local attempts = 0
            local maxAttempts = timeout or 500
            local lastDist = nil
            local stuckCount = 0
            
            while attempts < maxAttempts do
                if not DoesEntityExist(ped) then 
                    return false 
                end
                
                local currentPos = GetEntityCoords(ped)
                local dist = #(currentPos - waypointPos)
                
                -- Vérifier si le waypoint est atteint
                if dist < 1.0 then
                    waypointReached = true
                    break
                end
                
                -- Détecter si le ped est bloqué (distance ne change pas)
                if lastDist and math.abs(dist - lastDist) < 1.0 then
                    stuckCount = stuckCount + 1
                    if stuckCount > 50 then -- Bloqué pendant 5 secondes
                        break -- Sortir pour réessayer
                    end
                else
                    stuckCount = 0
                end
                lastDist = dist
                
                Wait(100)
                attempts = attempts + 1
            end
            
            -- Si timeout sans être bloqué, considérer comme échec
            if attempts >= maxAttempts and not waypointReached then
                break
            end
            
            -- Si toujours pas arrivé, incrémenter retry
            if not waypointReached then
                retryCount = retryCount + 1
            end
        end
        
        -- Si après 3 tentatives le ped n'est pas arrivé, téléporter
        if not waypointReached then
            --null.DebugPrint("[PATHFINDING] Failed to reach waypoint, teleporting")
            SetEntityCoords(ped, waypointPos.x, waypointPos.y, waypointPos.z - 0.5, false, false, false, false)
        end
    end
    
    return true
end)