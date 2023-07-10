-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ClientDialog = {}

function ClientDialog.Show(args)
	args.TargetUser = args.TargetUser
	args.SourceObject = args.SourceObject
	args.ResponseObj = args.ResponseObj
	args.DialogId = args.DialogId or ("Dialog"..uuid())
	args.TitleStr = args.TitleStr
	args.DescStr = args.DescStr or ""
	-- if no dialog source, force remote
	if not(args.DialogSource) then
		args.IsRemote = true
	end

	local responses = {  }
	-- if neither button is set, then use the default confirm, cancel
	if( args.Button1Str ) then
		table.insert(responses,{ handle="0", text=args.Button1Str, close=true})
	end

	if( args.Button2Str ) then
		table.insert(responses,{ handle="1", text=args.Button2Str, close=true})
	end

	-- no buttons passed in so just use defaults
	if(#responses == 0) then
		responses = { { handle="Confirm", text="I accept.", close=true }, { handle="Cancel", text="I decline.", close=true} }
	end

	local maxDistance = nil
	if(args.IsRemote) then
		maxDistance = -1
	end
	NPCInteraction(args.DescStr,args.SourceObject,args.TargetUser,args.DialogId,responses,args.TitleStr,maxDistance)

	if(args.ResponseFunc ~= nil) then
		RegisterSingleEventHandler(EventType.DynamicWindowResponse,args.DialogId,
			function(user,buttonId)
				args.ResponseFunc(user,tonumber(buttonId))
			end)
	end
end

-- sends nil to response func if user cancelled
TextFieldDialog = {}
function TextFieldDialog.Show(args)
	args.TargetUser = args.TargetUser
	args.ResponseObj = args.ResponseObj
	args.DialogId = args.DialogId or ("TextEntry"..uuid())
	args.Title = args.Title or args.TargetUser:GetName()
	args.Description = args.Description or "Enter your text here"
	args.InitialValue = args.InitialValue or ""

	if (args.TargetUser == nil) then
		--DebugMessage("invalid user")
		return
	end

	local userType = GetValueType(args.TargetUser)
	if(userType ~= "GameObj") then
		LuaDebugCallStack("ERROR: User parameter is of wrong type: "..userType)
		return
	end

	if(not args.TargetUser:IsValid()) then
		return
	end

	--DebugMessage("Title is "..tostring(title))
	width = 1880
	height = 1000 
	local npcWindow = DynamicWindow(args.DialogId,"",0,0,-(width/2),-1000,"Transparent","Bottom",-1,"lockedui")
	
	npcWindow:AddImage(
			0, --(number) x position in pixels on the window
			300, --(number) y position in pixels on the window
			"Scroll_BG", --(string) sprite name
			0, --(number) width of the image
			0, --(number) height of the image
			"", --(string) sprite type Simple, Sliced or Object (defaults to Simple)
			"", --(string) sprite hue (defaults to white)
			0, -- hueindex
			1 --(number) (default 1.0)		
		)

	if(args.TargetUser) then
		npcWindow:AddPortrait(330,40,304,585,args.TargetUser,"body_static")
	end

	npcWindow:AddLabel(620,360,"[F2F5A9]"..StripColorFromString(args.Title):upper().."[-]",0,0,56,"left",false,false,"Bonfire_Dynamic")
	npcWindow:AddLabel(620,420,args.Description,1186,320,38,"left",false,false,"Bonfire_Dynamic")

	npcWindow:AddTextField(620, 480, 800,60, "entry", args.InitialValue)

	local responses = { { handle = "Close", text = "Nevermind" }, { handle = "Enter", text = "Ok"} }
	
	local elementWidth = 400
	local responseWidth = elementWidth * #responses
	local curX = width/2 - responseWidth/2
	local curY = 580
	local k = 1	
	for i,j in pairs(responses) do
		if (responses[i] ~= nil) then				
			local closeOnClick = true

			if (k==1) then				
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==2) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end

			curX = curX + elementWidth
			k = k + 1
		end
	end
	--DebugMessage("User is "..tostring(args.TargetUser:GetName()))
	args.TargetUser:OpenDynamicWindow(npcWindow,args.ResponseObj)	
	--DebugMessage("Window Opened")

    if(args.ResponseFunc ~= nil) then
    	RegisterSingleEventHandler(EventType.DynamicWindowResponse,args.DialogId,
			function(user,buttonId,fieldData)
				if(buttonId == "Enter" or buttonId == "TextFieldEnter") then
					local result = StripTrailingNewline(fieldData.entry)
					args.ResponseFunc(user,result)
					args.TargetUser:CloseDynamicWindow(args.DialogId)	
				else
					args.ResponseFunc(user)
				end
			end)
	end
end

ButtonMenu = {}
function ButtonMenu.Show(args)
	if(args.Buttons == nil or #args.Buttons == 0
			or args.TargetUser == nil or not(args.TargetUser:IsValid())) then 
		DebugMessage("ERROR: Invalid ButtonMenu arguments see ButtonMenu.Show in incl_dialogwindow.lua")
		return
	end

	if(not(args.TargetUser:IsPlayer())) then
		DebugMessage("ERROR: Sending ButtonMenu to NPC. NPCs cannot pick buttons!")
		return
	end

	args.ResponseObj = args.ResponseObj or args.TargetUser		

	local dialogId = args.DialogId or "ButtonMenu"
	local titleStr = args.TitleStr or ""
	-- can be index or str
	local responseType = args.ResponseType or "index"	
	local numButtons = #args.Buttons
	local size = args.Size or 200
	
	local closeOnClick = true
	if(args.CloseOnClick == false) then closeOnClick = false end

	local yPadding = 70
	if(args.SubtitleStr) then
		yPadding = yPadding + 20
	end

	if(numButtons <= 6) then
		local newWindow = DynamicWindow(dialogId,titleStr,size+42,yPadding + (numButtons*26),0,0,"")

		local startY = 5
		if(args.SubtitleStr) then
			newWindow:AddLabel((size+20)/2,4,args.SubtitleStr,size,20,20,"center")
			startY = startY + 20
		end
		
		for i,buttonData in pairs(args.Buttons) do
			local yVal = startY + (i-1)*26
			local buttonId = tostring(i)
			local buttonStr = buttonData
			local tooltipStr = ""
			if(responseType == "str") then
				buttonId = buttonData
				buttonStr = buttonData
			elseif(responseType == "id") then
				buttonId = buttonData.Id
				buttonStr = buttonData.Text
				buttonTooltip = buttonData.Tooltip or ""
			end
			newWindow:AddButton(10, yVal, buttonId, buttonStr, size, 26, buttonTooltip, "", closeOnClick,"List")
		end
		args.TargetUser:OpenDynamicWindow(newWindow,args.ResponseObj)
	else
		local newWindow = DynamicWindow(dialogId,titleStr,size+42,yPadding + (6*26),0,0,"")
		local startY = 10
		if(args.SubtitleStr) then
			newWindow:AddLabel((size+20)/2,4,args.SubtitleStr,size,20,20,"center")
			startY = startY + 20
		end

		local scrollWindow = ScrollWindow(10,startY,size,156,26)
		for i,buttonData in pairs(args.Buttons) do
			local scrollElement = ScrollElement()
			local buttonId = tostring(i)
			local buttonStr = buttonData
			local tooltipStr = ""
			if(responseType == "str") then
				buttonId = buttonData
				buttonStr = buttonData
			elseif(responseType == "id") then
				buttonId = buttonData.Id
				buttonStr = buttonData.Text
				buttonTooltip = buttonData.Tooltip or ""
			end
			scrollElement:AddButton(0, 0, buttonId, buttonStr, size-10, 26, buttonTooltip, "", closeOnClick,"List")
			scrollWindow:Add(scrollElement)
		end
		newWindow:AddScrollWindow(scrollWindow)
		args.TargetUser:OpenDynamicWindow(newWindow,args.ResponseObj)
	end	

	if(args.ResponseFunc ~= nil) then
		RegisterSingleEventHandler(EventType.DynamicWindowResponse,dialogId,
			function(user,buttonId)
				local response = buttonId
				if(responseType == "index") then
					response = tonumber(buttonId)
				end
				args.ResponseFunc(user,response)
			end)
	end
end

-- Args table
--     Anchor (Window Anchor) (Default Center)
-- 	   X (Default 0)
--     Y (Default -100)
--     Width (Default 200)
--     Label: Label text (Default empty)
--     BarColor (Default C45E05 - Orange)
--     Duration: Duration in seconds (Default 1)
--     TargetUser: Target user to show window 
--     DialogId: Id of window (must be unique to have more than one at the same time. Default Label)
--     PresetLocation: Currently supported "UnderPlayer" (default) and "AboveHotbar"
-- NOTE: Height is not yet supported for the progress bar widget
ProgressBar = {}
function ProgressBar.Show(args)
	--DebugMessage("ProgressBar.Show",DumpTable(args))
	args = args or {}
	args.Anchor = args.Anchor or "Center"
	args.X = args.X or 0
	args.Y = args.Y or 200
	args.Width = args.Width or 400
	args.Label = args.Label or ""
	args.BarColor = args.BarColor or ""
	args.Duration = args.Duration or TimeSpan.FromSeconds(1.0)
	if(type(args.Duration) == "number") then
		args.Duration = TimeSpan.FromSeconds(args.Duration)
	end
	args.DialogId = args.DialogId or args.Label
	args.TargetUser = args.TargetUser
	args.SourceObject = args.SourceObject or args.TargetUser
	args.CanCancel = args.CanCancel or false
	args.Callback = args.Callback or function()end

	if(args.PresetLocation == "UnderPlayer") then
		args.Anchor = "Center"
		args.X = 0
		args.Y = 340
	elseif(args.PresetLocation == "AboveHotbar") then
		args.Anchor = "Bottom"
		args.X = 0
		args.Y = -240
	end

	local progressBarWidth = args.Width
	if(args.CanCancel) then 
		progressBarWidth = progressBarWidth - 44 
	end

	local newWindow = DynamicWindow(args.DialogId,"",0,0,0,0,"Transparent",args.Anchor,-1,"always")	
	newWindow:AddProgressBar(args.X,args.Y,progressBarWidth,0,args.Label,args.Duration.TotalSeconds,true,args.BarColor)
	if(args.CanCancel) then
		newWindow:AddButton(args.Width/2 - 22,args.Y - 11,"Close","",22,22,"","",true,"CloseSquare")
	end

	args.TargetUser:OpenDynamicWindow(newWindow,args.SourceObject)

	RegisterSingleEventHandler(EventType.Timer,args.DialogId.."Close",
		function()
			args.TargetUser:CloseDynamicWindow(args.DialogId)
			args.Callback()
		end)

	if(args.CancelFunc) then
		RegisterSingleEventHandler(EventType.DynamicWindowResponse,args.DialogId,
			function(user,buttonId)
				if(buttonId == "Close") then
					args.CancelFunc(args.DialogId)
				end
			end)
	end

	args.SourceObject:ScheduleTimerDelay(args.Duration,args.DialogId.."Close")
end

function ProgressBar.Cancel(dialogId,user)
	--DebugMessage("ProgressBar.Cancel",tostring(dialogId),tostring(user))
	user = user or this
	user:CloseDynamicWindow(dialogId)
end

function NPCInteraction(text,npc,user,windowHandle,responses,title,max_distance,responseObj)
	if (user == nil) then
		--DebugMessage("invalid user")
		return
	end

	local userType = GetValueType(user)
	if(userType ~= "GameObj") then
		LuaDebugCallStack("ERROR: User parameter is of wrong type: "..userType)
		return
	end

	if(not user:IsValid()) then
		return
	end

	if (npc ~= nil and IsDead(npc) and not npc:HasObjVar("UseableWhileDead")) then 
		--DebugMessage("dead npc or user")
		return
	end

	max_distance = max_distance or OBJECT_INTERACTION_RANGE
	if (type(max_distance) == "string") then max_distance = OBJECT_INTERACTION_RANGE end
	if (npc ~= nil and max_distance ~= -1 and (max_distance >= 0 and npc:DistanceFrom(user) > max_distance)) then
		--LuaDebugCallStack("ERROR: NPCInteraction sent for mob out of range: "..max_distance)
		return 
	end

	if(npc ~= nil) then
		npc:SendMessage("WakeUp")
	end

	if((title == nil or type(title) ~= "string")) then
		if(npc ~= nil) then
			title = npc:GetName()
		else
			title = ""
		end
	end
	--DebugMessage("Title is "..tostring(title))
	width = 1880
	height = 1000 
	local npcWindow = DynamicWindow(windowHandle,"",0,0,-(width/2),-1000,"Transparent","Bottom",-1,"lockedui")
	
	npcWindow:AddImage(
			0, --(number) x position in pixels on the window
			300, --(number) y position in pixels on the window
			"Scroll_BG", --(string) sprite name
			0, --(number) width of the image
			0, --(number) height of the image
			"", --(string) sprite type Simple, Sliced or Object (defaults to Simple)
			"", --(string) sprite hue (defaults to white)
			0, -- hueindex
			1 --(number) (default 1.0)		
		)

	if(npc) then
		npcWindow:AddPortrait(330,40,304,585,npc,"body_static")
	end

	npcWindow:AddLabel(620,360,"[F2F5A9]"..StripColorFromString(title):upper().."[-]",0,0,56,"left",false,false,"Bonfire_Dynamic")
	npcWindow:AddLabel(620,420,text,850,320,38,"left",false,false,"Bonfire_Dynamic")

	if (responses == nil) then
		responses = {}
		responses[1] = {}
		responses[1].handle = "Close"
		responses[1].text = "Okay."
	end

	if (type(responses) == "string") then
		LuaDebugCallStack("[incl_dialogwindow] responses is a string value")
	end

	local elementWidth = 400
	local responseWidth = elementWidth * #responses
	local curX = width/2 - responseWidth/2
	local curY = 580
	local k = 1	
	for i,j in pairs(responses) do
		if (responses[i] ~= nil) then				
			local closeOnClick = not(j.handle) or j.handle == "" or j.handle == "Close" or j.close ~= nil

			if (k==1) then				
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==2) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==3) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==4) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==5) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end
			if (k==6) then
				npcWindow:AddButton(curX,curY,j.handle,j.text,elementWidth,46,"","",closeOnClick,"Text")
			end

			curX = curX + elementWidth
			k = k + 1
		end
	end
	--DebugMessage("User is "..tostring(user:GetName()))
	user:OpenDynamicWindow(npcWindow,responseObj)	
	--DebugMessage("Window Opened")

	if (npc ~= nil and max_distance ~= -1) then
		user:SendMessage("DynamicWindowRangeCheck",npc,windowHandle,max_distance)
	end
end

function TaskDialogNotification(user,text,title)
 	NPCInteraction(text,nil,user,"Responses",nil,nil,title)
end

function QuickDialogMessage(source,user,text,max_distance)
	--DebugMessage("Text is " ..text,"User is" ..tostring(user))
	NPCInteraction(text,source,user,"Responses",nil,source:GetName(),max_distance,true)
end

function DialogReturnMessage(source,user,text,button)
    response = {}

    response[1] = {}
    response[1].text = button
    response[1].handle = "Nevermind" 

    NPCInteraction(text,source,user,"Responses",response)
end

function DialogEndMessage(source,user,text,button)
    response = {}

    response[1] = {}
    response[1].text = button
    response[1].handle = "" 

    NPCInteraction(text,source,user,"Responses",response)
end