
function load_textures()
    TEX_MOB1_1 = am.texture2d("../res/mob1_1.png")
end

function pack_texture_into_sprite(texture, width, height)
    return am.sprite{
        texture = texture,
        s1 = 0, s2 = 1, t1 = 0, t2 = 1,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }
end



