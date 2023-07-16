local command = {
    name = 'hash_bans',
    description = 'Command ($cmd) | List all hash-bans.',
    permission_level = 6,
    help = 'Syntax: /$cmd>',
    output = '[$id] [$offender] [Expires: $years/$months/$days - $hours:$minutes:$seconds]'
}

function command:run(id, args)

    local admin = self.players[id]
    if admin:hasPermission(self.permission_level, args[1]) then
        local header = true
        for _, ban in pairs(self.bans['hash']) do
            if (header) then
                header = false
                admin:send('[Hash-Bans]')
            end
            local stdout = self:banViewFormat(ban.id, ban.offender, ban.time)
            admin:send(stdout)
        end

        if (header) then
            admin:send('There are no hash-bans.')
        end
        self:log(admin.name .. ' viewed the hash-ban list.', self.logging.management)
    end

    return false
end

return command