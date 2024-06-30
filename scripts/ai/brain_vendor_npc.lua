-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

LoadDNA(this, Template[Object.TemplateId(this)])

require 'ai.brain_vendor'

--[[local equipment
if ( initializer ~= nil ) then
    equipment = initializer.Equipment
else
    -- TODO: Random clothing
    equipment = {
        'equipment_wizard_hat',
        'equipment_hide_legs'
    }
end

if ( not this:HasObjVar("CreatedDefaultEquipment") ) then
    for i=1,#equipment do
        Create.Equipped(equipment[i], this, function(obj)
            obj:SetObjVar("NoLoot", true)
            obj:SetObjVar("Default", true)
        end)
    end
    this:SetObjVar("CreatedDefaultEquipment", true)
end]]

RegisterEventHandler(EventType.Timer, "Restock", function()
    Vendor.NPC.Restock(this)
end)

-- if you try to create it instantly it doesn't show in container window -KH
--- (plus this can be later used to stagger re-stock timers to prevent them all hitting at once)
this:ScheduleTimerDelay(TimeSpan.FromMilliseconds(2500), "Restock")

