-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ContainerBehavior.player_backpack = {
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
        if ( usedObj:IsContainer() ) then
            -- attempt to view inside it
            Container.TryViewContents(usedObj, playerObj)
        else
            -- attempt to equip used obj
            if not( Interaction.TryEquip(playerObj, usedObj) ) then
                -- failed to equip, perform the use of item
                Interaction.Use(playerObj, usedObj)
            end
        end
    end
}

-- useful for testing default behavior
--ContainerBehavior.player_backpack = ContainerBehavior.default