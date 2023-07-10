-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ContainerBehavior.bank_box = {
    --TODO: To officially prevent accessing bank containers (from hackers) a mobile effect will be necessary,
        --- check the existance of the mobile effect to allow view/add/remove. In mobile effect constantly check for banker that started it, if too far away, remove effect.
    View = function(containerObj, playerObj)
        return containerObj:TopmostContainer() == playerObj
    end,
    Add = function(containerObj, playerObj)
        return containerObj:TopmostContainer() == playerObj
    end,
    Remove = function(containerObj, playerObj)
        return containerObj:TopmostContainer() == playerObj
    end,
    Used = function(containerObj, playerObj, usedObj)
        -- move to backpack
        Backpack.TryAdd(playerObj, usedObj)
    end
}