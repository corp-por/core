-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- Mortal commands
local Include = {}
-- set access level for all included functions
Include.access = AccessLevel.Mortal

-- function definitions
Include.functions = {
	Say = function(...)
		local line = CombineArgs(...)
		this:PlayerSpeech(line,ServerSettings.Interaction.PlayerSayRange)
	end,

	BugReport = function()
		OpenBugReportDialog(this)
	end,

	Where = function()
		local loc = this:GetLoc()
		local locX = string.format("%.2f", loc.X)
		local locY = string.format("%.2f", loc.Y)
		local locZ = string.format("%.2f", loc.Z)

		if ( ServerSettings.RegionAddress ~= nil and ServerSettings.RegionAddress ~= "") then
			this:SystemMessage("Region Address: "..ServerSettings.RegionAddress)
		end

		if ( this:HasAccessLevel(AccessLevel.God) ) then
			local regions = GetRegionsAtLoc(loc)
			local regionStr = ""
			for i,regionName in pairs(regions) do
				regionStr = regionStr .. regionName .. ", "
			end
			this:SystemMessage("World: "..ServerSettings.WorldName)
			this:SystemMessage("Subregions: "..regionStr)
		end
		
		this:SystemMessage(locX..", "..locY..", "..locZ)
	end,

	DeleteChar = function ()
		TextFieldDialog.Show{
	        TargetUser = user,
	        Title = "Delete Character",
	        Description = "[$2467]",
	        ResponseFunc = function(user,newValue)
	            if(newValue == "DELETE") then
	            	-- remove from guild (function does nothing if not in a guild)
	            	Guild.Remove(this)

	            	local houseObj = GetUserHouse(this)
	            	if(houseObj) then
	            		houseObj:SendMessageGlobal("OnCharDelete",this)
	            	end

			    	local clusterController = GetClusterController()
			    	clusterController:SendMessage("UserLogout", this);

	                this:DeleteCharacter()
			    	
	            else
	            	this:SystemMessage("Delete character cancelled")
	            end
	        end
	    }
	end,

    Cast = function(ability)
        Ability.SafePerform(this, nil, ability)
    end
}

-- command definitions: { name, function, usage, description, aliases }
Include.commands = {
    { "say", Include.functions.Say, "<text>", "[$3342]", {} },
    { "where", Include.functions.Where, "", "[$3345]", {} },
    { "deletechar", Include.functions.DeleteChar, "", "[$3347]", {} },
    --{ "bugreport", Include.functions.BugReport, "", "[$3341]", {} },
    { "cast", Include.functions.Cast, "", "Perform an Ability", {} },
}

return Include

