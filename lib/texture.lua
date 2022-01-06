
local IMG_FILE_PREFIX = "res/img/"

local function load_texture(filepath)
    local path = IMG_FILE_PREFIX .. filepath
    local status, texture = pcall(am.texture2d, path)

    if status then
        return texture
    else
        log("failed to load texture at path: " .. path)
        return am.texture2d(IMG_FILE_PREFIX .. "bagel.jpg")
    end
end

TEXTURES = {
    -- note that in amulet, if you prefix paths with './', they fail to be found in the exported data.pak
    WHITE                   = load_texture("white-texture.png"),
    LOGO                    = load_texture("logo.png"),
    GEM1                    = load_texture("gem1.png"),

    SHADED_HEX              = load_texture("shaded_hex.png"),
    NEW_GAME_HEX            = load_texture("newgamehex.png"),
    SAVE_GAME_HEX           = load_texture("savegamehex.png"),
    LOAD_GAME_HEX           = load_texture("loadgamehex.png"),
    SETTINGS_HEX            = load_texture("settingshex.png"),
    MAP_EDITOR_HEX          = load_texture("mapeditorhex.png"),
    ABOUT_HEX               = load_texture("abouthex.png"),
    QUIT_HEX                = load_texture("quithex.png"),
    UNPAUSE_HEX             = load_texture("unpausehex.png"),
    MAIN_MENU_HEX           = load_texture("mainmenuhex.png"),

    CURTAIN                 = load_texture("curtain1.png"),

    SOUND_ON1               = load_texture("sound-on.png"),
    SOUND_OFF               = load_texture("sound-off.png"),

    -- gui stuff
    BUTTON1                 = load_texture("button1.png"),
    WIDER_BUTTON1           = load_texture("wider_button1.png"),
    GEAR                    = load_texture("gear.png"),

    SELECT_BOX              = load_texture("select_box.png"),

    -- tower stuff
    TOWER_WALL              = load_texture("tower_wall.png"),
    TOWER_WALL_ICON         = load_texture("tower_wall_icon.png"),
    TOWER_GATTLER           = load_texture("tower_gattler.png"),
    TOWER_GATTLER_ICON      = load_texture("tower_gattler_icon.png"),
    TOWER_HOWITZER          = load_texture("tower_howitzer.png"),
    TOWER_HOWITZER_ICON     = load_texture("tower_howitzer_icon.png"),
    TOWER_REDEYE            = load_texture("tower_redeye.png"),
    TOWER_REDEYE_ICON       = load_texture("tower_redeye_icon.png"),
    TOWER_MOAT              = load_texture("tower_moat.png"),
    TOWER_MOAT_ICON         = load_texture("tower_moat_icon.png"),
    TOWER_RADAR             = load_texture("tower_radar.png"),
    TOWER_RADAR_ICON        = load_texture("tower_radar_icon.png"),
    TOWER_LIGHTHOUSE        = load_texture("tower_lighthouse.png"),
    TOWER_LIGHTHOUSE_ICON   = load_texture("tower_lighthouse_icon.png"),

    -- mob stuff
    MOB_BEEPER              = load_texture("mob_beeper.png"),
    MOB_SPOODER             = load_texture("mob_spooder.png"),
    MOB_VELKOOZ             = load_texture("mob_velkooz.png"),
    MOB_VELKOOZ1            = load_texture("mob_velkooz1.png"),
    MOB_VELKOOZ2            = load_texture("mob_velkooz2.png"),
    MOB_VELKOOZ3            = load_texture("mob_velkooz3.png"),
}

function pack_texture_into_sprite(
    texture,
    width,
    height,
    color,
    s1,
    s2,
    t1,
    t2
)
    local width, height = width or texture.width, height or texture.height

    local sprite = am.sprite{
        texture = texture,
        s1 = s1 or 0, s2 = s2 or 1, t1 = t1 or 0, t2 = t2 or 1,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }

    if color then sprite.color = color end

    return sprite
end

function update_sprite(sprite, texture, width, height, s1, t1, s2, t2)
    local s1, t1, s2, t2 = s1 or 0, t1 or 0, s2 or 1, t2 or 1
    local width, height = width or texture.width, height or texture.height

    sprite.source = {
        texture = texture,
        s1 = s1, t1 = t1, s2 = s2, t2 = t2,
        x1 = 0, x2 = width, width = width,
        y1 = 0, y2 = height, height = height
    }
end

