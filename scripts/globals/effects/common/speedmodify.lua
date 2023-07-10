-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Effects.SpeedModify = {
    Icon = "SpellBook05_103",
    DisplayName = "Speed Potion",
    Duration = TimeSpan.FromSeconds(10),
    Cancelable = true,

    OnStart = function(self)
        self.Parent:NpcSpeech("SPEED!")
        if ( self.Modifier ~= nil ) then
            Effects.SpeedModify.ApplyMod(self)
            return true
        end

        return false
    end,

    MaxStacks = 5,
    OnStack = function(self)
        Effects.SpeedModify.ApplyMod(self)
        Effect.Refresh(self)
        return true
    end,

    OnStop = function(self, canceled)
        Modify.Del(self.Parent, "MoveSpeed", "SpeedModify")
    end,

    -- this function is specific to this effect and allows us to not duplicate logic
    ApplyMod = function(self)
        local amount = self.Modifier * (self.Stacks or 1)
        Modify.Factor(self.Parent, "MoveSpeed", "SpeedModify", amount)
        self.Tooltip = "Speed increased by "..(amount * 100).."%"
    end
}