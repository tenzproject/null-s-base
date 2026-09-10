local ActualDate = {
    dayName = os.date("%A"),
    mountName = os.date("%B"),
    mount = tonumber(os.date("%m")),
    day = tonumber(os.date("%d")),
    minutes = tonumber(os.date("%M")),
    date = os.date("%x"),
    time = os.date("%X"),
    years = tonumber(os.date("%Y")),
}

local payedMensuelIdUnique = {}
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    Wait(30*1000)
    while true do 
        local isPayDate = false
        for k,v in pairs(Config.PayAtDays) do 
            if v == day then
                isPayDate = true
            end
        end
        if isPayDate then
            for k,v in pairs(ESX.Players) do 
                if payedMensuelIdUnique[v.idunique] == nil then 
                    if v.job and v.job.name ~= "unemployed" and v.job.name ~= nil then
                        if ESX.Jobs[v.job.name] ~= nil and ESX.Jobs[v.job.name].grades and ESX.Jobs[v.job.name].grades[v.job.grade] then
                            if ESX.Jobs[v.job.name].grades[v.job.grade].mensuelpay ~= 0 then
                                payedMensuelIdUnique[v.idunique] = true
                                local salary = ESX.Jobs[v.job.name].grades[v.job.grade].mensuelpay
                                v.addAccountMoney('bank', salary, {title = 'Salaire mensuel', description = 'Jour de paie de votre métier : '..v.job.label, category = 'salary'})
                                local newamount, toreduc = RemoveTaxesOfAmount("salaire", salary, true, v.job.label, v.job.name)
                                SocietyCache[v.job.name].data["accounts"].cash = SocietyCache[v.job.name].data["accounts"].cash - (salary + toreduc)
                                SocietySaved[v.job.name] = SocietyCache[v.job.name]

                                TriggerClientEvent("esx:showNotification",v.source, "Jour de paye : ~g~+$"..math.floor(salary).." ~s~")
                            end
                        end
                    end
                end
            end
        end
        Wait(60*60*1000)
    end
end))