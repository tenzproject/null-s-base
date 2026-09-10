-- Exports for external resources to access animation data

-- Export to get all animations data
exports('GetAllAnimations', function()
    local data = {
        emotes = {},
        dances = {},
        shared = {},
        props = {},
        walks = {},
        expressions = {},
        animals = {}
    }
    
    -- Get emotes from RP.Emotes
    if RP and RP.Emotes then
        for key, anim in pairs(RP.Emotes) do
            local label = anim[3] or key
            data.emotes[key] = {
                name = key,
                label = label,
                command = key,
                category = "emotes"
            }
        end
    end
    
    -- Get dances from RP.Dances
    if RP and RP.Dances then
        for key, anim in pairs(RP.Dances) do
            local label = anim[3] or key
            data.dances[key] = {
                name = key,
                label = label,
                command = key,
                category = "dances"
            }
        end
    end
    
    -- Get shared emotes from RP.Shared
    if RP and RP.Shared then
        for key, anim in pairs(RP.Shared) do
            local label = anim[3] or key
            data.shared[key] = {
                name = key,
                label = label,
                command = key,
                category = "shared"
            }
        end
    end
    
    -- Get prop emotes from RP.PropEmotes
    if RP and RP.PropEmotes then
        for key, anim in pairs(RP.PropEmotes) do
            local label = anim[3] or key
            data.props[key] = {
                name = key,
                label = label,
                command = key,
                category = "props"
            }
        end
    end
    
    -- Get walks from RP.Walks
    if RP and RP.Walks then
        for key, walk in pairs(RP.Walks) do
            local label = walk[2] or key
            data.walks[key] = {
                name = key,
                label = label,
                command = key,
                category = "walks"
            }
        end
    end
    
    -- Get expressions from RP.Expressions
    if RP and RP.Expressions then
        for key, expr in pairs(RP.Expressions) do
            local label = expr[2] or key
            data.expressions[key] = {
                name = key,
                label = label,
                command = key,
                category = "expressions"
            }
        end
    end
    
    -- Get animal emotes from RP.AnimalEmotes
    if RP and RP.AnimalEmotes then
        for key, anim in pairs(RP.AnimalEmotes) do
            local label = anim[3] or key
            data.animals[key] = {
                name = key,
                label = label,
                command = key,
                category = "animals"
            }
        end
    end
    
    return data
end)

-- Export to check if animations are loaded
exports('AreAnimationsLoaded', function()
    return RP and RP.Emotes ~= nil
end)

-- Export to play an animation
exports('PlayAnimation', function(animName)
    if EmoteCommandStart then
        EmoteCommandStart(nil, {animName, 0})
        return true
    end
    return false
end)

-- Export to cancel current animation
exports('CancelAnimation', function()
    if EmoteCancel then
        EmoteCancel()
        return true
    end
    return false
end)
