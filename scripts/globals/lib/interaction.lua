-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Interaction = {}

--- Determine if a gameObj is within a range of another gameObj
--- @param a GameObj
--- @param b GameObj
--- @param range Number (optional) defaults to server setting ObjectInteractionRange
--- @return true if within range, otherwise false
function Interaction.WithinRange(a, b, range)
    b = b:TopmostContainer() or b
    a = a:TopmostContainer() or a
    return b:GetLoc():Distance(a:GetLoc()) <= ( range or ServerSettings.Interaction.ObjectInteractionRange )
end

--- Determine if a gameObj is within a range of a location
--- @param a GameObj
--- @param targetLoc Loc
--- @param range Number (optional) defaults to server setting ObjectInteractionRange
--- @return true if within range, otherwise false
function Interaction.WithinLocRange(a, targetLoc, range)
    a = a:TopmostContainer() or a
    return targetLoc:Distance(a:GetLoc()) <= ( range or ServerSettings.Interaction.ObjectInteractionRange )
end

--- Cause mobile a to look at mobile b
--- @param a mobileObj
--- @param b mobileObj
function Interaction.LookAt(a, b)
	if ( a ~= b ) then
		Interaction.LookAtLoc(a, b:GetLoc())
	end
end

--- Cause mobile a to look at location loc
--- @param a mobileObj
--- @param loc location
--- @param aloc (options) provide for optimization
function Interaction.LookAtLoc(a, loc, aloc)
	a:SetFacing((aloc or a:GetLoc()):YAngleTo(loc))
end

--- Check if a mobile has line of sight to an object
--- @param mobileObj
--- @param targetObj
--- @return true if mobileObj has line of sight to targetObj, false otherwise
function Interaction.HasLineOfSight(mobileObj, targetObj)
	return mobileObj:HasLineOfSightToObj(targetObj, ServerSettings.Interaction.LineOfSightHeight)
end

--- Check if a mobile has line of sight to an object
--- @param mobileObj
--- @param targetLoc
--- @return true if mobileObj has line of sight to targetLoc, false otherwise
function Interaction.HasLineOfSightToLoc(mobileObj, targetLoc)
	return mobileObj:HasLineOfSightToLoc(targetLoc, ServerSettings.Interaction.LineOfSightHeight)
end

--- Attempt to equip an object into a mobile
--- @param mobileObj | The target mobile object to equip the object into
--- @param equipObj | The potential object to be equipped onto the mobile
--- @return bool | true if successful
function Interaction.TryEquip(mobileObj, equipObj)
	if ( mobileObj == nil ) then
		LuaDebugCallStack("[Interaction.TryEquip] equipObj is nil")
		return false
	end
	if ( equipObj == nil ) then
		LuaDebugCallStack("[Interaction.TryEquip] equipObj is nil")
		return false
	end
	if ( equipObj:HasObjVar("NoEquip") ) then return false end
	local equipSlot = Equipment.GetSlot(equipObj)
	if ( equipSlot ~= nil and equipSlot ~= "Backpack" ) then
		-- if its in our body then we have it equipped
		if ( Equipment.Unequip(mobileObj, equipObj) ) then			
			return true
		elseif ( equipObj:TopmostContainer() == mobileObj ) then
			Equipment.Equip(mobileObj, equipObj, mobileObj)
			return true
		end
	end
	return false
end

--- Attempt to use an object, no matter the cirumstances of target object
--- @param playerObj
--- @param targetObj
function Interaction.TryUse(playerObj, targetObj)
	if ( targetObj == playerObj ) then return end -- TODO: Handle 'using' self player

	-- validate input
	if ( targetObj and targetObj:IsValid() ) then

		-- look for an interaction range overide
		local interactionRange = Interaction.GetInteractionRange(targetObj)

		-- the the topmost container (if any)
		local topMost = targetObj:TopmostContainer()

		-- verify interaction range
		if ( topMost ~= playerObj and not Interaction.WithinRange(playerObj, topMost or targetObj, interactionRange) ) then
			playerObj:SystemMessage("Too far away.", "info")
			return
		end

		if ( topMost ~= nil ) then -- handle objects in containers
			-- prefer a mobile's backpack over the mobile itself
			topMost = Backpack.Get(topMost) or topMost
			-- defer to the container behavior
			Container.Behavior("Used", topMost, playerObj, targetObj)
		else -- handle objects in the world
			-- try to pick it up
			if not( Interaction.TryPickup(playerObj, targetObj, true) ) then
				-- failed to pick it up, if there's an interaction range, use the item in the world
				if ( interactionRange ~= nil ) then
					Interaction.Use(playerObj, targetObj)
				elseif ( targetObj:IsContainer() ) then
					-- otherwise try to view the contents of containers
					Container.TryViewContents(targetObj, playerObj)
				end
			end
		end
	end
end

--- Attempt to use a MapObj
--- @param mapObj
--- @param playerObj
--- @return true or false
function Interaction.TryUseMapObj(mapObj, playerObj)
	if ( mapObj ~= nil and mapObj.Interactable and Harvestable[mapObj.Index..""] ~= nil ) then
		return Effect.Apply(playerObj, "Harvest", {
			MapObj = mapObj
		})
	end
	return false
end


--- Get the interaction range of an object (if any) this looks for a specific defined range in properties, and if found, allow interacting with the item in the world, outside of your own container.
--- @param targetObj | Ths mobile to find the interaction range
--- @return range or nil if no range specified.
function Interaction.GetInteractionRange(targetObj)
	local templateid = Object.TemplateId(targetObj)
	if ( Template[templateid] ~= nil and Template[templateid].InteractionRange ~= nil ) then
		return Template[templateid].InteractionRange
	end
	return nil
end

--- Will 'use' an item and apply any effects or abilities, does NOT perform checks!
--- @param mobileObj | The mobile (usually a player) using the object
--- @param targetObj | The object being used
--- @param templateid
function Interaction.Use(mobileObj, targetObj)
	local templateid = Object.TemplateId(targetObj)

	-- run the onuse hook if it exists
	if ( Template[templateid] and Template[templateid].OnUse ~= nil ) then
		Template[templateid].OnUse(targetObj, mobileObj)
	end

	if ( Template[templateid] and Template[templateid].Effect ) then
		local args = Template[templateid].EffectArgs or {}
		args.Interacted = targetObj
		if ( Effect.Apply(mobileObj, Template[templateid].Effect, args) ) then
			if ( Template[templateid].Consume == true ) then
				args.Interacted = nil
				if ( Stackable.Is(templateid) ) then
					Stackable.Adjust(targetObj, -1)
				else
					targetObj:Destroy()
				end
			end
		end
	elseif ( Template[templateid] and Template[templateid].Ability ) then
		Ability.Perform(mobileObj, nil, Template[templateid].Ability, false, Template[templateid].Consume == true and targetObj or nil)
	end
end

--- Can the player pick up the specified object
--- @param playerObj
--- @param object to see if we can pick up
--- @return true if able to be picked up, false and reason string if not able to pick up
function Interaction.CanPickUp(mobileObj, targetObj)
	-- if any object is invalid, deny pickup
	if (
		not mobileObj or
		not mobileObj:IsValid() or
		not targetObj or
		not targetObj:IsValid()
	) then
		return false
	end

	-- cannot pickup mobiles
	if ( targetObj:IsMobile() ) then return false, "[$2402]" end

	-- immovable cannot be picked up by annyone, even a god
	if ( Object.Immovable(targetObj) ) then return false, "[$2402]" end

	-- if we are already carrying something, fail
	local carriedObject = mobileObj:CarriedObject()
	if ( carriedObject and carriedObject:IsValid() ) then return false, "[$3329]" end
	
	-- at this point gods are ok to pick up the item
	if ( IsGod(mobileObj) ) then return true end
	
    local topMost = targetObj:TopmostContainer() or targetObj
    
    if not( Interaction.WithinRange(mobileObj, topMost) ) then
        return false, "Too far away."
    end

	-- do we have line of sight to the object or container
	if not( Interaction.HasLineOfSight(mobileObj, topMost) ) then		
		return false, "[$3330]"
	end

	-- if in a container
	if ( topMost ~= targetObj ) then
		-- prefer a mobile's backpack over the mobile itself
		topMost = Backpack.Get(topMost) or topMost
		-- defer to container behavior
		return Container.Behavior("Remove", topMost, mobileObj) or false
	end

	return true
end

--- First check to see if we can pick it up (calls CanPickup) then perform the actual pickup
---- there exists only a TryPickup because a Pickup cannot be guaranteed, maybe the target container is full?
--- @param playerObj
--- @param object to pick up
--- @param directlyToBackpack | If true the item wont be moved into the players cursor, instead it will go into the backpack
--- @return true if picked up, false if not able to pick up
function Interaction.TryPickup(playerObj, pickedUpObject, directlyToBackpack)
	-- check to see if this object can be picked up by mobile
	local success, reason = Interaction.CanPickUp(playerObj, pickedUpObject)
	if not( success ) then
		return false, reason
	end

    if ( directlyToBackpack ~= true ) then
		local topMost = pickedUpObject:TopmostContainer()
		if ( topMost ~= nil ) then
			-- prefer a mobile's backpack over the mobile itself
			topMost = Backpack.Get(topMost) or topMost
			-- defer to the container behavior
			if not( Container.Behavior("Remove", topMost, playerObj) ) then
				return false
			end
		end
        -- pick it up into cursor
        local loc = pickedUpObject:GetLoc()
        success, reason = Container.TryAdd(playerObj, pickedUpObject, Loc(0,0,0))
		-- if it was picked up in the world
		if ( success and topMost == nil ) then
            Interaction.LookAtLoc(playerObj, loc)
            playerObj:PlayAnimation("pickup")
		end
    else
        -- move it to the backpack
        local loc = pickedUpObject:GetLoc()
        success, reason = Backpack.TryAdd(playerObj, pickedUpObject)
        if ( success ) then
            Interaction.LookAtLoc(playerObj, loc)
            playerObj:PlayAnimation("pickup")
        end
    end

    if ( success ) then
		pickedUpObject:RemoveDecay()
	else
        if ( reason ) then
            playerObj:SystemMessage(reason)
        end
        return false, reason
	end
	return true
end

--- Undo a pickup (attempt to put back whatever the player is currently 'holding' in their cursor from the place it came from)
--- @param playerObj
--- @param notInWorld when true, will not undo a pick unless that undo results into a container
function Interaction.UndoPickup(playerObj, notInWorld)
	playerObj:SendMessage("UndoPickup", notInWorld)
end

--- First check to see if we can drop then perform the actual drop
--- @param mobileObj the mobile object that is attempting the drop, normally a player
--- @param droppedObject the object that is being attempted to be dropped
--- @param dropLocation the location the item is being dropped
--- @param dropObject the object that is being dropped onto (if any)
--- @return true if picked up, false if not able to pick up
function Interaction.TryDrop(mobileObj, droppedObject, dropLocation, dropObject)
	-- Make sure this is the item the mobile is carrying
	if not( droppedObject:IsBeingCarriedBy(mobileObj) ) then
		-- something really bad happened
		DebugMessage("ERROR: Tried to drop object that is not that players carried object!")
		-- if this happened the client has some how fallen out of sync. lets try to force the client to drop it
		mobileObj:SendPickupFailed(droppedObject)
		return false
	end

	-- if we are dropping this on a mobile, change the drop object to the backpack
	-- if no backpack just drop at the feet of the mobile
	if ( dropObject and dropObject:IsMobile() ) then
		local backpackObj = Backpack.Get(mobileObj)
		if ( backpackObj ) then				
			dropObject = backpackObj
		else
			dropObject = nil
			dropLocation = mobileObj:GetLoc()
		end
	end

	-- If we are dropping onto an object
	if ( dropObject and dropObject:IsValid() ) then		
		-- check that the drop object is not too far away
		if not( Interaction.WithinRange(mobileObj, dropObject) ) then
			mobileObj:SystemMessage("[$3332]")
			return false
		end

		-- if we are dropping onto a container
		if ( dropObject:IsContainer() ) then
			local topMost = dropObject:TopmostContainer()

			-- prefer a mobile's backpack over the mobile itself
			topMost = Backpack.Get(topMost) or topMost

			-- defer to the container behavior
			if not( Container.Behavior("Add", topMost, mobileObj) ) then
				return false
			end

			-- try to perform the drop into the container
			local canHold, reason = Container.TryAdd(dropObject, droppedObject, dropLocation)
			if not( canHold ) then
				mobileObj:SystemMessage("[$3331] "..(reason or ""))
				return false
			end		
		-- try to stack onto the dropped object
		elseif ( Stackable.Combine(droppedObject, dropObject) ) then
			return true
		-- dropped object is not a container or a stackable target so we just drop it at the same location as the drop object
		else
			if not( dropLocation ) then
				dropLocation = dropObject:GetLoc()
			end

			-- if the target object is in a container, try to drop it in that container
			local dropContainer = dropObject:ContainedBy()
			if ( dropContainer ) then
				local topMost = dropContainer:TopmostContainer()
				
				-- prefer a mobile's backpack over the mobile itself
				topMost = Backpack.Get(topMost) or topMost
				
				-- defer to the container behavior
				if not( Container.Behavior("Add", topMost, mobileObj) ) then
					return false
				end

				local canHold, reason = Container.TryAdd(dropContainer, droppedObject, dropLocation)
				if not( canHold ) then
					mobileObj:SystemMessage("[$3331] "..(reason or ""))
					return false
				end		
			-- otherwise it's in the world so we can drop it there
			else
				Interaction.DropInWorld(droppedObject,dropLocation)
			end
		end
	-- not dropping on an object so just drop it in the world
	elseif ( dropLocation ~= nil ) then
		if not( Interaction.WithinLocRange(mobileObj, dropLocation) ) then		
			mobileObj:SystemMessage("Cannot reach that.")
			return false
		end

		Interaction.DropInWorld(mobileObj,droppedObject,dropLocation)
	end
	return true
end

--- Mobile drop object into the world (handles decay and animations)
--- @param mobileObj
--- @param droppedObject object to drop
--- @param dropLocation location in world to drop
function Interaction.DropInWorld(mobileObj,droppedObject,dropLocation)
    Interaction.LookAtLoc(mobileObj, dropLocation)
	mobileObj:PlayAnimation("drop")
    droppedObject:SetWorldPosition(dropLocation)
    Object.Decay(droppedObject)
end