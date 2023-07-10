-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Ability = {}

function Ability.GetData(ability)
    local data = Abilities[ability]
    if ( data ) then return data end
    LuaDebugCallStack(string.format("Invalid Ability Provided: '%s'", ability))
end

function Ability.DisplayName(ability, data)
    if not( data ) then data = Ability.GetData(ability) end
    if ( data and data.Action and data.Action.DisplayName ) then
        return data.Action.DisplayName
    end
    return ability
end


--- Convenience function to help when debugging an NPC performing Abilities.
-- @param message(string) The error message
-- @param mobileObj(mobileObj) The mobile that was performing the ability that caused the error
-- @param isPlayer(boolean) true is mobileObj is a player, false otherwise.
-- @return false
function Ability.Error(message, mobileObj, isPlayer)
	if ( isPlayer ) then
        mobileObj:SystemMessage(message)
    else
        --mobileObj:NpcSpeech(message)
	end
	--DebugMessage(mobileObj, message)
	return false
end

Ability.Hook = {}
function Ability.Hook.Perform(playerObj, targetObj, ability, castComplete, abilityData, isPlayer)
    return true
end

function Ability.HasResource(abilityData, playerObj, isPlayer)
    return true
end

-- prevent insta-casting a Queued ability
function Ability.SafePerform(playerObj, targetObj, ability)
    if ( Abilities[ability] == nil ) then return end
    if ( Abilities[ability].Queued ) then
        playerObj:SendMessage("QueueAbility", ability)
    elseif not( Abilities[ability].SubAbility ) then
        Ability.Perform(playerObj, targetObj, ability, false)
    end
end

function Ability.Perform(playerObj, targetObj, ability, castComplete, consumeObj)
    local isPlayer = IsPlayerCharacter(playerObj)
	local abilityData = Ability.GetData(ability)

    if ( isPlayer ) then
        if ( IsMobileDisabled(playerObj) ) then
            if ( abilityData.AllowDisabled ~= true ) then
                return Ability.Error("Cannot do that right now.", playerObj, isPlayer)
            end
        end
    end

    if ( abilityData.AllowDead ~= true and Death.Active(playerObj) ) then
        return Ability.Error("Cannot do that right now.", playerObj, isPlayer)
    end
    
    if ( (abilityData.Cooldown ~= nil or abilityData.CooldownFunc ~= nil) and playerObj:HasTimer(ability.."Cooldown") ) then
        if ( abilityData.CooldownSilent ) then return false end
        return Ability.Error(Ability.DisplayName(ability, abilityData) .. " is on cooldown.", playerObj, isPlayer)
    end

    if not( Ability.Hook.Perform(playerObj, targetObj, ability, castComplete, abilityData, isPlayer) ) then
        return false
    end

    -- ensure has resources
    if not( Ability.HasResource(abilityData, playerObj, isPlayer) ) then return false end

    if ( abilityData.CustomRequire ) then
        local success, error = abilityData.CustomRequire(playerObj)
        if not( success ) then
            if ( error ~= nil ) then
                Ability.Error(error, playerObj, isPlayer)
            end
            return false
        end
    end

    -- trigger an action taken (break invisibility and similar)
    Action.Taken(playerObj, "Ability", ability)

    if ( castComplete ~= true ) then
        if ( abilityData.CastTime ~= nil ) then
            -- when an ability has a cast timer, and the cast is not complete
            Ability.Cast.Begin(playerObj, ability, abilityData, targetObj, consumeObj)
            return true
        else
            -- or if we need to request a target
            if ( abilityData.RequestTarget ) then
                Ability.Cast.Complete(playerObj, ability, targetObj, abilityData, false, consumeObj)
                return true
            end
        end
    end

    if not( Ability.ValidateTarget(playerObj, targetObj, abilityData, isPlayer) ) then
        -- if the cast is done but the target failed, request a new target
        if ( isPlayer and castComplete == true ) then
            Ability.Cast.Complete(playerObj, ability, nil, abilityData, true, consumeObj)
        end
        return false
    end

    -- Consume the resources
    if not( Ability.ConsumeResource(abilityData, playerObj, isPlayer) ) then
        return false
    end

    if ( consumeObj ~= nil ) then
        if not( consumeObj:IsValid() ) then
            return Ability.Error("Item is no longer valid.")
        end
		if ( Stackable.Is(consumeObj) ) then
            if not( Stackable.Adjust(consumeObj, -1) ) then
                return Ability.Error("Failed to consume item.")
            end
		else
			consumeObj:Destroy()
		end
    end
    
    -- force combat mode cause used ability.
    if not( abilityData.NoCombat == true ) then
        playerObj:SendMessage("ForceCombat")
    end

    -- interrupt the target if this ability allows
    if ( targetObj ~= nil and abilityData.SpellInterrupt == true ) then
        --CheckSpellCastInterrupt(targetObj) --TODO
    end

    -- if the ability has a mobile effect for the mobile doing the ability
    if ( abilityData.Effect ~= nil ) then
        -- apply the effect to that mobile
        Effect.Apply(playerObj, abilityData.Effect, (abilityData.EffectArgs or {}), targetObj)
    end
    -- if the ability has a mobile effect for a target
    if ( targetObj ~= nil and abilityData.TargetEffect ~= nil and abilityData.RequireLocationTarget ~= true ) then
        -- apply the effect to the target.
        --- a message is required as to run the effect within the target's script module
        targetObj:SendMessage("ApplyEffect", abilityData.TargetEffect, (abilityData.TargetEffectArgs or {}), playerObj)
    end

    if ( isPlayer and abilityData.Cooldown ~= nil ) then
        Ability.StartCooldown(playerObj, ability, abilityData.CooldownFunc and abilityData.CooldownFunc(playerObj) or abilityData.Cooldown)
    end

    return true

end

--- Initiate the cooldown for an ability
-- @param playerObj
-- @param position
-- @param cooldown TimeSpan
function Ability.StartCooldown(playerObj, ability, cooldown)
	if ( playerObj == nil ) then
		return LuaDebugCallStack("nil playerObj provided.")
	end
    playerObj:ScheduleTimerDelay(cooldown, ability.."Cooldown")
    
	playerObj:SendClientMessage("ActivateCooldown", {
		"Ability",
		ability,
		cooldown.TotalSeconds
	})
end

--- Reset the cooldown for an ability
-- @param playerObj
-- @param position
function Ability.ResetCooldown(playerObj, ability)
	local timerId = ability.."Cooldown"
	if ( playerObj:HasTimer(timerId) ) then

		-- a timer exists, so the client should prevent the button, let's fix that
		playerObj:SendClientMessage("ActivateCooldown", {
			"Ability",
			ability,
			0
		})
		-- then clear the timer
		playerObj:RemoveTimer(timerId)
	end
end

function Ability.ConsumeResource( abilityData, playerObj, isPlayer )
    if ( abilityData.NoConsume == true ) then
        -- some abilites (like casting a spell) need to check for resources without taking them
        return true
    end
    
    if ( isPlayer and abilityData.Reagent ) then
        if not( Ability.ConsumeReagent(playerObj, abilityData, false) ) then
            return false
        end
    end

    return true
end

-- only used for players
function Ability.ConsumeReagent(playerObj, abilityData, dryRun)
    local backpack = Backpack.Get(playerObj)
    if not( backpack ) then return false end
    
    -- TODO:

    return true
end

function Ability.ValidateTarget(playerObj, targetObj, abilityData, isPlayer)
    if ( abilityData.RequireLocationTarget ) then
        -- Need line of sight
        if not( abilityData.NoLos ) then
            if not( Interaction.HasLineOfSightToLoc(playerObj, targetObj) ) then
                return Ability.Error("Cannot see target.", playerObj, isPlayer)
            end
        end

        -- check distance
        if ( playerObj:GetLoc():Distance(targetObj) > (abilityData.Range or 1) ) then
            return Ability.Error("Too far away.", playerObj, isPlayer)
        end
    end
    
    -- when an ability requires a target, validate we have a target.
    if ( abilityData.RequireTarget or abilityData.RequireCombatTarget or abilityData.RequireDeadTarget or abilityData.RequireValidFriendlyTarget ) then
        if ( targetObj == nil ) then
            return Ability.Error("Target is required.", playerObj, isPlayer)
        end
        
        LookAt(playerObj, targetObj)

        -- Need line of sight
        if not( abilityData.NoLos ) then
            if not( Interaction.HasLineOfSight(playerObj, targetObj) ) then
                return Ability.Error("Cannot see target.", playerObj, isPlayer)
            end
        end

        -- require dead target
        if ( abilityData.RequireDeadTarget and not Death.Active(targetObj) ) then
            return Ability.Error("Target must be dead.", playerObj, isPlayer)
        end
        
        -- prevent trying to apply a non stacking effect multiple times
        if ( abilityData.TargetEffect ~= nil and not Effects[abilityData.TargetEffect].OnStack ~= nil and Effect.Has(targetObj, abilityData.TargetEffect) ) then
            return Ability.Error("Target already affected.", playerObj, isPlayer)
        end
        
        -- required combat target, validate the target is valid combat target.
        if ( abilityData.RequireCombatTarget and not Combat.ValidTarget(playerObj, targetObj) ) then
            return Ability.Error("Invalid target.", playerObj, isPlayer)
        end

        -- default all RequireTarget abilities to require a valid range of the weapon
        -- but if Range is set, use that to calculate instead.
        if ( (abilityData.Range ~= nil and not Combat.WithinRange(playerObj, targetObj, abilityData.Range)) 
            or (abilityData.Range == nil and not Combat.WithinWeaponRange(playerObj, targetObj)) ) then
            return Ability.Error("Too far away.", playerObj, isPlayer)
        end
    end

    return true
end


--[[
    Start Casting
]]

Ability.Cast = {}

function Ability.Cast.Begin(playerObj, ability, abilityData, target, consumeObj)
    if not( playerObj:HasTimer("CastAbility") ) then
        local isPlayer = IsPlayerCharacter(playerObj)

        if ( isPlayer and playerObj:IsMoving() ) then
            return Ability.Error("Must be stopped to cast.", playerObj, isPlayer)
        end

		if ( abilityData.PreCast ~= nil ) then
			abilityData.PreCast(playerObj, abilityData)
        end

        if ( abilityData.AllowPushback ) then
            playerObj:SendMessage("ResetAbilityCastPushback")
        end

        Modify.Set(playerObj, "Busy", "Casting", true)

        Ability.Cast.Timer(playerObj, ability, abilityData, target, consumeObj)
	end
end

function Ability.Cast.Timer(playerObj, ability, abilityData, target, consumeObj, timer, isRefresh)
    if not( ability ) then
        local timerArgs = playerObj:GetTimerArgs("CastAbility")
        if ( timerArgs ) then
            ability = timerArgs[1]
            target = timerArgs[2]
            consumeObj = timerArgs[3]
        end
    end
    if ( timer == nil ) then
        timer = abilityData.CastTime
    end

    if ( ability ) then
        if not( abilityData ) then
            abilityData = Ability.GetData(ability)
        end
        
        playerObj:StopCastbar()
        local icon = abilityData.Action and abilityData.Action.Icon or nil
        if ( icon == nil ) then
            icon = "SpellBook02_86"
        end

        playerObj:Castbar(icon, timer.TotalSeconds, isRefresh or false)

        if ( 
            (
                abilityData.RequireLocationTarget
                or
                abilityData.RequireTarget
                or
                abilityData.RequestTarget
                or
                abilityData.RequireCombatTarget
                or
                abilityData.RequireDeadTarget
                or
                abilityData.RequireValidFriendlyTarget
            )
            and
            IsPlayerCharacter(playerObj)
        ) then
            playerObj:SendClientMessage("StartCasting", timer.TotalSeconds)
        end

        playerObj:ScheduleTimerDelay(timer, "CastAbility", ability, target, consumeObj) 
    end
end

function Ability.Cast.TryPushback(playerObj, delay)
    local timerArgs = playerObj:GetTimerArgs("CastAbility")
    if ( timerArgs ) then
        local abilityData = Ability.GetData(timerArgs[1])
        if ( abilityData.AllowPushback ) then
            local castTimer = TimeSpan.FromSeconds(playerObj:GetTimerDelay("CastAbility").TotalSeconds + delay)
            Ability.Cast.Timer(playerObj, timerArgs[1], abilityData, timerArgs[2], timerArgs[3], castTimer, true)
            return true
        end
    end
    return false
end

function Ability.Cast.Complete(playerObj, ability, target, abilityData, requestNewTarget, consumeObj)
    Modify.Del(playerObj, "Busy", "Casting")

    if ( abilityData == nil ) then
        abilityData = Ability.GetData(ability)
    end

    if ( 
        requestNewTarget
        or
        abilityData.RequireLocationTarget
        or
            (
                (target == nil or playerObj:HasObjVar("NoAutoTarg"))
                and
                abilityData.RequestTarget and IsPlayerCharacter(playerObj)
            )
        )
    then
        playerObj:SendMessage("AbilityReadyToRelease", ability)
        if ( abilityData.RequireLocationTarget ) then
            playerObj:RequestClientTargetLoc(playerObj, "SelectAbilityTargetLoc")
        else
            playerObj:RequestClientTargetGameObj(playerObj, "SelectAbilityTarget")
        end
    else
        playerObj:SendMessage("AbilityReadyToRelease") -- clear ability ready to release
        Ability.Perform(playerObj, target or Var.Get(playerObj, "CurrentTarget"), ability, true, consumeObj)
    end

	if ( abilityData.CastTime ~= nil and abilityData.PostCast ) then
		abilityData.PostCast(playerObj)
	end
end

function Ability.Cast.Cancel(playerObj, keepCurrentLoadedAbility)
    if ( playerObj:HasTimer("CastAbility") ) then
        
        if ( IsPlayerCharacter(playerObj) ) then
            playerObj:SendClientMessage("StartCasting", 0)
        end

        local ability
        local timerArgs = playerObj:GetTimerArgs("CastAbility")
        if ( timerArgs ) then
            ability = timerArgs[1]
        end
        
        Modify.Del(playerObj, "Busy", "Casting")
        playerObj:RemoveTimer("CastAbility")
        playerObj:StopCastbar()

        if not( keepCurrentLoadedAbility ) then
            playerObj:SendMessage("AbilityReadyToRelease")
        end
        
        if ( ability ) then
            local abilityData = Ability.GetData(ability)
            if ( abilityData and abilityData.PostCast ) then
                abilityData.PostCast(playerObj, true)
            end
        end
        
        return true
    else
        if not( keepCurrentLoadedAbility ) then
            playerObj:SendMessage("AbilityReadyToRelease")
        end
	end
	return false
end

--[[
    End Casting
]]