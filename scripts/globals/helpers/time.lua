-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD

function TimeSpanToWords(tmspn, singular, skip)
    if ( tmspn.TotalSeconds <= 0 ) then return "no time" end
    if ( tmspn.TotalSeconds < 1 ) then return "less than a second" end
    local str = ""
    if ( tmspn.Days > 0 ) then
        str = str .. tmspn.Days .. " day"
        if ( not singular and tmspn.Days > 1 ) then
            str = str .. "s "
        else
            str = str .. " "
        end
    end
    if ( tmspn.Hours > 0 ) then
        str = str .. tmspn.Hours .. " hour"
        if ( not singular and tmspn.Hours > 1 ) then
            str = str .. "s "
        else
            str = str .. " "
        end
    end
    if ( tmspn.Minutes > 0 ) then
        str = str .. tmspn.Minutes .. " minute"
        if ( not singular and tmspn.Minutes > 1 ) then
            str = str .. "s "
        else
            str = str .. " "
        end
    end
    if ( (str == "" or skip == nil or skip.Seconds ~= true) and tmspn.Seconds > 0 ) then
        str = str .. tmspn.Seconds .. " second"
        if ( not singular and tmspn.Seconds > 1 ) then
            str = str .. "s "
        else
            str = str .. " "
        end
    end
    return StringTrim(str)
end

function GetNow()
    return DateTime.UtcNow
end

function GetNextTime(epoch, interval, now)
    if not( now ) then now = DateTime.UtcNow end
    local es = now:Subtract(epoch).TotalSeconds
    local ti = math.ceil(es / interval.TotalSeconds)
    return epoch:AddSeconds(ti*interval.TotalSeconds)
end

function TimeUntil(epoch, interval, now)
    if not( now ) then now = DateTime.UtcNow end
    return GetNextTime(epoch, interval, now):Subtract(now)
end

-- check if it is the next interval of an epoch
-- @param epoch -- The starting date to base the interval off of
-- @param interval -- how often is the loop of time we are checking
-- @param now -- (optional) defaults to DateTime.UtcNow
-- @param resolution - (optional) TimeSpan resolution in seconds, defaults to 1 second.
-- @return boolean
function IsTime(epoch, interval, now, resolution)
    if not( now ) then now = DateTime.UtcNow end
    if not( resolution ) then resolution = TimeSpan.FromSeconds(1) end
    --DebugMessage(TimeSpanToWords(TimeUntil(epoch, interval, now:Subtract(resolution))))
    return ( TimeUntil(epoch, interval) >= interval:Subtract(resolution) )
end