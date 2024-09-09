-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD

-- rocks
Harvestable["135"] = {
    Colors = {}
}

Harvestable["135"].Colors[Color.Value.Iron] = {
    Name = "Iron Ore",
    Reward = "resource_iron_ore",
    Respawn = TimeSpan.FromSeconds(15),
    Tool = "tool_pickaxe"
}