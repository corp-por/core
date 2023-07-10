-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



States.FightAdvanced = {
    Name = "FightAdvanced",
    Init = function(self)
        -- call base fight
        States.Fight.Init(self)
        FSMHelper.AbilityInit(self)
        self.FightAdvancedList = {}
        if ( self.Abilities ) then
            self.FightAdvancedList[#self.FightAdvancedList+1] = function()
                FSMHelper.RandomAbility(self, math.random(self.AbilityMin or 4, self.AbilityMax or 8))
            end
        end
    end,
    EnterState = States.Fight.EnterState,
    ExitState = States.Fight.ExitState,
    ShouldRun = States.Fight.ShouldRun,
    Run = function(self)
        -- call base fight
        States.Fight.Run(self)
        if not( self.CurrentTarget ) then return end

        if ( #self.FightAdvancedList > 0 ) then
            if ( #self.FightAdvancedList == 1 ) then
                self.FightAdvancedList[1]()
            else
                self.FightAdvancedList[math.random(1,#self.FightAdvancedList)]()
            end
        end
    end,
}