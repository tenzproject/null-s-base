RegisterNetEvent("Null:suit:equip", function(equip, suitname)
    if equip == "equip" then
        Citizen.CreateThread(function()
            PlayToggleEmote({Dict = "clothingtie", Anim = "try_tie_positive_a", Move = 51, Dur = 2100})
            Citizen.Wait(2100)
            ClearPedTasks(PlayerPedId())
            PlayerState.suit = suitname
            CreateSuitThread()
        end)
    elseif equip == "unequip" then
        Citizen.CreateThread(function()
            PlayToggleEmote({Dict = "clothingtie", Anim = "try_tie_positive_a", Move = 51, Dur = 2100})
            Citizen.Wait(2100)
            ClearPedTasks(PlayerPedId())
        end)
        PlayerState.suit = nil
    end
end)

local CreateThread = false
function CreateSuitThread()
    if CreateThread then return end
    CreateThread = true
    Citizen.CreateThread(function()
        while true do
            if PlayerState.suit == nil then break end
            TriggerEvent('Null:skinchanger:getSkin', function(skin)
                if skin.sex == 0 then
                    TriggerEvent('Null:skinchanger:loadClothes', skin, Config.Suits.allSuits[PlayerState.suit].skins)
                else
                    TriggerEvent('Null:skinchanger:loadClothes', skin, Config.Suits.allSuits[PlayerState.suit].skins2)
                end
            end)
            Wait(1000)
        end
        CreateThread = false
    end)
end