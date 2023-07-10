-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- Cannot remove a state after FSM has started, will break. So this is a close second
States.EmptyFalse = {
    Name = "EmptyFalse",
    ShouldRun = function(self)
        return false
    end,
    Run = function(self)

    end,
}