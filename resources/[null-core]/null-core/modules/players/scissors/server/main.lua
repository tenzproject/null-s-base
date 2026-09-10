ESX.RegisterUsableItem('ciseaux', function(source)
	TriggerClientEvent('null:use-scissors', source)
end)

RegisterNetEvent('null:scissors:cut', function(target)
	TriggerClientEvent('null:scissors:cut', target, source)
end)