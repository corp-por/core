
RegisterEventHandler(EventType.Timer, "ColorTimer", function()
    this:SetColor(math.random(128,255),math.random(128,255),math.random(128,255))
    this:ScheduleTimerDelay(TimeSpan.FromSeconds(1), "ColorTimer")
end)
this:FireTimer("ColorTimer")