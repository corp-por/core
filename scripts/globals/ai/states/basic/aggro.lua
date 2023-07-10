-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Aggro = {
    Name = "Aggro",
    OnAggro = function(self, damager, amount)
        if ( damager and Var.Get(damager, "MobileTeamType") ~= self.TeamType ) then
            if not( self.AggroList[damager] ) then self.AggroList[damager] = 0 end
            self.AggroList[damager] = self.AggroList[damager] + (amount or 1)
            if ( self.AggroMost[2] < self.AggroList[damager] ) then
                self.AggroMost = {damager, self.AggroList[damager]}
            end
        end
        
        -- attack the damager with the most aggro
        if ( self.AggroMost[1] and self.AggroMost[1] ~= self.CurrentTarget and self.ValidCombatTarget(self.AggroMost[1]) ) then
            self.SetTarget(self.AggroMost[1])
            self.Pulse()
        end
    end,
    Init = function(self)
        self.AggroList = {}
        self.AggroMost = {nil,0}
        RegisterEventHandler(EventType.Message, "Damage", function(damager, amount)
            States.Aggro.OnAggro(self, damager, amount)
        end)
        RegisterEventHandler(EventType.Message, "SwungOn", function(attacker)
            States.Aggro.OnAggro(self, attacker)
        end)
        RegisterEventHandler(EventType.Message, "AddAggro", function(attacker, amount)
            States.Aggro.OnAggro(self, attacker, amount)
        end)
        RegisterEventHandler(EventType.Message, "Died", function(attacker, amount)
            self.AggroList = {}
            self.AggroMost = {nil,0}
        end)
        RegisterEventHandler(EventType.Message, "Taunt", function(taunter)
            self.AggroList = {}
            self.AggroMost = {taunter,20}
            self.SetTarget(taunter)
            self.Pulse()
        end)
    end,
}