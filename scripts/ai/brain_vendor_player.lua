-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

LoadDNA(this, Template[Object.TemplateId(this)])

require 'ai.brain_vendor'

local droppedItem = nil
local droppedSlot = nil
local waitingOnResponseFrom = nil

-- handle something dropped onto my container
RegisterEventHandler(EventType.Message, "DropItemVendor", function(playerObj, droppedObj, droppedLoc)
    if ( Vendor.Player.HasControl(playerObj, this) ) then
        droppedItem = droppedObj
        droppedSlot = droppedLoc
        waitingOnResponseFrom = playerObj
        Var.Set(playerObj, "VendorAwaitingResponse", this)
        this:NpcSpeechToUser("How much should I charge for this item?", playerObj)
        this:ScheduleTimerDelay(TimeSpan.FromSeconds(10), "ResponseTimeout")
    else
        this:NpcSpeechToUser("I am not equipped yet for purchases, my appologies.", playerObj)
    end
end)

RegisterEventHandler(EventType.Timer, "ResponseTimeout", function()
    droppedItem = nil
    droppedSlot = nil
    waitingOnResponseFrom = nil
end)


HandleResponse = function(response)
    this:RemoveTimer("ResponseTimeout")

    if ( waitingOnResponseFrom and waitingOnResponseFrom:IsValid() ) then
        if ( droppedItem and droppedItem:IsValid() ) then
            local cost = math.floor(tonumber(response))
            if ( cost <= 0 ) then
                this:NpcSpeechToUser("Nevermind then", waitingOnResponseFrom)
            else
                this:NpcSpeechToUser(string.format("I will put this up for sale and ask %s gold.", cost), waitingOnResponseFrom)
                droppedItem:MoveToContainer(this:GetObjVar("VendorInventory"),droppedSlot)
                Vendor.Player.SetObjectPrice(this, droppedItem, cost)
                SetTooltipEntry(droppedItem,"price","\n[E5C233]"..price.." Gold",-10000)
            end

            droppedItem = nil
            droppedSlot = nil
        end
    end

    waitingOnResponseFrom = nil

end
