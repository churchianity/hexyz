

local function load_texture(filepath)
    local status, texture = pcall(am.texture2d, filepath)

    if status then
        return texture
    else
        return am.texture2d("res/bagel.jpg")
    end
end


TEXTURES = {
    -- note that in amulet, if you prefix paths with './', they fail to be found in the exported data.pak
    LOGO                    = load_texture("res/logo.png"),
    GEM1                    = load_texture("res/gem1.png"),

    SHADED_HEX              = load_texture("res/shaded_hex.png"),
    NEW_GAME_HEX            = load_texture("res/newgamehex.png"),
    SAVE_GAME_HEX           = load_texture("res/savegamehex.png"),
    LOAD_GAME_HEX           = load_texture("res/loadgamehex.png"),
    SETTINGS_HEX            = load_texture("res/settingshex.png"),
    MAP_EDITOR_HEX          = load_texture("res/mapeditorhex.png"),
    ABOUT_HEX               = load_texture("res/abouthex.png"),
    QUIT_HEX                = load_texture("res/quithex.png"),
    UNPAUSE_HEX             = load_texture("res/unpausehex.png"),

    CURTAIN                 = load_texture("res/curtain1.png"),

    -- gui stuff
    BUTTON1                 = load_texture("res/button1.png"),
    WIDER_BUTTON1           = load_texture("res/wider_button1.png"),
    TAB_ICON                = load_texture("res/tab_icon.png"),
    GUI_SLIDER              = load_texture("res/slider.png"),
    GEAR                    = load_texture("res/gear.png"),

    SELECT_BOX_ICON         = load_texture("res/select_box.png"),

    -- tower stuff
    TOWER_WALL              = load_texture("res/tower_wall.png"),
    TOWER_WALL_ICON         = load_texture("res/tower_wall_icon.png"),
    TOWER_HOWITZER          = load_texture("res/tower_howitzer.png"),
    CANNON1                 = load_texture("res/cannon1.png"),
    TOWER_HOWITZER_ICON     = load_texture("res/tower_howitzer_icon.png"),
    TOWER_REDEYE            = load_texture("res/tower_redeye.png"),
    TOWER_REDEYE_ICON       = load_texture("res/tower_redeye_icon.png"),
    TOWER_MOAT              = load_texture("res/tower_moat.png"),
    TOWER_MOAT_ICON         = load_texture("res/tower_moat_icon.png"),
    TOWER_RADAR             = load_texture("res/tower_radar.png"),
    TOWER_RADAR_ICON        = load_texture("res/tower_radar_icon.png"),
    TOWER_LIGHTHOUSE        = load_texture("res/tower_lighthouse.png"),
    TOWER_LIGHTHOUSE_ICON   = load_texture("res/tower_lighthouse_icon.png"),

    HEX_FLOWER              = load_texture("res/thing.png"),

    -- mob stuff
    MOB_BEEPER          = load_texture("res/mob_beeper.png"),
    MOB_SPOODER         = load_texture("res/mob_spooder.png"),
}

function pack_texture_into_sprite(texture, width, height, color)
    local sprite = am.sprite{
        texture = texture,
        s1 = 0, s2 = 1, t1 = 0, t2 = 1,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }

    sprite.color = color or vec4(1)
    return sprite
end

