-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



function RequestPlaceMapObj()
    this:RequestClientTargetLoc(this, "TestMapObj")
end

RegisterEventHandler(EventType.ClientTargetLocResponse, "TestMapObj", function(success, loc)
    if ( success ) then
        
        local mapObj = MapObj(1, loc.X, loc.Z, 0)
        --mapObj.Red = 0
        --mapObj.Green = 0
        --mapObj.Blue = 0
        mapObj:Add()

        do return end

        local myLoc = this:GetLoc()
        local total = myLoc:Distance(mapObj:GetLoc()) / ServerSettings.TileSize

        for i=1,total do

            --while( mapObj:Exists() ) do
                --mapObj.L = mapObj.L + 1
            --end

            mapObj:Add()
            mapObj.X = mapObj.X + ServerSettings.TileSize
        end

        RequestPlaceMapObj()
    end
end)

RequestPlaceMapObj()