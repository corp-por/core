-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



--- Determine if a mobile is disabled (cannot use items or abilites)
-- @param mobileObj
-- @return true if mobile is disabled.
function IsMobileDisabled(mobileObj)
    --Verbose("Combat", "IsMobileDisabled", mobileObj)
    return Var.Temp.Get(mobileObj, "Disabled")
end

--- Determine if a is behind b
-- @param a mobileObj
-- @param b mobileObj
-- @param angle(optional) number, default to 90
-- @return true if a is behind b, otherwise false.
function IsBehind(a, b, angle)
	angle = angle or 90
	local diff = (b:GetFacing() - b:GetLoc():YAngleTo(a:GetLoc())) + 180
	if ( diff > 0 ) then
		return diff < angle
	else
		return diff > -angle
	end
end

--- Determine if mobile b is infront of mobile a
-- @param a mobileObj
-- @param b mobileObj
-- @param angle(optional) number, defaults to 90
function InFrontOf(a, b, angle)
	angle = angle or 90
	return ( math.abs( a:GetFacing() - a:GetLoc():YAngleTo(b:GetLoc()) ) < angle )
end

--- Cause mobile a to look at mobile b
-- @param a mobileObj
-- @param b mobileObj
function LookAt(a, b)
	if ( a ~= b ) then
		LookAtLoc(a, b:GetLoc())
	end
end

--- Cause mobile a to look at location loc
-- @param a mobileObj
-- @param loc location
-- @param aloc (options) provide for optimization
function LookAtLoc(a, loc, aloc)
	a:SetFacing((aloc or a:GetLoc()):YAngleTo(loc))
end

--- Get the body size of a mobileObject or gameObject
-- @param target
-- @return number
function GetBodySize(target)
	if ( target ~= nil and target:IsMobile() ) then
		local bodyOffset = target:GetSharedObjectProperty("BodyOffset")
		if not( bodyOffset ) then
			DebugMessage("ERROR: Mobile has no body offset! "..tostring(Object.TemplateId(target)))
			return ServerSettings.Interaction.DefaultBodySize
		else
			return bodyOffset * target:GetScale().X
		end
	else
		local objectOffset = target:GetSharedObjectProperty("ObjectOffset")
		if ( objectOffset ~= nil ) then
			return objectOffset
		end
		return ServerSettings.Interaction.DefaultBodySize
	end
end

function LoadEquipment(mobileObj,table)
    if ( table ~= nil and table.Equipment ~= nil ) then
        for slot,template in pairs(table.Equipment) do
            if ( type(template) == 'table' ) then
                Create.Equipped(template[math.random(1,#template)], mobileObj)
            else
                Create.Equipped(template, mobileObj)
            end
        end
    end
end

function LoadDNA(mobileObj,table)
	if ( table and table.DNA ~= nil ) then
	    local dnaString = ""
	    for i,dnaEntry in pairs(table.DNA) do
	        if(type(dnaEntry) == "table") then
	            dnaString = dnaString .. dnaEntry[math.random(#dnaEntry)] .. ";"
	        else
	            dnaString = dnaString .. dnaEntry .. ";"
	        end
	    end
	    dnaString = StripTrailingComma(dnaString,";")

	    mobileObj:SetSharedObjectProperty("DNAString",dnaString)
	end
end

function GetCustomDNA(mobileObj,overrides)
	--DebugMessage("OVERRIDES ".. DumpTable(overrides))
	local customParts = Var.Get(mobileObj, "CustomDNAParts") or {}

	if(overrides) then
		for partName,partData in pairs(overrides) do
			customParts[partName] = partData
		end
	end

	-- make sure gender is first
	local playerDNAString = "Gender="..(customParts.Gender or "Male")..";"
	
	for partType,customParts in pairs(customParts) do
		if(partType ~= "Gender") then
			playerDNAString = playerDNAString .. partType .. "="
			if(type(customParts) == "table") then
				for i,partName in pairs(customParts) do
					playerDNAString = playerDNAString .. partName .. ","
				end
				StripTrailingComma(playerDNAString)
			elseif(customParts ~= "") then
				playerDNAString = playerDNAString .. customParts
			end
			playerDNAString = playerDNAString .. ";"
		end
	end

	--DebugMessage("NEW CUSTOM DNA " .. playerDNAString)

	return customParts,playerDNAString
end

function UpdateCustomDNA(mobileObj,overrides)
	local customParts,playerDNAString = GetCustomDNA(mobileObj,overrides)
	
	Var.Set(mobileObj, "CustomDNAParts", customParts)

	mobileObj:SetSharedObjectProperty("CustomDNA",playerDNAString)
end

function AddMountDNA(mobileObj,mountType)
	UpdateCustomDNA(mobileObj,{Mount=mountType})
end

function ClearMountDNA(mobileObj)
	UpdateCustomDNA(mobileObj,{Mount=""})
end