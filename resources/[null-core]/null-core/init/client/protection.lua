token = nil

RegisterNetEvent('null:protection:token:retrevie')
AddEventHandler('null:protection:token:retrevie', function(TokenReceive)
    token = TokenReceive
end)