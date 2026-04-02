--@description: shared logo
--@author: uwukson4800

local http = require 'gamesense/http'
local base64 = require 'gamesense/base64'

local menu = {
    scoreboard = ui.new_checkbox('MISC', 'Miscellaneous', 'shared icon')
}

-- НАСТРОЙКИ (ИЗМЕНИТЕ ПОД СЕБЯ)
local GITHUB_TOKEN = 
local REPO_OWNER = "celexuw-glitch" --
local REPO_NAME = "centrumental" -
local FILE_PATH = "players.json"

-- Иконки (только stable и developer)
local icons = {
    stable = 'https://github.com/celexuw-glitch/centrumental/blob/main/image/Icon_Stable.png?raw=true',
    developer = 'https://raw.githubusercontent.com/celexuw-glitch/centrumental/main/image/Icon_Dev.png',
}

-- SAFEDATA (информация о билде)
local safedata = {
    build = {
        status = "developer"  -- Может быть "stable" или "developer"
    }
}

-- Данные пользователей с их статусами
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

-- Функция обновления файла на GitHub
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
            -- Сохраняем статус билда (stable или developer)
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

-- Получение локального SteamID
local function get_local_steamid()
    return tostring(panorama.open().MyPersonaAPI.GetXuid())
end

-- Обновление safedata статуса
local function update_safedata_status(status)
    safedata.build.status = status
end

-- Обновление данных на счётборде
local function update_target_players(github_data)
    user_data = {}
    for steamid, build_status in pairs(github_data) do
        -- По статусу билда выбираем нужную иконку
        if build_status == "stable" then
            user_data[steamid] = icons.stable
        elseif build_status == "developer" then
            user_data[steamid] = icons.developer
        end
    end
    scoreboard_images.update(user_data, user_data)
end

-- Проверка и обновление с GitHub
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

-- Выбор статуса для пользователя
local function select_user_status()
    local steamid = get_local_steamid()
    if steamid then
        -- Сохраняем в GitHub статус билда (stable или developer)
        if safedata.build.status == "developer" then
            update_github_file(steamid, "developer", "add")
            update_safedata_status("developer")
        else
            update_github_file(steamid, "stable", "add")
            update_safedata_status("stable")
        end
    end
end

-- События
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

-- Первоначальная проверка
check_and_update_github()

-- Циклическое обновление
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

-- Обработчик меню
ui.set_callback(menu.scoreboard, function()
    local steamid = get_local_steamid()
    if not ui.get(menu.scoreboard) then
        scoreboard_images.remove()
        update_github_file(steamid, nil, "remove")
    else
        select_user_status()
        check_and_update_github()
    end
end)

-- При выключении скрипта
client.set_event_callback("shutdown", function()
    local steamid = get_local_steamid()
    if steamid and not ui.get(menu.scoreboard) then
        update_github_file(steamid, nil, "remove")
    end
    scoreboard_images.remove()
end)