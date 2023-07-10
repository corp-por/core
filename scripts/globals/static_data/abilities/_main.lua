-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Abilities = {}

Abilities.Mount = {
    Effect = "Mount",
    EffectArgs = {
        SpeedModifier = 1.0,
    },
    Cooldown = TimeSpan.FromSeconds(5),
    CastTime = TimeSpan.FromSeconds(5)
}