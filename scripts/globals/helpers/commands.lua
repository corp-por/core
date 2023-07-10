-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- Helper functions for user commands
-- @module globals.helpers.commands

--- Searches for a template by partial name. If only one is found it is returned.
-- If multiple are found they are sent to the user in a debug message
-- @param templateSearchStr partial name of template
-- @param user user to send system messages to
function GetTemplateMatch(templateSearchStr,user)
	templateList = GetAllTemplateNames()

	-- if we have an exact match, then return it
	if( IsInTableArray(templateList,templateSearchStr) ) then
		return templateSearchStr
	end

	matches = {}
	for i, templateName in pairs(templateList) do		
		if (templateName:find(templateSearchStr) ~= nil) then
			matches[#matches+1] = templateName
		end
	end

	if( #matches == 1 ) then
		return matches[1]
	elseif( #matches > 1 ) then
		resultStr = "Multiple templates match: "
		for i, match in pairs(matches) do
			resultStr = resultStr .. ", " .. match
		end
		user:SystemMessage(resultStr)
		return nil		
	else
		user:SystemMessage("No template matches search string")
	end
end

--- Searches for a player object across all regions connected to the server
-- if multiple matches are found they are sent to the user in a system message
-- @param arg can be either a number (Object Id) or string (partial name search)
-- @param user to send system messages to
function GetPlayerByNameOrIdGlobal(arg,user)
	local found = FindGlobalUsers(arg)

	if( #found == 0 ) then
		user:SystemMessage("No players found by that name")
	elseif( #found == 1 ) then
		return found[1]
	else
		user:SystemMessage("Multiple matches found (use /command [id] instead)")
		local matches = ""
		for index, entry in pairs(found) do
			matches = matches .. entry.Name .. ":"..entry.Obj.Id..", "
		end
		user:SystemMessage(matches)
	end
end

--- Searches for a player object on this server region
-- if multiple matches are found they are sent to the user in a system message
-- @param arg can be either a number (Object Id) or string (partial name search)
-- @param user to send system messages to
function GetPlayerByNameOrId(arg,user)
	if tonumber(arg) ~= nil then
		local targetObj = GameObj(tonumber(arg))
		if( targetObj:IsValid() or isGlobal ) then
			return targetObj		
		else
			user:SystemMessage("No players found by that id")
		end
	else
		local found = GetPlayersByName(arg)
		if( #found == 0 ) then
			user:SystemMessage("No players found by that name")
		elseif( #found == 1 ) then
			return found[1]
		else
			user:SystemMessage("Multiple matches found (use /command [id] instead)")
			local matches = ""
			for index, obj in pairs(found) do
				matches = matches .. obj:GetName() .. ":"..obj.Id..", "
			end
			user:SystemMessage(matches)
		end
	end
end