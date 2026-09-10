commonFunction = LPH_NO_VIRTUALIZE(function()
	AddEventHandler('esx:getSharedObject', function(cb)
		cb(ESX)
	end)

	function getSharedObject()
		return ESX
	end

	exports("getSharedObject", function()
		return ESX
	end)
end)

commonFunction()

