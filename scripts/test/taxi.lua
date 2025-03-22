
if DEV then require 'globals.main' end

local r = {
    {
        Name = "Route A",
        Route = {
            Loc(-23,10,60), -- first one is always the start
            Loc(73,10,72) -- last one in list is the destination
        },
    },
    {
        Name = "Route B",
        Route = {
            Loc(64,10,-30), -- first one is always the start
            Loc(-17,10,0) -- last one in list is the destination
        }
    }
}

Effect.Apply(this, "OfferTaxi", {Routes = r}, this)

Effect.End(this, "Taxi")