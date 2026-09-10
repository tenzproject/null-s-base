null.data.world.props = {
    propsSpawned = {},
}

local previewPropMenu = nil
local isForStaff = nil
local SelectedModel = nil
local previewProp = nil

local function deletePreviewProp()
    if not DoesEntityExist(previewProp) then return end
    DeleteEntity(previewProp)
    previewProp = nil
end

local function deletePreviewModel()
    if not DoesEntityExist(previewModel) then return end
    DeleteEntity(previewModel)
    previewProp = nil
end

CreateThread(function()
    null.fct.waitPlayerLoaded()
    local props = {}
    for k,v in pairs(WorldProps.list) do
        props[k] ={
            name = v.label,
            item = v.name,
            image = "carton.png",
            price = v.price,
            type = "props"
        }
    end
end)

local function activePreviewMode(hash, name, category, id, name2)
    local propName = name
    local propCategory = category

    Wait(200)

    Citizen.CreateThread(function()
        local coords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())
        local objectCoords = (coords + forward * 3.0)

        ESX.Streaming.RequestModel(hash)
        previewProp = CreateObjectNoOffset(hash, objectCoords.x, objectCoords.y, objectCoords.z, false, false, false)
        SetModelAsNoLongerNeeded(hash)

        SetEntityCollision(previewProp, false, false)
        SetCanClimbOnEntity(previewProp, false)
        FreezeEntityPosition(previewProp, true)

        local relativeCoords = vector3(0.0, 0.0, 0.0)

        useGizmo(previewProp)

        RageUI.CloseAll()

        local placeEntityProperlyOnTheGround = true
        local inPreviewMode = true

        while inPreviewMode do
            HideHudComponentThisFrame(19)
            HideHudComponentThisFrame(20)

            DrawScaleformMovieFullscreen(previewInstructions, 255, 255, 255, 255, 0)

            coords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())

            local newObjectCoords = GetEntityCoords(previewProp)

            SetEntityCoords(previewProp, newObjectCoords.x, newObjectCoords.y, newObjectCoords.z)

            if placeEntityProperlyOnTheGround and not isForStaff then
                PlaceObjectOnGroundProperly(previewProp)
            end

            if IsControlJustPressed(0, 215) then -- Enter
                inPreviewMode = false


                objectCoords = GetEntityCoords(previewProp)
                objectRotation = GetEntityRotation(previewProp)
                
                TriggerServerEvent('Null:props:place', name2, name, id, objectCoords, objectRotation, isForStaff)

                deletePreviewProp()
            end

            if IsControlJustPressed(0, 177) then -- BACKSPACE : Cancel
                deletePreviewProp()
                inPreviewMode = false
                return
            end

            SetEntityRotation(previewProp, objectRotation)
            Citizen.Wait(0)
        end
    end)
end

local acutalprops = nil
local function PreviewModel(hash, name)
    local propName = name

    if acutalprops == hash then return end
    
    if acutalprops ~= nil then
        deletePreviewModel()
    end
    acutalprops = hash
    
    local coords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())
    
    local objectCoords = coords + forward * 1.5

    ESX.Streaming.RequestModel(hash)
    previewModel = CreateObjectNoOffset(hash, objectCoords.x, objectCoords.y, objectCoords.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)

    objectCoords = GetEntityCoords(previewModel) 
    local objectRotation = GetEntityRotation(previewModel)

    SetEntityAlpha(previewModel, 150, false)  
    SetEntityCollision(previewModel, false, false) 
    SetCanClimbOnEntity(previewModel, false) 
    FreezeEntityPosition(previewModel, true) 

    local relativeCoords = GetOffsetFromEntityGivenWorldCoords(PlayerPedId(), objectCoords.x, objectCoords.y, objectCoords.z)
    relativeCoords = vector3(relativeCoords.x, relativeCoords.y, relativeCoords.z)

end

RegisterNetEvent('Null:props:place', function(data)
    activePreviewMode(data.name, data.label, 'test', data.id, data.name)
end)

RegisterNetEvent('null:world:propsaddTable', function(iid, table)
    null.data.world.props.propsSpawned[iid] = table
end)

RegisterNetEvent('null:world:propsremoveTable', function(iid)
    local entity = null.data.world.props.propsSpawned[iid].entity
    null.data.world.props.propsSpawned[iid] = nil

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    local loopWait = 2000
    null.fct.waitPlayerLoaded()
    Wait(5000)
    TriggerServerEvent('null:world:propsserver:loadProps')
    Wait(5000)

    while json.encode(worldProps) == '[]' do
        Wait(100)
    end

    while true do
        loopWait = 2000
        for k,v in pairs(null.data.world.props.propsSpawned) do
            NullCoord = GetEntityCoords(PlayerPedId())
            if v == nil then goto continue end
            if #(NullCoord - vector3(v.position.x, v.position.y, v.position.z)) > 50.0 then
                if v.entity ~= nil and DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                    v.entity = nil
                    v.target = nil
                end
                goto continue 
            end
            if v.instance ~= nil and PlayerState.bucket ~= v.instance then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end
                goto continue 
            end

            if v.entity == nil or v.entity == 0 or (not DoesEntityExist(v.entity) and v.entity ~= "in_spawning") then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end

                v.entity = "in_spawning"

                ESX.Game.SpawnLocalObject(v.propsName, vector3(v.position.x, v.position.y, v.position.z), function(entity)
                    v.entity = entity
                    FreezeEntityPosition(v.entity, true)
                    SetEntityCoords(v.entity, v.position.x, v.position.y, v.position.z)
                    SetEntityRotation(v.entity, v.heading.x, v.heading.y, v.heading.z)
                end)
            end

            if #(NullCoord - vector3(v.position.x, v.position.y, v.position.z)) < 2.5 then
                loopWait = 0
                if nTable.objets then
                    ESX.ShowHelpNotification(('~h~Informations de l\'objet~h~\n\nNom: %s\nLabel: %s\nId: %s\n\n~h~Informations admin~h~\nJoueur: %s\nUniqueID: %s\nDate: %s/%s/%s %sh%s\nPropriétaire: %s %s\n\n~INPUT_FRONTEND_ENDSCREEN_ACCEPT~ pour l\'enlever [Admin Mode]'):format(v.propsName, v.label, v.propsId, v.owner.Name, v.owner.UniqueID, v.owner.day, v.owner.month, v.owner.years, v.owner.hours, v.owner.min, v.owner.firstName, v.owner.lastName))
                else
                    if PlayerState.WorldPropsInfo then
                        ESX.ShowHelpNotification(('~h~Informations de l\'objet~h~\n\nNom: %s\nLabel: %s\nId: %s\nDate: %s/%s/%s %sh%s\nPropriétaire: %s %s\n\n~INPUT_FRONTEND_ENDSCREEN_ACCEPT~ pour l\'enlever'):format(v.propsName, v.label, v.propsId, v.owner.day, v.owner.month, v.owner.years, v.owner.hours, v.owner.min, v.owner.firstName, v.owner.lastName))
                    end
                end
  
                if PlayerState.WorldPropsInfo then
                    if IsControlJustPressed(0, 215) then
                        if nTable.staffMode then
                            if nTable.objets then
                                TriggerServerEvent('null:world:propsserver:delete', v)
                            else
                                if v.owner.UniqueID ~= ESX.PlayerData.idunique then
                                    ESX.ShowNotification('Ce n\'est pas vous le propriétaire de l\'objet')
                                else 
                                    TriggerServerEvent('null:world:propsserver:delete', v)
                                end
                            end
                        else
                            if v.owner.UniqueID ~= ESX.PlayerData.idunique then
                                ESX.ShowNotification('Ce n\'est pas vous le propriétaire de l\'objet')
                            else 
                                if PlayerState.WorldPropsInfo then
                                    TriggerServerEvent('null:world:propsserver:delete', v)
                                end
                            end
                        end
                    end
                elseif nTable.objets then
                    if IsControlJustPressed(0, 215) then
                        TriggerServerEvent('null:world:propsserver:delete', v)
                    end
                end
            end
            
            ::continue::
        end
        Citizen.Wait(loopWait)
    end
end))

--AddTextEntry('BLIP_PROPCAT', 'Objets ')
function setobject()
    Citizen.CreateThread(function()
        while nTable.objets do
            Wait(500)
            for _,v in pairs(null.data.world.props.propsSpawned) do
                if not DoesBlipExist(v.blip) then
                    v.blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
                    
                    SetBlipScale(v.blip,  0.5)
                    ShowHeadingIndicatorOnBlip(v.blip, true)
                    SetBlipSprite(v.blip, 1)
                    SetBlipColour(v.blip, 57)

                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString(("%s [%s]"):format(v.propsName, v.propsId))
                    EndTextCommandSetBlipName(v.blip)
                    SetBlipCategory(v.blip, 10)

                    null.data.world.props.propsSpawned[v.propsId].blip = v.blip
                end
            end
        end

        for _,v in pairs(null.data.world.props.propsSpawned) do
            local exist = DoesBlipExist(v.blip)
            if exist == nil then goto continue end

            RemoveBlip(v.blip)

            ::continue::
        end
    end)
end


function openPropItemsMenu(category, isStaff)
    isForStaff = isStaff
    local categoryMenu = RageUI.CreateMenu("", "Action disponible")
    local propMenu = RageUI.CreateSubMenu(categoryMenu, "", "Action disponible")
    propMenu.Closed = function()
        if acutalprops ~= nil then
            deletePreviewModel()
            acutalprops = nil
        end
    end

    local research = nil
    local category = {}
    local categoryName = nil
    local categoryResearch = nil
    
	RageUI.Visible(categoryMenu, not RageUI.Visible(categoryMenu))

	while categoryMenu do
		Citizen.Wait(0)

        RageUI.IsVisible(categoryMenu, function()
            if categoryResearch == nil then
                RageUI.Button(("Rechercher"):format(), nil, {}, true, {
                    onActive = function()
                        deletePreviewModel()
                    end,
                    onSelected = function()
                        null.fct.inputCb("Nom de la catégorie",function(result) 
                            if result ~= nil then
                                categoryResearch = result
                            end
                        end);
                    end
                })
            else
                RageUI.Button(("Arrêter la recherche"):format(), nil, {}, true, {
                    onActive = function()
                        deletePreviewModel()
                    end,
                    onSelected = function()
                        categoryResearch = nil
                    end
                })
            end

            RageUI.Line()

            for k,_ in pairs(Config.WorldProps.Objects) do
                if not isForStaff then
                    if k == 'Disabled' or k == 'AdminProps' then goto continue end 
                end

                if categoryResearch == nil then 
                    RageUI.Button(k, false, {}, true, {
                        onSelected = function() 
                            category = Config.WorldProps.Objects[k]
                            categoryName = k
                        end
                    }, propMenu)
                else
                    if string.match(string.lower(k), string.lower(categoryResearch)) then 
                        RageUI.Button(k, false, {}, true, {
                            onSelected = function() 
                                category = Config.WorldProps.Objects[k]
                                categoryName = k
                            end
                        }, propMenu)
                    end
                end

                ::continue::
            end
        end)
	
        RageUI.IsVisible(propMenu, function()
            if research == nil then
                RageUI.Button(("Rechercher"):format(), nil, {}, true, {
                    onSelected = function()
                        null.fct.inputCb("Entrez le nom de l\'objet",function(result) 
                            if result ~= nil then
                                research = result
                            end
                        end);
                    end
                })
            else
                RageUI.Button(("Arrêter la recherche"):format(), nil, {}, true, {
                    onSelected = function()
                        research = nil
                    end
                })
            end

            RageUI.Line()

            for _, v in pairs(category) do
                if research == nil then
                    RageUI.Button(v.name, false, {}, true, {
                        onActive = function()
                            PreviewModel(v.model, v.name)
                        end,
                        onSelected = function()
                            activePreviewMode(v.model, v.name, 'test', GenerateId(), v.model)
                            deletePreviewModel()
                        end
                    })
                else
                    if string.match(string.lower(v.name), string.lower(research)) then 
                        RageUI.Button(v.name, false, {}, true, {
                            onActive = function()
                                PreviewModel(v.model, v.name)
                            end,
    
                            onSelected = function() 
                                activePreviewMode(v.model, v.name, 'test', GenerateId(), GetHashKey(v.model))
                                deletePreviewModel()
                            end
                        })
                    end
                end
            end
        end)

        if not RageUI.Visible(categoryMenu) and not RageUI.Visible(propMenu) then
			categoryMenu = RMenu:DeleteType('categoryMenu', true)
            if DoesEntityExist(previewPropMenu) then
                DeleteEntity(previewPropMenu)
            end
        end 
    end
end


RegisterNetEvent('props:client:useProp', function(Staff)
	TriggerEvent("null:inventory:closeinv")
    openPropItemsMenu(nil, Staff)
end)

GenerateId = function()
    id = ""
    for i = 1, 6 do 
        id = id..''..math.random(0, 15)
    end
    return id
end