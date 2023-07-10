-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- player ability targeting reticle
local AbilityReadyToRelease = nil
RegisterEventHandler(EventType.Message, "AbilityReadyToRelease", function(ability)
    if ( ability == nil and AbilityReadyToRelease ~= nil ) then
        this:SendClientMessage("CancelSpellCast")
    end
    AbilityReadyToRelease = ability
end)

RegisterEventHandler(EventType.ClientTargetGameObjResponse, "SelectAbilityTarget", function(target)
    if ( AbilityReadyToRelease ~= nil and target ) then
        -- set current target
        --SetCurrentTarget(target)

        LookAt(this, target)

        if ( Ability.Perform(this, target, AbilityReadyToRelease, true) ) then
            AbilityReadyToRelease = nil
        else
            this:RequestClientTargetGameObj(this, "SelectAbilityTarget")
        end
    end
end)

RegisterEventHandler(EventType.ClientTargetLocResponse, "SelectAbilityTargetLoc", function(success, loc)
    if ( AbilityReadyToRelease ~= nil and success ) then

        LookAtLoc(this, loc)

        if ( Ability.Perform(this, loc, AbilityReadyToRelease, true) ) then
            AbilityReadyToRelease = nil
        else
            this:RequestClientTargetLoc(this, "SelectAbilityTargetLoc")
        end
    end
end)

RegisterEventHandler(EventType.ClientUserCommand, "cancelspellcast", function()
    Ability.Cast.Cancel(this, this:HasTimer("CastAbility"))
end)