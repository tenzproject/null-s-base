-- =============================================================================
-- Comptes bancaires / types d'argent
-- =============================================================================

-- @dashboardLabel: Comptes disponibles
-- @dashboardDescription: Types d'argent du serveur : cash (liquide), dirtycash (sale), bank (banque), chip (casino), etc. Pour chaque compte vous pouvez régler le solde de départ et les droits (lâcher/donner).
-- @dashboardGroup: Économie
-- @dashboardWidget: object
Config.Accounts = {
    ['cash'] = {
        -- @dashboardLabel: Cash — solde initial
        -- @dashboardGroup: Économie
        -- @dashboardWidget: money
        label = _U('cash'),
        starting = 15000,
        priority = 1,
        canDrop = true,
        canGive = true,
    },
    ['dirtycash'] = {
        -- @dashboardLabel: Argent sale — solde initial
        -- @dashboardGroup: Économie
        -- @dashboardWidget: money
        label = _U('dirtycash'),
        starting = 0,
        priority = 2,
        canDrop = true,
        canGive = true,
    },
    ['bank'] = {
        -- @dashboardLabel: Banque — solde initial
        -- @dashboardGroup: Économie
        -- @dashboardWidget: money
        label = _U('bank'),
        starting = 20000,
        priority = 3,
        canDrop = false,
        canGive = false,
    },
    ['chip'] = {
        label = 'Jetons Casino',
        starting = 0,
        priority = 4,
        canDrop = false,
        canGive = true,
    },
    ['fidelcoins'] = {
        label = 'Points de Fidélité',
        starting = 0,
        priority = 5,
        canDrop = false,
        canGive = false,
    }
}

function Config.AddAccount(name, data)
    if Config.Accounts[name] then
        return false, 'Account already exists'
    end
    
    Config.Accounts[name] = {
        label = data.label or name,
        starting = data.starting or 0,
        priority = data.priority or (#Config.Accounts + 1),
        canDrop = data.canDrop ~= nil and data.canDrop or false,
        canGive = data.canGive ~= nil and data.canGive or false,
    }
    
    return true
end
