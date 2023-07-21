local command = {
    name = 'pw_admin_add',
    description = 'Command (pw_admin_add) | Adds a new username & password admin.',
    permission_level = 6,
    help = 'Syntax: /$cmd <player index/username> <level> <password>'
}

local concat = table.concat

function command:run(id, args)

    local target, level = args[2], tonumber(args[3])
    local admin = self.players[id]
    local admins = self.admins

    if admin:hasPermission(self.permission_level, args[1]) then

        if (args[2] == 'help') then
            admin:send(self.description)
        elseif (not target or not level) then
            admin:send(self.help)
        elseif (not self.commands[level]) then
            admin:send('Invalid level. Must be between 1 and ' .. #self.commands)
        else
            local target_index = tonumber(target)
            local is_online = target_index and player_present(target_index)
            local username = is_online and self.players[target_index].name or target

            local password = concat(args, ' ', 4)
            if (not password or password == '') then
                admin:send('You must specify a password.')
            else
                if (not admins.password_admins[username]) then

                    local min = self.password_length_limit[1]
                    local max = self.password_length_limit[2]

                    local length = password:len()
                    if (length < min or length > max) then
                        admin:send('Password must be ' .. min .. ' to ' .. max .. ' characters')
                        return false
                    end
                    
                    if is_online then
                        target = self.players[target_index]
                        target.level = level
                        target:setLevelVariable()
                        target.password_admin = true
                    end

                    admins.password_admins[username] = {
                        password = self:getSHA2Hash(password),
                        level = level,
                        date = 'Added on ' .. self:getDate() .. ' by ' .. admin.name .. ' (' .. admin.ip .. ')'
                    }
                    self:updateAdmins()

                    admin:send('Added ' .. username .. ' to the password-admin list. Level (' .. level .. ').')
                    self:log(admin.name .. ' (' .. admin.ip .. ') added ' .. username .. ' to the password-admin list. Level (' .. level .. ')', self.logging.management)
                else
                    admin:send(username .. ' is already a password-admin (level ' .. admins.password_admins[username].level .. ')')
                end
            end
        end
    end
end

return command