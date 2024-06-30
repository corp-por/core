-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- allows reloading module in development and with it reloading all globals in this space.
if DEV then require 'globals.main' end

require 'inc.damage'

-- Do things that should happen on both new objects and from backup (always when first loaded)
function OnLoad()
	Death.Init(this)
end

function SetStartingStat(name, template)
    local val = 1
    --local template = Template[Object.TemplateId(this)] --Object.TemplateId(this)
    if ( template ~= nil and template.Stats ~= nil and template.Stats[name] ~= nil ) then
        val = template.Stats[name]
    end
    Stat[name].SetMax(this, val)
    Stat[name].Set(this, val)
end

-- Do things that should happen when the mobile object is first created
function OnModuleAttached()
    local t = Template[Object.TemplateId(this)]

    -- create initial equipment (if any))
    LoadEquipment(this,t)

    -- or dna string (if any)
    LoadDNA(this,t)

    -- setup initial stats
    ForeachStat(function(name)
        Stat[name].Init(this)
        SetStartingStat(name, t)
    end)

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