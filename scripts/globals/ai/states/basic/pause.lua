-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Pause = {
    Name = "Pause",
    ShouldRun = function(self)
        return ( self.Paused == true )
    end,
    Run = function(self)
        -- do nothing
        return true -- stop all timers
    end,
}