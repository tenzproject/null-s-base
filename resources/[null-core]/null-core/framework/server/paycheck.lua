-- Désactiver pour un systeme plus réaliste
-- Ancienne config 
--[[
Config.EnableSocietyPayouts = true 
Config.PaycheckInterval = 30 * 60 * 1000
]]


-- ESX.StartPayCheck = function()
-- 	function payCheck()
-- 		attempts = false
-- 		local xPlayers = ESX.GetPlayers()

-- 		for i = 1, #xPlayers, 1 do
-- 			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

-- 			if xPlayer then
-- 				local salary = xPlayer.job.grade_salary
-- 				if salary > 0 then

-- 					stateVip = nil
-- 					local stateVip = exports["null-core"]:GetVIP(xPlayer.identifier)
					
-- 					while stateVip == nil do
-- 						Wait(150)
-- 					end
					
-- 					attempts = true

-- 					if stateVip then
-- 						multiplicator = 2
-- 						text = "(Premium)"
-- 						attempts = false
-- 					else
-- 						multiplicator = 1
-- 						text = ""
-- 						attempts = false
-- 					end

-- 					while attempts do
-- 						Wait(100)
-- 					end

-- 					returnText = text

-- 					if xPlayer.job.grade_name == 'unemployed' then
-- 						xPlayer.addAccountMoney('bank', salary*multiplicator)
-- 						TriggerClientEvent("esx:showNotification",xPlayer.source,"Jour de paye : ~g~+$"..math.floor(salary*multiplicator).." ~s~"..returnText)
-- 					elseif Config.EnableSocietyPayouts then
-- 						local society = "society_"..xPlayer.job.name
-- 						if society ~= nil then
-- 							xPlayer.addAccountMoney('bank', salary*multiplicator)
-- 							local newamount, toreduc = RemoveTaxesOfAmount("salaire", salary, true, xPlayer.job.label, xPlayer.job.name)
-- 							SocietyCache[xPlayer.job.name].data["accounts"].cash = SocietyCache[xPlayer.job.name].data["accounts"].cash - (salary + toreduc)
-- 							TriggerClientEvent("esx:showNotification",xPlayer.source,"Jour de paye : ~g~+$"..math.floor(salary*multiplicator).." ~s~"..returnText)
-- 						else
-- 							xPlayer.addAccountMoney('bank', salary*multiplicator)
-- 							TriggerClientEvent("esx:showNotification",xPlayer.source,"Jour de paye : ~g~+$"..math.floor(salary*multiplicator).." ~s~"..returnText)
-- 						end
-- 					else
-- 						xPlayer.addAccountMoney('bank', salary*multiplicator)
-- 						TriggerClientEvent("esx:showNotification",xPlayer.source,"Jour de paye : ~g~+$"..math.floor(salary*multiplicator).." ~s~"..returnText)
-- 					end
-- 				end
-- 			end
-- 		end

-- 		SetTimeout(Config.PaycheckInterval, payCheck)
-- 	end

-- 	SetTimeout(Config.PaycheckInterval, payCheck)
-- end

-- local SalaryPlayers = {}

-- RegisterNetEvent('Zgegframework:Salary')
-- AddEventHandler('Zgegframework:Salary', function()
--     local xPlayer = ESX.Players[tonumber(source)]
--     if not SalaryPlayers[xPlayer.identifier] then 
--         local Delai = (28 * 60)

--         if Delai < os.time() then
--             SalaryPlayers[xPlayer.identifier] = os.time() + Delai
--         end
-- 		local AmountSalary = exports["null-core"]:GetVIP(xPlayer.identifier) == true and xPlayer.job.grade_salary*2 or xPlayer.job.grade_salary
-- 		xPlayer.addAccountMoney('bank', AmountSalary)
-- 		xPlayer.showNotification('Aide de l\'état (+~g~'..AmountSalary..'$~s~)')
--     else
--         if SalaryPlayers[xPlayer.identifier] < os.time() then 
--             local Delai = (28 * 60)

--             if Delai < os.time() then
--                 SalaryPlayers[xPlayer.identifier] = os.time() + Delai
--             end
-- 			local AmountSalary = exports["null-core"]:GetVIP(xPlayer.identifier) == true and xPlayer.job.grade_salary*2 or xPlayer.job.grade_salary
-- 			xPlayer.addAccountMoney('bank', AmountSalary)
-- 			xPlayer.showNotification('Aide de l\'état (+~g~'..AmountSalary..'$~s~)')
--         else
--             ExecuteCommand("ban " .. source .. " 0 Tentative de triche framework (7)")
--         end
--     end
-- end)