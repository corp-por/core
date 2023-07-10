-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- GameObj Extensions: Player Objects
-- @module globals.helpers.player_objects

--- Does the player have god access level or above
-- @param playerObj
-- @return true if god level or above
function IsGod(playerObj)
	return playerObj:HasAccessLevel(AccessLevel.God)
end

--- Does the player have demigod access level or above
-- @param playerObj
-- @return true if demigod level or above
function IsDemiGod(playerObj)
	return playerObj:HasAccessLevel(AccessLevel.DemiGod)
end

--- Does the player have immortal access level or above
-- @param playerObj
-- @return true if immortal level or above
function IsImmortal(playerObj)
	return playerObj:HasAccessLevel(AccessLevel.Immortal)
end

--- Perform character delete.
-- Does not perform user confirmation, check must be done prior
-- @param playerObj
function DeleteChar(playerObj)
	if not(playerObj:IsPlayer()) then
		return
	end

	local clusterController = GetClusterController()
	clusterController:SendMessage("UserLogout", playerObj);

    playerObj:DeleteCharacter()
end


--- Determine if a gameObj has player module or user attached
-- @param target(gameObj)
-- @return true or false
function IsPlayerCharacter(target)
	if not( target ) then
		LuaDebugCallStack("[IsPlayerCharacter] target not provided.")
		return false
	end
	if not( target:IsValid() ) then
		LuaDebugCallStack("[IsPlayerCharacter] invalid target provided.")
		return false
	end
	
    return target:IsPlayer() or target:HasModule("player")
end

--- Determine if a gameObj has player module, user attached, or controlled by the former, or is a player corpse
-- @param target(gameObj)
-- @return true or false
function IsPlayerObject(objRef)
	if not( objRef ) then
		LuaDebugCallStack("[IsPlayerObject] objRef not provided.")
		return false
	end
	if not( objRef:IsValid() ) then
		LuaDebugCallStack("[IsPlayerObject] invalid objRef provided.")
		return false
	end

	local controller = Var.Get(objects, "controller")
	if ( controller and controller:IsValid() ) then
		objRef = controller
	end

	-- player corpses are player objects.
    if ( IsPlayerCorpse(objRef) ) then return true end
    
    return IsPlayerCharacter(objRef)
end

--- Determine if a gameObj is a player corpse via the Template Id
-- @param target(gameObj)
-- @return true or false
function IsPlayerCorpse(target)
	if ( target == nil ) then
		LuaDebugCallStack("[IsPlayerCorpse] nil target provided.")
		return false
	end
	return Object.Template(target) == "player_corpse"
end