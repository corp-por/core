-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- Immortal commands
local Include = {}

-- set access level for all included functions
Include.access = AccessLevel.Immortal

-- function definitions
Include.functions = {
    Resurrect = function(objId)
        if ( objId ~= nil ) then
            local target = GameObj(tonumber(objId))
            Death.End(target)
        else
            this:RequestClientTargetGameObj(this, "ResurrectTarget")

            RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "ResurrectTarget",
                function(target,user)
                    if( target == nil ) then
                        return
                    end

                    Death.End(target)
                end)
        end
    end,
    Teleport = function()
        this:RequestClientTargetLoc(this, "TeleportCommand")

        RegisterEventHandler(EventType.ClientTargetLocResponse, "TeleportCommand", function(success,targetLoc)
            if ( success ) then
                this:RequestClientTargetLoc(this, "TeleportCommand")
                --if( this:HasLineOfSightToLoc(targetLoc,ServerSettings.Combat.LOSEyeLevel) ) then --IsPassable(targetLoc) ) then
                if ( targetLoc:Fix() ) then
                    this:SetWorldPosition(targetLoc)
                    this:PlayEffect("TeleportToEffect")
                else
                    this:SystemMessage("Area not passable", "info")
                end
            else
                UnregisterEventHandler("",EventType.ClientTargetLocResponse, "TeleportCommand")
            end	
        end)
    end,
    Invulnerable = function()
        if ( Var.Has(this, "Invulnerable") ) then
            this:NpcSpeechToUser("Invulnerability DISABLED", this)
            Var.Del(this, "Invulnerable")
        else
            this:NpcSpeechToUser("Invulnerability enabled.", this)
            Var.Set(this, "Invulnerable", true)
        end
    end,
    GoTo = function(x, y, z)
        if ( z == nil ) then
            z = y
        end
        if ( x ~= nil and y ~= nil ) then
            x = tonumber(x)
            y = tonumber(y)
        end
        if ( z ~= nil ) then
            z = tonumber(z)
        end
        local loc = Loc(x,y,z)
        loc:Fix()
        this:SetWorldPosition(loc)
    end
}

-- command definitions: { name, function, usage, description, aliases }
Include.commands = {
    { "resurrect", Include.functions.Resurrect, "[]", "Bring something back from the dead.", {"res"} },
    { "teleport", Include.functions.Teleport, "[]", "Jump. Jump. Jump around.", {"tele"} },
    { "invulnerable", Include.functions.Invulnerable, "[]", "Toggle self Invulnerability", {"inv"} },
    { "goto", Include.functions.GoTo, "[]", "Teleport to a specific location.", {"go"} },
}

return Include

