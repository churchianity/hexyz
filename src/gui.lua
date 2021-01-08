
local hot, active = false, false
local widgets = {}

function get_widgets() return widgets end

function register_widget(id, poll)
    widgets[id] = { id = id, poll = poll }
end

function set_hot(id)
    if not active then hot = { id = id } end
end

function register_button_widget(id, rect)
    register_widget(id, function()
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

        return click
    end)
end

function make_button_widget(id, position, dimensions, text)
    local rect = am.rect(
        -dimensions.x/2,
        dimensions.y/2,
        dimensions.x/2,
        -dimensions.y/2,
        vec4(1, 0, 0, 1)
    )

    register_button_widget(id, rect)
    return am.group{
        rect,
        am.text(text)
    }:tag(id)
end

