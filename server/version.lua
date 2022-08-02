------------------------------------------------------------
-- Used to check if using latest version on all resources.
------------------------------------------------------------

local check_verison = function(url, version)
    local p = promise.new()

    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        if resultData and errorCode == 200 then
            resultData = resultData:match('%d%.%d+%.%d+')
            
            if version ~= resultData then
                latestversion = resultData
            else
                latestversion = true
            end
        end

        p:resolve({latestversion})
    end, 'GET')

    return table?.unpack(Citizen.Await(p))
end

CreateThread(function()
    local url = 'https://raw.githubusercontent.com/ImTrase/versions/main/lib.txt'
    local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    local ver = check_verison(url, version)

    if (ver ~= true) then
        print(('^4An update is available! ^0(^1Current Version: %s ^0|^2 Newest Version: %s^0)'):format(version, ver))
    end
end)

exports('check_verison', check_verison)