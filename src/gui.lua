
-- text popup in the middle of the screen that dissapates
function gui_alert(message, color, decay_time)
    win.scene:append(
        am.scale(3) ^ am.text(message, color or COLORS.WHITE)
        :action(coroutine.create(function(self)
            am.wait(am.tween(self, decay_time or 1, { color = vec4(0) }, am.ease_in_out))
            win.scene:remove(self)
        end))
    )
end

function gui_numberfield(dimensions, opts)

end

function gui_textfield(position, dimensions, max, disallowed_chars)
    local width, height = dimensions.x, dimensions.y
    local disallowed_chars = disallowed_chars or {}
    local max = max or 10

    local outer_rect = am.rect(
        -width/2,
        -height/2,
        width/2,
        height/2,
        COLORS.VERY_DARK_GRAY
    )
    local inner_rect = am.rect(
        -width/2 + 1,
        -height/2 + 1,
        width/2 - 2,
        height/2 - 2,
        COLORS.PALE_SILVER
    )

    local group = am.group{
        outer_rect,
        inner_rect,
        am.translate(-width/2 + 5, 0) ^ am.scale(2) ^ am.text("", COLORS.BLACK, "left"),
        am.translate(-width/2 + 5, -8) ^ am.line(vec2(0, 0), vec2(16, 0), 2, COLORS.BLACK)
    }

    group:action(function(self)
        local keys = win:keys_pressed()
        if #keys == 0 then return end

        local chars = {}
        local shift = win:key_down("lshift") or win:key_down("rshift")
        for i,k in pairs(keys) do
            if k:len() == 1 then -- @HACK alphabetical or digit characters
                if string.match(k, "%a") then
                    if shift then
                        table.insert(chars, k:upper())
                    else
                        table.insert(chars, k)
                    end
                elseif string.match(k, "%d") then
                    if shift then
                        if k == "1" then table.insert(chars, "!")
                        elseif k == "2" then table.insert(chars, "@")
                        elseif k == "3" then table.insert(chars, "#")
                        elseif k == "4" then table.insert(chars, "$")
                        elseif k == "5" then table.insert(chars, "%")
                        elseif k == "6" then table.insert(chars, "^")
                        elseif k == "7" then table.insert(chars, "&")
                        elseif k == "8" then table.insert(chars, "*")
                        elseif k == "9" then table.insert(chars, "(")
                        elseif k == "0" then table.insert(chars, ")")
                        end
                    else
                        table.insert(chars, k)
                    end
                end
            -- begin non-alphabetical/digit
            elseif k == "minus" then
                if shift then table.insert(chars, "_")
                else          table.insert(chars, "-") end
            elseif k == "equals" then
                if shift then table.insert(chars, "=")
                else          table.insert(chars, "+") end
            elseif k == "leftbracket" then
                if shift then table.insert(chars, "{")
                else          table.insert(chars, "[") end
            elseif k == "rightbracket" then
                if shift then table.insert(chars, "}")
                else          table.insert(chars, "]") end
            elseif k == "backslash" then
                if shift then table.insert(chars, "|")
                else          table.insert(chars, "\\") end
            elseif k == "semicolon" then
                if shift then table.insert(chars, ":")
                else          table.insert(chars, ";") end
            elseif k == "quote" then
                if shift then table.insert(chars, "\"")
                else          table.insert(chars, "'") end
            elseif k == "backquote" then
                if shift then table.insert(chars, "~")
                else          table.insert(chars, "`") end
            elseif k == "comma" then
                if shift then table.insert(chars, "<")
                else          table.insert(chars, ",") end
            elseif k == "period" then
                if shift then table.insert(chars, ">")
                else          table.insert(chars, ".") end
            elseif k == "slash" then
                if shift then table.insert(chars, "?")
                else          table.insert(chars, "/") end

            -- control characters
            elseif k == "backspace" then
                -- @NOTE this doesn't preserve the order of chars in the array so if
                -- someone presses a the key "a" then the backspace key in the same frame, in that order
                -- the backspace occurs first
                self"text".text = self"text".text:sub(1, self"text".text:len() - 1)

            elseif k == "tab" then
                -- @TODO

            elseif k == "space" then
                table.insert(chars, " ")

            elseif k == "capslock" then
                -- @OTOD
            end
        end

        for _,c in pairs(chars) do
            if not disallowed_chars[c] then
                if self"text".text:len() <= max then
                    self"text".text = self"text".text .. c
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

