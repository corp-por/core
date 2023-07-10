-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- advanced mobiles are ones that can use abilites (basically anything more advanced then prey)

require 'base.mobile'

function OnStartMoving()
    Effect.OnMovement(this)
end

-- local variables for ability cast pushback
m_CurrentAbilityPushback = 0
RegisterEventHandler(EventType.Message, "ResetAbilityCastPushback", function()
    m_CurrentAbilityPushback = 0
end)

RegisterEventHandler(EventType.Timer, "CastAbility", function(ability, target, consumeObj)
    Ability.Cast.Complete(this, ability, target or Var.Get(this, "CurrentTarget") or this, nil, false, consumeObj)
end)

RegisterEventHandler(EventType.StartMoving, "", function() OnStartMoving() end)