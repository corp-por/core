-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Wander = {
    Name = "Wander",
    Init = function(self)
        if not( Var.Has(self.Parent, "SpawnLocation") ) then
            self.SpawnLocation = self.Loc
            Var.Set(self.Parent, "SpawnLocation", self.SpawnLocation)
        end
        if not ( self.SpawnLocation ) then
            self.SpawnLocation = Var.Get(self.Parent, "SpawnLocation")
        end
    end,
    EnterState = function(self)
        Modify.Factor(self.Parent, "MoveSpeed", "WanderState", -0.5)
    end,
    ExitState = function(self)
        Modify.Del(self.Parent, "MoveSpeed", "WanderState")
    end,
    ShouldRun = function(self)
        return (not self.Parent:HasPath() and math.random(1,self.WanderPulsewisePauseChance or 5) == 1)
    end,
    Run = function(self)
        local maxHP = Stat.Health.Max(self.Parent)
        if not( Stat.Health.Get(self.Parent) == maxHP ) then
            Stat.Health.Set(self.Parent, maxHP)
        end
        
        local loc = self.SpawnLocation:Project(math.random(0,360), math.random(self.WanderMin or 2, self.WanderMax or 4))
        if ( IsPassable(loc) ) then
            self.PathTo(loc)
        end
    end,
}