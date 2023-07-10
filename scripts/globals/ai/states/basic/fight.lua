-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Fight = {
    Name = "Fight",
    Init = function(self)
        if ( self.RangedWeapon == nil ) then
            self.RangedWeapon = Weapon.IsRanged("Weapon", AIProperty.GetTable(self.Template))
        end
        if not( self.WeaponRange ) then
            self.WeaponRange = Weapon.GetRange("Weapon", AIProperty.GetTable(self.Template))
        end
        if not( self.BodySize ) then
            self.BodySize = GetBodySize(self.Parent)
        end
        if not( self.DamageType ) then
            self.DamageType = Weapon.GetDamageType("Weapon", AIProperty.GetTable(self.Template))
        end
        self.AttackLeft = false
        -- start as ready to attack
        self.AttackReady = true
    end,
    EnterState = function(self)
        -- set in combat
        self.Parent:SetSharedObjectProperty("CombatMode", true)
        RegisterEventHandler(EventType.Timer, "AutoAttack", function()
            self.AttackReady = true
            self.ScheduleImmediate()
        end)
        -- if not ready to attack and no timer, reset attack timer
        if ( not self.AttackReady and not self.Parent:HasTimer("AutoAttack") ) then
            States.Fight.ResetAutoAttack(self)
        end
        -- reset the swing timer from outside
        RegisterEventHandler(EventType.Message, "ResetSwingTimer", function(delay)
            States.Fight.ResetAutoAttack(self)
        end)
    end,
    ExitState = function(self)
        -- remove from combat state
        self.Parent:SetSharedObjectProperty("CombatMode", false)
        UnregisterEventHandler("",EventType.Timer,"AutoAttack")
        UnregisterEventHandler("",EventType.Message,"ResetSwingTimer")
    end,
    ShouldRun = function(self)
        return ( self.CurrentTarget ~= nil )
    end,
    Run = function(self)
        if ( self.ValidCombatTarget(self.CurrentTarget) ) then
            if not( self.Parent:HasPath() ) then
                self.PathFollow(self.CurrentTarget, self.WeaponRange)
            end
            local distance = self.WeaponRange + GetBodySize(self.CurrentTarget)
            if ( self.AttackReady and self.Parent:DistanceFrom(self.CurrentTarget) <= distance ) then
                States.Fight.PerformAttack(self)
            end
        else
            self.SetTarget(nil)
        end
    end,


    --- fight state specific functions
    ResetAutoAttack = function(self)
        self.AttackReady = false
        local delay = TimeSpan.FromSeconds(1.0 / Weapon.GetSpeed("Weapon", AIProperty.GetTable(self.Template)))
        self.Parent:ScheduleTimerDelay(delay, "AutoAttack")
    end,
    PerformAttack = function(self)
        if (
            not self.CurrentTarget
            or
            not self.AttackReady
            or
            IsMobileDisabled(self.Parent)
        ) then return end

        if not( self.ValidCombatTarget(self.CurrentTarget) ) then
            self.SetTarget(nil)
            return
        end

        if not( Interaction.HasLineOfSight(self.Parent, self.CurrentTarget) ) then
            return
        end
        
        Action.Taken(self.CurrentTarget, "SwungAt")

        if ( self.RangedWeapon ) then
            PerformClientArrowShot(self.Parent, self.CurrentTarget)
        else
            PlayAttackAnimation(self.Parent, self.AttackLeft and "lattack" or "rattack")
        	self.AttackLeft = not self.AttackLeft
        end

        LookAt(self.Parent, self.CurrentTarget)

        -- grunting and stuff
        if ( math.random(1,3) == 1 ) then
            PlayAttackSound(self.Parent)
        end

        Equipment.PlayImpactSound(self.CurrentTarget, "Weapon", AIProperty.GetTable(self.Template))

        local damage = Modify.Apply(self.Parent, string.format("%sFrom", self.DamageType), Weapon.ObserveDamage("Weapon", AIProperty.GetTable(self.Template)))

        self.CurrentTarget:SendMessage("Damage", self.Parent, damage, self.DamageType)

        States.Fight.ResetAutoAttack(self)
    end,

}