-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD



Effects.Harvest = {
    Debuff = false,
    Cancelable = true,
    Duration = TimeSpan.FromSeconds(4),
    Pulse = 3,
    EndOnMovement = true,

    OnStart = function(self)
        if not( Effects.Harvest.CanHarvest(self) ) then return false end

        -- start harvesting it
        return Effects.Harvest.OnPulse(self)
    end,

    OnPulse = function(self)
        if ( (self.Pulses or 0) < Effects.Harvest.Pulse ) then
            if ( self.MapObj.ObjectType == MapObjType.Tree ) then
                self.Parent:PlayAnimation("choph")
            elseif ( self.MapObj.ObjectType == MapObjType.Rock ) then
                self.Parent:PlayAnimation("chopv")
            end
        end

        return true
    end,

    OnStop = function(self, canceled)
		if ( not canceled and self.MapObj:Exists() ) then
            Effects.Harvest.OnHarvestSuccess(self)
        end
    end,

    CanHarvest = function(self)
        if ( self.Parent:GetLoc():Distance(self.MapObj:GetLoc()) > self.MapObj.MaxSize + self.Parent:GetSharedObjectProperty("BodyOffset") ) then
			self.Parent:SystemMessage("Too Far Away.", "info")
			return false
		end
		-- some funny business going on if this happens, potentially (or someone tried to harvest a tree that was just removed)
		if not( self.MapObj:Exists() ) then return false end

        return true
    end,

    OnHarvestSuccess = function(self)
        local existing = self.MapObj:Existing()

        if ( existing == nil ) then return end

        local mapObj = self.MapObj

        -- reward
        local reward = Harvestable[existing.Index..""].Reward
        if ( reward ~= nil ) then
            Create.InBackpack(reward, self.Parent)
        end

        -- remove
        existing:Remove()

        -- replace
        local replace = Harvestable[existing.Index..""].Replace
        if ( replace ~= nil ) then
            mapObj.Index = replace
            mapObj:Add()
        else
            mapObj = nil
        end

        -- respawn
        local respawn = Harvestable[existing.Index..""].Respawn
        if ( respawn ~= nil ) then
            Future.ScheduleTask(respawn, {existing, replace ~= nil and mapObj or nil}, function(data)
                if ( data[2] ~= nil ) then
                    data[2]:Remove()
                end
                data[1]:Add()
            end)
        end
    end,
}