-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- allows reloading module in development and with it reloading all globals in this space.
if DEV then require 'globals.main' end

require 'inc.damage'

-- Do things that should happen on both new objects and from backup (always when first loaded)
function OnLoad()
	Death.Init(this)
end

function SetStartingStat(name)
    local val = 1
    if ( initializer ~= nil and initializer.Stats ~= nil and initializer.Stats[name] ) then
        val = initializer.Stats[name]
    else
        local template = Object.Template(this)
        if (
            AIProperties[template] ~= nil
            and
            AIProperties[template].Stats ~= nil
            and
            AIProperties[template].Stats[name] ~= nil
        ) then
            val = AIProperties[template].Stats[name]
        end
    end
    Stat[name].SetMax(this, val)
    Stat[name].Set(this, val)
end

function SetStartingSpeed()
    local template = Object.Template(this)
    if (
        AIProperties[template] ~= nil
        and
        AIProperties[template].BaseMoveSpeed ~= nil
    ) then
        this:SetBaseMoveSpeed(AIProperties[template].BaseMoveSpeed)
    else
        this:SetBaseMoveSpeed(ServerSettings.Stats.BaseMoveSpeed)
    end
end

-- Do things that should happen when the mobile object is first created
function OnModuleAttached()
    -- create initial equipment (if any))
    LoadEquipment(this,initializer)

    -- or dna string (if any)
    LoadDNA(this,initializer)

    -- setup initial stats
    ForeachStat(function(name)
        Stat[name].Init(this)
        SetStartingStat(name)
    end)

    -- set the starting speed
    SetStartingSpeed()

    OnLoad()
end

-- Do things that should happen every time the mobile enters the world after existing previously
function OnLoadedFromBackup()
	OnLoad()
end

function OnStartSwimming()
    Effect.OnSwim(this)
    Modify.Factor(this, "MoveSpeed", "Swimming", -0.5)
end

function OnStopSwimming()
    Modify.Factor(this, "MoveSpeed", "Swimming", nil)
end

RegisterEventHandler(EventType.StartSwimming, "", function() OnStartSwimming() end)
RegisterEventHandler(EventType.StopSwimming, "", function() OnStopSwimming() end)

-- allowing applying an effect within this mobile's script context from anothers context
RegisterEventHandler(EventType.Message, "ApplyEffect", function(effect, args, targetObj)
    Effect.Apply(this, effect, args, targetObj)
end)

RegisterSingleEventHandler(EventType.ModuleAttached, GetCurrentModule(), function(...) OnModuleAttached(...) end)
RegisterSingleEventHandler(EventType.LoadedFromBackup, "", function(...) OnLoadedFromBackup(...) end)