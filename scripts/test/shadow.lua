-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

if (initializer == nil or initializer.TargetId == nil) then
    CallFunctionDelayed(TimeSpan.FromMilliseconds(250), function()
        this:NpcSpeech("No ID provided to shadow! SELF DESTRUCTING IN 5")
    end)
    CallFunctionDelayed(TimeSpan.FromSeconds(5), function()
        this:Destroy()
    end)
    return
end

local g = GameObj(initializer.TargetId)

RegisterEventHandler(EventType.Timer, "Shadow", function()
    this:SetWorldPosition(g:GetLoc())
    this:ScheduleTimerDelay(TimeSpan.FromMilliseconds(1), "Shadow")
end)

this:FireTimer("Shadow")