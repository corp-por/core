-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

RegisterEventHandler(EventType.DynamicWindowResponse, "EffectIcons", function ( user,buttonId )
    if ( user == this and Effects[buttonId] ~= nil and Effects[buttonId].Cancelable == true ) then
        Effect.End(this, buttonId)
    end
end)