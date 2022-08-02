local cachedCbs = {}

lib.callback = function(callback, cb, ...)
    local key = #cachedCbs + 1
    cachedCbs[key] = cb
    TriggerServerEvent("trase_lib:trigger_callback", callback, key, ...)
end

lib.await.callback = function(callback, ...)
    local key = #cachedCbs + 1
    local toreturn

    cachedCbs[key] = function(...)
        toreturn = {...}
    end
    TriggerServerEvent("trase_lib:trigger_callback", callback, key, ...)

    while not toreturn do
        Wait(0)
    end

    return table.unpack(toreturn)
end

RegisterNetEvent("trase_lib:callback_result")
AddEventHandler("trase_lib:callback_result", function(key, ...)
    if cachedCbs[key] then 
        cachedCbs[key](...)
        cachedCbs[key] = nil
    end
end)