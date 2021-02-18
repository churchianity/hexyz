

function gui_numberfield(dimensions, opts)

end


function gui_textfield(position, dimensions, max, disallowed_keys)
    local width, height = dimensions.x, dimensions.y
    local disallowed_keys = disallowed_keys or {}
    local max = max or 99

    local padding = 2
    local outer_rect = am.rect(-width/2, -height/2, width/2, height/2, COLORS.VERY_DARK_GRAY)
    local inner_rect = am.rect(-width/2 + padding
                             , -height/2 + padding
                             , width/2 - padding
                             , height/2 - padding
                             , COLORS.PALE_SILVER)

    local group = am.group{
        outer_rect,
        inner_rect,
        am.translate(-width/2 + 5, 0) ^ am.scale(2) ^ am.text("", COLORS.BLACK, "left"),
        am.translate(-width/2 + 5, -8) ^ am.line(vec2(0, 0), vec2(16, 0), 2, COLORS.BLACK)
    }

    group:action(function(self)
        local keys = win:keys_pressed()
        if #keys == 0 then return end

        -- @HACK all characters and digits are represented by a single string in amulet
        -- so we don't have to iterate over everything
        -- pattern matching doesn't work because control characters are also just normal strings
        for i,k in pairs(keys) do
            if not disallowed_keys[k] then
                if k:len() == 1 then
                    if string.match(k, "%d") then
                        self"text".text = self"text".text .. k

                    elseif win:key_down("lshift") or win:key_down("rshift") then
                        self"text".text = self"text".text .. k:upper()

                    else
                        self"text".text = self"text".text .. k
                    end
                elseif k == "space" then
                    self"text".text = self"text".text .. " "

                elseif k == "backspace" then
                    self"text".text = self"text".text:sub(1, self"text".text:len() - 1)

                elseif k == "enter" then

                end
            end
        end
    end)

    return group
end

function gui_slider(position, dimensions, bar_color, circle_color, min, max, default_value, action)
    local position = position or vec2(0)
    local width = dimensions.x
    local height = dimensions.y
    local bar_color = bar_color or COLORS.WHITE
    local circle_color = circle_color or COLORS.GREEN_YELLOW
    local min = min or 0
    local max = max or 100
    local default_value = math.clamp(default_value or 50, min, max)

    local slider = pack_texture_into_sprite(TEXTURES.GUI_SLIDER, width, height, bar_color)
    local circle = am.circle(vec2(-width/2 + (default_value/max) * (width/2), 0), height, circle_color)

    local node = am.translate(position) ^ am.group{
        slider,
        circle
    }

    if action then node:action(action) end

    return node
end

