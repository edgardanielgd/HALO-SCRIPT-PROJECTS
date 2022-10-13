-- Parkour Timer script by Jericho Crosby (Chalwk).
-- Copyright (c) 2022, Jericho Crosby <jericho.crosby227@gmail.com>

local Helper = {}
local insert = table.insert
local sort = table.sort

-- Saves a player's time to the database:
function Helper:saveTime()

    local ip = self.ip
    local name = self.name
    local time = self.timer:get()

    local database = self.database

    database[ip].name = name -- update the name in case it changed
    insert(database[ip].times, time)
    sort(database[ip].times)

    self.timer:stop()
    self.hud = nil
    self.checkpoint = 0
    self.x, self.y, self.z = nil, nil, nil

    self:WriteFile(self.database)
end

return Helper