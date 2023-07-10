-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'commands.god.ui_info'

-- God commands
local Include = {}

-- set access level for all included functions
Include.access = AccessLevel.God

-- helpers



-- function definitions
Include.functions = {
    -- destroyall
    DestroyAll = function(arg)
        if (arg and arg:match("force")) then
            DestroyAllObjects(true)
        elseif(arg and arg:match("ignorenoreset")) then
            DestroyAllObjects(false)
        else
            ClientDialog.Show {
            TargetUser = this,
            DialogId = "DestroyAllDialog",
            TitleStr = "WARNING",
            DescStr = "[$2466]",
            Button1Str = "Yes",
            Button2Str = "No",
            ResponseFunc = function ( user, buttonId )
                buttonId = tonumber(buttonId)
                if( buttonId == 0) then                                
                    DestroyAllObjects(true)
                else
                    this:SystemMessage("Destroy All cancelled")
                end
            end
            }
        end
    end,

    -- dostring (exec)
    DoString = function(...)        
        -- DAB TODO: sanitize and secure
        local line = CombineArgs(...)
        this:SystemMessage("Executing: "..line)

        f = load(line)
        f()
    end,

    -- reloadbehavior (reload)
    ReloadBehavior = function(behaviorName)
        if (nil == behaviorName) then
            return
        end

        ReloadModule(behaviorName)
    end,

    ReloadTemplates = function()
        ReloadTemplates()
    end,

    -- backup
    ServerBackup = function()
        ForceBackup()
    end,

    Info = function(targetObjId)
        if(targetObjId ~= nil) then
            gameObj = GameObj(tonumber(targetObjId))
            if(gameObj:IsValid()) then
                DoInfo(gameObj)
                return
            else
                this:SystemMessage(tostring(targetObjId).." is not a valid id. Object does not exist.")
            end
        end
        this:RequestClientTargetGameObj(this, "info")

        RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "info",
            function(target,user)
                if not(IsDemiGod(this)) then return end

                if( target == nil ) then
                    return
                end

                DoInfo(target)
            end)
    end,

    OpenContainer = function(targetObjId)
        if(targetObjId ~= nil) then
            gameObj = GameObj(tonumber(targetObjId))
            if(gameObj:IsValid()) then
                gameObj:SendOpenContainer(this)
                return
            else
                this:SystemMessage(tostring(targetObjId).." is not a valid id. Object does not exist.")
            end
        end
        this:RequestClientTargetGameObj(this, "opencontainer")

        RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "opencontainer",
            function(target,user)
                if not(IsDemiGod(this)) then return end

                if ( target == nil ) then
                    return
                end

                target:SendOpenContainer(this)
            end)
    end,

    CreateShadow = function(target)
        Create.AtLoc("shadow", target:GetLoc(), function(shadow)
            shadow:AddModule("test.shadow", {
                TargetId = target.Id
            })
        end)
    end,

    Shadow = function(targetObjId)
        if(targetObjId ~= nil) then
            gameObj = GameObj(tonumber(targetObjId))
            if(gameObj:IsValid()) then
                Include.functions.CreateShadow(gameObj)
                return
            else
                this:SystemMessage(tostring(targetObjId).." is not a valid id. Object does not exist.")
            end
        end
        this:RequestClientTargetGameObj(this, "shadowtarget")

        RegisterSingleEventHandler(EventType.ClientTargetGameObjResponse, "shadowtarget",
            function(target,user)
                if not(IsGod(this)) then return end

                if ( target == nil ) then
                    return
                end

                Include.functions.CreateShadow(target)
            end)
    end,
}

-- command definitions: { name, function, usage, description, aliases }
Include.commands = {
    { "backup", Include.functions.ServerBackup, "", "Force a backup to take place." },
    { "destroyall", Include.functions.DestroyAll, "[force|ignorenoreset]", "[$2509]" },
    { "dostring", Include.functions.DoString, "<lua code>", Desc="[$2514]", { "exec" } },
    { "reload", Include.functions.ReloadBehavior, "<behavior>", "[DEBUG COMMAND] Reload the behavior in memory." },
    { "reloadtemplates", Include.functions.ReloadTemplates, "", "[DEBUG COMMAND] Reload all templates in memory." },
    { "info", Include.functions.Info, "", "Get information about an object. Gives cursor" },
    { "opencontainer", Include.functions.OpenContainer, "", "View the contents of a container." },
    { "shadow", Include.functions.Shadow, "", "Debug movement by seeing server the representation of a character." }
}

return Include

