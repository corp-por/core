Taxi = {}

function Taxi.AskDestination(playerObj, routes)
    for i=1,#routes do
        playerObj:NpcSpeech(routes[i][1])
        for j=2,#routes[i] do
            playerObj:NpcSpeech(routes[i][j].X .. " " .. routes[i][j].Z)
        end
    end
end

function Taxi.Start(playerObj, route)
    Effect.Apply(playerObj, "Taxi", {Route = route})
end