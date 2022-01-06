
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

local function gui_make_backing_rect(
    position,
    content_width,
    content_height,
    padding
)
    local half_width = content_width/2
    local half_height = content_height/2

    local x1 = position[1] - half_width - padding
    local y1 = position[2] - half_height - padding
    local x2 = position[1] + half_width + padding
    local y2 = position[2] + half_height + padding

    return x1, y1, x2, y2
end

-- args {
--  position vec2
--  onclick function
--  padding number
--
--  min_width number
--  min_height number
--
--  label string
--  font {
--    color vec4
--    halign "center" | "left" | "right"
--    valign "center" | "top" | "bottom"
--  }
-- }
function gui_make_button(args)
    local args = args or {}

    local position = args.position or vec2(0)
    local onclick = args.onclick
    local padding = args.padding or 6

    local min_width = args.min_width or 0
    local min_height = args.min_height or 0

    local label = args.label or ""
    local font = args.font or {
        color = vec4(1),
        halign = "center",
        valign = "center"
    }

    local scene = am.group()

    local text = am.text(args.label or "", font.color, font.halign, font.valign)
    scene:append(am.translate(args.position) ^ text)

    local content_width = math.max(min_width, text.width)
    local content_height = math.max(min_height, text.height)

    local x1, y1, x2, y2 = gui_make_backing_rect(position, content_width, content_height, padding)

    local back_rect = am.rect(x1 - padding/2, y1, x2, y2 + padding/2, vec4(0, 0, 0, 1))
    local front_rect = am.rect(x1, y1, x2, y2, vec4(0.4))
    scene:prepend(front_rect)
    scene:prepend(back_rect)

    scene:action(function(self)
        if point_in_rect(win:mouse_position(), back_rect) then
            if win:mouse_pressed"left" then
                front_rect.color = vec4(0.4)

                if onclick then
                    onclick()
                end
            else
                front_rect.color = vec4(0, 0, 0, 1)
            end
        else
            front_rect.color = vec4(0.4)
        end
    end)

    return scene
end

function gui_textfield(
    position,
    dimensions,
    max,
    disallowed_chars
)
    local width, height = dimensions.x, dimensions.y
    local disallowed_chars = disallowed_chars or {}
    local max = max or 10
    local padding = padding or 6
    local half_width = width/2
    local half_height = height/2

    local x1 = position[1] - half_width - padding
    local y1 = position[2] - half_height - padding
    local x2 = position[1] + half_width + padding
    local y2 = position[2] + half_height + padding

    local back_rect = am.rect(x1 - padding/2, y1, x2, y2 + padding/2, vec4(0, 0, 0, 1))
    local front_rect = am.rect(x1, y1, x2, y2, vec4(0.4))

    local group = am.group{
        back_rect,
        front_rect,
        am.translate(-width/2 + padding, 0) ^ am.scale(2) ^ am.text("", vec4(0, 0, 0, 1), "left"),
        am.translate(-width/2 + padding, -8) ^ am.line(vec2(0, 0), vec2(16, 0), 2, vec4(0, 0, 0, 1))
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
                -- @TODO
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

function gui_open_modal()

end

