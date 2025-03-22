-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- This module defines functions that are called directly from Engine
-- @module globals.engine_callbacks

--- Return a list full of MapObjTypes, telling client a player can interact with them (right click) and a use command will be sent to server.
-- Requires a server restart to reflect changes.
InteractableMapObjTypes = {MapObjType.Tree, MapObjType.Rock}
function GetInteractableMapObjTypes()
	return InteractableMapObjTypes
end

--- Returns the list of seed groups that should be loaded when the world is reset. <br><br>
-- This allows modders to load custom seed object groups based on the region address
-- For example you could use the same dungeon map to create two unique dungeons by
-- having different seed objects for each by region address.
-- This function can be overridden to have special rules based on region address
-- The default implementation is to return all seed groups for the current map that have exclude set to false
-- @return array Returns the array of seed groups to load on world reset
function GetInitialSeedGroups()		
	-- no special rulse so just return all groups that are not excluded for this map
	return GetAllSeedGroups("All",false)
end

--- Returns the initial location for a player object when created on this server region.
-- This allows you to pick different locations based on certain circumstances.
-- @return loc location to spawn player
function GetSpawnPosition(playerObj)
	local loc = nil
	local spawnPositions = FindObjects(SearchTemplate("new_player_spawn"),GameObj(0))
	if ( #spawnPositions > 0 ) then
		loc = spawnPositions[1]:GetLoc()
	else
		loc = Loc(0,0,0)
		loc:Fix()
	end
	return loc
end

--- This function is called by the core engine before it sends any given object to the users' client
-- It allows you to allow users to see cloaked objects (they appear "cloaked")
-- @param user to check for
-- @param cloaked object to check
function ShouldSeeCloakedObject(user, targetObj)
	
	if ( user == nil ) then return false end
	if ( targetObj == nil ) then return false end
	
		
	if not( targetObj:IsCloaked() ) then return true end
	
	if ( targetObj:HasObjVar("AlwaysInvisible") ) then return false end

	if ( IsImmortal(user) ) then return true end

	if ( user:HasObjVar("SeeInvis") ) then return true end

	if ( targetObj:HasObjVar("VisibleToAll") ) then return true end
	
	if ( targetObj:HasObjVar("IsGhost") ) then
		if ( user:HasObjVar("IsGhost") or user:HasObjVar("CanSeeGhosts") ) then
			return true
		else
			return false
		end
	end

	if ( targetObj:HasObjVar("VisibleToDeadOnly") ) then
		if ( Death.Active(user) ) then
			return true
		else
			return false
		end
	end
			
	return false
end

--- Return a list of options for interacting with the specified object
-- each option is an array containing the display name and the return id
-- NOTE: empty string is the default id 
-- @param user performing the action
-- @param targetObj object being used
function GetObjectInteractionList(user, targetObj)
	local menuItems = {}
	return menuItems
end