-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Leash = {
    Name = "Leash",
    Init = function(self)
        if not( self.Parent:HasObjVar("SpawnLocation") ) then
            self.SpawnLocation = self.Loc
            Var.Set(self.Parent, "SpawnLocation", self.SpawnLocation)
        end
        if not ( self.SpawnLocation ) then
            self.SpawnLocation = Var.Get(self.Parent, "SpawnLocation")
        end
    end,
    EnterState = function(self)
        self.SetTarget(nil)
        --SetMobileMod(self.Parent, "HealthRegenTimes", "Leashing", 1000)
        Var.Set(self.Parent, "Invulnerable", true)
    end,
    ExitState = function(self)
        --SetMobileMod(self.Parent, "HealthRegenTimes", "Leashing", nil)
        Var.Del(self.Parent, "Invulnerable")
    end,
    ShouldRun = function(self)
        return (
            self.IsLeashing
            or
            (
                ( self.CurrentTarget == nil and self.Loc:Distance(self.SpawnLocation) > (self.WanderMax or 8) + 3 )
                or
                ( self.Loc:Distance(self.SpawnLocation) >= (self.LeashDistance or 45) )
            )
        )
    end,
    Run = function(self)
        if ( self.IsLeashing ) then
            if not( self.Parent:HasPath() ) then
                self.IsLeashing = nil
            end
        else
            self.SetTarget(nil)
            if ( self.Loc:Distance(self.SpawnLocation) >= MAX_PATHTO_DIST ) then
                -- teleport them, too far away
                PlayEffectAtLoc("TeleportFromEffect", self.Loc)
                self.Parent:SetWorldPosition(self.SpawnLocation)
                return
            end
            self.PathTo(self.SpawnLocation, (self.LeashSpeed or 7))
            if ( self.Parent:HasPath() ) then
                self.IsLeashing = true
            end
        end
    end,
}