-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'commands.demigod.ui_create'
require 'commands.demigod.ui_search'

-- DemiGod commands
local Include = {}

-- set access level for all included functions
Include.access = AccessLevel.DemiGod

-- Helpers

function DoCopy(target,destLoc)
    target:CopyObjectToPos(nil, destLoc)
end

function DoCopySelectLoc(target)
    this:RequestClientTargetLoc(this, "copyDest")
    RegisterSingleEventHandler(EventType.ClientTargetLocResponse, "copyDest",
        function(success,targetLoc)
            if not( success ) then
                return
            end

            DoCopy(target,targetLoc)
        end)
end

function DoDestroy(target)
    if(target:IsPlayer()) then
        this:SystemMessage("You can not destroy players")
    elseif(target:HasObjVar("NoReset")) then
        destroyTargetObj = target
        ClientDialog.Show{
            TargetUser = this,
            DialogId = "DestroyConfirm",
            TitleStr = "Warning",
            DescStr = "[$2456]",
            Button1Str = "Yes",
            Button2Str = "No",
            ResponseFunc = function ( user, buttonId )
                buttonId = tonumber(buttonId)
                if( buttonId == 0 and destroyTargetObj ~= nil) then
                    destroyTargetObj:Destroy()
                end
            end
        }
    else
        this:SystemMessage("Destroying object "..tostring(target))
        target:Destroy()
    end
end

-- function definitions
Include.functions = {
    Create = function(templateName)     
        if( templateName ~= nil ) then
            templateId = GetTemplateMatch(templateName,this)
            if( templateId ~= nil ) then
                Create.AtLoc(templateId, this:GetLoc(), function(item)
                    if ( item:IsMobile() ) then
                        item:RemoveDecay()
                    end
                end)
            else
                templateListCategory = "All"
                templateListCategoryIndex = 1
                templateListFilter = templateName
                ShowPlacableTemplates()
            end
        else
            templateListFilter = ""
            ShowPlacableTemplates()
        end
    end,

    Search = function(arg)
		ShowNewSearch(arg)
	end,

    Destroy = function(objId)
        if( objId ~= nil ) then
            local target = GameObj(tonumber(objId))
            DoDestroy(target)
        else
            this:RequestClientTargetGameObj(this, "destroyTarget")

            RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "destroyTarget",
                function(target,user)
                    if( target == nil ) then
                        return
                    end

                    DoDestroy(target)
                end)
        end
    end,

    Copy = function(objId)
        if( objId ~= nil ) then
            local target = GameObj(tonumber(objId))
            DoCopySelectLoc(target)
        else
            this:RequestClientTargetGameObj(this, "copyTarget")

            RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "copyTarget",
                function(target,user)
                    if( target == nil ) then
                        return
                    end

                    this:RequestClientTargetLoc(this, "copyDest")
                    DoCopySelectLoc(target)
                end)
        end
    end,

    Slay = function()
        this:RequestClientTargetGameObj(this, "slay")
        RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "slay",
            function(target,user)
                if not(IsDemiGod(this)) then return end

                if ( target == nil ) then
                    return
                end

                target:PlayEffect("NukeRed")
                target:SendMessage("Damage", this, math.random(5000,10000), "True")

            end)
    end,

    Heal = function()
        this:RequestClientTargetGameObj(this, "heal")
        RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "heal",
            function(target,user)
                if not(IsDemiGod(this)) then return end

                if ( target == nil ) then
                    return
                end

                target:PlayEffect("HealEffect")
                Stat.Health.Fill(target)

            end)
    end,

    Summon = function(objId)
        if( objId ~= nil ) then
            local target = GameObj(tonumber(objId))
            target:SetWorldPosition(this:GetLoc())
        else
            this:RequestClientTargetGameObj(this, "summonTarget")

            RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "summonTarget",
                function(target,user)
                    if( target == nil ) then
                        return
                    end

                    target:SetWorldPosition(this:GetLoc())
                end)
        end
    end,
}

-- command definitions: { name, function, usage, description, aliases }
Include.commands = {
    { "create", Include.functions.Create, "[<template>]", "[$2478]" },
    { "destroy", Include.functions.Destroy, "[<target_id>]", "[$2479]" },
    { "slay", Include.functions.Slay, "[<target_id>]", "[$2495]"},
    { "heal", Include.functions.Heal, "[<target_id>]", "[$2495]"},
    { "search", Include.functions.Search, "[<name>]", "[$2486]" },
    { "copy", Include.functions.Copy, "[<target_id>]", "[$2495]"},
    { "summon", Include.functions.Summon, "[<target_id>]", "Summon your target"},
}

return Include

