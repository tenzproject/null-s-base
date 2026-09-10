local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

RegisterNetEvent("Kayce:AddVehToClient")
AddEventHandler("Kayce:AddVehToClient", function(id, name, newplate, type, boutique, vhForJob, plateAutomatic)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xLeJ = nil
    if not vhForJob then
        xLeJ = ESX.GetPlayerFromId(id)
    else
        xLeJ = 666
    end
    local typeByName = {
        ["car"] = "véhicule",
        ["aircraft"] = "avion",
        ["boat"] = "Bateau"
    }
    if boutique == 1 then boutique = true elseif boutique == 0 then boutique = false end
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if xLeJ ~= nil then
            if vhForJob then
                if plateAutomatic then
                    newplate = null.fct.format.randomPlateText()
                end
                SaveData.json["owned_vehicles"][string.upper(newplate)] = {
                    owner = id,
                    model = name,
                    plate = string.upper(newplate),
                    vehicle = { model = name, plate = newplate },
                    label = name,
                    coffre = {},
                    type = type,
                    state = true,
                    boutique = boutique,
                    garage = true,
                }
                --xLeJ.showNotification("Félicitation, il semblerait que "..ESX.Config("serverColor")..xPlayer.name.." ~s~vous est ajouté un "..ESX.Config("serverColor")..typeByName[type].."~s~ du nom de : "..ESX.Config("serverColor")..name)
                xPlayer.showNotification("Vous avez envoyé a "..ESX.Config("serverColor")..id.."~s~ une "..ESX.Config("serverColor")..typeByName[type].."~s~ du nom de : "..ESX.Config("serverColor")..name)
                webhook("[Logs] "..xPlayer.name..": a ajouté le véhicule (model:"..name..",plate:"..newplate..",type:"..type..") à ("..id..") !", 15277667)
            else
                if plateAutomatic then
                    newplate = null.fct.format.randomPlateText()
                end
                SaveData.json["owned_vehicles"][string.upper(newplate)] = {
                    owner = xLeJ.identifier,
                    model = name,
                    plate = string.upper(newplate),
                    vehicle = { model = name, plate = newplate },
                    label = name,
                    coffre = {},
                    type = type,
                    state = true,
                    boutique = boutique,
                    garage = true,
                }
                xLeJ.showNotification("Félicitation, il semblerait que "..ESX.Config("serverColor")..xPlayer.name.." ~s~vous est ajouté un "..ESX.Config("serverColor")..typeByName[type].."~s~ du nom de : "..ESX.Config("serverColor")..name)
                xPlayer.showNotification("Vous avez envoyé a "..ESX.Config("serverColor")..xLeJ.name.."~s~ une "..ESX.Config("serverColor")..typeByName[type].."~s~ du nom de : "..ESX.Config("serverColor")..name)
                webhook("[Logs] "..xPlayer.name..": a ajouté le véhicule (model:"..name..",plate:"..newplate..",type:"..type..") à ("..xLeJ.name..") !", 15277667) 
            end
        else
            xPlayer.showNotification("Une erreur est survenu lors de l'ajout du véhicule (CODE:ID) !")
        end
    else
        DropPlayer(source, 'Tentative de cheat/bug')
    end
end)

RegisterCommand("garage:clearGarage", function(source, args, rawCommand)
    if source == 0 then
        return print("Impossible de faire ceci par le biais de la console !")
    end
    local selectedPlayer = args[1]
    local xPlayer = ESX.GetPlayerFromId(source)
    local xSelected = ESX.GetPlayerFromId(selectedPlayer)
    if (selectedPlayer) then
        if (xSelected) then
            if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
                for k,v in pairs(SaveData.json["owned_vehicles"]) do
                    if v.owner == xSelected.identifier then
                        SaveData.json["owned_vehicles"][k] = nil
                    end
                end
                xPlayer.showNotification("Action réussi, tous les véhicule de ~g~"..xSelected.name.."~s~ on été supprimé !")
                webhook("[Staff] "..xPlayer.name..": a supprimer tout les véhicules du garage de ("..xSelected.name..") !", 15277667)
            else
                xPlayer.showNotification("Vous n'avez pas les permissions nécessaire !")
            end
        else
            xPlayer.showNotification("Une erreur est ~r~survenue~s~ il semblerait que l'utilisateur seléctionné n'est pas ~r~valide~s~ ou ~r~inexistante")
        end
    else
        xPlayer.showNotification("Arguments[1] undefined !")
    end
end, false)

RegisterCommand("garage:deleteVehicle", function(source, args, rawCommand)
    if source == 0 then
        return print("Impossible de faire ceci par le biais de la console !")
    end
    local selectedPlate = args[1]
    local xPlayer = ESX.GetPlayerFromId(source)
    local xSelected = ESX.GetPlayerFromId(selectedPlayer)
    if (selectedPlate) then
        if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
            for k,v in pairs(SaveData.json["owned_vehicles"]) do
                if v.plate == selectedPlate then
                    SaveData.json["owned_vehicles"][k] = nil
                end
            end
            xPlayer.showNotification("Action réussi, tous le véhicule sous la plaque ~g~"..selectedPlate.."~s~ a été supprimé de l'utilisateur détenteur !")
            webhook("[Staff] "..xPlayer.name..": a supprimer le véhicule avec la plaque ("..selectedPlate..") du garage de ("..xSelected.name..") !", 15277667)
        else
             xPlayer.showNotification("Vous n'avez pas les permissions nécessaire !")
        end
    else
        xPlayer.showNotification("Arguments[1] undefined !")
    end
end, false)

function webhook(message, color)
    date_local1 = os.date('%H', os.time())
    local date_local = date_local1 + 2
    local date_lolo = os.date('%M', os.time())
    local DiscordWebHook = "https://discord.com/api/webhooks/1205283567178096670/yF6tYXc145BcBJgXNi-VYt4oEb9qNnwx0f9ZNXfs1Da6adjeLGaEOEhoaUSPm96hBLsC"
    local embeds = {
        {
          ["title"] = "Garage",
          ["description"] = "```"..message.."```",
          ["type"] = "rich",
          ["color"] = color,
          ["thumbnail"] = {
            ["url"] = "",
          },
          ["footer"] =  {
              ["text"] = date_local..":"..date_lolo,
          },
        }
    }

    if message == nil or message == '' then return FALSE end
    PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = "Garage",embeds = embeds}), { ['Content-Type'] = 'application/json' })
end 