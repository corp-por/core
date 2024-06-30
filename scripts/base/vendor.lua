-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD



-- create the vendor's inventory object if it doesn't exist yet
if ( Backpack.Get(this) == nil ) then
    local templateData = GetTemplateData("vendor_backpack")

    templateData.Name = "Vendor Inventory"

    templateData.Attach = "vendor.inventory"

    Create.Custom.InContainer("vendor_backpack", templateData, this, nil, function(backpack)
        this:EquipObject(backpack)
        --Create.InContainer()
    end)
end