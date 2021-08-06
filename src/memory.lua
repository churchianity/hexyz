
local garbage_collector_cycle_timing_history = {}
local garbage_collector_average_cycle_time = 0
function run_garbage_collector_cycle()
    local time, result = fprofile(collectgarbage, "collect")

    table.insert(garbage_collector_cycle_timing_history, time)
    -- re-calc average gc timing
    local total = 0
    for _,v in pairs(garbage_collector_cycle_timing_history) do
        total = total + v
    end
    garbage_collector_average_cycle_time = total / #garbage_collector_cycle_timing_history
end

function check_if_can_collect_garbage_for_free(frame_start_time, min_goal_fps)
    -- often this will be polled at the end of a frame to see if we're running fast or slow,
    -- and if we have some time to kill before the start of the next frame, we could maybe run gc.
    --
    if (am.current_time() - frame_start_time) < (1 / min_fps + garbage_collector_average_cycle_time) then
        run_garbage_collector_cycle()
    end
end

