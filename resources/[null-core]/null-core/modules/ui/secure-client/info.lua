local displayInfo = true
local lastItem = nil
local lastCategory = nil
local lastTitle = nil 

ShowInfo = LPH_NO_VIRTUALIZE(function(title, items, category, name, icon, color)
    if not displayInfo then return end

    if category ~= "info_dialog" and category ~= "info_dialog_staff" then
        category = "info_dialog"
    end
    local infoCategory = category or 'info_dialog'

    if (title == lastTitle) and (infoCategory == lastCategory) and (json.encode(items) == lastItem) then
        return
    end

    local data = {
        type = 'SHOW_INFO',
        title = title,
        items = items or {},
        category = infoCategory,
        name = name,
        icon = icon,
        color = color
    }
    
    lastTitle = title
    lastItem = json.encode(items)
    lastCategory = infoCategory
    
    SendNUIMessage(data)
end)

function HideInfo(category)
    if category == nil then 
        category = "all"
    end

    SendNUIMessage({
        type = 'HIDE_INFO',
        category = category
    })
    
    lastTitle = nil
    lastItem = nil
    lastCategory = nil
end

function ForceCanInfo(bool)
    displayInfo = bool
    SendNUIMessage({
        type = 'FORCE_CAN_INFO',
        bool = bool
    })
end

exports('ShowInfo', ShowInfo)
exports('HideInfo', HideInfo)
exports('ForceCanInfo', ForceCanInfo)

-- -- @TODO: Supprimer les commandes de test

-- -- Test commands
-- RegisterCommand('testinfo', function()
--     ShowInfo('Informations Joueur', {
--         { left = 'Nom', right = 'John Doe' },
--         { left = 'Argent', right = '$5,000', color = '#10b981' },
--         { left = 'Niveau', right = '25', color = '#42a5f5' }
--     }, 'info_dialog_staff')

-- end)

-- RegisterCommand('testinfoadvanced', function()
--     ShowInfo('Statistiques Avancées', {
--         { left = 'Santé', right = '80/100', leftIcon = 'fas fa-heart' }, 
--         { left = 'Armure', right = '50/100', leftIcon = 'fas fa-shield' },
--         { left = 'Faim', right = '60/100', leftIcon = 'fas fa-utensils' },
--         { left = 'Soif', right = '40/100', leftIcon = 'fas fa-tint' },
--         { left = 'VIP Actif', right = true, leftIcon = 'fas fa-star' },
--         { left = 'Mode Passif', right = false, leftIcon = 'fas fa-hand-paper' }
--     }, 'info_dialog', 'Null RP', 'https://i.imgur.com/example.png', '#42a5f5')
    
-- end)

-- RegisterCommand('testinfostaff', function()
--     ShowInfo('Barre Compacte', {
--         { left = 'Joueurs', right = '45/64' },
--         { left = 'Ping', right = '25ms', color = '#10b981' },
--         { left = 'FPS', right = '60', color = '#42a5f5' }
--     }, 'info_dialog_staff')
    
-- end)

-- RegisterCommand('testinfotopright', function()
--     ShowInfo('Notifications', {
--         { left = 'Messages', right = '3', color = '#ef4444' },
--         { left = 'Alertes', right = '1', color = '#f59e0b' }
--     }, 'info_dialog')
    
--     print('Info UI affichée')
-- end)

-- RegisterCommand('testinfomiddleleft', function()
--     ShowInfo('Menu Gauche', {
--         { left = 'Option A', right = 'Activé', rightIcon = 'fas fa-check' },
--         { left = 'Option B', right = 'Désactivé', rightIcon = 'fas fa-times' }
--     }, 'info_dialog')
    
--     print('Info UI affichée')
-- end)

-- RegisterCommand('testinfoprogress', function()
--     ShowInfo('Progression', {
--         { left = 'XP', right = '750/1000' },
--         { left = 'Missions', right = '12/20' },
--         { left = 'Succès', right = '45/100' }
--     }, 'info_dialog', 'Progression', nil, '#f59e0b')
    
--     print('Info UI avec barres de progression')
-- end)

-- RegisterCommand('testinfobool', function()
--     ShowInfo('États', {
--         { left = 'Connecté', right = true },
--         { left = 'En mission', right = true },
--         { left = 'En combat', right = false },
--         { left = 'Recherché', right = false }
--     }, 'info_dialog')
    
--     print('Info UI avec valeurs booléennes')
-- end)

-- RegisterCommand('hideinfo', function()
--     HideInfo()
--     print('Info UI masquée')
-- end)
