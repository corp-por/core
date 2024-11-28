-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

UI.Main = {}

function UI.Main.Init(playerObj)

    UI.Main.Window(playerObj, true)

	ShowPlayerStatusElement(playerObj)
    
    RegisterEventHandler(EventType.Message, "UpdateMainWindow", function(playerObj)
        UI.Main.Window(playerObj)
    end)
end

function UI.Main.Window(playerObj, init)
    local dynamicWindow = DynamicWindow(
		"Main", --(string) Window ID used to uniquely identify the window. It is returned in the DynamicWindowResponse event.
		"", --(string) Title of the window for the client UI
		0, --(number) Width of the window
		0, --(number) Height of the window
		-980, --startX, --(number) Starting X position of the window (chosen by client if not specified)
		0, --startY, --(number) Starting Y position of the window (chosen by client if not specified)
		"Transparent",--windowType, --(string) Window type (optional)
		"Right", --windowAnchor --(string) Window anchor (default "TOPLEFT")
		-1, --windowDepth
		"mainui" -- this currently identifies that this window will be hidden unless toggled by keybind for Character Window.
    )

    if ( init ) then
        UI.Character.Init(playerObj, dynamicWindow)
    else
        UI.Character.Window(playerObj, dynamicWindow)
    end
	
    playerObj:OpenDynamicWindow(dynamicWindow)
end