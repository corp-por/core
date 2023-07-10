-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


Stat = {}

function ForeachStat(cb)
    if ( cb ~= nil ) then
        for id,stat in pairs(Stat) do
            cb(id)
        end
    end
end

function NewStat(name, public, regenRate)

    local self = {
        ID = name,
        Public = public == true or false
    }

    local function _validate(mobileObj)
        if ( mobileObj == nil ) then
            LuaDebugCallStack("[Stat Validate] nil mobileObj provided")
            return false
        end
        if not( mobileObj:IsValid() ) then
            LuaDebugCallStack("[Stat Validate] invalid mobileObj provided")
            return false
        end
        return true
    end

    -- initialize a stat for a mobile (only needs to be done once, on creation)
    function self.Init(mobileObj)
        if ( self.Public ) then
            if not( _validate(mobileObj) ) then return end
            mobileObj:SetStatVisibility(self.ID, "Global")
            if ( regenRate ~= nil ) then
                mobileObj:SetStatRegenRate(self.ID, regenRate)
            end
        end
    end

    function self.Get(mobileObj)
        if not( _validate(mobileObj) ) then return 0 end
        return mobileObj:GetStatValue(self.ID)
    end

    function self.Set(mobileObj, val)
        if not( _validate(mobileObj) ) then return end
        mobileObj:SetStatValue(self.ID, val)
    end

    function self.Max(mobileObj)
        if not( _validate(mobileObj) ) then return 0 end
        return mobileObj:GetStatMaxValue(self.ID)
    end

    function self.SetMax(mobileObj, newMax)
        mobileObj:SetStatMaxValue(self.ID, newMax)
    end

    function self.Regen(mobileObj)
        if not( _validate(mobileObj) ) then return 0 end
        return mobileObj:GetStatRegenRate(self.ID)
    end

    function self.SetRegen(mobileObj, newRate)
        if not( _validate(mobileObj) ) then return end
        mobileObj:SetStatRegenRate(self.ID, newRate)
    end

    function self.Percent(mobileObj)
        if not( _validate(mobileObj) ) then return end
        local val = self.Get(mobileObj)
        if ( val <= 0 ) then
            return 0.0
        end
        return val / self.Max(mobileObj)
    end

    function self.NotFull(mobileObj)
        if not( _validate(mobileObj) ) then return end
        return self.Get(mobileObj) < self.Max(mobileObj)
    end

    function self.Fill(mobileObj)
        if not( _validate(mobileObj) ) then return end
        self.Set(mobileObj, self.Max(mobileObj))
    end

    function self.Delta(mobileObj, amount)
        if not( _validate(mobileObj) ) then return end
        self.Set(mobileObj, self.Get(mobileObj) + amount)
    end
    
    Stat[self.ID] = self
end

require 'globals.stats.stats'