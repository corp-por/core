-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- Settings related to artifical intelligence / npc brains
ServerSettings.AI = {

    -- defaults to set if they are not provided
    Default = {
        MinDamage = 1,
        MaxDamage = 2,

        RespawnTimer = TimeSpan.FromSeconds(30),
    }
}