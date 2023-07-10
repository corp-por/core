-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Backpack = {}

--- Initalize a player's backpack (creating one if they don't have one yet)
-- @param playerObj MobileObj
-- @param cb Function callback function to perform after the backpack is guaranteed to be on the mobile
function Backpack.Init(playerObj, cb)
    local backpack = Backpack.Get(playerObj)
    if ( backpack ) then
        if ( cb ) then cb(backpack) end
    else
        Create.Equipped("player_backpack", playerObj, function(backpack)
            if ( cb ) then cb(backpack) end
        end)
    end
end

--- Get the equipped backpack of a mobileObj
-- @param mobileObj MobileObj
-- @return backpack GameObj the backpack worn by this mobile (if any)
function Backpack.Get(mobileObj)
    return mobileObj:GetEquippedObject("Backpack")
end

--- Try to add an object to the backpack of a mobile
-- @param mobileObj MobileObj
-- @param addingObj GameObj
-- @param addingLocation Loc (optional) slot to prefer when adding to the backpack
function Backpack.TryAdd(mobileObj, addingObj, addingLocation)
    local backpack = Backpack.Get(mobileObj)
    if ( backpack ) then
        if not( Container.Behavior("Add", backpack, mobileObj) ) then
            return false
        end

        return Container.TryAdd(backpack, addingObj, addingLocation)
    end
    return false, "No backpack"
end