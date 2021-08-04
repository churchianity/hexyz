
local map_editor_state = {
    map = {},
    world = {},

    selected_tile = false
}

local function deselect_tile()
    map_editor_state.selected_tile = false
    win.scene:remove("tile_select_box")
end

function map_editor_action()
    local mouse         = win:mouse_position()
    local hex           = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET, vec2(HEX_SIZE))
    local rounded_mouse = hex_to_pixel(hex, vec2(HEX_SIZE)) + WORLDSPACE_COORDINATE_OFFSET
    local evenq         = hex_to_evenq(hex)
    local tile          = hex_map_get(map_editor_state.map, hex)
    local interactable  = evenq_is_in_interactable_region(evenq{ y = -evenq.y })

    if win:key_pressed"escape" then
        win.scene("map_editor").paused = true
        win.scene:append(make_scene_menu(map_editor_scene_options))
    end

    if win:mouse_down"left" then
        deselect_tile()

        map_editor_state.selected_tile = tile
        win.scene:append((
                am.translate(rounded_mouse)
                ^ pack_texture_into_sprite(TEXTURES.SELECT_BOX, HEX_SIZE*2, HEX_SIZE*2, COLORS.SUNRAY)
            )
            :tag"tile_select_box"
        )
    end

    if map_editor_state.selected_tile then
        if win:key_pressed"a" then
            -- make the selected tile 'mountain'
            map_editor_state.selected_tile.elevation = 0.75
            map_editor_state.selected_tile.node("circle").color = map_elevation_color(map_editor_state.selected_tile.elevation)

        elseif win:key_pressed"w" then
            -- make the selected tile 'water'
            map_editor_state.selected_tile.elevation = -0.75
            map_editor_state.selected_tile.node("circle").color = map_elevation_color(map_editor_state.selected_tile.elevation)

        elseif win:key_pressed"d" then
            -- make the selected tile 'dirt'
            map_editor_state.selected_tile.elevation = 0.25
            map_editor_state.selected_tile.node("circle").color = map_elevation_color(map_editor_state.selected_tile.elevation)

        elseif win:key_pressed"g" then
            -- make the selected tile 'grass'
            map_editor_state.selected_tile.elevation = -0.25
            map_editor_state.selected_tile.node("circle").color = map_elevation_color(map_editor_state.selected_tile.elevation)
        end

        -- fine tune tile's elevation with mouse wheel
        local mouse_wheel_delta = win:mouse_wheel_delta().y / 100
        if map_editor_state.selected_tile and mouse_wheel_delta ~= 0 then
            map_editor_state.selected_tile.elevation = math.clamp(map_editor_state.selected_tile.elevation + mouse_wheel_delta, -1, 1)
            map_editor_state.selected_tile.node("circle").color = map_elevation_color(map_editor_state.selected_tile.elevation)
        end
    end

    -- update the cursor
    if not interactable then
        win.scene("cursor").hidden = true

    else
        win.scene("cursor").hidden = false
        win.scene("cursor_translate").position2d = rounded_mouse
    end

    if tile then
        win.scene("top_right_display").text = string.format(
            "raw elevation value: %.2f\ntile type: %s",
            tile.elevation, map_elevation_to_tile_type(tile.elevation)
        )
    end
end

function map_editor_init()
    local map_editor_scene = am.group():tag"map_editor"

    map_editor_state.map = default_map_editor_map(1)
    map_editor_state.world = make_hex_grid_scene(map_editor_state.map, false)

    map_editor_scene:append(map_editor_state.world)

    win.scene:remove("map_editor")
    win.scene:append(map_editor_scene)
    win.scene:append(
        am.translate(HEX_GRID_CENTER):tag"cursor_translate"
        ^ make_hex_cursor_node(0, COLORS.TRANSPARENT):tag"cursor"
    )

    win.scene:append(make_top_right_display_node())

    win.scene:late_action(map_editor_action)
end

