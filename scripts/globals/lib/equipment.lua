-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Equipment = {}

function Equipment.Equip(targetObj, equipObj, equipperObj)
	if ( targetObj == nil ) then
        LuaDebugCallStack("nil targetObj provided.")
        return false
    end
    
    local equipSlot = Equipment.GetSlot(equipObj)
	
	if ( equipSlot ~= nil ) then
    
        if not( Equipment.CanEquip(targetObj, equipObj, equipperObj) ) then
            return false
        end

		local oppositeHand = nil
		if ( equipSlot == "LeftHand" ) then
			oppositeHand = "RightHand"
		elseif ( equipSlot == "RightHand" ) then
			oppositeHand = "LeftHand"
		end

		local backpackObj = Backpack.Get(targetObj)
		if ( backpackObj ~= nil or equipSlot == "Backpack" ) then
			if ( equipSlot == "Ring" ) then
				equipSlot = "Ring1"
			end

			local equippedObj = targetObj:GetEquippedObject(equipSlot)
			if ( equippedObj ~= nil and equipSlot == "Ring1" ) then
				equipSlot = "Ring2"
				equippedObj = targetObj:GetEquippedObject(equipSlot)
   			end

			if ( equippedObj ~= nil ) then
				-- dont swap for backpacks that could get wierd				
                if ( equipSlot ~= "Backpack" ) then
                    equippedObj:MoveToContainer(backpackObj, equipObj:GetLoc())
	   			else
					targetObj:SystemMessage("You are already wearing something there.","info")
					return false
				end
            end
            
			--#2HanderForceBothHands
			-- if just equipped a LeftHand or RightHand
			if ( oppositeHand ~= nil ) then
				oppositeHand = targetObj:GetEquippedObject(oppositeHand)
				-- if there's something in the other hand
				if ( oppositeHand ~= nil ) then
					local unequipOpposite = false
					-- if the other hand is a 2hander
					if ( Weapon.IsTwoHanded(Object.TemplateId(oppositeHand)) ) then
						-- allow some stuff to stay equipped with 2 handers
						if ( Weapon.CanBeEquippedWithTwoHandedWeapon(Object.TemplateId(equipObj)) ) then
							unequipOpposite = false
						else
							unequipOpposite = true
						end
					end
					-- if we are equipping a 2hander
					if ( Weapon.IsTwoHanded(Object.TemplateId(equipObj)) ) then
						-- allow some stuff to stay equipped with 2 handers
						if ( Weapon.CanBeEquippedWithTwoHandedWeapon(Object.TemplateId(oppositeHand)) ) then
							unequipOpposite = false
						else
							unequipOpposite = true
						end
					end
					if ( unequipOpposite ) then
						-- unequip other hand
                        local loc = Container.NextEmptySlot(backpackObj)
                        if ( loc == nil ) then
                            targetObj:SystemMessage("Backpack is full.", "info")
                            return false
                        end
                        oppositeHand:MoveToContainer(backpackObj, loc)
					end
				end
			end
			--#End2HanderForceBothHands

		else
			targetObj:SystemMessage("You need a backpack to swap equipment.", "info")
        end
        
	else
		targetObj:SystemMessage("You cannot equip that.", "info")
		return false
    end
    
    targetObj:EquipObject(equipObj)
    return true
end

function Equipment.Unequip(targetObj, equipObj)
	if ( targetObj == nil ) then
        LuaDebugCallStack("nil targetObj provided.")
        return false
	end

	-- check valid object
	if ( equipObj:IsEquippedOn(targetObj) ) then
		local backpackObj = Backpack.Get(targetObj)
		-- make sure we have a backpack
		if ( backpackObj ~= nil ) then
            local loc = Container.NextEmptySlot(backpackObj)
            if ( loc ~= nil ) then
                equipObj:MoveToContainer(backpackObj, loc)
                return true
            end
		end
	end

	return false
end

function Equipment.CanEquip(targetObj, equipObj, equipperObj)
    if ( targetObj ~= equipperObj ) then
        -- don't allow equipping anything but on yourself (by default)
        return false
    end
    return true
end

function Equipment.GetSlot(gameObj)
	return gameObj:GetSharedObjectProperty("EquipSlot")
end

local armorSoundParameters = {
	none = 0,
	leather = 1,
	chainmail = 2,
	plate = 3,
}

function Equipment.PlayImpactSound(target, weapon_template, weapon_table, armor_type)
	local soundParameters = {
		armor = 0 --TODO: Get the worn item's impact sound
	}
	local weaponSFX = Weapon.GetImpactSound(weapon_template, weapon_table)
	if ( weaponSFX ~= nil ) then
		target:PlayObjectSoundWithParameter("event:/weapons/"..weaponSFX.."/"..weaponSFX.."_impact", soundParameters, false)
	else
		target:PlayObjectSoundWithParameter("event:/weapons/general/general_impact", soundParameters, false)
	end
end