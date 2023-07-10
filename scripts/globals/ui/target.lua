-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



function BuildTargetElement(playerObj,targetObj)
	if ( targetObj == nil or not targetObj:IsMobile() ) then
		playerObj:CloseDynamicWindow("Target")
		return
	end

	local width = 154
	local height = 244

	local dynWindow = DynamicWindow("Target","",width,height,880,40,"Transparent","TopLeft",-1,"always")	
	
	dynWindow:AddPortrait(0,0,154,193,targetObj,"head_static")

	local modifiedName = StripColorFromString(targetObj:GetName())
	if(not(modifiedName) or modifiedName == "") then
		modifiedName = Object.Template(targetObj)
	end

	dynWindow:AddStatBar(
		0,
		204,			
		154,
		28,
		"Health",
		"ff6a6a",
		targetObj)

	if ( Var.Has(targetObj, "Boss") ) then
		dynWindow:AddImage(-12,150,"skull",44,44)
	end

	dynWindow:AddLabel(width/2,244,modifiedName,180,100,40,"center",false,true,"Bonfire_Dynamic")

	return dynWindow
end

function ShowTargetElement(playerObj,targetObj)
	local element = BuildTargetElement(playerObj, targetObj)
	if ( element ~= nil ) then
		playerObj:OpenDynamicWindow(element)
	end
end