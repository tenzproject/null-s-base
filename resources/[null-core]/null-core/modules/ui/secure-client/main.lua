-- Null Interactions UI
-- Modern Input and Confirm dialogs

local InteractionsUI = {}
local currentPromise = nil

-- Open Input Dialog
function InteractionsUI.Input(data, resource)
    if currentPromise then
        return nil
    end

    currentPromise = promise.new() 
    
    local hasFocus, hasInputFocus = IsNuiFocused() == 1 and true or false, IsNuiFocusKeepingInput() == 1 and true or false

    local fields = {}
    if type(data) == "table" and data[1] then
        fields = data
    elseif type(data) == "table" and data.fields then
        fields = data.fields
    else
        fields = {{
            type = "input",
            label = data or "Saisie",
            required = true
        }}
    end

    SendNUIMessage({
        action = "openInput",
        title = type(data) == "table" and data.title or "Saisie",
        fields = fields,
        options = type(data) == "table" and data.options or nil,
        size = type(data) == "table" and data.size or nil
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    Citizen.CreateThread(function() 
        FocusTime = 0
        while currentPromise ~= nil and FocusTime < 500 do
            SetNuiFocus(true, true)
            Citizen.Wait(50)
            FocusTime = FocusTime + 50
        end
    end)

    local result = Citizen.Await(currentPromise)
    currentPromise = nil
    
    SendNUIMessage({action = "hideFocus"})
    
    if not hasFocus or resource ~= "null-core" then
        SetNuiFocus(false, false)
    end

    if hasInputFocus and resource == "null-core"  then
        SetNuiFocusKeepInput(true)
    end
    
    return result
end

-- Open Confirm Dialog
function InteractionsUI.Confirm(data)
    if currentPromise then
        return false
    end

    currentPromise = promise.new()
    
    local hasFocus, hasInputFocus = IsNuiFocused() == 1 and true or false, IsNuiFocusKeepingInput() == 1 and true or false

    local confirmData = {
        title = "Confirmation",
        message = "Êtes-vous sûr ?",
        type = "info",
        yesLabel = "Oui",
        noLabel = "Non"
    }

    if type(data) == "string" then
        confirmData.message = data
    elseif type(data) == "table" then
        confirmData.title = data.title or confirmData.title
        confirmData.message = data.message or confirmData.message
        confirmData.type = data.type or confirmData.type
        confirmData.yesLabel = data.yesLabel or confirmData.yesLabel
        confirmData.noLabel = data.noLabel or confirmData.noLabel
    end

    SendNUIMessage({
        action = "openConfirm",
        title = confirmData.title,
        message = confirmData.message,
        type = confirmData.type,
        yesLabel = confirmData.yesLabel,
        noLabel = confirmData.noLabel
    })

    Citizen.Wait(100)
    SetNuiFocus(true, true) 
    SetNuiFocusKeepInput(false)

    local result = Citizen.Await(currentPromise)
    currentPromise = nil
    
    SendNUIMessage({action = "hideFocus"})

    -- Ne désactiver le NUI Focus que s'il n'était pas déjà actif avant
    if not hasFocus or resource ~= "null-core" then
        SetNuiFocus(false, false)
    end

    if hasInputFocus and resource == "null-core" then
        SetNuiFocusKeepInput(true)
    end
    
    return result
end 

-- NUI Callbacks
RegisterNUICallback('inputDialogSubmit', function(data, cb)
    if currentPromise then
        currentPromise:resolve(data.values)
    end
    cb('ok')
end) 

RegisterNUICallback('inputDialogCancel', function(data, cb)
    if currentPromise then
        currentPromise:resolve(nil)
    end
    cb('ok')
end)

RegisterNUICallback('confirmDialogYes', function(data, cb)
    if currentPromise then
        currentPromise:resolve(true)
    end
    cb('ok')
end)

RegisterNUICallback('confirmDialogNo', function(data, cb)
    if currentPromise then
        currentPromise:resolve(false)
    end
    cb('ok')
end)

-- Export functions
exports('Input', function(data, resourceName)
    return InteractionsUI.Input(data, resourceName)
end)

exports('Confirm', function(data, resourceName)
    return InteractionsUI.Confirm(data, resourceName)
end)

-- Compatibility wrapper for old null-ui exports
exports('InputRequest', function(title)
    return InteractionsUI.Input({
        title = title,
        fields = {
            {
                type = "input",
                label = title,
                required = true
            }
        }
    })
end)

exports('ConfirmRequest', function(message, title, type)
    return InteractionsUI.Confirm({
        message = message or "Êtes-vous sûr ?",
        title = title or "Confirmation",
        type = type or "info"
    })
end)

-- Global functions for compatibility
function NullInput(data, resourceName)
    return InteractionsUI.Input(data, resourceName)
end

function NullConfirm(data, resourceName)
    return InteractionsUI.Confirm(data, resourceName)
end

-- @TODO: Supprimer les commandes de test


RegisterCommand('setfocus_Nullcore', function()
    SetNuiFocus(true, true)
end, false)

RegisterCommand('setunfocus_Nullcore', function()
    SetNuiFocus(false, false)
end, false)

-- -- Test Commands
RegisterCommand('testinput', function()
    local result = InteractionsUI.Input({
        title = "Test Input Simple",
        fields = {
            {
                type = "input",
                label = "Votre nom",
                placeholder = "Entrez votre nom...",
                required = true,
                icon = "fa-solid fa-user"
            }
        }
    })
    
    if result then
        print("Résultat:", json.encode(result))
    else
        print("Annulé")
    end
end, false)

RegisterCommand('testinputadvanced', function()
    local result = InteractionsUI.Input({
        title = "Formulaire Avancé",
        fields = {
            {
                type = "input",
                label = "Nom du joueur",
                placeholder = "John Doe",
                required = true,
                icon = "fa-solid fa-user",
                description = "Entrez le nom complet du joueur"
            },
            {
                type = "number",
                label = "Montant",
                placeholder = "1000",
                min = 0,
                max = 999999,
                required = true,
                icon = "fa-solid fa-dollar-sign",
                description = "Montant entre 0 et 999999"
            },
            {
                type = "select",
                label = "Catégorie",
                options = {
                    {value = "admin", label = "Administrateur"},
                    {value = "moderator", label = "Modérateur"},
                    {value = "player", label = "Joueur"}
                },
                required = true,
                icon = "fa-solid fa-list"
            },
            {
                type = "textarea",
                label = "Raison",
                placeholder = "Expliquez la raison...",
                rows = 4,
                icon = "fa-solid fa-message"
            },
            {
                type = "checkbox",
                label = "Confirmation",
                checkboxLabel = "J'ai vérifié les informations",
                required = true
            }
        }
    })
    
    if result then
        print("Résultat:", json.encode(result))
    else
        print("Annulé")
    end
end, false)

RegisterCommand('testconfirm', function()
    local result = InteractionsUI.Confirm({
        title = "Confirmation",
        message = "Êtes-vous sûr de vouloir effectuer cette action ?",
        type = "info"
    })
    
    print("Résultat:", result and "OUI" or "NON")
end, false)

RegisterCommand('testconfirmwarning', function()
    local result = InteractionsUI.Confirm({
        title = "Attention",
        message = "Cette action est irréversible. Voulez-vous continuer ?",
        type = "warning",
        yesLabel = "Continuer",
        noLabel = "Annuler"
    })
    
    print("Résultat:", result and "OUI" or "NON")
end, false)

RegisterCommand('testconfirmerror', function()
    local result = InteractionsUI.Confirm({
        title = "Erreur Critique",
        message = "Une erreur s'est produite. Voulez-vous réessayer ?",
        type = "error",
        yesLabel = "Réessayer",
        noLabel = "Abandonner"
    })
    
    print("Résultat:", result and "OUI" or "NON")
end, false)

RegisterCommand('testconfirmsuccess', function()
    local result = InteractionsUI.Confirm({
        title = "Succès",
        message = "L'opération a réussi ! Voulez-vous continuer ?",
        type = "success",
        yesLabel = "Continuer",
        noLabel = "Terminer"
    })
    
    print("Résultat:", result and "OUI" or "NON")
end, false)