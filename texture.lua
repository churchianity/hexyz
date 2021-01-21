

function load_textures()
    TEX_BUTTON1             = am.texture2d("res/button1.png")
    TEX_WIDER_BUTTON1       = am.texture2d("res/wider_button1.png")
    TEX_TAB_ICON            = am.texture2d("res/tab_icon.png")
    TEX_SATELLITE           = am.texture2d("res/satelite.png")

    TEX_TOWER_WALL          = am.texture2d("res/tower_wall.png")
    TEX_TOWER_MOAT          = am.texture2d("res/tower_moat.png")
    TEX_TOWER_REDEYE        = am.texture2d("res/tower_redeye.png")
    TEX_TOWER_LIGHTHOUSE    = am.texture2d("res/tower_lighthouse.png")

    TEX_MOB_BEEPER          = am.texture2d("res/mob_beeper.png")
end

function pack_texture_into_sprite(texture, width, height)
    return am.sprite{
        texture = texture,
        s1 = 0, s2 = 1, t1 = 0, t2 = 1,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }
end

