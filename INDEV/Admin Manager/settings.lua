-- FULL DESCRIPTION CAN BE FOUND HERE: https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS/releases/tag/AdminManager

-- todo: name ban pattern-matching (regex) | REQUESTED BY Buzzard.

return {

    --- TERMINAL ADMIN LEVEL:
    --
    -- Default level for the server console:
    -- Default: (6)
    console_default_level = 6,


    --- PASSWORD LENGTH:
    --
    -- Minimum and maximum password length for password admins:
    -- Default (4, 32)
    password_length_limit = { 4, 32 },


    --- ADMIN LEVEL DELETE TIMEOUT:
    --
    -- Confirmation timeout (in seconds) for deleting admin levels:
    -- If a player doesn't confirm the deletion within this time, the deletion is cancelled.
    -- Default: (10)
    confirmation_timeout = 10,


    --- DEFAULT BAN DURATION:
    --
    -- Players are banned for this duration if no duration is specified:
    default_ban_duration = {
        y = 0, -- years
        mo = 0, -- months
        d = 0, -- days
        h = 1, -- hours
        m = 0, -- minutes
        s = 0-- seconds
    },


    --- DATABASE DIRECTORIES:
    --
    -- Admin, command and logging data are stored in JSON format in the following files:
    directories = {

        -- Admins:
        -- This file is automatically generated and CAN be edited (but restart the server after editing).
        [1] = './Admin Manager/admins.json',

        -- Commands:
        -- This file is automatically generated and CAN be edited (but restart the server after editing).
        [2] = './Admin Manager/commands.json',

        -- Bans:
        -- This file is automatically generated and should not be edited.
        [3] = './Admin Manager/bans.json',

        -- Logging:
        -- This file is automatically generated and should not be edited.
        [4] = './Admin Manager/logs.json'
    },


    --- LOGGING:
    --
    -- When enabled, command logs are saved to the ./Admin Manager/logs.json file.
    logging = {

        -- Log management commands and ban actions:
        -- Default: (true)
        management = true,

        -- Log all other commands:
        -- Default: (true)
        default = true,
    },


    --- CUSTOM JOIN MESSAGES FOR ADMINS:
    --
    -- Format: [admin level] = {'custom join message', enabled/disabled (true/false)}}
    admin_join_messages = {
        enabled = false,
        [1] = {'[PUBLIC] %s joined the server.', false},
        [2] = {'[ADMIN] %s just showed up. Hold my beer!', true},
        [3] = {'[MOD] %s just joined. Hide your bananas!', true},
        [4] = {'[VIP] %s joined the server. Sexy is as sexy does.', true},
        [5] = {'[PRO] %s joined the server. Pro noob.', true},
        [6] = {'[OWNER] %s joined the server. Everybody hide!', true},
    },


    --- COMMAND SPY:
    --
    -- When enabled, admins will be able to see commands executed by players.
    -- You will only see commands from players with a lower or equal level to you.
    -- Format: [admin level] = true (or false)
    command_spy = {
        enabled = true,
        [1] = false,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true
    },


    --- CUSTOM MANAGEMENT COMMANDS:
    --
    -- Management command permissions can be changed in the ./Admin Manager/commands/<command> directory.
    -- Format: ['<command file name>'] = true (or false)
    -- Setting a command to false will disable it for all players.
    -- Default: (all true)
    management_commands = {

        ['change_level'] = true,
        ['confirm'] = true,
        ['disable_command'] = true,
        ['enable_command'] = true,
        ['hash_admin_add'] = true,
        ['hash_admin_delete'] = true,
        ['hash_admins'] = true,
        ['ip_admin_add'] = true,
        ['ip_admin_delete'] = true,
        ['ip_admins'] = true,
        ['level_add'] = true,
        ['level_delete'] = true,
        ['login'] = true, -- override (do not change)
        ['logout'] = true,
        ['pw_admin_add'] = true,
        ['pw_admin_delete'] = true,
        ['pw_admins'] = true,
        ['set_command'] = true,

        -- BAN / MUTE COMMANDS:
        ['hash_ban'] = true,
        ['hash_unban'] = true,
        ['hash_bans'] = true,
        ['ip_ban'] = true,
        ['ip_unban'] = true,
        ['ip_bans'] = true,
        ['name_ban'] = true,
        ['name_unban'] = true,
        ['name_bans'] = true,
        ['mute'] = true,
        ['mute_list'] = true,
        ['unmute'] = true,

        -- MISC:
        ['admin_chat'] = true,
        ['command_spy'] = true,
    },


    --
    --- DEFAULT COMMANDS:
    --
    -- These are the default commands that are available to players at each level:
    -- When the plugin is first installed, these commands are copied to the `commands.json` file.
    -- You can edit the commands in the ./commands.json file, or use the management commands to change them.
    --
    -- Format: ['<level>'] = { ['<command>'] = true (or false) ... }
    -- Setting a command to false will disable it for all players.
    -- Default: (all true)
    default_commands = {

        -- [!] NOTE:
        -- Level 1 is reserved for public commands.

        ['1'] = { -- public commands
            ['whatsnext'] = true,
            ['usage'] = true,
            ['unstfu'] = true,
            ['stats'] = true,
            ['stfu'] = true,
            ['sv_stats'] = true,
            ['report'] = true,
            ['info'] = true,
            ['lead'] = true,
            ['list'] = false,
            ['clead'] = true,
            ['about'] = true
        },

        ['2'] = { -- level 2
            ['uptime'] = true,
            ['kdr'] = true,
            ['mapcycle'] = true,
            ['change_password'] = false,
            ['admindel'] = false,
            ['adminadd'] = false,
            ['afk'] = true
        },

        ['3'] = { -- level 3
            ['skips'] = true,
            ['aimbot_scores'] = true
        },

        ['4'] = { -- level 4
            ['say'] = true,
            ['tell'] = true,
            ['mute'] = false,
            ['mutes'] = false,
            ['k'] = true,
            ['afks'] = true,
            ['balance_teams'] = true,
            ['pl'] = true,
            ['st'] = true,
            ['teamup'] = true,
            ['textban'] = false,
            ['textbans'] = false,
            ['textunban'] = false,
            ['unmute'] = false,
        },

        ['5'] = { -- level 5
            ['ub'] = false,
            ['inf'] = true,
            ['ip'] = true,
            ['ipban'] = false,
            ['ipbans'] = false,
            ['ipunban'] = false,
            ['map'] = true,
            ['refresh_ipbans'] = false,
            ['maplist'] = true,
            ['b'] = false,
            ['bans'] = false,
        },

        ['6'] = { -- level 6
            ['admin_add'] = false,
            ['admin_add_manually'] = false,
            ['admin_change_level'] = false,
            ['admin_change_pw'] = false,
            ['admin_del'] = false,
            ['admin_list'] = false,
            ['admin_prefix'] = true,
            ['adminadd_samelevel'] = false,
            ['adminban'] = false,
            ['admindel_samelevel'] = false,
            ['adminlevel'] = false,
            ['admins'] = false,
            ['afk_kick'] = true,
            ['aimbot_ban'] = true,
            ['alias'] = true,
            ['ammo'] = true,
            ['anticamp'] = true,
            ['anticaps'] = true,
            ['anticheat'] = true,
            ['antiglitch'] = true,
            ['antihalofp'] = true,
            ['antilagspawn'] = true,
            ['antispam'] = true,
            ['antiwar'] = true,
            ['area_add_cuboid'] = true,
            ['area_add_sphere'] = true,
            ['area_del'] = true,
            ['area_list'] = true,
            ['area_listall'] = true,
            ['assists'] = true,
            ['auto_update'] = true,
            ['ayy lmao'] = true,
            ['battery'] = true,
            ['beep'] = true,
            ['block_all_objects'] = true,
            ['block_all_vehicles'] = true,
            ['block_object'] = true,
            ['block_tc'] = true,
            ['boost'] = true,
            ['camo'] = true,
            ['cevent'] = true,
            ['chat_console_echo'] = true,
            ['cmd_add'] = true,
            ['cmd_del'] = true,
            ['cmdstart1'] = true,
            ['cmdstart2'] = true,
            ['collect_aliases'] = true,
            ['color'] = true,
            ['console_input'] = true,
            ['coord'] = true,
            ['cpu'] = true,
            ['custom_sleep'] = true,
            ['d'] = true,
            ['deaths'] = true,
            ['debug_strings'] = true,
            ['disable_all_objects'] = true,
            ['disable_all_vehicles'] = true,
            ['disable_backtap'] = true,
            ['disable_object'] = true,
            ['disable_timer_offsets'] = true,
            ['disabled_objects'] = true,
            ['dns'] = true,
            ['enable_object'] = true,
            ['eventdel'] = true,
            ['events'] = true,
            ['files'] = true,
            ['full_ipban'] = false,
            ['gamespeed'] = true,
            ['god'] = true,
            ['gravity'] = true,
            ['hide_admin'] = false,
            ['hill_timer'] = true,
            ['hp'] = true,
            ['iprangeban'] = false,
            ['kill'] = true,
            ['kills'] = true,
            ['lag'] = true,
            ['loc_add'] = true,
            ['loc_del'] = true,
            ['loc_list'] = true,
            ['loc_listall'] = true,
            ['log'] = true,
            ['log_name'] = true,
            ['log_note'] = true,
            ['log_rotation'] = true,
            ['lua'] = true,
            ['lua_api_v'] = true,
            ['lua_call'] = true,
            ['lua_list'] = true,
            ['lua_load'] = true,
            ['lua_unload'] = true,
            ['m'] = true,
            ['mag'] = true,
            ['map_download'] = true,
            ['map_load'] = true,
            ['map_next'] = true,
            ['map_prev'] = true,
            ['map_query'] = true,
            ['map_skip'] = true,
            ['map_spec'] = true,
            ['mapcycle_add'] = true,
            ['mapcycle_begin'] = true,
            ['mapcycle_del'] = true,
            ['mapvote'] = true,
            ['mapvote_add'] = true,
            ['mapvote_begin'] = true,
            ['mapvote_del'] = true,
            ['mapvotes'] = true,
            ['max_idle'] = true,
            ['max_votes'] = true,
            ['motd'] = true,
            ['msg_prefix'] = true,
            ['mtv'] = true,
            ['nades'] = true,
            ['network_thread'] = true,
            ['no_lead'] = true,
            ['object_sync_cleanup'] = true,
            ['packet_limit'] = true,
            ['ping_kick'] = true,
            ['query_add'] = true,
            ['query_del'] = true,
            ['query_list'] = true,
            ['reload'] = true,
            ['reload_gametypes'] = true,
            ['remote_console'] = true,
            ['remote_console_list'] = true,
            ['remote_console_port'] = true,
            ['rprint'] = true,
            ['s'] = true,
            ['sapp_console'] = true,
            ['sapp_mapcycle'] = true,
            ['sapp_rcon'] = true,
            ['save_respawn_time'] = true,
            ['save_scores'] = true,
            ['say_prefix'] = true,
            ['score'] = true,
            ['scorelimit'] = true,
            ['scrim_mode'] = true,
            ['set_ccolor'] = true,
            ['setadmin'] = false,
            ['setcmd'] = true,
            ['sh'] = true,
            ['sj_level'] = true,
            ['spawn'] = true,
            ['spawn_protection'] = true,
            ['t'] = true,
            ['team_score'] = true,
            ['text'] = true,
            ['timelimit'] = true,
            ['tp'] = true,
            ['unblock_object'] = true,
            ['ungod'] = true,
            ['unlag'] = true,
            ['unlock_console_log'] = true,
            ['v'] = true,
            ['var_add'] = true,
            ['var_conv'] = true,
            ['var_del'] = true,
            ['var_list'] = true,
            ['var_set'] = true,
            ['vdel'] = true,
            ['vdel_all'] = true,
            ['venter'] = true,
            ['vexit'] = true,
            ['wadd'] = true,
            ['wdel'] = true,
            ['wdrop'] = true,
            ['yeye'] = true,
            ['zombies'] = true
        }
    }
}