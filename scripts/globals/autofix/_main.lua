-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


AutoFixes = {}

-- This relies on the table size and ordering, never delete/reorder anything required below!!

--require 'globals.autofix.1_karma_reset'

function DoPlayerAutoFix(player)
    if ( player and player:IsValid() ) then
        local lastFix = player:GetObjVar("LastAutoFix") or 0
        while ( lastFix < #AutoFixes ) do
            lastFix = lastFix + 1
            if ( AutoFixes[lastFix] and AutoFixes[lastFix].Player ) then
                AutoFixes[lastFix].Player(player)
            end
            player:SetObjVar("LastAutoFix", lastFix)
        end
    end
end

function DoWorldAutoFix(clusterController)
    if ( clusterController and clusterController:IsValid() ) then
        local lastFix = clusterController:GetObjVar("LastAutoFix") or 0
        while ( lastFix < #AutoFixes ) do
            lastFix = lastFix + 1
            if ( AutoFixes[lastFix] and AutoFixes[lastFix].World ) then
                DebugMessage("Applying World Autofix #", lastFix)
                AutoFixes[lastFix].World(clusterController)
            end
            clusterController:SetObjVar("LastAutoFix", lastFix)
        end
    end
end

function AutoFixReplaceItem(item, template, cb)
    local containedBy = item:ContainedBy()
    local loc = item:GetLoc()
    if ( containedBy ) then
        local locDown = false
        local controller = nil
        local topmost = containedBy:TopmostContainer() or containedBy
        if not(topmost:IsPlayer()) then 
            local topLoc = topmost:GetLoc()
            controller = Plot.GetAtLoc(topLoc)
            locDown = (controller and controller:IsValid()) 
        end

        if(item:IsEquipped()) then
            Create.Equipped(template, containedBy)
        else
            -- replace in container, easy peasy.
            Create.InContainer(template, containedBy, loc, function(itm) 
                if(locDown) then
                    itm:SetObjVar("LockedDown",true)
                    itm:SetObjVar("NoReset",true)
                    itm:SetObjVar("PlotController", controller)
                    SetTooltipEntry(itm,"locked_down","Locked Down",98)
                    
                    local house = Plot.GetHouseAt(controller, loc, false, true) -- checking roof bounds
                    if ( house ) then
                        itm:SetObjVar("PlotHouse", house)
                    end
                    
                    if ( itm:DecayScheduled() ) then
                        itm:RemoveDecay()
                    end
                end
                if(cb) then cb(itm) end 
            end)
        end
    else
        -- replace when locked down, little more difficult.
        local controller = Plot.GetAtLoc(loc)
        if ( controller and controller:IsValid() ) then
            Create.AtLoc(template, loc, function(itm)
                itm:SetObjVar("LockedDown",true)
                itm:SetObjVar("NoReset",true)
                itm:SetObjVar("PlotController", controller)
                SetTooltipEntry(itm,"locked_down","Locked Down",98)
                
                local house = Plot.GetHouseAt(controller, loc, false, true) -- checking roof bounds
                if ( house ) then
                    itm:SetObjVar("PlotHouse", house)
                end
                
                if ( itm:DecayScheduled() ) then
                    itm:RemoveDecay()
                end
                if ( cb ) then cb(itm) end
            end)
        else
            if ( cb ) then cb(nil) end
        end
    end
    item:Destroy()
end