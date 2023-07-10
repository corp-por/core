-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

ItemProperties.npc_banker = {
    -- define this property to signal this object can be interacted within the world (doesn't require being in a container)
    InteractionRange = ServerSettings.Interaction.ObjectInteractionRange,
    -- define what happens when 'used' (interacted with)
    OnUse = function(this, user)
        if ( Interaction.WithinRange(this, user) ) then
            LookAt(this, user)
            -- open bank
            BankBox.TryViewContents(user)
        end
    end
}