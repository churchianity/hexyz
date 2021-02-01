
local hot, active = false, false
local widgets = {}

function get_widgets() return widgets end

function register_widget(id, poll)
    widgets[id] = { id = id, poll = poll }
end

function set_hot(id)
    if not active then hot = { id = id } end
end

function register_button_widget(id, rect, onclick)
    register_widget(id, function(i)
        local click = false

        if active and active.id == id then
            if WIN:mouse_released"left" then
                if hot and hot.id == id then click = true end
                active = false
            end
        elseif hot and hot.id == id then
            if WIN:mouse_pressed"left" then active = { id = id } end
        end

        if point_in_rect(WIN:mouse_position(), rect) then set_hot(id) end

        if click then onclick() end
    end)
end

function do_gui_updates()
    for i,w in pairs(widgets) do
        w.poll(i)
    end
end

local function get_tower_tooltip_text(tower_type)
    return string.format(
        "%s\n%s\n%s\ncost: %d"
      , get_tower_name(tower_type)
      , get_tower_placement_rules_text(tower_type)
      , get_tower_short_description(tower_type)
      , get_tower_base_cost(tower_type)
    )
end

function toolbelt()
    local function button(size, half_size, tower_texture, padding, i, offset, key_name)
        local x1 = (size + padding) * i + offset.x
        local y1 = offset.y
        local x2 = (size + padding) * i + offset.x + size
        local y2 = offset.y + size

        register_button_widget("toolbelt_tower_button" .. i, am.rect(x1, y1, x2, y2), function() select_tower_type(i) end)

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

    -- init the toolbelt
    local toolbelt_height = hex_height(HEX_SIZE) * 2
    local toolbelt = am.group{
        am.translate(WIN.left + 10, WIN.bottom + toolbelt_height + 20)
        ^ am.text(get_tower_tooltip_text(SELECTED_TOWER_TYPE), "left", "bottom"):tag"tower_tooltip",
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
    toolbelt:append(tower_select_square)

    -- fill in the other tower options
    local tower_type_values = {
        TOWER_TYPE.REDEYE,
        TOWER_TYPE.LIGHTHOUSE,
        TOWER_TYPE.WALL,
        TOWER_TYPE.MOAT
    }
    local keys = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=' }
    for i = 1, #keys do
        toolbelt:append(
            button(
                size,
                half_size,
                get_tower_texture(tower_type_values[i]),
                padding,
                i,
                offset,
                keys[i]
            )
        )
    end

    select_tower_type = function(tower_type)
        SELECTED_TOWER_TYPE = tower_type
        if TOWER_SPECS[SELECTED_TOWER_TYPE] then
            WIN.scene"tower_tooltip".text = get_tower_tooltip_text(tower_type)
            local new_position = vec2((size + padding) * tower_type, size/2) + offset
            WIN.scene"tower_select_square":action(am.tween(0.1, { position2d = new_position }))

            WIN.scene:action(am.play(am.sfxr_synth(SOUNDS.SELECT1), false, 1, SFX_VOLUME))
        end
    end

    return toolbelt
end
