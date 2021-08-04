
local map_editor_state = {
    map = {},
    world = {}
}

local function deselect_tile()
    win.scene:remove("tile_select_box")
end

function map_editor_action()
    local mouse          = win:mouse_position()
    local hex            = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET, vec2(HEX_SIZE))
    local rounded_mouse  = hex_to_pixel(hex, vec2(HEX_SIZE)) + WORLDSPACE_COORDINATE_OFFSET
    local evenq          = hex_to_evenq(hex)
    local tile           = hex_map_get(map_editor_state.map, hex)
    local interactable   = evenq_is_in_interactable_region(evenq{ y = -evenq.y })

    if win:mouse_pressed"left" then
        deselect_tile()

        win.scene:remove("tile_select_box")
        win.scene:append((
                am.translate(rounded_mouse)
                ^ pack_texture_into_sprite(TEXTURES.SELECT_BOX, HEX_SIZE*2, HEX_SIZE*2, COLORS.SUNRAY)
            )
            :tag"tile_select_box"
        )
    end

    -- update the cursor
    if not interactable then
        win.scene("cursor").hidden = true

    else
        win.scene("cursor").hidden = false
        win.scene("cursor_translate").position2d = rounded_mouse
    end
end

function map_editor_init()
    local map_editor_scene = am.group():tag"map_editor"

    map_editor_state.map = default_map_editor_map()
    map_editor_state.world = make_hex_grid_scene(map_editor_state.map)

    map_editor_scene:append(map_editor_state.world)

    win.scene:remove("map_editor")
    win.scene:append(map_editor_scene)
    win.scene:append(
        am.translate(HEX_GRID_CENTER):tag"cursor_translate"
        ^ make_hex_cursor(0, COLORS.TRANSPARENT):tag"cursor"
    )

    win.scene:late_action(map_editor_action)
end

