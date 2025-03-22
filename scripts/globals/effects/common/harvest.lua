-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD



Effects.Harvest = {
    Debuff = false,
    Cancelable = true,
    Duration = TimeSpan.FromSeconds(4),
    Pulse = 3,
    EndOnMovement = true,

    HarvestableTable = {},
    HarvestColor = nil,

    OnStart = function(self)
        local existing = self.MapObj:Existing()
		-- some funny business going on if this happens, potentially (or someone tried to harvest a tree that was just removed)
		if ( existing == nil ) then return false end

        self.HarvestableTable = Harvestable[existing.Index..""]

        -- cannot harvest this object
        if ( self.HarvestableTable == nil ) then return false end

        if ( self.HarvestableTable.Colors ~= nil ) then
            local color = existing:GetColor()
            self.HarvestableTable = self.HarvestableTable.Colors[color]
            self.HarvestColor = color
        end

        -- cannot harvest this color of object
        if ( self.HarvestableTable == nil ) then return false end

        if not( Effects.Harvest.CanHarvest(self) ) then return false end

        -- start harvesting it
        return Effects.Harvest.OnPulse(self)
    end,

    OnPulse = function(self)
        if not ( Effects.Harvest.CheckTool(self) ) then return false end

        if ( (self.Pulses or 0) < Effects.Harvest.Pulse ) then
            if ( self.MapObj.ObjectType == MapObjType.Tree ) then
                self.Parent:PlayAnimation("choph")
                CallFunctionDelayed(TimeSpan.FromSeconds(0.5), function()
                    self.Parent:PlayObjectSound("event:/character/skills/gathering_skills/lumberjack/lumberjack", false)
                end)
            elseif ( self.MapObj.ObjectType == MapObjType.Rock ) then
                self.Parent:PlayAnimation("chopv")
                CallFunctionDelayed(TimeSpan.FromSeconds(0.5), function()
                    self.Parent:PlayObjectSound("event:/character/skills/gathering_skills/mining/mining", false)
                end)
            end
        end

        return true
    end,

    OnStop = function(self, canceled)
		if ( not canceled and self.MapObj:Exists() ) then
            Effects.Harvest.OnHarvestSuccess(self)
        end
    end,

    CheckTool = function(self)
        -- no tool required to harvest this
        if ( self.HarvestableTable.Tool == nil ) then
            return true
        end

        -- look for tool in hand
        local item = self.Parent:GetEquippedObject("RightHand")
        if ( item ~= nil and Object.TemplateId(item) == self.HarvestableTable.Tool ) then
            return true
        else
            -- tool not in hand, find it in backpack
            local backpack = Backpack.Get(self.Parent)
            local tool = FindItemInContainerByTemplate(backpack, self.HarvestableTable.Tool)
            if ( tool ~= nil ) then
                -- found tool in backpack, equip it
                Equipment.Equip(self.Parent, tool, self.Parent)
                return true
            end
        end

        if ( Template[self.HarvestableTable.Tool] ~= nil ) then
            self.Parent:SystemMessage(Template[self.HarvestableTable.Tool].Name .. " required.")
        end

        return false
    end,

    CanHarvest = function(self)
        if ( self.Parent:GetLoc():Distance(self.MapObj:GetLoc()) > self.MapObj.MaxSize + self.Parent:GetSharedObjectProperty("BodyOffset") ) then
			self.Parent:SystemMessage("Too Far Away.", "info")
			return false
		end

        return true
    end,

    OnHarvestSuccess = function(self)
        local existing = self.MapObj:Existing()

        if ( existing == nil ) then return false end

        -- color no longer matches?
        if ( self.HarvestColor ~= nil and self.HarvestColor ~= existing:GetColor() ) then
            return false
        end

        local mapObj = self.MapObj

        -- reward
        local reward = self.HarvestableTable.Reward
        if ( reward ~= nil ) then
            Create.InBackpack(reward, self.Parent, nil, function(obj, err)
                if ( obj == nil and err == "full" ) then
                    Create.AtLoc(reward, self.Parent:GetLoc(), function(obj)
                        if ( obj ~= nil ) then
                            Object.Decay(obj)
                        end
                    end)
                end
            end)
        end

        -- remove
        existing:Remove()

        -- replace
        local replace = self.HarvestableTable.Replace
        if ( replace ~= nil ) then
            mapObj.Index = replace
            mapObj:Add()
        else
            mapObj = nil
        end

        -- respawn
        local respawn = self.HarvestableTable.Respawn
        if ( respawn ~= nil ) then
            Future.ScheduleTask(respawn, {existing, replace ~= nil and mapObj or nil}, function(data)
                if ( data[2] ~= nil ) then
                    data[2]:Remove()
                end
                data[1]:Add()
            end)
        end

        return true
    end,
}