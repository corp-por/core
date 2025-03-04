-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Container = {}

---- Run a container behavior by name. This is governed by the container behavior data under global table ContainerBehavior
---- The idea is, the topmost container is always used for all container inside (for mobiles, the backpack should be prefered over the mobile itself)
--- @param name | View, Add, Remove are options
--- @param containerObj | container being added to
--- @param mobileObj | mobile/player doing the adding
--- @return bool
function Container.Behavior(name, containerObj, mobileObj, ...)
    local behavior = ContainerBehavior[Object.TemplateId(containerObj)]
    if ( behavior == nil or behavior[name] == nil ) then
        behavior = ContainerBehavior.default
    end
    return behavior[name](containerObj, mobileObj, ...)
end

--- Get/Set a containers capacity
--- @param containerObj | Container gameObj to perform operation on
--- @param optionalNewAmount | Optional, if provided will set the new value
--- @return number
function Container.Capacity(containerObj, optionalNewAmount)
    if ( containerObj == nil ) then
        LuaDebugCallStack("[Container.Capacity] nil containerObj provided")
        return nil
    end
    if ( optionalNewAmount ~= nil ) then
        containerObj:SetSharedObjectProperty("Capacity", optionalNewAmount)
        return optionalNewAmount
    else
        return containerObj:GetSharedObjectProperty("Capacity") or 5
    end
end

function Container.Contents(containerObj)
    if ( containerObj == nil ) then
        LuaDebugCallStack("[Container.NextEmptySlot] nil containerObj provided")
        return nil
    end
    return containerObj:GetContainedObjects()
end

local frameOffsets = {}
function Container.NextEmptySlot(containerObj)
    if ( containerObj == nil ) then
        LuaDebugCallStack("[Container.NextEmptySlot] nil containerObj provided")
        return nil
    end

    -- sometimes this is called multiple times for the same containerObj in the same server frame,
        -- this hack fixes that
    local offset = 0
    local frameTime = ObjectFrameTimeMs()
    if ( frameOffsets[containerObj] ) then	
        if ( frameTime == frameOffsets[containerObj][1] ) then		
            offset = frameOffsets[containerObj][2] + 1
            frameOffsets[containerObj][2] = offset
        else
            frameOffsets[containerObj] = { frameTime, 0 }
        end
    else
        frameOffsets[containerObj] = { frameTime, 0 }
    end

    -- first loop all contents of a container
	local contents = Container.Contents(containerObj)
    local dropLoc = Loc(offset,0,0)
    local highestSlot = 0
    local slotUsed = {}
	if ( #contents > 0 ) then
		for i=1,#contents do
			local slot = math.floor(contents[i]:GetLoc().X)
			slotUsed[slot] = true
			if ( slot > highestSlot ) then
				highestSlot = slot
			end
        end
    end

    -- then find the first unused slot
    for j=0,offset do
        for i=0,(highestSlot+1+offset) do
            if not( slotUsed[i] ) then
                if ( j < offset ) then
                    slotUsed[i] = true
                else
                    dropLoc.X = i						
                end

                break
            end
        end
    end

    if ( dropLoc.X >= Container.Capacity(containerObj) ) then
        return nil
    end

    return dropLoc
end

function Container.GetObjAtSlot(containerObj, slotLocation)
    local contents = Container.Contents(containerObj)
    local slotIndex = math.floor(slotLocation.X)
    for i=1,#contents do
        local slot = math.floor(contents[i]:GetLoc().X)
        if ( slot == slotIndex ) then
            return contents[i]
        end
    end
end

---- Attempts to put an object into a container, does not perform container behavior checks, purpose is to enforce limits
--- @param containerObj
--- @param addingObj
--- @param addingLocation
--- @return bool,errorMsg
function Container.TryAdd(containerObj, addingObj, addingLocation)
    if ( containerObj == nil ) then
        LuaDebugCallStack("[Container.TryAdd] nil containerObj provided")
        return false, "Unknown"
    end

    -- if it's gold, destroy the item and add it to gold total
    if ( Object.TemplateId(addingObj) == "gold" ) then
        local topMost = containerObj:TopmostContainer()
        if ( IsPlayerCharacter(topMost) ) then
            local total = Stackable.GetCount(addingObj)
            if ( total > 0 ) then
                Gold.Create(topMost, total)
            end
            addingObj:Destroy()
            return true
        end
    end

	-- cant create recursive container loops (drop onto self)
	if ( addingObj == containerObj or containerObj:IsContainedBy(addingObj) ) then
		return false,"[$3331]"
    end

	-- make sure it does not put the container over capacity (capacity does not count items in stacks)
	if not( containerObj:CanHold(addingObj) ) then
		return false,"[$3334]"
	end
    
    if not( addingLocation ) then
        addingLocation = Container.NextEmptySlot(containerObj)
        if not( addingLocation ) then return false,"[$3334]" end
    end

    return addingObj:MoveToContainer(containerObj, addingLocation)
end

function Container.TryViewContents(containerObj, playerObj)
    -- prefer the mobile's backpack over the mobile itself
    containerObj = Backpack.Get(containerObj) or containerObj
    if ( Container.Behavior("View", containerObj, playerObj) ) then
        Container.ViewContents(containerObj, playerObj)
    end
end

function Container.ViewContents(containerObj, playerObj)
	if not( containerObj ) then
		LuaDebugCallStack("[ViewContainerContents] ERROR: invalid containerObj")
		return
    end

    containerObj:SendOpenContainer(playerObj, ServerSettings.Interaction.ObjectInteractionRange)
end