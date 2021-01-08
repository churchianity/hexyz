

function load_textures()
    TEX_MARQUIS             = am.texture2d("res/marquis.png")

    TEX_ARROW               = am.texture2d("res/arrow.png")

    TEX_WALL_CLOSED         = am.texture2d("res/wall_closed.png")
    TEX_TOWER1              = am.texture2d("res/tower1.png")
    TEX_TOWER2              = am.texture2d("res/tower2.png")

    TEX_MOB1_1              = am.texture2d("res/mob1_1.png")
    TEX_MOB2_1              = am.texture2d("res/mob2_1.png")
end

function pack_texture_into_sprite(texture, width, height)
    return am.sprite{
        texture = texture,
        s1 = 0, s2 = 1, t1 = 0, t2 = 1,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }
end

