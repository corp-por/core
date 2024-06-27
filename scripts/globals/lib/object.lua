-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Object = {}

--- Gets or sets an object immovability
-- @param object GameObj
-- @param newImmovable boolean (optional)
-- @return if newImmovable is not provided, will return true if object is immovable, false otherwise
function Object.Immovable(object, newImmovable)
    if ( newImmovable ~= nil ) then
        object:SetSharedObjectProperty("Immovable", newImmovable)
    else
        return object:GetSharedObjectProperty("Immovable")
    end
end

--- Set an object to decay after a specific timespan (or default decay timespan)
-- @param object GameObj
-- @param timespan TimeSpan (optional) will default to server setting default decay time
function Object.Decay(object, timespan)
    if ( not object or not object:IsValid() ) then
        LuaDebugCallStack("[Object.Decay] Invalid object provided.")
        return
    end

    timespan = timespan or ServerSettings.Interaction.DefaultDecayTime
    
	object:ScheduleDecay(timespan)
end

--- Get an object's template (preferred as the template id is cached in lua memory)
-- @param object - gameObject
local _templateIdCache = {}
function Object.Template(object)
    if ( object == nil ) then return nil end
    if ( _templateIdCache[object] == nil ) then
        _templateIdCache[object] = object:GetCreationTemplateId()
    end
    return _templateIdCache[object]
end