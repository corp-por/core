-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

local Command = {}

Command.registry = {}
Command.names = {}
Command.aliases = {}
Command.functions = {}

function Command.init()
    table.sort(Command.names)

    -- meta functions
    Command.register("help", AccessLevel.Mortal, Command.functions.meta.Help, "<command>", "[$2471]", { "?" })

    -- included functions by access level
    Command.include(AccessLevel.Mortal,     "mortal")
    Command.include(AccessLevel.Immortal, "immortal")
    Command.include(AccessLevel.DemiGod,    "demigod")
    Command.include(AccessLevel.God,            "god")
end

function Command.register(name, access, func, usage, desc, aliases)
    -- validation for required fields
    if (nil == name)     then DebugMessage("[Command.register] ERROR: Invalid command name."); return end
    if (nil == access) then DebugMessage("[Command.register] ERROR: Invalid command access level."); return end
    if (nil == func)     then DebugMessage("[Command.register] ERROR: Invalid command function."); return end
    if (nil == usage)    then DebugMessage("[Command.register] ERROR: Invalid command usage."); return end
    if (nil == desc)     then DebugMessage("[Command.register] ERROR: Invalid command description."); return end
    aliases = aliases or {} -- optional

    -- create entry
    local entry = { ["name"] = name, ["access"] = access, ["func"] = func, ["usage"] = usage, ["desc"] = desc, ["aliases"] = aliases }

    -- remove previous (if any)
    Command.unregister(name)

    -- add command to registry
    table.insert(Command.names, name)
    Command.registry[name] = entry
    RegisterEventHandler(EventType.ClientUserCommand, name, function(...) Command.execute(name, ...) end)
    
    -- add aliases to commands (if any)
    for k, aliasName in pairs(aliases) do
        Command.aliases[aliasName] = name -- point alias to command name
        RegisterEventHandler(EventType.ClientUserCommand, aliasName, function(...) Command.alias(aliasName, ...) end)
    end
end

function Command.include(access, name)
    -- only include function groups if the player has access to them
    if (not this:HasAccessLevel(access) and not this:HasObjVar("IsGod")) then
        return
    end

    local included = require("commands."..name..".main")
    if (nil == included) then
        return
    end

    table.insert(Command.functions, included.functions)

    for k, entry in pairs(included.commands) do
        Command.register(entry[1], included.access, entry[2], entry[3], entry[4], entry[5])
    end
end

function Command.unregister(name)
    local oldCommand = Command.registry[name]

    -- skip if command hasn't been registered already
    if (nil == oldCommand) then
        return
    end

    -- unregister command event handler
    UnregisterEventHandler('', EventType.ClientUserCommand, name)

    -- remove old aliases (if any)
    for i, aliasName in pairs(oldCommand.aliases) do
        Command.aliases[aliasName] = nil
        UnregisterEventHandler('', EventType.ClientUserCommand, aliasName)
    end

    -- remove old command entry
    Command.registry[name] = nil
end

function Command.execute(name, ...)
    local command = Command.registry[name]

    -- ignore unregistered/missing commands
    if (nil == command) then
        return
    end

    -- execute command if player has proper access level or is an admin
    -- TODO: replace IsGod objvar check with a player func IsAdmin()
    if (this:HasAccessLevel(command.access) or this:HasObjVar("IsGod")) then
        command.func(...)
    end
end

function Command.alias(name, ...)
    local alias = Command.aliases[name]

    -- ignore unregistered/missing aliases
    if (nil == alias) then
        return
    end

    -- try executing the aliased command
    Command.execute(alias, ...)
end

-- Add any meta-functions such as help and usage
Command.functions.meta = {
    Help = function(commandName)
        if(commandName == "actions") then
            local emotesStr = ""
            for commandName, animName in pairs(Emotes) do 
                emotesStr = emotesStr .. "/" .. commandName .. ", "
            end
            emotesStr = StripTrailingComma(emotesStr)
            this:SystemMessage("Emotes: "..emotesStr)
        elseif (nil ~= commandName) then
            local usage = Command.functions.meta.Usage(commandName)
            
            local usageStr = "Usage: /"..commandName.." "..usage
            this:SystemMessage(usageStr)

            if(Command.registry[commandName].desc ~= nil ) then
                this:SystemMessage(commandInfo.Desc)
            end            
        else
            -- List all commands
            local usage = Command.functions.meta.Usage("help")
            this:SystemMessage("'help' - Lists all avilable commands or describes a specific command.")
            this:SystemMessage("Usage: /help "..usage)
            this:SystemMessage("---")
            this:SystemMessage(table.concat(Command.names, ", "))
        end
    end,

    Usage = function(commandName)
        if (nil ~= commandName) then
            local usage = Command.registry[commandName].usage
            return (nil ~= usage) and "Usage: "..usage or ""
        end
    end,
}

Command.init()

return Command
