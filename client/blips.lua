local blips = {}

lib.createblip = function(args)
    assert(type(args) == 'table', ('%s attempted creating a blip but failed. (args ~= table)'):format(GetInvokingResource()))

    local blip = AddBlipForCoord(args?.coords or vec2(0.0, 0.0))
    SetBlipSprite(blip, args?.sprite or 1)
    SetBlipDisplay(blip, args?.display or 4)
    SetBlipScale(blip, args?.scale or 0.6)
    SetBlipColour(blip, args?.color or 1)
    SetBlipAsShortRange(blip, args?.range or true)

    if args?.category then SetBlipCategory(blip, args?.category) end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(args?.title or 'Unmarked Blip')
    EndTextCommandSetBlipName(blip)

    blips[#blips +1] = {
        resource = GetInvokingResource(),
        blip = blip
    }

    return blip
end

AddEventHandler('onResourceStop', function(res) -- Wipe blips when invoking resource is stopped
    if (res == GetCurrentResourceName()) then
        ClearAllHelpMessages()
        ClearHelp(true)
        return 
    end
    local removed = 0

    for k, v in pairs(type(blips) == 'table' and blips or {}) do
        if (v?.resource == res) then
            if (DoesBlipExist(v?.blip)) then
                removed += 1
                RemoveBlip(v?.blip) 
            end
        end
    end

    if (removed > 0) then print(('Removed %s blips due to %s stopping.'):format(removed, res)) end
end)