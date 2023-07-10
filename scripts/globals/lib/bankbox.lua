-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

BankBox = {}

--- Initalize a player's bankbox (creating one if they don't have one yet)
-- @param playerObj MobileObj
-- @param cb Function callback function to perform after the bankbox is guaranteed to be on the mobile
function BankBox.Init(playerObj, cb)
    local bankbox = BankBox.Get(playerObj)
    if ( bankbox ) then
        if ( cb ) then cb(bankbox) end
    else
        Create.Equipped("bank_box", playerObj, function(bankbox)
            if ( cb ) then cb(bankbox) end
        end)
    end
end

--- Get the equipped bank container of a mobileObj
-- @param mobileObj MobileObj
-- @return bankbox GameObj the bankbox worn by this mobile (if any)
function BankBox.Get(mobileObj)
    return mobileObj:GetEquippedObject("Bank")
end

--- Try to add an object to the bankbox of a mobile
-- @param mobileObj MobileObj
-- @param addingObject GameObj
-- @param addingLocation Loc (optional) slot to prefer when adding to the bankbox
function BankBox.TryAdd(mobileObj, addingObject, addingLocation)
    local bankbox = BankBox.Get(mobileObj)
    if ( bankbox ) then
        if not( Container.Behavior("Add", bankbox, mobileObj) ) then
            return false
        end
        return Container.TryAdd(bankbox, addingObject, addingLocation)
    end
    return false, "No bankbox"
end

-- Attempt to view the contents of a player's own bank
function BankBox.TryViewContents(playerObj)
    local bankbox = BankBox.Get(playerObj)
    if ( bankbox ~= nil ) then
        Container.TryViewContents(bankbox, playerObj)
    end
end