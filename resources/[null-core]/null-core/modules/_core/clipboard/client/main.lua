function Copy(value)
    SendNUIMessage({
        action = 'copy',
        tool = value,
        text = value
    })
end

RegisterNUICallback("copyToClipboard", function(data, cb)
    Copy(data.text)
    cb('ok')
end)

null.fct.copy = Copy

RegisterCommand("copy", function(source, args)
    if args[1] then
        Copy(table.concat(args, " "))
        ESX.ShowNotification("Copié dans le presse-papiers")
    end
end, false)

RegisterNetEvent("null:client:copy", function(txt)
    Copy(txt)
end)

function openUrl(url)
    SendNUIMessage({
        type = "openUrl",
        link = tostring(url)
    })
end

RegisterCommand("openUrl", function(source, args)
    if args[1] then
        openUrl(args[1])
    end
end, false)

RegisterNetEvent("null:client:openUrl", function(url)
    openUrl(url)
end)

exports('copy', Copy)
exports('Copy', Copy)
exports('CopyToClipboard', Copy)
exports('openUrl', openUrl)
exports('OpenUrl', openUrl)

null.InitPrint('^2Clipboard module loaded^7')
