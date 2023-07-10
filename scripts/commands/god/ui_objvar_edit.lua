-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- OBJVAR EDIT WINDOW

objVarEditInfo = nil
local selObjVar = ""

local keyTable = {}
local originalData = nil

function ValidateEditData()
	return objVarEditInfo.Target ~= nil 
		and objVarEditInfo.Target:IsValid() 
		and objVarEditInfo.Name ~= nil 
		and objVarEditInfo.Name ~= ""
		and objVarEditInfo.Type ~= nil
		and objVarEditInfo.Type ~= ""
		and objVarEditInfo.Data[objVarEditInfo.Type] ~= nil
end

function RefreshObjVarEditWindow()
	local windowHeight = 320
	if(objVarEditInfo.Type == "table") then
		windowHeight = 500
	end

	local newWindow = DynamicWindow("ObjVarEditWindow","Edit ObjVar",450,windowHeight,0,0,"","TopLeft",-1,"")

	newWindow:AddLabel(20, 20, "[F3F781]Name:[-]",600,0,18,"left",false)
	if(objVarEditInfo.IsNew) then
		newWindow:AddTextField(80, 20, 260,20, "ObjVarName", objVarEditInfo.Name,"",14)
	else
		newWindow:AddLabel(80, 20, objVarEditInfo.Name,600,0,18,"left",false)
	end

	newWindow:AddLabel(20, 50, "[F3F781]Type:[-]",600,0,18,"left",false)
	
	if not(objVarEditInfo.ExcludeTypes.string) then
		newWindow:AddButton(80, 50, "ObjectType|string", "string", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"string"))
	end
	if not(objVarEditInfo.ExcludeTypes.number) then
		newWindow:AddButton(210, 50, "ObjectType|number", "number", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"number"))
	end
	if not(objVarEditInfo.ExcludeTypes.Loc) then
		newWindow:AddButton(340, 50, "ObjectType|Loc", "Loc", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"Loc"))
	end
	if not(objVarEditInfo.ExcludeTypes.boolean) then
		newWindow:AddButton(80, 80, "ObjectType|boolean", "boolean", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"boolean"))
	end
	if not(objVarEditInfo.ExcludeTypes.table) then
		newWindow:AddButton(210, 80, "ObjectType|table", "table", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"table"))	
	end
	if not(objVarEditInfo.ExcludeTypes.GameObj) then
		newWindow:AddButton(80, 110, "ObjectType|GameObj", "GameObj", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"GameObj"))
	end
	if not(objVarEditInfo.ExcludeTypes.PermanentObj) then
		newWindow:AddButton(210, 110, "ObjectType|PermanentObj", "PermanentObj", 100, 23, "", "", false,"Selection",GetButtonState(objVarEditInfo.Type,"PermanentObj"))
	end

	newWindow:AddImage(20,150,"Divider",360,1,"Sliced")

	if(objVarEditInfo.Type == "string") then
		newWindow:AddLabel(20, 163, "[F3F781]Value:[-]",600,0,18,"left",false)
		newWindow:AddTextField(80, 160, 300,20, "StringValue", objVarEditInfo.Data.string or "","",14)
	elseif(objVarEditInfo.Type == "number") then
		newWindow:AddLabel(20, 163, "[F3F781]Value:[-]",600,0,18,"left",false)
		newWindow:AddTextField(80, 160, 300,20, "NumberValue", objVarEditInfo.Data.number and tostring(objVarEditInfo.Data.number) or "","",14)
	elseif(objVarEditInfo.Type == "Loc") then
		newWindow:AddLabel(20, 163, "[F3F781]X:[-]",600,0,18,"left",false)
		newWindow:AddTextField(40, 160, 100,20, "LocXValue", objVarEditInfo.Data.Loc and tostring(objVarEditInfo.Data.Loc.X) or "","",14)
		newWindow:AddLabel(150, 163, "[F3F781]Y:[-]",600,0,18,"left",false)
		newWindow:AddTextField(170, 160, 100,20, "LocYValue", objVarEditInfo.Data.Loc and tostring(objVarEditInfo.Data.Loc.Y) or "","",14)
		newWindow:AddLabel(280, 163, "[F3F781]Z:[-]",600,0,18,"left",false)
		newWindow:AddTextField(300, 160, 100,20, "LocZValue", objVarEditInfo.Data.Loc and tostring(objVarEditInfo.Data.Loc.Z) or "","",14)

		newWindow:AddButton(30, 210, "SelectLoc", "Select Loc", 150, 23, "", "", false,"")
	elseif(objVarEditInfo.Type == "boolean") then		
		newWindow:AddLabel(20, 163, "[F3F781]Value:[-]",600,0,18,"left",false)
		local trueButtonState = (objVarEditInfo.Data.boolean or false) and "pressed" or ""		
		newWindow:AddButton(80, 163, "BoolVal|true", "True", 100, 23, "", "", false,"Selection",trueButtonState)
		local falseButtonState = (objVarEditInfo.Data.boolean or false) and "" or "pressed"
		newWindow:AddButton(210, 163, "BoolVal|false", "False", 100, 23, "", "", false,"Selection",falseButtonState)
	elseif(objVarEditInfo.Type == "GameObj") then
		newWindow:AddLabel(20, 163, "[F3F781]Value:[-]",600,0,18,"left",false)
		newWindow:AddTextField(80, 160, 300,20, "GameObjValue", objVarEditInfo.Data.GameObj and tostring(objVarEditInfo.Data.GameObj.Id) or "","",14)

		newWindow:AddButton(30, 210, "SelectObj", "Select Object", 150, 23, "", "", false,"")
	elseif(objVarEditInfo.Type == "PermanentObj") then
		newWindow:AddLabel(20, 163, "[F3F781]Value:[-]",600,0,18,"left",false)
		newWindow:AddTextField(80, 160, 300,20, "PermanentObjValue", objVarEditInfo.Data.PermanentObj and tostring(objVarEditInfo.Data.PermanentObj.Id) or "","",14)

		newWindow:AddButton(30, 210, "SelectPermObj", "Select Object", 150, 23, "", "", false,"")
	elseif(objVarEditInfo.Type == "table") then
		if(objVarEditInfo.Data.table == nil) then
			newWindow:AddLabel(20, 163, "Table editing coming soon (tm)",0,0,18,"left",false)
		else
			

			local scrollWindow = ScrollWindow(25,155,355,250,25)

			local indexTable = 1

			for index,value in pairs(objVarEditInfo.Data.table) do

				local scrollElement = ScrollElement()

				if((indexTable-1) % 2 == 1) then
	            	scrollElement:AddImage(0,0,"Blank",330,25,"Sliced","242400")
	            end

				scrollElement:AddLabel(14, 6, tostring(index), 0, 0, 18)

				local varType = type(value)
				local valueLabel = nil

				if (varType == "userdata" or varType == "table") then
					valueLabel = "["..varType.."]"
				else
					valueLabel = tostring(value)
				end

				scrollElement:AddLabel(200, 6, valueLabel, 0, 0, 18)

				local selState = ""

				if (tostring(index) == selObjVar) then
					selState = "pressed"
				end

				scrollElement:AddButton(320, 3, "Select|"..tostring(index), "", 0, 11, "", "", false, "Selection", selState)

	            indexTable = indexTable + 1

	            scrollWindow:Add(scrollElement)
			end

			local editState = selObjVar and "" or "disabled"

			newWindow:AddButton(60, 400, "AddTable|"..selObjVar, "Add", 100, 23, "", "", false, "", editState)
			newWindow:AddButton(160, 400, "EditTable|"..selObjVar, "Edit", 100, 23, "", "", false, "", editState)
			newWindow:AddButton(260, 400, "DeleteTable|"..selObjVar, "Delete", 100, 23, "", "", false, "", editState)

			newWindow:AddScrollWindow(scrollWindow)
		end
	end

	if(objVarEditInfo.Type ~= "table") then
		newWindow:AddButton(310, windowHeight - 90, "SaveObjVar", "Save", 100, 23, "", "", true,"")
	end

	objVarEditInfo.TargetUser:OpenDynamicWindow(newWindow,this)
end

local TableEditButtonType = ""
local tableKey = ""
local booleanValue = nil
RegisterEventHandler(EventType.DynamicWindowResponse,"ObjVarEditWindow",
	function (user,returnId,fieldData)
		if (returnId == "") then
			keyTable = {}
			originalData = nil
		end

		if(fieldData ~= nil) then
			if(fieldData.ObjVarName ~= nil) then
				objVarEditInfo.Name = fieldData.ObjVarName
			end

			if(fieldData.StringValue ~= nil) then
				objVarEditInfo.Data.string = fieldData.StringValue
			end

			if(fieldData.NumberValue ~= nil) then
				objVarEditInfo.Data.number = tonumber(fieldData.NumberValue)
			end

			if(fieldData.LocXValue ~= nil and fieldData.LocYValue ~= nil and fieldData.LocZValue ~= nil) then
				local locX, locY, locZ = tonumber(fieldData.LocXValue), tonumber(fieldData.LocYValue), tonumber(fieldData.LocZValue)
				if(locX ~= nil and locY ~= nil and locZ ~= nil) then
					objVarEditInfo.Data.Loc = Loc(locX, locY, locZ)													
				end
			end

			if(fieldData.GameObjValue ~= nil) then
				local id = tonumber(fieldData.GameObjValue)
				if(id ~= nil) then
					objVarEditInfo.Data.GameObj = GameObj(id)
				end
			end

			if(fieldData.PermanentObjValue ~= nil) then
				local id = tonumber(fieldData.PermanentObjValue)
				if(id ~= nil) then
					objVarEditInfo.Data.PermanentObj = GameObj(id)
				end
			end
		end

		if(returnId:match("ObjectType")) then
			objVarEditInfo.Type = returnId:sub(12)
			RefreshObjVarEditWindow()
		elseif(returnId == "SaveObjVar") then			
			if(ValidateEditData()) then
				if(objVarEditInfo.SaveFunc ~= nil) then
					objVarEditInfo.Data = objVarEditInfo.Data[objVarEditInfo.Type]
					objVarEditInfo.SaveFunc(objVarEditInfo)
				end
			else
				objVarEditInfo.TargetUser:SystemMessage("Objvar edit data failed validation. Try again.")
				RefreshObjVarEditWindow()
			end
		elseif(returnId == "SelectLoc") then
			objVarEditInfo.TargetUser:RequestClientTargetLoc(this, "SelectObjVarLoc")
		elseif(returnId == "SelectObj") then
			objVarEditInfo.TargetUser:RequestClientTargetGameObj(this, "SelectObjVarObj")
		elseif(returnId == "SelectPermObj") then
			objVarEditInfo.TargetUser:RequestClientTargetAnyObj(this, "SelectObjVarPermObj")
		elseif(returnId:match("BoolVal")) then			
			if(objVarEditInfo ~= nil) then
				objVarEditInfo.Data.boolean = (returnId:match("true") ~= nil)
				RefreshObjVarEditWindow()
			end
		end

		if (returnId:match("Select")) then
			selObjVar = returnId:sub(8)
			RefreshObjVarEditWindow()
			return
		elseif (returnId:match("AddTable")) then
			tableKey = nil
			TableEditButtonType = "string"
			booleanValue = nil
			RefreshTableEditWindow()
			return
		elseif (returnId:match("EditTable")) then
			tableKey = returnId:sub(11)

			valueType = ""
			local objVarValue = nil

			for key,value in pairs(objVarEditInfo.Data.table) do
				if (tostring(key) == tableKey) then
					valueType = type(value)
					objVarValue = value
					break
				end
			end

			if (valueType == "table") then
				table.insert(keyTable, tableKey)

				ObjVarEditWindow.Show
				{
					Name = objVarEditInfo.Name or "",
					Target = objVarEditInfo.Target,
					IsNew = (objVarEditInfo.Name == nil),
					Type = "table",
					Data = objVarValue,
					SaveFunc = objVarEditInfo.SaveFunc
				}
			else
				TableEditButtonType = "string"
				booleanValue = nil
				RefreshTableEditWindow()
			end
			return
		elseif (returnId:match("DeleteTable")) then
			tableKey = returnId:sub(13)

			local originalTable = originalData.table

			for key,value in pairs(keyTable) do
				for i,j in pairs(originalTable) do
					if (tostring(i) == value) then
						originalTable = originalTable[i]
						break
					end
				end
			end

			local objVarTable = objVarEditInfo.Data.table

			objVarTable[tableKey] = null

			originalTable = objVarTable

			if(ValidateEditData()) then
				if(objVarEditInfo.SaveFunc ~= nil) then
					objVarEditInfo.Data = originalData[objVarEditInfo.Type]
					objVarEditInfo.SaveFunc(objVarEditInfo)
				end
			else
				objVarEditInfo.TargetUser:SystemMessage("Objvar edit data failed validation. Try again.")
				RefreshTableEditWindow()
				RefreshObjVarEditWindow()
			end

			return
		end
	end)

function RefreshTableEditWindow()
	local windowHeight = 320

	local newWindow = DynamicWindow("EditTableWindow", "Edit Table", 450, windowHeight)

	local tableValue = ""

	for key,value in pairs(objVarEditInfo.Data.table) do
		if (tostring(key) == tableKey) then
			tableValue = value
			if (booleanValue == nil) then
				booleanValue = value
			end
		end
	end

	newWindow:AddLabel(20, 20, "[F3F781]Table Key:[-]",600,0,18,"left",false)
	newWindow:AddLabel(20, 170, "[F3F781]Table Value:[-]",600,0,18,"left",false)

	newWindow:AddTextField(100, 17, 300, 20, "updateTableKey", tableKey or "")

	newWindow:AddButton(300, 230, "SaveTable", "Save", 100, 23, "", "", false,"")

	newWindow:AddLabel(20, 70, "[F3F781]Type:[-]",600,0,18,"left",false)

	newWindow:AddButton(80, 70, "Type|string", "string", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType,"string"))

	newWindow:AddButton(210, 70, "Type|number", "number", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType,"number"))

	newWindow:AddButton(340, 70, "Type|Loc", "Loc", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType,"Loc"))

	newWindow:AddButton(80, 100, "Type|boolean", "boolean", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType, "boolean"))

	newWindow:AddButton(210, 100, "Type|table", "table", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType, "table"))

	newWindow:AddButton(80, 130, "Type|GameObj", "GameObj", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType, "GameObj"))

	newWindow:AddButton(210, 130, "Type|PermanentObj", "PermanentObj", 100, 23, "", "", false, "Selection", GetButtonState(TableEditButtonType, "PermanentObj"))

	if (TableEditButtonType == "boolean") then
		newWindow:AddButton(40, 200, "BooleanVal|true", "True", 100, 23, "", "", false, "Selection", GetButtonState(booleanValue, true))
		newWindow:AddButton(140, 200, "BooleanVal|false", "False", 100, 23, "", "", false, "Selection", GetButtonState(booleanValue, false))
	elseif (TableEditButtonType == "Loc") then
		newWindow:AddLabel(20, 198, "[F3F781]X:[-]",100,0,18,"left",false)
		newWindow:AddTextField(40, 195, 100, 20, "updateXLoc")
		newWindow:AddLabel(150, 198, "[F3F781]Y:[-]",100,0,18,"left",false)
		newWindow:AddTextField(170, 195, 100, 20, "updateYLoc")
		newWindow:AddLabel(280, 198, "[F3F781]Z:[-]",100,0,18,"left",false)
		newWindow:AddTextField(300, 195, 100, 20, "updateZLoc")
	else
		newWindow:AddTextField(20, 195, 390, 20, "updateTableValue", tostring(tableValue) or "")
	end

	objVarEditInfo.TargetUser:OpenDynamicWindow(newWindow,this)
end

RegisterEventHandler(EventType.DynamicWindowResponse, "EditTableWindow",
	function(user, returnId, fieldData)

		if (returnId:match("Type")) then
			local valueType = returnId:sub(6)

			TableEditButtonType = valueType

			RefreshTableEditWindow()
			return
		end

		if (returnId:match("BooleanVal")) then
			local booleanChosen = returnId:sub(12)

			if (booleanChosen == "true") then
				booleanValue = true
			else
				booleanValue = false
			end

			RefreshTableEditWindow()
			return
		end

		if (returnId == ("SaveTable")) then

			local originalTable = originalData.table

			for key,value in pairs(keyTable) do
				for i,j in pairs(originalTable) do
					if (tostring(i) == value) then
						originalTable = originalTable[i]
						break
					end
				end
			end

			local objVarTable = objVarEditInfo.Data.table

			local objVarValue = fieldData.updateTableValue

			if (TableEditButtonType == "number") then
				objVarValue = tonumber(objVarValue)
			elseif (TableEditButtonType == "boolean") then
				objVarValue = booleanValue
			elseif (TableEditButtonType == "Loc") then
				local locX, locY, locZ = tonumber(fieldData.updateXLoc), tonumber(fieldData.updateYLoc), tonumber(fieldData.updateZLoc)
				if(locX ~= nil and locY ~= nil and locZ ~= nil) then
					objVarValue = Loc(locX, locY, locZ)
				end
			end

			if (fieldData.updateTableKey == nil or fieldData.updateTableKey == "") then
				objVarEditInfo.TargetUser:SystemMessage("Table Key cannot be empty.")
				return
			end

			if (tableKey ~= fieldData.updateTableKey) then
				if (objVarTable[tableKey] ~= nil) then
					objVarTable[tableKey] = nil
				elseif(tonumber(tableKey) ~= nil and objVarTable[tonumber(tableKey)] ~= nil) then
					objVarTable[tonumber(tableKey)] = nil
				end

				tableKey = fieldData.updateTableKey
			end

			objVarTable[tableKey] = objVarValue

			originalTable = objVarTable

			if(ValidateEditData()) then
				if(objVarEditInfo.SaveFunc ~= nil) then
					objVarEditInfo.Data = originalData[objVarEditInfo.Type]
					objVarEditInfo.SaveFunc(objVarEditInfo)
				end
			else
				objVarEditInfo.TargetUser:SystemMessage("Objvar edit data failed validation. Try again.")
				RefreshTableEditWindow()
				RefreshObjVarEditWindow()
			end
		end
	end)

RegisterEventHandler(EventType.ClientTargetLocResponse, "SelectObjVarLoc", 
	function (success, targetLoc)	
		if(success) then
			if(objVarEditInfo ~= nil) then
				objVarEditInfo.Data.Loc = targetLoc
				RefreshObjVarEditWindow()
			end
		end
	end)

RegisterEventHandler(EventType.ClientTargetGameObjResponse, "SelectObjVarObj", 
    function(target,user)
    	if(target ~= nil and objVarEditInfo ~= nil) then
    		objVarEditInfo.Data.GameObj = target
    		RefreshObjVarEditWindow()
    	end
    end)

RegisterEventHandler(EventType.ClientTargetAnyObjResponse, "SelectObjVarPermObj", 
    function(target,user)
    	if(target ~= nil and objVarEditInfo ~= nil) then
    		if not(target:IsPermanent()) then
    			objVarEditInfo.TargetUser:SystemMessage("You must select a permanent object.")
    		else
	    		objVarEditInfo.Data.PermanentObj = target
    			RefreshObjVarEditWindow()
    		end
    	end
    end)

ObjVarEditWindow = {
	Show = function (curEditInfo)
		objVarEditInfo = curEditInfo
		-- convert the data to a table to support multiple types
		local objVarData = objVarEditInfo.Data
		objVarEditInfo.Data = {}
		if(objVarEditInfo.Type ~= "") then
			objVarEditInfo.Data[objVarEditInfo.Type] = objVarData
		end	

		if (originalData == nil) then
			originalData = objVarEditInfo.Data
		end

		objVarEditInfo.ExcludeTypes = objVarEditInfo.ExcludeTypes or {}
		objVarEditInfo.TargetUser = objVarEditInfo.TargetUser or this

		--DebugMessage(DumpTable(objVarEditInfo))
		
		RefreshObjVarEditWindow()
	end,
}

