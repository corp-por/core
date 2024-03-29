-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Create = {}
Create.Custom = {}
Create.Extended = {}
Create.Stack = {}
Create.Temp = {}
Create.CustomTemp = {}

Create.OnCreateSuccessHook = function(obj, template)
    --SetItemTooltip(obj, template)
end

--- Create a template at location
-- @param template
-- @param loc - location to create at
-- @param cb - function(obj) callback
Create.AtLoc = function(template, loc, cb)
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template)
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateObj(template, loc, id)
end

--- Create a template on a mobile's equipment
-- @param template
-- @param mobile - mobile to created equipped object on
-- @param cb - function(obj) callback
Create.Equipped = function(template, mobile, cb)
    if ( mobile == nil or not mobile:IsValid() ) then
        if ( cb ) then cb(nil) end
        LuaDebugCallStack("[Create.Equipped] invalid mobile provided")
        return
    end
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then Create.OnCreateSuccessHook(obj, template) end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateEquippedObj(template, mobile, id)
end

--- Create a custom template at location
-- @param template
-- @param loc - location to create at
-- @param data - Template Data (GetTemplateData)
-- @param cb - function(obj) callback
Create.Custom.AtLoc = function(template, data, loc, cb)
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template)
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateCustomObj(template, data, loc, id)
end

Create.Extended.AtLoc = function(template, loc, rot, scale, cb)
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template)
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateObjExtended(template, nil, loc, rot, scale, id)
end

--- Create a template in a container
-- @param template
-- @param container - container gameObj
-- @param containerloc - (optional) location in container
-- @param cb - function(obj) callback
Create.InContainer = function(template, container, containerloc, cb)
    if ( container == nil or not container:IsValid() ) then
        if ( cb ) then cb(nil) end
        LuaDebugCallStack("[Create.InContainer] container mobile provided")
        return
    end

    if not( containerloc ) then
        containerloc = Container.NextEmptySlot(container)
        if ( containerloc == nil ) then
            if ( cb ) then cb(nil, "full") end
            return
        end
    end

    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then Create.OnCreateSuccessHook(obj, template) end
        if ( cb ) then cb(success and obj or nil) end
    end)

    CreateObjInContainer(template, container, containerloc, id)
end

--- Create a template in a container
-- @param template
-- @param container - container gameObj
-- @param containerloc - (optional) location in container
-- @param data - Template Data (GetTemplateData)
-- @param cb - function(obj) callback
Create.Custom.InContainer = function(template, data, container, containerloc, cb)
    if not( containerloc ) then
        containerloc = Container.NextEmptySlot(container)
        if ( containerloc == nil ) then
            if ( cb ) then cb(nil, "full") end
            return
        end
    end

    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then Create.OnCreateSuccessHook(obj, template) end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateCustomObjInContainer(template, data, container, containerloc, id)
end

--- Create a template in a mobile's backpack
-- @param template
-- @param mobile - mobileObj
-- @param containerloc - (optional) location in container
-- @param cb - function(obj) callback
Create.InBackpack = function(template, mobile, containerloc, cb)
    local backpack = Backpack.Get(mobile)
    if ( backpack == nil ) then
        LuaDebugCallStack("Mobile has no backpack.")
        if ( cb ) then cb(nil, "nobackpack") end
        return
    end
    Create.InContainer(template, backpack, containerloc, cb)
end

--- Create a template at a location, assigning StackCount before creation
-- @param template
-- @param count - stack count
-- @param loc - location in world
-- @param cb - function(obj) callback
Create.Stack.AtLoc = function(template, count, loc, cb)
    if ( count == nil or count < 1 ) then count = 1 end

    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template) 
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    
    -- set the stack count before creating
    local templateData = GetTemplateData(template)
    if ( templateData.SharedObjectProperties == nil ) then templateData.SharedObjectProperties = {} end
    if ( templateData.SharedObjectProperties.StackCount == nil or templateData.SharedObjectProperties.StackCount < 1 ) then
        templateData.SharedObjectProperties.StackCount = count
    end

    CreateCustomObj(template, templateData, loc, id)
end

--- Create a template in a container, assigning StackCount before creation
-- @param template
-- @param container - container gameObj
-- @param count - stack count
-- @param containerloc - (optional) location in container
-- @param cb - function(obj) callback
Create.Stack.InContainer = function(template, container, count, containerloc, cb)
    if ( count == nil or count < 1 ) then count = 1 end

    -- get the template id
    local templateData = GetTemplateData(template)

    if not(templateData) then
        LuaDebugCallStack("[Create.Stack.InContainer] ERROR: Invalid template specified. "..tostring(template))
        return
    end

    -- if this template isn't stackable then create a single one of them
    if not( Stackable.Is(nil, template) ) then
        Create.InContainer(template, container, containerloc, cb)
        return
    end
    
    if not( containerloc ) then
        containerloc = Container.NextEmptySlot(container)
        if ( containerloc == nil ) then
            -- early exit, container is full
            if ( cb ) then cb(nil, "full") end
            return
        end
    end

    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then Create.OnCreateSuccessHook(obj, template) end
        if ( cb ) then cb(success and obj or nil) end
    end)
    
    -- set the stack count before creating
    if ( templateData.SharedObjectProperties == nil ) then templateData.SharedObjectProperties = {} end
    if ( templateData.SharedObjectProperties.StackCount == nil or templateData.SharedObjectProperties.StackCount < 1 ) then
        templateData.SharedObjectProperties.StackCount = count
    end

    CreateCustomObjInContainer(template, templateData, container, containerloc, id)
end

--- Create a template in a mobile's backpack, assigning StackCount before creation
-- @param template
-- @param mobile - mobileObj
-- @param count - stack count
-- @param containerloc - (optional) location in container
-- @param cb - function(obj) callback
Create.Stack.InBackpack = function(template, mobile, count, containerloc, cb)
    local backpack = Backpack.Get(mobile)
    if ( backpack == nil ) then
        if ( cb ) then cb(nil, "nobackpack") end
        return
    end
    Create.Stack.InContainer(template, backpack, count, containerloc, cb)
end

--- Create a TEMPORARY (no backup) template at location
-- @param template
-- @param loc - location to create at
-- @param cb - function(obj) callback
Create.Temp.AtLoc = function(template, loc, cb)
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template)
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateTempObj(template, loc, id)
end

--- Create a custom TEMPORARY (no backup) template at location
-- @param template
-- @param loc - location to create at
-- @param data - Template Data (GetTemplateData)
-- @param cb - function(obj) callback
Create.CustomTemp.AtLoc = function(template, data, loc, cb)
    local id = template..uuid()
    RegisterSingleEventHandler(EventType.CreatedObject, id, function(success, obj)
        if ( success ) then
            Object.Decay(obj)
            Create.OnCreateSuccessHook(obj, template)
        end
        if ( cb ) then cb(success and obj or nil) end
    end)
    CreateCustomTempObj(template, data, loc, id)
end