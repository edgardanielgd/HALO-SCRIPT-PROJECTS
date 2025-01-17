--[[
--=====================================================================================================--
Script Name: No Damage, for SAPP (PC & CE)
Description: Stops you from taking damage.

Copyright (c) 2023, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS/blob/master/LICENSE
--=====================================================================================================--
]]--

-- config starts
local command = 'damage'
-- config ends

api_version = '1.12.0.0'

local players = {}

function OnScriptLoad()
    register_callback(cb['EVENT_LEAVE'], 'OnQuit')
    register_callback(cb['EVENT_SPAWN'], 'modifyBits')
    register_callback(cb['EVENT_COMMAND'], 'OnCommand')
    register_callback(cb['EVENT_GAME_START'], 'OnStart')
    register_callback(cb['EVENT_DAMAGE_APPLICATION'], 'OnDamage')
    OnStart()
end

local function getOriginalBits(id)

    local dyn = get_dynamic_player(id)
    if (dyn ~= 0) then

        local noCollision = dyn + 0x10
        local noDamage = dyn + 0x106

        local no_collision_bit = read_bit(noCollision, 0)
        local no_damage_bit = read_bit(noDamage, 11)

        return {
            [noCollision] = { 0, no_collision_bit },
            [noDamage] = { 11, no_damage_bit },
        }
    end

    return nil
end

local function restore(id)
    for address, v in pairs(players[id]) do
        write_bit(address, v[1], v[2])
    end
    players[id] = nil
end

function OnStart()
    if (get_var(0, '$gt') ~= 'n/a') then
        for i = 1, 16 do
            if player_present(i) then
                restore(i)
            end
        end
    end
end

function OnCommand(id, cmd)
    if (cmd:sub(1, command:len()):lower() == command) then
        if (players[id] ~= nil) then
            restore(id)
            rprint(id, "You will now take damage from other players.")
        else
            players[id] = getOriginalBits(id)
            modifyBits(id)
            rprint(id, "You will no longer take damage from other players.")
        end
        return false
    end
end

function OnDamage(victim, killer)

    local v = tonumber(victim)
    local k = tonumber(killer)

    if (v ~= k and players[v] ~= nil) then
        return false
    end
end

function OnQuit(id)
    players[id] = nil
end

function modifyBits(id)
    local dyn = get_dynamic_player(id)
    if (dyn ~= 0 and players[id] ~= nil) then
        write_bit(dyn + 0x10, 0, 1)     -- uncollidable/invulnerable
        write_bit(dyn + 0x106, 11, 1)   -- undamageable except for shields w explosions
    end
end

function OnScriptUnload()
    -- N/A
end