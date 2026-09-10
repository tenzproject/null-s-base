local SaveIndex = 1
local istalk = false
local IsTalking = false
local hasPayed = false
local demandeTable = {}
local hasBraquageDemande = false
local reponse = {
	[1] = nil,
	[2] = nil,
	[3] = nil,
}
local haveReponse = {
	[1] = false,
	[2] = false,
	[3] = false,
}
function resetAndClose()
	RageUI.CloseAll()
	haveReponse = {
		[1] = false,
		[2] = false,
		[3] = false,
	}
	reponse = {
		[1] = nil,
		[2] = nil,
		[3] = nil,
	}
	SaveIndex = 1
end
RegisterNetEvent('null:hacker:recevietalk', function(bool)
    istalk = bool
end)

function MenuHacker()
	if cooldown then return end
	local close = false
	TriggerServerEvent("null:lester:isswat")
	ESX.TriggerServerCallback('null:hacker:GetDemande', function(hasDemande)
		hasBraquageDemande = hasDemande
	end)
	ESX.TriggerServerCallback('null:lester:getnbrpolice', function(nbr)
		if nbr < Config.Robbery.RequiredPolice then
			ESX.ShowNotification("Je suis pas disponible.")
			RageUI.CloseAll()
		end
	end)
	TriggerServerEvent("null:hacker:istalk", true)
	if istalk then 
		ESX.ShowNotification("Quelqu'un parle déjà avec le hacker.")
		return
	 end
	IsTalking = true
	TriggerServerEvent("null:hacker:istalk", false, true)
	local vente = RageUI.CreateMenu("", "Action(s) disponible")
	local braquagelist = RageUI.CreateSubMenu(vente,"", "Action(s) disponible")
	RageUI.Visible(vente, not RageUI.Visible(vente))

	while vente do
		if istalk then RageUI.CloseAll() end
		Citizen.Wait(0)
			RageUI.IsVisible(vente, function()
				if LesterisSwat then
					return RageUI.Separator("Alors Casse toi, je veux pas avoir d'emerde.")
				end
				if hasBraquageDemande then
					return RageUI.Separator("J'ai pas encore trouver, je t'enverai un message.")
				end
				if not haveReponse[1] then
					RageUI.Separator("De quelle Entreprise voulez-vous des informations ? ")
					RageUI.Separator("")
					RageUI.List("Votre réponse : ", {"Brinks"}, SaveIndex, "Entrée pour confirmer votre réponse", {}, true, {
						onListChange = function(Index)
							SaveIndex = Index
						end,
						onSelected = function(Index)
							reponse[1] = SaveIndex
							haveReponse[1] = true
							SaveIndex = 1
						end,
					})
				else
					if not haveReponse[2] then
						RageUI.Separator("Êtes-vous sur ? Cela previendra la Police. ")
						RageUI.Separator("")
						RageUI.List("Votre réponse : ", {"Oui", "Non"}, SaveIndex, "Entrée pour confirmer votre réponse", {}, true, {
							onListChange = function(Index)
								SaveIndex = Index
							end,
							onSelected = function(Index)
								if SaveIndex == 2 then resetAndClose() end
								reponse[2] = SaveIndex
								haveReponse[2] = true
								SaveIndex = 1
							end,
						})
					else
						if reponse[1] == 1 then
							RageUI.Separator("Voici mon prix : "..ESX.Math.GroupDigits(Config.Robbery.HackerInfo["Brinks"]).."$, a prendre ou a laisser")
							RageUI.Separator("")
							RageUI.List("Votre réponse : ", {"Oui", "Non"}, SaveIndex, "Entrée pour confirmer votre réponse", {}, true, {
								onListChange = function(Index)
									SaveIndex = Index
								end,
								onSelected = function(Index)
									if SaveIndex == 2 then resetAndClose() end
									reponse[3] = SaveIndex
									haveReponse[3] = true
									SaveIndex = 1
									ESX.TriggerServerCallback('null:hacker:payinfo', function(good)
										if good then
											ESX.ShowNotification("Je te recontacterai quand j’aurai des informations (10-30 minutes).")
											resetAndClose()
										else
											ESX.ShowNotification("Vous n'avez pas asser d'argent sur vous.")
											resetAndClose()
										end
									end, "Brinks")
								end,
							})
						elseif reponse[1] == 2 then
							RageUI.Separator("Voici mon prix : "..ESX.Math.GroupDigits(Config.Robbery.HackerInfo["ROGER"]).."$, a prendre ou a laisser")
							RageUI.Separator("")
							RageUI.List("Votre réponse : ", {"Oui", "Non"}, SaveIndex, "Entrée pour confirmer votre réponse", {}, true, {
								onListChange = function(Index)
									SaveIndex = Index
								end,
								onSelected = function(Index)
									if SaveIndex == 2 then resetAndClose() end
									reponse[3] = SaveIndex
									haveReponse[3] = true
									SaveIndex = 1
									ESX.TriggerServerCallback('null:hacker:payinfo', function(good)
										if good then
											ESX.ShowNotification("Je te recontacterai quand j’aurai des informations (10-30 minutes).")
											resetAndClose()
										else
											ESX.ShowNotification("Vous n'avez pas asser d'argent sur vous.")
											resetAndClose()
										end
									end, "ROGER")
								end,
							})
						end
					end
				end
			end)
		if not RageUI.Visible(vente) and not RageUI.Visible(braquagelist) then
			vente = RMenu:DeleteType('vente', true)
			if IsTalking then
				TriggerServerEvent("null:hacker:istalk", false, false)
			end
			 null.fct.cooldown(5000)
		end
	end
end


Citizen.CreateThread(function ()
    while null.data.markers.loaded ~= true do Wait(100) end
    null.data.markers.register("hackerzone", {
        Position = Config.Robbery.HackerPos2,
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = nil,
        Action = function()
            MenuHacker()
        end
    })
end)