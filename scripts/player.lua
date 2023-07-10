-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- allows reloading module in development and with it reloading all globals in this space.
if DEV then require 'globals.main' end

-- easy/fast/effecient player module identification within this module
_IS_PLAYER = true

-- these are cleared in the event player has relogged
Modify.Clear(this)
Var.Temp.Clear(this)

require 'base.mobile_advanced'

require 'inc.player_effect'
require 'inc.player_ability'
require 'inc.player_combat'

-- load the script command module
Command = require 'commands.main'

-- Send messages client expects on login
function InitializeClient()
	this:SetBaseMoveSpeed(ServerSettings.Stats.BaseMoveSpeed)

	this:SendClientMessage("TimeUpdate", {
		GetCurrentTimeOfDay(), 
		GetDaylightDurationSecs(), 
		GetNighttimeDurationSecs()
	})
end

local _OnLoad = OnLoad
function OnLoad()
	_OnLoad()
	InitializeClient()
	Effect.ApplyPersistentEffects(this)
	BankBox.Init(this)
	Backpack.Init(this, function(backpack)
		UI.Main.Init(this)
	end)
end

local _OnModuleAttached = OnModuleAttached
function OnModuleAttached()
	_OnModuleAttached()
	-- better to set it here than to assume every starting template will have it specified
	this:SetObjectTag("Player")

	-- set our mobile team type, since a nil mobile team type is ignored by AI
	-- a mobile team type is how ai know friend from foe
	Var.Set(this, "MobileTeamType", "Player")
end

-- Do things that happen when the logout process begins for this user
function OnUserLogout()
	-- currently logouts immediately
	this:CompleteLogout()
end

-- User has attempted to pick up an object in the world
-- NOTE: The client assumes they can pick up most objects so you have to call SendPickupFailed if
-- the object can not be picked up for some reason
-- @param Object to be picked up
function HandleRequestPickUp(pickedUpObject)
	local success, reason = Interaction.TryPickup(this, pickedUpObject)
	if not( success ) then
		this:SendPickupFailed(pickedUpObject)
		if ( reason ) then
			this:SystemMessage(reason, "info")
		end
	end
end

-- User has attempted to drop an object they were carrying
-- NOTE: The parameter dropLocationSpecified is necesary because the engine can not send an "invalid" location
-- if dropLocationSpecified is false that means its dropping it into a container at a random location
function HandleRequestDrop(droppedObject, dropLocation, dropObject, dropLocationSpecified)
	-- NOTE: Engine can not have invalid (nil) locations but lua can, so just nil out the location if its not specified
	if not( dropLocationSpecified ) then
		dropLocation = nil
	end
	Interaction.TryDrop(this, droppedObject, dropLocation, dropObject)
end

function HandleRequestEquip(equipObject, equippedOn)
	local topmostObj = equipObject:TopmostContainer()
	if ( topmostObj ~= this ) then
		this:SystemMessage("Can only equip things you're already carrying","info")
		return
	end
	Equipment.Equip(equippedOn, equipObject, this)
end

function HandleUseCommand(usedObjectId)
	local object = GameObj(tonumber(usedObjectId))
	Interaction.TryUse(this, object)
end

-- Event Handlers

-- Inititalization handlers only fire once so just register single event handlers
RegisterSingleEventHandler(EventType.UserLogout,"", function (...) OnUserLogout(...) end)

-- Client event handlers
RegisterEventHandler(EventType.RequestPickUp, "", function(...) HandleRequestPickUp(...) end)
RegisterEventHandler(EventType.RequestDrop, "", function(...) HandleRequestDrop(...) end)
RegisterEventHandler(EventType.RequestEquip, "", function(...) HandleRequestEquip(...) end)
RegisterEventHandler(EventType.ClientUserCommand, "use", function(...) HandleUseCommand(...) end)