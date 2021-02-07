

state = {}

function game_end()
    delete_all_entities()
    game_init()
end

function update_score(diff) state.score = state.score + diff end
function update_money(diff) state.money = state.money + diff end

-- top right display types
local TRDTS = {
    NOTHING        = 0,
    CENTERED_EVENQ = 1,
    EVENQ          = 2,
    HEX            = 3,
    PLATFORM       = 4,
    PERF           = 5,
    SEED           = 6,
    TILE           = 7,
}

local function get_initial_game_state(seed)
    local STARTING_MONEY = 10000
    -- 2014
    local map, world = random_map(2014)

    return {
        map = map,              -- map of hex coords map[x][y] to some stuff at that location
        world = world,          -- the root scene graph node for the game 'world'
        ui = nil,               -- unused, root scene graph node for the 'ui' stuff

        perf = {},              -- result of call to am.perf_stats, called every frame
        time = 0,               -- real time since game started in seconds
        score = 0,              -- current game score
        money = STARTING_MONEY, -- current money

        current_wave = 0,

        selected_tower_type = false,
        selected_toolbelt_button = 9,
        selected_top_right_display_type = TRDTS.SEED,
    }
end

local function get_top_right_display_text(hex, evenq, centered_evenq, display_type)
    local str = ""
    if display_type == TRDTS.CENTERED_EVENQ then
        str = centered_evenq.x .. "," .. centered_evenq.y .. " (cevenq)"

    elseif display_type == TRDTS.EVENQ then
        str = evenq.x .. "," .. evenq.y .. " (evenq)"

    elseif display_type == TRDTS.HEX then
        str = hex.x .. "," .. hex.y .. " (hex)"

    elseif display_type == TRDTS.PLATFORM then
        str = string.format("%s %s lang %s", am.platform, am.version, am.language())

    elseif display_type == TRDTS.PERF then
        str = table.tostring(state.perf)

    elseif display_type == TRDTS.SEED then
        str = "SEED: " .. state.map.seed

    elseif display_type == TRDTS.TILE then
        str = table.tostring(state.map.get(hex.x, hex.y))
    end
    return str
end

-- initialized later, as part of the init of the toolbelt
function select_tower_type(tower_type) end

function select_toolbelt_button(i)
    state.selected_toolbelt_button = i
    if i <= 10 then
        select_tower_type(i)
    else
        select_tower_type(nil)
    end
end

function do_day_night_cycle()
    local tstep = (math.sin(state.time * am.delta_time) + 1) / 100
    state.world"negative_mask".color = vec4(tstep){a=1}
end

local function game_pause()
    WIN.scene("game").paused = true

    WIN.scene("game"):append(am.group{
        am.rect(WIN.left, WIN.bottom, WIN.right, WIN.top, COLORS.TRANSPARENT),
        am.scale(3)
        ^ am.text(string.format(
            "Paused.\nSeed: %d\nEscape to Resume\nf4 to start a new game", state.map.seed
        ), COLORS.BLACK),
    }
    :tag"pause_menu")

    WIN.scene:action(function()
        if WIN:key_pressed("escape") then
            WIN.scene:remove("pause_menu")
            WIN.scene("game").paused = false
            return true

        elseif WIN:key_pressed("f4") then
            game_end()
            return true
        end
    end)
end

local function game_action(scene)
    if state.score < 0 then game_end() return true end

    state.perf  = am.perf_stats()
    state.time  = state.time + am.delta_time
    state.score = state.score + am.delta_time

    local mouse          = WIN:mouse_position()
    local hex            = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET)
    local rounded_mouse  = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    local evenq          = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))
    local tile = state.map.get(hex.x, hex.y)

    local interactable = evenq_is_in_interactable_region(evenq{ y = -evenq.y })
    local buildable = tower_type_is_buildable_on(hex, tile, state.selected_tower_type)
    local firable = false

    if WIN:mouse_pressed"left" then
        if interactable then
            if buildable then
                local broken, flow_field = making_hex_unwalkable_breaks_flow_field(hex, tile)
                local cost = get_tower_cost(state.selected_tower_type)

                if broken then
                    local node = WIN.scene("cursor"):child(2)
                    node.color = COLORS.CLARET
                    node:action(am.tween(0.1, { color = COLORS.TRANSPARENT }))
                    play_sfx(SOUNDS.BIRD2)

                elseif cost > state.money then
                    local node = WIN.scene("cursor"):child(2)
                    node.color = COLORS.CLARET
                    node:action(am.tween(0.1, { color = COLORS.TRANSPARENT }))
                    play_sfx(SOUNDS.BIRD2)

                else
                    update_money(-cost)
                    build_tower(hex, state.selected_tower_type, flow_field)

                    if flow_field then
                        apply_flow_field(state.map, flow_field, state.world)
                    end
                end
            end
        end
    end

    if WIN:mouse_pressed"middle" then
        state.world"scale".scale2d = vec2(1)

    else
        local mwd = WIN:mouse_wheel_delta()
        state.world"scale".scale = state.world"scale".scale + vec3(mwd, 0) / 100
    end

    if WIN:key_pressed"escape" then
        game_pause()

    elseif WIN:key_pressed"f1" then
        state.selected_top_right_display_type = (state.selected_top_right_display_type + 1) % #table.keys(TRDTS)

    elseif WIN:key_pressed"f2" then
        state.world"flow_field".hidden = not state.world"flow_field".hidden

    elseif WIN:key_pressed"tab" then
        if WIN:key_down"lshift" then
            select_toolbelt_button((state.selected_toolbelt_button + 12 - 2) % 12 + 1)
        else
            select_toolbelt_button((state.selected_toolbelt_button) % 12 + 1)
        end
    elseif WIN:key_pressed"1" then select_toolbelt_button(1)
    elseif WIN:key_pressed"2" then select_toolbelt_button(2)
    elseif WIN:key_pressed"3" then select_toolbelt_button(3)
    elseif WIN:key_pressed"4" then select_toolbelt_button(4)
    elseif WIN:key_pressed"q" then select_toolbelt_button(5)
    elseif WIN:key_pressed"w" then select_toolbelt_button(6)
    elseif WIN:key_pressed"e" then select_toolbelt_button(7)
    elseif WIN:key_pressed"r" then select_toolbelt_button(8)
    elseif WIN:key_pressed"a" then select_toolbelt_button(9)
    elseif WIN:key_pressed"s" then select_toolbelt_button(10)
    elseif WIN:key_pressed"d" then select_toolbelt_button(11)
    elseif WIN:key_pressed"f" then select_toolbelt_button(12)
    end

    do_entity_updates()
    do_mob_spawning()
    do_gui_updates()
    do_day_night_cycle()

    WIN.scene("top_right_display").text = get_top_right_display_text(hex, evenq, centered_evenq, state.selected_top_right_display_type)
    WIN.scene("score").text = string.format("SCORE: %.2f", state.score)
    WIN.scene("money").text = string.format("MONEY: %d", state.money)
    if interactable then
        WIN.scene("cursor").hidden = false

        if buildable then
            WIN.scene("cursor_translate").position2d = rounded_mouse
        else
            WIN.scene("cursor").hidden = true
        end
    else
        WIN.scene("cursor").hidden = true
    end
end

local function make_game_toolbelt()
    local function toolbelt_button(size, half_size, tower_texture, padding, i, offset, key_name)
        local x1 = (size + padding) * i + offset.x
        local y1 = offset.y
        local x2 = (size + padding) * i + offset.x + size
        local y2 = offset.y + size

        register_button_widget("toolbelt_tower_button" .. i
                             , am.rect(x1, y1, x2, y2)
                             , function() select_toolbelt_button(i) end)

        return am.translate(vec2(size + padding, 0) * i + offset)
            ^ am.group{
                am.translate(0, half_size)
                ^ pack_texture_into_sprite(TEXTURES.BUTTON1, size, size),

                am.translate(0, half_size)
                ^ pack_texture_into_sprite(tower_texture, size, size),

                am.translate(vec2(half_size))
                ^ am.group{
                    pack_texture_into_sprite(TEXTURES.BUTTON1, half_size, half_size),
                    am.scale(2)
                    ^ am.text(key_name, COLORS.BLACK)
                }
            }
    end

    local toolbelt_height = hex_height(HEX_SIZE) * 2
    local function get_tower_tooltip_text_node(tower_type)
        local name = get_tower_name(tower_type)
        local placement_rules = get_tower_placement_rules_text(tower_type)
        local short_desc = get_tower_short_description(tower_type)
        local cost = get_tower_cost(tower_type)

        if not (name or placement_rules or short_desc or cost) then
            return am.group():tag"tower_tooltip_text"
        end

        local color = COLORS.PALE_SILVER
        return (am.translate(WIN.left + 10, WIN.bottom + toolbelt_height + 20)
            ^ am.group{
                am.translate(0, 60)
                ^ am.text(name, color, "left"):tag"tower_name",

                am.translate(0, 40)
                ^ am.text(placement_rules, color, "left"):tag"tower_placement_rules",

                am.translate(0, 20)
                ^ am.text(short_desc, color, "left"):tag"tower_short_description",

                am.translate(0, 0)
                ^ am.text(string.format("cost: %d", cost), color, "left"):tag"tower_cost"
            }
        )
        :tag"tower_tooltip_text"
    end
    local toolbelt = am.group{
        am.group():tag"tower_tooltip_text",
        am.rect(WIN.left, WIN.bottom, WIN.right, WIN.bottom + toolbelt_height, COLORS.TRANSPARENT)
    }:tag"toolbelt"

    local padding = 15
    local size = toolbelt_height - padding
    local half_size = size/2
    local offset = vec2(WIN.left + padding*3, WIN.bottom + padding/3)
    local tab_button = am.translate(vec2(0, half_size) + offset) ^ am.group{
        pack_texture_into_sprite(TEXTURES.WIDER_BUTTON1, 54, 32),
        pack_texture_into_sprite(TEXTURES.TAB_ICON, 25, 25)
    }
    toolbelt:append(tab_button)
    local tower_select_square = (
        am.translate(vec2(size + padding, half_size) + offset)
        ^ am.rect(-size/2-3, -size/2-3, size/2+3, size/2+3, COLORS.SUNRAY)
    ):tag"tower_select_square"
    tower_select_square.hidden = true
    toolbelt:append(tower_select_square)

    local keys = { '1', '2', '3', '4', 'q', 'w', 'e', 'r', 'a', 's', 'd', 'f' }
    --local keys = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=' }
    -- order of this array is the order of towers on the toolbelt.
    local tower_type_values = {
        TOWER_TYPE.WALL,
        TOWER_TYPE.HOWITZER,
        TOWER_TYPE.REDEYE,
        TOWER_TYPE.MOAT,
        TOWER_TYPE.RADAR,
        TOWER_TYPE.LIGHTHOUSE
    }
    for i = 1, #keys do
        local icon_texture = get_tower_icon_texture(tower_type_values[i])
        toolbelt:append(
            toolbelt_button(
                size,
                half_size,
                icon_texture,
                padding,
                i,
                offset,
                keys[i]
            )
        )
    end

    select_tower_type = function(tower_type)
        state.selected_tower_type = tower_type

        if get_tower_spec(tower_type) then
            WIN.scene:replace("tower_tooltip_text", get_tower_tooltip_text_node(tower_type))

            local new_position = vec2((size + padding) * tower_type, size/2) + offset
            if toolbelt("tower_select_square").hidden then
                toolbelt("tower_select_square").position2d = new_position
                toolbelt("tower_select_square").hidden = false
            else
                toolbelt("tower_select_square"):action(am.tween(0.1, { position2d = new_position }))
            end

            WIN.scene:replace("cursor", get_tower_cursor(tower_type):tag"cursor")

            WIN.scene:action(am.play(am.sfxr_synth(SOUNDS.SELECT1), false, 1, SFX_VOLUME))
        else
            -- de-selecting currently selected tower if any
            toolbelt("tower_select_square").hidden = true

            WIN.scene:replace("cursor", make_hex_cursor(0, COLORS.TRANSPARENT))
        end
    end

    return toolbelt
end

-- |color_f| can be a function that takes a hex and returns a color, or just a color
-- |action_f| should be an action that operates on the group node or nil
function make_hex_cursor(radius, color_f, action_f)
    local color = type(color_f) == "userdata" and color_f or nil
    local map = spiral_map(vec2(0), radius)
    local group = am.group()

    for _,h in pairs(map) do
        local hexagon = am.circle(hex_to_pixel(h), HEX_SIZE, color or color_f(h), 6)
        group:append(hexagon)
    end

    if action_f then
        group:action(action_f)
    end

    return group:tag"cursor"
end

function game_scene()
    local score = am.translate(WIN.left + 10, WIN.top - 20)
                  ^ am.text("", "left"):tag"score"

    local money = am.translate(WIN.left + 10, WIN.top - 40)
                  ^ am.text("", "left"):tag"money"

    local top_right_display = am.translate(WIN.right - 10, WIN.top - 20)
                              ^ am.text("", "right", "top"):tag"top_right_display"

    local curtain = am.rect(WIN.left, WIN.bottom, WIN.right, WIN.top, COLORS.TRUE_BLACK)
    curtain:action(coroutine.create(function()
        am.wait(am.tween(curtain, 3, { color = vec4(0) }, am.ease.out(am.ease.hyperbola)))
        WIN.scene:remove(curtain)
        return true
    end))

    local scene = am.group{
        state.world,
        am.translate(OFF_SCREEN):tag"cursor_translate" ^ make_hex_cursor(0, COLORS.TRANSPARENT),
        score,
        money,
        top_right_display,
        make_game_toolbelt(),
        curtain,
    }:tag"game"

    scene:action(game_action)

    return scene
end

function game_init()
    state = get_initial_game_state()

    build_tower(HEX_GRID_CENTER, TOWER_TYPE.RADAR)
    -- @HACK to make the center tile passable even though there's a tower on it
    state.map.get(HEX_GRID_CENTER.x, HEX_GRID_CENTER.y).elevation = 0

    WIN.scene:remove("game")
    WIN.scene:append(game_scene())
end

