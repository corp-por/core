-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.ChargeToLocation = {
    Name = "ChargeToLocation",
    --[[
    Init = function(self)
        if not( self.ChargeLocation ) then
            self.ChargeLocation = Loc(0,0,0)
            self.ChargeLocation:Fix()
        end
    end,
    ]]
    ShouldRun = function(self)
        return self.ChargeLocation ~= nil and self.Loc:Distance(self.ChargeLocation) > 1.0
    end,
    Run = function(self)
        if not( self.Parent:HasPath() ) then
            self.SetTarget(nil)
            self.PathTo(self.ChargeLocation, (self.ChargeSpeed or 5))
        end
    end,
}