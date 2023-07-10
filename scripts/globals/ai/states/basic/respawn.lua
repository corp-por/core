-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


States.Respawn = {
    Name = "Respawn",
    Init = function(self)
        RegisterEventHandler(EventType.Message, "Resurrected", function()
            self.Parent:RemoveTimer("Respawn")
            -- resume on a resurrect
            self.Schedule()
        end)
        RegisterEventHandler(EventType.Timer, "Respawn", function()
            States.Respawn.Reset(self)
        end)
        if not( Var.Has(self.Parent, "SpawnLocation") ) then
            self.SpawnLocation = self.Loc
            Var.Set(self.Parent, "SpawnLocation", self.SpawnLocation)
        end
        if not ( self.SpawnLocation ) then
            self.SpawnLocation = Var.Get(self.Parent, "SpawnLocation")
        end
    end,
    ShouldRun = function(self)
        return Death.Active(self.Parent)
    end,
    Run = function(self)
        self.SetTarget(nil)
        if not( self.Parent:HasTimer("Respawn") ) then
            self.Parent:ScheduleTimerDelay(
                self.RespawnTimer or AIProperty.GetRespawnTimer(self.Template) or ServerSettings.AI.Default.RespawnTimer,
                "Respawn"
            )
        end
        -- disable as a nav agent (stop blocking movement for other agents)
        self.Parent:DisableNavigationAgent()
        -- stop all ai while respawning.
        return true
    end,

    Reset = function(self)
        -- destroy all loot on me
        local backpack = Backpack.Get(self.Parent)
        if ( backpack ~= nil ) then
            backpack:Destroy()
        end

        -- this is to make it look more like a respawn (if you're an immortal character you will see them stand back up)
        self.Parent:SetCloak(true)

        CallFunctionDelayed(TimeSpan.FromSeconds(1), function()

            -- resurrect
            Death.End(self.Parent, 1.0, true)
    
            -- move to spawn point
            if ( self.SpawnLocation ) then
                self.Parent:SetWorldPosition(self.SpawnLocation)
            end
    
            -- resume
            self.Schedule()

            self.Parent:SetCloak(false)

        end)
    end,
    
    ExitState = function(self)
        self.Parent:EnableNavigationAgent()
    end,
    -- these are called if state is active or not
    OnPause = function(self)
        self.Parent:DisableNavigationAgent()
    end,
    OnResume = function(self)
        -- when resuming from a pause, we only want to re-enable navigation agent if we shouldn't run respawn
        if not States.Respawn.ShouldRun(self) then
            self.Parent:EnableNavigationAgent()
        end
    end,
}