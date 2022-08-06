lib.draw2dtext = function(args)
    assert(type(args) == 'table', ('%s attempted creating 2d text but failed. (args ~= table)'):format(GetInvokingResource()))
    SetTextFont(args?.font or 4)
    SetTextScale(args?.scale or 1.0, args?.scale or 1.0) 
    if args?.outline then SetTextOutline() end
    if args?.color then SetTextColour(args?.color[1] or 255, args?.color[2] or 255, args?.color[3] or 255, args?.color[4] or 255) end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(args?.text)
    local w, h = GetActiveScreenResolution()
    EndTextCommandDisplayText(args?.x/w, args?.y/h)
end

lib.draw3dtext = function(args)
    assert(type(args) == 'table', ('%s attempted creating 3d text but failed. (args ~= table)'):format(GetInvokingResource()))
    local dist = #(GetFinalRenderedCamCoord() - args?.coords)
    local scale = (1 / dist) * 25
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    local aScale = args?.scale or 1.0
    SetTextScale(aScale * scale, aScale * scale)
    SetTextFont(args?.font or 4)
    SetTextCentre(true)
    if args?.color then SetTextColour(args?.color[1] or 255, args?.color[2] or 255, args?.color[3] or 255, args?.color[4] or 255) end
    if args?.outline then SetTextOutline() end

    BeginTextCommandDisplayText("STRING") --drawing the text
    AddTextComponentSubstringPlayerName(args?.text)
    SetDrawOrigin(args?.coords.x, args?.coords.y, args?.coords.z, 0) --2d to 3d
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

lib.missiontext = function(text, duration)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text or 'Unspecified Mission Text')
    EndTextCommandPrint(duration or 250, 1)
end

local text = ('t_lib__helptext:%s'):format(GetCurrentResourceName())

lib.drawhelptext = function(text)
    AddTextEntry(text, text)
    BeginTextCommandDisplayHelp(text)
    EndTextCommandDisplayHelp(0, true, true, 0)
end

lib.hidehelptext = function()
    ClearAllHelpMessages()
    ClearHelp(true)
end

lib.createmarker = function(args)
    assert(type(args) == 'table', ('%s attempted creating a marker but failed. (args ~= table)'):format(GetInvokingResource()))
    return DrawMarker(
        args?.type or 2,
        args?.coords or vec3(0, 0, 0),
        args?.direction or vec3(0.0, 0.0, 0.0), 
        args?.rotation or vec3(0, 0.0, 0.0), 
        args?.size or vec3(0.3, 0.2, 0.15),
        args?.color or vec4(0, 0, 255, 100),
        false, false, false, true, false, false, false
    )
end

local function request(native, hasLoaded, requestType, name, timeout)
	native(name)

	if coroutine.running() then
		if not timeout then
			timeout = 500
		end

		for i = 1, timeout do
			Wait(0)
			if hasLoaded(name) then
				return name
			end
		end

		print(("Failed to load %s '%s' after %s ticks"):format(requestType, name, timeout))
	end

	return name
end

lib.loadanimdict = function(dict)
    if HasAnimDictLoaded(animDict) then return animDict end

	if not DoesAnimDictExist(animDict) then
		return error(("Attempted to load invalid animDict (%s)"):format(animDict))
	end

	return request(RequestAnimDict, HasAnimDictLoaded, 'animDict', animDict, timeout)
end

lib.requestmodel = function(model)
    if not tonumber(model) then model = joaat(model) end
	if HasModelLoaded(model) then return model end

	if not IsModelValid(model) then
		return error(("Attempted to load invalid model (%s)"):format(model))
	end

	return request(RequestModel, HasModelLoaded, 'model', model, timeout)
end

lib.playanim = function(wait, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)
	lib.loadanimdict(dict)
	CreateThread(function()
        local ped = PlayerPedId()
		TaskPlayAnim(ped, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)
		Wait(wait)
		if wait > 0 then ClearPedSecondaryTask(ped) end
	end)
end

lib.spawnvehicle = function(args)
    assert(type(args) == 'table', ('%s attempted creating a vehicle but failed. (args ~= table)'):format(GetInvokingResource()))
    local model = (type(args?.model) == 'number' and args?.model or GetHashKey(args?.model))
    local networked = args?.networked == nil and true or args?.networked
    CreateThread(function()
		lib?.requestmodel(model)

		local vehicle = CreateVehicle(model, args?.coords?.xyz, args?.coords?.w or 0.0, networked, false)

		if networked then
			local id = NetworkGetNetworkIdFromEntity(vehicle)
			SetNetworkIdCanMigrate(id, true)
			SetEntityAsMissionEntity(vehicle, true, false)
		end

		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
		SetVehRadioStation(vehicle, 'OFF')

        if (args?.seat) then
            SetPedIntoVehicle(PlayerPedId(), vehicle, args?.seat)
        end

        return vehicle 
	end)
end