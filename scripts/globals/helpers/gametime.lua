-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- Helpers for dealing with ingame time
-- @module globals.helpers.gametime

--- Get the ingame daylight duration in seconds
-- @return duration in seconds
function GetDaylightDurationSecs()
	return 60
end

--- Get the ingame nighttime duration in seconds
-- @return duration in seconds
function GetNighttimeDurationSecs()
	return 0
end

--- Get the ingame time of day in seconds (from 0 to day duration (daylight duration + nighttime duration))
-- @return duration in seconds
function GetCurrentTimeOfDay()	
	return 0
end