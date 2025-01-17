local command = {
    name = 'pw_admins',
    description = 'Command (pw_admins) | Shows a list of username & password admins.',
    header = '[IP-Admins] (Page: %s/%s)', -- page (current, total)
    output = '%s | Level: [%s]', -- name, level
    help = 'Syntax: /$cmd <page>'
}

function command:run(id, args)
    local admin = self.players[id]
    if admin:hasPermission(self.permission_level, args[1]) then

        if (args[2] == 'help') then
            return false, admin:send(self.description)
        end

        local page = tonumber(args[2]) or 1
        local results = self:showAdminList('password_admins', page, 5, admin)
        if (not results) then
            admin:send('There are no password-admins.')
        end
        self:log(admin.name .. ' viewed the password-admin list.', self.logging.management)
    end
end

return command