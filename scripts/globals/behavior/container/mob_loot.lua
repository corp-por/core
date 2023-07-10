-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ContainerBehavior.mob_loot = {
    View = function(containerObj, playerObj)
        return Death.Active(containerObj:TopmostContainer())
    end,
    Remove = function(containerObj, playerObj)
        return Death.Active(containerObj:TopmostContainer())
    end,
    Add = function() return false end,
    Used = function(containerObj, playerObj, usedObj)
        if ( Death.Active(containerObj:TopmostContainer()) ) then
            Backpack.TryAdd(playerObj, usedObj)
        end
    end
}