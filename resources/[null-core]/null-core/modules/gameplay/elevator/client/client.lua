AscenseurList = {}
ascenseurload = false

local proche = false
local nearascenseur = nil
local inMenu = false

RegisterNetEvent("null:ascenseur:recevie")
AddEventHandler("null:ascenseur:recevie", function(tablelist)
    null.fct.waitPlayerLoaded()
    while inMenu do
        Wait(100)
    end
    AscenseurList = tablelist
    ascenseurload = true
    proche = false
    nearascenseur = nil
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    while ascenseurload == false do
        Wait(100)
    end
    
    while true do
        for w,y in pairs(AscenseurList) do
            local Coords1 = GetEntityCoords(PlayerPedId())
            local dstCheck1 = GetDistanceBetweenCoords(Coords1.x,Coords1.y,Coords1.z, y.pos.x,y.pos.y,y.pos.z, true)
            if dstCheck1 < 200 then
                proche = true
                for k,v in pairs(y.data) do
                    local Coords = GetEntityCoords(PlayerPedId())
                    local dstCheck = GetDistanceBetweenCoords(Coords.x,Coords.y,Coords.z, v.position.x,v.position.y,v.position.z, true)
                    if dstCheck < 20 then
                        DrawMarker(25, v.position.x, v.position.y, v.position.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false) 
                    end
                    if dstCheck < 2 then
                        null.fct.draw.Text3DBar(v.position.x, v.position.y, v.position.z, 'Appuyer sur [~y~E~s~] pour ouvrir l\'ascenseur')
                        if IsControlJustPressed(0, 38) then
                            MenuAscenseur(k,y.name)
                        end
                    end
                end
            end
        end

        if proche then
            Wait(1)
        else
            Wait(5000)
        end
    end
end))

function MenuAscenseur(etage,id)
    inMenu = true
    local actuetage = etage
    local actuid = id
    local menu = RageUI.CreateMenu("", "Action(s) disponible")
    RageUI.Visible(menu, not RageUI.Visible(menu))
	while menu do
		Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            local formatData = nil
            for w,y in pairs(AscenseurList) do
                if y.name == actuid then
                    formatData = y.data
                    break
                end
            end
            if formatData == nil then return end
            for k,v in ipairs(formatData) do
                if k == actuetage then
                    RageUI.Button(v.label, nil, {RightLabel="Vous êtes ici !"}, true, {})
                else
                    RageUI.Button(v.label, nil, {}, true, {
                        onSelected = function()
                            actuetage = k
                            SetEntityCoords(PlayerPedId(), v.position.x, v.position.y, v.position.z)
                        end
                    })
                end
            end
        end)
        if not RageUI.Visible(menu) then
            inMenu = false
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent("null:initAscenseur")
end)