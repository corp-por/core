-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Death = {}

--- These are the stats that will be set to 0 on death and set to a percent on resurrect
Death.Stats = {
	"Health"
}

function Death.Init(mobileObj)
	
end

function Death.Active(mobileObj)
    if ( not mobileObj:IsMobile() and not Var.Has(mobileObj, "Attackable") ) then
		--LuaDebugCallStack("ERROR: Trying to check IsDead on non mobile.")
		return true
    end
	return mobileObj:GetSharedObjectProperty("IsDead") == true
end

function Death.Start(mobileObj)
	for i=0,#Death.Stats do
		if ( Stat[Death.Stats[i]] ~= nil ) then
			Stat[Death.Stats[i]].Set(mobileObj, 0)
		end
	end

	if ( mobileObj:IsPlayer() ) then
		Death.Player.Start(mobileObj)
	else
		Death.Npc.Start(mobileObj)
	end
    
    Effect.OnDeath(mobileObj)

	mobileObj:PlayObjectSound("Death", true)
	
	mobileObj:StopMoving()
    mobileObj:ClearCollisionBounds()

    mobileObj:SetMobileFrozen(true,true)
    -- set as corpse
    mobileObj:SetSharedObjectProperty("IsDead", true)
    mobileObj:SetSharedObjectProperty("Pose", "Dead")

    mobileObj:SendMessage("Died")
end

-- Basically a resurrect
function Death.End(mobileObj, healthPercent, instant)
	if not( Death.Active(mobileObj) ) then
		return
	end

	if not( healthPercent ) then
		healthPercent = 1.0
	end

	for i=0,#Death.Stats do
		if ( Stat[Death.Stats[i]] ~= nil ) then
			Stat[Death.Stats[i]].Set(mobileObj, Stat[Death.Stats[i]].Max(mobileObj) * healthPercent)
		end
	end
	
	mobileObj:SetMobileFrozen(false, false)

    mobileObj:SetSharedObjectProperty("IsDead", false)
    mobileObj:SetSharedObjectProperty("Pose", "")

	if ( mobileObj:IsPlayer() ) then
		Death.Player.End(mobileObj)
	else
		Death.Npc.End(mobileObj)
	end

    mobileObj:SendMessage("Resurrected")
end

Death.Player = {}

function Death.Player.Start(playerObj)
	HidePlayerStatusElement(playerObj)
end
function Death.Player.End(playerObj)
	ShowPlayerStatusElement(playerObj)
end

Death.Npc = {}

function Death.Npc.Start(mobileObj)
	AIProperty.GenerateLoot(mobileObj)
end

function Death.Npc.End(mobileObj)

end