-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2025 Corp Por LTD

Effects.Taxi = {
    -- icon of effect (optional)
    Icon = "SpellBook05_103",
    -- display name of icon, if not set will use effect name
    DisplayName = "Taxi",
    -- tool tip to display on icon (optional)
    Tooltip = "In route.",
    -- optional tooltip function
    OnTooltip = function(self)
        return ""
    end,
    -- if the effect a good or a bad effect?
    Debuff = false,
    -- can the effect be canceled? (by clicking the icon)
    Cancelable = true,
    -- total duration of this effect (optional)
    --Duration = TimeSpan.FromSeconds(15),
    -- how many times should this pulse? (optional)
    --Pulse = 10,
    
    -- should this effect remain after a player and re-logged?
    PersistSession = true,
    -- should this effect remain on death?
    PersistDeath = false,

    -- end the effect when any movement occurs?
    EndOnMovement = false,

    -- handle starting the effect, returning false means the effect failed to start
    OnStart = function(self)
        if ( self.Route ~= nil ) then
            Var.Set(self.Parent, "TEMP_TaxiRoute", self.Route)
        end

        self.Route = self.Route or Var.Get(self.Parent, "TEMP_TaxiRoute")

        if ( self.Route == nil ) then
            LuaDebugCallStack("No Available Route Provided")
            return false
        end

        self.RouteI = Var.Get(self.Parent, "TEMP_OnRouteI") or 1

        self.Parent:EnableNavigationAgent()
        -- give them a horse.
        self.Parent:SetSharedObjectProperty("Pose", "Mounted")
        AddMountDNA(self.Parent, "EquipmentHorseMount")
        -- up the movement speed.
        Modify.Factor(self.Parent, "MoveSpeed", "Mount", 2.5)

        --self.Parent:NpcSpeech("En Route to: " .. self.Route.Name)

        self.Parent:PathTo(self.Route.Route[self.RouteI])

        Effects.Taxi.CustomPulse(self)

        return true
    end,

    CustomPulseTime = TimeSpan.FromSeconds(1),

    -- on pulse will be called each pulse if Pulse is specified
    CustomPulse = function(self)
        if ( self.Parent:GetLoc():Distance(self.Route.Route[self.RouteI]) <= 5 ) then
            -- move onto next one
            self.RouteI = self.RouteI + 1

            if ( self.RouteI > #self.Route.Route ) then
                -- reached the end.
                Effect.EndSelf(self)
            else
                Var.Set(self.Parent, "TEMP_OnRouteI", self.RouteI)
                -- path toward next one
                self.Parent:PathTo(self.Route.Route[self.RouteI])
            end
        end
        CallFunctionDelayed(Effects.Taxi.CustomPulseTime, function()
            Effects.Taxi.CustomPulse(self)
        end)
    end,

    -- called when effect has ended and been removed
    OnStop = function(self, canceled)
        Var.Del(self.Parent, "TEMP_TaxiRoute")
        Var.Del(self.Parent, "TEMP_OnRouteI")
        self.Parent:DisableNavigationAgent()
        -- remove the horse and speed benefit
        self.Parent:SetSharedObjectProperty("Pose", "")
        ClearMountDNA(self.Parent)
        Modify.Del(self.Parent, "MoveSpeed", "Mount")
    end,
}