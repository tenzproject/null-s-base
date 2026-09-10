-- Write 100% by Null
-- .gg/null 

local tempoLoaded = false
SaveData.owned_vehicles = {}
SaveData.tempo_vehicles = {}

Citizen.CreateThread(function()
    local ActualDate = os.date('%Y-%m-%d %H:%M:%S')
    local ActualTime = {
        years=tonumber(ActualDate:sub(1,4)), 
        mounts=tonumber(ActualDate:sub(6,7)),  
        days=tonumber(ActualDate:sub(9,10)),  
        hours=tonumber(ActualDate:sub(12,13)),  
        minutes=tonumber(ActualDate:sub(15,16)),  
        secondes=tonumber(ActualDate:sub(18,19)),  
    }
    local function DeleteTempoVeh(plate)
        print("^7[^5Null^7] Delete temporaly vehicle with plate = "..plate)
        SaveData.tempo_vehicles[plate] = nil
		SaveData.json["owned_vehicles"][string.upper(plate)] = nil
    end

    SaveData.owned_vehicles = SaveData.json["owned_vehicles"]
    for k,v in pairs(SaveData.owned_vehicles) do
        if v.datetoremove ~= nil and v.datetoremove ~= 0 then
            v.datetoremove2 = v.datetoremove / 1000
            v.realdate = os.date('%Y-%m-%d %H:%M:%S', v.datetoremove2)
            v.time = {
                years=tonumber(v.realdate:sub(1,4)), 
                mounts=tonumber(v.realdate:sub(6,7)),  
                days=tonumber(v.realdate:sub(9,10)),  
                hours=tonumber(v.realdate:sub(12,13)),  
                minutes=tonumber(v.realdate:sub(15,16)),  
                secondes=tonumber(v.realdate:sub(18,19)),  
            }
            SaveData.tempo_vehicles[v.plate] = v
            local difference = {
                years = v.time.years - ActualTime.years,
                mounts = v.time.mounts - ActualTime.mounts,
                days = v.time.days - ActualTime.days,
                hours = v.time.hours - ActualTime.hours,
                minutes = v.time.minutes - ActualTime.minutes,
                secondes = v.time.secondes - ActualTime.secondes,
            }
            if difference.years < 0 then DeleteTempoVeh(v.plate) return end
            if difference.mounts < 0 then DeleteTempoVeh(v.plate) return end
            if difference.days < 0 then DeleteTempoVeh(v.plate) return end
            if difference.days == 0 then
                if difference.hours < 0 then DeleteTempoVeh(v.plate) return end
                if difference.hours == 0 then
                    if difference.minutes < 0 then DeleteTempoVeh(v.plate) return end
                    if difference.minutes == 0 then
                        if difference.secondes < 0 then DeleteTempoVeh(v.plate) return end
                    end
                end
            end
        end
    end
    tempoLoaded = true
end)


RegisterNetEvent('null:updateownedveh:totempo', function(plate, newtime)
    SaveData.json["owned_vehicles"][string.upper(plate)].datetoremove = newtime+0.0
end)