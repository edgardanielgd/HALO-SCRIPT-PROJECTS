--[[
Script Name: Focal Point (beta v2.1), for SAPP | (PC\CE)
Implementing API version: 1.11.0.0


This script is also available on my github! Check my github for regular updates on my projects, including this script.
https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS

* IGN: Chalwk
* This is my extension of another "progression based game" that was for Phasor, by SlimJim
* Re-written and converted to sapp by Jericho Crosby (Chalwk)
]]

api_version = "1.11.0.0"

BLUE_TEAM = 1
RED_TEAM = 1 - BLUE_TEAM
AnnounceRank = true
game_started = false
processid = 0
kill_count = 0
cur_players = 0
cur_red_count = 0
cur_blue_count = 0
time = { } 	 	-- Declare time. Used for PlayerIndex's time spent in server.
kills = { }
avenge = { }
killers = { }
xcoords = { } 	-- Declare x coords. Used for distance traveled.
ycoords = { } 	-- Declare y coords. Used for distance traveled.
zcoords = { } 	-- Declare z coords. Used for distance traveled.
messages = { }
jointime = { } 	-- Declare Jointime. Used for a PlayerIndex's time spent in server.
hash_table = { }
last_damage = { }
kill_command_count = { }

function OnScriptLoad()
    --register_callback(cb['EVENT_TICK'], "OnTick")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_DIE"], "OnPlayerDeath")
    register_callback(cb['EVENT_CHAT'], "OnServerChat")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerLeave")
    register_callback(cb["EVENT_GAME_START"], "OnNewGame")
	register_callback(cb['EVENT_PRESPAWN'], "OnPlayerPreSpawn")
    register_callback(cb["EVENT_DAMAGE_APPLICATION"], "OnDamageApplication")
    LoadItems()
end
 
function OnScriptUnload()
    -- Save Tables --
    SaveTableData(sprees, "Sprees.txt")
    SaveTableData(medals, "Medals.txt")
    SaveTableData(stats, "Stats.txt")
    last_damage = {}
end
 
function CheckType()
    type_is_koth = get_var(1, "$gt") == "koth"
    type_is_oddball = get_var(1, "$gt") == "oddball"
    type_is_race = get_var(1, "$gt") == "race"
    type_is_slayer = get_var(1, "$gt") == "slayer"
    if (type_is_koth) or (type_is_oddball) or (type_is_race) or (type_is_slayer) then
        unregister_callback(cb['EVENT_TICK'])
        unregister_callback(cb["EVENT_JOIN"])
        unregister_callback(cb["EVENT_DIE"])
        unregister_callback(cb['EVENT_CHAT'])
        unregister_callback(cb["EVENT_GAME_END"])
        unregister_callback(cb['EVENT_SPAWN'])
        unregister_callback(cb["EVENT_LEAVE"])
        unregister_callback(cb["EVENT_GAME_START"])
        unregister_callback(cb['EVENT_COMMAND'])
        unregister_callback(cb['EVENT_PRESPAWN'])
        unregister_callback(cb["EVENT_DAMAGE_APPLICATION"])
        cprint("Warning: This script doesn't support KOTH, ODDBALL, RACE or SLAYER", 4 + 8)
    end
end

function OnNewGame()
    CheckType()
    LoadItems()
    -- 	Map Name
    map_name = get_var(1, "$map")
    -- 	Reset Variables
    cur_blue_count = 0
    cur_red_count = 0
    cur_players = 0
    game_started = true
    Rule_Timer = timer(1000, "RuleTimer")
    OpenFiles()
	for i=1,16 do
		if player_present(i) then	
			last_damage[i] = 0
		end
	end	
end
 
function OnGameEnd()
    -- 		stage 1: 	F1 Screen
    -- 		stage 2: 	PGCR Appears
    -- 		stage 3: 	Players may quit
    if stage == 1 then
        -- <	Remove Timers
        if credit_timer then credit_timer = nil end
        if Rule_Timer then Rule_Timer = nil end
        -- >
        timer(10, "AssistDelay")
        for i = 1, 16 do
            if getplayer(i) then
                -- Verify Red Team
                if getteam(i) == RED_TEAM then
                    changescore(i, 50, plus)
                    -- If a red PlayerIndex survives the game without dying, then reward them 50+ cR
                    SendMessage(i, "Awarded: +50 (cR) - Survivor")
                    local hash = get_var(i, "$hash")
                    killstats[gethash(i)].total.credits = killstats[gethash(i)].total.credits + 50
                end
                -- If the palyer has less than 3 Deaths on game end, then award them 15+ cR
                if read_word(getplayer(i) + 0xAE) < 3 then
                    -- PlayerIndex deaths
                    changescore(i, 15, plus)
                    SendMessage(i, "Awarded: +15 (cR) - Less then 3 Deaths")
                    killstats[gethash(i)].total.credits = killstats[gethash(i)].total.credits + 15
                end
                extra[gethash(i)].woops.gamesplayed = extra[gethash(i)].woops.gamesplayed + 1
                time = os.time() - jointime[gethash(i)]
                extra[gethash(i)].woops.time = extra[gethash(i)].woops.time + time
            end
        end
    end
    
	for i=1,16 do
		if player_present(i) then		
			last_damage[i] = 0
		end
	end
    
    SaveTableData(killstats, "KillStats.txt")
    SaveTableData(extra, "Extra.txt")
    SaveTableData(done, "CompletedMedals.txt")
    SaveTableData(sprees, "Sprees.txt")
    SaveTableData(stats, "Stats.txt")
    SaveTableData(medals, "Medals.txt")
    SaveTableData(extra, "Extra.txt")

    game_started = false
end

function OnPlayerPreSpawn(PlayerIndex)
	last_damage[PlayerIndex] = 0
end

function WelcomeHandler(PlayerIndex)
    local network_struct = read_dword(sig_scan("F3ABA1????????BA????????C740??????????E8????????668B0D") + 3)
    ServerName = read_widestring(network_struct + 0x8, 0x42)
    execute_command("msg_prefix \"\"")
    say(PlayerIndex, "Welcome to " .. ServerName)
    execute_command("msg_prefix \"** SERVER ** \"")
end

function OnServerChat(PlayerIndex, Message)

    local Message = string.lower(Message)
    local t = tokenizestring(Message, " ")
    local count = #t

    if PlayerIndex ~= nil then
        local hash = get_var(PlayerIndex, "$hash")
        if Message == "@info" then
            rprint(PlayerIndex, "\"@weapons\":  Will display stats for eash weapon.")
            rprint(PlayerIndex, "\"@stats\":  Will display about your kills, deaths etc.")
            rprint(PlayerIndex, "\"@sprees\":  Will display info about your Killing Spreees.")
            rprint(PlayerIndex, "\"@rank\":  Will display info about your rank.")
            rprint(PlayerIndex, "\"@medals\":  Will display info about your medals.")
            return false
        elseif Message == "@weapons" then
            -- =========================================================================================================================================================================
            rprint(PlayerIndex, "Assault Rifle: " .. stats[hash].kills.assaultrifle .. " | Banshee: " .. stats[hash].kills.banshee .. " | Banshee Fuel Rod: " .. stats[hash].kills.bansheefuelrod .. " | Chain Hog: " .. stats[hash].kills.chainhog)
            rprint(PlayerIndex, "EMP Blast: " .. extra[hash].woops.empblast .. " | Flame Thrower: " .. stats[hash].kills.flamethrower .. " | Frag Grenade: " .. stats[hash].kills.fragnade .. " | Fuel Rod: " .. stats[hash].kills.fuelrod)
            rprint(PlayerIndex, "Ghost: " .. stats[hash].kills.ghost .. " | Melee: " .. stats[hash].kills.melee .. " | Needler: " .. stats[hash].kills.needler .. " | People Splattered: " .. stats[hash].kills.splatter)
            rprint(PlayerIndex, "Pistol: " .. stats[hash].kills.pistol .. " | Plasma Grenade: " .. stats[hash].kills.plasmanade .. " | Plasma Pistol: " .. stats[hash].kills.plasmapistol .. " | Plasma Rifle: " .. stats[hash].kills.plasmarifle)
            rprint(PlayerIndex, "Rocket Hog: " .. extra[hash].woops.rockethog .. " | Rocket Launcher: " .. stats[hash].kills.rocket .. " | Shotgun: " .. stats[hash].kills.shotgun .. " | Sniper Rifle: " .. stats[hash].kills.sniper)
            rprint(PlayerIndex, "Stuck Grenade: " .. stats[hash].kills.grenadestuck .. " | Tank Machine Gun: " .. stats[hash].kills.tankmachinegun .. " | Tank Shell: " .. stats[hash].kills.tankshell .. " | Turret: " .. stats[hash].kills.turret)
            -- =========================================================================================================================================================================
            return false
        elseif Message == "@stats" then
            -- =========================================================================================================================================================================
            local Player_KDR = RetrievePlayerKDR(PlayerIndex)
            local cpm = math.round(killstats[hash].total.credits / extra[hash].woops.gamesplayed, 2)
            if cpm == 0 or cpm == nil then
                cpm = "No credits earned"
            end
            local days, hours, minutes, seconds = secondsToTime(extra[hash].woops.time, 4)
            -- =========================================================================================================================================================================
            rprint(PlayerIndex, "Kills: " .. killstats[hash].total.kills .. " | Deaths: " .. killstats[hash].total.deaths .. " | Assists: " .. killstats[hash].total.assists)
            rprint(PlayerIndex, "KDR: " .. Player_KDR .. " | Suicides: " .. killstats[hash].total.suicides .. " | Betrays: " .. killstats[hash].total.betrays)
            rprint(PlayerIndex, "Games Played: " .. extra[hash].woops.gamesplayed .. " | Time in Server: " .. days .. "d " .. hours .. "h " .. minutes .. "m " .. seconds .. "s")
            rprint(PlayerIndex, "Distance Traveled: " .. math.round(extra[hash].woops.distance / 1000, 2) .. " kilometers | Credits Per Map: " .. cpm)
            -- =========================================================================================================================================================================
            return false
        elseif Message == "@sprees" then
            -- =========================================================================================================================================================================
            rprint(PlayerIndex, "Double Kill: " .. sprees[hash].count.double .. " | Triple Kill: " .. sprees[hash].count.triple .. " | Overkill: " .. sprees[hash].count.overkill .. " | Killtacular: " .. sprees[hash].count.killtacular)
            rprint(PlayerIndex, "Killtrocity: " .. sprees[hash].count.killtrocity .. " | Killimanjaro " .. sprees[hash].count.killimanjaro .. " | Killtastrophe: " .. sprees[hash].count.killtastrophe .. " | Killpocalypse: " .. sprees[hash].count.killpocalypse)
            rprint(PlayerIndex, "Killionaire: " .. sprees[hash].count.killionaire .. " | Kiling Spree " .. sprees[hash].count.killingspree .. " | Killing Frenzy: " .. sprees[hash].count.killingfrenzy .. " | Running Riot: " .. sprees[hash].count.runningriot)
            rprint(PlayerIndex, "Rampage: " .. sprees[hash].count.rampage .. " | Untouchable: " .. sprees[hash].count.untouchable .. " | Invincible: " .. sprees[hash].count.invincible .. " | Anomgstopkillingme: " .. sprees[hash].count.anomgstopkillingme)
            rprint(PlayerIndex, "Unfrigginbelievable: " .. sprees[hash].count.unfrigginbelievable .. " | Minutes as Last Man Standing: " .. sprees[hash].count.timeaslms)
            -- =========================================================================================================================================================================
            return false
        elseif Message == "@rank" then
            local credits = { }
            for k, _ in pairs(killstats) do
                table.insert(credits, { ["hash"] = k, ["credits"] = killstats[k].total.credits })
            end

            table.sort(credits, function(a, b) return a.credits > b.credits end)

            for k, v in ipairs(credits) do
                if hash == credits[k].hash then
                    local until_next_rank = CreditsUntilNextPromo(PlayerIndex)
                    -- =========================================================================================================================================================================
                    rprint(PlayerIndex, "You are ranked " .. k .. " out of " .. #credits .. "!")
                    rprint(PlayerIndex, "Credits: " .. killstats[hash].total.credits .. " | Rank: " .. killstats[hash].total.rank)
                    rprint(PlayerIndex, "Credits Until Next Rank: " .. until_next_rank)
                    -- =========================================================================================================================================================================
                end
            end
            return false
        elseif Message == "@medals" then
            -- =========================================================================================================================================================================
            rprint(PlayerIndex, "Any Spree: " .. medals[hash].class.sprees .. " (" .. medals[hash].count.sprees .. ") | Assistant: " .. medals[hash].class.assists .. " (" .. medals[hash].count.assists .. ") | Close Quarters: " .. medals[hash].class.closequarters .. " (" .. medals[hash].count.assists .. ")")
            rprint(PlayerIndex, "Crack Shot: " .. medals[hash].class.crackshot .. " (" .. medals[hash].count.crackshot .. ") | Downshift: " .. medals[hash].class.downshift .. " (" .. medals[hash].count.downshift .. ") | Grenadier: " .. medals[hash].class.grenadier .. " (" .. medals[hash].count.grenadier .. ")")
            rprint(PlayerIndex, "Heavy Weapons: " .. medals[hash].class.heavyweapons .. " (" .. medals[hash].count.heavyweapons .. ") | Jack of all Trades: " .. medals[hash].class.jackofalltrades .. " (" .. medals[hash].count.jackofalltrades .. ") | Mobile Asset: " .. medals[hash].class.mobileasset .. " (" .. medals[hash].count.moblieasset .. ")")
            rprint(PlayerIndex, "Multi Kill: " .. medals[hash].class.multikill .. " (" .. medals[hash].count.multikill .. ") | Sidearm: " .. medals[hash].class.sidearm .. " (" .. medals[hash].count.sidearm .. ") | Trigger Man: " .. medals[hash].class.triggerman .. " (" .. medals[hash].count.triggerman .. ")")
            -- =========================================================================================================================================================================
            return false
        end

        if t[1] == "@weapons" then
            if t[2] then
                local rcon_id = tonumber(t[2])
                if rcon_id then
                    local Player = rresolveplayer(rcon_id)
                    if Player then
                        local hash = get_var(PlayerIndex, "$hash")
                        if hash then
                            rprint(PlayerIndex, getname(Player) .. "'s Weapon Stats")
                            rprint(PlayerIndex, "Assault Rifle: " .. stats[hash].kills.assaultrifle .. " | Banshee: " .. stats[hash].kills.banshee .. " | Banshee Fuel Rod: " .. stats[hash].kills.bansheefuelrod .. " | Chain Hog: " .. stats[hash].kills.chainhog)
                            rprint(PlayerIndex, "EMP Blast: " .. extra[hash].woops.empblast .. " | Flame Thrower: " .. stats[hash].kills.flamethrower .. " | Frag Grenade: " .. stats[hash].kills.fragnade .. " | Fuel Rod: " .. stats[hash].kills.fuelrod)
                            rprint(PlayerIndex, "Ghost: " .. stats[hash].kills.ghost .. " | Melee: " .. stats[hash].kills.melee .. " | Needler: " .. stats[hash].kills.needler .. " | People Splattered: " .. stats[hash].kills.splatter)
                            rprint(PlayerIndex, "Pistol: " .. stats[hash].kills.pistol .. " | Plasma Grenade: " .. stats[hash].kills.plasmanade .. " | Plasma Pistol: " .. stats[hash].kills.plasmapistol .. " | Plasma Rifle: " .. stats[hash].kills.plasmarifle)
                            rprint(PlayerIndex, "Rocket Hog: " .. extra[hash].woops.rockethog .. " | Rocket Launcher: " .. stats[hash].kills.rocket .. " | Shotgun: " .. stats[hash].kills.shotgun .. " | Sniper Rifle: " .. stats[hash].kills.sniper)
                            rprint(PlayerIndex, "Stuck Grenade: " .. stats[hash].kills.grenadestuck .. " | Tank Machine Gun: " .. stats[hash].kills.tankmachinegun .. " | Tank Shell: " .. stats[hash].kills.tankshell .. " | Turret: " .. stats[hash].kills.turret)
                            -- =========================================================================================================================================================================
                        else
                            rprint(PlayerIndex, "Script Error! Please try again!")
                        end
                    else
                        rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats! They must be in the server!")
                    end
                else
                    rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats!")
                end
            end
            return false
        elseif t[1] == "@stats" then
            if t[2] then
                local rcon_id = tonumber(t[2])
                if rcon_id then
                    local Player = rresolveplayer(rcon_id)
                    if Player then
                        local hash = gethash(Player)
                        if hash then
                            local Player_KDR = RetrievePlayerKDR(Player)
                            local cpm = math.round(killstats[hash].total.credits / extra[hash].woops.gamesplayed, 2)
                            if cpm == 0 or cpm == nil then
                                cpm = "No credits earned"
                            end
                            local days, hours, minutes, seconds = secondsToTime(extra[hash].woops.time, 4)
                            -- =========================================================================================================================================================================
                            rprint(PlayerIndex, getname(Player) .. "'s Stats.")
                            rprint(PlayerIndex, "Kills: " .. killstats[hash].total.kills .. " | Deaths: " .. killstats[hash].total.deaths .. " | Assists: " .. killstats[hash].total.assists)
                            rprint(PlayerIndex, "KDR: " .. Player_KDR .. " | Suicides: " .. killstats[hash].total.suicides .. " | Betrays: " .. killstats[hash].total.betrays)
                            rprint(PlayerIndex, "Games Played: " .. extra[hash].woops.gamesplayed .. " | Time in Server: " .. days .. "d " .. hours .. "h " .. minutes .. "m " .. seconds .. "s")
                            rprint(PlayerIndex, "Distance Traveled: " .. math.round(extra[hash].woops.distance / 1000, 2) .. " kilometers | Credits Per Map: " .. cpm)
                            -- =========================================================================================================================================================================
                        else
                            rprint(PlayerIndex, "Script Error! Please try again!")
                        end
                    else
                        rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats! They must be in the server!")
                    end
                else
                    rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats!")
                end
            end
            return false
        elseif t[1] == "@sprees" then
            if t[2] then
                local rcon_id = tonumber(t[2])
                if rcon_id then
                    local Player = rresolveplayer(rcon_id)
                    if Player then
                        local hash = gethash(Player)
                        if hash then
                            -- =========================================================================================================================================================================
                            rprint(PlayerIndex, getname(Player) .. "'s Spree Stats.")
                            rprint(PlayerIndex, "Double Kill: " .. sprees[hash].count.double .. " | Triple Kill: " .. sprees[hash].count.triple .. " | Overkill: " .. sprees[hash].count.overkill .. " | Killtacular: " .. sprees[hash].count.killtacular)
                            rprint(PlayerIndex, "Killtrocity: " .. sprees[hash].count.killtrocity .. " | Killimanjaro " .. sprees[hash].count.killimanjaro .. " | Killtastrophe: " .. sprees[hash].count.killtastrophe .. " | Killpocalypse: " .. sprees[hash].count.killpocalypse)
                            rprint(PlayerIndex, "Killionaire: " .. sprees[hash].count.killionaire .. " | Kiling Spree " .. sprees[hash].count.killingspree .. " | Killing Frenzy: " .. sprees[hash].count.killingfrenzy .. " | Running Riot: " .. sprees[hash].count.runningriot)
                            rprint(PlayerIndex, "Rampage: " .. sprees[hash].count.rampage .. " | Untouchable: " .. sprees[hash].count.untouchable .. " | Invincible: " .. sprees[hash].count.invincible .. " | Anomgstopkillingme: " .. sprees[hash].count.anomgstopkillingme)
                            rprint(PlayerIndex, "Unfrigginbelievable: " .. sprees[hash].count.unfrigginbelievable .. " | Minutes as Last Man Standing: " .. sprees[hash].count.timeaslms)
                            -- =========================================================================================================================================================================
                        else
                            rprint(PlayerIndex, "Script Error! Please try again!")
                        end
                    else
                        rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats! They must be in the server!")
                    end
                else
                    rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats!")
                end
            end
            return false
        elseif t[1] == "@rank" then
            if t[2] then
                local rcon_id = tonumber(t[2])
                if rcon_id then
                    local Player = rresolveplayer(rcon_id)
                    if Player then
                        local hash = gethash(Player)
                        if hash then
                            local credits = { }
                            for k, _ in pairs(killstats) do
                                table.insert(credits, { ["hash"] = k, ["credits"] = killstats[k].total.credits })
                            end

                            table.sort(credits, function(a, b) return a.credits > b.credits end)

                            for k, v in ipairs(credits) do
                                if hash == credits[k].hash then
                                    local until_next_rank = CreditsUntilNextPromo(Player)
                                    if until_next_rank == nil then
                                        until_next_rank = "Unknown - " .. getname(Player) .. " is a new PlayerIndex"
                                    end
                                    -- =========================================================================================================================================================================
                                    rprint(PlayerIndex, getname(Player) .. " is ranked " .. k .. " out of " .. #credits .. "!")
                                    rprint(PlayerIndex, "Credits: " .. killstats[hash].total.credits .. " | Rank: " .. killstats[hash].total.rank)
                                    rprint(PlayerIndex, "Credits Until Next Rank: " .. until_next_rank)
                                    -- =========================================================================================================================================================================
                                end
                            end
                        else
                            rprint(PlayerIndex, "Script Error! Please try again!")
                        end
                    else
                        rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats! They must be in the server!")
                    end
                else
                    rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats!")
                end
            end
            return false
        elseif t[1] == "@medals" then
            if t[2] then
                local rcon_id = tonumber(t[2])
                if rcon_id then
                    local Player = rresolveplayer(rcon_id)
                    if Player then
                        local hash = gethash(Player)
                        if hash then
                            -- =========================================================================================================================================================================
                            rprint(PlayerIndex, getname(Player) .. "'s Medal Stats.")
                            rprint(PlayerIndex, "Any Spree: " .. medals[hash].class.sprees .. " (" .. medals[hash].count.sprees .. ") | Assistant: " .. medals[hash].class.assists .. " (" .. medals[hash].count.assists .. ") | Close Quarters: " .. medals[hash].class.closequarters .. " (" .. medals[hash].count.assists .. ")")
                            rprint(PlayerIndex, "Crack Shot: " .. medals[hash].class.crackshot .. " (" .. medals[hash].count.crackshot .. ") | Downshift: " .. medals[hash].class.downshift .. " (" .. medals[hash].count.downshift .. ") | Grenadier: " .. medals[hash].class.grenadier .. " (" .. medals[hash].count.grenadier .. ")")
                            rprint(PlayerIndex, "Heavy Weapons: " .. medals[hash].class.heavyweapons .. " (" .. medals[hash].count.heavyweapons .. ") | Jack of all Trades: " .. medals[hash].class.jackofalltrades .. " (" .. medals[hash].count.jackofalltrades .. ") | Mobile Asset: " .. medals[hash].class.mobileasset .. " (" .. medals[hash].count.moblieasset .. ")")
                            rprint(PlayerIndex, "Multi Kill: " .. medals[hash].class.multikill .. " (" .. medals[hash].count.multikill .. ") | Sidearm: " .. medals[hash].class.sidearm .. " (" .. medals[hash].count.sidearm .. ") | Trigger Man: " .. medals[hash].class.triggerman .. " (" .. medals[hash].count.triggerman .. ")")
                            -- =========================================================================================================================================================================
                        else
                            rprint(PlayerIndex, "Script Error! Please try again!")
                        end
                    else
                        rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats! They must be in the server!")
                    end
                else
                    rprint(PlayerIndex, "Please enter a number between 1 and 16 to view their stats!")
                end
            end
            return false
        end
    end
end

function OnPlayerJoin(PlayerIndex)
    -- execute_command("sv_password vm315")
    DeclearNewPlayerStats(gethash(PlayerIndex))
    kill_command_count[gethash(PlayerIndex)] = 0
    -- credit_timer = timer(60000, "CreditTimer", PlayerIndex)
    -- Update the PlayerIndex counts
    cur_players = cur_players + 1
    GetMedalClasses(PlayerIndex)
    local alreadyExists = false
    GetPlayerRank(PlayerIndex)
    jointime[gethash(PlayerIndex)] = os.time()
    xcoords[gethash(PlayerIndex)] = read_float(getplayer(PlayerIndex) + 0xF8)
    ycoords[gethash(PlayerIndex)] = read_float(getplayer(PlayerIndex) + 0xFC)
    zcoords[gethash(PlayerIndex)] = read_float(getplayer(PlayerIndex) + 0x100)
    timer(1000 * 6, "WelcomeHandler", PlayerIndex)
    local thisTeamSize = 0
    killers[PlayerIndex] = { }
    if AnnounceRank == true then
        AnnouncePlayerRank(PlayerIndex)
    end

    if table.find(hash_table, gethash(PlayerIndex), false) then
        for k, v in pairs(hash_table) do
            if v ~= getteam(PlayerIndex) then
                changeteam(PlayerIndex, true)
            end
            rprint(PlayerIndex, REJOIN_MESSAGE)
            alreadyEsists = true
            break
        end
    end

    if alreadyExists == false then
        hash_table[gethash(PlayerIndex)] = getteam(PlayerIndex)
    end
    -- 	Verify Blue Team
    if getteam(PlayerIndex) == BLUE_TEAM then
        -- 	Add one to player count (blue)
        cur_blue_count = cur_blue_count + 1
        -- 	Update Counts
        thisTeamSize = cur_blue_count
    else
        -- 	Add one to player count (red)
        cur_red_count = cur_red_count + 1
        -- 	Update Counts
        thisTeamSize = cur_red_count
    end
end	

function OnPlayerLeave(PlayerIndex)
    last_damage[PlayerIndex] = nil
    cur_players = cur_players - 1
    hash_table[gethash(PlayerIndex)] = getteam(PlayerIndex)
    kills[gethash(PlayerIndex)] = 0
    extra[gethash(PlayerIndex)].woops.time = extra[gethash(PlayerIndex)].woops.time + os.time() - jointime[gethash(PlayerIndex)]
    -- 	Verify Blue Team
    if getteam(PlayerIndex) == BLUE_TEAM then
        -- 	Take one away from player count (blue)
        cur_blue_count = cur_blue_count - 1
        -- 	Verify Red Team
    elseif getteam(PlayerIndex) == RED_TEAM then
        -- 	Take one away from player count (red)
        cur_red_count = cur_red_count - 1
    end
end

function OnPlayerDeath(PlayerIndex, KillerIndex)
    local victim = tonumber(PlayerIndex)
    local killer = tonumber(KillerIndex)
    -- Player Name --
    VictimName = get_var(PlayerIndex, "$name")
    KillerName = get_var(KillerIndex, "$name")
    -- Player Team --
    KillerTeam = get_var(KillerIndex, "$team")
    VictimTeam = get_var(PlayerIndex, "$team")
    
    -- KILLED BY SERVER --
    if (killer == -1) then  mode = 0 end
    -- FALL / DISTANCE DAMAGE
    if last_damage[PlayerIndex] == falling_damage or last_damage[PlayerIndex] == distance_damage then mode = 1 end
    -- GUARDIANS / UNKNOWN --
    if (killer == nil) then mode = 2 end
    -- KILLED BY VEHICLE --
    if (killer == 0) then  mode = 3 end
    -- KILLED BY KILLER --
    if (killer > 0) and (victim ~= killer) then mode = 4 end
    -- BETRAY / TEAM KILL --
    if (KillerTeam == VictimTeam) and (PlayerIndex ~= KillerIndex) then mode = 5 end
    -- SUICIDE --
    if tonumber(PlayerIndex) == tonumber(KillerIndex) then mode = 6 end
    
    if mode == 4 then
        local hash = gethash(killer)
        local m_object = read_dword(get_player(victim) + 0x34)
        -- Weapon Melee --
        if last_damage[PlayerIndex] == flag_melee or
            last_damage[PlayerIndex] == ball_melee or
            last_damage[PlayerIndex] == pistol_melee or
            last_damage[PlayerIndex] == needle_melee or
            last_damage[PlayerIndex] == shotgun_melee or
            last_damage[PlayerIndex] == flame_melee or
            last_damage[PlayerIndex] == sniper_melee or
            last_damage[PlayerIndex] == prifle_melee or
            last_damage[PlayerIndex] == ppistol_melee or
            last_damage[PlayerIndex] == assault_melee or
            last_damage[PlayerIndex] == rocket_melee then
            medals[hash].count.closequarters = medals[hash].count.closequarters + 1
            stats[hash].kills.melee = stats[hash].kills.melee + 1
            
        -- Grenades --
        elseif last_damage[PlayerIndex] == frag_explode then
            medals[hash].count.grenadier = medals[hash].count.grenadier + 1
            stats[hash].kills.fragnade = stats[hash].kills.fragnade + 1
        elseif last_damage[PlayerIndex] == plasma_attach then
            medals[hash].count.grenadier = medals[hash].count.grenadier + 1
            stats[hash].kills.grenadestuck = stats[hash].kills.grenadestuck + 1
        elseif last_damage[PlayerIndex] == plasma_explode then
            medals[hash].count.grenadier = medals[hash].count.grenadier + 1
            stats[hash].kills.plasmanade = stats[hash].kills.plasmanade + 1
            
        -- Vehicle Collision --
        elseif last_damage[PlayerIndex] == veh_damage then
            stats[hash].kills.splatter = stats[hash].kills.splatter + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1

        -- Vehicle Projectiles --
        elseif last_damage[PlayerIndex] == banshee_explode then
            stats[hash].kills.bansheefuelrod = stats[hash].kills.bansheefuelrod + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == banshee_bolt then
            stats[hash].kills.banshee = stats[hash].kills.banshee + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == turret_bolt then
            stats[hash].kills.turret = stats[hash].kills.turret + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == ghost_bolt then
            stats[hash].kills.ghost = stats[hash].kills.ghost + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == tank_bullet then
            stats[hash].kills.tankmachinegun = stats[hash].kills.tankmachinegun + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == tank_shell then
            stats[hash].kills.tankshell = stats[hash].kills.tankshell + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
        elseif last_damage[PlayerIndex] == chain_bullet then
            stats[hash].kills.chainhog = stats[hash].kills.chainhog + 1
            medals[hash].count.moblieasset = medals[hash].count.moblieasset + 1
            
        -- Weapon Projectiles --
        elseif last_damage[PlayerIndex] == assault_bullet then
            stats[hash].kills.assaultrifle = stats[hash].kills.assaultrifle + 1
            medals[hash].count.triggerman = medals[hash].count.triggerman + 1
        elseif last_damage[PlayerIndex] == flame_explode then
            medals[hash].count.heavyweapons = medals[hash].count.heavyweapons + 1
            stats[hash].kills.flamethrower = stats[hash].kills.flamethrower + 1
        elseif last_damage[PlayerIndex] == needle_detonate or last_damage[PlayerIndex] == needle_explode or last_damage[PlayerIndex] == needle_impact then
            medals[hash].count.triggerman = medals[hash].count.triggerman + 1
            stats[hash].kills.needler = stats[hash].kills.needler + 1
        elseif last_damage[PlayerIndex] == pistol_bullet then
            stats[hash].kills.pistol = stats[hash].kills.pistol + 1
            medals[hash].count.sidearm = medals[hash].count.sidearm + 1
        elseif last_damage[PlayerIndex] == ppistol_bolt then
            stats[hash].kills.plasmapistol = stats[hash].kills.plasmapistol + 1
            medals[hash].count.sidearm = medals[hash].count.sidearm + 1
        elseif last_damage[PlayerIndex] == ppistol_charged then
            extra[hash].woops.empblast = extra[hash].woops.empblast + 1
            medals[hash].count.jackofalltrades = medals[hash].count.jackofalltrades + 1
        elseif last_damage[PlayerIndex] == prifle_bolt then
            stats[hash].kills.plasmarifle = stats[hash].kills.plasmarifle + 1
            medals[hash].count.triggerman = medals[hash].count.triggerman + 1
        elseif last_damage[PlayerIndex] == pcannon_explode then
            medals[hash].count.heavyweapons = medals[hash].count.heavyweapons + 1
            stats[hash].kills.fuelrod = stats[hash].kills.fuelrod + 1
        elseif last_damage[PlayerIndex] == rocket_explode then
            if m_object then
                if read_byte(m_object + 0x2A0) == 1 then
                    -- obj_crouch
                    extra[hash].woops.rockethog = extra[hash].woops.rockethog + 1
                else
                    medals[hash].count.heavyweapons = medals[hash].count.heavyweapons + 1
                    stats[hash].kills.rocket = stats[hash].kills.rocket + 1
                end
            else
                medals[hash].count.heavyweapons = medals[hash].count.heavyweapons + 1
                stats[hash].kills.rocket = stats[hash].kills.rocket + 1
            end
        elseif last_damage[PlayerIndex] == shotgun_pellet then
            medals[hash].count.closequarters = medals[hash].count.closequarters + 1
            stats[hash].kills.shotgun = stats[hash].kills.shotgun + 1
        elseif last_damage[PlayerIndex] == sniper_bullet then
            medals[hash].count.crackshot = medals[hash].count.crackshot + 1
            stats[hash].kills.sniper = stats[hash].kills.sniper + 1
        elseif last_damage[PlayerIndex] == "backtap" then
            medals[hash].count.closequarters = medals[hash].count.closequarters + 1
            stats[hash].kills.melee = stats[hash].kills.melee + 1
        end
    end
    if game_started == true then
        -- 		mode 0: Killed by server
        if mode == 0 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            -- 		mode 1: Killed by fall damage
        elseif mode == 1 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            -- 		mode 2: Killed by guardians
        elseif mode == 2 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            -- 		mode 3: Killed by vehicle
        elseif mode == 3 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            -- 		mode 4: Killed by killer
        elseif mode == 4 then
            if table.find(killers[victim], killer, false) == nil then
                table.insert(killers[victim], killer)
            end
            killstats[gethash(killer)].total.kills = killstats[gethash(killer)].total.kills + 1
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            -- 		Verify Blue Team
            if getteam(killer) == BLUE_TEAM then
                changescore(killer, 15, plus)
                SendMessage(killer, "Rewarded:  +15 (cR) - Kill")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 15
            end

            if read_word(getplayer(killer) + 0x9C) == 10 then
                changescore(killer, 5, plus)
                SendMessage(killer, "Rewarded:  +5 (cR) - 10 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
            elseif read_word(getplayer(killer) + 0x9C) == 20 then
                changescore(killer, 5, plus)
                SendMessage(killer, "Rewarded:  +5 (cR) - 20 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
            elseif read_word(getplayer(killer) + 0x9C) == 30 then
                changescore(killer, 5, plus)
                SendMessage(killer, "Rewarded:  +5 (cR) - 30 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
            elseif read_word(getplayer(killer) + 0x9C) == 40 then
                changescore(killer, 5, plus)
                SendMessage(killer, "Rewarded:  +5 (cR) - 40 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
            elseif read_word(getplayer(killer) + 0x9C) == 50 then
                changescore(killer, 10, plus)
                SendMessage(killer, "Rewarded:  +10 (cR) - 50 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
            elseif read_word(getplayer(killer) + 0x9C) == 60 then
                changescore(killer, 10, plus)
                SendMessage(killer, "Rewarded:  +10 (cR) - 60 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
            elseif read_word(getplayer(killer) + 0x9C) == 70 then
                changescore(killer, 10, plus)
                SendMessage(killer, "Rewarded:  +10 (cR) - 70 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
            elseif read_word(getplayer(killer) + 0x9C) == 80 then
                changescore(killer, 10, plus)
                SendMessage(killer, "Rewarded:  +10 (cR) - 80 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
            elseif read_word(getplayer(killer) + 0x9C) == 90 then
                changescore(killer, 10, plus)
                SendMessage(killer, "Rewarded:  +10 (cR) - 90 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
            elseif read_word(getplayer(killer) + 0x9C) == 100 then
                changescore(killer, 20, plus)
                SendMessage(killer, "Rewarded:  +20 (cR) - 100 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 20
            elseif read_word(getplayer(killer) + 0x9C) > 100 then
                changescore(killer, 5, plus)
                SendMessage(killer, "Rewarded:  +5 (cR) - More then 100 Kills")
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
            end

            local hash = gethash(killer)
            if read_word(getplayer(killer) + 0x98) == 2 then
                -- if multi kill is equal to 2 then
                SendMessage(killer, "Rewarded:  +8 (cR) - Double Kill")
                changescore(killer, 8, plus)
                killstats[hash].total.credits = killstats[hash].total.credits + 8
                sprees[hash].count.double = sprees[hash].count.double + 1
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 3 then
                -- if multi kill is equal to 3 then
                SendMessage(killer, "Rewarded:  +10 (cR) - Triple Kill")
                changescore(killer, 10, plus)
                sprees[hash].count.triple = sprees[hash].count.triple + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 10
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 4 then
                -- if multi kill is equal to 4 then
                SendMessage(killer, "Rewarded:  +12 (cR) - Overkill")
                changescore(killer, 12, plus)
                sprees[hash].count.overkill = sprees[hash].count.overkill + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 12
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 5 then
                -- if multi kill is equal to 5 then
                SendMessage(killer, "Rewarded:  +14 (cR) - Killtacular")
                changescore(killer, 14, plus)
                sprees[hash].count.killtacular = sprees[hash].count.killtacular + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 14
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 6 then
                -- if multi kill is equal to 6 then
                SendMessage(killer, "Rewarded:  +16 (cR) - Killtrocity")
                changescore(killer, 16, plus)
                sprees[hash].count.killtrocity = sprees[hash].count.killtrocity + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 16
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 7 then
                -- if multi kill is equal to 7 then
                SendMessage(killer, "Rewarded:  +18 (cR) - Killimanjaro")
                changescore(killer, 18, plus)
                sprees[hash].count.killimanjaro = sprees[hash].count.killimanjaro + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 18
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 8 then
                -- if multi kill is equal to 8 then
                SendMessage(killer, "Rewarded:  +20 (cR) - Killtastrophe")
                changescore(killer, 20, plus)
                sprees[hash].count.killtastrophe = sprees[hash].count.killtastrophe + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 20
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) == 9 then
                -- if multi kill is equal to 9 then
                rprint(killer, "Rewarded:  +22 (cR) - Killpocalypse")
                changescore(killer, 22, plus)
                sprees[hash].count.killpocalypse = sprees[hash].count.killpocalypse + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 22
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            elseif read_word(getplayer(killer) + 0x98) >= 10 then
                -- if multi kill is equal to 10 or more then
                SendMessage(killer, "Rewarded:  +25 (cR) - Killionaire")
                changescore(killer, 25, plus)
                sprees[hash].count.killionaire = sprees[hash].count.killionaire + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 25
                medals[hash].count.multikill = medals[hash].count.multikill + 1
            end

            if read_word(getplayer(killer) + 0x96) == 5 then
                -- if killing spree is 5 then
                SendMessage(killer, "Rewarded:  +5 (cR) - Killing Spree")
                changescore(killer, 5, plus)
                sprees[hash].count.killingspree = sprees[hash].count.killingspree + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 5
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 10 then
                -- if killing spree is 10 then
                SendMessage(killer, "Rewarded:  +10 (cR) - Killing Frenzy")
                changescore(killer, 10, plus)
                sprees[hash].count.killingfrenzy = sprees[hash].count.killingfrenzy + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 10
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 15 then
                -- if killing spree is 15 then
                SendMessage(killer, "Rewarded:  +15 (cR) - Running Riot")
                changescore(killer, 15, plus)
                sprees[hash].count.runningriot = sprees[hash].count.runningriot + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 15
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 20 then
                -- if killing spree is 20 then
                SendMessage(killer, "Rewarded:  +20 (cR) - Rampage")
                changescore(killer, 20, plus)
                sprees[hash].count.rampage = sprees[hash].count.rampage + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 20
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 25 then
                -- if killing spree is 25 then
                SendMessage(killer, "Rewarded:  +25 (cR) - Untouchable")
                changescore(killer, 25, plus)
                sprees[hash].count.untouchable = sprees[hash].count.untouchable + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 25
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 30 then
                -- if killing spree is 30 then
                SendMessage(killer, "Rewarded:  +30 (cR) - Invincible")
                changescore(killer, 30, plus)
                sprees[hash].count.invincible = sprees[hash].count.invincible + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 30
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) == 35 then
                -- if killing spree is 35 then
                SendMessage(killer, "Rewarded:  +35 (cR) - Anomgstopkillingme")
                changescore(killer, 35, plus)
                sprees[hash].count.anomgstopkillingme = sprees[hash].count.anomgstopkillingme + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 35
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            elseif read_word(getplayer(killer) + 0x96) >= 40 and sprees % 5 == 0 then
                -- if killing spree is 40 or more (Every 5 it will say this after 40) then
                SendMessage(killer, "Rewarded:  +40 (cR) - Unfrigginbelievable")
                changescore(killer, 40, plus)
                sprees[hash].count.unfrigginbelievable = sprees[hash].count.unfrigginbelievable + 1
                killstats[hash].total.credits = killstats[hash].total.credits + 40
                medals[hash].count.sprees = medals[hash].count.sprees + 1
            end
            -- 			Revenge		
            for k, v in pairs(killers[killer]) do
                if v == victim then
                    table.remove(killers[killer], k)
                    medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                    killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
                    SendMessage(killer, "Rewarded:  +10 (cR) - Revenge")
                    changescore(killer, 10, plus)
                end
            end
            -- 			Killed from the Grave		
            if isplayerdead(killer) == true then
                medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
                SendMessage(killer, "Rewarded:  +10 (cR) - Killed from the Grave")
                changescore(killer, 10, plus)
            end
            -- 			Downshift
            if getplayer(killer) then
                if killer ~= nil then
                    if PlayerInVehicle(killer) then
                        local player_object = get_dynamic_player(killer)
                        local VehicleObj = get_object_memory(read_dword(player_object + 0x11c))
                        local seat_index = read_word(player_object + 0x2F0)
                        if (VehicleObj ~= 0) and (seat_index == 0) or (seat_index == 1) or (seat_index == 2) or (seat_index == 3) or (seat_index == 4) then
                            for i = 1, 16 do
                                if getplayer(i) then
                                    cprint("looping 16 times!", 2+8)
                                    -- local m_object = getobject(getplayerobjectid(i))
                                    -- local loopvehicleid = read_dword(m_object + 0x11C)
                                    -- local seat_index = read_word(m_object + 0x2F0)
                                    -- if kvehicleid == loopvehicleid then
                                        -- if seat_index == 0 then
                                            -- if getteam(killer) == getteam(i) then
                                                -- medals[gethash(i)].count.downshift = medals[gethash(i)].count.downshift + 1
                                                -- killstats[gethash(i)].total.credits = killstats[gethash(i)].total.credits + 5
                                                -- SendMessage(i, "Awarded: +5 (cR) - Downshift")
                                                -- changescore(i, 5, plus)
                                            -- end
                                        -- end
                                    -- end
                                end
                            end
                        end
                    end
                end
            end
            -- 			Avenge
            for i = 1, 16 do
                if getplayer(i) then
                    if i ~= victim then
                        if gethash(i) then
                            if getteam(i) == getteam(victim) then
                                avenge[gethash(i)] = gethash(killer)
                            end
                        end
                    end
                end
            end

            if avenge[gethash(killer)] == gethash(victim) then
                medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
                SendMessage(killer, "Rewarded:  +5 (cR) - Avenger")
                changescore(killer, 5, plus)
            end

            -- 			Killjoy

            if killer then
                kills[gethash(killer)] = kills[gethash(killer)] or 1
            end

            if killer and victim then
                -- Works
                if kills[gethash(victim)] ~= nil then
                    if kills[gethash(victim)] >= 5 then
                        medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                        killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
                        SendMessage(killer, "Rewarded:  +5 (cR) - Killjoy")
                        changescore(killer, 5, plus)
                    end
                end
            end
            kills[gethash(victim)] = 0

            -- 			Reload This
            local m_object = get_dynamic_player(victim)
            local reloading = read_byte(m_object + 0x2A4)
            if reloading == 5 then
                SendMessage(killer, "Rewarded:  +5 (cR) - Reload This!")
                medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 5
                changescore(killer, 5, plus)
            end
            -- 			First Strike
            kill_count = kill_count + 1

            if kill_count == 1 then
                medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
                SendMessage(killer, "Rewarded:  +10 (cR) - First Strike")
                changescore(killer, 10, plus)
            end

            timer(10, "CloseCall", killer)
            -- 		mode 5: Betrayed by killer
        elseif mode == 5 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            killstats[gethash(killer)].total.betrays = killstats[gethash(killer)].total.betrays + 1
            -- 		mode 6: Suicide
        elseif mode == 6 then
            killstats[gethash(victim)].total.deaths = killstats[gethash(victim)].total.deaths + 1
            killstats[gethash(victim)].total.suicides = killstats[gethash(victim)].total.suicides + 1
            changescore(victim, 10, minus)
        end

        -- 		mode 4: Killed by killer
        if mode == 4 then
            GetPlayerRank(killer)
            timer(10, "LevelUp", killer)
        end
    end
    last_damage[PlayerIndex] = 0
end

function getobject(PlayerIndex)
	local m_player = get_player(PlayerIndex)
	if m_player ~= 0 then
		local ObjectId = read_dword(m_player + 0x24)
		return ObjectId
	end
	return nil
end

function OnDamageApplication(PlayerIndex, CauserIndex, MetaID, Damage, HitString, Backtap)
    if game_started == true then
        last_damage[PlayerIndex] = MetaID
    end
end

function OnTick()
    for i = 1,16 do
        if player_present(i) then
            GivePlayerMedals(i)
            local player_object = get_dynamic_player(i)
            local x, y, z = read_vector3d(player_object + 0x5C)
            if xcoords[gethash(i)] then
                local x_dist = x - xcoords[gethash(i)]
                local y_dist = y - ycoords[gethash(i)]
                local z_dist = z - zcoords[gethash(i)]
                local dist = math.sqrt(x_dist ^ 2 + y_dist ^ 2 + z_dist ^ 2)
                extra[gethash(i)].woops.distance = extra[gethash(i)].woops.distance + dist
            end
            xcoords[gethash(i)] = x
            ycoords[gethash(i)] = y
            zcoords[gethash(i)] = z
        end
    end
end

-- Directory to store Data (Stats.txt, KillStats.txt, Sprees.txt, Medals.txt, Extra.txt, CompletedMedals.txt)
data_folder = 'sapp\\'

function getprofilepath()
    local folder_directory = data_folder
    return folder_directory
end

function SaveTableData(t, filename)
    local dir = getprofilepath()
    local file = io.open(dir .. filename, "w")
	local spaces = 0
	local function tab()
		local str = ""
		for i = 1,spaces do
			str = str .. " "
		end
		return str
	end
	local function format(t)
		spaces = spaces + 4
		local str = "{ "
		for k,v in opairs(t) do
			-- Key datatypes
			if type(k) == "string" then
				k = string.format("%q", k)
			elseif k == math.inf then
				k = "1 / 0"
			end
			k = tostring(k)
			-- Value datatypes
			if type(v) == "string" then
				v = string.format("%q", v)
			elseif v == math.inf then
				v = "1 / 0"
			end
			if type(v) == "table" then
				if tablelen(v) > 0 then
					str = str .. "\n" .. tab() .. "[" .. k .. "] = " .. format(v) .. ","
				else
					str = str .. "\n" .. tab() .. "[" .. k .. "] = {},"
				end
			else
				str = str .. "\n" .. tab() .. "[" .. k .. "] = " .. tostring(v) .. ","
			end
		end
		spaces = spaces - 4
		return string.sub(str, 1, string.len(str) - 1) .. "\n" .. tab() .. "}"
	end
	file:write("return " .. format(t))
	file:close()
end

function opairs(t)
	local keys = {}
	for k,v in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys,
	function(a,b)
		if type(a) == "number" and type(b) == "number" then
			return a < b
		end
		an = string.lower(tostring(a))
		bn = string.lower(tostring(b))
		if an ~= bn then
			return an < bn
		else
			return tostring(a) < tostring(b)
		end
	end)
	local count = 1
	return function()
		if unpack(keys) then
			local key = keys[count]
			local value = t[key]
			count = count + 1
			return key,value
		end
	end
end

function spaces(n, delimiter)
	delimiter = delimiter or ""
	local str = ""
	for i = 1, n do
		if i == math.floor(n / 2) then
			str = str .. delimiter
		end
		str = str .. " "
	end
	return str
end

function LoadTableData(filename)
    local dir = getprofilepath()
	local file = loadfile(dir .. filename)
	if file then
		return file() or {}
	end
	return {}
end

function tablelen(t)
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
end

function adjustedtimestamp()
    local strMonth = os.date("%m")
    local strYear = os.date("%Y")
    local strMin = os.date("%M")
    local strSec = os.date("%S")
    local intDay = tonumber(os.date("%d"))
    local intHour = tonumber(os.date("%H"))
    if intHour < 7 then
        local intDiff = 7 - intHour
        intHour = 24 - intDiff
        intDay = intDay - 1
    elseif intHour >= 7 then
        intHour = intHour - 7
    end
    local strMonthFinal = string.format("%02.0f", strMonth)
    local strYearFinal = string.format("%04.0f", strYear)
    local strMinFinal = string.format("%02.0f", strMin)
    local strSecFinal = string.format("%02.0f", strSec)
    local intDayFinal = string.format("%02.0f", intDay)
    local intHourFinal = string.format("%02.0f", intHour)
    local temp = "[" .. strMonthFinal .. "/" .. intDayFinal .. "/" .. strYearFinal .. " " .. intHourFinal .. ":" .. strMinFinal .. ":" .. strSecFinal .. "]"
    local timestamp = tostring(temp)
    return timestamp
end


function isplayerdead(PlayerIndex)

    local m_objectId = getplayerobjectid(PlayerIndex)
    if m_objectId then
        local m_object = getobject(m_objectId)
        if m_object then
            return false
        else
            return true
        end
    end
end

function isplayerinvis(PlayerIndex)

    if PlayerIndex ~= nil then
        local m_playerObjId = read_dword(getplayer(PlayerIndex) + 0x34)
        local m_object = getobject(m_playerObjId)
        local obj_invis_scale = read_float(m_object + 0x37C)
        if obj_invis_scale == 0 then
            return false
        else
            return true
        end
    end
end

function CreditTimer(id, count, PlayerIndex)
    if game_started == true then
        if getplayer(PlayerIndex) then
            SendMessage(PlayerIndex, "Rewarded:  +15 (cR) - 1 Minute in Server")
            changescore(PlayerIndex, 15, plus)
            if killstats[gethash(PlayerIndex)].total.credits ~= nil then
                killstats[gethash(PlayerIndex)].total.credits = killstats[gethash(PlayerIndex)].total.credits + 15
            else
                killstats[gethash(PlayerIndex)].total.credits = 15
            end
        end
        return true
    else
        return false
    end
end

function AssistDelay(id, count)

    for i = 1, 16 do
        if getplayer(i) then
            if gethash(i) then
                if read_word(getplayer(i) + 0xA4) ~= 0 then
                    killstats[gethash(i)].total.assists = killstats[gethash(i)].total.assists + read_word(getplayer(i) + 0xA4)
                    medals[gethash(i)].count.assists = medals[gethash(i)].count.assists + read_word(getplayer(i) + 0xA4)
                    if (read_word(getplayer(i) + 0xA4) * 3) ~= 0 then
                        killstats[gethash(i)].total.credits = killstats[gethash(i)].total.credits +(read_word(getplayer(i) + 0xA4) * 3)
                        changescore(i,(read_word(getplayer(i) + 0xA4) * 3), plus)
                    end
                    if read_word(getplayer(i) + 0xA4) == 1 then
                        SendMessage(i, "Awarded: +" ..(read_word(getplayer(i) + 0xA4) * 3) .. " (cR) - " .. read_word(getplayer(i) + 0xA4) .. " Assist")
                    else
                        SendMessage(i, "Awarded: +" ..(read_word(getplayer(i) + 0xA4) * 3) .. " (cR) - " .. read_word(getplayer(i) + 0xA4) .. " Assists")
                    end
                end
            end
        end
    end
end

function getplayerobjectid(PlayerIndex)
    local player_object = get_dynamic_player(PlayerIndex)
    local weaponId = read_dword(player_object + 0x118)
    if weaponId ~= 0 then
        local m_weapon = read_dword(player_object + 0x2F8)
        return m_weapon
    end
end

function CloseCall(id, count, killer)
    -- Cleared

    if getplayer(killer) then
        if killer ~= nil then
            local objectid = getplayerobjectid(killer)
            if objectid ~= nil then
                local m_object = getobject(objectid)
                local shields = read_float(m_object + 0xE4)
                local health = read_float(m_object + 0xE0)
                if shields ~= nil then
                    if shields == 0 then
                        if health then
                            if health ~= 1 then
                                medals[gethash(killer)].count.jackofalltrades = medals[gethash(killer)].count.jackofalltrades + 1
                                killstats[gethash(killer)].total.credits = killstats[gethash(killer)].total.credits + 10
                                SendMessage(killer, "Rewarded:  +10 (cR) - Close Call")
                                changescore(killer, 10, plus)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Rounds the number
function round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function OpenFiles()
    stats = LoadTableData("Stats.txt")
    killstats = LoadTableData("KillStats.txt")
    sprees = LoadTableData("Sprees.txt")
    medals = LoadTableData("Medals.txt")
    extra = LoadTableData("Extra.txt")
    done = LoadTableData("CompletedMedals.txt")
end

function RetrievePlayerKDR(PlayerIndex)
    local Player_KDR = nil
    if killstats[gethash(PlayerIndex)].total.kills ~= 0 then
        if killstats[gethash(PlayerIndex)].total.deaths ~= 0 then
            local kdr = killstats[gethash(PlayerIndex)].total.kills / killstats[gethash(PlayerIndex)].total.deaths
            Player_KDR = math.round(kdr, 2)
        else
            Player_KDR = "No Deaths"
        end
    else
        Player_KDR = "No Kills"
    end

    return Player_KDR
end

function DeclearNewPlayerStats(hash)
    if stats[hash] == nil then
        stats[hash] = { }
        stats[hash].kills = { }
        stats[hash].kills.melee = 0
        stats[hash].kills.fragnade = 0
        stats[hash].kills.plasmanade = 0
        stats[hash].kills.grenadestuck = 0
        stats[hash].kills.sniper = 0
        stats[hash].kills.shotgun = 0
        stats[hash].kills.rocket = 0
        stats[hash].kills.fuelrod = 0
        stats[hash].kills.plasmarifle = 0
        stats[hash].kills.plasmapistol = 0
        stats[hash].kills.pistol = 0
        stats[hash].kills.needler = 0
        stats[hash].kills.flamethrower = 0
        stats[hash].kills.flagmelee = 0
        stats[hash].kills.oddballmelee = 0
        stats[hash].kills.assaultrifle = 0
        stats[hash].kills.chainhog = 0
        stats[hash].kills.tankshell = 0
        stats[hash].kills.tankmachinegun = 0
        stats[hash].kills.ghost = 0
        stats[hash].kills.turret = 0
        stats[hash].kills.bansheefuelrod = 0
        stats[hash].kills.banshee = 0
        stats[hash].kills.splatter = 0
    end

    if killstats[hash] == nil then
        killstats[hash] = { }
        killstats[hash].total = { }
        killstats[hash].total.kills = 0
        killstats[hash].total.deaths = 0
        killstats[hash].total.assists = 0
        killstats[hash].total.suicides = 0
        killstats[hash].total.betrays = 0
        killstats[hash].total.credits = 0
        killstats[hash].total.rank = 0
    end

    if sprees[hash] == nil then
        sprees[hash] = { }
        sprees[hash].count = { }
        sprees[hash].count.double = 0
        sprees[hash].count.triple = 0
        sprees[hash].count.overkill = 0
        sprees[hash].count.killtacular = 0
        sprees[hash].count.killtrocity = 0
        sprees[hash].count.killimanjaro = 0
        sprees[hash].count.killtastrophe = 0
        sprees[hash].count.killpocalypse = 0
        sprees[hash].count.killionaire = 0
        sprees[hash].count.killingspree = 0
        sprees[hash].count.killingfrenzy = 0
        sprees[hash].count.runningriot = 0
        sprees[hash].count.rampage = 0
        sprees[hash].count.untouchable = 0
        sprees[hash].count.invincible = 0
        sprees[hash].count.anomgstopkillingme = 0
        sprees[hash].count.unfrigginbelievable = 0
        sprees[hash].count.timeaslms = 0
    end

    if medals[hash] == nil then
        medals[hash] = { }
        medals[hash].count = { }
        medals[hash].class = { }
        medals[hash].count.sprees = 0
        medals[hash].class.sprees = "Iron"
        medals[hash].count.assists = 0
        medals[hash].class.assists = "Iron"
        medals[hash].count.closequarters = 0
        medals[hash].class.closequarters = "Iron"
        medals[hash].count.crackshot = 0
        medals[hash].class.crackshot = "Iron"
        medals[hash].count.downshift = 0
        medals[hash].class.downshift = "Iron"
        medals[hash].count.grenadier = 0
        medals[hash].class.grenadier = "Iron"
        medals[hash].count.heavyweapons = 0
        medals[hash].class.heavyweapons = "Iron"
        medals[hash].count.jackofalltrades = 0
        medals[hash].class.jackofalltrades = "Iron"
        medals[hash].count.moblieasset = 0
        medals[hash].class.mobileasset = "Iron"
        medals[hash].count.multikill = 0
        medals[hash].class.multikill = "Iron"
        medals[hash].count.sidearm = 0
        medals[hash].class.sidearm = "Iron"
        medals[hash].count.triggerman = 0
        medals[hash].class.triggerman = "Iron"
    end

    if extra[hash] == nil then
        extra[hash] = { }
        extra[hash].woops = { }
        extra[hash].woops.rockethog = 0
        extra[hash].woops.falldamage = 0
        extra[hash].woops.empblast = 0
        extra[hash].woops.gamesplayed = 0
        extra[hash].woops.time = 0
        extra[hash].woops.distance = 0
    end

    if done[hash] == nil then
        done[hash] = { }
        done[hash].medal = { }
        done[hash].medal.sprees = "False"
        done[hash].medal.assists = "False"
        done[hash].medal.closequarters = "False"
        done[hash].medal.crackshot = "False"
        done[hash].medal.downshift = "False"
        done[hash].medal.grenadier = "False"
        done[hash].medal.heavyweapons = "False"
        done[hash].medal.jackofalltrades = "False"
        done[hash].medal.mobileasset = "False"
        done[hash].medal.multikill = "False"
        done[hash].medal.sidearm = "False"
        done[hash].medal.triggerman = "False"
    end
end

function AnnouncePlayerRank(PlayerIndex)
    local rank = nil
    local total = nil
    local hash = get_var(PlayerIndex, "$hash")

    local credits = { }
    for k, _ in pairs(killstats) do
        table.insert(credits, { ["hash"] = k, ["credits"] = killstats[k].total.credits })
    end

    table.sort(credits, function(a, b) return a.credits > b.credits end)

    for k, v in ipairs(credits) do
        if hash == credits[k].hash then
            rank = k
            total = #credits
            string = "Server Statistics: You are currently ranked " .. rank .. " out of " .. total .. "."
        end
    end
    return rprint(PlayerIndex, string)
end
	
function table.find(t, v, case)

    if case == nil then case = true end

    for k, val in pairs(t) do
        if case then
            if v == val then
                return k
            end
        else
            if string.lower(v) == string.lower(val) then
                return k
            end
        end
    end
end

function math.round(input, precision)
    return math.floor(input *(10 ^ precision) + 0.5) /(10 ^ precision)
end

function LevelUp(killer)

    local hash = gethash(killer)

    killstats[hash].total.rank = killstats[hash].total.rank or "Recruit"
    killstats[hash].total.credits = killstats[hash].total.credits or 0

    if killstats[hash].total.rank ~= nil and killstats[hash].total.credits ~= 0 then
        if killstats[hash].total.rank == "Recruit" and killstats[hash].total.credits > 7500 then
            killstats[hash].total.rank = "Private"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Private" and killstats[hash].total.credits > 10000 then
            killstats[hash].total.rank = "Corporal"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Corporal" and killstats[hash].total.credits > 15000 then
            killstats[hash].total.rank = "Sergeant"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Sergeant" and killstats[hash].total.credits > 20000 then
            killstats[hash].total.rank = "Sergeant Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Sergeant Grade 1" and killstats[hash].total.credits > 26250 then
            killstats[hash].total.rank = "Sergeant Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Sergeant Grade 2" and killstats[hash].total.credits > 32500 then
            killstats[hash].total.rank = "Warrant Officer"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Warrant Officer" and killstats[hash].total.credits > 45000 then
            killstats[hash].total.rank = "Warrant Officer Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Warrant Officer Grade 1" and killstats[hash].total.credits > 78000 then
            killstats[hash].total.rank = "Warrant Officer Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Warrant Officer Grade 2" and killstats[hash].total.credits > 111000 then
            killstats[hash].total.rank = "Warrant Officer Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Warrant Officer Grade 3" and killstats[hash].total.credits > 144000 then
            killstats[hash].total.rank = "Captain"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Captain" and killstats[hash].total.credits > 210000 then
            killstats[hash].total.rank = "Captain Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Captain Grade 1" and killstats[hash].total.credits > 233000 then
            killstats[hash].total.rank = "Captain Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Captain Grade 2" and killstats[hash].total.credits > 256000 then
            killstats[hash].total.rank = "Captain Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Captain Grade 3" and killstats[hash].total.credits > 279000 then
            killstats[hash].total.rank = "Major"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Major" and killstats[hash].total.credits > 325000 then
            killstats[hash].total.rank = "Major Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Major Grade 1" and killstats[hash].total.credits > 350000 then
            killstats[hash].total.rank = "Major Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Major Grade 2" and killstats[hash].total.credits > 375000 then
            killstats[hash].total.rank = "Major Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Major Grade 3" and killstats[hash].total.credits > 400000 then
            killstats[hash].total.rank = "Lt. Colonel"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Lt. Colonel" and killstats[hash].total.credits > 450000 then
            killstats[hash].total.rank = "Lt. Colonel Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Lt. Colonel Grade 1" and killstats[hash].total.credits > 480000 then
            killstats[hash].total.rank = "Lt. Colonel Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Lt. Colonel Grade 2" and killstats[hash].total.credits > 510000 then
            killstats[hash].total.rank = "Lt. Colonel Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Lt. Colonel Grade 3" and killstats[hash].total.credits > 540000 then
            killstats[hash].total.rank = "Commander"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Commander" and killstats[hash].total.credits > 600000 then
            killstats[hash].total.rank = "Commander Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Commander Grade 1" and killstats[hash].total.credits > 650000 then
            killstats[hash].total.rank = "Commander Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Commander Grade 2" and killstats[hash].total.credits > 700000 then
            killstats[hash].total.rank = "Commander Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Commander Grade 3" and illstats[hash].total.credits > 750000 then
            killstats[hash].total.rank = "Colonel"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Colonel" and killstats[hash].total.credits > 850000 then
            killstats[hash].total.rank = "Colonel Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Colonel Grade 1" and killstats[hash].total.credits > 960000 then
            killstats[hash].total.rank = "Colonel Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Colonel Grade 2" and killstats[hash].total.credits > 1070000 then
            killstats[hash].total.rank = "Colonel Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Colonel Grade 3" and killstats[hash].total.credits > 1180000 then
            killstats[hash].total.rank = "Brigadier"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Brigadier" and killstats[hash].total.credits > 1400000 then
            killstats[hash].total.rank = "Brigadier Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Brigadier Grade 1" and killstats[hash].total.credits > 1520000 then
            killstats[hash].total.rank = "Brigadier Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Brigadier Grade 2" and killstats[hash].total.credits > 1640000 then
            killstats[hash].total.rank = "Brigadier Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Brigadier Grade 3" and killstats[hash].total.credits > 1760000 then
            killstats[hash].total.rank = "General"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "General" and killstats[hash].total.credits > 2000000 then
            killstats[hash].total.rank = "General Grade 1"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "General Grade 1" and killstats[hash].total.credits > 2200000 then
            killstats[hash].total.rank = "General Grade 2"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "General Grade 2" and killstats[hash].total.credits > 2350000 then
            killstats[hash].total.rank = "General Grade 3"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "General Grade 3" and killstats[hash].total.credits > 2500000 then
            killstats[hash].total.rank = "General Grade 4"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "General Grade 4" and killstats[hash].total.credits > 2650000 then
            killstats[hash].total.rank = "Field Marshall"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Field Marshall" and killstats[hash].total.credits > 3000000 then
            killstats[hash].total.rank = "Hero"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Hero" and killstats[hash].total.credits > 3700000 then
            killstats[hash].total.rank = "Legend"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Legend" and killstats[hash].total.credits > 4600000 then
            killstats[hash].total.rank = "Mythic"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Mythic" and killstats[hash].total.credits > 5650000 then
            killstats[hash].total.rank = "Noble"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Noble" and killstats[hash].total.credits > 7000000 then
            killstats[hash].total.rank = "Eclipse"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Eclipse" and killstats[hash].total.credits > 8500000 then
            killstats[hash].total.rank = "Nova"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Nova" and killstats[hash].total.credits > 11000000 then
            killstats[hash].total.rank = "Forerunner"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Forerunner" and killstats[hash].total.credits > 13000000 then
            killstats[hash].total.rank = "Reclaimer"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        elseif killstats[hash].total.rank == "Reclaimer" and killstats[hash].total.credits > 16500000 then
            killstats[hash].total.rank = "Inheritor"
            say(getname(killer) .. " is now a " .. killstats[hash].total.rank .. "!")
        end
    end
end

function GivePlayerMedals(PlayerIndex)

    local hash = get_var(PlayerIndex, "$hash")
    -- Get the PlayerIndex's hash.
    if hash then
        if done[hash].medal.sprees == "False" then
            if medals[hash].class.sprees == "Iron" and medals[hash].count.sprees >= 5 then
                -- If the class is iron and the count is more then 5,
                medals[hash].class.sprees = "Bronze"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.sprees == "Bronze" and medals[hash].count.sprees >= 50 then
                -- If the class is bronze and the count is more then 50.
                medals[hash].class.sprees = "Silver"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree Bronze!")
                -- Tell them what they earned.
            elseif medals[hash].class.sprees == "Silver" and medals[hash].count.sprees >= 250 then
                -- If the class is silver and the clount is more then 250.
                medals[hash].class.sprees = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.sprees == "Gold" and medals[hash].count.sprees >= 1000 then
                -- If the class is gold and the count is more then 1000.
                medals[hash].class.sprees = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Any Spree : Gold")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.sprees == "Onyx" and medals[hash].count.sprees >= 4000 then
                -- If the class is onyx and the count is more then 4000.
                medals[hash].class.sprees = "MAX"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 2000
                rprint(PlayerIndex, "Rewarded:  +2000 cR - Any Spree : Onyx")
                changescore(PlayerIndex, 2000, plus)
            elseif medals[hash].class.sprees == "MAX" and medals[hash].count.sprees == 10000 then
                -- if the class is max and the count is 10000.
                say(getname(PlayerIndex) .. " has earned a medal : Any Spree MAX!")
                -- Tell them what they have earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 3000
                rprint(PlayerIndex, "Rewarded:  +3000 cR - Any Spree : MAX")
                changescore(PlayerIndex, 3000, plus)
                done[hash].medal.sprees = "True"
            end
        end

        if done[hash].medal.assists == "False" then
            if medals[hash].class.assists == "Iron" and medals[hash].count.assists >= 50 then
                -- If the class is iron and the count is more then 50.
                medals[hash].class.assists = "Bronze"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.assists == "Bronze" and medals[hash].count.assists >= 250 then
                -- If the class is bronze and the count is more then 250.
                medals[hash].class.assists = "Silver"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant Bronze!")
                -- Tell them what they earned.
            elseif medals[hash].class.assists == "Silver" and medals[hash].count.assists >= 1000 then
                -- If the class is silver and the count is more then 1000.
                medals[hash].class.assists = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.assists == "Gold" and medals[hash].count.assists >= 4000 then
                -- If the class is gold and the count is more then 4000.
                medals[hash].class.assists = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Assistant : Gold")
                changescore(PlayerIndex, 1500, plus)
            elseif medals[hash].class.assists == "Onyx" and medals[hash].count.assists >= 8000 then
                -- If the class is onyx and the count is more then 8000.
                medals[hash].class.assists = "MAX"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 2500
                rprint(PlayerIndex, "Rewarded:  +2500 cR - Assistant : Onyx")
                changescore(PlayerIndex, 2500, plus)
            elseif medals[hash].class.assists == "MAX" and medals[hash].count.assists == 20000 then
                -- If the class is max and the count is 20000.
                say(getname(PlayerIndex) .. " has earned a medal : Assistant MAX!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 3500
                rprint(PlayerIndex, "Rewarded:  +3500 cR - Assistant : MAX")
                changescore(PlayerIndex, 3500, plus)
                done[hash].medal.assists = "True"
            end
        end

        if done[hash].medal.closequarters == "False" then
            if medals[hash].class.closequarters == "Iron" and medals[hash].count.closequarters >= 50 then
                -- If the class is iron and the count is more then 50.
                medals[hash].class.closequarters = "Bronze"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.closequarters == "Bronze" and medals[hash].count.closequarters >= 125 then
                -- If the class is bronze and the count is more then 125.
                medals[hash].class.closequarters = "Silver"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters Bronze!")
                -- Tell them what they earned.
            elseif medals[hash].class.closequarters == "Silver" and medals[hash].count.closequarters >= 400 then
                -- If the class is silver and the count is more then 400.
                medals[hash].class.closequarters = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.closequarters == "Gold" and medals[hash].count.closequarters >= 1600 then
                -- If the class is gold and the count is more then 1600.
                medals[hash].class.closequarters = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 750
                rprint(PlayerIndex, "Rewarded:  +750 cR - Close Quarters : Gold")
                changescore(PlayerIndex, 750, plus)
            elseif medals[hash].class.closequarters == "Onyx" and medals[hash].count.closequarters >= 4000 then
                -- If the class is onyx and the count is more then 4000.
                medals[hash].class.closequarters = "MAX"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Close Quarters : Onyx")
                changescore(PlayerIndex, 1500, plus)
            elseif medals[hash].class.closequarters == "MAX" and medals[hash].count.closequarters == 8000 then
                -- If the class is max and the count is 8000.
                say(getname(PlayerIndex) .. " has earned a medal : Close Quarters MAX!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 2250
                rprint(PlayerIndex, "2250 cR - Close Quarters : MAX")
                changescore(PlayerIndex, 2250, plus)
                done[hash].medal.closequarters = "True"
            end
        end

        if done[hash].medal.crackshot == "False" then
            if medals[hash].class.crackshot == "Iron" and medals[hash].count.crackshot >= 100 then
                -- If the class is iron and the count is more then 100 .
                medals[hash].class.crackshot = "Bronze"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.crackshot == "Bronze" and medals[hash].count.crackshot >= 500 then
                -- If the class is bronze and the count is more then 500.
                medals[hash].class.crackshot = "Silver"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot Bronze!")
                -- Tell them what they earned.
            elseif medals[hash].class.crackshot == "Silver" and medals[hash].count.crackshot >= 4000 then
                -- If the class is silver and the count is more then 4000.
                medals[hash].class.crackshot = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.crackshot == "Gold" and medals[hash].count.crackshot >= 10000 then
                -- If the class is gold and the count is more then 10000.
                medals[hash].class.crackshot = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Crack Shot : Gold")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.crackshot == "Onyx" and medals[hash].count.crackshot >= 20000 then
                -- If the class is onyx and the count is more then 20000.
                medals[hash].class.crackshot = "MAX"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 2000
                rprint(PlayerIndex, "Rewarded:  +2000 cR - Crack Shot : Onyx")
                changescore(PlayerIndex, 2000, plus)
            elseif medals[hash].class.crackshot == "MAX" and medals[hash].count.crackshot == 32000 then
                -- If the class is max and the count is 32000.
                say(getname(PlayerIndex) .. " has earned a medal : Crack Shot MAX!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 3000
                rprint(PlayerIndex, "Rewarded:  +3000 cR - Crack Shot : MAX")
                changescore(PlayerIndex, 3000, plus)
                done[hash].medal.crackshot = "True"
            end
        end

        if done[hash].medal.downshift == "False" then
            if medals[hash].class.downshift == "Iron" and medals[hash].count.downshift >= 5 then
                -- If the class is iron and count is more then 5.
                medals[hash].class.downshift = "Bronze"
                -- Level it up.
                say(getnamye(PlayerIndex) .. " has earned a medal : Downshift Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.downshift == "Bronze" and medals[hash].count.downshift >= 50 then
                -- If the class is bronze and count is more then 50.
                medals[hash].class.downshift = "Silver"
                -- Level it up
                say(getname(PlayerIndex) .. " has earned a medal : Downshift Bronze!")
                -- Tell them what the earned.
            elseif medals[hash].class.downshift == "Silver" and medals[hash].count.downshift >= 750 then
                -- If the class is silver and count is more then 750.
                medals[hash].class.downshift = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Downshift Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.downshift == "Gold" and medals[hash].count.downshift >= 4000 then
                -- If the class is gold and count is more then 4000.
                medals[hash].class.downshift = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Downshift Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 500
                rprint(PlayerIndex, "Rewarded:  +500 cR - Downshift : Gold")
                changescore(PlayerIndex, 500, plus)
            elseif medals[hash].class.downshift == "Onyx" and medals[hash].count.downshift >= 8000 then
                -- If the class is onyx and count is more then 8000.
                medals[hash].class.downshift = "MAX"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Downshift Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Downshift : Onyx")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.downshift == "MAX" and medals[hash].count.downshift == 20000 then
                -- If the class is max and count is 20000.
                say(getname(PlayerIndex) .. " has earned a medal : Downshift MAX!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Downshift : MAX")
                changescore(PlayerIndex, 1500, plus)
                done[hash].medal.downshift = "True"
            end
        end

        if done[hash].medal.grenadier == "False" then
            if medals[hash].class.grenadier == "Iron" and medals[hash].count.grenadier >= 25 then
                -- If the class is iron and count is more then 25.
                medals[hash].class.grenadier = "Bronze"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier Iron!")
                -- Tell them what they earned.
            elseif medals[hash].class.grenadier == "Bronze" and medals[hash].count.grenadier >= 125 then
                -- If the class is bronze and count is more then 125.
                medals[hash].class.grenadier = "Silver"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier Bronze!")
                -- Tell them what they earned.
            elseif medals[hash].class.grenadier == "Silver" and medals[hash].count.grenadier >= 500 then
                -- If the class is silver and count is more then 500.
                medals[hash].class.grenadier = "Gold"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier Silver!")
                -- Tell them what they earned.
            elseif medals[hash].class.grenadier == "Gold" and medals[hash].count.grenadier >= 4000 then
                -- If the class is gold and count is more then 4000.
                medals[hash].class.grenadier = "Onyx"
                -- Level it up.
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier Gold!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 750
                rprint(PlayerIndex, "Rewarded:  +750 cR - Grenadier : Gold")
                changescore(PlayerIndex, 750, plus)
            elseif medals[hash].class.grenadier == "Onyx" and medals[hash].count.grenadier >= 8000 then
                -- If the class is onyx and count is more then 8000.
                medals[hash].class.grenadier = "MAX"
                -- Level it up
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier Onyx!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Grenadier : Onyx")
                changescore(PlayerIndex, 1500, plus)
            elseif medals[hash].class.grenadier == "MAX" and medals[hash].count.grenadier == 14000 then
                -- If the class is max and count is 14000.
                say(getname(PlayerIndex) .. " has earned a medal : Grenadier MAX!")
                -- Tell them what they earned.
                killstats[hash].total.credits = killstats[hash].total.credits + 2250
                rprint(PlayerIndex, "Rewarded:  +2250 cR - Grenadier : MAX")
                changescore(PlayerIndex, 2250, plus)
                done[hash].medal.grenadier = "True"
            end
        end

        if done[hash].medal.heavyweapons == "False" then
            if medals[hash].class.heavyweapons == "Iron" and medals[hash].count.heavyweapons >= 25 then
                medals[hash].class.heavyweapons = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon Iron!")
            elseif medals[hash].class.heavyweapons == "Bronze" and medals[hash].count.heavyweapons >= 150 then
                medals[hash].class.heavyweapons = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon Bronze!")
            elseif medals[hash].class.heavyweapons == "Silver" and medals[hash].count.heavyweapons >= 750 then
                medals[hash].class.heavyweapons = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon Silver!")
            elseif medals[hash].class.heavyweapons == "Gold" and medals[hash].count.heavyweapons >= 3000 then
                medals[hash].class.heavyweapons = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 500
                rprint(PlayerIndex, "Rewarded:  +500 cR - Heavy Weapon : Gold")
                changescore(PlayerIndex, 500, plus)
            elseif medals[hash].class.heavyweapons == "Onyx" and medals[hash].count.heavyweapons >= 7000 then
                medals[hash].class.heavyweapons = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Heavy Weapon : Onyx")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.heavyweapons == "MAX" and medals[hash].count.heavyweapons == 14000 then
                say(getname(PlayerIndex) .. " has earned a medal : Heavy Weapon MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Heavy Weapon : MAX")
                changescore(PlayerIndex, 1500, plus)
                done[hash].medal.heavyweapons = "True"
            end
        end

        if done[hash].medal.jackofalltrades == "False" then
            if medals[hash].class.jackofalltrades == "Iron" and medals[hash].count.jackofalltrades >= 50 then
                -- Create the jackofalltrades count table.
                medals[hash].class.jackofalltrades = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades Iron!")
            elseif medals[hash].class.jackofalltrades == "Bronze" and medals[hash].count.jackofalltrades >= 125 then
                medals[hash].class.jackofalltrades = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades Bronze!")
            elseif medals[hash].class.jackofalltrades == "Silver" and medals[hash].count.jackofalltrades >= 400 then
                medals[hash].class.jackofalltrades = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades Silver!")
            elseif medals[hash].class.jackofalltrades == "Gold" and medals[hash].count.jackofalltrades >= 1600 then
                medals[hash].class.jackofalltrades = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 500
                rprint(PlayerIndex, "Rewarded:  +500 cR - Jack of all Trades : Gold")
                changescore(PlayerIndex, 500, plus)
            elseif medals[hash].class.jackofalltrades == "Onyx" and medals[hash].count.jackofalltrades >= 4800 then
                medals[hash].class.jackofalltrades = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Jack of all Trades : Onyx")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.jackofalltrades == "MAX" and medals[hash].count.jackofalltrades == 9600 then
                say(getname(PlayerIndex) .. " has earned a medal : Jack of all Trades MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Jack of all Trades : MAX")
                changescore(PlayerIndex, 1500, plus)
                done[hash].medal.jackofalltrades = "True"
            end
        end

        if done[hash].medal.mobileasset == "False" then
            if medals[hash].class.mobileasset == "Iron" and medals[hash].count.moblieasset >= 25 then
                medals[hash].class.mobileasset = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset Iron!")
            elseif medals[hash].class.mobileasset == "Bronze" and medals[hash].count.moblieasset >= 125 then
                medals[hash].class.mobileasset = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset Bronze!")
            elseif medals[hash].class.mobileasset == "Silver" and medals[hash].count.moblieasset >= 500 then
                medals[hash].class.mobileasset = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset Silver!")
            elseif medals[hash].class.mobileasset == "Gold" and medals[hash].count.moblieasset >= 4000 then
                medals[hash].class.mobileasset = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 750
                rprint(PlayerIndex, "Rewarded:  +750 cR - Mobile Asset : Gold")
                changescore(PlayerIndex, 750, plus)
            elseif medals[hash].class.mobileasset == "Onyx" and medals[hash].count.moblieasset >= 8000 then
                medals[hash].class.mobileasset = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Mobile Asset : Onyx")
                changescore(PlayerIndex, 1500, plus)
            elseif medals[hash].class.mobileasset == "MAX" and medals[hash].count.moblieasset == 14000 then
                say(getname(PlayerIndex) .. " has earned a medal : Mobile Asset MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 2250
                rprint(PlayerIndex, "Rewarded:  +2250 cR - Mobile Asset : MAX")
                changescore(PlayerIndex, 2250, plus)
                done[hash].medal.mobileasset = "True"
            end
        end

        if done[hash].medal.multikill == "False" then
            if medals[hash].class.multikill == "Iron" and medals[hash].count.multikill >= 10 then
                medals[hash].class.multikill = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Multikill Iron!")
            elseif medals[hash].class.multikill == "Bronze" and medals[hash].count.multikill >= 125 then
                medals[hash].class.multikill = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Multikill Bronze!")
            elseif medals[hash].class.multikill == "Silver" and medals[hash].count.multikill >= 500 then
                medals[hash].class.multikill = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Multikill Silver!")
            elseif medals[hash].class.multikill == "Gold" and medals[hash].count.multikill >= 2500 then
                medals[hash].class.multikill = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Multikill Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 500
                rprint(PlayerIndex, "Rewarded:  +500 cR - Multikill : Gold")
                changescore(PlayerIndex, 500, plus)
            elseif medals[hash].class.multikill == "Onyx" and medals[hash].count.multikill >= 5000 then
                medals[hash].class.multikill = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Multikill Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Multikill : Onyx")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.multikill == "MAX" and medals[hash].count.multikill == 15000 then
                say(getname(PlayerIndex) .. " has earned a mdeal : Multikill MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1500
                rprint(PlayerIndex, "Rewarded:  +1500 cR - Multikill : MAX")
                changescore(PlayerIndex, 1500, plus)
                done[hash].medal.multikill = "True"
            end
        end

        if done[hash].medal.sidearm == "False" then
            if medals[hash].class.sidearm == "Iron" and medals[hash].count.sidearm >= 50 then
                medals[hash].class.sidearm = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm Iron!")
            elseif medals[hash].class.sidearm == "Bronze" and medals[hash].count.sidearm >= 250 then
                medals[hash].class.sidearm = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm Bronze!")
            elseif medals[hash].class.sidearm == "Silver" and medals[hash].count.sidearm >= 1000 then
                medals[hash].class.sidearm = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm Silver!")
            elseif medals[hash].class.sidearm == "Gold" and medals[hash].count.sidearm >= 4000 then
                medals[hash].class.sidearm = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Sidearm : Gold")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.sidearm == "Onyx" and medals[hash].count.sidearm >= 8000 then
                medals[hash].class.sidearm = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 2000
                rprint(PlayerIndex, "Rewarded:  +2000 cR - Sidearm : Onyx")
                changescore(PlayerIndex, 2000, plus)
            elseif medals[hash].class.sidearm == "MAX" and medals[hash].count.sidearm == 10000 then
                say(getname(PlayerIndex) .. " has earned a medal : Sidearm MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 3000
                rprint(PlayerIndex, "Rewarded:  +3000 cR - Sidearm : MAX")
                changescore(PlayerIndex, 3000, plus)
                done[hash].medal.sidearm = "True"
            end
        end

        if done[hash].medal.triggerman == "False" then
            if medals[hash].class.triggerman == "Iron" and medals[hash].count.triggerman >= 100 then
                medals[hash].class.triggerman = "Bronze"
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman Iron!")
            elseif medals[hash].class.triggerman == "Bronze" and medals[hash].count.triggerman >= 500 then
                medals[hash].class.triggerman = "Silver"
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman Bronze!")
            elseif medals[hash].class.triggerman == "Silver" and medals[hash].count.triggerman >= 4000 then
                medals[hash].class.triggerman = "Gold"
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman Silver!")
            elseif medals[hash].class.triggerman == "Gold" and medals[hash].count.triggerman >= 10000 then
                medals[hash].class.triggerman = "Onyx"
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman Gold!")
                killstats[hash].total.credits = killstats[hash].total.credits + 1000
                rprint(PlayerIndex, "Rewarded:  +1000 cR - Triggerman : Gold")
                changescore(PlayerIndex, 1000, plus)
            elseif medals[hash].class.triggerman == "Onyx" and medals[hash].count.triggerman >= 20000 then
                medals[hash].class.triggerman = "MAX"
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman Onyx!")
                killstats[hash].total.credits = killstats[hash].total.credits + 2000
                rprint(PlayerIndex, "Rewarded:  +2000 cR - Triggerman : Onyx")
                changescore(PlayerIndex, 2000, plus)
            elseif medals[hash].class.triggerman == "MAX" and medals[hash].count.triggerman == 32000 then
                say(getname(PlayerIndex) .. " has earned a medal : Triggerman MAX!")
                killstats[hash].total.credits = killstats[hash].total.credits + 3000
                rprint(PlayerIndex, "Rewarded:  +3000 cR - Triggerman : MAX")
                changescore(PlayerIndex, 3000, plus)
                done[hash].medal.triggerman = "True"
            end
        end
    end
end

function GetMedalClasses(PlayerIndex)

    local hash = get_var(PlayerIndex, "$hash")

    if medals[hash].count.sprees > 5 and medals[hash].count.sprees < 50 then
        medals[hash].class.sprees = "Bronze"
    elseif medals[hash].count.sprees > 50 and medals[hash].count.sprees < 250 then
        medals[hash].class.sprees = "Silver"
    elseif medals[hash].count.sprees > 250 and medals[hash].count.sprees < 1000 then
        medals[hash].class.sprees = "Gold"
    elseif medals[hash].count.sprees > 1000 and medals[hash].count.sprees < 4000 then
        medals[hash].class.sprees = "Onyx"
    elseif medals[hash].count.sprees > 4000 and medals[hash].count.sprees < 10000 then
        medals[hash].class.sprees = "MAX"
    elseif medals[hash].count.sprees > 10000 then
        medals[hash].class.sprees = "MAX"
    end

    if medals[hash].count.assists > 50 and medals[hash].count.assists < 250 then
        medals[hash].class.assists = "Bronze"
    elseif medals[hash].count.assists > 250 and medals[hash].count.assists < 1000 then
        medals[hash].class.assists = "Silver"
    elseif medals[hash].count.assists > 1000 and medals[hash].count.assists < 4000 then
        medals[hash].class.assists = "Gold"
    elseif medals[hash].count.assists > 4000 and medals[hash].count.assists < 8000 then
        medals[hash].class.assists = "Onyx"
    elseif medals[hash].count.assists > 8000 and medals[hash].count.assists < 20000 then
        medals[hash].class.assists = "MAX"
    elseif medals[hash].count.assists > 20000 then
        medals[hash].class.assists = "MAX"
    end

    if medals[hash].count.closequarters > 50 and medals[hash].count.closequarters < 150 then
        medals[hash].class.closequarters = "Bronze"
    elseif medals[hash].count.closequarters > 150 and medals[hash].count.closequarters < 400 then
        medals[hash].class.closequarters = "Silver"
    elseif medals[hash].count.closequarters > 400 and medals[hash].count.closequarters < 1600 then
        medals[hash].class.closequarters = "Gold"
    elseif medals[hash].count.closequarters > 1600 and medals[hash].count.closequarters < 4000 then
        medals[hash].class.closequarters = "Onyx"
    elseif medals[hash].count.closequarters > 4000 and medals[hash].count.closequarters < 8000 then
        medals[hash].count.closequarters = "MAX"
    elseif medals[hash].count.closequarters > 8000 then
        medals[hash].count.closequarters = "MAX"
    end

    if medals[hash].count.crackshot > 100 and medals[hash].count.crackshot < 500 then
        medals[hash].class.crackshot = "Bronze"
    elseif medals[hash].count.crackshot > 500 and medals[hash].count.crackshot < 4000 then
        medals[hash].class.crackshot = "Silver"
    elseif medals[hash].count.crackshot > 4000 and medals[hash].count.crackshot < 10000 then
        medals[hash].class.crackshot = "Gold"
    elseif medals[hash].count.crackshot > 10000 and medals[hash].count.crackshot < 20000 then
        medals[hash].class.crackshot = "Onyx"
    elseif medals[hash].count.crackshot > 20000 and medals[hash].count.crackshot < 32000 then
        medals[hash].class.crackshot = "MAX"
    elseif medals[hash].count.crackshot > 32000 then
        medals[hash].class.crackshot = "MAX"
    end

    if medals[hash].count.downshift > 5 and medals[hash].count.downshift < 50 then
        medals[hash].class.downshift = "Bronze"
    elseif medals[hash].count.downshift > 50 and medals[hash].count.downshift < 750 then
        medals[hash].class.downshift = "Silver"
    elseif medals[hash].count.downshift > 750 and medals[hash].count.downshift < 4000 then
        medals[hash].class.downshift = "Gold"
    elseif medals[hash].count.downshift > 4000 and medals[hash].count.downshift < 8000 then
        medals[hash].class.downshift = "Onyx"
    elseif medals[hash].count.downshift > 8000 and medals[hash].count.downshift < 20000 then
        medals[hash].count.downshift = "MAX"
    elseif medals[hash].count.downshift > 20000 then
        medals[hash].count.downshift = "MAX"
    end

    if medals[hash].count.grenadier > 25 and medals[hash].count.grenadier < 125 then
        medals[hash].class.grenadier = "Bronze"
    elseif medals[hash].count.grenadier > 125 and medals[hash].count.grenadier < 500 then
        medals[hash].class.grenadier = "Silver"
    elseif medals[hash].count.grenadier > 500 and medals[hash].count.grenadier < 4000 then
        medals[hash].class.grenadier = "Gold"
    elseif medals[hash].count.grenadier > 4000 and medals[hash].count.grenadier < 8000 then
        medals[hash].class.grenadier = "Onyx"
    elseif medals[hash].count.grenadier > 8000 and medals[hash].count.grenadier < 14000 then
        medals[hash].class.grenadier = "MAX"
    elseif medals[hash].count.grenadier > 14000 then
        medals[hash].class.grenadier = "MAX"
    end

    if medals[hash].count.heavyweapons > 25 and medals[hash].count.heavyweapons < 150 then
        medals[hash].class.heavyweapons = "Bronze"
    elseif medals[hash].count.heavyweapons > 150 and medals[hash].count.heavyweapons < 750 then
        medals[hash].class.heavyweapons = "Silver"
    elseif medals[hash].count.heavyweapons > 750 and medals[hash].count.heavyweapons < 3000 then
        medals[hash].class.heavyweapons = "Gold"
    elseif medals[hash].count.heavyweapons > 3000 and medals[hash].count.heavyweapons < 7000 then
        medals[hash].class.heavyweapons = "Onyx"
    elseif medals[hash].count.heavyweapons > 7000 and medals[hash].count.heavyweapons < 14000 then
        medals[hash].class.heavyweapons = "MAX"
    elseif medals[hash].count.heavyweapons > 14000 then
        medals[hash].class.heavyweapons = "MAX"
    end

    if medals[hash].count.jackofalltrades > 50 and medals[hash].count.jackofalltrades < 125 then
        medals[hash].class.jackofalltrades = "Bronze"
    elseif medals[hash].count.jackofalltrades > 125 and medals[hash].count.jackofalltrades < 400 then
        medals[hash].class.jackofalltrades = "Silver"
    elseif medals[hash].count.jackofalltrades > 400 and medals[hash].count.jackofalltrades < 1600 then
        medals[hash].class.jackofalltrades = "Gold"
    elseif medals[hash].count.jackofalltrades > 1600 and medals[hash].count.jackofalltrades < 4800 then
        medals[hash].class.jackofalltrades = "Onyx"
    elseif medals[hash].count.jackofalltrades > 4800 and medals[hash].count.jackofalltrades < 9600 then
        medals[hash].class.jackofalltrades = "MAX"
    elseif medals[hash].count.jackofalltrades > 9600 then
        medals[hash].class.jackofalltrades = "MAX"
    end

    if medals[hash].count.moblieasset > 25 and medals[hash].count.moblieasset < 125 then
        medals[hash].class.mobileasset = "Bronze"
        -- Declear the medal's class.
    elseif medals[hash].count.moblieasset > 125 and medals[hash].count.moblieasset < 500 then
        medals[hash].class.mobileasset = "Silver"
        -- Declear the medal's class.
    elseif medals[hash].count.moblieasset > 500 and medals[hash].count.moblieasset < 4000 then
        medals[hash].class.mobileasset = "Gold"
        -- Declear the medal's class.
    elseif medals[hash].count.moblieasset > 4000 and medals[hash].count.moblieasset < 8000 then
        medals[hash].class.mobileasset = "Onyx"
        -- Declear the medal's class.
    elseif medals[hash].count.moblieasset > 8000 and medals[hash].count.moblieasset < 14000 then
        medals[hash].class.mobileasset = "MAX"
        -- Declear the medal's class.
    elseif medals[hash].count.moblieasset > 14000 then
        medals[hash].class.mobileasset = "MAX"
        -- Declear the medal's class.
    end

    if medals[hash].count.multikill > 10 and medals[hash].count.multikill < 125 then
        medals[hash].class.multikill = "Bronze"
        -- Declear the medal's class.
    elseif medals[hash].count.multikill > 125 and medals[hash].count.multikill < 500 then
        medals[hash].class.multikill = "Silver"
        -- Declear the medal's class.
    elseif medals[hash].count.multikill > 500 and medals[hash].count.multikill < 2500 then
        medals[hash].class.multikill = "Gold"
        -- Declear the medal's class.
    elseif medals[hash].count.multikill > 2500 and medals[hash].count.multikill < 5000 then
        medals[hash].class.multikill = "Onyx"
        -- Declear the medal's class.
    elseif medals[hash].count.multikill > 5000 and medals[hash].count.multikill < 15000 then
        medals[hash].class.multikill = "MAX"
        -- Declear the medal's class.
    elseif medals[hash].count.multikill > 15000 then
        medals[hash].class.multikill = "MAX"
        -- Declear the medal's class.
    end

    if medals[hash].count.sidearm > 50 and medals[hash].count.sidearm < 250 then
        medals[hash].class.sidearm = "Bronze"
    elseif medals[hash].count.sidearm > 250 and medals[hash].count.sidearm < 1000 then
        medals[hash].class.sidearm = "Silver"
    elseif medals[hash].count.sidearm > 1000 and medals[hash].count.sidearm < 4000 then
        medals[hash].class.sidearm = "Gold"
    elseif medals[hash].count.sidearm > 4000 and medals[hash].count.sidearm < 8000 then
        medals[hash].class.sidearm = "Onyx"
    elseif medals[hash].count.sidearm > 8000 and medals[hash].count.sidearm < 10000 then
        medals[hash].class.sidearm = "MAX"
    elseif medals[hash].count.sidearm > 10000 then
        medals[hash].class.sidearm = "MAX"
    end

    if medals[hash].count.triggerman > 100 and medals[hash].count.triggerman < 500 then
        medals[hash].class.triggerman = "Bronze"
    elseif medals[hash].count.triggerman > 500 and medals[hash].count.triggerman < 4000 then
        medals[hash].class.triggerman = "Silver"
    elseif medals[hash].count.triggerman > 4000 and medals[hash].count.triggerman < 10000 then
        medals[hash].class.triggerman = "Gold"
    elseif medals[hash].count.triggerman > 10000 and medals[hash].count.triggerman < 20000 then
        medals[hash].class.triggerman = "Onyx"
    elseif medals[hash].count.triggerman > 20000 and medals[hash].count.triggerman < 32000 then
        medals[hash].class.triggerman = "MAX"
    elseif medals[hash].count.triggerman > 32000 then
        medals[hash].class.triggerman = "MAX"
    end
end

function getplayer(PlayerIndex)
    if tonumber(PlayerIndex) then
        if tonumber(PlayerIndex) ~= 0 then
            local m_player = get_player(PlayerIndex)
            if m_player ~= 0 then return m_player end
        end
    end
    return nil
end

function getteam(PlayerIndex)
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		local team = get_var(PlayerIndex, "$team")
		return team
	end
	return nil
end

function gethash(PlayerIndex)
	if PlayerIndex ~= nil and PlayerIndex ~= "-1" then
		local hash = get_var(PlayerIndex, "$hash")
		return hash
	end
	return nil
end

function SendMessage(PlayerIndex, message)
    if getplayer(PlayerIndex) then
        rprint(PlayerIndex, "|c" .. message)
    end
end

function GetPlayerRank(PlayerIndex)

    local hash = get_var(PlayerIndex, "$hash")
    -- Get the hash of the PlayerIndex.
    if hash then
        killstats[hash].total.credits = killstats[hash].total.credits or 0
        if killstats[hash].total.credits > 0 and killstats[hash].total.credits ~= nil and killstats[hash].total.rank ~= nil then
            if killstats[hash].total.credits >= 0 and killstats[hash].total.credits < 7500 then
                -- 0 - 7,500
                killstats[hash].total.rank = "Recruit"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 7500 and killstats[hash].total.credits < 10000 then
                -- 7,500 - 10,000
                killstats[hash].total.rank = "Private"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 10000 and killstats[hash].total.credits < 15000 then
                -- 10,000 - 15,000
                killstats[hash].total.rank = "Corporal"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 15000 and killstats[hash].total.credits < 20000 then
                -- 15,000 - 20,000
                killstats[hash].total.rank = "Sergeant"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 20000 and killstats[hash].total.credits < 26250 then
                -- 20,000 - 26,250
                killstats[hash].total.rank = "Sergeant Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 26250 and killstats[hash].total.credits < 32500 then
                -- 26,250 - 32,500
                killstats[hash].total.rank = "Sergeant Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 32500 and killstats[hash].total.credits < 45000 then
                -- 32,500 - 45,000
                killstats[hash].total.rank = "Warrant Officer"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 45000 and killstats[hash].total.credits < 78000 then
                -- 45,000 - 78,000
                killstats[hash].total.rank = "Warrant Officer Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 78000 and killstats[hash].total.credits < 111000 then
                -- 78,000 - 111,000
                killstats[hash].total.rank = "Warrant Officer Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 111000 and killstats[hash].total.credits < 144000 then
                -- 111,000 - 144,000
                killstats[hash].total.rank = "Warrant Officer Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 144000 and killstats[hash].total.credits < 210000 then
                -- 144,000 - 210,000
                killstats[hash].total.rank = "Captain"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 210000 and killstats[hash].total.credits < 233000 then
                -- 210,000 - 233,000
                killstats[hash].total.rank = "Captain Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 233000 and killstats[hash].total.credits < 256000 then
                -- 233,000 - 256,000
                killstats[hash].total.rank = "Captain Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 256000 and killstats[hash].total.credits < 279000 then
                -- 256,000 - 279,000
                killstats[hash].total.rank = "Captain Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 279000 and killstats[hash].total.credits < 325000 then
                -- 279,000 - 325,000
                killstats[hash].total.rank = "Major"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 325000 and killstats[hash].total.credits < 350000 then
                -- 325,000 - 350,000
                killstats[hash].total.rank = "Major Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 350000 and killstats[hash].total.credits < 375000 then
                -- 350,000 - 375,000
                killstats[hash].total.rank = "Major Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 375000 and killstats[hash].total.credits < 400000 then
                -- 375,000 - 400,000
                killstats[hash].total.rank = "Major Grade 3"
                -- Decide his rank
            elseif killstats[hash].total.credits > 400000 and killstats[hash].total.credits < 450000 then
                -- 400,000 - 450,000
                killstats[hash].total.rank = "Lt. Colonel"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 450000 and killstats[hash].total.credits < 480000 then
                -- 450,000 - 480,000
                killstats[hash].total.rank = "Lt. Colonel Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 480000 and killstats[hash].total.credits < 510000 then
                -- 480,000 - 510,000
                killstats[hash].total.rank = "Lt. Colonel Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 510000 and killstats[hash].total.credits < 540000 then
                -- 510,000 - 540,000
                killstats[hash].total.rank = "Lt. Colonel Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 540000 and killstats[hash].total.credits < 600000 then
                -- 540,000 - 600,000
                killstats[hash].total.rank = "Commander"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 600000 and killstats[hash].total.credits < 650000 then
                -- 600,000 - 650,000
                killstats[hash].total.rank = "Commander Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 650000 and killstats[hash].total.credits < 700000 then
                -- 650,000 - 700,000
                killstats[hash].total.rank = "Commander Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 700000 and killstats[hash].total.credits < 750000 then
                -- 700,000 - 750,000
                killstats[hash].total.rank = "Commander Grade 3"
                -- Decide his rank
            elseif killstats[hash].total.credits > 750000 and killstats[hash].total.credits < 850000 then
                -- 750,000 - 850,000
                killstats[hash].total.rank = "Colonel"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 850000 and killstats[hash].total.credits < 960000 then
                -- 850,000 - 960,000
                killstats[hash].total.rank = "Colonel Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 960000 and killstats[hash].total.credits < 1070000 then
                -- 960,000 - 1,070,000
                killstats[hash].total.rank = "Colonel Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 1070000 and killstats[hash].total.credits < 1180000 then
                -- 1,070,000 - 1,180,000
                killstats[hash].total.rank = "Colonel Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 1180000 and killstats[hash].total.credits < 1400000 then
                -- 1,180,000 - 1,400,000
                killstats[hash].total.rank = "Brigadier"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 1400000 and killstats[hash].total.credits < 1520000 then
                -- 1,400,000 - 1,520,000
                killstats[hash].total.rank = "Brigadier Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 1520000 and killstats[hash].total.credits < 1640000 then
                -- 1,520,000 - 1,640,000
                killstats[hash].total.rank = "Brigadier Grade 2"
                -- Decide his rank
            elseif killstats[hash].total.credits > 1640000 and killstats[hash].total.credits < 1760000 then
                -- 1,640,000 - 1,760,000
                killstats[hash].total.rank = "Brigadier Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 1760000 and killstats[hash].total.credits < 2000000 then
                -- 1,760,000 - 2,000,000
                killstats[hash].total.rank = "General"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 2000000 and killstats[hash].total.credits < 2200000 then
                -- 2,000,000 - 2,200,000
                killstats[hash].total.rank = "General Grade 1"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 2200000 and killstats[hash].total.credits < 2350000 then
                -- 2,200,000 - 2,350,000
                killstats[hash].total.rank = "General Grade 2"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 2350000 and killstats[hash].total.credits < 2500000 then
                -- 2,350,000 - 2,500,000
                killstats[hash].total.rank = "General Grade 3"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 2500000 and killstats[hash].total.credits < 2650000 then
                -- 2,500,000 - 2,650,000
                killstats[hash].total.rank = "General Grade 4"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 2650000 and killstats[hash].total.credits < 3000000 then
                -- 2,650,000 - 3,000,000
                killstats[hash].total.rank = "Field Marshall"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 3000000 and killstats[hash].total.credits < 3700000 then
                -- 3,000,000 - 3,700,000
                killstats[hash].total.rank = "Hero"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 3700000 and killstats[hash].total.credits < 4600000 then
                -- 3,700,000 - 4,600,000
                killstats[hash].total.rank = "Legend"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 4600000 and killstats[hash].total.credits < 5650000 then
                -- 4,600,000 - 5,650,000
                killstats[hash].total.rank = "Mythic"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 5650000 and killstats[hash].total.credits < 7000000 then
                -- 5,650,000 - 7,000,000
                killstats[hash].total.rank = "Noble"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 7000000 and killstats[hash].total.credits < 8500000 then
                -- 7,000,000 - 8,500,000
                killstats[hash].total.rank = "Eclipse"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 8500000 and killstats[hash].total.credits < 11000000 then
                -- 8,500,000 - 11,000,000
                killstats[hash].total.rank = "Nova"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 11000000 and killstats[hash].total.credits < 13000000 then
                -- 11,000,000 - 13,000,000
                killstats[hash].total.rank = "Forerunner"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 13000000 and killstats[hash].total.credits < 16500000 then
                -- 13,000,000 - 16,500,000
                killstats[hash].total.rank = "Reclaimer"
                -- Decide his rank.
            elseif killstats[hash].total.credits > 16500000 and killstats[hash].total.credits < 20000000 then
                -- 16,500,000 - 20,000,000
                killstats[hash].total.rank = "Inheritor"
                -- Decide his rank.
            end
        end
    end
end

function CreditsUntilNextPromo(PlayerIndex)
    local hash = get_var(PlayerIndex, "$hash")
    killstats[hash].total.rank = killstats[hash].total.rank or "Recruit"
    killstats[hash].total.credits = killstats[hash].total.credits or 0
    
    if killstats[hash].total.rank == "Recruit" then
        return 7500 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Private" then
        return 10000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Corporal" then
        return 15000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Sergeant" then
        return 20000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Sergeant Grade 1" then
        return 26250 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Sergeant Grade 2" then
        return 32500 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Warrant Officer" then
        return 45000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Warrant Officer Grade 1" then
        return 78000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Warrant Officer Grade 2" then
        return 111000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Warrant Officer Grade 3" then
        return 144000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Captain" then
        return 210000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Captain Grade 1" then
        return 233000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Captain Grade 2" then
        return 256000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Captain Grade 3" then
        return 279000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Major" then
        return 325000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Major Grade 1" then
        return 350000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Major Grade 2" then
        return 375000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Major Grade 3" then
        return 400000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Lt. Colonel" then
        return 450000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Lt. Colonel Grade 1" then
        return 480000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Lt. Colonel Grade 2" then
        return 510000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Lt. Colonel Grade 3" then
        return 540000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Commander" then
        return 600000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Commander Grade 1" then
        return 650000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Commander Grade 2" then
        return 700000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Commander Grade 3" then
        return 750000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Colonel" then
        return 850000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Colonel Grade 1" then
        return 960000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Colonel Grade 2" then
        return 1070000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Colonel Grade 3" then
        return 1180000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Brigadier" then
        return 1400000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Brigadier Grade 1" then
        return 1520000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Brigadier Grade 2" then
        return 1640000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Brigadier Grade 3" then
        return 1760000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "General" then
        return 2000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "General Grade 1" then
        return 2350000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "General Grade 2" then
        return 2500000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "General Grade 3" then
        return 2650000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "General Grade 4" then
        return 3000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Field Marshall" then
        return 3700000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Hero" then
        return 4600000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Legend" then
        return 5650000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Mythic" then
        return 7000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Noble" then
        return 8500000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Eclipse" then
        return 11000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Nova" then
        return 13000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Forerunner" then
        return 16500000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Reclaimer" then
        return 20000000 - killstats[hash].total.credits
    elseif killstats[hash].total.rank == "Inheritor" then
        return "Ranks Complete"
    end
end

 -- [function get_tag_info] - Thanks to 002
function get_tag_info(tagclass,tagname)
    local tagarray = read_dword(0x40440000)
    for i=0,read_word(0x4044000C)-1 do
        local tag = tagarray + i * 0x20
        local class = string.reverse(string.sub(read_string(tag),1,4))
        if (class == tagclass) then
            if (read_string(read_dword(tag + 0x10)) == tagname) then
                return read_dword(tag + 0xC)
            end
        end
    end
    return nil
end

function LoadItems()
    -- fall damage --
    falling_damage = get_tag_info("jpt!", "globals\\falling")
    distance_damage = get_tag_info("jpt!", "globals\\distance")
    
    -- vehicle collision --
    veh_damage = get_tag_info("jpt!", "globals\\vehicle_collision")
    
    -- vehicle projectiles --
    ghost_bolt = get_tag_info("jpt!", "vehicles\\ghost\\ghost bolt")
    tank_bullet = get_tag_info("jpt!", "vehicles\\scorpion\\bullet")
    chain_bullet = get_tag_info("jpt!", "vehicles\\warthog\\bullet")
    turret_bolt = get_tag_info("jpt!", "vehicles\\c gun turret\\mp bolt")
    banshee_bolt = get_tag_info("jpt!", "vehicles\\banshee\\banshee bolt")
    tank_shell = get_tag_info("jpt!", "vehicles\\scorpion\\shell explosion")
    banshee_explode = get_tag_info("jpt!", "vehicles\\banshee\\mp_fuel rod explosion")
    
    -- weapon projectiles --
    pistol_bullet = get_tag_info("jpt!", "weapons\\pistol\\bullet")
    prifle_bolt = get_tag_info("jpt!", "weapons\\plasma rifle\\bolt")
    shotgun_pellet = get_tag_info("jpt!", "weapons\\shotgun\\pellet")
    ppistol_bolt = get_tag_info("jpt!", "weapons\\plasma pistol\\bolt")
    needle_explode = get_tag_info("jpt!", "weapons\\needler\\explosion")
    assault_bullet = get_tag_info("jpt!", "weapons\\assault rifle\\bullet")
    needle_impact = get_tag_info("jpt!", "weapons\\needler\\impact damage")
    flame_explode = get_tag_info("jpt!", "weapons\\flamethrower\\explosion")
    sniper_bullet = get_tag_info("jpt!", "weapons\\sniper rifle\\sniper bullet")
    rocket_explode = get_tag_info("jpt!", "weapons\\rocket launcher\\explosion")
    needle_detonate = get_tag_info("jpt!", "weapons\\needler\\detonation damage")
    ppistol_charged = get_tag_info("jpt!", "weapons\\plasma rifle\\charged bolt")
    pcannon_melee = get_tag_info("jpt!", "weapons\\plasma_cannon\\effects\\plasma_cannon_melee")
    pcannon_explode = get_tag_info("jpt!", "weapons\\plasma_cannon\\effects\\plasma_cannon_explosion")
    
    -- grenades --
    frag_explode = get_tag_info("jpt!", "weapons\\frag grenade\\explosion")
    plasma_attach = get_tag_info("jpt!", "weapons\\plasma grenade\\attached")
    plasma_explode = get_tag_info("jpt!", "weapons\\plasma grenade\\explosion")
    
    -- weapon melee --
    flag_melee = get_tag_info("jpt!", "weapons\\flag\\melee")
    ball_melee = get_tag_info("jpt!", "weapons\\ball\\melee")
    pistol_melee = get_tag_info("jpt!", "weapons\\pistol\\melee")
    needle_melee = get_tag_info("jpt!", "weapons\\needler\\melee")
    shotgun_melee = get_tag_info("jpt!", "weapons\\shotgun\\melee")
    flame_melee = get_tag_info("jpt!", "weapons\\flamethrower\\melee")
    sniper_melee = get_tag_info("jpt!", "weapons\\sniper rifle\\melee")	
    prifle_melee = get_tag_info("jpt!", "weapons\\plasma rifle\\melee")
    ppistol_melee = get_tag_info("jpt!", "weapons\\plasma pistol\\melee")
    assault_melee = get_tag_info("jpt!", "weapons\\assault rifle\\melee")
    rocket_melee = get_tag_info("jpt!", "weapons\\rocket launcher\\melee")
end

function RuleTimer(id, count)
    local number = getvalidcount(count)
    if number ~= nil then
        if number == 1 then
            say("Blocking Ports / Pathways / Tunnels, Glitching into rocks/trees/out of map is not allowed.")
        elseif number == 2 then
            say("Team Grenading / Flipping / Shooting / Meleeing / Ramming is not allowed.")
        elseif number == 3 then
            say("Type \"@stuck\" for more indepth rules")
        elseif number == 4 then
            say("If you get stuck, you can type \"@stuck\" to find a way out.")
        elseif number == 5 then
            say("Type \"@info\" for all the commands to view your stats.")
        end
    end
    return true
end

function getvalidcount(count)
    local number = nil
    if table.find( { "180", "360", "540", "720", "900", "1080" }, count) then
        number = 1
    elseif table.find( { "182", "362", "542", "722", "902", "1082" }, count) then
        number = 2
    elseif table.find( { "184", "364", "544", "724", "904", "1084" }, count) then
        number = 3
    elseif table.find( { "186", "366", "546", "726", "906", "1086" }, count) then
        number = 4
    elseif table.find( { "188", "368", "548", "728", "908", "1088" }, count) then
        number = 5
    end
    return number
end
		

function secondsToTime(seconds, places)
    local years = math.floor(seconds /(60 * 60 * 24 * 365))
    seconds = seconds %(60 * 60 * 24 * 365)
    local weeks = math.floor(seconds /(60 * 60 * 24 * 7))
    seconds = seconds %(60 * 60 * 24 * 7)
    local days = math.floor(seconds /(60 * 60 * 24))
    seconds = seconds %(60 * 60 * 24)
    local hours = math.floor(seconds /(60 * 60))
    seconds = seconds %(60 * 60)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    
    if places == 6 then
        return string.format("%02d:%02d:%02d:%02d:%02d:%02d", years, weeks, days, hours, minutes, seconds)
    elseif places == 5 then
        return string.format("%02d:%02d:%02d:%02d:%02d", weeks, days, hours, minutes, seconds)
    elseif not places or places == 4 then
        return days, hours, minutes, seconds
    elseif places == 3 then
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    elseif places == 2 then
        return string.format("%02d:%02d", minutes, seconds)
    elseif places == 1 then
        return string.format("%02", seconds)
    end
end

function setscore(PlayerIndex, score)
    if tonumber(score) then
        if get_var(0, "$gt") == "ctf" then
            local m_player = getplayer(PlayerIndex)
            if score >= 0x7FFF then
                write_word(m_player + 0xC8, 0x7FFF)
            elseif score <= -0x7FFF then
                write_word(m_player + 0xC8, -0x7FFF)
            else
                write_word(m_player + 0xC8, score)
            end
        elseif get_var(0, "$gt") == "slayer" then
            if score >= 0x7FFF then
                execute_command("score " .. PlayerIndex .. " +1")
            elseif score <= -0x7FFF then
                execute_command("score " .. PlayerIndex .. " -1")
            else
                execute_command("score " .. PlayerIndex .. " " .. score)
            end
        end
    end
end

function changescore(PlayerIndex, number, type)
    local m_player = getplayer(PlayerIndex)
    if m_player then
        local player_flag_scores = read_word(m_player + 0xC8)
        if type == plus or type == add then
            local score = player_flag_scores + number
            setscore(PlayerIndex, score)
        elseif type == take or type == minus or type == subtract then
            local score = player_flag_scores + math.abs(number)
            setscore(PlayerIndex, score)
        end
    end
end

function read_widestring(address, length)
    local count = 0
    local byte_table = { }
    for i = 1, length do
        if read_byte(address + count) ~= 0 then
            byte_table[i] = string.char(read_byte(address + count))
        end
        count = count + 2
    end
    return table.concat(byte_table)
end

function tokenizestring(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = { }; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- Check if player is in a Vehicle. Returns boolean --
function PlayerInVehicle(PlayerIndex)
    local player_object = get_dynamic_player(PlayerIndex)
    if (player_object ~= 0) then
        local VehicleID = read_dword(player_object + 0x11C)
        if VehicleID == 0xFFFFFFFF then
            return false
        else
            return true
            end
    else
        return false
    end
end
