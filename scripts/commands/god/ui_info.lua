-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'commands.common.ui_objvar_edit'

-- INFO WINDOW

function GetObjVarsSorted(gameObj)
	local array = {}
	for key, value in pairs(gameObj:GetAllObjVars()) do
		table.insert(array,{name = key, value = value})		
	end
	table.sort(array,function(a,b) return a.name < b.name end)

	return array
end

curInfoObj = this
local curTab = "Behaviors"
local selObjVar = nil
function DoInfo(target)
    curInfoObj = target

   	if not(curInfoObj) then 
   		this:SystemMessage("Info Command: Invalid object")
   		return
   	end    
 
    local newWindow = DynamicWindow("InfoWindow","Object Info ("..curInfoObj.Id..")",440,500,0,0,"","TopLeft",-1,"")
 
    newWindow:AddLabel(20, 10, "[F3F781]Name: [-]"..(curInfoObj:GetName() or ""),600,0,18,"left",false)
    newWindow:AddLabel(20, 30, "[F3F781]Loc: [-]" ..tostring(curInfoObj:GetLoc()),600,0,18,"left",false)
    newWindow:AddLabel(20, 50, "[F3F781]Template: [-]"..tostring(curInfoObj:GetCreationTemplateId()),600,0,18,"left",false)
    newWindow:AddLabel(210, 50, "[F3F781]Hue: [-]"..tostring(curInfoObj:GetHue()),600,0,18,"left",false)
    if(curInfoObj:IsPlayer()) then
    	newWindow:AddLabel(295, 50, "[F3F781]UserId: [-]"..tostring(curInfoObj:GetAttachedUserId()),600,0,18,"left",false)
    else
	    newWindow:AddLabel(295, 50, "[F3F781]ClientId: [-]"..tostring(curInfoObj:GetIconId()),600,0,18,"left",false)
    end
    newWindow:AddLabel(20, 70, "[F3F781]Cloaked: [-]"..tostring(curInfoObj:IsCloaked()),600,0,18,"left",false)
    newWindow:AddLabel(115, 70, "[F3F781]Frozen: [-]"..tostring(curInfoObj:IsMobileFrozen()),600,0,18,"left",false)
    newWindow:AddLabel(200, 70, "[F3F781]Color: [-]"..tostring(curInfoObj:GetColor()),600,0,18,"left",false)
  
    newWindow:AddButton(320, 10, "Refresh", "Refresh", 80, 23, "", "", false,"")

  	if curInfoObj:IsMobile() then
        newWindow:AddLabel(20, 85, "[F3F781]Scale: [-]"..string.format("%4.2f",curInfoObj:GetScale().X),600,0,18,"left",false)
    end

    local behaviorState = ""
    if(curTab == "Behaviors") then
        behaviorState = "pressed"
    end
    local objvarState = ""
    if(curTab == "ObjVars") then
        objvarState = "pressed"
    end
    local statsState = ""
    if(curTab == "Stats") then
    	statsState = "pressed"
    end
    if(curInfoObj:IsMobile()) then
    	newWindow:AddButton(20,100,"BehaviorsTab","Behaviors",126,23,"","",false,"",behaviorState)
    	newWindow:AddButton(146,100,"ObjVarsTab","Variables",126,23,"","",false,"",objvarState)
    	newWindow:AddButton(272,100,"StatsTab","Stats",126,23,"","",false,"",statsState)
    else
	    newWindow:AddButton(20,100,"BehaviorsTab","Behaviors",190,23,"","",false,"",behaviorState)
    	newWindow:AddButton(210,100,"ObjVarsTab","Object Variables",190,23,"","",false,"",objvarState)
    end
 
    --newWindow:AddLabel(20, 100, "[F3F781]Behaviors:[-]",0,0,18,"left",true)
    newWindow:AddImage(20,130,"DropHeaderBackground",380,310,"Sliced")
 
    if(curTab == "Behaviors") then 
        local scrollWindow = ScrollWindow(25,135,355,225,25)
        for i,behavior in pairs(curInfoObj:GetAllModules()) do
            local scrollElement = ScrollElement()
            if((i-1) % 2 == 1) then
            scrollElement:AddImage(0,0,"Blank",320,25,"Sliced","242400")
            end    
            scrollElement:AddLabel(5, 5, behavior,0,0,18,"left")
            scrollElement:AddButton(210, 0, "", "Reload", 65, 23, "Reload Script", "reload "..behavior, false,"")
            scrollElement:AddButton(275, 0, "Detach|"..behavior, "Detach", 65, 23, "Detach Script", "", false,"")
            scrollWindow:Add(scrollElement)
        end
       
        newWindow:AddScrollWindow(scrollWindow)

        newWindow:AddImage(
					30,375,
					"Blank", --(string) sprite name
					260, --(number) width of the image
					20, --(number) height of the image
					"Sliced", --(string) sprite type Simple, Sliced or Object (defaults to Simple)
					"000000", --(string) sprite hue (defaults to white)
					0, -- hueindex
					0.9 --(number) (default 1.0)		
				)
        newWindow:AddTextField(33, 362, 260, 20,"Attach", "","",14)
        newWindow:AddButton(305, 375, "Attach", "Attach", 80, 23, "", "", false,"")
 
        newWindow:AddButton(40, 410, "SendMessage", "Send Message", 110, 23, "", "", false,"")
        newWindow:AddButton(155, 410, "FireTimer", "Fire Timer", 110, 23, "", "", false,"")
        newWindow:AddButton(270, 410, "Use", "Use", 110, 23, "", "", false,"")
    elseif(curTab == "ObjVars") then
        local array = GetObjVarsSorted(curInfoObj)
        local scrollWindow = ScrollWindow(25,135,355,250,25)
        for i,entry in pairs(array) do
            local scrollElement = ScrollElement()
            if((i-1) % 2 == 1) then
            scrollElement:AddImage(0,0,"Blank",330,25,"Sliced","242400")
            end    
 
            local varName = entry.name
            if( varName:len() > 25 ) then
                varName = varName:sub(1,22).."..."
            end
            scrollElement:AddLabel(5, 5, varName,0,0,18)
            local varType = type(entry.value)
            local valueLabel = nil
            if( varType == "userdata" or varType == "table") then
                valueLabel = "["..varType.."]"
            else
                valueLabel = tostring(entry.value)
            end
            scrollElement:AddLabel(200, 5, valueLabel,0,0,18)
 
            local selState = ""
            if(entry.name == selObjVar) then
                selState = "pressed"
            end
               
            scrollElement:AddButton(320, 0, "Select|"..entry.name, "", 0, 22, "", "", false, "Selection",selState)
            scrollWindow:Add(scrollElement)
        end
 
        newWindow:AddScrollWindow(scrollWindow)
        newWindow:AddButton(60, 400, "AddObjVar", "Add", 100, 23, "", "", false,"")
 
        local editState = selObjVar and "" or "disabled"
        newWindow:AddButton(160, 400, "EditObjVar", "Edit", 100, 23, "", "", false,"",editState)
        newWindow:AddButton(260, 400, "DelObjVar", "Delete", 100, 23, "", "", false,"",editState)      
    elseif(curTab == "Stats") then
    	local array = { "Health", "Mana", "Rage", "Accuracy", "Evasion", "Attack", "Power", "Defense", "AttackSpeed" }
        local scrollWindow = ScrollWindow(25,135,355,300,25)
        for i,statName in pairs(array) do
            local scrollElement = ScrollElement()
            if((i-1) % 2 == 1) then
            	scrollElement:AddImage(0,0,"Blank",330,25,"Sliced","242400")
            end    
 
            local varName = statName
            if( varName:len() > 25 ) then
                varName = varName:sub(1,22).."..."
            end
            scrollElement:AddLabel(5, 3, varName,0,0,18)
            if(curInfoObj:IsRegeneratingStat(statName)) then
            	scrollElement:AddLabel(180, 3, tostring(math.round(curInfoObj:GetStatValue(statName),2)),0,0,18)
            	scrollElement:AddLabel(240, 3, tostring(math.round(curInfoObj:GetStatMaxValue(statName)),2),0,0,18)
            	scrollElement:AddLabel(290, 3, tostring(math.round(curInfoObj:GetStatRegenRate(statName)),2),0,0,18)
            else
	            scrollElement:AddLabel(200, 3, tostring(math.round(curInfoObj:GetStatValue(statName)),2),0,0,18)
	        end
             
            scrollWindow:Add(scrollElement)
        end
 
        newWindow:AddScrollWindow(scrollWindow) 
   	end    
 
    this:OpenDynamicWindow(newWindow)
end

RegisterEventHandler(EventType.Timer,"DoInfo",
	function (target)
		if(target ~= nil) then
			DoInfo(target)
		end
	end)

-- Allow asynch operation to complete before refreshing the window
function DelayRefresh()
	this:ScheduleTimerDelay(TimeSpan.FromMilliseconds(300),"DoInfo",curInfoObj)
end

RegisterEventHandler(EventType.ClientTargetGameObjResponse, "info",
	function(target,user)
		if not(IsImmortal(this)) then return end

		if( target == nil ) then
			return
		end

		DoInfo(target)
	end)

function ParseMessageArgs(messageComps)

	table.remove(messageComps,1)

	for i,j in pairs(messageComps) do
		if (tonumber(j) ~= nil) then
			messageComps[i] = tonumber(j)
		elseif (j:match("#")) then
			messageComps[i] = GameObj(tonumber(j:sub(2)))
		end
	end

	return table.unpack(messageComps)
end

RegisterEventHandler(EventType.DynamicWindowResponse,"InfoWindow",
	function (user,returnId,fieldData)	

		if(returnId == "AddObjvar") then
			this:SendClientMessage("EnterChat","/setobjvar "..curInfoObj.Id.." ")
		elseif(returnId == "ToggleDebug") then
			if(curInfoObj:HasObjVar("Debug")) then
				curInfoObj:SetObjVar("Debug",true)
			else
				curInfoObj:DelObjVar("Debug")
			end			
		elseif(returnId == "BehaviorsTab") then
			curTab = "Behaviors"
			DoInfo(curInfoObj)
		elseif(returnId == "ObjVarsTab") then
			curTab = "ObjVars"
			DoInfo(curInfoObj)
		elseif(returnId == "StatsTab") then
			curTab = "Stats"
			DoInfo(curInfoObj)
		elseif(returnId:match("Detach")) then
			if(curInfoObj ~= nil) then
				local behavior = returnId:sub(8)
				curInfoObj:DelModule(behavior)
				DelayRefresh()
			end
		elseif(returnId == "Attach") then
			if(curInfoObj ~= nil and fieldData ~= nil and fieldData.Attach ~= nil and fieldData.Attach ~= "") then
				curInfoObj:AddModule(fieldData.Attach)
				DelayRefresh()
			end
		elseif(returnId:match("Select")) then
			selObjVar = returnId:sub(8)
			DoInfo(curInfoObj)
		elseif(returnId == "EditObjVar") then
			if(selObjVar ~= nil) then
				InitObjVarEditWindow(curInfoObj,selObjVar)
			end
		elseif(returnId == "DelObjVar") then
			if(selObjVar ~= nil) then
				curInfoObj:DelObjVar(selObjVar)
				DelayRefresh()
			end
		elseif(returnId == "AddObjVar") then
			selObjVar = nil
			objVarEditName = nil
			InitObjVarEditWindow(curInfoObj)
		elseif(returnId == "SendMessage" and fieldData ~= nil and fieldData.Attach ~= nil and fieldData.Attach ~= "") then		
			local fieldComps = StringSplit(fieldData.Attach," ")
			if(fieldComps ~= nil and #fieldComps > 0 and curInfoObj:IsValid()) then
				local msgName = fieldComps[1]
				curInfoObj:SendMessage(msgName,ParseMessageArgs(fieldComps))
				this:SystemMessage("Sent message "..msgName.." to "..curInfoObj:GetName())
			end			
		elseif(returnId == "FireTimer" and fieldData ~= nil and fieldData.Attach ~= nil and fieldData.Attach ~= "") then		
			local fieldComps = StringSplit(fieldData.Attach," ")
			if(fieldComps ~= nil and #fieldComps > 0 and curInfoObj:IsValid()) then
				local timerName = fieldComps[1]
				if(timerName ~= nil and timerName ~= "") then
					curInfoObj:FireTimer(timerName,ParseMessageArgs(fieldComps))
					this:SystemMessage("Fired timer "..timerName.." on "..curInfoObj:GetName())
				end
			end
		elseif(returnId == "Use") then		
			if(fieldData ~= nil and fieldData.Attach ~= nil and fieldData.Attach ~= "") then
				local fieldComps = StringSplit(fieldData.Attach," ")
				if(fieldComps ~= nil and #fieldComps > 0 and curInfoObj:IsValid()) then
					local useType = fieldComps[1]
					curInfoObj:SendMessage("UseObject",this,useType)
					this:SystemMessage("Fired UseObject type:"..useType.." on "..curInfoObj:GetName())
				end
			else
				curInfoObj:SendMessage("UseObject",this)
				this:SystemMessage("Fired UseObject on "..curInfoObj:GetName())
			end
		elseif(returnId == "Refresh") then
			DoInfo(curInfoObj)
		else
			curInfoObj = nil
			selObjVar = nil
		end
	end)

-- OBJVARS WINDOW

function ObjVarSaveFunc(objVarEditInfo)	
	objVarEditInfo.Target:SetObjVar(objVarEditInfo.Name,objVarEditInfo.Data)
	-- auto update the name color and pets etc.
	if ( objVarEditInfo.Name == "Karma" ) then
		objVarEditInfo.Target:SendMessage("UpdateName")
		SyncPetsToOwner(objVarEditInfo.Target)
	end
	this:SystemMessage("Objvar "..objVarEditInfo.Name.." set on target "..objVarEditInfo.Target:GetName().." ("..objVarEditInfo.Target.Id..")")
	-- update info window if its open
	if(curInfoObj ~= nil) then
		DelayRefresh()
	end
end

function InitObjVarEditWindow(targetObj, objVarName)
	local objVarData = nil
	if(objVarName ~= nil and objVarName ~= "") then 
		objVarData = targetObj:GetObjVar(objVarName)
	end
	local objVarType = GetValueType(objVarData)

	ObjVarEditWindow.Show{ 
		Name = objVarName or "",
		Target = targetObj,
		IsNew = (objVarName == nil),
		Type = objVarType,
		Data = objVarData,
		SaveFunc = ObjVarSaveFunc
	}
end