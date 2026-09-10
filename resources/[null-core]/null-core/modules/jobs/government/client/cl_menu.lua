-- MenuFouille
local Items = {}      
local Armes = {}    
local ArgentSale = {} 
local PlayerData = {}


grade = {}
local open = false 
local mainMenu = RageUI.CreateMenu('', 'interaction')
local subMenu = RageUI.CreateSubMenu(mainMenu,'', 'interaction')
local subMenu1 = RageUI.CreateSubMenu(mainMenu,'', 'interaction')
local subMenu2 = RageUI.CreateSubMenu(mainMenu,'', 'interaction')
mainMenu.Display.Header = true 
mainMenu.Closed = function()
  open = false
end


function OpenMenuGouv()
	
	if not servicegouv then 
		ESX.ShowNotification("Vous devez avoir votre service.")
		return
	end
	if open then 
		open = false
		RageUI.Visible(mainMenu, false)
		return
	else
		open = true 
		RageUI.Visible(mainMenu, true)
		CreateThread(function()
		while open do 
		   RageUI.IsVisible(mainMenu,function() 
			if status == nil then status = false end
			RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                onChecked = function()
                    status = true 
                    TriggerServerEvent("vsociety:updateSocietyStatus", "gouvernement", true)
                end,
                onUnChecked = function()
                    status = false 
                    TriggerServerEvent("vsociety:updateSocietyStatus", "gouvernement", false)
                end
            })
			RageUI.Button("Annonces", nil, {RightLabel = ""}, true , {
				onSelected = function()
				end
			}, subMenu1)
			RageUI.Button("Gestion Citoyen", nil, {RightLabel = ""}, true , {
				onSelected = function()
				end
			}, subMenu2)
			RageUI.Button("Montrer son badge", nil, {}, true, {
				onSelected = function()
					ShowJobBadge(ESX.PlayerData.job.name)
				end
			})
		end)

        RageUI.IsVisible(subMenu2,function()
            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            if closestPlayer ~= -1 and closestDistance < 3 then
				RageUI.Button("Fouiller", nil, {}, true, {
					onSelected = function() 
						if closestDistance <= 5.0 then 
							RageUI.CloseAll()
							ESX.TriggerServerCallback('null:fouiller', function(data, id)
								if data then
									local inventory = data
									inventory.weight = 0
									inventory.id = GetPlayerServerId(closestPlayer)
									inventory.maxWeight = 1000
									inventory.type = "PLAYER"
									TriggerEvent("inventory:openSearch", inventory, false, data.cash or 0,data.dirtycash or 0)
								end
							end, GetPlayerServerId(closestPlayer))
						end
					end,
				})
            else
                RageUI.Button("~r~Personne autour de toi !", nil, {}, false, {})
            end

			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			RageUI.Button("Menotter/démenotter", nil, {}, true, {
				onSelected = function() 
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
   
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification('Aucun joueur proche', '~r~Erreur')
					else
						TriggerServerEvent('gouv:handcuff', GetPlayerServerId(closestPlayer))
					end
				end
			})

			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			RageUI.Button("Escorter", nil, {}, true, {
				onSelected = function() 
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification('Aucun joueur proche', '~r~Erreur')
					else
						TriggerServerEvent('gouv:drag', GetPlayerServerId(closestPlayer))
					end
				end
			})



			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			RageUI.Button("Mettre dans un véhicule", nil, {}, true, {
				onSelected = function() 
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification('Aucun joueur proche', '~r~Erreur')
					else
						TriggerServerEvent('gouv:putInVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			})

			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
			RageUI.Button("Sortir du véhicule", nil, {}, true, {
				onSelected = function() 
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification('Aucun joueur proche', '~r~Erreur')
					else
						TriggerServerEvent('gouv:OutVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			})
		end)

		RageUI.IsVisible(subMenu1,function()
			--[[RageUI.Button("Annonce Ouvertures", nil, {}, true , {
				onSelected = function()
					local sur = null.fct.confirm("Êtes-vous sur ?")
					if not sur then return end
					TriggerServerEvent('Null:gouv:annonce', "ouvre")
				end
			})

			RageUI.Button("Annonce Fermetures", nil, {}, true , {
				onSelected = function()
					local sur = null.fct.confirm("Êtes-vous sur ?")
					if not sur then return end
					TriggerServerEvent('Null:gouv:annonce', "ferme")
				end
			})]]

			RageUI.Button("Annonce Recrutement", nil, {}, true , {
				onSelected = function()
					local sur = null.fct.confirm("Êtes-vous sur ?")
					if not sur then return end
					TriggerServerEvent('Null:gouv:annonce', "recrutement")
				end
			})
		end)
    	Wait(0)
    end
    end)
    end
end

local function notNilString(value)
	if value == nil then
		return ""
	else
		return value
	end
end

local LicensesList = {}
for k,v in pairs(Config.Licenses.Listes) do 
	if v.indexmenu and v.card then
		LicensesList[v.indexmenu] = v
		LicensesList[v.indexmenu].name = k
	end
end

function MenuCitoyenGouvernement()
    local servpopo = RageUI.CreateMenu("Gouvernement", "Que puis-je faire pour vous ?")
    local entreprise = RageUI.CreateSubMenu(servpopo, "Gouvernement", "Gouvernement")
	local plainte = RageUI.CreateSubMenu(entreprise, "Gouvernement", "Gouvernement")
    RageUI.Visible(servpopo, not RageUI.Visible(servpopo))
    while servpopo do
        Citizen.Wait(0)
            RageUI.IsVisible(servpopo, function()
				for k,v in ipairs(LicensesList) do 
					if PlayerState.myLicense[v.name] or v.name == "identity_card" then
						RageUI.Button(v.description, nil, {RightLabel = "~y~"..v.price.."$~s~"}, true, {
							onSelected = function()
								TriggerServerEvent("null:buy:newlicense", v.name)
							end
						})
					end
				end
				RageUI.Line()
				RageUI.Button("Appeler un agent du Gouvernement ", nil, {}, true, {
					onSelected = function()
						TriggerServerEvent("null:sendcall")
						ESX.ShowNotification("~b~Votre appel à bien été pris en compte")
					end
				})

				RageUI.Button("Gestion Entreprise", nil, {}, true, {}, entreprise)    
		    end, function()
			end)

            RageUI.IsVisible(entreprise, function()
				RageUI.Button("A quoi sert une Entreprise ?", nil, {RightLabel = ESX.Config("serverColor")..'Voir'},true, {
					onActive = function()
						RageUI.Info("Information Entreprises", {
							"Une entreprise peut être créée par le gouvernement",
							"dans le but de générer des revenus et de créer des ",
							"emplois. Elle contribue à la croissance économique," ,
							"stimuler l'innovation et améliorer les infrastructures.",
							"Ces initiatives peuvent soutenir l'économie locale,",
							"renforçant ainsi la stabilité sociale et financière.",
						}, {
							"",
							"",
							"",
							"",
							"",
							"",
						})
					end
				})

				RageUI.Button("Effectuer une demande de création d'Entreprise", nil, {},true, {}, plainte) 
				-- RageUI.Line()
				-- RageUI.Button("Ouvrir une entreprise Superette", nil, {RightLabel = "Prix : "..IZZY.Price.Min.."-"..IZZY.Price.Max.."$"},false, {
				-- 	onSelected = function()
				-- 		RageUI.CloseAll()
				-- 		--OpenBuyShop()
				-- 	end
				-- }) 
            end, function()
			end)

			RageUI.IsVisible(plainte, function()

				RageUI.Button("Votre Nom : "..notNilString(LastName), nil, {RightLabel = ""},true, {
					onSelected = function()   
		                LastName = null.fct.input("Votre Nom :")
					end
				})

				RageUI.Button("Votre Prénom : "..notNilString(FirstName), nil, {RightLabel = ""},true, {
					onSelected = function()   
		                FirstName = null.fct.input("Votre Prénom :")
					end
				})   

				RageUI.Button("Votre Numéro de téléphone~s~ : "..notNilString(tel), nil, {RightLabel = ""},true, {
					onSelected = function()   
		                tel = null.fct.input("Votre Numéro de téléphone :")
					end
				})   

				RageUI.Button("Pourquoi voulez vous une entreprise", Subject, {RightLabel = ""},true, {
					onSelected = function()    
		                Subject = null.fct.input("Pourquoi voulez vous une Entreprise ?")
					end
				})

				RageUI.Button("But de votre entreprise", Desc, {RightLabel = ""},true, {
					onSelected = function()   
		                Desc = null.fct.input("But de votre Entreprise")
					end
				})  

				if LastName ~= nil and LastName ~= "" and FirstName ~= nil and FirstName ~= "" and tel ~= nil and tel ~= "" and Subject ~= nil and Subject ~= "" and Desc ~= nil and Desc ~= "" then
					cansend = true
				end

		        RageUI.Button("Envoyer", nil, {Color = {BackgroundColor = {0, 150, 0, 200}}}, cansend, {
					onSelected = function()  
		                TriggerServerEvent("gouv:sendentreprise", LastName, FirstName, tel ,Subject, Desc)
		                --RageUI.Popup({message = "Votre demande à bien été pris en compte"})
		            end
				})

			end, function()
			end)
	
        if not RageUI.Visible(servpopo) and not RageUI.Visible(entreprise) and not RageUI.Visible(plainte) then
            servpopo = RMenu:DeleteType("servpopo", true)
        end
    end
end