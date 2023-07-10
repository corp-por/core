-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- this is to replace wander as the least-priority state so that leashing will exit state
States.Empty = {
    Name = "Empty",
    ShouldRun = function(self)
        return true
    end,
    Run = function(self)

    end,
}