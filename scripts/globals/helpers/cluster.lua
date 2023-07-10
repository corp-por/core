-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- In the default rules, the multiverse is divided into parallel universes
-- The region address for each region in the cluster has the following naming convention
--    UniverseName.MapName (Ex: AzureSky.Celador or AzureSky.Outlands)
function GetUniverseName(regionAddress)
	--DebugMessage("GetUniverseName",tostring(regionAddress))
	regionAddress = regionAddress or ServerSettings.RegionAddress

	local myUniverseName, worldName = string.match(regionAddress or "", "(%a+)%.(%a+)")
	--DebugMessage("GetUniverseName",tostring(myUniverseName),tostring(worldName))
	return myUniverseName, worldName
end

function GetUniverseDisplayName(regionAddress)
	local universe = GetUniverseName(regionAddress)
	return UniverseDisplayNames[universe] or universe
end

-- Return the list of universes running the specified map
-- NOTE: If the map has subregions it will be included if atleast one of them is running
function GetUniversesWithMap(mapName)
	-- We need to find a list of universes that are running NewCelador
	local validUniverses = {}
	for regionName,regionInfo in pairs(GetClusterRegions()) do 
		local parts = StringSplit(regionName,".")
		if(#parts > 1) then
			local universeName = parts[1]
			local curMapName = parts[2]
			if(curMapName == mapName) then
				validUniverses[universeName] = true
			end
		end
	end

	local universeList = {}
	for universeName,dummy in pairs(validUniverses) do
		table.insert(universeList,universeName)
	end

	return universeList
end

-- Return the list of region addresses that contain the search term
function GetRegionAddressesForName(name)
	local universeList = {}
	for regionName,regionInfo in pairs(GetClusterRegions()) do 
		if(string.find(regionName, name) ~= nil) then
			table.insert(universeList,regionName)
		end
	end

	return universeList
end

-- returns the first matching region address
function GetRegionAddressForName(name)
	for regionName,regionInfo in pairs(GetClusterRegions()) do 
		if(string.find(regionName, name) ~= nil) then
			return regionName
		end
	end
end

-- Returns true if another region is running on the cluster with the same map (in another universe)
function HasParallelRegion(regionAddress)
	regionAddress = regionAddress or ServerSettings.RegionAddress

	local myUniverseName, worldDotSubregionName = string.match(regionAddress, "(%a+)%.(%a+)")
	--DebugMessage("myUniverseName",tostring(myUniverseName),"worldName",tostring(worldName))
	if(myUniverseName == nil or worldName == nil) then
		-- region is not using universe naming scheme so no parallels exist
		return false
	end

	local allRegions = GetClusterRegions()
	for otherRegionAddress,otherRegionInfo in pairs(allRegions) do
		if(otherRegionAddress ~= regionAddress) then			
			local otherUniverseName, otherWorldDotSubregionName = string.match(otherRegionAddress, "(%a+)%.(%a+)")
			if(otherUniverseName ~= nil and otherWorldDotSubregionName == worldDotSubregionName) then
				return true
			end
		end
	end

	return false
end

function GetCurrentUniverseName()
	return GetUniverseName(ServerSettings.RegionAddress)
end

local clusterController = nil
function GetClusterController() -- TODO rename this to instance controller
	if(clusterController == nil) then
		clusterController = FindObjectWithTag("InstanceController")
	end

	--DebugMessage("ClusterController "..tostring(clusterController))

	return clusterController
end

function MessageAllClusterControllers(messageName,...)
	for regionName, regionInfo in pairs(GetClusterRegions()) do
        if (regionName ~= ServerSettings.RegionAddress) then
            MessageRemoteClusterController(regionName, messageName, ...)
        else
            GetClusterController():SendMessage(messageName,...)
        end
    end
end

function MessageRemoteClusterController(regionAddress,messageName,...)
	return SendRemoteMessage(regionAddress,Loc(0.1,0.1,0.1),1.0,messageName,...)
end

function FindGlobalUsersByName(name)
	if ( name ~= nil ) then name = name:lower() end
	local online = GlobalVarRead("User.Online") or {}
	local results = {}
	for gameObj,dummy in pairs(online) do
		if ( name == nil or gameObj:GetCharacterName():lower():match(name) ) then	
			table.insert(results, gameObj)
		end
	end
	return results
end

function FindGlobalUsers(partialNameOrId)
	-- searching by id.
	local id = tonumber(partialNameOrId)
	if ( id ) then
		local obj = GameObj(id)
		if ( GlobalVarReadKey("User.Online", obj) ) then
			return {obj}
		end
	end
	return FindGlobalUsersByName(partialNameOrId)
end

function IsUserOnline(user)
	return GlobalVarReadKey("User.Online", user)
end

function SetGlobalVar(name, writeFunction, callbackFunction)
    if ( name == nil ) then
        LuaDebugCallStack("[SetGlobalVar] Nil name provided.")
        return false
    end
    if ( writeFunction == nil ) then
        LuaDebugCallStack("[SetGlobalVar] Nil writeFunction provided.")
        return false
    end
    -- handle global var write event
    local eventId = uuid()
    RegisterSingleEventHandler(EventType.GlobalVarUpdateResult, eventId, function(success, name, record)
        if ( callbackFunction ) then callbackFunction(success, name) end
    end)
    -- kick off the global write
    GlobalVarWrite(name, eventId, writeFunction)
end

function DelGlobalVar(name, callbackFunction)
    if not( name ) then
        LuaDebugCallStack("[DelGlobalVar] name not provided.")
        return false
    end
    -- handle global var delete event
    local eventId = uuid()
    RegisterSingleEventHandler(EventType.GlobalVarUpdateResult, eventId, function(success, name, record)
        if ( callbackFunction ) then callbackFunction(success, name) end
    end)
    -- kick off the global write
    GlobalVarDelete(name, eventId)
end