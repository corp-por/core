-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


function HookPlayerStatusElement(playerObj, statusWindow)

end

function HidePlayerStatusElement(playerObj)
	playerObj:CloseDynamicWindow("playerstatus")
end

function ShowPlayerStatusElement(playerObj)
	if ( Death.Active(playerObj) ) then
		HidePlayerStatusElement(playerObj)
		return
	end

	local statusWindow = DynamicWindow("playerstatus","",0,0,60,40,"Transparent","TopLeft",-1,"always")

	statusWindow:AddPortrait(0,0,154,193,playerObj,"head_static")
	
	statusWindow:AddLabel(190,50,tostring(StripColorFromString(playerObj:GetName())),600,100,42,"",false,true,"Bonfire_Dynamic")
	statusWindow:AddStatBar(
		190,
		98,
		400,
		38,
		"Health",		
		"ff6a6a",
		playerObj)

	--[[statusWindow:AddImage(610,95,"Heal",40,40)
    statusWindow:AddLabel(676,102,"[E2E5E6][STAT:Health][-]",0,0,40)]]
    
    HookPlayerStatusElement(playerObj, statusWindow)

    -- TODO: Groups!
    --[[
	local groupId = playerObj:GetObjVar("Group")
	if ( groupId ~= nil and GetGroupVar(groupId, "Leader") == playerObj ) then
		statusWindow:AddImage(180,50, "GroupLeaderIcon", 0, 0)
    end
    ]]

	playerObj:OpenDynamicWindow(statusWindow)
end