-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Walk = {
    Name = "Walk",
    Init = function(self)
        self.CacheLoc = nil
        self.TargetLoc = Var.Get(self.Parent, "TargetWalkLoc")
        RegisterEventHandler(EventType.Message, "WalkTo", function(loc)
            self.TargetLoc = loc
            self.ScheduleImmediate()
        end)
        local _PathArrived = self.PathArrived
        self.PathArrived = function()
            _PathArrived()
            if ( self.CacheLoc == nil ) then
                self.TargetLoc = nil
            end
            self.ScheduleImmediate()
        end
        self.Walk_I = 0
    end,
    ShouldRun = function(self)
        return self.TargetLoc ~= nil
    end,
    EnterState = function(self)
        self.Walk_I = 0
    end,
    ExitState = function(self)
        self.CacheLoc = nil
    end,
    Run = function(self)
        self.Walk_I = self.Walk_I + 1

        -- if not pathing or really close to a cached loc or haven't moved
        if (
            not self.Parent:HasPath()
            or
            (self.CacheLoc ~= nil and self.Loc:Distance(self.CacheLoc) <= 10)
            or
            (self.Walk_I > 20 and not self.Parent:IsMoving())
        ) then
            -- determine distance to location
            local distance = self.Loc:Distance(self.TargetLoc)
            if ( distance >= 30 ) then
                -- to far away to just path directly, project toward target and pick a spot that's not too far
                self.CacheLoc = self.Loc:Project(self.Loc:YAngleTo(self.TargetLoc), 30)
                if not( IsPassable(self.CacheLoc) ) then
                    self.CacheLoc = GetNearbyPassableLocFromLoc(self.CacheLoc, 5, 20)
                end
                if not( IsPassable(self.CacheLoc) ) then
                    DebugMessage("Warning! Could not find a passable midway location for long distance walking!")
                end
                self.PathTo(self.CacheLoc, self.Speed)
            else
                self.CacheLoc = nil
                -- close enough to just directly path to
                self.PathTo(self.TargetLoc, self.Speed)
            end
        end
    end,
}