-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'inc.weapon_cache'

m_InCombat = this:GetSharedObjectProperty("CombatMode")
m_CurrentTarget = Var.Get(this, "CurrentTarget")

local _queuedAbility = nil
local _isMoving = this:IsMoving()

local _outOfArrows = false
local _bowDrawn = false
local _arrowType = "arrows"
-- a list of arrow types that gets re-ordered when preferred type is changed so that preferred is top of list

local _left = false
-- cache some stuff to check against to prevent re-adding views that already exist.
local _primed = nil
-- When the swing timer goes up, swing is ready.
local _swingReady = true

--[[
RegisterEventHandler(EventType.Message, "CombatDebug", function()
	DebugMessage(_primed)
	DebugMessage(_swingReady)
	if(_isMoving)then
		DebugMessage("_isMoving True")
	else
		DebugMessage("_isMoving False")
	end
	if(_bowDrawn)then
		DebugMessage("mBownDraw True")
	else
		DebugMessage("mBownDraw False")
	end
end)
]]

--- Perform a weapon attack.
-- @param atTarget mobile
function PerformWeaponAttack(atTarget)
	if (
		not m_InCombat
		or
		atTarget == nil
		or
		atTarget == this
		or
		not _swingReady
		or
		Death.Active(this)
		or
		IsMobileDisabled(this)
	) then return end

	if not( Combat.ValidTarget(this, atTarget) )  then
		ClearTarget()
		ResetSwingTimer(0)
		return
	end

	-- handle moving bow men
	if ( m_weapon.IsRanged ) then
		-- dont let archers shoot when they are moving.
		if ( _isMoving ) then return end
	end

	if not( Combat.WithinRange(this, atTarget, m_weapon.Range) ) then
		-- the SetupViews will takecare of restarting this
		return
	end

	if not( Interaction.HasLineOfSight(this, atTarget) ) then
		if ( this:IsPlayer() ) then
			this:SystemMessage("Cannot See Target.", "info")
		end
		-- reset swing timer, can't really trigger on los gained back like we can with range
		ResetSwingTimer(0)
		return
	end

	LookAt(this, atTarget)

	local setWasHidden = false
	if ( _queuedAbility ~= nil and _queuedAbility.AllowCloaked == true and this:IsCloaked() ) then
		this:SetObjVar("WasHidden", true)
		setWasHidden = true
    end
    
    Action.Taken(this, "Swing")
    Action.Taken(atTarget, "SwungAt")

    --[[
	-- dismount them
	if ( _MyOwner ~= nil ) then
		-- dismount pet owners when their pet's do damage
		DismountMobile(_MyOwner)
	else
		DismountMobile(this)
	end]]

	--- perform the actual swing/shoot/w.e.
	if ( m_weapon.IsRanged ) then
		ExecuteRangedWeaponAttack(atTarget)
	else
		ExecuteWeaponAttack(atTarget)
	end

	if ( setWasHidden ) then this:DelObjVar("WasHidden") end
end

function ExecuteRangedWeaponAttack(atTarget, hitSuccessOverride)
	-- if they were out of arrows before, prevent them dropping arrows in their back and fire off a shot without first pulling
	if ( _outOfArrows ) then
		_outOfArrows = false
		ResetSwingTimer(0)
		return
	end
	if ( IsPlayerCharacter(this) and not(IsPossessed(this)) ) then
		-- consume the arrow before any further calculations.
		if ( ConsumeResourceBackpack(this, _arrowType, 1) ) then
			_outOfArrows = false
			ExecuteWeaponAttack(atTarget, true, hitSuccessOverride)
		else
			EndDrawBow()
			FindArrowType(this)
			-- reset swing timer
			ResetSwingTimer(0)
		end
	else
		-- non-players don't consume arrows on ranged attacks (That's loot!)
		ExecuteWeaponAttack(atTarget, true, hitSuccessOverride)
	end
end

RegisterEventHandler(EventType.Message, "ExecuteRangedWeaponAttack", ExecuteRangedWeaponAttack)


--- Performs the actual attack with a weapon, also consumes any queued weapon abilities
-- @param atTarget, mobileObj this weapon attack is being executed against
-- @param hand, string, weapon hand, LeftHand or RightHand
-- @param ranged, bool, (optional) is this a ranged attack?
-- @param hitSuccessOverride, bool, (optional) if supplied hit chance will be based on this value, nil or not provided will calculate the hit chance (or 100% hit chance for queued weapon abilities)
function ExecuteWeaponAttack(atTarget, ranged, hitSuccessOverride)

	if ( ranged ) then
		PerformClientArrowShot(this, atTarget, m_weapon.Object)
		_bowDrawn = false
    else
        -- PerformClientArrowShot calls this internally
        if ( m_swingOffhand ) then
            -- flip between left/right
            PlayAttackAnimation(this, _left and "lattack" or "rattack")
            _left = not _left
        else
            PlayAttackAnimation(this, "rattack")
        end
	end

	-- grunting and stuff
	if ( math.random(1,3) == 1 ) then
		PlayAttackSound(this)
	end

	-- reset swing timer with a delay to drawing any bows ( to allow current attack animations to playout )
    ResetSwingTimer(0, true)
    
    local isTargetPlayer = nil

	local hitSuccess = hitSuccessOverride
	if ( hitSuccess == nil ) then hitSuccess = CheckHitSuccess(atTarget) end
    if ( hitSuccess and _queuedAbility ~= nil ) then
        if ( _queuedAbility.Rage ~= 0 ) then
            this:ScheduleTimerDelay(MINIMUM_TIMESPAN, "PreventRageFromDamage")
        end
        if ( PerformAbility(this, atTarget, _queuedAbility.Name) ) then
            isTargetPlayer = IsPlayerCharacter(atTarget)
            
			if ( _queuedAbility == nil ) then
				LuaDebugCallStack("_queuedAbility is nil where it shouldn't be, ExecuteWeaponAttack is probably being called multiple times in quick succession.")
			end

			-- successfully took the stamina required, apply any mods
			if ( _queuedAbility.QueuedMobileMods ~= nil and not isTargetPlayer ) then
				for k,v in pairs(_queuedAbility.QueuedMobileMods) do
					HandleMobileMod(k, "QueuedAbility", v)
				end
			end
			if ( _queuedAbility.PvPQueuedMobileMods ~= nil and isTargetPlayer ) then
				for k,v in pairs(_queuedAbility.PvPQueuedMobileMods) do
					HandleMobileMod(k, "QueuedAbility", v)
				end
			end
		end
	end

	-- some queued abilities will bypass the normal execute hit action and call it manually, or do whatever is needed for the ability.
	if ( _queuedAbility == nil or _queuedAbility.SkipHitAction ~= true ) then
		if ( hitSuccess ) then
			-- delay it a frame (hackish) to line up with animation swing hits better
			OnNextFrame(function()
				ExecuteHitAction(atTarget)
			end)
		else
			ExecuteMissAction(atTarget)
		end
	end

	if ( hitSuccess and _queuedAbility ~= nil ) then
		-- remove any mods applied from the weapon ability.
		if ( _queuedAbility.QueuedMobileMods ~= nil and not isTargetPlayer ) then
			for k,v in pairs(_queuedAbility.QueuedMobileMods) do
				HandleMobileMod(k, "QueuedAbility", nil)
			end
		end
        if ( _queuedAbility.PvPQueuedMobileMods ~= nil and isTargetPlayer ) then
            for k,v in pairs(_queuedAbility.PvPQueuedMobileMods) do
                HandleMobileMod(k, "QueuedAbility", v)
            end
        end
		if ( hitSuccess ) then
			-- ability was used and we hit, let's clear it.
			ClearQueuedAbility()
		end
	end
end

function ClearQueuedAbility()
	local queuedAbility = _queuedAbility
	_queuedAbility = nil
	if ( queuedAbility and this:IsPlayer() ) then
		-- tell the client to stop 'highlighting' this button
		this:SendClientMessage("SetActionActivated",{"Ability",queuedAbility.Name,false})
	end
end

RegisterEventHandler(EventType.Message, "ClearQueuedAbility", ClearQueuedAbility)

--- Delay the next swing by a TimeSpan
-- @param delay (optional) TimeSpan - The amount of time to delay next swing. If not provided, swing will execute immediately if swing timer does not exist.
function DelaySwingTimer(delay)
    if not( m_InCombat ) then return end
    
    if ( m_weapon.NoCombat ~= true ) then
        local nextSwingIn = this:GetTimerDelay("SWING_TIMER")
        if ( delay ) then
            if ( nextSwingIn == nil ) then
                ResetSwingTimer(delay.TotalSeconds)
            else
                this:ScheduleTimerDelay(delay:Add(nextSwingIn), "SWING_TIMER")
            end
        else
            -- this is to allow passing no delay
            if ( nextSwingIn == nil ) then
                ResetSwingTimer(0)
            end
        end
    end
end

function GetSwingSpeedSeconds()
	local speed = m_weapon.Speed

	if ( m_offhand.Object ~= nil ) then
		speed = speed * ( 1.0 + m_offhand.Speed )
	end

	speed = Modify.Apply(this, "SwingSpeed", speed)
	
	-- speed is really swings per second
	speed = 1.0 / speed

    if ( speed < 0.1 ) then speed = 0.1 end
	if ( speed > 10.0 ) then speed = 10.0 end
	
    return speed
end

function ResetSwingTimer(timeToDelayNextSwing, delayDrawBow)
	if not( m_InCombat ) then return end
	if ( timeToDelayNextSwing == nil ) then timeToDelayNextSwing = 0 end

	EndDrawBow()

	if ( m_weapon.IsRanged ) then
		if ( delayDrawBow ) then
			-- this is a 'hack' to prevent animation from snapping directly to loading a new arrow after firing an arrow.
			-- I call it a hack because I think client should handle that.. But maybe that would be too restrictive for bow speed? -Kade
			CallFunctionDelayed(TimeSpan.FromSeconds(1.45), DrawBow)
		else
			DrawBow()
		end
	end

    -- mark swing as not ready anymore.
    _swingReady = false
    if ( m_weapon.NoCombat ~= true ) then
        this:ScheduleTimerDelay(
            TimeSpan.FromSeconds(GetSwingSpeedSeconds() + timeToDelayNextSwing),
            "SWING_TIMER"
        )
    end
end

------------------------------------------

-- Evalutators
function ValidateCurrentTarget()
	if( m_CurrentTarget == nil ) then return false end
	if not( m_CurrentTarget:IsValid() ) then return false end
	return true
end


function CheckHitSuccess(victim)
    local hitChance = 1.0--0.5
	return Success(hitChance)
end

-- Get Combat Status
function InCombat(obj)
	if ( obj == nil or obj == this ) then
		return m_InCombat
	else
		return IsInCombat(obj)
	end
end

function ExecuteMissAction(atTarget)
	atTarget:NpcSpeech("[08FFFF]*miss*[-]","combat")
	atTarget:SendMessage("SwungOn", this)
	PlayWeaponSound(this, "Miss", m_weapon.Object)
end

function CalculateHitDamage(targetObj)
	local damage = Weapon.ObserveDamage(m_weapon.Template)
	if ( m_offhand.Object ~= nil ) then
		damage = damage * Weapon.ObserveDamage(m_offhand.Template)
	end
	return damage
end

--- This comes after a successful (hitchance) ExecuteWeaponAttack, and applies the weapon damage
-- @param targetObj mobileObj target to execute the hit action against
function ExecuteHitAction(targetObj)
	Equipment.PlayImpactSound(targetObj, m_weapon.Template)
	local damage = Modify.Apply(this, string.format("%sTo", m_weapon.DamageType), CalculateHitDamage(targetObj))
    targetObj:SendMessage("Damage", this, damage, m_weapon.DamageType)
end

RegisterEventHandler(EventType.Message, "ExecuteHitAction", ExecuteHitAction)

function SetCurrentTarget(newTarget, fromClient)

	if ( m_CurrentTarget ~= newTarget ) then
		m_CurrentTarget = newTarget

		if ( m_CurrentTarget ) then
			Var.Set(this, "CurrentTarget", m_CurrentTarget)
		else
			Var.Del(this, "CurrentTarget")
		end

		if( this:IsPlayer() ) then
			ShowTargetElement(this,newTarget)

			if ( not fromClient ) then
				this:SendClientMessage("ChangeTarget", m_CurrentTarget)
			end
		end

		--UpdateSpellTarget(newTarget)		
	end

	if ( m_InCombat ) then
		InitiateCombatSequence()
	end
end
RegisterEventHandler(EventType.Message,"SetCurrentTarget",SetCurrentTarget)

function ClearView()
	if ( _primed ) then
        DelView("AttackRange")
        _primed = nil
	end
end

function EndCombat()
	ClearView()
	SetInCombat(false)
end

function SetupViews()
	if ( m_CurrentTarget ~= nil ) then				
		if ( m_InCombat ) then
			SetupView("RightHand")
		end
	end
end

function SetupView()
	if ( m_CurrentTarget == nil or m_CurrentTarget == this or not InCombat(this) ) then return end

	local range = Combat.GetRange(this, m_CurrentTarget, m_weapon.Range)

	if ( _primed == range ) then
		-- this view already exists, don't need to add it again.
		return
	end

	_primed = range

	AddView("AttackRange", SearchObjectInRange( range ))
end


function SetInCombat(inCombat, force)
    if ( inCombat ~= true ) then inCombat = false end
    
	if ( Death.Active(this) ) then 
		inCombat = false
    end
    
	if( m_InCombat ~= inCombat or force ) then
		m_InCombat = inCombat
		this:SendMessage("CombatStatusUpdate", inCombat)
        this:SetSharedObjectProperty("CombatMode", inCombat)
        ClearQueuedAbility()
			
		if ( m_InCombat == true ) then
            ArcherMinDelay()
            Action.Taken(this, "Combat")
		else
            SetCurrentTarget(nil)
			EndDrawBow()
		end
	end
end

function BeginCombat()
	if ( Death.Active(this) ) then return end
	-- make sure we are in combat! (this function does nothing if you are already in combat)
	SetInCombat(true)
	InitiateCombatSequence()
end

function InitiateCombatSequence()
	if ( Death.Active(this) ) then return end

	if ( _swingReady ) then
		-- swing is ready, do it
		PerformWeaponAttack(m_CurrentTarget)
	elseif not( this:HasTimer("SWING_TIMER") ) then
		-- start swing over
		ResetSwingTimer(0)
	end

	if ( m_CurrentTarget ~= nil ) then
		SetupViews()
	end
end

--EVENT HANDLERS
function HandleAttackTarget(target)
	SetInCombat(true)
	if ( target ~= nil ) then 
		SetCurrentTarget(target)
	end
end


function HandleScriptCommandToggleCombat()
	if ( Death.Active(this) ) then return end

	if ( Ability.Cast.Cancel(this) ) then return end

	-- Enter combat mode if not already
	if not( m_InCombat ) then
		BeginCombat()
	else
		SetInCombat(false)
	end
end

function HandleScriptCommandTargetObject(targetObjId)
	if ( targetObjId == nil ) then SetCurrentTarget(nil, true) return end
	
	local newTarget = GameObj(tonumber(targetObjId))
	if not( newTarget:IsValid() ) then return end
	
	SetCurrentTarget(newTarget,true)
end

function EndDrawBow()
	if ( _bowDrawn ) then
		this:PlayAnimation("end_draw_bow")
		_bowDrawn = false
	end
end

function ClearSwingTimers()
	if ( this:HasTimer("SWING_TIMER") ) then
		this:RemoveTimer("SWING_TIMER")
    end
    _swingReady = false
end

RegisterEventHandler(EventType.Message, "ClearSwingTimers", ClearSwingTimers)

-- Enter attack range of right hand weapon
RegisterEventHandler(EventType.EnterView, "AttackRange", function(obj)
	if ( not m_InCombat or obj ~= m_CurrentTarget ) then return end
	PerformWeaponAttack(m_CurrentTarget)
end)

--Right Hand Swing Timer
RegisterEventHandler(EventType.Timer, "SWING_TIMER", function()
	_swingReady = true
	PerformWeaponAttack(m_CurrentTarget)
end)

RegisterEventHandler(EventType.Message, "ResetSwingTimer", function(delay)
	if not( InCombat(this) ) then return end
	ResetSwingTimer(delay or 0)
end)

RegisterEventHandler(EventType.Message, "DelaySwingTimer", function(delay)
	if not( InCombat(this) ) then return end
	DelaySwingTimer(delay)
end)

function ClearTarget()
	SetCurrentTarget(nil)
	if ( this:IsPlayer() ) then
		this:SendClientMessage("ChangeTarget", nil)
	end
end

function FindArrowType(mobile)
	local backpack = mobile:GetEquippedObject("Backpack")
	if ( backpack ) then		
		if ( FindItemInContainerRecursive(backpack, function(item) return item:GetObjVar("ResourceType") == _arrowType end) ) then
			return true		
		end
	end
	NotifyOutOfArrows(mobile)
	return false
end

function NotifyOutOfArrows(mobile)
	if not( mobile:HasTimer("OutOfArrows") ) then
		mobile:SystemMessage("Out of arrows.", "info")
		mobile:ScheduleTimerDelay(TimeSpan.FromSeconds(4), "OutOfArrows")
	end
end

function DrawBow()
	if ( 
		not m_weapon.IsRanged
		or
		_bowDrawn
		or
		_isMoving
		or
		not m_InCombat
		and
		not IsMobileDisabled(this)
	) then
		return false
	end

	if ( IsPlayerCharacter(this) and not(IsPossessed(this)) and not(FindArrowType(this)) ) then
		_outOfArrows = true
		return false
	end

	-- have the client character pull and hold the bow
	this:PlayAnimation("draw_bow")
	_bowDrawn = true
	PlayWeaponSound(this, "Load", m_weapon.Object)

	return true
end

--Movement Handler
local _OnStartMoving = OnStartMoving
function OnStartMoving()
    _OnStartMoving()

	Ability.Cast.Cancel(this, true)
	
	if ( _isMoving ) then return end
	_isMoving = true
	EndDrawBow()
end


function OnStopMoving()
	if ( not _isMoving ) then return end
	_isMoving = false
	ArcherMinDelay()
end

RegisterEventHandler(EventType.StopMoving, "", OnStopMoving)

function ArcherMinDelay()
	if ( m_InCombat ) then

		if ( m_weapon.IsRanged ) then
			if ( DrawBow() ) then
				if ( _swingReady ) then
                    -- swing is ready, fire in min delay
                    _swingReady = false
					this:ScheduleTimerDelay(ServerSettings.Combat.BowStopMinDelay, "SWING_TIMER")
				else
					-- swing is not ready, fire in time left (if greater than min) or min
					local delay = ServerSettings.Combat.BowStopMinDelay
					local timerDelay = this:GetTimerDelay("SWING_TIMER")
					if ( timerDelay ~= nil and timerDelay > ServerSettings.Combat.BowStopMinDelay ) then
						delay = timerDelay
					end
					this:ScheduleTimerDelay(delay, "SWING_TIMER")
				end
			else
				--failed to draw bow (out of arrows?) try again later.
				ResetSwingTimer(0)
			end

			if ( m_CurrentTarget ~= nil  ) then
				LookAt(this, m_CurrentTarget)
			end
		end
	end
end

RegisterEventHandler(EventType.Message, "EndCombatMessage", function()
	SetInCombat(false)
end)

RegisterEventHandler(EventType.Message, "ForceCombat", function(target)
	if ( target ) then
		SetCurrentTarget(target)
	end
	if ( m_InCombat ~= true ) then
		SetInCombat(true)
		BeginCombat()
	end
end)

local one_frame_timer = TimeSpan.FromMilliseconds(1)
RegisterEventHandler(EventType.ItemEquipped, "", function(item)
	if ( item == nil ) then return end
	local slot = Equipment.GetSlot(item)
	if ( slot == "Mount" ) then return end

	Ability.Cast.Cancel(this)
	
	Action.Taken(this, "Equipment", "Equipped")

	if ( slot == "RightHand" or slot == "LeftHand" ) then
		-- weapon was equipped, clear queued abilities.
		-- update reference to our weapons
		UpdateWeapon(item, slot == "LeftHand")
	end
	
	ClearQueuedAbility()
	ClearSwingTimers()
	if ( m_InCombat ) then
		this:ScheduleTimerDelay(one_frame_timer, "ResumeCombat")
	end
end)

RegisterEventHandler(EventType.ItemUnequipped, "", function(item)
	if ( item == nil ) then return end
	local slot = Equipment.GetSlot(item)
	if ( slot == "Mount" ) then return end

    Ability.Cast.Cancel(this)

	Action.Taken(this, "Equipment", "Unequipped")
    
    if ( slot == "RightHand" or slot == "LeftHand" ) then
        -- delete the view if it exists
        if ( _primed ) then
            DelView("AttackRange", hand)
            _primed = nil
        end

		
		UpdateWeapon(nil, slot == "LeftHand")
	end
	
	ClearQueuedAbility()
	ClearSwingTimers()
	if ( m_InCombat ) then
		this:ScheduleTimerDelay(one_frame_timer, "ResumeCombat")
	end
end)

-- resume swinging after resetting timers (on next frame)
RegisterEventHandler(EventType.Timer, "ResumeCombat", function()
	if ( m_InCombat ) then
		InitiateCombatSequence()
	end
end)

RegisterEventHandler(EventType.ClientUserCommand, "targetObject", function(...) HandleScriptCommandTargetObject(...) end)
RegisterEventHandler(EventType.ClientUserCommand, "toggleCombat", function(...) HandleScriptCommandToggleCombat(...) end)

RegisterEventHandler(EventType.Message, "ClearTarget", function(...) ClearTarget(...) end)
RegisterEventHandler(EventType.Message, "AttackTarget", function(...) HandleAttackTarget(...) end)
RegisterEventHandler(EventType.Message, "ExecuteMissAction", function(...) ExecuteMissAction(...) end)
RegisterEventHandler(EventType.Message, "ExecuteWeaponAttack", function(...) ExecuteWeaponAttack(...) end)

-------------INITIALIZERS

if ( m_InCombat ) then
    EndCombat()
end

if ( this:HasObjVar("WasHidden") ) then
	this:DelObjVar("WasHidden")
end


RegisterEventHandler(EventType.Message, "QueueAbility", function(ability)
    local abilityData = Ability.GetData(ability)
    if ( _queuedAbility ) then
        if ( this:IsPlayer() ) then
            if ( _queuedAbility.Action and _queuedAbility.Action.Icon ) then
                -- anytime _queuedAbility is set, we clear it when it's called. This works like a toggle.
                this:SendClientMessage("SetActionActivated",{"Ability",_queuedAbility.Name,false})
                this:SystemMessage(_queuedAbility.Action.DisplayName.." canceled.","info")
            end
        end
        -- 'activated' one that was already active. Clear it and stop here
        if ( _queuedAbility.Name == ability ) then
            _queuedAbility = nil
            return
        end
    end
    
    if not( Ability.HasResource(abilityData, this, true) ) then return false end

    _queuedAbility = abilityData
    _queuedAbility.Name = ability
    if ( this:IsPlayer() ) then
        if ( _queuedAbility.Action and _queuedAbility.Action.Icon ) then
            this:SendClientMessage("SetActionActivated",{"Ability",_queuedAbility.Name,true})
        end
        if ( m_InCombat == false ) then
            BeginCombat()
        end
    end
end)