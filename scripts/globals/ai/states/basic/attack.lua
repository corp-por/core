-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Attack = {
    Name = "Attack",
    Init = function(self)
        if not( self.BodySize ) then
            self.BodySize = GetBodySize(self.Parent)
        end
    end,
    ShouldRun = function(self)
        -- already have a target, no reason to seek one
        if ( self.CurrentTarget ~= nil and not Death.Active(self.CurrentTarget) ) then return false end

        self.AttackTarget = nil
        local loc, d, ld
        local nearbyMobile
        local nearbyEnemies = FindObjects(
            SearchOtherMobileTeamTypeInRange(self.BodySize + (self.AttackRange or 10), self.CanSeeInvis or false)
        )
        for i=1,#nearbyEnemies do
            nearbyMobile = nearbyEnemies[i]
            if (
                Interaction.HasLineOfSight(self.Parent, nearbyMobile)
                and
                self.ValidCombatTarget(nearbyMobile)
            ) then
                loc = nearbyMobile:GetLoc()
                d = self.Loc:Distance(loc)
                -- super close or in field of view
                if ( d <= (self.BodySize + 4) or math.abs( self.Parent:GetFacing() - self.Loc:YAngleTo(loc) ) < 90 ) then
                    -- closer than any others
                    if ( ld == nil or d < ld ) then
                        self.AttackTarget = nearbyMobile
                        ld = d
                    end
                end
            end
        end
        return ( self.AttackTarget ~= nil )
    end,
    Run = function(self)
        if ( self.AttackTarget ~= nil ) then
            self.SetTarget(self.AttackTarget)
            self.AttackTarget = nil
            
            self.ScheduleImmediate()
            return true -- prevent default schedule post run
        end
    end,
}