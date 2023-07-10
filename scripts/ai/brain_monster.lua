-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'base.mobile'

this:SetMobileType("Monster")

local fsm = FSM(this, {
    States.Respawn,
    --States.Flee,
    States.Attack,
    States.Leash,
    States.Aggro,
    States.Fight,
    States.Wander,
})

fsm.Start()