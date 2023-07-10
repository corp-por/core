-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.SummonFollow = {
    Name = "SummonFollow",
    Init = function(self)
        self.Owner = Var.Get(self.Parent, "controller")

        self._ValidCombatTarget = self.ValidCombatTarget
        self.ValidCombatTarget = function(target)
            if ( self._ValidCombatTarget(target) ) then
                return not ShareGroup(self.Owner, target) 
            end
        end

        RegisterEventHandler(EventType.Message, "DefendController", function(target)
            self.CurrentTarget = target
            self.PathClear()
            -- react to the new target asap
            self.ScheduleImmediate()
        end)
    end,
    ShouldRun = function(self)
        return ( self.CurrentTarget == nil or self.Loc:Distance(self.Owner:GetLoc()) >= 15 )
    end,
    EnterState = function(self)
        self.CurrentTarget = nil
        self.PathClear()
    end,
    Run = function(self)
        if ( self.Parent:GetPathTarget() ~= self.Owner ) then
            self.PathFollow(
                self.Owner,
                ServerSettings.Pets.Follow.Distance,
                IsMounted(self.Owner) and
                    -- go mount speed
                    ServerSettings.Pets.Follow.Speed.Mounted
                or
                    ServerSettings.Pets.Follow.Speed.OnFoot
            )
        end
    end,
}