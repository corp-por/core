-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- Helper functions for container objects
-- @module globals.helpers.container_objects

--- Is this a locked container
-- @param containerObj 
-- @return true if locked
function IsLocked (contObj)
	return targetObj:GetObjVar("locked") == true
end

--- Searches for a single object contained within the specified object by creation template id (NOT RECURSIVE!)
-- NOTE: If multiple items match, it just returns the first one it finds
-- @param containerObj 
-- @param template template id to search for
-- @return match object (nil if not found)
function FindItemInContainerByTemplate(contObj, template)
	if( not(contObj) or not(contObj:IsContainer()) ) then return nil end

	local contents = contObj:GetContainedObjects()
	for i=1,#contents do
		if ( Object.Template(contents[i]) == template ) then
			return containedObj		
		end
	end
end

--- Searches for a single object contained within the specified object by calling a comparison function on each one (NOT RECURSIVE!)
-- NOTE: If multiple items match, it just returns the first one it finds
-- @param containerObj 
-- @param functor comparison function to call on each object (returns a boolean indicating if the object is a match)
-- @return match object (nil if not found)
function FindItemInContainer(contObj,compFunc)
	if ( not contObj or not contObj:IsContainer() ) then return nil end

	local contents = contObj:GetContainedObjects()
	for i=1,#contents do
		if ( compFunc(contents[i]) ) then
			return containedObj		
		end
	end
end

--- Searches for a single object contained within the specified object by creation template id (recursively)
-- NOTE: If multiple items match, it just returns the first one it finds
-- @param containerObj 
-- @param template template id to search for
-- @return match object (nil if not found)
function FindItemInContainerByTemplateRecursive(contObj,template)
	return FindItemInContainerRecursive(contObj, function(containedItem)
		return Object.Template(containedItem) == template
	end)
end

--- Searches for a single object contained within the specified object by calling a comparison function on each one (recursively)
-- NOTE: If multiple items match, it just returns the first one it finds
-- @param containerObj 
-- @param functor comparison function to call on each object (returns a boolean indicating if the object is a match)
-- @return match object (nil if not found)
function FindItemInContainerRecursive (contObj, compFunc)
	if ( not contObj or not contObj:IsContainer() or not compFunc ) then return nil end

	local contents = contObj:GetContainedObjects()
	for i=1,#contents do	
		if ( compFunc(contents[i]) ) then
			return containedObj
		end

		local subResult = FindItemInContainerRecursive(containedObj, compFunc)
		if ( subResult ) then
			return subResult
		end
	end
end

--- Searches for objects contained within the specified object by creation template id (recursively)
-- @param containerObj 
-- @param template template id to search for
-- @return array of matching objects
function FindItemsInContainerByTemplateRecursive(contObj,template)
	return FindItemsInContainerRecursive(contObj, function(objRef)
		return Object.Template(objRef) == template
	end)
end

--- Searches for objects contained within the specified object by calling a comparison function on each one (recursively)
-- @param containerObj 
-- @param functor comparison function to call on each object (returns a boolean indicating if the object should be included in the results)
-- @return array of matching objects
function FindItemsInContainerRecursive(contObj,compFunc)
	if ( not contObj or not contObj:IsContainer() or not compFunc ) then return {} end

	local result = {}
	local contents = contObj:GetContainedObjects()
	for i=1,#contents do
		if ( compFunc(contents[i]) ) then
			table.insert(result, containedObj)
		end
		local subResults = FindItemsInContainerRecursive(containedObj, compFunc)
		if ( #subResults > 0 ) then
			for i=1,#subResults do
				table.insert(result, subResults[i])
			end
		end
	end

	return result
end

--- Calls a function on each item contained within the specified object (recursively)
-- NOTE If the function returns nil or false, the search stops. You must return true
-- @param containerObj 
-- @param compFunc function to call on each object
-- @param depth how many levels deep should the search go (default infinity)
function ForEachItemInContainerRecursive(contObj,compFunc,depth)
	if not( contObj:IsContainer() ) then return end

	if ( depth == nil ) then
		depth = 1
	else
		depth = depth + 1	
	end

	local contents = contObj:GetContainedObjects()
	for i=1,#contents do
		if not( compFunc(contents[i], depth) ) then
			return
		else			
			ForEachItemInContainerRecursive(contents[i], compFunc, depth)
		end
	end
end

--- Calls a function on each parent of the specified object all the way to the top level object
-- NOTE If the function returns nil or false, the search stops. You must return true
-- @param containerObj 
-- @param includeSelf should you call the function on the current object 
-- @param functor function to call on each object
function ForEachParentContainerRecursive(contObj, includeSelf, functor)
	local curObj = contObj
	if not(includeSelf) then
		curObj = contObj:ContainedBy()
	end

	while curObj ~= nil do 
		if not(functor(curObj)) then
			return
		end

		curObj = curObj:ContainedBy()
	end
end

function GetObjectAtSlot(containerObj,slotIndex)
	local containedObjects = containerObj:GetContainedObjects()
	if(#containedObjects > 0) then
		for i,contObj in pairs(containedObjects) do			
			local contLoc = contObj:GetLoc()
			local slot = math.floor(contLoc.X)
			if(slot == tonumber(slotIndex)) then
				return contObj
			end
		end
	end
end

frameOffsets = {}