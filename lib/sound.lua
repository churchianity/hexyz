
SOUNDS = {
    -- sfxr_synth seeds
    EXPLOSION1      = 49179102, -- this slowed sounds metal as fuck
    EXPLOSION2      = 19725402,
    EXPLOSION3      = 69338002,
    EXPLOSION4      = 92224102,
    COIN1           = 10262800,
    HIT1            = 39920504,
    LASER1          = 79859301,
    LASER2          = 86914201,
    PUSH1           = 30455908,
    SELECT1         = 76036806,
    PUSH2           = 57563308,
    BIRD1           = 50838307,
    BIRD2           = 16549407,
    RANDOM1         = 85363309,
    RANDOM2         = 15482409,
    RANDOM3         = 58658009,
    RANDOM4         = 89884209,
    RANDOM5         = 36680709,

    -- audio buffers
    MAIN_THEME = am.track(am.load_audio("res/ogg/main_theme.ogg"), true, 1, SETTINGS.music_volume)
}

CURRENT_TRACKS = {}
function update_music_volume(volume)
    for _,track in pairs(CURRENT_TRACKS) do
        track.volume = math.clamp(volume, 0, 1)
    end
end

-- play sound effect with variable pitch
function vplay_sfx(sound, pitch_range)
    local pitch = (math.random() + 0.5)/(pitch_range and 1/pitch_range or 2)
    win.scene:action(am.play(sound, false, pitch, SETTINGS.sfx_volume))
end

function play_sfx(sound)
    win.scene:action(am.play(sound, false, 1, SETTINGS.sfx_volume))
end

function stop_track()

end

function play_track(track, do_loop)
    table.insert(CURRENT_TRACKS, track)
    win.scene:action(am.play(track, do_loop or true))
end

