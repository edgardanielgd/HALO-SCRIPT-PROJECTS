--[[
------------------------------------
Script Name: AdminChat (utility), for SAPP | (PC\CE)
    - Version 1
    
Description: Chat privately with other admins. 
             Command: /achat on|off

This script is also available on my github! Check my github for regular updates on my projects, including this script.
https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS

Copyright (c) 2016-2017, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/Halo-Scripts-Phasor-V2-/blob/master/LICENSE

* IGN: Chalwk
* Written by Jericho Crosby
-----------------------------------
]]--

api_version = "1.11.0.0"

-- configuration starts here --
min_admin_level = 1
prefix = "[ADMIN CHAT] "
Restore_Previous_State = true
-- configuration ends here --

data = { }
players = { }
adminchat = { }
stored_data = { }
function OnScriptLoad()
    register_callback(cb['EVENT_CHAT'], "OnPlayerChat")
    register_callback(cb['EVENT_JOIN'], "OnPlayerJoin")
    register_callback(cb['EVENT_LEAVE'], "OnPlayerLeave")
    register_callback(cb['EVENT_GAME_START'], "OnNewGame")
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
    for i = 1,16 do
        if player_present(i) then
            players[get_var(i, "$name")].adminchat = nil
        end
    end
end

function OnScriptUnload() 
    for i = 1,16 do
        if player_present(i) then
            players[get_var(i, "$name")].adminchat = false
        end
    end
end

function OnNewGame()
    for i = 1,16 do
        if player_present(i) then
            players[get_var(i, "$name")].adminchat = nil
        end
    end
end

function OnGameEnd()
    for i = 1,16 do
        if player_present(i) then
            if (Restore_Previous_State == true) then
                if players[get_var(i, "$name")].adminchat == true then bool = "true" else bool = "false" end
                data[i] = get_var(i, "$name") .. ":" .. bool
                stored_data[data] = stored_data[data] or { }
                table.insert(stored_data[data], tostring(data[i]))
            else
                players[get_var(i, "$name")].adminchat = false
            end
        end
    end
end

function OnPlayerJoin(PlayerIndex)
    players[get_var(PlayerIndex, "$name")] = { }
    players[get_var(PlayerIndex, "$name")].adminchat = nil
    if (Restore_Previous_State == true) then
        local t = tokenizestring(tostring(data[PlayerIndex]), ":")
        if t[2] == "true" then
            rprint(PlayerIndex, "Your admin chat is on!")
            players[get_var(PlayerIndex, "$name")].adminchat = true
        else
            players[get_var(PlayerIndex, "$name")].adminchat = false
        end
    else
        players[get_var(PlayerIndex, "$name")].adminchat = false
    end
end

function OnPlayerLeave(PlayerIndex)
    if PlayerIndex ~= 0 then
        if (Restore_Previous_State == true) then
            if players[get_var(PlayerIndex, "$name")].adminchat == true then bool = "true" else bool = "false" end
            data[PlayerIndex] = get_var(PlayerIndex, "$name") .. ":" .. bool
            stored_data[data] = stored_data[data] or { }
            table.insert(stored_data[data], tostring(data[PlayerIndex]))
        else
            players[get_var(PlayerIndex, "$name")].adminchat = false
        end
    end
end

function OnPlayerChat(PlayerIndex, Message)
    local message = tokenizestring(Message)
    if #message == 0 then
        return nil
    end
    local t = tokenizestring(Message)
    local Message = tostring(Message)
    if string.sub(t[1], 1, 1) == "/" then
        cmd = t[1]:gsub("\\", "/")
        if cmd == "/achat" then
            if (tonumber(get_var(PlayerIndex,"$lvl"))) >= min_admin_level then 
                if t[2] == "on" or t[2] == "1" or t[2] == "true" then
                    rprint(PlayerIndex, "Admin Chat Toggled on!")
                    players[get_var(PlayerIndex, "$name")].adminchat = true
                    return false
                elseif t[2] == "off" or t[2] == "0" or t[2] == "false" then
                    players[get_var(PlayerIndex, "$name")].adminchat = false
                    rprint(PlayerIndex, "Admin Chat Toggled off!")
                    return false
                else
                    rprint(PlayerIndex, "Invalid Syntax! Type /achat on|off")
                    return false
                end
            else
                rprint(PlayerIndex, "You do not have permission to execute that command!")
            end
            return false
        end
    end
    if players[get_var(PlayerIndex, "$name")].adminchat == true then
        for i = 0, #message do
            if message[i] then
                if string.sub(message[1], 1, 1) == "/" or string.sub(message[1], 1, 1) == "\\" then
                    return true
                else
                    AdminChat(prefix .. " " .. get_var(PlayerIndex, "$name") .. ":  " .. Message, PlayerIndex)
                    return false
                end
            end
        end
    end
end

function AdminChat(Message, PlayerIndex)
    for i = 1, 16 do
        if player_present(i) then
            if (tonumber(get_var(i,"$lvl"))) >= min_admin_level then
                rprint(i, "|l" .. Message)
            end
        end
    end
end

function tokenizestring(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function OnError(Message)
    print(debug.traceback())
end