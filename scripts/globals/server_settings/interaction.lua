-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- Settings related to players interaction with the world
ServerSettings.Interaction = {
	-- Range for other players to hear a players normal speech
	PlayerSayRange = 30,

	-- Default range for normal player object interaction
	ObjectInteractionRange = 1.25,
	-- How far off the ground should we perform the line of sight check by default
	LineOfSightHeight = 1.9,
	-- The default amount of time (seconds) it should take for an item dropped on the ground to decay
	DefaultDecayTime = TimeSpan.FromSeconds(180),

	-- default body size when one is not provided
	DefaultBodySize = 0.8,
}