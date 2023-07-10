-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Modify = {}

-- without this if check, any script that 'reloads' this will empty all other mods for everything
if ( _G.Modifications == nil ) then
    _G.Modifications = {}
end

-- local variable pointing to the global one for convenience
local Modifications = _G.Modifications

function Modify.Set(gameObj, mod, id, val, sum)
    if ( gameObj == nil or mod == nil or id == nil ) then
        LuaDebugCallStack("[Modify.Set] required parameter is missing.")
        return
    end

    if ( Modifications[gameObj] == nil ) then
        Modifications[gameObj] = {}
    end

    if ( Modifications[gameObj][mod] == nil ) then
        Modifications[gameObj][mod] = {}
    end

    if ( val == nil ) then
        Modifications[gameObj][mod][id] = nil
    else
        Modifications[gameObj][mod][id] = {val, sum or false}
    end

    if ( mod == "MoveSpeed" ) then
        -- special case for movement, all negative movement affects mount speed as well.
        if ( val == nil or val < 0 ) then
            if ( Modifications[gameObj].MountMoveSpeed == nil ) then
                Modifications[gameObj].MountMoveSpeed = {}
            end
            Modifications[gameObj]["MountMoveSpeed"][id] = Modifications[gameObj][mod][id]
        end

        if ( false ) then -- IsMounted(this) ) then
            gameObj:SetBaseMoveSpeed(math.max(0.1, Modify.Apply(gameObj, mod, ServerSettings.Stats.BaseMoveSpeed)))
        else
            gameObj:SetBaseMoveSpeed(math.max(0.1, Modify.Apply(gameObj, mod, ServerSettings.Stats.BaseMoveSpeed)))
        end
    end

    
    if ( ({Freeze=true,Disable=true,Busy=true})[mod] ) then
        -- force value to be either true or false
        if ( val ~= true ) then val = false end
        Modify.MoveLock(gameObj, mod, id, val)
    end
    
end

-- alias for Modify.Set
function Modify.Factor(gameObj, mod, id, val)
    Modify.Set(gameObj, mod, id, val, false)
end

function Modify.Sum(gameObj, mod, id, val)
    Modify.Set(gameObj, mod, id, val, true)
end

function Modify.Del(gameObj, mod, id)
    Modify.Set(gameObj, mod, id, nil)
end

function Modify.Apply(gameObj, mod, value, inverse)
    if ( Modifications[gameObj] ~= nil and Modifications[gameObj][mod] ~= nil ) then
        local sum = 0
        local factor = 1
        for id,v in pairs(Modifications[gameObj][mod]) do
            if ( v[2] == true ) then
                if ( inverse ) then
                    sum = sum - v[1]
                else
                    sum = sum + v[1]
                end
            else
                if ( inverse ) then
                    factor = factor - v[1]
                else
                    factor = factor + v[1]
                end
            end
        end
        return ( value + sum ) * factor
    end
    return value
end

function Modify.Clear(gameObj)
    Modifications[gameObj] = nil
end

function Modify.Debug(gameObj)
    DebugMessage("-Modify Debug-", gameObj)
    if ( Modifications[gameObj] == nil ) then
        DebugMessage("Nothing is Modified")
        return
    end
    for mod,mods in pairs(Modifications[gameObj]) do
        for id,v in pairs(Modifications[gameObj][mod]) do
            DebugMessage(mod, id, v[1], v[2])
        end
    end
    DebugMessage("-End Modify Debug-")
end

-- Handles the 'stacking' of disable/freeze effects
function Modify.MoveLock(gameObj, name, id, val)
    --DebugMessage(gameObj, name, id, val)

	local disable,busy,freeze = ({Disable=true})[name],({Busy=true})[name],({Freeze=true})[name]
    local freezes,disables,slows = false,false,false

	if ( freeze ) then
        -- check all Freeze mods that only use SetMobileFrozen
        if ( Modifications[gameObj].Freeze ~= nil ) then
            for i,v in pairs(Modifications[gameObj].Freeze) do
                if ( v == true and i ~= id ) then freezes = true break end
            end
        end
	
		-- if the mod is Freeze, and there are no other freezes, do exactly as asked.
		if ( freezes == false ) then gameObj:SetMobileFrozen(val, val) end

		return
	end
	
	if ( (disable or busy) and Modifications[gameObj].Disable ~= nil ) then
		for i,v in pairs(Modifications[gameObj].Disable) do
			if ( v == true and i ~= id ) then
				disables = true
				slows = true
				break
			end
		end
	end
	
	if ( (busy and disables == false) and Modifications[gameObj].Busy ~= nil ) then
		-- check all Busy mods that only use Disabled objVar
		for i,v in pairs(Modifications[gameObj].Busy) do
			if ( v == true and i ~= id ) then disables = true break end
		end
	end

	-- if the mod is Disable, and there are no other slows, do exactly as asked.
	if ( disable and slows == false ) then
		if ( id == "CastFreeze" ) then
			Modifications[gameObj].MoveSpeedTimes.ReservedIDCast = val and -0.7 or nil
			Modifications[gameObj].MountMoveSpeedTimes.ReservedIDCast = val and -0.7 or nil
		else
			Modifications[gameObj].MoveSpeedTimes.ReservedID = val and -1 or nil
			Modifications[gameObj].MountMoveSpeedTimes.ReservedID = val and -1 or nil
        end
	end

	-- if the mod is Disable or Busy and there are no other disables, do exactly as asked.
	if ( (disable or busy) and disables == false ) then
        if ( val ) then
            Var.Temp.Set(gameObj, "Disabled", true)
        else
            Var.Temp.Del(gameObj, "Disabled")
            gameObj:SendMessage("ResetSwingTimer")
		end
    end
    
    if ( disable and val ) then
        Ability.Cast.Cancel(gameObj)
    end
end