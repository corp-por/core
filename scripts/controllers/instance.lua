-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'clusterglobal_request_response'

local MASTER_CONTROLLER_PULSE_SPEED = TimeSpan.FromMinutes(1)
local MASTER_CONTROLLER_PULSE_FIRST = TimeSpan.FromMinutes(5)

-- prevent pulse from firing immediately if loading from a backup
this:RemoveTimer("MasterControllerPulse")

local regionAddress = ServerSettings.RegionAddress
local isMasterController = false

function OnLoad()
	this:SetObjectTag("InstanceController")
	local lastStartTime = GlobalVarReadKey("ClusterControl", "LastStartTime")
	if ( lastStartTime == nil or lastStartTime ~= SERVER_STARTTIME ) then
		SetGlobalVar("ClusterControl", function(record)
			-- double check that another region didn't already assume the role of master cluster
			if ( record.LastStartTime == SERVER_STARTTIME ) then
				DebugMessage("[ClusterControl] Prevented Duplicate Master Controller.")
				return false
			end
			record.LastStartTime = SERVER_STARTTIME
			record.Master = this
			return true
		end, function(success)
			if ( success ) then
				-- if successful, we are the master controller, clear User.Online and start the master controller pulse
				DebugMessage("[ClusterControl] "..(regionAddress or "").." is the master controller")
                isMasterController = true
                
                -- clear the User.Online global variable
				if ( GlobalVarRead("User.Online") ) then
					DelGlobalVar("User.Online", function()
						this:ScheduleTimerDelay(MASTER_CONTROLLER_PULSE_FIRST, "MasterControllerPulse")
					end)
				else
					this:ScheduleTimerDelay(MASTER_CONTROLLER_PULSE_FIRST, "MasterControllerPulse")
				end
			else
				-- if start time is correct, another region beat us to master controller, double check that is the case
				if ( GlobalVarReadKey("ClusterControl", "LastStartTime") ~= SERVER_STARTTIME ) then
					DebugMessage("ERROR: ClusterControl global var write failed. No master controller detected!!")
				end
			end
		end)
	end
end

function OnUserLogin(user,type)
	if ( type == "ChangeWorld" ) then

	elseif ( type == "Connect" ) then
		-- write function to write user as online globally
		local writeOnline = function(record)
			record[user] = true
			return true
		end
		-- kick off the global writes
		SetGlobalVar("User.Online", writeOnline)
	end
end

local pulseCount = 1
RegisterEventHandler(EventType.Timer, "MasterControllerPulse", function ()
	-- double check we are infact the master controller.
	if ( GlobalVarReadKey("ClusterControl", "Master") ~= this ) then
		DebugMessage("[ClusterControl] Preventing incorrect master controller from performing master pulse.")
		return
    end
    
    -- currently nothing is being done
	
	pulseCount = pulseCount + 1
	this:ScheduleTimerDelay(MASTER_CONTROLLER_PULSE_SPEED,"MasterControllerPulse")
end)

RegisterEventHandler(EventType.ModuleAttached,GetCurrentModule(),
	function ()		
		this:SetObjVar("ServerBirth",DateTime.UtcNow.Date)
		OnLoad()			
	end)

RegisterEventHandler(EventType.LoadedFromBackup,"", OnLoad)

RegisterEventHandler(EventType.Message, "UserLogin", function(user, type)
    if ( type == "ChangeWorld" ) then

    elseif ( type == "Connect" ) then
        -- write function to write user as online globally
        local writeOnline = function(record)
            record[user] = true
            return true
        end
        -- kick off the global writes
        SetGlobalVar("User.Online", writeOnline)
    end
end)

RegisterEventHandler(EventType.Message, "UserLogout", function(user, clear)
    -- write function to remove user as online globally
    local write = function(record)
        record[user] = nil
        return true
    end
    -- write user as offline
    SetGlobalVar("User.Online", write)
end)

--- FRAMETIME MONITORING CODE ---


FRAMETIME_ALERT_THRESHOLD = 0.200
-- dont send alert more than once an hour
FRAMETIME_ALERT_THROTTLE = 60*60

-- give the server 5 minutes to start up before we start monitoring
this:ScheduleTimerDelay(TimeSpan.FromMinutes(5), "frametime_monitor")
RegisterEventHandler(EventType.Timer, "frametime_monitor", function ( ... )
    local avgFrameTime = DebugGetAvgFrameTime()
	if ( avgFrameTime >= FRAMETIME_ALERT_THRESHOLD ) then
		DebugMessage("Lag Report: "..os.date().." from "..tostring(ServerSettings.RegionAddress),"Average Frame Time: "..tostring(avgFrameTime))
        this:ScheduleTimerDelay(TimeSpan.FromSeconds(FRAMETIME_ALERT_THROTTLE),"frametime_monitor")
    else
        this:ScheduleTimerDelay(TimeSpan.FromSeconds(3),"frametime_monitor")
    end
end)

-- do the autofix on world items.
CallFunctionDelayed(TimeSpan.FromSeconds(5), function()
	DoWorldAutoFix(this)
end)

--[[
local loc = Loc(0,50,0)
Create.AtLoc('skeleton', Loc(0,50,0), function(skeleton)
	Create.AtLoc('sword', Loc(0,50,0), function(sword)
		
	end)
end)
]]