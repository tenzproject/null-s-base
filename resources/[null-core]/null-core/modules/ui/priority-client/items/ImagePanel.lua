--[[
    ImagePanel - Panneau d'affichage d'image avec zoom et navigation
    
    Exemple d'utilisation:
    RageUI.ImagePanel("Aperçu du véhicule", "https://example.com/car.png", {
        width = 300,
        height = 200,
        clickable = true
    })
]]

RageUI.ImagePanel = LPH_NO_VIRTUALIZE(function(Title, ImageUrl, Options)
    if RageUI.CurrentMenu ~= nil or RageUI._Render.Active then
        local opts = Options or {}
        local item = {
            type = "imagepanel",
            label = Title or "Image",
            description = "",
            imageUrl = ImageUrl or "",
            width = opts.width or 300,
            height = opts.height or 200,
            clickable = opts.clickable or false,
            callback = opts.callback,
            enabled = false
        }
        RageUI._AddRenderItem(item)
        
        -- Stocker le callback dans le menu pour le NUI
        if RageUI.CurrentMenu and opts.callback then
            RageUI.CurrentMenu._imagePanelCallback = opts.callback
        end
    end
end)
