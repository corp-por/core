-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Effect = {}

local DefaultDuration = TimeSpan.FromSeconds(1)

function Effect.Has(gameObj, effect)
    return (Var.Temp.Get(gameObj, "ActiveEffects") or {})[effect] ~= nil
end

-- private function
local _endeffect = function(self, cancel, effects)
    if ( type(self) ~= 'table' ) then
        LuaDebugCallStack("Invalid self provided to _endeffect")
        return
    end

    if ( effects == nil ) then
        effects = Var.Temp.Get(self.Parent, "ActiveEffects")
    end

    -- mark it as ended so we can check for it ending in same frame as starting
    self.HasEnded = true

    if ( effects ~= nil and effects[self.Effect] == self ) then

        -- if there's a timerid, there's could be a timer running, remove it
        if ( self.TimerId ) then
            self.Parent:RemoveTimer(self.TimerId)
            UnregisterEventHandler("", EventType.Timer, self.TimerId)
        end

        -- update the temp var to mark this effect as no longer active
            -- (we mark this here before OnStop incase OnStop throws an exception and fails to reach this)
        effects[self.Effect] = nil
        Var.Temp.Set(self.Parent, "ActiveEffects", effects)

    end

    if ( Effects[self.Effect].PersistSession == true ) then
        local savedEffects = Var.Get(self.Parent, "PersistentEffects") or {}
        if ( savedEffects[self.Effect] ~= nil ) then
            savedEffects[self.Effect] = nil
            Var.Set(self.Parent, "PersistentEffects", savedEffects)
        end
    end

    -- update icons (if this effect has an icon)
    if ( ( self.Icon or Effects[self.Effect].Icon ) and self.Parent:IsPlayer() ) then
        Effect.Icon.UpdateWindow(self.Parent, effects)
    end
        
    if ( Effects[self.Effect].OnStop ) then
        Effects[self.Effect].OnStop(self, cancel or false)
    end
end

function Effect.Apply(gameObj, effect, args, targetObj)
    if ( Effects[effect] == nil ) then
        LuaDebugCallStack("[Effect.Start] Invalid effect provided: "..tostring(effect))
        return false
    end

    local effects = Var.Temp.Get(gameObj, "ActiveEffects") or {}

    -- if currently have the effect
    if ( effects[effect] ~= nil ) then

        -- if the effect is stackable
        if ( Effects[effect].OnStack ) then
            if ( effects[effect].Stacks == nil ) then
                effects[effect].Stacks = 1 -- one for the first time this applied ( this is the second stack )
            end
            -- increment the stack count, as long as we aren't going over limit
            if ( effects[effect].Stacks < (effects[effect].MaxStacks or Effects[effect].MaxStacks or 99) ) then
                effects[effect].Stacks = effects[effect].Stacks + 1
            end
            return Effects[effect].OnStack(effects[effect])
        end

		-- non-stackable effects fail here
		return false
    end

    -- setup our self
    local self = args ~= nil and deepcopy(args) or {}
    self.Parent = gameObj
    self.Target = targetObj
    self.Effect = effect

    -- if we successfully started the effect
    if ( Effects[effect].OnStart == nil or Effects[effect].OnStart(self) == true ) then

        -- need to check if not ended already incase effect was ended somehow in the OnStart call directly above
        if ( self.HasEnded ~= true ) then

            -- update the temp var so we can check for active effects, also we can access the effect data
            effects[effect] = self
            Var.Temp.Set(gameObj, "ActiveEffects", effects)

            Effect.Refresh(self)

            -- if the effect persists, save it
            if ( Effects[effect].PersistSession == true ) then
                local savedEffects = Var.Get(gameObj, "PersistentEffects") or {}
                savedEffects[effect] = self
                Var.Set(gameObj, "PersistentEffects", savedEffects)
            end

        end

        -- return true even if the effect was already ended, since it successfully started
        return true
    end

    return false
end

function Effect.ApplyPersistentEffects(playerObj)
    local savedEffects = Var.Get(playerObj, "PersistentEffects")
    if ( savedEffects ~= nil ) then
        for effect,self in pairs(savedEffects) do
            Effect.Apply(playerObj, effect, self, self.Target)
        end
    end
end

function Effect.OnDeath(gameObj)
    local effects = Var.Temp.Get(gameObj, "ActiveEffects")
    if ( effects ~= nil ) then
        for effect,self in pairs(effects) do
            if ( Effects[effect].PersistDeath ~= true ) then
                _endeffect(self, false, effects)
            end
        end
    end
end

function Effect.OnSwim(gameObj)
    local effects = Var.Temp.Get(gameObj, "ActiveEffects")
    if ( effects ~= nil ) then
        for effect,self in pairs(effects) do
            if ( Effects[effect].NoSwim == true ) then
                _endeffect(self, true, effects)
            end
        end
    end
end

function Effect.OnMovement(gameObj)
    local effects = Var.Temp.Get(gameObj, "ActiveEffects")
    if ( effects ~= nil ) then
        for effect,self in pairs(effects) do
            if ( Effects[effect].EndOnMovement == true ) then
                _endeffect(self, false, effects)
            end
        end
    end
end

function Effect.End(gameObj, effect, cancel)
    local effects = Var.Temp.Get(gameObj, "ActiveEffects")
    if ( effects ~= nil and effects[effect] ~= nil ) then
        _endeffect(effects[effect], cancel or false, effects)
    end
end

function Effect.EndSelf(self)
    _endeffect(self)
end

function Effect.Cancel(self)
    _endeffect(self, true)
end

function Effect.TimeRemaining(self)
    if ( self.Duration or Effects[self.Effect].Duration ) then
        if ( self.Pulse ~= nil or Effects[self.Effect].Pulse ~= nil ) then
            local remainingPulses = (self.Pulse or Effects[self.Effect].Pulse) - (self.Pulses or 0) - 1
            return (
                TimeSpan.FromSeconds(remainingPulses * self.PulseDuration.TotalSeconds)
            ) + self.Parent:GetTimerDelay(self.TimerId)
        else
            return self.Parent:GetTimerDelay(self.TimerId)
        end
    end
    return nil
end

function Effect.Refresh(self, effects)

    local E = Effects[self.Effect]

    -- if we have a duration of any kind
    if ( self.Duration or E.Duration ) then

        -- only ever set this if it's not set, never overwrite an existing timerid
            -- this keeps the same TimerId through the effect's entire lifetime
        if ( self.TimerId == nil ) then
            self.TimerId = uuid() .. self.Effect
        end

        -- if the effect pulses
        if ( E.Pulse and E.OnPulse ) then
            
            self.Pulses = 0

            -- this effect will pulse, calling OnPulse periodically before finally ending
            self.PulseDuration = TimeSpan.FromSeconds((self.Duration or E.Duration).TotalSeconds / (self.Pulse or E.Pulse))
            RegisterEventHandler(EventType.Timer, self.TimerId, function()
                self.Pulses = self.Pulses + 1
                E.OnPulse(self)
                if ( self.Pulses >= ( self.Pulse or E.Pulse ) ) then
                    -- this was the last pulse, end it
                    _endeffect(self)
                else
                    -- schedule another pulse (unless the OnPulse ended the effect)
                    if not( self.HasEnded ) then
                        self.Parent:ScheduleTimerDelay(self.PulseDuration, self.TimerId)
                    end
                end
            end)
            self.Parent:ScheduleTimerDelay(self.PulseDuration, self.TimerId)
        
        else

            -- no pulse, only a duration, end the effect after specified amount of time
            RegisterEventHandler(EventType.Timer, self.TimerId, function()
                _endeffect(self)
            end)
            self.Parent:ScheduleTimerDelay(self.Duration or E.Duration, self.TimerId)

        end

    end

    -- update icons for players (if this effect has an icon)
    if ( ( self.Icon or E.Icon ) and self.Parent:IsPlayer() ) then
        Effect.Icon.UpdateWindow(self.Parent, effects)
    end

end

-- icons for active effects
Effect.Icon = {}

function Effect.Icon.UpdateWindow(playerObj, effects)
    local effectIconWindow = DynamicWindow("EffectIcons","",0,0,0,0,"Transparent","Top")

    if ( effects == nil ) then
        effects = Var.Temp.Get(playerObj, "ActiveEffects")
    end

    -- count the active effect table
    local count = CountTable(effects)

    -- if there's no effects then just close the window
	if ( count == 0 ) then
		playerObj:CloseDynamicWindow("EffectIcons")
		return
	end

    local SS = ServerSettings.UI.Effect.Icon
	local OFFSET = SS.Size + 2
    local startX = -math.min(count, SS.PerRow) * OFFSET / 2
    
    local index = 1
    for effect,self in pairs(effects) do

		local displayString = Effects[effect].DisplayName or effect
        if ( self.Debuff ) then
            -- TODO
        end
        
		-- create an icon that shows something when you mouse over it
        if ( self.Tooltip or Effects[effect].Tooltip ) then
            displayString = displayString .. ( self.Tooltip or Effects[effect].Tooltip )
        end

        if ( Effects[effect].OnTooltip ) then
            displayString = displayString .. "\n" .. Effects[effect].OnTooltip(self)
        end
		
		effectIconWindow:AddButton(startX + (((index-1) % SS.PerRow) * OFFSET),math.floor((index-1)/SS.PerRow)*OFFSET,(self.Cancelable or Effects[effect].Cancelable) and effect or "","",SS.Size,SS.Size,displayString,"",false,"Invisible")
		effectIconWindow:AddImage(startX + (((index-1) % SS.PerRow) * OFFSET),math.floor((index-1)/SS.PerRow)*OFFSET,self.Icon or Effects[effect].Icon,SS.Size,SS.Size)
		local timeRemaining = Effect.TimeRemaining(self)
        if ( timeRemaining ) then
            
			local timerString = "[TIMER_M:"..timeRemaining:ToString("dd\\:hh\\:mm\\:ss").."]"
            if ( self.Debuff ) then
                -- TODO
			end

			effectIconWindow:AddLabel(startX + (((index-1) % SS.PerRow) * OFFSET) + SS.Size/2,SS.Size/2-26,timerString,120,SS.Size,60,"center",false,true,"Bonfire_Dynamic")
        
        end

        if ( self.Stacks ~= nil and self.Stacks > 1 ) then
            effectIconWindow:AddLabel(startX + (((index-1) % SS.PerRow) * OFFSET) + SS.Size - 5,SS.Size- 35,tostring(self.Stacks),120,SS.Size,40,"center",false,true,"Bonfire_Dynamic")
        end
        
        index = index + 1

    end
    
	--open the window
	playerObj:OpenDynamicWindow(effectIconWindow)
end