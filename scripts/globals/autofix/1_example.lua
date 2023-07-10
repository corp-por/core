-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



AutoFixes[#AutoFixes+1] = {
    Player = function(player)
        -- remove old auto fix
        if ( player:HasModule("autofix") ) then
            player:DelModule("autofix")
        end

        -- set example alignment to Peaceful
        player:SetObjVar("exampleAlignment", ServerSettings.example.NewPlayerexampleAlignment)
        player:SendClientMessage("SetexampleState", "Peaceful")

        -- reset example if they have negative example
        local example = Getexample(player)
        if ( example < 0 ) then
            player:SetObjVar("example", 51) -- (51 cause Daily login Bonus + 1 as new starting number)
            player:SendMessage("UpdateName")
            player:SystemMessage("Your example has been reset.", "event")
        end
        
    end,
    World = function(clusterController)
        local worldObjects = FindObjects(SearchObjVar("NoReset", true))
        local before = DateTime.UtcNow
        DebugMessage("[AutoFix] "..#worldObjects.." World Objects found via NoReset ObjVar.")
        for i=1,#worldObjects do
            AutoFixes[index].DoFix(worldObjects[i])
        end
        DebugMessage("[AutoFix] World Objects Done. TotalMS: "..DateTime.UtcNow:Subtract(before).TotalMilliseconds)
        DebugMessage("[AutoFix] "..totalSecure.." Total Secure Chests Fixed.")
    end
}