-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



Stackable = {}

function Stackable.Is(item, templateid, skipChecks)
    if not( templateid ) then
        if not( skipChecks ) then
            if not( item ) then
                LuaDebugCallStack("[Stackable.Is] item not provided.")
                return false
            end
            if not( item:IsValid() ) then
                LuaDebugCallStack("[Stackable.Is] invalid item provided.")
                return false
            end
        end
        templateid = Object.TemplateId(item)
    end
    if not( templateid ) then return false end
    return Template[templateid] and Template[templateid].Stackable
end

function Stackable.Combinable(item, templateid, skipChecks)
    if not( templateid ) then
        if not( skipChecks ) then
            if not( item ) then
                LuaDebugCallStack("[Stackable.Is] item not provided.")
                return false
            end
            if not( item:IsValid() ) then
                LuaDebugCallStack("[Stackable.Is] invalid item provided.")
                return false
            end
        end
        templateid = Object.TemplateId(item)
    end
    if not( templateid ) then return false end
    return Template[templateid] and Template[templateid].Combinable
end

function Stackable.GetCount(item, skipChecks)
    if not( skipChecks ) then
        if not( item ) then
            LuaDebugCallStack("[Stackable.GetCount] item not provided.")
            return 0
        end
        if not( item:IsValid() ) then
            LuaDebugCallStack("[Stackable.GetCount] invalid item provided.")
            return 0
        end
    end
    return item:GetSharedObjectProperty("StackCount") or 1
end

function Stackable.SetCount(item, amount, skipChecks)
    if not( skipChecks ) then
        if not( item ) then
            LuaDebugCallStack("[Stackable.SetCount] item not provided.")
            return false
        end
        if not( item:IsValid() ) then
            LuaDebugCallStack("[Stackable.SetCount] invalid item provided.")
            return false
        end
    end
    if ( amount == nil or amount <= 0 ) then
        item:Destroy()
    else
        item:SetSharedObjectProperty("StackCount", amount)
        --SetItemTooltip(item)
    end
    return true
end

function Stackable.Adjust(item, amount, skipChecks)
    if not( skipChecks ) then
        if not( item ) then
            LuaDebugCallStack("[Stackable.Adjust] item not provided.")
            return false
        end
        if not( item:IsValid() ) then
            LuaDebugCallStack("[Stackable.Adjust] invalid item provided.")
            return false
        end
        if ( amount == nil ) then
            LuaDebugCallStack("[Stackable.Adjust] amount not provided.")
            return false
        end
        if not( Stackable.Is(item, nil, true) ) then
            LuaDebugCallStack("[Stackable.Adjust] cannot adjust non-stackable items.")
            return false
        end
    end

    return Stackable.SetCount(item, Stackable.GetCount(item, true) + amount, true)
end

function Stackable.CanStack(item, otherObj, skipChecks)
    if not( skipChecks ) then
        if not( item ) then
            LuaDebugCallStack("[Stackable.CanStack] item not provided.")
            return false
        end
        if not( otherObj ) then
            LuaDebugCallStack("[Stackable.CanStack] otherObj not provided.")
            return false
        end
        if not( item:IsValid() ) then
            LuaDebugCallStack("[Stackable.CanStack] invalid item provided.")
            return false
        end
        if not( otherObj:IsValid() ) then
            LuaDebugCallStack("[Stackable.CanStack] invalid otherObj provided.")
            return false
        end
    end
    local templateid = Object.TemplateId(item)
    if ( not Template[templateid] or not Template[templateid].Combinable ) then return false end
    if not( Stackable.Is(item, nil, true) ) then return false end
    if not( Stackable.Is(otherObj, nil, true) ) then return false end
    return templateid == Object.TemplateId(otherObj)
end

function Stackable.Combine(item, otherObj)
    if not( item ) then
        LuaDebugCallStack("[Stackable.Combine] item not provided.")
        return false
    end
    if not( otherObj ) then
        LuaDebugCallStack("[Stackable.Combine] otherObj not provided.")
        return false
    end
    if not( item:IsValid() ) then
        LuaDebugCallStack("[Stackable.Combine] invalid item provided.")
        return false
    end
    if not( otherObj:IsValid() ) then
        LuaDebugCallStack("[Stackable.Combine] invalid otherObj provided.")
        return false
    end
    if ( not Stackable.Is(item, nil, true) or not Stackable.Is(otherObj, nil, true) ) then return false end
    if not( Stackable.CanStack(item, otherObj, true) ) then return false end

    if ( Stackable.Adjust(item, Stackable.GetCount(otherObj, true), true) ) then
        otherObj:Destroy()
        return true
    end
    return false
end