-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



Effects.OfferTaxi = {

    -- end the effect when any movement occurs?
    EndOnMovement = true,

    -- handle starting the effect, returning false means the effect failed to start
    OnStart = function(self)

        
        RegisterSingleEventHandler(EventType.DynamicWindowResponse, "TaxiWindow", function(user,buttonId)
            local id = tonumber(StringSplit(buttonId, "_")[2])
            if ( self.Routes[id] ~= nil ) then
                Effect.Apply(self.Parent, "Taxi", {Route = self.Routes[id]})
            end
            Effect.EndSelf(self)
        end)
        
        local height = 1010
        local width = 1200

        local dynamicWindow = DynamicWindow(
            "TaxiWindow", --(string) Window ID used to uniquely identify the window. It is returned in the DynamicWindowResponse event.
            "Select Destination", --(string) Title of the window for the client UI
            width+20, --(number) Width of the window
            height+10, --(number) Height of the window
            -0.5 * width, --startX, --(number) Starting X position of the window (chosen by client if not specified)
            -0.5 * height, --startY, --(number) Starting Y position of the window (chosen by client if not specified)
            nil,--windowType, --(string) Window type (optional)
            "Center", --windowAnchor --(string) Window anchor (default "TOPLEFT")
            -1 --windowDepth
        )

        local routes = {}

        for i=1,#self.Routes do
            local r = self.Routes[i]
            routes[i] = {
                Id = "R_" .. i,
                Icon = "SpellBook05_103",
                Location = Loc2(r.Route[#r.Route].X,r.Route[#r.Route].Z),
                Width = 45,
                Height = 45,
                Tooltip = r.Name
            }
        end

        dynamicWindow:AddMap(0, 0, width, height, routes, true)

        self.Parent:OpenDynamicWindow(dynamicWindow)

        return true
    end,

    -- called when effect has ended and been removed
    OnStop = function(self, canceled)
        self.Parent:CloseDynamicWindow("TaxiWindow")
    end,
}