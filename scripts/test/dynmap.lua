


RegisterEventHandler(EventType.DynamicWindowResponse, "TestDynamicWindowMap", function(user,buttonId,fieldData)
    DebugMessage(buttonId)
    if ( buttonId == "MapClick" ) then
        local loc = Loc(tonumber(fieldData.X),0,tonumber(fieldData.Z))
        loc:Fix()
        this:SetWorldPosition(loc)
        this:PlayEffect("TeleportToEffect")
        this:NpcSpeech(fieldData.X .. "," .. fieldData.Z)
    elseif ( buttonId == "LOC_1" ) then
        local loc = Loc(50,0,50)
        loc:Fix()
        this:SetWorldPosition(loc)
    end

    --this:CloseDynamicWindow("TestDynamicWindowMap")
end)

local height = 770
local width = 900

local dynamicWindow = DynamicWindow(
    "TestDynamicWindowMap", --(string) Window ID used to uniquely identify the window. It is returned in the DynamicWindowResponse event.
    "Select Destination", --(string) Title of the window for the client UI
    width+20, --(number) Width of the window
    height+10, --(number) Height of the window
    -0.5 * width, --startX, --(number) Starting X position of the window (chosen by client if not specified)
    -0.5 * height, --startY, --(number) Starting Y position of the window (chosen by client if not specified)
    nil,--windowType, --(string) Window type (optional)
    "Center", --windowAnchor --(string) Window anchor (default "TOPLEFT")
    -1 --windowDepth
)

dynamicWindow:AddMap(0, 0, width, height, 
{
    {
        Id = "LOC_1",
        Icon = "SpellBook05_103",
        Location = Loc2(50,50),
        Width = 45,
        Height = 45,
        Tooltip = "Go here"
    }
}, true, true)

this:OpenDynamicWindow(dynamicWindow)