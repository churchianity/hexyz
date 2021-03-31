

game = false -- flag to tell if there is a game running
state = {}


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
    local STARTING_MONEY = 50

    local map, world = random_map(seed)

    return {
        map = map,              -- map of hex coords map[x][y] to a 'tile'
        world = world,          -- the root scene graph node for the game 'world'
        ui = nil,               -- unused, root scene graph node for the 'ui' stuff

        perf = {},              -- result of call to am.perf_stats, called every frame
        time = 0,               -- real time since the *current* game started in seconds
        score = 0,              -- current game score
        money = STARTING_MONEY, -- current money

        towers = {},            -- list of tower entities
        mobs = {},              -- list of mob entities
        projectiles = {},       -- list of projectile entities

        current_wave = 1,
        time_until_next_wave = 15,
        time_until_next_break = 0,
        spawning = false,
        spawn_chance = 0,
        last_mob_spawn_time = 0,

        selected_tower_type = false,
        selected_toolbelt_button = false,
        selected_top_right_display_type = TRDTS.SEED,
    }
end

local function get_wave_timer_text()
    if state.spawning then
        return string.format("WAVE (%d) OVER: %.2f", state.current_wave, state.time_until_next_break)
    else
        return string.format("NEXT WAVE (%d): %.2f", state.current_wave, state.time_until_next_wave)
    end
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
        str = table.tostring(hex_map_get(state.map, hex))
    end
    return str
end

-- initialized later, as part of the init of the toolbelt
local function select_tower_type(tower_type) end
local function select_toolbelt_button(i) end

local function get_wave_time(current_wave)
    return 45
end

local function get_break_time(current_wave)
    return 20
end

local function do_day_night_cycle()
    local tstep = (math.sin(state.time * am.delta_time) + 1) / 100
    --state.world"negative_mask".color = vec4(tstep){a=1}
end

local function game_pause()
    win.scene("game").paused = true

    win.scene:append(main_scene(false, false))
end

local function game_deserialize(json_string)
    -- @TODO decode from some compressed format or whatever
    local new_state = am.parse_json(json_string)

    if new_state.version ~= version then
        log("loading old save data.")
        return nil
    end

    new_state.map, new_state.world = random_map(new_state.seed)
    new_state.seed = nil

    for i,t in pairs(new_state.towers) do
        if t then
            new_state.towers[i] = tower_deserialize(t)

            for _,h in pairs(new_state.towers[i].hexes) do
                local tile = hex_map_get(new_state.map, h.x, h.y)
                tile.elevation = tile.elevation + new_state.towers[i].height
            end

            -- @STATEFUL, shouldn't be done here
            new_state.world:append(new_state.towers[i].node)
        end
    end

    -- after we have re-constituted all of the towers and modified the map's elevations accordingly,
    -- we should re-calc the flow-field
    apply_flow_field(new_state.map, generate_flow_field(new_state.map, HEX_GRID_CENTER), new_state.world)

    for i,m in pairs(new_state.mobs) do
        if m then
            new_state.mobs[i] = mob_deserialize(m)

            -- @STATEFUL, shouldn't be done here
            new_state.world:append(new_state.mobs[i].node)
        end
    end

    for i,p in pairs(new_state.projectiles) do
        if p then
            new_state.projectiles[i] = projectile_deserialize(p)

            -- @STATEFUL, shouldn't be done here
            new_state.world:append(new_state.projectiles[i].node)
        end
    end

    return new_state
end

local function game_serialize()
    local serialized = table.shallow_copy(state)
    serialized.version = version

    serialized.seed = state.map.seed
    serialized.map = nil -- we re-generate the entire map from the seed on de-serialize

    -- in order to serialize the game state, we have to convert all relevant userdata into
    -- something else.
    --
    -- this practically means vectors need to become arrays of floats,
    -- and the scene graph needs to be re-constituted at load time
    --
    -- this is dumb and if i forsaw this i would have probably used float arrays instead of vectors

    serialized.towers = {}
    for i,t in pairs(state.towers) do
        if t then
            serialized.towers[i] = tower_serialize(t)
        end
    end

    serialized.mobs = {}
    for i,m in pairs(state.mobs) do
        if m then
            serialized.mobs[i] = mob_serialize(m)
        end
    end

    serialized.projectiles = {}
    for i,p in pairs(state.projectiles) do
        if p then
            serialized.projectiles[i] = projectile_serialize(p)
        end
    end

    -- @TODO b64 encode or otherwise scramble/compress
    return am.to_json(serialized)
end

local function deselect_tile()
    win.scene:remove("tile_select_box")
end

local function game_action(scene)
    if state.score < 0 then game_end() return true end

    state.perf = am.perf_stats()
    state.time = state.time + am.delta_time
    state.score = state.score + am.delta_time

    if state.spawning then
        state.time_until_next_break = state.time_until_next_break - am.delta_time

        if state.time_until_next_break <= 0 then
            state.time_until_next_break = 0
            state.current_wave = state.current_wave + 1

            state.spawning = false

            state.time_until_next_wave = get_break_time(state.current_wave)
        end
    else
        state.time_until_next_wave = state.time_until_next_wave - am.delta_time

        if state.time_until_next_wave <= 0 then
            state.time_until_next_wave = 0

            state.spawning = true

            -- calculate spawn chance for next wave
            state.spawn_chance = math.log(state.current_wave)/100 + 0.002
            log(state.spawn_chance)

            state.time_until_next_break = get_wave_time(state.current_wave)
        end
    end

    local mouse          = win:mouse_position()
    local hex            = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET, vec2(HEX_SIZE))
    local rounded_mouse  = hex_to_pixel(hex, vec2(HEX_SIZE)) + WORLDSPACE_COORDINATE_OFFSET
    local evenq          = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))
    local tile = hex_map_get(state.map, hex)

    local interactable = evenq_is_in_interactable_region(evenq{ y = -evenq.y })
    local buildable = tower_type_is_buildable_on(hex, tile, state.selected_tower_type)

    if win:mouse_pressed"left" then
        deselect_tile()

        if interactable then
            if buildable then
                local broken, flow_field = building_tower_breaks_flow_field(state.selected_tower_type, hex)
                local cost = get_tower_cost(state.selected_tower_type)

                if broken then
                    local node = win.scene("cursor"):child(2)
                    node.color = COLORS.CLARET
                    node:action(am.tween(0.1, { color = COLORS.TRANSPARENT }))
                    play_sfx(SOUNDS.BIRD2)
                    alert("closes the circle")

                elseif cost > state.money then
                    local node = win.scene("cursor"):child(2)
                    node.color = COLORS.CLARET
                    node:action(am.tween(0.1, { color = COLORS.TRANSPARENT }))
                    play_sfx(SOUNDS.BIRD2)
                    alert("not enough $$$$")

                else
                    update_money(-cost)
                    build_tower(hex, state.selected_tower_type, flow_field)

                    if flow_field then
                        apply_flow_field(state.map, flow_field, state.world)
                    end
                end
            else
                -- interactable tile, but no tower type selected
                -- depending on what's under the cursor, we can show some information.
                local towers = towers_on_hex(hex)
                local tcount = table.count(towers)

                if tcount > 0 then
                    play_sfx(SOUNDS.SELECT1)
                    win.scene:remove("tile_select_box")
                    win.scene:append((
                            am.translate(rounded_mouse)
                            ^ pack_texture_into_sprite(TEXTURES.SELECT_BOX, HEX_SIZE*2, HEX_SIZE*2, COLORS.SUNRAY)
                        )
                        :tag"tile_select_box"
                    )
                end
            end
        end
    end

    if win:mouse_pressed"middle" then
        win.scene("world_scale").scale2d = vec2(1)

    elseif win:key_down"lctrl" then
        local mwd = win:mouse_wheel_delta()
        win.scene("world_scale").scale2d = win.scene("world_scale").scale2d + vec2(mwd.y) / 100
    end

    if win:key_pressed"escape" then
        game_pause()

    elseif win:key_pressed"f1" then
        state.selected_top_right_display_type = (state.selected_top_right_display_type + 1) % #table.keys(TRDTS)

    elseif win:key_pressed"f2" then
        state.world"flow_field".hidden = not state.world"flow_field".hidden

    elseif win:key_pressed"f3" then
        game_save()

    elseif win:key_pressed"tab" then
        if win:key_down"lshift" then
            select_toolbelt_button((state.selected_toolbelt_button + table.count(TOWER_TYPE) - 2) % table.count(TOWER_TYPE) + 1)
        else
            select_toolbelt_button((state.selected_toolbelt_button) % table.count(TOWER_TYPE) + 1)
        end
    elseif win:key_pressed"1" then select_toolbelt_button( 1)
    elseif win:key_pressed"2" then select_toolbelt_button( 2)
    elseif win:key_pressed"3" then select_toolbelt_button( 3)
    elseif win:key_pressed"4" then select_toolbelt_button( 4)
    elseif win:key_pressed"q" then select_toolbelt_button( 5)
    elseif win:key_pressed"w" then select_toolbelt_button( 6)
    elseif win:key_pressed"e" then select_toolbelt_button( 7)
    elseif win:key_pressed"r" then select_toolbelt_button( 8)
    elseif win:key_pressed"a" then select_toolbelt_button( 9)
    elseif win:key_pressed"s" then select_toolbelt_button(10)
    elseif win:key_pressed"d" then select_toolbelt_button(11)
    elseif win:key_pressed"f" then select_toolbelt_button(12)
    end

    do_entity_updates()
    do_mob_spawning(state.spawn_chance)
    do_day_night_cycle()

    -- update the cursor
    if not interactable then
        win.scene("cursor").hidden = true

    else
        if state.selected_tower_type then
            if buildable then
                win.scene("cursor").hidden = false

            else
                win.scene("cursor").hidden = true
            end
        else
            -- if we don't have a tower selected, but the tile is interactable, then show the 'select' cursor
            win.scene("cursor").hidden = false
        end
        win.scene("cursor_translate").position2d = rounded_mouse
    end

    win.scene("score").text = string.format("SCORE: %.2f", state.score)
    win.scene("money").text = string.format("MONEY: $%d", state.money)
    win.scene("wave_timer").text = get_wave_timer_text()
    win.scene("top_right_display").text = get_top_right_display_text(hex, evenq, centered_evenq, state.selected_top_right_display_type)
end

local function make_game_toolbelt()
    local toolbelt_height = win.height * 0.07
    local tower_tooltip_text_position = vec2(win.left + 10, win.bottom + toolbelt_height + 20)
    local keys = { '1', '2', '3', '4', 'q', 'w', 'e', 'r', 'a', 's', 'd', 'f' }
    --local keys = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=' }

    local function get_tower_tooltip_text_node(tower_type)
        local name = get_tower_name(tower_type)
        local placement_rules = get_tower_placement_rules_text(tower_type)
        local short_desc = get_tower_short_description(tower_type)
        local cost = get_tower_cost(tower_type)

        local color = COLORS.WHITE
        return (am.translate(tower_tooltip_text_position)
            ^ am.scale(1)
            ^ am.group(
                am.translate(0, 40)
                ^ am.text(string.format("%s - %s", name, short_desc), color, "left"):tag"tower_name",

                am.translate(0, 20)
                ^ am.text(placement_rules, color, "left"):tag"tower_placement_rules",

                am.translate(0, 0)
                ^ am.text(string.format("$%d", cost), color, "left"):tag"tower_cost"
            )
        )
        :tag"tower_tooltip_text"
    end

    local padding = 12
    local offset = vec2(win.left, win.bottom + padding/3)
    local size = toolbelt_height - padding
    local half_size = size/2

    local function toolbelt_button(i)
        local texture = get_tower_icon_texture(i)
        local button =
            am.translate(vec2(size + padding, 0) * i + offset)
            ^ am.group(
                am.translate(0, half_size)
                ^ pack_texture_into_sprite(TEXTURES.BUTTON1, size, size),

                am.translate(0, half_size)
                ^ pack_texture_into_sprite(texture, size, size),

                am.translate(vec2(half_size))
                ^ am.group(
                    pack_texture_into_sprite(TEXTURES.BUTTON1, half_size, half_size),
                    am.scale(2)
                    ^ am.text(keys[i], COLORS.BLACK)
                )
            )

        local x1 = (size + padding) * i + offset.x - half_size
        local y1 = offset.y
        local x2 = (size + padding) * i + offset.x + size - half_size
        local y2 = offset.y + size
        local rect = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }

        return button, rect
    end

    local toolbelt = am.group(
        am.group():tag"tower_tooltip_text",
        am.rect(win.left, win.bottom, win.right, win.bottom + toolbelt_height, COLORS.TRANSPARENT)
    )
    :tag"toolbelt"

    local tower_select_square = (
        am.translate(vec2(size + padding, half_size) + offset)
        ^ am.rect(-size/2-3, -size/2-3, size/2+3, size/2+3, COLORS.SUNRAY)
    )
    :tag"toolbelt_select_square"
    tower_select_square.hidden = true
    toolbelt:append(tower_select_square)

    -- it's important these are in the same order as integers assigned to the enum
    -- TOWER_TYPE, and none are missing.
    local toolbelt_options = {
        TOWER_TYPE.WALL,
        TOWER_TYPE.HOWITZER,
        TOWER_TYPE.REDEYE,
        TOWER_TYPE.MOAT,
        TOWER_TYPE.RADAR,
        TOWER_TYPE.LIGHTHOUSE,
    }
    local toolbelt_buttons = {}
    for i,v in pairs(toolbelt_options) do
        local button, rect = toolbelt_button(i)
        table.insert(toolbelt_buttons, { node = button, rect = rect })
        toolbelt:append(button)
    end

    toolbelt:action(function(self)
        local mouse = win:mouse_position()

        if mouse.y <= (win.bottom + toolbelt_height) then
            for i,b in pairs(toolbelt_buttons) do
                if point_in_rect(mouse, b.rect) then
                    win.scene:replace("tower_tooltip_text", get_tower_tooltip_text_node(i))

                    if win:mouse_pressed("left") then
                        select_toolbelt_button(i)
                    end

                    break
                end
            end
        else
            if state.selected_tower_type then
                win.scene:replace("tower_tooltip_text", get_tower_tooltip_text_node(state.selected_tower_type))
            else
                win.scene:replace("tower_tooltip_text", am.group():tag"tower_tooltip_text")
            end
        end
    end)

    -- make the 'escape/pause/settings' button in the lower right
    local settings_button_position = vec2(win.right - half_size - 20, win.bottom + half_size + padding/3)
    local settings_button_rect = {
        x1 = settings_button_position.x - size/2,
        y1 = settings_button_position.y - size/2,
        x2 = settings_button_position.x + size/2,
        y2 = settings_button_position.y + size/2
    }
    toolbelt:append(
        am.translate(settings_button_position)
        ^ am.group(
            pack_texture_into_sprite(TEXTURES.BUTTON1, size, size),
            pack_texture_into_sprite(TEXTURES.GEAR, size - padding, size - padding)
        )
        :action(function(self)
            if point_in_rect(win:mouse_position(), settings_button_rect) then
                if win:mouse_pressed("left") then
                    game_pause()
                end
            end
        end)
    )

    select_tower_type = function(tower_type)
        state.selected_tower_type = tower_type

        if get_tower_spec(tower_type) then
            win.scene:replace(
                "toolbelt_tooltip_text",
                get_tower_tooltip_text_node(tower_type)
            )

            local new_position = vec2((size + padding) * tower_type, size/2) + offset
            if toolbelt("toolbelt_select_square").hidden then
                toolbelt("toolbelt_select_square").position2d = new_position
                toolbelt("toolbelt_select_square").hidden = false

            else
                toolbelt("toolbelt_select_square"):action(am.tween(0.1, { position2d = new_position }))
            end

            win.scene:replace("cursor", get_tower_cursor(tower_type):tag"cursor")

            play_sfx(SOUNDS.SELECT1)
        else
            deselect_tile()

            -- de-selecting currently selected tower if any
            toolbelt("toolbelt_select_square").hidden = true

            win.scene:replace("cursor", make_hex_cursor(0, COLORS.TRANSPARENT):tag"cursor")
        end
    end

    select_toolbelt_button = function(i)
        state.selected_toolbelt_button = i

        if get_tower_spec(i) then
            select_tower_type(i)
        else
            select_tower_type(nil)
        end
    end

    return toolbelt
end

local function game_scene()
    local score =
        am.translate(win.left + 10, win.top - 15)
        ^ am.text("", "left", "top"):tag"score"

    local money =
        am.translate(win.left + 10, win.top - 35)
        ^ am.text("", "left", "top"):tag"money"

    local wave_timer =
        am.translate(0, win.top - 20)
        ^ am.text(get_wave_timer_text()):tag"wave_timer"

    local send_now_button_position = vec2(0, win.top - 40)
    local send_now_button_dimensions = vec2(200, 20)
    local send_now_button_rect = {
        x1 = -send_now_button_dimensions.x/2 + send_now_button_position.x,
        y1 = -send_now_button_dimensions.y/2 + send_now_button_position.y,
        x2 = send_now_button_dimensions.x/2 + send_now_button_position.x,
        y2 = send_now_button_dimensions.y/2 + send_now_button_position.y
    }
    local send_now_button =
        am.translate(send_now_button_position)
        ^ am.text("> SEND NOW <")
        :tag"send_now_button"
        :action(function(self)
            local mouse = win:mouse_position()

            if point_in_rect(mouse, send_now_button_rect) then
                self.color = COLORS.SUNRAY

                if win:mouse_pressed("left") then
                    if state.spawning then
                        -- in this case, we don't exactly just send the next wave, we turn the current wave into the next
                        -- wave, and add the amount of time it would have lasted to the amount of remaining time in the
                        -- current wave
                        state.current_wave = state.current_wave + 1

                        -- calculate spawn chance for next wave
                        state.spawn_chance = math.log(state.current_wave)/100 + 0.002

                        state.time_until_next_break = state.time_until_next_break + get_break_time(state.current_wave)

                        play_sfx(SOUNDS.EXPLOSION4)
                    else
                        state.time_until_next_wave = 0

                        play_sfx(SOUNDS.EXPLOSION4)
                    end
                end
            else
                self.color = COLORS.WHITE
            end
        end)

    local top_right_display =
        am.translate(win.right - 10, win.top - 15)
        ^ am.text("", "right", "top"):tag"top_right_display"

    local bottom_right_display =
        am.translate(win.right - 10, win.bottom + win.height * 0.07 + 20)
        ^ am.text("", "right", "bottom"):tag"bottom_right_display"

    local curtain = am.rect(win.left, win.bottom, win.right, win.top, COLORS.TRUE_BLACK)
    curtain:action(coroutine.create(function()
        am.wait(am.tween(curtain, 3, { color = vec4(0) }, am.ease.out(am.ease.hyperbola)))
        win.scene:remove(curtain)
        return true
    end))

    local scene = am.group(
        am.scale(1):tag"world_scale" ^ state.world,
        am.translate(HEX_GRID_CENTER):tag"cursor_translate" ^ make_hex_cursor(0, COLORS.TRANSPARENT):tag"cursor",
        score,
        money,
        wave_timer,
        send_now_button,
        top_right_display,
        make_game_toolbelt(),
        curtain
    )
    :tag"game"

    -- dangling actions run before the main action
    scene:late_action(game_action)

    return scene
end

function update_score(diff) state.score = state.score + diff end
function update_money(diff) state.money = state.money + diff end

function game_end()
    state = {}
    game = false
    -- @TODO anything
end

function game_save()
    am.save_state("save", game_serialize(), "json")
    alert("succesfully saved!")
end

function game_init(saved_state)
    if saved_state then
        state = game_deserialize(saved_state)

        if not state then
            -- failed to load a save
            win.scene:append(main_scene(true, true))
            return
        end

        -- @HACK fixes a bug where loading game state with a tower type selected,
        -- but you don't have a built tower cursor node, so hovering a buildable tile throws an error
        select_tower_type(nil)
    else
        state = get_initial_game_state()
        local home_tower = build_tower(HEX_GRID_CENTER, TOWER_TYPE.RADAR)
        for _,h in pairs(home_tower.hexes) do
            -- @HACK to make the center tile(s) passable even though there's a tower on it
            hex_map_get(state.map, h).elevation = 0
        end
    end

    game = true
    win.scene:remove("game")
    win.scene:append(game_scene())
end

-- this is a stupid name, it just returns a scene node group of hexagons in a hexagonal shape centered at 0,0, of size |radius|
-- |color_f| can be a function that takes a hex and returns a color, or just a color
-- optionally, |action_f| is a function that operates on the group node every frame
function make_hex_cursor(radius, color_f, action_f)
    local color = type(color_f) == "userdata" and color_f or nil
    local map = hex_spiral_map(vec2(0), radius)
    local group = am.group()

    for _,h in pairs(map) do
        local hexagon = am.circle(hex_to_pixel(h, vec2(HEX_SIZE)), HEX_SIZE, color or color_f(h), 6)
        group:append(hexagon)
    end

    if action_f then
        group:action(action_f)
    end

    return group
end

