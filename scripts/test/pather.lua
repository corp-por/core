-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD




local g = GameObj(3)

this:EnableNavigationAgent()

function RequestPathTarget()
    g:RequestClientTargetLoc(this, "Pather")
end

RegisterEventHandler(EventType.ClientTargetLocResponse, "Pather", function(success, loc)
    if ( success ) then
        this:PathTo(Loc(loc.X, loc.Y, loc.Z))
        RequestPathTarget()
    end
end)

RegisterEventHandler(EventType.StopMoving, "", function()
    this:NpcSpeech("Stop Moving")
end)

RequestPathTarget()