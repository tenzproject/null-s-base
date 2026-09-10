local screenshotQueue = {}
local isProcessing = false

local function ProcessScreenshotQueue()
    if isProcessing or #screenshotQueue == 0 then
        return
    end
    
    isProcessing = true
    local data = table.remove(screenshotQueue, 1)
    
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local rawImagesPath = resourcePath .. "/raw_images"
    
    exports['screenshot-basic']:requestClientScreenshot(data.source, {
        fileName = rawImagesPath .. "/" .. data.filename,
        encoding = 'png',
        quality = 1.0
    }, function(err, screenshotData)
        if err then
            print("^1[ImageMaker] Erreur screenshot: " .. err .. "^0")
        else
            print("^2[ImageMaker] Screenshot sauvegardé: " .. data.filename .. "^0")
        end
        
        isProcessing = false
        
        if #screenshotQueue > 0 then
            SetTimeout(100, ProcessScreenshotQueue)
        end
    end)
end

RegisterNetEvent('null-imagemaker:saveScreenshot')
AddEventHandler('null-imagemaker:saveScreenshot', function(data)
    local source = source
    
    table.insert(screenshotQueue, {
        source = source,
        category = data.category,
        index = data.index,
        gender = data.gender,
        filename = data.filename,
        genderSpecific = data.genderSpecific
    })
    
    if not isProcessing then
        ProcessScreenshotQueue()
    end
end)

print("^2[ImageMaker] Serveur chargé^0")
