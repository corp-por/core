-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ContainerBehavior.vendor_backpack = {
    View = function() return true end,
    Remove = function() return false end,
    Add = function() return false end,
    Used = function(containerObj, playerObj, usedObj)
        local vendor = containerObj:TopmostContainer()
        vendor:SendMessage("Purchase", playerObj, usedObj)
    end
}