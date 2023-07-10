-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Var = {}

if ( _G.VAR_CACHE == nil ) then
    _G.VAR_CACHE = {}
end

local VAR_CACHE = _G.VAR_CACHE

function Var.Set(gameObj, varName, varValue)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Set] nil gameObj provided")
        return
    end
    if ( VAR_CACHE[gameObj] == nil ) then
        VAR_CACHE[gameObj] = {}
    end
    VAR_CACHE[gameObj][varName] = varValue
    gameObj:SetObjVar(varName, varValue)
end

function Var.Get(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Get] nil gameObj provided")
        return
    end
    if ( VAR_CACHE[gameObj] ~= nil and VAR_CACHE[gameObj][varName] ~= nil ) then
        return VAR_CACHE[gameObj][varName]
    else
        local val = gameObj:GetObjVar(varName)
        if ( VAR_CACHE[gameObj] == nil ) then
            VAR_CACHE[gameObj] = {}
        end
        VAR_CACHE[gameObj][varName] = val
        return val
    end
end

function Var.Del(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Del] nil gameObj provided")
        return
    end
    if ( VAR_CACHE[gameObj] ) then
        VAR_CACHE[gameObj][varName] = nil
    end
    gameObj:DelObjVar(varName)
end

function Var.Has(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Has] nil gameObj provided")
        return
    end
    if ( VAR_CACHE[gameObj] and VAR_CACHE[gameObj][varValue] ~= nil ) then
        return true
    else
        return ( Var.Get(gameObj, varName) ~= nil )
    end
end

-- Temporary Variables, these are memory only variables thus are never committed to disk and are not persistent
Var.Temp = {}

if ( _G.TempVars == nil ) then
    _G.TempVars = {}
end

local TempVars = _G.TempVars

function Var.Temp.Set(gameObj, varName, varValue)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Temp.Set] nil gameObj provided")
        return
    end
    if not( TempVars[gameObj] ) then
        TempVars[gameObj] = {}
    end
    TempVars[gameObj][varName] = varValue
end

function Var.Temp.Get(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Temp.Get] nil gameObj provided")
        return
    end
    if ( TempVars[gameObj] ~= nil ) then
        return TempVars[gameObj][varName]
    end
    return nil
end

function Var.Temp.Del(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Temp.Del] nil gameObj provided")
        return
    end
    if ( TempVars[gameObj] ~= nil ) then
        TempVars[gameObj][varName] = nil
    end
end

function Var.Temp.Has(gameObj, varName)
    if ( gameObj == nil ) then
        LuaDebugCallStack("[Var.Temp.Has] nil gameObj provided")
        return false
    end
    return ( TempVars[gameObj] ~= nil and TempVars[gameObj][varName] ~= nil )
end

function Var.Temp.Clear(gameObj)
    TempVars[gameObj] = nil
end