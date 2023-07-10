-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ContainerBehavior = {}

-- default behavior for a container if not defined.
---- must exist or will cause errors in cases it would apply.
ContainerBehavior.default = {
    -- view/add/remove expect a bool return associated with the player's ability to do this action to this container.
    View = function(containerObj, playerObj) return false end,
    Add = function(containerObj, playerObj) return false end,
    Remove = function(containerObj, playerObj) return false end,
    -- this function is called when an object in the container is used
    Used = function(containerObj, playerObj) return end,
}

-- a container behavior is defined by the template

-- for example:
-- ContainerBehavior.my_custom_template = {}

require 'globals.behavior.container.bank_box'
require 'globals.behavior.container.mob_loot'
require 'globals.behavior.container.player_backpack'
require 'globals.behavior.container.vendor_backpack'