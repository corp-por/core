-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

AIProperty = {}

function AIProperty.GetTable(templateid)
    if ( Template[templateid] ~= nil ) then
        return Template[templateid]
    end
    return nil
end

--- Get the TeamType of a brain/ai, this is what determines friendly/foe. This is automatically set when using a new FSM
-- @param templateid - The TemplateId of the mobileObj running the AI
-- @return string - The team type, "Unknown" is returned if not set
function AIProperty.GetTeamType(templateid)
    if ( templateid ~= nil and Template[templateid] ~= nil and Template[templateid].TeamType ~= nil ) then
        return Template[templateid].TeamType
    end
    return "Unknown"
end

--- Get the abilities this mobile can perform
-- @param templateid - The TemplateId of the mobileObj running the AI
-- @return table - table of abilities, otherwise nil
function AIProperty.GetAbilities(templateid)
    if ( templateid ~= nil and Template[templateid] ~= nil and Template[templateid].Abilities ~= nil ) then
        return Template[templateid].Abilities
    end
    return nil
end

--- Gets the path and if should loop
-- @param templateid - The TemplateId of the mobileObj running the AI
-- @return string,bool - First return is the path name, second return is if the path should loop
function AIProperty.GetPath(templateid)
    if ( templateid ~= nil and Template[templateid] ~= nil and Template[templateid].Path ~= nil ) then
        return Template[templateid].Path, Template[templateid].PathLoop == true
    end
    return nil, false
end

function AIProperty.GetRespawnTimer(templateid)
    if ( templateid ~= nil and Template[templateid] ~= nil and Template[templateid].RespawnTimer ~= nil ) then
        return Template[templateid].RespawnTimer
    end
    return nil
end

function AIProperty.GetMovementSpeed(templateid)
    if ( templateid ~= nil and Template[templateid] ~= nil and Template[templateid].Mobile ~= nil and Template[templateid].Mobile.MovementSpeed ~= nil ) then
        return Template[templateid].Mobile.MovementSpeed
    end
    return nil
end

function AIProperty.GenerateLoot(mobileObject, cb)
    if ( mobileObject == nil or not mobileObject:IsValid() ) then
        LuaDebugCallStack("[Loot.Generate] invalid mobile provided.")
        return
    end

    if ( mobileObject:IsPlayer() ) then
        LuaDebugCallStack("[Loot.Generate] attempted to generate loot on a player. Ending here")
        return
    end

    local templateid = Object.TemplateId(mobileObject)

    if ( Template[templateid] == nil or Template[templateid].Loot == nil ) then
        return
    end

    local backpack = Backpack.Get(mobileObject)

    if ( backpack ~= nil ) then
        backpack:Destroy()
    end

    backpack = nil

    local L = Template[templateid].Loot

    if ( #L < 1 ) then
        DebugMessage("[AIProperty.GenerateLoot] Loot table length less than 1 for templateid '" .. templateid .. "' Remove Loot entry if this is intended.")
        return
    end

    local done = 0
    -- first create a backpack
	local templateData = GetTemplateData("mob_loot")

    templateData.Name = mobileObject:GetName()

    if not( templateData.SharedProperties ) then
		templateData.SharedProperties = {}
	end

    -- set a custom capacity for this temporary loot container (minimum of 5 to not look too odd)
    templateData.SharedProperties.Capacity = #L > 5 and #L or 5

    Create.Custom.InContainer("mob_loot", templateData, mobileObject, Loc(0,1,0), function(container)
        mobileObject:EquipObject(container)

        -- fill the backpack with the loot items
        for i=1,#L do
            if ( type(L[i]) == 'table' ) then
                local count = L[i][2]
                if ( type(count) == 'table' ) then
                    count = math.random(L[i][2][1], L[i][2][2])
                end
                if ( count > 0 ) then
                    Create.Stack.InContainer(L[i][1], container, count, nil, function(item)
                        if ( cb ) then
                            done = done + 1
                            if ( done >= #L ) then
                                cb(container)
                            end
                        end
                    end)
                end
            else
                Create.InContainer(L[i], container, nil, function(item)
                    if ( cb ) then
                        done = done + 1
                        if ( done >= #L ) then
                            cb(container)
                        end
                    end
                end)
            end
        end
    end)
end