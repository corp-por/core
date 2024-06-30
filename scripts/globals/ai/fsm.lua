-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- Finite State Machine for NPC AI/Brains


local FSM_DEFAULT_PULSE_RATE = TimeSpan.FromMilliseconds(500)
local FSM_DEFAULT_SLEEP_RANGE = 50
local FSM_DEFAULT_SLEEP_DELAY = TimeSpan.FromSeconds(2)
local FSM_DEFAULT_PATH_TIMEOUT = TimeSpan.FromSeconds(10)

MINIMUM_TIMESPAN = TimeSpan.FromMilliseconds(1)

function FSM(parentObj, states, pulseRate, sleepDelay)

    local paused = true

    -- allow all brains to be paused
    table.insert(states, 1, States.Pause)

    local self = {
        Parent = parentObj,
        States = states,
        PulseRate = pulseRate and TimeSpan.FromSeconds(pulseRate) or FSM_DEFAULT_PULSE_RATE,
        SleepDelay = sleepDelay and TimeSpan.FromSeconds(sleepDelay) or FSM_DEFAULT_SLEEP_DELAY,
        MoveSpeedPlus = 0,
        MoveSpeedTimes = 1,
        CurrentTarget = nil,
        AllowSleeping = true,
        PreviousStateIndex = 1,
        Template = Object.TemplateId(parentObj),
        Debug = false
    }
  
    function self.Pulse()
        if ( not self.Parent or not self.Parent:IsValid() ) then return end
        if ( self.AllowSleeping == true and not self.Debug and not(FindObject(SearchPlayerInRange(self.SleepRange or FSM_DEFAULT_SLEEP_RANGE, true))) ) then
            if not( paused ) then
                paused = true
                for i=1,#self.States do
                    if ( self.States[i].OnPause ) then self.States[i].OnPause(self) end
                end
            end
            self.Schedule(self.SleepDelay:Add(TimeSpan.FromMilliseconds(math.random(100,500))))
            return
        end
        if ( paused ) then
            paused = false
            for i=1,#self.States do
                if ( self.States[i].OnResume ) then self.States[i].OnResume(self) end
            end
        end
        self.Loc = self.Parent:GetLoc()
        for i=1,#self.States do
            if ( self.States[i].ShouldRun ~= nil and self.States[i].ShouldRun(self) ) then
                if ( self.StateIndex and self.States[self.StateIndex].Name ~= self.States[i].Name ) then
                    if ( self.States[self.StateIndex] and self.States[self.StateIndex].ExitState ) then
                        self.States[self.StateIndex].ExitState(self)
                    end
                end
                if ( not self.StateIndex or self.States[self.StateIndex].Name ~= self.States[i].Name ) then
                    if ( self.States[i].EnterState ) then
                        self.States[i].EnterState(self)
                    end
                    self.PreviousStateIndex = self.StateIndex
                end
                self.StateIndex = i
                if ( self.Debug ) then DebugMessage("Running State", self.States[self.StateIndex].Name) end
                -- allow a run state to return true and prevent a normal schedule
                if ( self.States[i].Run(self) == true ) then return end
                break
            end
        end
        self.Schedule()
    end

    function self.Schedule(delay)
        if ( not self.Parent or not self.Parent:IsValid() ) then return end
        self.Parent:ScheduleTimerDelay((delay or self.PulseRate):Add(TimeSpan.FromMilliseconds(math.random(10,200))), "FSMPulse")
    end

    function self.ScheduleImmediate()
        self.Parent:ScheduleTimerDelay(MINIMUM_TIMESPAN, "FSMPulse")
    end

    function self.Register()
        RegisterEventHandler(EventType.Timer, "FSMPulse", self.Pulse)
        RegisterEventHandler(EventType.StopMoving, "", self.StopMoving) -- This event should be state specific
        --RegisterEventHandler(EventType.Timer, "PathTimeout", self.PathTimedOut)
        RegisterEventHandler(EventType.Message, "SetPaused", function(newPaused)
            self.Paused = ( newPaused == true )
            self.ScheduleImmediate()
        end)
        if ( self.Debug ) then RegisterEventHandler(EventType.Message, "FSM", function()
            DebugTable(self)
            DebugMessage("Current State: "..self.States[self.StateIndex].Name)
            DebugMessage("Previous State: "..self.States[self.PreviousStateIndex].Name)
        end) end
    end

    -- useful for overriding
    function self.StopMoving()
        self.PathClear()
        if ( self.CurrentTarget ~= nil ) then
            LookAt(self.Parent, self.CurrentTarget)
        end
    end

    -- useful for overriding
    function self.PathTimedOut()
        self.PathClear()
    end

    function self.PathFollow(target, distance)
        self.Parent:PathToTarget(target, distance or self.FollowDistance or 2)
        --self.Parent:ScheduleTimerDelay(FSM_DEFAULT_PATH_TIMEOUT, "PathTimeout")
    end

    function self.PathTo(target)
        if ( self.Parent and target ) then
            self.Parent:PathTo(target)
            --self.Parent:ScheduleTimerDelay(FSM_DEFAULT_PATH_TIMEOUT, "PathTimeout")
        end
    end

    function self.PathClear()
        if ( self.Parent:HasPath() ) then
            self.Parent:StopMoving()
        end
    end

    function self.SetTarget(target)
        self.PathClear()
        self.CurrentTarget = target
        if ( target == nil ) then
            Var.Del(self.Parent, "CurrentTarget")
        else
            Var.Set(self.Parent, "CurrentTarget", target)
        end
        if ( self.StateIndex ~= nil and self.States[self.StateIndex].OnTargetChanged ~= nil ) then
            self.States[self.StateIndex].OnTargetChanged(self)
        end
    end

    function self.ValidCombatTarget(target)
        return (
            target ~= nil
            and target:IsValid()
            and not Death.Active(target)
            and (self.CanSeeInvis or not target:IsCloaked())
            and Var.Get(target, "MobileTeamType") ~= self.TeamType
            and not Var.Has(target, "Invulnerable")
            and not Var.Has(target, "InvalidTarget")
        )
    end

    function self.RemoveState(state)
        if ( not state ) then return end
        local states = {}
        for i=1,#self.States do
            if not( self.States[i] == state ) then
                states[#states+1] = self.States[i]
            elseif ( self.Debug ) then
                DebugMessage("[FSM] Removed state:", state.Name or "Unknown", "from:", self.Parent)
            end
        end
        self.States = states
    end

    function self.ReplaceState(state, with)
        if ( not state ) then return end
        for i=1,#self.States do
            if ( self.States[i] == state ) then
                self.States[i] = with
                if ( self.Debug ) then DebugMessage("[FSM] Replaced state:", state.Name or "Unknown", "with:", with.Name or "Unknown") end
                return true
            end
        end
        return false
    end

    function self.Start()
        self.TeamType = AIProperty.GetTeamType(self.Template)
        if ( self.TeamType ~= nil ) then
            -- set it as an objvar to allow other mobiles to search it out
            Var.Set(self.Parent, "MobileTeamType", self.TeamType)
        end
        self.Loc = self.Parent:GetLoc()
        for i=1,#self.States do
            if ( self.States[i].Init ) then
                self.States[i].Init(self)
            end
        end
        self.Register()
        self.Schedule()
        if ( self.Debug ) then DebugMessage("[FSM] Started for", self.Parent) end
    end

    -- return instance from creator function
    return self
end

FSMHelper = {}

FSMHelper.NearbyFriend = function(self, range, dead)
    return FindObjects(SearchMulti({
        SearchMobileInRange(range, true, dead or false, true),
        SearchObjVar("MobileTeamType", self.TeamType),
    }))
end

FSMHelper.AbilityInit = function(self)
    self.Abilities = AIProperty.GetAbilities(self.Template)
    if ( self.Abilities and #self.Abilities < 1 ) then self.Abilities = nil end
end

FSMHelper.RandomAbility = function(self, delaySeconds, force)
    if ( self.Abilities ) then
        if ( FSMHelper.PerformAbility(self, self.Abilities[math.random(1,#self.Abilities)], delaySeconds, force) ) then

        end
    end
end

FSMHelper.PerformAbility = function(self, ability, delaySeconds, force)
    if ( force ~= true and self.Parent:HasTimer("RecentAbility") ) then return end
    local abilityData = Ability.GetData(ability)
    if not( abilityData ) then
        LuaDebugCallStack(string.format("[FSMHelper.PerformAbility] invalid ability: %s", ability))
        return
    end
    local target
    if ( abilityData.NoCombat ) then -- if this is a beneficial ability
        if ( abilityData.RequireDeadTarget ) then
            target = FSMHelper.NearbyFriend(self, abilityData.Range or 5, true)[1]
        else
            -- selfish healing
            if ( 
                ( ability == "Heal" or ability == "BigHeal" )
                and
                Stat.Health.NotFull(self.Parent)
            ) then
                target = self.Parent
            end
            if not( target ) then
                target = FSMHelper.NearbyFriend(self, abilityData.Range or 5)[1]
            end
        end
    else
        target = self.CurrentTarget
    end

    if ( abilityData.RequireLocationTarget and target ) then
        target = target:GetLoc()
    end
    
    if ( target and Ability.Perform(self.Parent, target, ability) ) then
        if ( delaySeconds ) then self.Parent:ScheduleTimerDelay(TimeSpan.FromSeconds(delaySeconds), "RecentAbility") end
        return true
    end
    return false
end

FSMHelper.UseAbility = function(self, abilityName, delaySeconds, target)
    if ( abilityName and not self.Parent:HasTimer("RecentAbility") ) then
        FSMHelper.TriggerSpeech(self)
        Ability.Perform(self.Parent, target or self.CurrentTarget, abilityName)
        self.Parent:ScheduleTimerDelay(TimeSpan.FromSeconds(delaySeconds), "RecentAbility")
    end
end

FSMHelper.TriggerSelfEffect = function(self, effect, delaySeconds, target, args)
    if ( effect and not self.Parent:HasTimer("RecentSelfEffect") ) then
        FSMHelper.TriggerSpeech(self)
        Effect.Apply(self.Parent, effect, args, target)
        self.Parent:ScheduleTimerDelay(TimeSpan.FromSeconds(delaySeconds), "RecentSelfEffect")
    end
end

FSMHelper.TriggerTargetEffect = function(self, effect, delaySeconds, target, args)
    if ( effect and not self.Parent:HasTimer("RecentTargetEffect") ) then
        FSMHelper.TriggerSpeech(self)
        Effect.Apply(target, effect, args, self.Parent)
        self.Parent:ScheduleTimerDelay(TimeSpan.FromSeconds(delaySeconds), "RecentTargetEffect")
    end
end

FSMHelper.TriggerSpeech = function(self)
    if ( self.NPCSpeech ~= nil ) then
        self.Parent:NpcSpeech(self.NPCSpeech)
        self.NPCSpeech = nil
    end
end
