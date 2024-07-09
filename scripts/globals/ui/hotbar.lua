-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2024 Corp Por LTD

UI.Hotbar = {
    IconSize = 128,
    NumSlots = 10,
}

function UI.Hotbar.Init(playerObj)
    UI.Hotbar.Register(playerObj)

    local width = UI.Hotbar.IconSize*UI.Hotbar.NumSlots

    local dynamicWindow = DynamicWindow(
		"Hotbar", --(string) Window ID used to uniquely identify the window. It is returned in the DynamicWindowResponse event.
		"", --(string) Title of the window for the client UI
		width, --(number) Width of the window
		UI.Hotbar.IconSize, --(number) Height of the window
		-(width / 2), --startX, --(number) Starting X position of the window (chosen by client if not specified)
		-200, --startY, --(number) Starting Y position of the window (chosen by client if not specified)
		"Transparent",--windowType, --(string) Window type (optional)
		"Bottom", --windowAnchor --(string) Window anchor (default "TOPLEFT")
		-1 --windowDepth
    )

    local userActions = {}
    local hotbarActions = Var.Get(playerObj, "HotbarActions") or {}

    for i=1,UI.Hotbar.NumSlots do
        local hba = hotbarActions["s"..i]
        if ( hba == nil ) then
            userActions[i] = UI.Hotbar.EmptySlot(i)
        else
            userActions[i] = hba
        end
        dynamicWindow:AddHotbarAction(
            (i-1)*UI.Hotbar.IconSize, --x
            0, --y
            i, --slot index
            UI.Hotbar.IconSize, --width
            UI.Hotbar.IconSize, --height
            userActions[i].Draggable == true or userActions[i].Draggable == nil --draggable (if draggable not set default to true)
        )
    end

    playerObj:SendClientMessage("UpdateUserAction", userActions)
    playerObj:OpenDynamicWindow(dynamicWindow)
end

function UI.Hotbar.EmptySlot(slot)
    return {
        Slot = slot,
        ID = "hb"..slot,
        Draggable = false,
        Enabled = true,
    }
end

function UI.Hotbar.Register(playerObj)
    RegisterEventHandler(EventType.ClientObjectCommand, "dropAction", function(user,sourceId,targetId)
        DebugMessage(user,sourceId,targetId)
        if ( targetId == sourceId ) then return end

        -- determine if the source and/or target are from the hotbar (by checking the ID of the action starts with 'hb')
        local hbSource = sourceId ~= nil and string.sub(sourceId, 1, 2) == "hb"
        local hbTarget = targetId ~= nil and string.sub(targetId, 1, 2) == "hb"
        -- get the slots
        local sourceSlot = hbSource and tonumber(string.sub(sourceId, 3, #sourceId))
        local targetSlot = hbTarget and tonumber(string.sub(targetId, 3, #targetId))

        if ( hbSource and hbTarget ) then
            -- swapping hotbar actions
            UI.Hotbar.SwapUserActions(playerObj, sourceSlot, targetSlot)
        elseif ( hbSource and targetId == nil ) then
            -- removing action
            UI.Hotbar.DelUserActionSlot(playerObj, sourceSlot, true)
        elseif ( hbTarget ) then
            -- adding new action
            if ( Ability.Valid(sourceId) ) then
                local abilityAction = Ability.UserAction(sourceId)
                abilityAction.Slot = targetSlot
                UI.Hotbar.AddUserAction(playerObj, abilityAction, true)
            end
        end
    end)
    
    RegisterEventHandler(EventType.ClientUserCommand, "dropItemToHotbar", function(slot)
        if ( slot ~= nil ) then
            slot = tonumber(slot)
            -- limit of 100 hotbar actions per player
            if ( slot > 0 and slot <= 100) then
                local carriedObject = this:CarriedObject()
                if ( carriedObject ~= nil and carriedObject:IsValid() ) then
                    -- get the data for this item to be on the hotbar
                    local action = UI.Hotbar.ItemUserAction(carriedObject, slot)
                    -- add the hotbar data
                    UI.Hotbar.AddUserAction(playerObj, action, true)
                    -- attempt to put back whatever is being held in the cursor (unless the destination would be the world)
                    Interaction.UndoPickup(playerObj, true)
                end
            end
        end
    end)
end

function UI.Hotbar.ItemUserAction(gameObj, slot)
    local serverCommand = "use " .. gameObj.Id
    return {
        ID=gameObj.Id.."",
        TargetObject=gameObj,
        Slot=slot,
        Enabled=true,
        ServerCommand=serverCommand,
        Resource=gameObj:HasSharedObjectProperty("Resource") and gameObj:GetSharedObjectProperty("Resource") or nil
    }
end

function UI.Hotbar.AddUserAction(playerObj, action, sendUpdate)
	if ( playerObj == nil ) then
		LuaDebugCallStack("[UI.Hotbar.AddUserAction] playerObj is nil")
        return
	end
	if ( action == nil ) then
		LuaDebugCallStack("[UI.Hotbar.AddUserAction] action is nil")
        return
	end
	if ( action.ID == nil or not( type(action.ID) =="string" ) ) then
		LuaDebugCallStack("[UI.Hotbar.AddUserAction] invalid action.ID provided")
        return
	end

    local hotbarActions = Var.Get(playerObj, "HotbarActions") or {}

    if ( action.Slot == nil ) then 
		action.Slot = 1
		while( hotbarActions["s"..action.Slot] ~= nil) do
			action.Slot = action.Slot + 1
		end
	end

    action.ID = "hb"..action.Slot
    hotbarActions["s"..action.Slot] = action

    Var.Set(playerObj, "HotbarActions", hotbarActions)

    if ( sendUpdate == true ) then
        playerObj:SendClientMessage("UpdateUserAction", {action})
    end
end

function UI.Hotbar.DelUserActionSlot(playerObj, slot, sendUpdate)
	if ( playerObj == nil ) then
		LuaDebugCallStack("[UI.Hotbar.DelUserAction] playerObj is nil")
        return
	end
	if ( slot == nil ) then
		LuaDebugCallStack("[UI.Hotbar.DelUserActionSlot] slot is nil")
        return
	end

    local hotbarActions = Var.Get(playerObj, "HotbarActions") or {}

    if ( hotbarActions["s"..slot] ~= nil ) then
        hotbarActions["s"..slot] = nil

        Var.Set(playerObj, "HotbarActions", hotbarActions)

        if ( sendUpdate == true ) then
            playerObj:SendClientMessage("UpdateUserAction", {UI.Hotbar.EmptySlot(slot)})
        end
    end
end

function UI.Hotbar.SwapUserActions(playerObj, fromSlot, toSlot)
	if ( playerObj == nil ) then
		LuaDebugCallStack("[UI.Hotbar.SwapUserActions] playerObj is nil")
        return
	end
	if ( fromSlot == nil ) then
		LuaDebugCallStack("[UI.Hotbar.SwapUserActions] fromSlot is nil")
        return
	end
	if ( toSlot == nil ) then
		LuaDebugCallStack("[UI.Hotbar.SwapUserActions] toSlot is nil")
        return
	end

    local hotbarActions = Var.Get(playerObj, "HotbarActions") or {}

    local fromAction = hotbarActions["s"..fromSlot]
    local toAction = hotbarActions["s"..toSlot]

    local update = {}
    if ( fromAction ~= nil ) then
        fromAction.Slot = toSlot
        fromAction.ID = "hb"..toSlot
        hotbarActions["s"..toSlot] = fromAction
        update[#update+1] = fromAction
        if ( toAction == nil ) then
            hotbarActions["s"..fromSlot] = nil
            update[#update+1] = UI.Hotbar.EmptySlot(fromSlot)
        end
    end
    if ( toAction ~= nil ) then
        toAction.Slot = fromSlot
        toAction.ID = "hb"..fromSlot
        hotbarActions["s"..fromSlot] = toAction
        update[#update+1] = toAction
        if ( fromAction == nil ) then
            hotbarActions["s"..toSlot] = nil
            update[#update+1] = UI.Hotbar.EmptySlot(toSlot)
        end
    end

    Var.Set(playerObj, "HotbarActions", hotbarActions)
    playerObj:SendClientMessage("UpdateUserAction", update)
end