-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

UI.Character = {}

--[[
    TODO!
	    dynamicWindow:AddImage(startX + 760, startY - 102,"coins")
        dynamicWindow:AddLabel(startX + 760, startY - 60,"[STAT:Gold]",0,0,50,"right",false,false,"","bold")
]]

local TOP = -ServerSettings.UI.Screen.Height/2

function UI.Character.Init(playerObj, dynamicWindow)
    RegisterEventHandler(EventType.ClientUserCommand, "esc", function (equipSlot)	
        local carriedObject = playerObj:CarriedObject()
        if ( carriedObject ) then

        end
    end)
    UI.Character.Window(playerObj, dynamicWindow)
end

function UI.Character.Window(playerObj, dynamicWindow)

    local startX = -200
	local startY = TOP+100

	local SLOTLARGE = 168
	local SLOTSMALL = 116

	local SLOTLARGESPACING = SLOTLARGE + 20
	local SLOTSMALLSPACING = SLOTSMALL + 20

	dynamicWindow:AddUserAction(startX + SLOTSMALLSPACING,       startY,                           UI.Character.EquipSlotUserAction("Head",this,"Head"),SLOTLARGE,SLOTLARGE,"SquareFixed")
	dynamicWindow:AddUserAction(startX + SLOTSMALLSPACING,       startY + SLOTLARGESPACING,        UI.Character.EquipSlotUserAction("Chest",this,"Chest"),SLOTLARGE,SLOTLARGE,"SquareFixed")
	dynamicWindow:AddUserAction(startX + SLOTSMALLSPACING,       startY + SLOTLARGESPACING*2,      UI.Character.EquipSlotUserAction("Legs",this,"Legs"),SLOTLARGE,SLOTLARGE,"SquareFixed")

	dynamicWindow:AddUserAction(startX + 44,                    startY + SLOTLARGESPACING*3,      UI.Character.EquipSlotUserAction("RightHand",this,"Right Hand"),SLOTLARGE,SLOTLARGE,"SquareFixed")
	dynamicWindow:AddUserAction(startX + 44 + SLOTLARGESPACING, startY + SLOTLARGESPACING*3,      UI.Character.EquipSlotUserAction("LeftHand",this,"Left Hand"),SLOTLARGE,SLOTLARGE,"SquareFixed")

	dynamicWindow:AddUserAction(startX,                          startY + 20,                      UI.Character.EquipSlotUserAction("Shoulders",this,"Shoulders"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(startX,                          startY + 20 + SLOTSMALLSPACING,   UI.Character.EquipSlotUserAction("Arms",this,"Arms"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(startX,                          startY + 20 + SLOTSMALLSPACING*2, UI.Character.EquipSlotUserAction("Gloves",this,"Gloves"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(startX,                          startY + 20 + SLOTSMALLSPACING*3, UI.Character.EquipSlotUserAction("Boots",this,"Boots"),SLOTSMALL,SLOTSMALL,"SquareFixed")

	local jewelryX = startX + SLOTSMALLSPACING + SLOTLARGESPACING
	dynamicWindow:AddUserAction(jewelryX,                        startY + 20,                      UI.Character.EquipSlotUserAction("Cloak",this,"Cloak"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(jewelryX,                        startY + 20 + SLOTSMALLSPACING,   UI.Character.EquipSlotUserAction("Ring1",this,"Ring"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(jewelryX,                        startY + 20 + SLOTSMALLSPACING*2, UI.Character.EquipSlotUserAction("Ring2",this,"Ring"),SLOTSMALL,SLOTSMALL,"SquareFixed")
	dynamicWindow:AddUserAction(jewelryX,                        startY + 20 + SLOTSMALLSPACING*3, UI.Character.EquipSlotUserAction("Totem",this,"Totem"),SLOTSMALL,SLOTSMALL,"SquareFixed")

end

function UI.Character.EquipSlotUserAction(equipSlot,targetObj,displayName)
     -- no need to send the target obj option if its for the local player	
    local id = equipSlot
    local serverCommand = "esc " .. equipSlot
    if ( targetObj ~= nil and targetObj ~= this ) then
        id = targetObj.Id.."|"..equipSlot
        serverCommand = serverCommand .. targetObj.Id
    end
    --DebugMessage("displayName is "..tostring(displayName))
    return {
        ID=id,
        ActionType="EquipSlot",
        DisplayName=displayName,
        Tooltip=displayName,
        Enabled=true,
        ServerCommand=serverCommand,
    }
end