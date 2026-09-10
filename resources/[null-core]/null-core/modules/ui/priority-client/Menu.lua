RageUI.CreateMenu = LPH_NO_VIRTUALIZE(function(Title, Subtitle, MaxVisibleItems, TextureDictionary, TextureName)
    local Menu = {}
    
    Menu.Title = Title or ""
    Menu.Subtitle = Subtitle or ""
    Menu.X = Config.NykzUI.DefaultPosition.X
    Menu.Y = Config.NykzUI.DefaultPosition.Y
    Menu.Open = false
    Menu.Index = 1
    Menu.Parent = nil
    Menu.Items = {}
    
    -- Utiliser MaxVisibleItems personnalisé ou la valeur par défaut
    local maxItems = MaxVisibleItems or Config.NykzUI.MenuSize.MaxVisibleItems
    Menu.Pagination = { Minimum = 1, Maximum = maxItems, Total = maxItems }
    Menu.MaxVisibleItems = maxItems
    Menu.Closable = true
    Menu.EnableMouse = true
    
    -- Propriété Display pour compatibilité avec l'ancien RageUI
    Menu.Display = {
        Header = true,
        Glare = false,
        Instructional = true
    }
    
    -- Propriétés de texture (pour compatibilité)
    Menu.TextureDictionary = TextureDictionary
    Menu.TextureName = TextureName
    
    return setmetatable(Menu, RageUI.Menus)
end)

RageUI.CreateSubMenu = LPH_NO_VIRTUALIZE(function(ParentMenu, Title, Subtitle, MaxVisibleItems)
    if ParentMenu ~= nil then
        local Menu = RageUI.CreateMenu(
            Title or ParentMenu.Title,
            Subtitle or ParentMenu.Subtitle,
            MaxVisibleItems or ParentMenu.MaxVisibleItems
        )
        Menu.Parent = ParentMenu
        return Menu
    end
    return nil
end)

function RageUI.Menus:SetTitle(Title)
    self.Title = Title
    if self.Open then
        RageUI.SendNUI("updateTitle", { title = Title })
    end
end

function RageUI.Menus:SetSubtitle(Subtitle)
    self.Subtitle = Subtitle
    if self.Open then
        RageUI.SendNUI("updateSubtitle", { subtitle = Subtitle })
    end
end

function RageUI.Menus:RefreshIndex()
    self.Index = 1
end

function RageUI.Menus:ClearItems()
    self.Items = {}
end

function RageUI.Menus:AddItem(item)
    table.insert(self.Items, item)
end

RageUI.Menus.Refresh = LPH_NO_VIRTUALIZE(function(self)
    if self.Open and RageUI.CurrentMenu == self then
        local nuiItems = {}
        for i, item in ipairs(self.Items) do
            table.insert(nuiItems, {
                type = item.type,
                label = item.label,
                description = item.description or "",
                rightLabel = item.rightLabel or "",
                value = item.value,
                min = item.min,
                max = item.max,
                items = item.items,
                checked = item.checked,
                enabled = item.enabled ~= false,
                leftBadge = item.leftBadge,
                rightBadge = item.rightBadge,
                leftItems = item.leftItems,
                rightItems = item.rightItems,
                panelItems = item.panelItems,
                collapsed = item.collapsed,
                _isHeader = item._isHeader,
                _isCollapsibleChild = item._isCollapsibleChild,
                _parentIndex = item._parentIndex,
            })
        end
        
        RageUI.SendNUI("setItems", {
            items = nuiItems,
            index = self.Index - 1
        })
    end
end)

function RageUI.OpenMenu(menu)
    if menu ~= nil then
        -- Fermer le menu actuel proprement si un autre est ouvert
        if RageUI.CurrentMenu ~= nil and RageUI.CurrentMenu ~= menu then
            local oldMenu = RageUI.CurrentMenu
            oldMenu.Open = false
            oldMenu._lastHash = nil
        end
        
        menu.Open = true
        RageUI.CurrentMenu = menu
        menu._lastHash = nil
        menu.Items = {}
        
        RageUI.SendNUI("openMenu", {
            title = menu.Title,
            subtitle = menu.Subtitle,
            position = { x = menu.X, y = menu.Y },
            maxVisibleItems = menu.MaxVisibleItems
        })
    end
end

function RageUI.CloseMenu(menu)
    if menu ~= nil then
        menu.Open = false
        menu._lastHash = nil
        if RageUI.CurrentMenu == menu then
            RageUI.CurrentMenu = nil
            RageUI.SendNUI("closeMenu", {})
        end
    end
end

-- Fonctions de compatibilité avec l'ancien RageUI
function RageUI.Menus:DisplayGlare(bool)
    -- NUI ne supporte pas le glare, fonction vide pour compatibilité
end

function RageUI.Menus:DisplayHeader(bool)
    -- NUI ne supporte pas le header display, fonction vide pour compatibilité
end

function RageUI.Menus:SetRectangleBanner(r, g, b, a)
    -- NUI ne supporte pas les banners rectangle, fonction vide pour compatibilité
end

function RageUI.Menus:AcceptFilter(bool)
    -- NUI ne supporte pas les filtres, fonction vide pour compatibilité
end

function RageUI.ResetFiltre()
    -- NUI ne supporte pas les filtres, fonction vide pour compatibilité
end