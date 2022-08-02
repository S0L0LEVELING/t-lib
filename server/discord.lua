--------------------------------------------------------------------------------
-- All information is fully server-sided
-- No infomrmation is passed to client to prevent a security risk.
--------------------------------------------------------------------------------

local config = {
    roles = { -- Can be used to get a users discord information, and check if a user has a discord role.
        enabled = false, -- If enabled you need to fill in the values below.
        token = '',
        guild = ''
    },
    embed = {
        color = '48383',
        footer = {
            text = 'Discord Logs',
            icon_url = 'https://i.imgur.com/i4v7thW.png'
        },
        user = {
            name = 'Discord Logs',
            icon_url = 'https://i.imgur.com/i4v7thW.png'
        }
    }
}

local roles_enabled = function()
    return config?.roles?.enabled and token ~= '' and guild ~= ''
end

local getIdentifiers = function(player)
    local t = {}

    if player then
        local identifiers = GetPlayerIdentifiers(player)

        for i=1, #identifiers do
            local prefix, identifier = string.strsplit(':', identifiers[i])
            t[prefix] = identifier
        end
    end

    return t
end

lib.discordlog = function(args)
    if (not args or type(args) ~= 'table') then return end

    local embed = {
        color = config?.embed?.color,
        type = 'rich',
        title = args?.title or '',
        description = args?.description or '',
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
        footer = config?.embed?.footer or {}
    }

    -- Add fields IF present
    if type(args?.fields) == 'table' and #args?.fields >= 1 then
        embed.fields = args?.fields
    end

    -- Add image IF present
    if args?.image and type(args?.image) == 'string' then
        embed.image = {url = args?.image}
    end
 
    PerformHttpRequest(args?.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = config?.embed?.user?.name, 
        avatar_url = config?.embed?.user?.icon_url, 
        embeds = { embed } }), { ['Content-Type'] = 'application/json' 
    })
end

lib.organaizeidentifiers = function(target)
    assert(target, 'Attempted to organaize an invalid targets identifiers.')
    local t = {}

    local identifiers = getIdentifiers(target)

    for k, v in pairs(identifiers) do
        if k == 'steam' then
            t[#t+1] = ('Steam: [%s](https://steamcommunity.com/profiles/%s)'):format(v, tonumber(v, 16))
        elseif k == 'discord' then
            t[#t+1] = ('Discord: <@%s>'):format(v)
        elseif k == 'license' then
            t[#t+1] = ('License: %s'):format(v)
        elseif k == 'license2' then
            t[#t+1] = ('License 2: %s'):format(v)
        elseif k == 'fivem' then
            t[#t+1] = ('FiveM: %s'):format(v)
        elseif k == 'xbl' then
            t[#t+1] = ('Xbox: %s'):format(v)
        elseif k == 'live' then
            t[#t+1] = ('Live: %s'):format(v)
        end
    end

    return table.concat(t, '\n')
end

lib.getdiscordinfo = function(target, onlyRoles)
    if (not roles_enabled()) then
        print('^1You cannot utilize "getdiscordinfo" due to the option being disabled in the libary.')
        print('^2To utilize & install this, visit the "discord.lua" in the "t-lib" resource. (server folder)')
        print('^0[^3WARNING^0]: When setting up the discord part, visit the docs to ensure you do it correctly.')
        return
    end

    local p = promise.new()
    local id = getIdentifiers(target)?.discord or ''
    local url = ('https://discordapp.com/api/guilds/%s/members/%s'):format(config?.roles?.guild, id)

    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        local d, inGuild = {}, resultData and true or false

        resultData = json.decode(resultData)

        if (resultData) then
            local roles = {}
            
            for i = 1, (type(resultData?.roles) == 'table' and #resultData?.roles or 0) do
                roles[i] = tonumber(resultData?.roles[i])
            end

            if (onlyRoles) then
                d = roles
            else
                if (resultData?.user) then
                    if (resultData?.user?.username and resultData?.user?.discriminator) then
                        d.name = ('%s#%s'):format(resultData.user.username, resultData.user.discriminator)
                    end

                    if (resultData?.user?.avatar) then   
                        d.avatar = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(id, resultData.user.avatar, resultData.user.avatar:sub(1, 1) and resultData.user.avatar:sub(2, 2) == '_' and 'gif' or 'png')
                    end
                end

                d.roles = roles
            end
        end

        p:resolve({d, inGuild})
    end, 'GET', '', {['Content-Type'] = 'application/json', ['Authorization'] = ('Bot %s'):format(config?.roles?.token)})

    return table?.unpack(Citizen.Await(p))
end

lib.checkrole = function(target, role)
    if (not roles_enabled()) then
        print('^1You cannot utilize "checkrole" due to the option being disabled in the libary.')
        print('^2To utilize & install this, visit the "discord.lua" in the "t-lib" resource. (server folder)')
        print('^0[^3WARNING^0]: When setting up the discord part, visit the docs to ensure you do it correctly.')
        return
    end

    assert(target, ('The specified target to be checked from %s was not found (%s)'):format(GetInvokingResource(), target))
    assert(role, ('The specified role to be checked from %s was not found (%s)'):format(GetInvokingResource(), role))

    local roles = lib?.getdiscordinfo(target, true) -- Gets all the users discord roles.
    
    for i = 1, (type(roles) == 'table' and #roles or 0) do
        if (tonumber(roles[i]) == tonumber(role)) then
            return true
        end
    end

    return false
end

lib.registercallback('t-lib:checkrole', function(src, cb, role)
    cb(lib.checkrole(src, role))
end)

CreateThread(function()
    if (roles_enabled()) then
        local url = ('https://discordapp.com/api/guilds/%s'):format(config?.roles?.guild)
        PerformHttpRequest(url, function(errorCode, data, resultHeaders)
            if (errorCode == 200) then
                data = json.decode(data)
                print(('^2[SUCCESS]^0: Discord Authorized. (Guild: %s)'):format(data?.name))
            else
                CreateThread(function()
                    while (true) do
                        print('^1[ERROR]^0: Discord information is incorrect, failed to login!')
                        Wait(2000)
                    end
                end)
            end
        end, 'GET', '', {['Content-Type'] = 'application/json', ['Authorization'] = ('Bot %s'):format(config?.roles?.token)})
    end
end)