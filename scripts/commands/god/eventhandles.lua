
--- Function fired after everything is destroyed from the command resetworld
function OnWorldResetDestroyComplete()
	DebugMessage("--- (WorldReset) OBJECTS DESTROYED --- LOADING SEEDS ---")
	LoadSeeds()
	ResetPermanentObjectStates()
end

RegisterEventHandler(EventType.DestroyAllComplete, "WorldReset", function()
	OnWorldResetDestroyComplete()
end)