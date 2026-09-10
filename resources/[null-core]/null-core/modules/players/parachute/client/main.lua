local parachuteEquipped = false

local function giveParachute(tintIndex, model)
    local weapon = GetHashKey("GADGET_PARACHUTE")
    local ped = GetPlayerPed(PlayerId())
    GiveWeaponToPed(ped, weapon, 1000, false, false)
    if model then
        SetPlayerParachuteModelOverride(PlayerId(), GetHashKey(model))
    end
    if tintIndex then
        SetPlayerParachuteTintIndex(PlayerId(), tintIndex)
    end
    SetPedComponentVariation(ped, 5, 63, 0, 0)
    parachuteEquipped = true
    startParachuteWhile()
end

local parachuteEvents = {
    { event = "GivePedWeapon", tintIndex = 0, model = nil }, -- Rainbow
    { event = "GivePedWeapon2", tintIndex = 1, model = nil }, -- Red
    { event = "GivePedWeapon3", tintIndex = 2, model = nil }, -- Seaside
    { event = "GivePedWeapon4", tintIndex = 3, model = nil },-- Widowmaker
    { event = "GivePedWeapon5", tintIndex = 4, model = nil },--  Patriot
    { event = "GivePedWeapon6", tintIndex = 5, model = nil },-- Blue
    { event = "GivePedWeapon7", tintIndex = 6, model = nil },--  Black
    { event = "GivePedWeapon8", tintIndex = 7, model = nil },-- Hornet
    { event = "GivePedWeapon9", tintIndex = 8, model = "pil_p_para_pilot_sp_s" },-- Air Force
    { event = "GivePedWeapon10", tintIndex = 9, model = "pil_p_para_pilot_sp_s" },-- Desert 
    { event = "GivePedWeapon11", tintIndex = 10, model = "pil_p_para_pilot_sp_s" },-- Shadow
    { event = "GivePedWeapon12", tintIndex = 11, model = "pil_p_para_pilot_sp_s" },-- High Altitude
    { event = "GivePedWeapon13", tintIndex = 12, model = "pil_p_para_pilot_sp_s" },-- Airborne
    { event = "GivePedWeapon14", tintIndex = 13, model = "pil_p_para_pilot_sp_s" },-- Sunrise
}

RegisterNetEvent("null:setInParachute")
AddEventHandler("null:setInParachute", function(tinit, model)
    giveParachute(tinit, model)
end)


-- Event to reset the SetPedComponentVariation
local whileStarted = false
function startParachuteWhile()
    if whileStarted then return end
    whileStarted = true
    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        while true do
            Citizen.Wait(0)
            if parachuteEquipped then
                local playerPed = GetPlayerPed(-1)
                local speed = GetEntitySpeed(playerPed)
                if speed > 10.0 then -- Skydiving-Speed
                    if IsControlJustReleased(0, 144) then
                        local ped = GetPlayerPed(PlayerId())
                        SetPedComponentVariation(ped, 5, 0, 0, 0)
                        parachuteEquipped = false
                    end
                end
            else
                break
            end
        end
    end))
end

-- Event to remove the weapon "parachute"
RegisterNetEvent("null:removeParachute")
AddEventHandler("null:removeParachute", function()
    local weapon = GetHashKey("GADGET_PARACHUTE")
    local ped = GetPlayerPed(PlayerId())
    RemoveWeaponFromPed(ped, weapon)
end)