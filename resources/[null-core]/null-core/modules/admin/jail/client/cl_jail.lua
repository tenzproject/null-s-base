

IS_IN_JAIL = false;
IS_UNJAIL = false;
JAIL_MESSAGE = nil;
JAIL_DURATION = 0
JAIL_STAFF = nil;
RegisterNetEvent("Null:JailPutIn")
AddEventHandler("Null:JailPutIn", function(duration, message,staffname)
	PlayerJail = true;
	JAIL_MESSAGE = message
	JAIL_DURATION = tonumber(duration)
    JAIL_STAFF = staffname
	IS_IN_JAIL = true;
	IS_UNJAIL = false;
	local Timer = 0;
    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        while true do
            if (IS_IN_JAIL) then
				--ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour voir vos informations")
                --if (IsControlJustPressed(1, 51)) then
                --    Penitentiary()
                --end
                if JAIL_DURATION == -1 then
                    pcall(function()
                        ShowInfo(
                            "Informations Jail",  
                            {
                                {left = "Raison", right = ("%s"):format(JAIL_MESSAGE == nil and "Raison inconnu" or JAIL_MESSAGE), color = "rgb(255, 255, 255)"},
                                {left = "Temps restant", right = "Permanent", color = "rgb(255, 0, 0)"},
                                --{ title = "Staff", subtitle = ("%s"):format(JAIL_STAFF == nil and "Nom du staff inconnu" or JAIL_STAFF) },
                            }
                        )
                    end)
                else 
                    time = null.fct.format.SecondsToClock(JAIL_DURATION)
                    pcall(function()
                        ShowInfo(
                            "Informations Jail",  
                            {
                                {left = "Raison", right = ("%s"):format(JAIL_MESSAGE == nil and "Raison inconnu" or JAIL_MESSAGE), color = "rgb(255, 255, 255)"},
                                {left = "Temps restant", right = ("%s"):format(time[1]..':'..time[2]..':'..time[3]), color = "rgb(255, 255, 255)"},
                                --{ title = "Staff", subtitle = ("%s"):format(JAIL_STAFF == nil and "Nom du staff inconnu" or JAIL_STAFF) },
                            }
                        )
                    end)
                end
                local player = PlayerPedId();
                local model = GetEntityModel(player)
                null.helper:Switch(model, {
                    [GetHashKey("mp_m_freemode_01")] = function()
                        if #(GetEntityCoords(player) - vector3(1723.970581, 2535.255371, 54.9172)) > 30.0 then
                            SetEntityCoords(player, 1723.970581, 2535.255371, 45.564838 - 1.0)
                        end
                    end,
                    [GetHashKey("mp_f_freemode_01")] = function()
                        if #(GetEntityCoords(player) - vector3(1723.970581, 2535.255371, 54.9172)) > 30.0 then
                            SetEntityCoords(player, 1723.970581, 2535.255371, 45.564838 - 1.0);
                        end
                    end,
                    ["default"] = function()
                        if #(GetEntityCoords(player) - vector3(1723.970581, 2535.255371, 54.9172)) > 30.0 then
                            SetEntityCoords(player, 1723.970581, 2535.255371, 45.564838 - 1.0)
                        end
                    end
                })
            end
            Citizen.Wait(0)
        end
        pcall(function()
            HideInfo()
        end)
    end))
	Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
		while true do
            if JAIL_DURATION ~= -1 then
                TriggerServerEvent('Null:JailSeconds')
            end
			Citizen.Wait(1000)
			local player = PlayerPedId();
			if #(GetEntityCoords(player) - vector3(1723.970581, 2535.255371, 54.9172)) > 20.0 then
				SetEntityCoords(player, 1723.970581, 2535.255371, 45.564838 - 1.0);
			end
            if (IS_IN_JAIL) and (JAIL_DURATION == -1) then
                JAIL_DURATION = JAIL_DURATION
				JAIL_DURATIONFORMATED = JAIL_DURATION/60
            elseif (IS_IN_JAIL) and (JAIL_DURATION) > 0 then
				JAIL_DURATION = JAIL_DURATION - 1.0
				JAIL_DURATIONFORMATED = JAIL_DURATION/60
			else
				return
			end
		end
	end))
end)

RegisterNetEvent("Null:JailPutOut")
AddEventHandler("Null:JailPutOut", function()
	TriggerServerEvent('Null:leaveJail')
	PlayerJail = false;
	IS_UNJAIL = true
	IS_IN_JAIL = false
	JAIL_DURATION = 0
	RageUI.CloseAll()
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin) 
        TriggerEvent('Null:skinchanger:loadSkin', skin)
    end)
    pcall(function()
        HideInfo()
    end)
	Citizen.Wait(1000)
	TriggerEvent('esx:restoreLoadout')
end)

function Penitentiary()
    mainMenu = RageUI.CreateMenu("", "BIENVENUE EN PRISON.")

    RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))

    while mainMenu do
        Citizen.Wait(0)
	    	RageUI.IsVisible(mainMenu, function()
	    		RageUI.Button("Temps restant", "Temps restant avant votre libération", { RightLabel = JAIL_DURATION }, true, {

	    		})
	    		RageUI.Button("Raison", (JAIL_MESSAGE == nil and "Raison inconnu" or JAIL_MESSAGE), {}, true, {

	    		})
                RageUI.Button("Nom de l'admin", nil, { RightLabel = JAIL_STAFF == nil and "Nom du staff inconnu" or JAIL_STAFF}, true, {

	    		})
				RageUI.Line()
				RageUI.Separator('Quitter = 5 minutes~s~ de plus')
	    	end)
            if not RageUI.Visible(mainMenu) then
                mainMenu = RMenu:DeleteType("mainMenu", true)
            end
       end
end

RegisterNetEvent("Null:StaffUpdateJail")
AddEventHandler("Null:StaffUpdateJail", function(table)
    JAIL_PLAYER = table;
    JAIL_PLAYER_COUNT = ESX.Table.SizeOf(table)
    while not JAIL_PLAYER do
        Citizen.Wait(1)
    end
end)