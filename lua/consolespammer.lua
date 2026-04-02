--#note: > safesolver

--# > libs

local ffi = require("ffi")
local bit = require("bit")
local pui = require("gamesense/pui")
local vector = require("vector")
local http = require("gamesense/http")
local base64 = require ("gamesense/base64")

--# > ffi

ffi.cdef[[
    typedef struct
    {
        float x;
        float y;
        float z;
    } vec3_t;

    typedef struct
    {
        int     m_order;
        int     m_sequence;
        float   m_prev_cycle;
        float   m_cycle;
        float   m_weight;
        float   m_weight_delta_rate;
        float   m_playback_rate;
        void*   m_owner;
    } C_AnimationLayer;

    typedef struct
    {
        char        pad0[0x60];
        void*       pEntity;
        void*       pActiveWeapon;
        void*       pLastActiveWeapon;
        float       flLastUpdateTime;
        int         iLastUpdateFrame;
        float       flLastUpdateIncrement;
        float       flEyeYaw;
        float       flEyePitch;
        float       flGoalFeetYaw;
        float       flLastFeetYaw;
        float       flMoveYaw;
        float       flLastMoveYaw;
        float       flLeanAmount;
        char        pad1[0x4];
        float       flFeetCycle;
        float       flMoveWeight;
        float       flMoveWeightSmoothed;
        float       flDuckAmount;
        float       flHitGroundCycle;
        float       flRecrouchWeight;
        vec3_t      vecOrigin;
        vec3_t      vecLastOrigin;
        vec3_t      vecVelocity;
        vec3_t      vecVelocityNormalized;
        vec3_t      vecVelocityNormalizedNonZero;
        float       flVelocityLenght2D;
        float       flJumpFallVelocity;
        float       flSpeedNormalized;
        float       flRunningSpeed;
        float       flDuckingSpeed;
        float       flDurationMoving;
        float       flDurationStill;
        bool        bOnGround;
        bool        bHitGroundAnimation;
        char        pad2[0x2];
        float       flNextLowerBodyYawUpdateTime;
        float       flDurationInAir;
        float       flLeftGroundHeight;
        float       flHitGroundWeight;
        float       flWalkToRunTransition;
        char        pad3[0x4];
        float       flAffectedFraction;
        char        pad4[0x208];
        char        pad_because_yes[0x4];
        float       flMinBodyYaw;
        float       flMaxBodyYaw;
        float       flMinPitch;
        float       flMaxPitch;
        int         iAnimsetVersion;
    } CCSGOPlayerAnimationState_t;
]]

--# > reset function

local function reset_all_data()
    ResolverData = {}
    JitterWindow = {}
    DefensiveData = {}
    MovementHistory = {}
    UnmatchedData = {}
    TickbaseHistory = {}
    AnimationLayerCache = {}
    animstate_cache = {}
    animstate_cache_time = {}
    LagCompensationData = {}
    client.exec("play survival/securitydoor_payment_failed.wav")
    client.color_log(175, 148, 214, "#savesolver | Resolver data has been reset")
end

local function reset_unmatched()
    UnmatchedData = {}
    for player, data in pairs(ResolverData) do
        if data then
            data.unmatched_mode = false
            data.defensive_ticks = 0
        end
    end
    client.exec("play survival/securitydoor_payment_failed.wav")
    client.color_log(175, 148, 214, "#savesolver | UnmatchedResolver data has been reset")
end

--# > safedata

local safedata = {
    username = panorama.open("CSGOHud").MyPersonaAPI.GetName(),
    version = '2.1.1',
    upd = '02.04.2026',
    dev = 'safe ~ @jeiloy',
    build = 'stable'
}

pui.macros.pl = '\aAF94D6FF'
pui.macros.gr = '\a656565FF'
local js = panorama.open()
local SteamOverlayAPI = js.SteamOverlayAPI

--# > menu

local lua_a = pui.group("LUA","A")
local lua_b = pui.group("LUA", "B")

local menu = {
    combo = {
        combo = lua_b:combobox("\f<gr>#safesolver", {"Home", "Features", "Resolver", "Unmatched"})
    },
    main = {
        label1 = lua_a:label("\f<gr>#Resolver"),
        enable = lua_a:checkbox("~ Enable \f<pl>Resolver"),
        jitter_correction = lua_a:checkbox("~ Jitter \f<pl>Correction"),
        def_correction = lua_a:checkbox("~ Defensive \f<pl>Correction"), 
        lag_fix = lua_a:checkbox("~ Lag Compensation \f<pl>Fix"),
        reset_data = lua_b:button("Reset Data", function() reset_all_data() end),
        label2 = lua_a:label(" ")
    },
    unmatched = {
        label = lua_a:label("\f<gr>#Unmatched Resolver"),
        unmatched_resolver = lua_a:checkbox("~ Unmatched \f<pl>Resolver"),
        resolver_aggression = lua_a:slider("~ Aggression", 0, 100, 65, "%d%%"),
        prediction_speed = lua_a:slider("~ Prediction", 0, 100, 70, "%d%%"),
        brute_force = lua_a:checkbox("~ Logic-based \f<pl>Brute Force"),
        reset_unmatched = lua_b:button("Reset Unmatched Data", function() reset_unmatched() end),
        label4 = lua_a:label(" ")
    },
    features = {
        label3 = lua_a:label("\f<gr>#Features"),
        trash_talk = lua_a:checkbox("~ Trash \f<pl>Talk"),
        clantag = lua_a:checkbox("~ Clan \f<pl>Tag"),
        shared_logo = lua_a:checkbox("~ Shared \f<pl>Logo"),
        label4 = lua_a:label(" ")
    },
    information = {
        text = lua_a:label("\f<gr>#Information"),
        name = lua_a:label(" User: \f<pl>" .. safedata.username),
        version = lua_a:label(" Version: \f<pl>" .. safedata.version),
        loaded = lua_a:label(" Updated at: \f<pl>" .. safedata.upd),
        text1 = lua_a:label(" "),
        devtext = lua_a:label("\f<gr>" .. safedata.dev),
        discord = lua_b:button("Discord ~ \f<pl>", function() 
            SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/JFxkm3TrEr")
        end),
        telegram = lua_b:button("Telegram ~ \f<pl>", function() 
            SteamOverlayAPI.OpenExternalBrowserURL("https://t.me/safesolver")
        end)
    }
}

local function update_menu_visibility()
    local selected = menu.combo.combo:get()
    local is_home = (selected == "Home")
    local is_features = (selected == "Features")
    local is_resolver = (selected == "Resolver")
    local is_unmatched = (selected == "Unmatched")
    local resolver_enabled = menu.main.enable:get()

    for _, element in pairs(menu.main) do
        if element and element.set_visible then
            element:set_visible(is_resolver)
        end
    end
    for _, element in pairs(menu.features) do
        if element and element.set_visible then
            element:set_visible(is_features)
        end
    end
    for _, element in pairs(menu.unmatched) do
        if element and element.set_visible then
            element:set_visible(is_unmatched)
        end
    end
    for _, element in pairs(menu.information) do
        if element and element.set_visible then
            element:set_visible(is_home)
        end
    end
end

menu.combo.combo:set_callback(function()
    update_menu_visibility()
end)
update_menu_visibility()


--# > shared logo

local GITHUB_TOKEN = "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"
local REPO_OWNER = "celexuw-glitch"
local REPO_NAME = "centrumental"
local FILE_PATH = "players.json"

local icons = {
    stable = 'https://github.com/celexuw-glitch/centrumental/blob/main/image/Icon_Stable.png?raw=true',
    developer = 'https://raw.githubusercontent.com/celexuw-glitch/centrumental/main/image/Icon_Dev.png',
}

local user_data = {}

local scoreboard_images = panorama.loadstring([[
    var panel = null;
    var name_panels = {};
    var target_players = {};
    var user_icons = {};

    var _Update = function(players, icons_data) {
        _Destroy();
        target_players = players || {};
        user_icons = icons_data || {};
        
        let scoreboard = $.GetContextPanel().FindChildTraverse("ScoreboardContainer").FindChildTraverse("Scoreboard");
      
        if (!scoreboard) return;

        scoreboard.FindChildrenWithClassTraverse("sb-row").forEach(function(row) {
            var xuid = row.m_xuid;
            
            if (target_players[xuid] && user_icons[xuid]) {
                row.style.backgroundColor = "rgb(0, 0, 0)";
                row.style.border = "1px solid rgb(94, 94, 94)";
              
                row.Children().forEach(function(child) {
                    let nameLabel = child.FindChildTraverse("name");
                    if (nameLabel) {
                        nameLabel.style.color = "rgb(155, 155, 155)";
                        nameLabel.style.fontFamily = "Stratum2 Bold Monodigit";
                        nameLabel.style.fontWeight = "bold";
                        
                        let parent = nameLabel.GetParent();
                        parent.style.flowChildren = "left";

                        let image_panel = $.CreatePanel("Panel", parent, "custom_image_panel_" + xuid);
                        
                        var icon_url = user_icons[xuid];
                        var layout = `
                        <root>
                            <Panel style="flow-children: left; margin-right: 5px;">
                                <Image textureheight="24" texturewidth="24" src="` + icon_url + `" />
                            </Panel>
                        </root>
                        `;

                        image_panel.BLoadLayoutFromString(layout, false, false);
                        parent.MoveChildBefore(image_panel, nameLabel);
                        name_panels[xuid] = image_panel;
                    }
                });
            }
        });
    };

    var _Destroy = function() {
        let scoreboard = $.GetContextPanel().FindChildTraverse("ScoreboardContainer").FindChildTraverse("Scoreboard");
      
        if (scoreboard) {
            scoreboard.FindChildrenWithClassTraverse("sb-row").forEach(function(row) {
                row.style.backgroundColor = null;
                row.style.border = null;
              
                row.Children().forEach(function(child) {
                    let nameLabel = child.FindChildTraverse("name");
                    if (nameLabel) {
                        nameLabel.style.color = null;
                        nameLabel.style.fontFamily = "Stratum2";
                        nameLabel.style.fontWeight = "normal";
                    }
                });
            });
        }

        for (var xuid in name_panels) {
            if (name_panels[xuid] && name_panels[xuid].IsValid()) {
                name_panels[xuid].DeleteAsync(0.0);
            }
        }
      
        name_panels = {};
        target_players = {};
        user_icons = {};
    };

    return {
        update: _Update,
        remove: _Destroy
    };
]], "CSGOHud")()

local function update_github_file(steamid, build_status, action)
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Accept"] = "application/vnd.github.v3+json"
    }
  
    local api_url = string.format(
        "https://api.github.com/repos/%s/%s/contents/%s",
        REPO_OWNER, REPO_NAME, FILE_PATH
    )

    http.get(api_url, {headers = headers}, function(success, response)
        if not success then
                print("#shared | Ошибка получения данных")
            return 
        end
      
        local current_data = {}
        local sha = nil
      
        if response.status == 200 then
            local content = json.parse(response.body)
            sha = content.sha
            current_data = json.parse(base64.decode(content.content))
        end
        
        if action == "add" then
            current_data[tostring(steamid)] = build_status
        elseif action == "remove" then
            current_data[tostring(steamid)] = nil
        end
      
        local update_data = {
            message = string.format("update - %s %s", action, steamid),
            content = base64.encode(json.stringify(current_data)),
            sha = sha
        }
      
        http.put(api_url, {
            headers = headers,
            body = json.stringify(update_data)
        }, function(success, response)
        end)
    end)
end

local function get_local_steamid()
    return tostring(panorama.open().MyPersonaAPI.GetXuid())
end

local function update_safedata_status(status)
    safedata.build = status
end

local function update_target_players(github_data)
    user_data = {}
    for steamid, build_status in pairs(github_data) do
        if build_status == "stable" then
            user_data[steamid] = icons.stable
        elseif build_status == "developer" then
            user_data[steamid] = icons.developer
        end
    end
    scoreboard_images.update(user_data, user_data)
end

local function check_and_update_github()
    if GITHUB_TOKEN == "" or REPO_OWNER == "" or REPO_NAME == "" then
        return
    end
    
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Accept"] = "application/vnd.github.v3+json"
    }
  
    local api_url = string.format(
        "https://api.github.com/repos/%s/%s/contents/%s",
        REPO_OWNER, REPO_NAME, FILE_PATH
    )

    http.get(api_url, {headers = headers}, function(success, response)
        if success and response.status == 200 then
            local content = json.parse(response.body)
            local current_data = json.parse(base64.decode(content.content))
            update_target_players(current_data)
        end
    end)
end

local function select_user_status()
    local steamid = get_local_steamid()
    if steamid then
        if safedata.build == "developer" then
            update_github_file(steamid, "developer", "add")
            update_safedata_status("developer")
        else
            update_github_file(steamid, "stable", "add")
            update_safedata_status("stable")
        end
    end
end

client.set_event_callback("player_connect_full", function(e)
    local steamid = get_local_steamid()
    if steamid then
        select_user_status()
        
        local target = client.userid_to_entindex(e.userid)
        if target == entity.get_local_player() then
            scoreboard_images.remove()
            client.delay_call(0.5, function()
                scoreboard_images.update(user_data, user_data)
            end)
        end
    end
end)

check_and_update_github()

local last_update = 0
local last_github_check = 0

client.set_event_callback('paint', function()
    local current_time = globals.realtime()
    
    if current_time - last_update >= 3.0 then
        scoreboard_images.update(user_data, user_data)
        last_update = current_time
    end

    if current_time - last_github_check >= 1.5 then
        check_and_update_github()
        last_github_check = current_time
    end
end)

menu.features.shared_logo:set_callback(function()
    local steamid = get_local_steamid()
    if not menu.features.shared_logo:get() then
        scoreboard_images.remove()
        update_github_file(steamid, nil, "remove")
    else
        select_user_status()
        check_and_update_github()
    end
end)

client.set_event_callback("shutdown", function()
    local steamid = get_local_steamid()
    if steamid and not menu.features.shared_logo:get() then
        update_github_file(steamid, nil, "remove")
    end
    scoreboard_images.remove()
end)

--# > features

--# < animation
local anim = {active=false, img=nil, alpha=0, start=0, type=nil, fade=0, display=0, sound=false}

local function load_anim_image(url, t)
    http.get(url, function(s, r)
        if s and r.status == 200 then
            local img = renderer.load_png(r.body, 565, 535)
            if img then
                anim.active, anim.img, anim.alpha = true, img, 0
                anim.start, anim.type, anim.sound = globals.realtime(), t, false
                if t == "load" then
                    anim.fade, anim.display = 0.4, 1.5
                else
                    anim.fade, anim.display = 0.3, 0.2
                end
            end
        end
    end)
end
load_anim_image("://raw.githubusercontent.com/celexuw-glitch/centrumental/main/image/safeloaded.png", "load")

local function draw_anim()
    if not anim.active or not anim.img then return end
    local elapsed = globals.realtime() - anim.start
    local total = anim.fade * 2 + anim.display
    if elapsed >= total then
        anim.active, anim.img = false, nil
        return
    end
    if elapsed < anim.fade then
        anim.alpha = math.floor((elapsed / anim.fade) * 255)
    elseif elapsed < anim.fade + anim.display then
        anim.alpha = 255
    else
        anim.alpha = math.floor((1 - (elapsed - anim.fade - anim.display) / anim.fade) * 255)
    end
    if not anim.sound then
        client.exec(anim.type == "load" and "play music/nemesis.wav" or "play ui/panorama/music_equip_01.wav")
        anim.sound = true
    end
    local sx, sy = client.screen_size()
    renderer.texture(anim.img, (sx - 565) / 2, (sy - 485) / 2, 565, 535, 255, 255, 255, anim.alpha)
end

local was = false
local function check_resolver_anim()
    local enabled = menu.main.enable:get()
    if enabled and not was and not anim.active then
        load_anim_image("://raw.githubusercontent.com/celexuw-glitch/centrumental/main/image/safeenabled.png", "enable")
    end
    was = enabled
end

--# < trash talk
local trash_phrases = {
    ">..< get gamesense'd by safesolver",
    "^,.,^ safesolver",
    "t.me/safesolver",
    "stay mad >_< safesolver",
    "𝚝.𝚖𝚎/𝚜𝚊𝚏𝚎𝚜𝚘𝚕𝚟𝚎𝚛",
    "𝑫𝑶𝑵𝑻 𝑩𝑬 𝑺𝑻𝑼𝑷𝑰𝑫 ~ 𝑼𝑺𝑬 𝑺𝑨𝑭𝑬𝑺𝑶𝑳𝑽𝑬𝑹",
    "𝒔𝒐 𝒘𝒉𝒂𝒕 𝒏𝒐𝒘?",
    "𝒈𝒐𝒅 𝒗𝒔 𝒍𝒐𝒔𝒆𝒓",
    "𝒅𝒐𝒏𝒕 𝒂𝒔𝒌, 𝒋𝒖𝒔𝒕 𝒖𝒔𝒆 𝒔𝒂𝒇𝒆𝒔𝒐𝒍𝒗𝒆𝒓",
    ">_< 𝒖𝒓 𝒔𝒐 𝒃𝒂𝒅 𝒘𝒐𝒖𝒕 𝒔𝒂𝒇𝒆𝒔𝒐𝒍𝒗𝒆𝒓",
    "@,..,@ desync god vs you",
    "^...^ stay hardstuck",
    "^...^ desync king"
}

local function on_death(e)
    if not menu.features.trash_talk:get() then return end
    local victim_userid = e.userid
    local attacker_userid = e.attacker
    if not victim_userid or not attacker_userid then return end
    local victim = client.userid_to_entindex(victim_userid)
    local attacker = client.userid_to_entindex(attacker_userid)
    local local_player = entity.get_local_player()
    if attacker == local_player and entity.is_enemy(victim) then
        local random_index = math.random(1, #trash_phrases)
        local phrase = trash_phrases[random_index]
        client.exec("say " .. phrase)
    end
end

client.set_event_callback("player_death", function(e)
    on_death(e)
end)

--# < clan tag
local clan = "#safesolver"
local clan_state = { 
    active = false,
    current_text = "",
    animation_direction = 1,
    position = 0,
    last_update = 0,
    update_interval = 0.2
}

local function update_clan()
    if not menu.features.clantag:get() then
        if clan_state.active then
            client.set_clan_tag("")
            clan_state.active = false
            clan_state.current_text = ""
            clan_state.position = 0
            clan_state.animation_direction = 1
        end
        return
    end
    local current_time = globals.realtime()
    if current_time - clan_state.last_update >= clan_state.update_interval then
        clan_state.last_update = current_time
        if clan_state.animation_direction == 1 then
            clan_state.position = clan_state.position + 1
            clan_state.current_text = string.sub(clan, 1, clan_state.position)
            if clan_state.position >= #clan then
                clan_state.animation_direction = -1
                clan_state.last_update = current_time + 0.5
            end
        else
            clan_state.position = clan_state.position - 1
            clan_state.current_text = string.sub(clan, 1, clan_state.position)
            if clan_state.position <= 0 then
                clan_state.animation_direction = 1
                clan_state.last_update = current_time + 0.5
            end
        end
        client.set_clan_tag(clan_state.current_text)
        clan_state.active = true
    end
end

--# > constans

local MAX_PLAYERS = 64
local MAX_HISTORY = 120
local FL_ONGROUND = bit.lshift(1, 0)
local FL_DUCKING = bit.lshift(1, 1)
local MAX_DESYNC_BASE = 58.0
local CS_PLAYER_SPEED_RUN = 260.0
local CS_PLAYER_SPEED_WALK_MODIFIER = 0.52
local TICK_INTERVAL = 1 / 64

local JITTER_THRESHOLD = 8.0
local SPIN_THRESHOLD = 180
local SWAY_THRESHOLD = 45
local PROGRESSIVE_THRESHOLD = 15

local PITCH_STATIC_RANGE = 5
local PITCH_JITTER_RANGE = 20
local PITCH_SPIN_RANGE = 178
local PITCH_RANDOM_RANGE = 100

local YAW_STATIC_RANGE = 10
local YAW_JITTER_RANGE = 35
local YAW_SWAY_RANGE = 65

local ANIMATION_LAYER_OFFSETS = {
    [6] = 0x00,
    [11] = 0x00
}

--# > global tables

local ResolverData = {}
local JitterWindow = {}
local DefensiveData = {}
local MovementHistory = {}
local UnmatchedData = {}
local TickbaseHistory = {}
local AnimationLayerCache = {}
local LagCompensationData = {}

--# > helpers

local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

local function norm_angle(angle)
    if not angle then return 0 end
    angle = angle % 360
    if angle > 180 then angle = angle - 360 end
    return angle
end

local function angle_diff(dest, src)
    if not dest or not src then return 0 end
    local delta = (dest - src) % 360
    if delta > 180 then delta = delta - 360 end
    return delta
end

local function vec_len2d(vec)
    if not vec then return 0 end
    local x = vec.x or 0
    local y = vec.y or 0
    return math.sqrt(x * x + y * y)
end

local function exp_smooth(prev, current, alpha)
    return prev * alpha + current * (1 - alpha)
end

--# > init pl data

local function init_player(player)
    if not ResolverData then
        ResolverData = {}
    end
    
    if not ResolverData[player] then
        ResolverData[player] = {
            resolved_yaw = 0,
            resolved_side = "unknown",
            aa_type = "unknown",
            last_eye_yaw = 0,
            last_eye_pitch = 0,
            desync_delta = 0,
            hit_confidence = 0.5,
            adaptive_side = "unknown",
            last_resolve_time = 0,
            consecutive_misses = 0,
            misses = 0,
            last_hit_side = nil,
            hit_angles = {},
            last_hit_yaw = nil,
            kalman_state = {x = 0, p = 1, q = 0.05, r = 0.1},
            pll_state = {phase = 0, freq = 1.5, lock_time = 0},
            fft_buffer = {},
            defensive_ticks = 0,
            confidence_score = 0.5,
            unmatched_mode = false,
            last_corrected_yaw = nil,
            last_amp = nil
        }
    end
    return ResolverData[player]
end

--# > anim state

local raw_ientitylist = client.create_interface('client.dll', 'VClientEntityList003')
local ientitylist = raw_ientitylist and ffi.cast("void***", raw_ientitylist)
local get_client_entity = ientitylist and ffi.cast("void*(__thiscall*)(void*, int)", ientitylist[0][3])

local animstate_cache = {}
local animstate_cache_time = {}

local function get_animstate(player)
    if not player or not get_client_entity then return nil end
    
    local now = globals.realtime()
    if animstate_cache[player] and animstate_cache_time[player] and now - animstate_cache_time[player] < 0.05 then
        return animstate_cache[player]
    end
    
    local player_ptr = get_client_entity(ientitylist, player)
    if not player_ptr then return nil end
    
    local animstate_ptr = ffi.cast("uintptr_t", player_ptr) + 0x9960
    local result = ffi.cast("CCSGOPlayerAnimationState_t**", animstate_ptr)[0]
    
    animstate_cache[player] = result
    animstate_cache_time[player] = now
    
    return result
end

--# > lagcomp fix

local function lag_fix(player, eye_yaw, animstate)
    if not menu.main.lag_fix:get() then return eye_yaw, false end
    
    if not LagCompensationData[player] then
        LagCompensationData[player] = {
            last_origin = vector(0, 0, 0),
            last_simtime = 0,
            velocity_samples = {},
            extrapolated_yaw = eye_yaw,
            lag_spike_detected = false,
            compensation_active = false,
            tick_rate_comp = 1.0,
            last_comp_yaw = eye_yaw,
            ping_history = {},
            latency_smoothing = 0,
            last_shot_tick = 0,
            missed_ticks = 0,
            interpolation_buffer = {}
        }
    end
    
    local data = LagCompensationData[player]
    local current_origin = vector(entity.get_origin(player))
    local current_simtime = entity.get_prop(player, "m_flSimulationTime") or 0
    local local_player = entity.get_local_player()
    
    if not local_player then return eye_yaw, false end
    
    local local_origin = vector(entity.get_origin(local_player))
    local tick_interval = globals.tickinterval() or 1/64
    local current_tick = globals.tickcount()
    
    local ping = client.latency() or 0
    table.insert(data.ping_history, ping)
    if #data.ping_history > 30 then table.remove(data.ping_history, 1) end
    
    local avg_ping = 0
    local ping_variance = 0
    if #data.ping_history > 0 then
        for _, p in ipairs(data.ping_history) do
            avg_ping = avg_ping + p
        end
        avg_ping = avg_ping / #data.ping_history
        for _, p in ipairs(data.ping_history) do
            ping_variance = ping_variance + (p - avg_ping)^2
        end
        ping_variance = ping_variance / #data.ping_history
    end
    
    local simtime_diff = current_simtime - data.last_simtime
    local expected_diff = tick_interval
    local lag_factor = 1.0
    local spike_magnitude = 1.0
    
    if simtime_diff > expected_diff + 0.01 then
        data.lag_spike_detected = true
        spike_magnitude = simtime_diff / expected_diff
        lag_factor = clamp(1.0 / spike_magnitude, 0.5, 1.0)
        data.compensation_active = true
        data.missed_ticks = data.missed_ticks + 1
    else
        if data.lag_spike_detected then
            data.lag_spike_detected = false
            data.missed_ticks = math.max(0, data.missed_ticks - 1)
        end
    end
    
    if data.last_origin and data.last_origin.x ~= 0 then
        local velocity = (current_origin - data.last_origin) / math.max(simtime_diff, 0.001)
        table.insert(data.velocity_samples, {vel = velocity, time = globals.realtime(), weight = clamp(simtime_diff / expected_diff, 0.5, 1.5)})
        
        if #data.velocity_samples > 12 then
            table.remove(data.velocity_samples, 1)
        end
    end
    
    local avg_velocity = vector(0, 0, 0)
    local total_weight = 0
    if #data.velocity_samples > 0 then
        local now_time = globals.realtime()
        for i, sample in ipairs(data.velocity_samples) do
            local age_weight = 1.0 - (now_time - sample.time) * 2
            age_weight = clamp(age_weight, 0.2, 1.0)
            local final_weight = sample.weight * age_weight
            avg_velocity = avg_velocity + sample.vel * final_weight
            total_weight = total_weight + final_weight
        end
        if total_weight > 0 then
            avg_velocity = avg_velocity / total_weight
        end
    end
    
    local ping_ticks = math.floor(avg_ping / tick_interval + 0.5)
    ping_ticks = clamp(ping_ticks, 0, 10)
    
    local variance_factor = 1.0 + clamp(ping_variance / 100, 0, 0.5)
    local compensation_strength = clamp(0.2 + ping_ticks * 0.06, 0.2, 0.7) * variance_factor
    
    local vel_2d = avg_velocity:length2d()
    local extrapolation_time = ping + tick_interval * (data.missed_ticks + 1)
    if vel_2d < 50 then
        extrapolation_time = extrapolation_time * 0.5
    elseif vel_2d > 200 then
        extrapolation_time = extrapolation_time * 1.2
    end
    
    local extrapolated_origin = current_origin + avg_velocity * extrapolation_time
    
    local dir_to_extrapolated = (extrapolated_origin - local_origin):normalized()
    local extrapolated_target_yaw = math.atan2(dir_to_extrapolated.y, dir_to_extrapolated.x) * 180 / math.pi
    
    local blend_factor = compensation_strength * lag_factor
    if data.lag_spike_detected then
        blend_factor = clamp(blend_factor * 1.3, 0.3, 0.8)
    end
    
    local compensated_yaw = norm_angle(eye_yaw * (1 - blend_factor) + extrapolated_target_yaw * blend_factor)
    
    table.insert(data.interpolation_buffer, compensated_yaw)
    if #data.interpolation_buffer > 5 then
        table.remove(data.interpolation_buffer, 1)
    end
    
    if #data.interpolation_buffer >= 2 then
        local smoothed_yaw = 0
        for i, y in ipairs(data.interpolation_buffer) do
            local weight = i / #data.interpolation_buffer
            smoothed_yaw = smoothed_yaw + y * weight
        end
        smoothed_yaw = smoothed_yaw / ((#data.interpolation_buffer + 1) / 2)
        compensated_yaw = norm_angle(smoothed_yaw)
    end
    
    local yaw_diff = angle_diff(compensated_yaw, data.last_comp_yaw)
    local max_change = data.lag_spike_detected and 35 or 22
    if math.abs(yaw_diff) > max_change then
        compensated_yaw = norm_angle(data.last_comp_yaw + yaw_diff * (max_change / math.abs(yaw_diff)))
    end
    
    data.tick_rate_comp = exp_smooth(data.tick_rate_comp, lag_factor, 0.85)
    
    data.extrapolated_yaw = compensated_yaw
    data.last_comp_yaw = compensated_yaw
    data.last_origin = current_origin
    data.last_simtime = current_simtime
    data.latency_smoothing = exp_smooth(data.latency_smoothing, ping, 0.7)
    
    if not data.lag_spike_detected and data.compensation_active then
        if data.missed_ticks == 0 then
            data.compensation_active = false
        end
    end
    
    return compensated_yaw, data.lag_spike_detected
end

--# > move analyze

local function analyze_move(player)
    local velocity = vector(entity.get_prop(player, "m_vecVelocity"))
    local vel_2d = velocity:length2d()
    local flags = entity.get_prop(player, "m_fFlags")
    local on_ground = bit.band(flags, FL_ONGROUND) ~= 0
    local ducking = bit.band(flags, FL_DUCKING) ~= 0
    
    if not MovementHistory then
        MovementHistory = {}
    end
    
    if not MovementHistory[player] then
        MovementHistory[player] = {}
    end
    
    local history = MovementHistory[player]
    table.insert(history, {
        vel_2d = vel_2d,
        on_ground = on_ground,
        ducking = ducking,
        time = globals.realtime()
    })
    
    if #history > 45 then
        table.remove(history, 1)
    end
    
    local move_state = "standing"
    if not on_ground then
        move_state = "airborne"
    elseif ducking then
        move_state = "crouching"
    elseif vel_2d > CS_PLAYER_SPEED_RUN * 0.8 then
        move_state = "running"
    elseif vel_2d > CS_PLAYER_SPEED_WALK_MODIFIER * CS_PLAYER_SPEED_RUN then
        move_state = "walking"
    elseif vel_2d > 5 then
        move_state = "slow_walking"
    end
    
    return move_state, vel_2d
end

--# > pitch detect

local function detect_pitch(pitch_history)
    local history_len = #pitch_history
    local min_history = 16
    if history_len < min_history then
        return {type = "analyzing", confidence = 0, params = {}}
    end
    
    local min_pitch, max_pitch = pitch_history[1], pitch_history[1]
    local sum_pitch = 0
    local deltas = {}
    local zero_crossings = 0
    local last_sign = 0
    local pattern_peaks = {}
    
    for i = 1, history_len do
        local p = pitch_history[i]
        sum_pitch = sum_pitch + p
        if p < min_pitch then min_pitch = p end
        if p > max_pitch then max_pitch = p end
        
        if i > 1 then
            local diff = p - pitch_history[i-1]
            table.insert(deltas, diff)
            
            local sign = diff > 0 and 1 or (diff < 0 and -1 or 0)
            if sign ~= 0 and last_sign ~= 0 and sign ~= last_sign then
                zero_crossings = zero_crossings + 1
                table.insert(pattern_peaks, i)
            end
            last_sign = sign
        end
    end
    
    local avg_pitch = sum_pitch / history_len
    local range = max_pitch - min_pitch
    
    local sum_abs_delta = 0
    local max_delta = 0
    for _, d in ipairs(deltas) do
        local abs_d = math.abs(d)
        sum_abs_delta = sum_abs_delta + abs_d
        if abs_d > max_delta then max_delta = abs_d end
    end
    local avg_delta = sum_abs_delta / #deltas
    local frequency = zero_crossings / #deltas
    
    local pattern = {type = "unknown", confidence = 0, params = {}}
    
    if range <= PITCH_STATIC_RANGE and avg_delta < 2 then
        pattern.type = "static"
        pattern.confidence = 0.96
        pattern.params.value = avg_pitch
        pattern.params.description = string.format("static at %.1f", avg_pitch)
    
    elseif avg_delta >= 2 and avg_delta <= 14 and frequency > 0.35 then
        pattern.type = "jitter"
        pattern.confidence = 0.89
        pattern.params.amplitude = avg_delta
        pattern.params.frequency = frequency
        pattern.params.center = avg_pitch
        pattern.params.description = string.format("jitter (amp: %.1f)", avg_delta)
    
    elseif range >= PITCH_SPIN_RANGE and max_delta > 30 then
        pattern.type = "spin"
        pattern.confidence = 0.93
        pattern.params.range = range
        pattern.params.description = string.format("spin (range: %.1f)", range)
    
    elseif avg_pitch < -70 or avg_pitch > 70 then
        pattern.type = "fake"
        pattern.confidence = 0.91
        pattern.params.pitch = avg_pitch
        pattern.params.description = string.format("fake pitch (%.1f)", avg_pitch)
    end
    
    return pattern
end

--# > yaw detect

local function detect_yaw(yaw_history)
    local history_len = #yaw_history
    local min_history = 16
    if history_len < min_history then
        return {type = "analyzing", confidence = 0, params = {}}
    end
    
    local normalized_yaws = {}
    for _, y in ipairs(yaw_history) do
        table.insert(normalized_yaws, norm_angle(y))
    end
    
    local min_yaw, max_yaw = normalized_yaws[1], normalized_yaws[1]
    local sum_yaw = 0
    local deltas = {}
    local zero_crossings = 0
    local last_sign = 0
    local direction_consistency = 0
    
    for i = 1, history_len do
        local y = normalized_yaws[i]
        sum_yaw = sum_yaw + y
        if y < min_yaw then min_yaw = y end
        if y > max_yaw then max_yaw = y end
        
        if i > 1 then
            local diff = angle_diff(y, normalized_yaws[i-1])
            table.insert(deltas, diff)
            
            local sign = diff > 0 and 1 or (diff < 0 and -1 or 0)
            if sign ~= 0 then
                if last_sign ~= 0 and sign ~= last_sign then
                    zero_crossings = zero_crossings + 1
                end
                direction_consistency = direction_consistency + sign
            end
            last_sign = sign
        end
    end
    
    local avg_yaw = sum_yaw / history_len
    local range = angle_diff(max_yaw, min_yaw)
    if not range then range = 0 end
    if range < 0 then range = -range end
    
    local sum_abs_delta = 0
    local max_delta = 0
    for _, d in ipairs(deltas) do
        local abs_d = math.abs(d)
        sum_abs_delta = sum_abs_delta + abs_d
        if abs_d > max_delta then max_delta = abs_d end
    end
    local avg_delta = #deltas > 0 and sum_abs_delta / #deltas or 0
    local frequency = #deltas > 0 and zero_crossings / #deltas or 0
    
    local pattern = {type = "unknown", confidence = 0, params = {}}
    
    if range <= YAW_STATIC_RANGE and avg_delta < 2 then
        pattern.type = "static"
        pattern.confidence = 0.97
        pattern.params.value = avg_yaw
        pattern.params.description = string.format("static at %.1f", avg_yaw)
    
    elseif math.abs(avg_yaw) < 15 and avg_delta < 5 then
        pattern.type = "fake_zero"
        pattern.confidence = 0.94
        pattern.params.description = "fake zero desync"
    
    elseif avg_delta >= 5 and avg_delta <= YAW_JITTER_RANGE and frequency > 0.35 then
        pattern.type = "jitter"
        pattern.confidence = 0.88
        pattern.params.amplitude = avg_delta
        pattern.params.frequency = frequency
        pattern.params.center = avg_yaw
        pattern.params.description = string.format("jitter (amp: %.1f)", avg_delta)
    
    elseif range > 300 and avg_delta > 20 then
        local spin_direction = direction_consistency / #deltas
        pattern.type = "spin"
        pattern.confidence = 0.92
        pattern.params.direction = spin_direction > 0 and "right" or "left"
        pattern.params.rate = avg_delta
        pattern.params.description = string.format("spin %s (rate: %.1f)", pattern.params.direction, avg_delta)
    
    elseif avg_delta > 25 and range > 120 then
        pattern.type = "random"
        pattern.confidence = 0.77
        pattern.params.range = range
        pattern.params.description = string.format("random (range: %.1f)", range)
    
    elseif range >= YAW_SWAY_RANGE and avg_delta >= 15 and avg_delta <= 40 and frequency < 0.3 then
        pattern.type = "sway"
        pattern.confidence = 0.83
        pattern.params.range = range
        pattern.params.frequency = frequency
        pattern.params.description = string.format("sway (range: %.1f)", range)
    end
    
    return pattern
end

--# > calc max desync

local function calc_max_desync(animstate, move_state, pattern_type, pattern_confidence)
    if not animstate then return MAX_DESYNC_BASE end
    
    local speedfactor = animstate.flSpeedNormalized or 0
    local duck_amount = animstate.flDuckAmount or 0
    local walk_to_run = animstate.flWalkToRunTransition or 0
    
    local move_mod = 1.0
    if move_state == "running" then
        move_mod = 0.40
    elseif move_state == "walking" then
        move_mod = 0.62
    elseif move_state == "crouching" then
        move_mod = 0.80
    elseif move_state == "slow_walking" then
        move_mod = 0.86
    elseif move_state == "airborne" then
        move_mod = 0.92
    end
    
    local pattern_mod = 1.0
    if pattern_type == "jitter" then
        pattern_mod = 0.80 + (1 - pattern_confidence) * 0.18
    elseif pattern_type == "spin" then
        pattern_mod = 0.65
    elseif pattern_type == "random" then
        pattern_mod = 0.92
    elseif pattern_type == "static" then
        pattern_mod = 0.88
    elseif pattern_type == "sway" then
        pattern_mod = 0.76
    elseif pattern_type == "fake_zero" then
        pattern_mod = 0.86
    end
    
    local speed_mod = 1.0 - (speedfactor * 0.35)
    local duck_mod = 1.0 - (duck_amount * 0.25)
    local transition_mod = 1.0 - (walk_to_run * 0.25)
    
    local final_desync = MAX_DESYNC_BASE * move_mod * speed_mod * duck_mod * transition_mod * pattern_mod
    
    return clamp(final_desync, 12, MAX_DESYNC_BASE)
end

--# > tickbase detect

local function detect_tickbase(player)
    local animstate = get_animstate(player)
    if not animstate then return false, 0, nil end
    
    local current_simtime = entity.get_prop(player, "m_flSimulationTime") or 0
    local current_cycle = animstate.flFeetCycle or 0
    
    if not TickbaseHistory[player] then
        TickbaseHistory[player] = {
            last_simtime = current_simtime,
            last_cycle = current_cycle,
            shifts = {},
            shift_detected = false,
            shift_count = 0,
            last_shift_time = 0,
            shift_pattern = {}
        }
    end
    
    local history = TickbaseHistory[player]
    local simtime_diff = current_simtime - history.last_simtime
    local expected_diff = globals.tickinterval() or 1/64
    
    local is_shift = simtime_diff > expected_diff + 0.008
    local shift_amount = 0
    
    if is_shift then
        shift_amount = math.floor(simtime_diff / expected_diff + 0.5)
        shift_amount = clamp(shift_amount, 1, 16)
        
        history.shift_detected = true
        history.shift_count = history.shift_count + 1
        history.last_shift_time = globals.realtime()
        
        table.insert(history.shifts, {
            amount = shift_amount,
            time = globals.realtime(),
            cycle = current_cycle
        })
        
        table.insert(history.shift_pattern, shift_amount)
        if #history.shift_pattern > 12 then
            table.remove(history.shift_pattern, 1)
        end
        
        if #history.shifts > 25 then
            table.remove(history.shifts, 1)
        end
    else
        history.shift_detected = false
    end
    
    history.last_simtime = current_simtime
    history.last_cycle = current_cycle
    
    return history.shift_detected, shift_amount, history
end

--# > kalman

local function kalman_update(state, measurement)
    local x_pred = state.x
    local p_pred = state.p + state.q
    
    local k = p_pred / (p_pred + state.r)
    local x_new = x_pred + k * (measurement - x_pred)
    local p_new = (1 - k) * p_pred
    
    state.x = x_new
    state.p = p_new
    
    return x_new
end

--# > autocorr

local function autocorr(samples, max_lag)
    local n = #samples
    if n < 16 then return 0, 0 end
    
    max_lag = max_lag or math.min(math.floor(n / 2), 32)
    local correlations = {}
    
    for lag = 1, max_lag do
        local sum = 0
        local sum_sq_x = 0
        local sum_sq_y = 0
        local count = 0
        
        for i = 1, n - lag do
            local x = samples[i]
            local y = samples[i + lag]
            if x and y then
                sum = sum + x * y
                sum_sq_x = sum_sq_x + x * x
                sum_sq_y = sum_sq_y + y * y
                count = count + 1
            end
        end
        
        if count > 0 and sum_sq_x > 0 and sum_sq_y > 0 then
            correlations[lag] = sum / math.sqrt(sum_sq_x * sum_sq_y)
        else
            correlations[lag] = 0
        end
    end
    
    local best_lag = 1
    local best_corr = 0
    
    for lag = 2, max_lag do
        if correlations[lag] > best_corr then
            best_corr = correlations[lag]
            best_lag = lag
        end
    end
    
    return best_lag, best_corr
end

local function fft_power(samples)
    local n = #samples
    if n < 8 then return {} end
    
    local power = {}
    
    for k = 1, math.min(math.floor(n/2), 16) do
        local real_sum = 0
        local imag_sum = 0
        for t = 1, n do
            local angle = 2 * math.pi * (k-1) * (t-1) / n
            real_sum = real_sum + samples[t] * math.cos(angle)
            imag_sum = imag_sum - samples[t] * math.sin(angle)
        end
        power[k] = (real_sum * real_sum + imag_sum * imag_sum) / (n * n)
    end
    
    return power
end

--# > stabilize jitter

local function stabilize_jitter(player, eye_yaw, yaw_pattern)
    local data = init_player(player)
    
    if not JitterWindow[player] then
        JitterWindow[player] = {}
    end
    
    local window = JitterWindow[player]
    table.insert(window, eye_yaw)
    
    local max_window = 90
    if #window > max_window then
        table.remove(window, 1)
    end
    
    if #window < 25 then
        return eye_yaw, 0, "analyzing", 0.5, 0
    end
    
    local lag, corr = autocorr(window, math.min(math.floor(#window / 2), 35))
    
    local power_spectrum = fft_power(window)
    
    local dominant_freq_idx = 1
    local max_power = 0
    for idx, p in ipairs(power_spectrum) do
        if p > max_power then
            max_power = p
            dominant_freq_idx = idx
        end
    end
    
    local period_ticks = lag
    if corr < 0.55 then
        period_ticks = math.max(4, math.floor(64 / 2.3))
    end
    
    local sorted_window = {}
    for i, val in ipairs(window) do
        table.insert(sorted_window, val)
    end
    table.sort(sorted_window)
    
    local q1 = sorted_window[math.floor(#sorted_window * 0.25)]
    local q3 = sorted_window[math.floor(#sorted_window * 0.75)]
    local iqr = q3 - q1
    local lower_bound = q1 - iqr * 1.5
    local upper_bound = q3 + iqr * 1.5
    
    local filtered_window = {}
    for _, val in ipairs(window) do
        if val >= lower_bound and val <= upper_bound then
            table.insert(filtered_window, val)
        end
    end
    
    if #filtered_window < 10 then
        filtered_window = window
    end
    
    table.sort(filtered_window)
    local center = filtered_window[math.floor(#filtered_window / 2)]
    
    local amplitudes = {}
    for _, val in ipairs(filtered_window) do
        local dev = math.abs(angle_diff(val, center))
        table.insert(amplitudes, dev)
    end
    table.sort(amplitudes)
    local median_amp = amplitudes[math.floor(#amplitudes / 2)]
    
    local now = globals.realtime()
    local tick_interval = globals.tickinterval() or 1/64
    local phase_velocity = 1.0 / (period_ticks * tick_interval)
    
    if not data.pll_state then
        data.pll_state = {phase = 0, freq = phase_velocity, lock_time = 0, last_phase_error = 0, integral_error = 0}
    end
    
    local expected_phase = data.pll_state.phase + data.pll_state.freq * tick_interval
    local current_phase = (now * phase_velocity) % 1
    local phase_error = angle_diff(current_phase * 360, expected_phase * 360) / 360
    
    local p_gain = 0.18
    local i_gain = 0.008
    local d_gain = 0.04
    
    if corr > 0.7 then
        p_gain = 0.28
        i_gain = 0.015
        d_gain = 0.06
        data.pll_state.lock_time = data.pll_state.lock_time + tick_interval
    else
        data.pll_state.lock_time = math.max(0, data.pll_state.lock_time - tick_interval)
        p_gain = 0.12
        i_gain = 0.005
    end
    
    local delta_error = phase_error - data.pll_state.last_phase_error
    data.pll_state.last_phase_error = phase_error
    
    data.pll_state.integral_error = data.pll_state.integral_error + phase_error * i_gain
    data.pll_state.integral_error = clamp(data.pll_state.integral_error, -0.3, 0.3)
    
    local total_correction = phase_error * p_gain + data.pll_state.integral_error + delta_error * d_gain
    
    data.pll_state.phase = expected_phase + total_correction
    data.pll_state.freq = data.pll_state.freq + phase_error * 0.025 * data.pll_state.freq
    data.pll_state.freq = clamp(data.pll_state.freq, 0.7, 3.8)
    
    local wave_shape = "sine"
    if yaw_pattern and yaw_pattern.type == "jitter" then
        local freq = yaw_pattern.params.frequency or 1.5
        if freq > 2.2 then
            wave_shape = "triangle"
        elseif freq > 1.3 then
            wave_shape = "sine"
        else
            wave_shape = "square_like"
        end
    end
    
    local phase_val = data.pll_state.phase % 1
    local wave_value = 0
    
    if wave_shape == "sine" then
        wave_value = math.sin(phase_val * math.pi * 2)
    elseif wave_shape == "triangle" then
        local phase_mod = phase_val * 2
        if phase_mod < 1 then
            wave_value = phase_mod * 2 - 1
        else
            wave_value = 1 - (phase_mod - 1) * 2
        end
    else
        wave_value = phase_val < 0.5 and 1 or -1
    end
    
    local dynamic_amp = median_amp * (0.65 + data.hit_confidence * 0.4)
    if data.consecutive_misses > 0 then
        dynamic_amp = dynamic_amp * (1 + math.min(data.consecutive_misses * 0.06, 0.4))
    end
    dynamic_amp = clamp(dynamic_amp, 6, 68)
    
    if not data.last_amp then data.last_amp = dynamic_amp end
    dynamic_amp = exp_smooth(data.last_amp, dynamic_amp, 0.7)
    data.last_amp = dynamic_amp
    
    local predicted_offset = wave_value * dynamic_amp
    local predicted_yaw = norm_angle(center + predicted_offset)
    
    if data.kalman_state then
        data.kalman_state.q = 0.05 * (1 + (1 - corr))
        data.kalman_state.r = 0.1 * (1 - corr * 0.5)
        local kalman_yaw = kalman_update(data.kalman_state, predicted_yaw)
        predicted_yaw = kalman_yaw
    end
    
    local stability = clamp(corr, 0.3, 0.9)
    local smoothing = (1 - stability) * 0.6
    local corrected_yaw = norm_angle(eye_yaw * smoothing + predicted_yaw * (1 - smoothing))
    
    if data.last_corrected_yaw then
        local delta = angle_diff(corrected_yaw, data.last_corrected_yaw)
        if math.abs(delta) > 18 then
            corrected_yaw = norm_angle(data.last_corrected_yaw + delta * 0.4)
        end
    end
    data.last_corrected_yaw = corrected_yaw
    
    local jitter_type = "unknown"
    if median_amp > 58 then jitter_type = "extreme"
    elseif median_amp > 45 then jitter_type = "aggressive"
    elseif median_amp > 32 then jitter_type = "high"
    elseif median_amp > 22 then jitter_type = "medium"
    elseif median_amp > 12 then jitter_type = "low"
    elseif median_amp > 6 then jitter_type = "micro"
    else jitter_type = "static" end
    
    local freq_hz = data.pll_state.freq
    if freq_hz > 2.6 then jitter_type = "fast_" .. jitter_type
    elseif freq_hz < 1.1 then jitter_type = "slow_" .. jitter_type end
    
    local confidence = 0.7 + corr * 0.25
    confidence = clamp(confidence, 0.5, 0.94)
    data.confidence_score = confidence
    
    return corrected_yaw, median_amp, jitter_type, confidence, period_ticks
end

--# > counter defensive

local function counter_defensive(player, eye_yaw, yaw_pattern, pitch_pattern, max_desync)
    local data = init_player(player)
    
    if not DefensiveData[player] then
        DefensiveData[player] = {
            pitch_history = {},
            yaw_history = {},
            flip_counter = 0,
            last_flip_time = 0,
            defensive_type = "none",
            yaw_pattern = {type = "unknown"},
            pitch_pattern = {type = "unknown"},
            predicted_next = nil,
            confidence_multiplier = 1.0,
            pattern_stability = 0,
            last_successful_angle = eye_yaw,
            defensive_confidence = 0.5,
            last_resolve_time = 0,
            tickbase_compensation = 0,
            last_final_yaw = eye_yaw,
            consecutive_same_side = 0,
            exploit_detected = false,
            last_side = nil,
            pattern_phase = 0,
            last_correction_time = 0
        }
    end
    
    local def_data = DefensiveData[player]
    
    if def_data.tickbase_compensation == nil then def_data.tickbase_compensation = 0 end
    if def_data.defensive_confidence == nil then def_data.defensive_confidence = 0.5 end
    if def_data.last_successful_angle == nil then def_data.last_successful_angle = eye_yaw end
    if def_data.last_final_yaw == nil then def_data.last_final_yaw = eye_yaw end
    if def_data.consecutive_same_side == nil then def_data.consecutive_same_side = 0 end
    if def_data.exploit_detected == nil then def_data.exploit_detected = false end
    if def_data.pattern_phase == nil then def_data.pattern_phase = 0 end
    if def_data.pattern_stability == nil then def_data.pattern_stability = 0 end
    
    local shift_detected, shift_amount, shift_history = detect_tickbase(player)
    
    local tick_exploit_detected = false
    local exploit_compensation = 0
    
    if shift_detected and shift_amount >= 12 then
        tick_exploit_detected = true
        def_data.exploit_detected = true
        
        local exploit_magnitude = clamp((shift_amount - 11) / 5, 0.2, 1.2)
        exploit_compensation = 35 * exploit_magnitude
        
        if not def_data.exploit_history then
            def_data.exploit_history = {}
        end
        table.insert(def_data.exploit_history, {amount = shift_amount, time = globals.realtime()})
        if #def_data.exploit_history > 8 then
            table.remove(def_data.exploit_history, 1)
        end
        
        local large_shifts = 0
        for _, exp in ipairs(def_data.exploit_history) do
            if exp.amount >= 13 then large_shifts = large_shifts + 1 end
        end
        if large_shifts >= 3 then
            exploit_compensation = exploit_compensation * 1.3
        end
    elseif shift_detected and shift_amount >= 8 then
        exploit_compensation = 18 * ((shift_amount - 7) / 6)
        tick_exploit_detected = true
    else
        if def_data.exploit_detected then
            local time_since_last = globals.realtime() - (shift_history and shift_history.last_shift_time or 0)
            if time_since_last > 1.5 then
                def_data.exploit_detected = false
            end
        end
    end
    
    table.insert(def_data.pitch_history, entity.get_prop(player, "m_angEyeAnglesX") or 0)
    table.insert(def_data.yaw_history, eye_yaw)
    
    if #def_data.pitch_history > 60 then
        table.remove(def_data.pitch_history, 1)
        table.remove(def_data.yaw_history, 1)
    end
    
    local detected_pitch = detect_pitch(def_data.pitch_history)
    local detected_yaw = detect_yaw(def_data.yaw_history)
    
    def_data.pitch_pattern = detected_pitch
    def_data.yaw_pattern = detected_yaw
    
    if detected_yaw.type == def_data.yaw_pattern.type then
        def_data.pattern_stability = math.min(1, def_data.pattern_stability + 0.05)
    else
        def_data.pattern_stability = math.max(0, def_data.pattern_stability - 0.03)
    end
    
    local is_defensive = false
    local defensive_score = 0
    local defensive_type = "none"
    
    if detected_yaw.type ~= "unknown" and detected_yaw.confidence > 0.55 then
        is_defensive = true
        defensive_score = defensive_score + detected_yaw.confidence
        defensive_type = detected_yaw.type
    end
    
    if detected_pitch.type ~= "unknown" and detected_pitch.confidence > 0.55 then
        is_defensive = true
        defensive_score = defensive_score + detected_pitch.confidence
        if defensive_type ~= "none" then
            defensive_type = defensive_type .. "_" .. detected_pitch.type
        else
            defensive_type = detected_pitch.type
        end
    end
    
    if is_defensive then
        data.defensive_ticks = math.min(45, (data.defensive_ticks or 0) + 1)
        def_data.defensive_confidence = math.min(0.95, (def_data.defensive_confidence or 0.5) + 0.045)
    else
        data.defensive_ticks = math.max(0, (data.defensive_ticks or 0) - 0.35)
        def_data.defensive_confidence = math.max(0.3, (def_data.defensive_confidence or 0.5) - 0.018)
    end
    
    local tickbase_comp = 0
    if shift_detected and shift_amount > 0 then
        if shift_amount >= 12 then
            tickbase_comp = shift_amount * 3.2
        elseif shift_amount >= 8 then
            tickbase_comp = shift_amount * 2.2
        else
            tickbase_comp = shift_amount * 1.8
        end
        def_data.tickbase_compensation = tickbase_comp
    else
        def_data.tickbase_compensation = math.max(0, def_data.tickbase_compensation - 0.45)
    end
    
    tickbase_comp = tickbase_comp + exploit_compensation
    
    def_data.pattern_phase = def_data.pattern_phase + (def_data.pattern_stability * 0.15)
    if def_data.pattern_phase > 1 then def_data.pattern_phase = def_data.pattern_phase - 1 end
    
    local inverted_yaw = norm_angle(eye_yaw + 180)
    local final_yaw = inverted_yaw
    local correction_type = "inversion"
    local confidence = 0.85
    
    local move_state, _ = analyze_move(player)
    local move_factor = 1.0
    if move_state == "running" then
        move_factor = 0.58
    elseif move_state == "walking" then
        move_factor = 0.73
    elseif move_state == "airborne" then
        move_factor = 0.88
    end
    
    if detected_yaw.type == "jitter" then
        local jitter_amp = detected_yaw.params.amplitude or 18
        local freq = detected_yaw.params.frequency or 2
        local phase = (globals.realtime() * freq) % 1
        
        local micro = (phase - 0.5) * jitter_amp * 0.38 * move_factor
        
        if #def_data.yaw_history >= 15 then
            local recent_yaws = {}
            local recent_start = math.max(1, #def_data.yaw_history - 14)
            for i = recent_start, #def_data.yaw_history do
                table.insert(recent_yaws, def_data.yaw_history[i])
            end
            if #recent_yaws >= 2 then
                local trend = 0
                for i = 2, #recent_yaws do
                    trend = trend + angle_diff(recent_yaws[i], recent_yaws[i-1])
                end
                trend = trend / (#recent_yaws - 1)
                micro = micro + (trend or 0) * 0.22 * move_factor
            end
        end
        
        final_yaw = norm_angle(inverted_yaw + micro + tickbase_comp)
        correction_type = "jitter_inversion"
        confidence = 0.94 * (1 + (def_data.defensive_confidence or 0.5) * 0.08)
        
    elseif detected_yaw.type == "spin" then
        local spin_dir = (detected_yaw.params.direction == "right") and -1 or 1
        local spin_rate = detected_yaw.params.rate or 30
        local spin_phase = (globals.realtime() * (spin_rate / 360)) % 1
        local spin_offset = max_desync * 1.9 * spin_dir + (spin_phase - 0.5) * 14 * move_factor
        final_yaw = norm_angle(eye_yaw + spin_offset + tickbase_comp)
        correction_type = "spin_counter"
        confidence = 0.97
        
    elseif detected_yaw.type == "sway" then
        local sway_phase = math.sin(globals.realtime() * 0.55)
        local sway_freq = detected_yaw.params.frequency or 0.55
        local adaptive_sway = math.sin(globals.realtime() * sway_freq * math.pi) * 24 * move_factor
        final_yaw = norm_angle(inverted_yaw + adaptive_sway + tickbase_comp)
        correction_type = "sway_inversion"
        confidence = 0.9 * (1 + (def_data.defensive_confidence or 0.5) * 0.04)
        
    elseif detected_yaw.type == "static" then
        final_yaw = norm_angle(inverted_yaw + tickbase_comp)
        correction_type = "static_inversion"
        confidence = 0.98
        
    elseif detected_yaw.type == "fake_zero" then
        local fake_offset = 65 * move_factor
        if (def_data.defensive_confidence or 0.5) > 0.7 then
            fake_offset = fake_offset + 18
        end
        if tick_exploit_detected then
            fake_offset = fake_offset * 1.2
        end
        final_yaw = norm_angle(eye_yaw + fake_offset + tickbase_comp)
        correction_type = "fake_zero_counter"
        confidence = 0.96
        
    elseif detected_yaw.type == "random" then
        local variation = math.sin(globals.realtime() * 4.2) * 18 * move_factor
        final_yaw = norm_angle(inverted_yaw + variation + tickbase_comp)
        correction_type = "random_inversion"
        confidence = 0.84
    end
    
    local pitch_val = detected_pitch.params and detected_pitch.params.value
    if detected_pitch.type == "static" and pitch_val and math.abs(pitch_val) > 60 then
        local pitch_factor = clamp(1 - math.abs(pitch_val) / 90, 0.4, 1)
        final_yaw = norm_angle(final_yaw + (eye_yaw - final_yaw) * (1 - pitch_factor))
        correction_type = correction_type .. "_pitch_comp"
        confidence = confidence * 0.97
    end
    
    if detected_pitch.type == "fake" then
        local fake_pitch_offset = 45 * (1 + (def_data.defensive_confidence or 0.5) * 0.3)
        final_yaw = norm_angle(final_yaw + fake_pitch_offset)
        correction_type = correction_type .. "_fake_pitch_comp"
    end
    
    local animstate = get_animstate(player)
    if animstate then
        local move_weight = animstate.flMoveWeight or 0
        if move_weight > 0.6 then
            local move_adjust = (eye_yaw - final_yaw) * 0.18
            final_yaw = norm_angle(final_yaw + move_adjust)
            correction_type = correction_type .. "_move_adj"
        end
        
        local speed_norm = animstate.flSpeedNormalized or 0
        if speed_norm > 0.5 then
            local speed_adjust = angle_diff(final_yaw, eye_yaw) * 0.12
            final_yaw = norm_angle(final_yaw + speed_adjust)
        end
    end
    
    local yaw_change = angle_diff(final_yaw, def_data.last_final_yaw)
    local max_change_per_tick = 28
    
    if tick_exploit_detected then
        max_change_per_tick = 40
    end
    
    if math.abs(yaw_change) > max_change_per_tick then
        final_yaw = norm_angle(def_data.last_final_yaw + yaw_change * (max_change_per_tick / math.abs(yaw_change)))
        correction_type = correction_type .. "_flick_fixed"
    end
    
    local current_side = angle_diff(final_yaw, eye_yaw) > 0 and "right" or "left"
    if def_data.last_side == current_side then
        def_data.consecutive_same_side = def_data.consecutive_same_side + 1
        if def_data.consecutive_same_side > 4 then
            local variation = (def_data.consecutive_same_side % 2 == 0 and 6 or -6)
            final_yaw = norm_angle(final_yaw + variation)
            correction_type = correction_type .. "_variation"
        end
    else
        def_data.consecutive_same_side = 0
    end
    def_data.last_side = current_side
    
    def_data.last_final_yaw = final_yaw
    
    if data.hit_confidence > 0.7 then
        def_data.last_successful_angle = final_yaw
    end
    
    data.confidence_score = confidence
    
    return final_yaw, correction_type, confidence, is_defensive, defensive_type, shift_detected, tick_exploit_detected
end

--# > unmatched resolver

local function init_unmatched(player)
    if not UnmatchedData then
        UnmatchedData = {}
    end
    
    if not UnmatchedData[player] then
        UnmatchedData[player] = {
            phase = 0,
            last_yaw = 0,
            amplitude_history = {},
            frequency_history = {},
            dominant_freq = 2.2,
            dominant_amp = 28,
            pattern_stability = 0,
            last_update = 0,
            predicted_center = 0,
            cycle_position = 0,
            success_rate = 0.5,
            last_hit_time = 0,
            hit_window = {},
            phase_velocity = 2.2,
            bias = 0,
            missed_ticks = 0
        }
    end
    return UnmatchedData[player]
end

local function detect_unmatched(yaw_history)
    local history_len = #yaw_history
    if history_len < 25 then
        return {type = "analyzing", confidence = 0.4, params = {amp_estimate = 28, freq_estimate = 2.2}}
    end
    
    local amplitudes = {}
    local zero_crossings = 0
    local last_sign = 0
    
    for i = 2, history_len do
        local diff = angle_diff(yaw_history[i], yaw_history[i-1])
        local sign = diff > 0 and 1 or (diff < 0 and -1 or 0)
        if sign ~= 0 and last_sign ~= 0 and sign ~= last_sign then
            zero_crossings = zero_crossings + 1
        end
        last_sign = sign
        table.insert(amplitudes, math.abs(diff))
    end
    
    local sum_amp = 0
    for _, amp in ipairs(amplitudes) do
        sum_amp = sum_amp + amp
    end
    local avg_amp = sum_amp / #amplitudes
    local frequency = zero_crossings / (#amplitudes) * 0.5
    
    local sorted = {}
    for _, y in ipairs(yaw_history) do
        table.insert(sorted, y)
    end
    table.sort(sorted)
    local center = sorted[math.floor(#sorted / 2)]
    
    local pattern = {type = "unmatched_jitter", confidence = 0.85, params = {}}
    
    if avg_amp > 38 then
        pattern.type = "unmatched_high_jitter"
        pattern.confidence = 0.92
    elseif avg_amp > 25 then
        pattern.type = "unmatched_medium_jitter"
        pattern.confidence = 0.88
    elseif avg_amp > 15 then
        pattern.type = "unmatched_low_jitter"
        pattern.confidence = 0.82
    else
        pattern.type = "unmatched_static"
        pattern.confidence = 0.76
    end
    
    pattern.params.amp = avg_amp
    pattern.params.freq = frequency
    pattern.params.center = center
    
    return pattern
end

local function update_unmatched_success(player, hit)
    local um_data = init_unmatched(player)
    
    local now = globals.realtime()
    table.insert(um_data.hit_window, {hit = hit, time = now})
    
    if #um_data.hit_window > 15 then
        table.remove(um_data.hit_window, 1)
    end
    
    local success_count = 0
    for _, entry in ipairs(um_data.hit_window) do
        if entry.hit then success_count = success_count + 1 end
    end
    
    um_data.success_rate = success_count / #um_data.hit_window
    
    if hit then
        um_data.last_hit_time = now
        um_data.missed_ticks = 0
    end
    
    return um_data.success_rate
end

--# > anim layers

local function get_layers(player)
    if not player or not get_client_entity then return nil end
    
    local now = globals.realtime()
    if AnimationLayerCache[player] and now - (AnimationLayerCache[player].time or 0) < 0.05 then
        return AnimationLayerCache[player].layers
    end
    
    local player_ptr = get_client_entity(ientitylist, player)
    if not player_ptr then return nil end
    
    local layers_ptr = ffi.cast("uintptr_t", player_ptr) + 0x9970
    local layers = ffi.cast("C_AnimationLayer*", layers_ptr)
    
    AnimationLayerCache[player] = {
        layers = layers,
        time = now
    }
    
    return layers
end

local function analyze_layers(player, eye_yaw, goal_feet_yaw)
    local layers = get_layers(player)
    if not layers then return nil end
    
    local layer_data = {
        layer6_weight = 0,
        layer6_cycle = 0,
        layer11_weight = 0,
        layer11_cycle = 0,
        model_direction = "unknown",
        confidence = 0
    }
    
    if layers[5] then
        layer_data.layer6_weight = layers[5].m_weight or 0
        layer_data.layer6_cycle = layers[5].m_cycle or 0
    end
    
    if layers[10] then
        layer_data.layer11_weight = layers[10].m_weight or 0
        layer_data.layer11_cycle = layers[10].m_cycle or 0
    end
    
    if layer_data.layer11_weight > 0.6 then
        local cycle = layer_data.layer11_cycle
        if cycle > 0.75 or cycle < 0.25 then
            layer_data.model_direction = "left"
            layer_data.confidence = 0.85 + layer_data.layer11_weight * 0.1
        elseif cycle > 0.25 and cycle < 0.5 then
            layer_data.model_direction = "right"
            layer_data.confidence = 0.85 + layer_data.layer11_weight * 0.1
        elseif cycle >= 0.5 and cycle <= 0.75 then
            layer_data.model_direction = "center"
            layer_data.confidence = 0.75 + layer_data.layer11_weight * 0.1
        end
    elseif layer_data.layer6_weight > 0.5 then
        local cycle = layer_data.layer6_cycle
        if cycle > 0.7 then
            layer_data.model_direction = "right"
            layer_data.confidence = 0.7
        elseif cycle < 0.3 then
            layer_data.model_direction = "left"
            layer_data.confidence = 0.7
        else
            layer_data.model_direction = "center"
            layer_data.confidence = 0.6
        end
    end
    
    if goal_feet_yaw and eye_yaw then
        local feet_diff = angle_diff(goal_feet_yaw, eye_yaw)
        if feet_diff > 30 and layer_data.model_direction == "left" then
            layer_data.confidence = layer_data.confidence + 0.1
        elseif feet_diff < -30 and layer_data.model_direction == "right" then
            layer_data.confidence = layer_data.confidence + 0.1
        end
    end
    
    layer_data.confidence = clamp(layer_data.confidence, 0.3, 0.95)
    
    return layer_data
end

local function resolve_unmatched(player, eye_yaw, yaw_history, move_state)
    local data = init_player(player)
    local um_data = init_unmatched(player)
    local current_time = globals.realtime()
    
    local aggression = menu.unmatched.resolver_aggression:get() / 100
    local prediction = menu.unmatched.prediction_speed:get() / 100
    local logic_brute = menu.unmatched.brute_force:get()
    
    local animstate = get_animstate(player)
    local goal_feet_yaw = animstate and animstate.flGoalFeetYaw or eye_yaw
    local layer_data = analyze_layers(player, eye_yaw, goal_feet_yaw)
    
    local real_dir = "unknown"
    local dir_confidence = 0.5
    
    if layer_data and layer_data.confidence > 0.6 then
        real_dir = layer_data.model_direction
        dir_confidence = layer_data.confidence
    end
    
    if #yaw_history >= 2 then
        local recent_amp = math.abs(angle_diff(yaw_history[#yaw_history], yaw_history[#yaw_history-1]))
        table.insert(um_data.amplitude_history, recent_amp)
        if #um_data.amplitude_history > 40 then
            table.remove(um_data.amplitude_history, 1)
        end
        
        local sum_amp = 0
        for _, amp in ipairs(um_data.amplitude_history) do
            sum_amp = sum_amp + amp
        end
        if #um_data.amplitude_history > 0 then
            local base_amp = sum_amp / #um_data.amplitude_history
            um_data.dominant_amp = base_amp * (0.6 + aggression * 0.8)
        end
        um_data.dominant_amp = clamp(um_data.dominant_amp, 12, 58)
    end
    
    local pattern = detect_unmatched(yaw_history)
    
    local tick_interval = globals.tickinterval() or 1/64
    local time_factor = current_time - um_data.last_update
    if time_factor > 0.1 then time_factor = tick_interval end
    um_data.last_update = current_time
    
    local move_mod = 1.0
    if move_state == "running" then
        move_mod = 0.55
    elseif move_state == "walking" then
        move_mod = 0.70
    elseif move_state == "crouching" then
        move_mod = 0.82
    elseif move_state == "airborne" then
        move_mod = 0.90
    end
    
    local base_freq = 2.0
    if pattern.type == "unmatched_high_jitter" then
        base_freq = 2.7
    elseif pattern.type == "unmatched_medium_jitter" then
        base_freq = 2.3
    elseif pattern.type == "unmatched_low_jitter" then
        base_freq = 1.9
    end
    
    local adapt_factor = 0.5 + prediction * 0.8
    um_data.phase_velocity = base_freq * move_mod * adapt_factor
    um_data.phase_velocity = clamp(um_data.phase_velocity, 1.2, 3.8)
    
    um_data.phase = um_data.phase + um_data.phase_velocity * tick_interval * 2.2
    if um_data.phase > 1 then um_data.phase = um_data.phase - 1 end
    
    local center_estimate = pattern.params.center or eye_yaw
    
    if real_dir == "left" then
        center_estimate = norm_angle(center_estimate - 15)
    elseif real_dir == "right" then
        center_estimate = norm_angle(center_estimate + 15)
    end
    
    local feet_delta = angle_diff(goal_feet_yaw, eye_yaw)
    if math.abs(feet_delta) > 20 then
        local feet_influence = 0.3 * dir_confidence
        center_estimate = norm_angle(center_estimate * (1 - feet_influence) + goal_feet_yaw * feet_influence)
    end
    
    if data.hit_confidence > 0.65 and data.last_hit_yaw then
        local hit_influence = 0.25 + (data.hit_confidence - 0.65) * 0.5
        center_estimate = center_estimate * (1 - hit_influence) + data.last_hit_yaw * hit_influence
    end
    
    if logic_brute and data.consecutive_misses > 2 then
        local brute_index = data.consecutive_misses % 8
        
        local feet_eye_delta = angle_diff(goal_feet_yaw, eye_yaw)
        
        local brute_offsets = {}
        if math.abs(feet_eye_delta) > 30 then
            brute_offsets = {
                feet_eye_delta > 0 and -MAX_DESYNC_BASE or MAX_DESYNC_BASE,
                feet_eye_delta > 0 and MAX_DESYNC_BASE or -MAX_DESYNC_BASE,
                feet_eye_delta > 0 and -MAX_DESYNC_BASE * 0.5 or MAX_DESYNC_BASE * 0.5,
                feet_eye_delta > 0 and MAX_DESYNC_BASE * 0.7 or -MAX_DESYNC_BASE * 0.7,
                feet_eye_delta > 0 and -MAX_DESYNC_BASE * 0.8 or MAX_DESYNC_BASE * 0.8,
                feet_eye_delta > 0 and -MAX_DESYNC_BASE * 0.3 or MAX_DESYNC_BASE * 0.3,
                feet_eye_delta > 0 and MAX_DESYNC_BASE * 0.4 or -MAX_DESYNC_BASE * 0.4,
                feet_eye_delta > 0 and -MAX_DESYNC_BASE * 0.15 or MAX_DESYNC_BASE * 0.15
            }
        else
            brute_offsets = {
                MAX_DESYNC_BASE, -MAX_DESYNC_BASE, MAX_DESYNC_BASE * 0.6, -MAX_DESYNC_BASE * 0.6,
                MAX_DESYNC_BASE * 0.8, -MAX_DESYNC_BASE * 0.8, MAX_DESYNC_BASE * 0.3, -MAX_DESYNC_BASE * 0.3
            }
        end
        
        local brute_offset = brute_offsets[(brute_index % #brute_offsets) + 1] or 0
        center_estimate = norm_angle(center_estimate + brute_offset)
        
        um_data.missed_ticks = um_data.missed_ticks + 1
    elseif data.consecutive_misses > 2 then
        um_data.missed_ticks = um_data.missed_ticks + 1
        local miss_angle = 0
        if data.consecutive_misses == 3 then miss_angle = 6
        elseif data.consecutive_misses == 4 then miss_angle = -10
        elseif data.consecutive_misses == 5 then miss_angle = 14
        elseif data.consecutive_misses >= 6 then miss_angle = (data.consecutive_misses % 4 - 2) * 9
        end
        center_estimate = norm_angle(center_estimate + miss_angle)
    else
        um_data.missed_ticks = 0
    end
    
    um_data.predicted_center = center_estimate
    
    local wave_value = 0
    if aggression < 0.4 then
        wave_value = math.sin(um_data.phase * math.pi * 2)
    elseif aggression < 0.7 then
        local phase_mod = um_data.phase * 2
        if phase_mod < 1 then
            wave_value = phase_mod * 2 - 1
        else
            wave_value = 1 - (phase_mod - 1) * 2
        end
    else
        wave_value = math.sin(um_data.phase * math.pi * 2) * 0.6 + math.sin(um_data.phase * math.pi * 4) * 0.4
    end
    
    local min_swing = 12
    local max_swing = 52
    local target_amp = min_swing + (max_swing - min_swing) * aggression
    
    local detected_amp = pattern.params.amp or 25
    local final_amp = target_amp * 0.6 + detected_amp * 0.4
    final_amp = clamp(final_amp, 12, 58)
    
    local dynamic_offset = wave_value * final_amp
    
    if real_dir == "left" then
        dynamic_offset = dynamic_offset - 8 * dir_confidence
    elseif real_dir == "right" then
        dynamic_offset = dynamic_offset + 8 * dir_confidence
    end
    
    if move_state == "airborne" then
        dynamic_offset = dynamic_offset * 0.65
    elseif move_state == "crouching" then
        dynamic_offset = dynamic_offset * 0.85
    end
    
    local resolved_yaw = norm_angle(center_estimate + dynamic_offset)
    
    if logic_brute and data.consecutive_misses > 4 then
        local brute_phases = {0, 0.25, 0.5, 0.75, 0.125, 0.375, 0.625, 0.875}
        local brute_phase = brute_phases[(data.consecutive_misses % 8) + 1] or 0
        
        local feet_eye_delta = angle_diff(goal_feet_yaw, eye_yaw)
        local brute_dir = feet_eye_delta > 0 and -1 or 1
        
        local brute_offset = math.sin(brute_phase * math.pi * 2) * 28 * brute_dir
        resolved_yaw = norm_angle(resolved_yaw + brute_offset)
    end
    
    local confidence = pattern.confidence * (1 - data.consecutive_misses * 0.07) * dir_confidence
    confidence = clamp(confidence, 0.45, 0.94)
    
    data.unmatched_mode = true
    data.confidence_score = confidence
    
    return resolved_yaw, pattern.type, confidence, final_amp, real_dir
end

--# > side logic

local function get_adaptive_side(player, eye_yaw, defensive_active, predicted_side)
    local data = init_player(player)
    
    local local_player = entity.get_local_player()
    if local_player then
        local local_origin = vector(entity.get_origin(local_player))
        local player_origin = vector(entity.get_origin(player))
        
        local dir_to_local = (local_origin - player_origin):normalized()
        local target_yaw = math.atan2(dir_to_local.y, dir_to_local.x) * 180 / math.pi
        local yaw_diff = angle_diff(target_yaw, eye_yaw)
        
        if math.abs(yaw_diff) < 60 then
            local freestanding_side = yaw_diff > 0 and "right" or "left"
            return freestanding_side == "left" and "right" or "left", 0.98
        end
    end
    
    if data.consecutive_misses > 2 then
        local brute_index = data.consecutive_misses % 6
        local sides = {"right", "left", "center", "forward", "right", "left"}
        return sides[brute_index + 1], math.max(0.4, 1 - data.consecutive_misses * 0.12)
    end
    
    if data.hit_confidence > 0.7 and data.last_hit_side then
        return data.last_hit_side, data.hit_confidence
    end
    
    if data.adaptive_side == "unknown" then
        local random_factor = math.sin(globals.realtime() * 0.6) * 0.3 + 0.5
        data.adaptive_side = random_factor > 0.5 and "right" or "left"
    end
    
    return data.adaptive_side, 0.65
end

--# > cleanup

local function cleanup_dead()
    for player, _ in pairs(ResolverData) do
        if not entity.is_alive(player) or entity.get_prop(player, "m_lifeState") == 1 then
            ResolverData[player] = nil
            JitterWindow[player] = nil
            DefensiveData[player] = nil
            MovementHistory[player] = nil
            UnmatchedData[player] = nil
            TickbaseHistory[player] = nil
            AnimationLayerCache[player] = nil
            LagCompensationData[player] = nil
            animstate_cache[player] = nil
            animstate_cache_time[player] = nil
        end
    end
end

--# > pl update

local cached_players = {}
local last_player_update = 0

local function update_players()
    local now = globals.realtime()
    if now - last_player_update < 0.033 then
        return cached_players
    end
    last_player_update = now
    
    local players = {}
    local local_player = entity.get_local_player()
    
    if not local_player then
        return players
    end
    
    local max_players = globals.maxplayers()
    
    for i = 1, max_players do
        if i ~= local_player and entity.is_alive(i) and entity.is_enemy(i) then
            table.insert(players, i)
        end
    end
    
    cached_players = players
    return players
end

--# > resolver logic

local function resolve(player)
    local data = init_player(player)
    
    if not entity.is_alive(player) or not entity.is_enemy(player) then
        return
    end
    
    local animstate = get_animstate(player)
    local eye_angles = vector(entity.get_prop(player, "m_angEyeAngles"))
    local eye_yaw = eye_angles.y
    local eye_pitch = eye_angles.x
    
    local lag_compensated_yaw, lag_spike = lag_fix(player, eye_yaw, animstate)
    eye_yaw = lag_compensated_yaw
    
    local move_state, current_speed = analyze_move(player)
    
    if not DefensiveData[player] then
        DefensiveData[player] = {
            pitch_history = {},
            yaw_history = {},
            yaw_pattern = {type = "unknown"},
            pitch_pattern = {type = "unknown"}
        }
    end
    
    local def_data = DefensiveData[player]
    table.insert(def_data.pitch_history, eye_pitch)
    table.insert(def_data.yaw_history, eye_yaw)
    
    if #def_data.pitch_history > 60 then
        table.remove(def_data.pitch_history, 1)
        table.remove(def_data.yaw_history, 1)
    end
    
    local pitch_pattern = detect_pitch(def_data.pitch_history)
    local yaw_pattern = detect_yaw(def_data.yaw_history)
    
    local pattern_for_desync = yaw_pattern.type
    if pattern_for_desync == "unknown" then pattern_for_desync = pitch_pattern.type end
    local pattern_confidence = math.max(yaw_pattern.confidence or 0.5, pitch_pattern.confidence or 0.5)
    local max_desync = calc_max_desync(animstate, move_state, pattern_for_desync, pattern_confidence)
    
    local resolved_yaw = eye_yaw
    local resolved_side = "unknown"
    local desync_adjustment = 0
    local aa_type = "unknown"
    local correction_confidence = 0.5
    
    local unmatched_enabled = menu.unmatched.unmatched_resolver:get()
    local jitter_enabled = menu.main.jitter_correction:get()
    local defensive_enabled = menu.main.def_correction:get()
    
    if unmatched_enabled and (yaw_pattern.type == "jitter" or yaw_pattern.type == "unknown" or yaw_pattern.type == "random") then
        local unmatched_yaw, unmatched_type, unmatched_conf, unmatched_amp, real_dir = resolve_unmatched(player, eye_yaw, def_data.yaw_history, move_state)
        resolved_yaw = unmatched_yaw
        desync_adjustment = angle_diff(resolved_yaw, eye_yaw)
        resolved_side = desync_adjustment > 0 and "right" or "left"
        aa_type = "unmatched_" .. unmatched_type .. (real_dir ~= "unknown" and ("_dir_" .. real_dir) or "")
        correction_confidence = unmatched_conf
        
    elseif (yaw_pattern.type == "jitter" or yaw_pattern.type == "random") and jitter_enabled then
        local jitter_corrected, jitter_amp, jitter_type, jitter_confidence, period = stabilize_jitter(player, eye_yaw, yaw_pattern)
        resolved_yaw = jitter_corrected
        desync_adjustment = angle_diff(resolved_yaw, eye_yaw)
        resolved_side = desync_adjustment > 0 and "right" or "left"
        aa_type = "jitter_stabilized_" .. jitter_type .. (period and ("_p" .. period) or "")
        correction_confidence = jitter_confidence
    
    elseif defensive_enabled then
        local defensive_corrected, correction_type, def_confidence, is_defensive, defensive_type, shift_detected, exploit_detected = counter_defensive(player, eye_yaw, yaw_pattern, pitch_pattern, max_desync)
        resolved_yaw = defensive_corrected
        desync_adjustment = angle_diff(resolved_yaw, eye_yaw)
        resolved_side = desync_adjustment > 0 and "right" or "left"
        aa_type = "defensive_" .. correction_type .. (shift_detected and "_shift" or "") .. (exploit_detected and "_exploit" or "")
        correction_confidence = def_confidence
    
    else
        aa_type = "desync"
        
        local desync_multiplier = 1.0
        if move_state == "running" then
            desync_multiplier = 0.40
        elseif move_state == "walking" then
            desync_multiplier = 0.62
        elseif move_state == "crouching" then
            desync_multiplier = 0.80
        elseif move_state == "slow_walking" then
            desync_multiplier = 0.86
        elseif move_state == "airborne" then
            desync_multiplier = 0.92
        end
        
        local desync_delta = max_desync * desync_multiplier
        local side, side_confidence = get_adaptive_side(player, eye_yaw, false, nil)
        
        if side == "left" then
            desync_adjustment = desync_delta
            resolved_side = "right"
        elseif side == "right" then
            desync_adjustment = -desync_delta
            resolved_side = "left"
        elseif side == "center" then
            desync_adjustment = 0
            resolved_side = "center"
        else
            desync_adjustment = desync_delta * 0.5
            resolved_side = "forward"
        end
        
        resolved_yaw = norm_angle(eye_yaw + desync_adjustment)
        correction_confidence = side_confidence
    end
    
    if data.misses == nil then
        data.misses = 0
    end
    
    if data.misses >= 3 then
        local brute_index = data.misses % 8
        local brute_offsets = {max_desync, -max_desync, 0, max_desync * 0.7, -max_desync * 0.7, max_desync * 0.35, -max_desync * 0.35, max_desync * 0.15}
        
        desync_adjustment = brute_offsets[brute_index + 1] or 0
        resolved_yaw = norm_angle(eye_yaw + desync_adjustment)
        
        local brute_sides = {"brute_right", "brute_left", "brute_center", "brute_mid_right", "brute_mid_left", "brute_micro_right", "brute_micro_left", "brute_micro"}
        resolved_side = brute_sides[brute_index + 1] or "brute"
        aa_type = aa_type .. "_" .. resolved_side
        correction_confidence = math.max(0.38, correction_confidence * 0.85)
    end
    
    data.resolved_yaw = resolved_yaw
    data.resolved_side = resolved_side
    data.aa_type = aa_type
    data.last_eye_yaw = eye_yaw
    data.last_eye_pitch = eye_pitch
    data.desync_delta = desync_adjustment
    data.last_resolve_time = globals.realtime()
    data.confidence_score = correction_confidence
    
    entity.set_prop(player, "m_angEyeAnglesY", resolved_yaw)
    
    return resolved_yaw, resolved_side, aa_type, yaw_pattern, pitch_pattern, correction_confidence
end

--# > event handlers

client.set_event_callback("aim_miss", function(e)
    if not menu.main.enable:get() then return end
    
    local target = e.target
    if not target then return end
    
    local data = init_player(target)
    local reason = e.reason
    
    if reason == "resolver" then
        data.misses = (data.misses or 0) + 1
        data.consecutive_misses = (data.consecutive_misses or 0) + 1
        data.last_shot_time = globals.realtime()
        
        update_unmatched_success(target, false)
        
        if data.misses > 20 then
            data.misses = 10
        end
        
        if data.consecutive_misses > 8 then
            data.adaptive_side = "unknown"
            data.hit_confidence = math.max(0, data.hit_confidence - 0.3)
        end
        
        data.hit_confidence = math.max(0, data.hit_confidence - 0.1)
    end
end)

client.set_event_callback("aim_hit", function(e)
    if not menu.main.enable:get() then return end
    
    local target = e.target
    if not target then return end
    
    local data = init_player(target)
    
    data.hit_confidence = math.min(1, (data.hit_confidence or 0) + 0.2)
    data.consecutive_misses = 0
    data.last_hit_side = data.resolved_side
    data.last_hit_yaw = data.resolved_yaw
    
    update_unmatched_success(target, true)
    
    if not data.hit_angles then
        data.hit_angles = {}
    end
    
    table.insert(data.hit_angles, {
        yaw = entity.get_prop(target, "m_angEyeAnglesY") or 0,
        resolved = data.resolved_yaw,
        confidence = data.hit_confidence,
        time = globals.realtime()
    })
    
    if #data.hit_angles > 50 then
        table.remove(data.hit_angles, 1)
    end
end)

client.set_event_callback("player_hurt", function(e)
    if not menu.main.enable:get() then return end
    
    local victim = client.userid_to_entindex(e.userid)
    if victim then
        if entity.get_prop(victim, "m_lifeState") == 1 then
            ResolverData[victim] = nil
            JitterWindow[victim] = nil
            DefensiveData[victim] = nil
            MovementHistory[victim] = nil
            UnmatchedData[victim] = nil
            TickbaseHistory[victim] = nil
            AnimationLayerCache[victim] = nil
            LagCompensationData[victim] = nil
            animstate_cache[victim] = nil
            animstate_cache_time[victim] = nil
        end
    end
end)

client.set_event_callback("round_start", function()
    ResolverData = {}
    JitterWindow = {}
    DefensiveData = {}
    MovementHistory = {}
    UnmatchedData = {}
    TickbaseHistory = {}
    AnimationLayerCache = {}
    LagCompensationData = {}
    animstate_cache = {}
    animstate_cache_time = {}
    
    last_player_update = 0
    cached_players = {}
end)

client.set_event_callback("round_end", function()
    ResolverData = {}
    JitterWindow = {}
    DefensiveData = {}
    MovementHistory = {}
    UnmatchedData = {}
    TickbaseHistory = {}
    AnimationLayerCache = {}
    LagCompensationData = {}
    animstate_cache = {}
    animstate_cache_time = {}
end)

client.set_event_callback("paint_ui", function()
    update_clan()
    draw_anim()
    check_resolver_anim()
end)

client.set_event_callback("paint", function()
    if not menu.main.enable:get() then return end
    local players = update_players()
    for _, player in ipairs(players) do
        resolve(player)
    end
    cleanup_dead()
end)

--#note: > safesolver