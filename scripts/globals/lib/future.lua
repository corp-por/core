-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD


--- Purpose of Future is to schedule a task into the future, but in an effecient way to handle many vs using many many timers
---- For example, to handle potentially thousands of trees that need to be respawned.
---- These tasks are not persistent either and will clear when server restarts, thus mapobjs they update shouldn't be permanent changes


Future = {}

_G._scheduledTasks = {}
local _tasksPerPulse = 25

function Future.Init(gameObj)
    RegisterEventHandler(EventType.Timer, "FutureTasksRun", function()
        Future.RunTasks()
    end)
end

function Future.RunTasks()
    local now = DateTime.UtcNow
    local i = #_G._scheduledTasks
    local t = 0
    while ( i > 0 and t <= _tasksPerPulse and now >= _G._scheduledTasks[i][1] ) do
        _G._scheduledTasks[i][3](_G._scheduledTasks[i][2])
        _G._scheduledTasks[i] = nil
        i = i - 1
        t = t + 1
    end
    if ( i > 0 ) then
        _G.Instance:ScheduleTimerDelay(_G._scheduledTasks[i][1] - now, "FutureTasksRun")
    end
end

--- The reasoning behind storing and passing in the parameters (data) is to prevent lua garbage collection from clearing any variables we are passing to the task
function Future.ScheduleTask(timespan, data, task)

    local timeoftask = DateTime.UtcNow + timespan

    -- first find where in line it should be, while moving everything down a peg
    local j = #_G._scheduledTasks
    while ( j > 0 ) do
        if ( timeoftask > _G._scheduledTasks[j][1] ) then
            _G._scheduledTasks[j + 1] = _G._scheduledTasks[j]
            j = j - 1
        else
            break
        end
    end

    -- going to add a new task at the bottom
    if ( j == #_G._scheduledTasks ) then
        -- this task will be more recent than all other tasks already scheduled, so change the timer
        _G.Instance:ScheduleTimerDelay(timespan, "FutureTasksRun")
    end

    -- then add the new task to its place in line
    _G._scheduledTasks[j + 1] = {timeoftask, data, task}
end