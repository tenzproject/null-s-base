-- Null Confirm Functions
-- Uses the new null-core InteractionsUI system

null.fct.confirm = LPH_NO_VIRTUALIZE(function(message, title, type)
    local confirmData = {
        message = message or "Êtes-vous sûr de vouloir effectuer cette action ?",
        title = title or "Confirmation",
        type = type or "info",
        yesLabel = "Oui",
        noLabel = "Non"
    }
    
    local result = exports['null-core']:Confirm(confirmData)
    return result
end)

-- Alias for compatibility with null.fct.confirm
null.fct.confirmRequest = LPH_NO_VIRTUALIZE(function(message, title, type)
    return null.fct.confirm(message, title, type)
end)
