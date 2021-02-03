
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


