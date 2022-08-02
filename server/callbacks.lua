local cachedCbs = {}

lib.registercallback = function(callback, cb)
    cachedCbs[callback] = cb
end

RegisterNetEvent("trase_lib:trigger_callback")
AddEventHandler("trase_lib:trigger_callback", function(callback, key, ...)
    local src = source
    if cachedCbs[callback] then
        cachedCbs[callback](src, function(...)
            TriggerClientEvent("trase_lib:callback_result", src, key, ...)
        end, ...)
    end
end)