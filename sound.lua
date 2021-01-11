
SOUNDS = {
    -- sfxr_synth seeds
    EXPLOSION1      = 49179102, -- this slowed sounds metal as fuck
    EXPLOSION2      = 19725402,
    EXPLOSION3      = 69338002,
    HIT1            = 25811004,
    LASER1          = 79859301,
    LASER2          = 86914201,
    PUSH1           = 30455908,
    SELECT1         = 76036806,
    PUSH2           = 57563308,
    BIRD1           = 50838307,
    RANDOM1         = 85363309,
    RANDOM2         = 15482409,
    RANDOM3         = 58658009,
    RANDOM4         = 89884209,
    RANDOM5         = 36680709,

    -- audio buffers
    TRACK1 = am.track(am.load_audio("res/track1.ogg"), true, 1, 0.1)
}

-- play a sound with variable pitch
function vplay_sound(seed)
    return am.play(am.sfxr_synth(seed), false, (math.random() + 0.5)/2)
end

function play_sound(seed)
    return am.play(am.sfxr_synth(seed), false)
end

