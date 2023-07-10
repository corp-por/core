-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Death = {
    Name = "Death",
    Init = function(self)
        RegisterEventHandler(EventType.Message, "Resurrected", function()
            -- remove decay
            self.Parent:RemoveDecay()
            -- resume on a resurrect
            self.Schedule()
        end)
    end,
    ShouldRun = function(self)
        return Death.Active(self.Parent)
    end,
    Run = function(self)
        -- begin decaying
        self.Parent:ScheduleDecay(TimeSpan.FromSeconds(60))
        -- clear target
        self.SetTarget(nil)
        -- disable as a nav agent (stop blocking movement for other agents)
        self.Parent:DisableNavigationAgent()
        -- stop all ai while dead.
        return true
    end,
    ExitState = function(self)
        self.Parent:EnableNavigationAgent()
    end,

    -- these are called if state is active or not
    OnPause = function(self)
        self.Parent:DisableNavigationAgent()
    end,
    OnResume = function(self)
        -- when resuming from a pause, we only want to re-enable navigation agent if we shouldn't run death
        if not States.Death.ShouldRun(self) then
            self.Parent:EnableNavigationAgent()
        end
    end,
}