-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



Effects.Example = {
    -- icon of effect (optional)
    Icon = "SpellBook05_103",
    -- display name of icon, if not set will use effect name
    DisplayName = "Example Effect",
    -- tool tip to display on icon (optional)
    Tooltip = "Repeat a phrase over and over.",
    -- optional tooltip function
    OnTooltip = function(self)
        return ""
    end,
    -- if the effect a good or a bad effect?
    Debuff = false,
    -- can the effect be canceled? (by clicking the icon)
    Cancelable = false,
    -- total duration of this effect (optional)
    Duration = TimeSpan.FromSeconds(15),
    -- how many times should this pulse? (optional)
    Pulse = 10,
    
    -- should this effect remain after a player and re-logged?
    PersistSession = false,
    -- should this effect remain on death?
    PersistDeath = false,

    -- end the effect when any movement occurs?
    EndOnMovement = false,

    -- handle starting the effect, returning false means the effect failed to start
    OnStart = function(self)
        Effects.Example.OnPulse(self)
        return true
    end,

    -- on pulse will be called each pulse if Pulse is specified
    OnPulse = function(self)
        self.Parent:NpcSpeech("Pulse! " .. (self.Pulses or 0))
    end,

    MaxStacks = 5,
    OnStack = function(self)
        Effect.Refresh(self)
        return true
    end,

    -- called when effect has ended and been removed
    OnStop = function(self, canceled)

    end,
}