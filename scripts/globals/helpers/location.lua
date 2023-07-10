-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- Helper functions for obtaining positions in the world
-- @module globals.helpers.world_location

--- Finds a location near the specified object that is passable
-- @param targetObj target object to search around
-- @param angleRange angle range from target facing (defaults to 360)
-- @param minDist minimum distance from target
-- @param maxDis maximum distance from target
-- @return nearbyLoc nearby passable location (nil if not found)
function GetNearbyPassableLoc(targetObj,angleRange,minDist,maxDist)
	if not( targetObj:IsValid() ) then return nil end

	angleRange = angleRange or 360
	minDist = minDist or 3
	maxDist = maxDist or 10

	local maxTries = 20
    local moveAngle = math.random(angleRange,angleRange*2)-angleRange
    local nearbyLoc = targetObj:GetLoc():Project(moveAngle, math.random(minDist,maxDist))
    -- try to find a passable location
    while ( maxTries > 0 and not IsPassable(nearbyLoc) ) do
    	local moveAngle = math.random(angleRange,angleRange*2)-angleRange
        nearbyLoc = targetObj:GetLoc():Project(moveAngle, math.random(minDist,maxDist))
        maxTries = maxTries - 1
    end

    return nearbyLoc
end

--- Finds a location near the specified location that is passable
-- @param targetObj target object to search around
-- @param minDist minimum distance from target
-- @param maxDis maximum distance from target
-- @return nearbyLoc nearby passable location (nil if not found)
function GetNearbyPassableLocFromLoc(targetLoc,minDist,maxDist)	
	local angleRange = 360
	minDist = minDist or 3
	maxDist = maxDist or 10

	local maxTries = 20
    local moveAngle = math.random(angleRange,angleRange*2)-angleRange
    local nearbyLoc = targetLoc:Project(moveAngle, math.random(minDist,maxDist))
    -- try to find a passable location
    while(maxTries > 0 and not(IsPassable(nearbyLoc)) ) do
    	local moveAngle = math.random(angleRange,angleRange*2)-angleRange
        nearbyLoc = targetLoc:Project(moveAngle, math.random(minDist,maxDist))
        maxTries = maxTries - 1
    end

    return nearbyLoc
end

--- Checks if a location is passable and does not have a house at that location
-- @param spawnLoc location to check
-- @param excludeHousing should we exclude locations where houses are placed
-- @return true if valid
function IsValidLoc(spawnLoc,excludeHousing)
	if(spawnLoc == nil) then
		LuaDebugCallStack("Invalid Location!")
		return false
	end

	if not(IsPassable(spawnLoc)) then
		return false
	end

	if( excludeHousing and HasHouseAtLoc(spawnLoc) ) then
		return false
	end

	return true
end

--- Get a random passable location within a specified region
-- @param spawnLoc location to check
-- @param excludeHousing should we exclude locations where houses are placed
-- @return true if valid
function GetRandomPassableLocation(regionName,excludeHousing)
	local region = GetRegion(regionName)
	if( region == nil ) then
		LuaDebugCallStack("REGION IS NIL: "..tostring(regionName))
		return nil
	end

    local maxTries = 20
    local spawnLoc = region:GetRandomLocation()
    -- try to find a passable location
    while(maxTries > 0 
    		and not(IsValidLoc(spawnLoc,excludeHousing)) ) do
        spawnLoc = region:GetRandomLocation()
        maxTries = maxTries - 1
    end

    return spawnLoc
end 

--- Validate a range is less than or equal to a value, optionally give errors to any players involed. Safe for a and b to be the same obj.
-- @param range double The distance to check
-- @param a mobileObj
-- @param b mobileObj
-- @param aErr(optional) Given the distance between a and b is > range, a will receive this in a system message.
-- @param bErr(optional) Given the distance between a and b is > range, b will receive this in a system message.
-- @return true if distance between a and b is less than or equal to range.
function ValidateRangeWithError(range, a, b, aErr, bErr)
	if ( a ~= b and a:DistanceFrom(b) > range ) then
		if ( aErr ~= nil and a:IsPlayer() ) then
			a:SystemMessage(aErr)
		end
		if ( bErr ~= nil and b:IsPlayer() ) then
			b:SystemMessage(bErr)
		end
		return false
	else
		return true
	end
end