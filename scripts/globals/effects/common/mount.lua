-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



Effects.Mount = {
    Icon = "SpellBook05_103",
    DisplayName = "Mount",
    OnTooltip = function(self)
        return "Increase movement speed by " .. (self.SpeedModifier * 100) .. "%."
    end,
    Cancelable = true,
    PersistSession = true,
    PersistDeath = false,
    NoSwim = true,

    -- handle starting the effect, returning false means the effect failed to start
    OnStart = function(self)
        if ( self.MountDNAString == nil ) then
            self.MountDNAString = "EquipmentHorseMount"
        end
        if ( self.SpeedModifier == nil ) then
            self.SpeedModifier = 0.1
        end

        self.Parent:SendMessage("EndCombatMessage")

        -- only do animation mounted on a horse
        self.PoseType = self.MountDNAString == "EquipmentHorseMount" and "Mounted" or "StaticMounted"
        
        self.Parent:SetSharedObjectProperty("Pose", self.PoseType)
        AddMountDNA(self.Parent, self.MountDNAString)

        Modify.Factor(self.Parent, "MoveSpeed", "Mount", self.SpeedModifier)

        return true
    end,

    -- called when effect has ended and been removed
    OnStop = function(self, canceled)
        if ( self.Parent:GetSharedObjectProperty("Pose") == self.PoseType ) then
            self.Parent:SetSharedObjectProperty("Pose", "")
        end
        ClearMountDNA(self.Parent)
        Modify.Del(self.Parent, "MoveSpeed", "Mount")
    end,
}