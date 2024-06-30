-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



local player_vendor = this:HasModule("brain_vendor_player")

-- create the vendor's inventory object if it doesn't exist yet
if ( Backpack.Get(this) == nil ) then

    local template = "vendor_backpack"
    if ( player_vendor == true ) then
        template = "player_" .. template
    end
    
    local templateData = GetTemplateData(template)
    templateData.Name = this:GetName()

    if not( templateData.SharedProperties ) then
		templateData.SharedProperties = {}
	end

    -- set a custom capacity for this temporary loot container (minimum of 5 to not look too odd)
    templateData.SharedProperties.Capacity = 5

    Create.Custom.InContainer(template, templateData, this, nil, function(obj)
        if ( obj ~= nil ) then
            this:EquipObject(obj)
        end
    end)
end

RegisterEventHandler(EventType.Message, "Purchase", function(user, item)
    local inventory = Backpack.Get(this)
    local objs = inventory:GetContainedObjects() or {}
    for i=1,#objs do
        if ( item.Id == objs[i].Id ) then
            local price = Vendor.GetPrice(this, item)
            if ( Gold.Has(user, price) ) then
                if ( Gold.Transfer(user, this, price) ) then
                    if ( Backpack.TryAdd(user, item) ) then
                        Vendor.OnPurchase(item)
                        if ( player_vendor ) then
                            Vendor.Player.RemoveObjectPrice(this, item)
                        end
                        Vendor.NPC.Restock(this)
                        --REPLACE WITH ANIMATIONS
                        this:NpcSpeechToUser("Thank you for your patronage!", user)
                    else
                        this:NpcSpeechToUser("I could not move the item to your inventory, is your bag full?", user)
                    end
                else
                    this:NpcSpeechToUser("Failed to transfer the gold from you to me.", user)
                end
            else
                this:NpcSpeechToUser("You do not have enough gold.", user)
            end
        end
    end
end)

-- meant to be overridden
function HandleResponse(response)

end

RegisterEventHandler(EventType.Message, "Response", function(response)
    HandleResponse(response)
end)
