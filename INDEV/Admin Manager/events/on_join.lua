local event = {}

local function getHighest(a, b)
    return (a > b and a or b)
end

local function setLevel(self, admins)

    local id = self.id
    local ip = self.ip
    local socket = self.socket
    local hash = self.hash

    local hash_admins = admins.hash_admins
    local ip_admins = admins.ip_admins
    local cached_pw_admins = self.cached_pw_admins

    if (hash_admins[hash] and ip_admins[ip]) then
        self.level = getHighest(hash_admins[hash].level, ip_admins[ip].level)
        cprint('Admin Manager: ' .. self.name .. ' (' .. self.ip .. ') logged in as a level ' .. self.level .. ' ip-hash-admin.')
    elseif (hash_admins[hash]) then
        self.level = hash_admins[hash].level
        cprint('Admin Manager: ' .. self.name .. ' (' .. self.ip .. ') logged in as a level ' .. self.level .. ' hash-admin.')
    elseif (ip_admins[ip]) then
        self.level = ip_admins[ip].level
        cprint('Admin Manager: ' .. self.name .. ' (' .. self.ip .. ') logged in as a level ' .. self.level .. ' ip-admin.')
    elseif (cached_pw_admins[socket]) then
        self.level = cached_pw_admins[socket]
    else
        self.level = 1 -- public
    end

    self:setLevelVariable()

    execute_command('adminadd ' .. id .. ' 4')
end

function event:newPlayer(o)

    setmetatable(o, { __index = self })
    self.__index = self

    local rejected = o:rejectPlayer()
    if (rejected) then
        return o
    elseif (o.id ~= 0) then
        setLevel(o, self.admins)
        o:newAlias('IP_ALIASES', o.ip, o.name)
        o:newAlias('HASH_ALIASES', o.hash, o.name)
    end
    return o
end

function event:onJoin(id)
    self.players[id] = self:newPlayer({
        id = id,
        name = get_var(id, '$name'),
        hash = get_var(id, '$hash'),
        ip = get_var(id, '$ip'):match('%d+.%d+.%d+.%d+'),
        socket = get_var(id, '$ip')
    })
    self.players[id]:vipMessages()
end

register_callback(cb['EVENT_JOIN'], 'OnJoin')

return event