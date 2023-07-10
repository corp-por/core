-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Damage = {}

Damage.Type = {
    True = {}, -- nothing (should) lower this type
    Bashing = {
        Physical = true,
    },
    Slashing = {
        Physical = true,
    },
    Piercing = {
        Physical = true,
    },
    Fire = {
        Elemental = true,
    },
    Frost = {
        Elemental = true,
    }
}