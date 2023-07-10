-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.FollowPath = {
    Name = "FollowPath",
    Init = function(self)
        self.Path, self.LoopPath = AIProperty.GetPath(self.Template)
        local _PathArrived = self.PathArrived
        self.PathArrived = function()
            if ( self.States[self.StateIndex] == States.FollowPath ) then
                _PathArrived()
                if ( self.FollowPathSkipNextImmediate == true ) then
                    self.FollowPathSkipNextImmediate = false
                else
                    self.ScheduleImmediate()
                end
            end
        end
        self.WanderMax = (self.LeashDistance or 45) -- to allow pathing between far points and not leashing
        self.Returning = false
    end,
    ShouldRun = function(self)
        return (self.Path ~= nil and #self.Path > 0)
    end,
    EnterState = function(self)
        self.Path_Index = States.FollowPath.FindClosestPoint(self)
        self.SpawnLocation = self.Path[self.Path_Index]
        self._I = 0
        self.Parent:SendMessage("ClearDamagersHealers")
    end,
    Run = function(self)
        if ( self.FollowPathSkipNextImmediate ) then
            self.FollowPathSkipNextImmediate = false
        end
        -- if a closest path wasn't found we can't run
        if ( self.Path_Index < 1 ) then
            DebugMessage("Failed to find closest path, I must be too far away? Maybe add a teleport here??")
            return
        end

        self._I = self._I + 1

        -- if not pathing or really close to a next target or haven't moved
        if (
            not self.Parent:HasPath()
            or
            self.Loc:DistanceSquared(self.TargetLoc) <= 2
            or
            (self._I > 20 and not self.Parent:IsMoving())
        ) then
            self._I = 0
            -- determine distance to location
            local distance = self.Loc:Distance(self.Path[self.Path_Index])
            if ( distance >= 60 ) then
                -- to far away to just path directly, project toward target and pick a spot that's not too far
                self.TargetLoc = self.Loc:Project(self.Loc:YAngleTo(self.Path[self.Path_Index]), 30)
                if not( IsPassable(self.TargetLoc) ) then
                    self.TargetLoc = GetNearbyPassableLocFromLoc(self.TargetLoc, 5, 20)
                end
                if not( IsPassable(self.TargetLoc) ) then
                    DebugMessage("Warning! Could not find a passable midway location for long distance walking!")
                end
                self.PathTo(self.TargetLoc, self.Speed)
            else
                -- close enough to just directly path to
                self.TargetLoc = self.Path[self.Path_Index]:Add(Loc(math.random()*2-1,0,math.random()*2-1))
                self.PathTo(self.TargetLoc, self.Speed)
            end
            self.SpawnLocation = self.TargetLoc

            if ( self.Returning ) then
                self.Path_Index = self.Path_Index - 1
                if ( self.Path_Index < 1 ) then
                    self.Path_Index = 2
                    self.Returning = false
                    return States.FollowPath.Pause(self)
                end
            else
                self.Path_Index = self.Path_Index + 1
                if ( self.Path_Index > #self.Path ) then
                    if ( self.LoopPath ) then
                        -- looping, start over
                        self.Path_Index = 1
                    else
                        -- ping pong (default) start going back down the path backwards
                        self.Path_Index = #self.Path - 1
                        self.Returning = true
                        return States.FollowPath.Pause(self)
                    end
                end
            end
        end
    end,
    FindClosestPoint = function(self)
        local closest, index = 999999, -1
        for i=1,#self.Path do
            local distance = self.Loc:DistanceSquared(self.Path[i])
            if ( distance < closest ) then
                closest, index = distance, i
            end
        end
        return index
    end,
    Pause = function(self)
        if ( (self.FollowPathPauseMax or 14) <= 0 ) then
            return false
        end

        self.FollowPathSkipNextImmediate = true -- to prevent an immediate schedule on arrival
        self.Schedule(TimeSpan.FromSeconds(math.random(self.FollowPathPauseMin or 6, self.FollowPathPauseMax or 14)))
        return true
    end,
}