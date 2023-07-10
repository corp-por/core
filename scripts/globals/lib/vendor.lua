-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

if ( Vendor == nil ) then Vendor = {} end

local restockPriceList = {}
for vendor_template, vdata in pairs(Vendor.Stock) do
    if ( restockPriceList[vendor_template] == nil ) then
        restockPriceList[vendor_template] = {}
    end
    for i=1,#vdata do
        restockPriceList[vendor_template][vdata[i].Template] = vdata[i].Price
    end
end

-- NPC vendors only (technically player vendors are npcs too but you get the idea)
Vendor.NPC = {}

function Vendor.NPC.Restock(vendor, inventory)
    if not( inventory ) then
        inventory = Backpack.Get(vendor)
    end
    if not( inventory ) then
        LuaDebugCallStack("Attempting to restock a vendor that doesn't have an Inventory")
        return
    end

    local template = Object.Template(vendor)

    -- no restock necessary
    if ( Vendor.Stock[template] == nil ) then return end
    
    -- find all items that are missing
    local restock = Vendor.Stock[template]
    local skip = {}
    local objs = inventory:GetContainedObjects()
    for i=1,#restock do
        for ii=1,#objs do
            if ( restock[i].Template == Object.Template(objs[ii]) ) then
                skip[restock[i].Template] = true
            end
        end
    end

    local priceList = Vendor.GetPriceList(vendor)
    for i=1,#restock do
        if ( skip[restock[i].Template] ~= true ) then
            Create.InContainer(restock[i].Template, inventory, nil, function(obj)
                if ( priceList[restock[i].Template] ) then
                    --SetTooltipEntry(obj,"price","\n[E5C233]"..priceList[restock[i].Template].." Gold",-10000)
                end
            end)
        end
    end
end

function Vendor.GetPriceList(vendor)
    local price_list = Var.Get(vendor, "PriceList")
    if ( price_list == nil ) then
        local vendor_template = Object.Template(vendor)
        if ( restockPriceList[vendor_template] ) then
            return restockPriceList[vendor_template]
        end
    else
        return price_list
    end

    return {}
end

function Vendor.GetPrice(vendor, object, price_list)
    if not( price_list ) then
        price_list = Vendor.GetPriceList(vendor)
    end

    if ( price_list ) then
        local template = Object.Template(object)
        if ( price_list[template] ) then
            return price_list[template]
        end
        if (  price_list[object] ) then
            return price_list[object]
        end
    end

    return 999999999
end

function Vendor.OnPurchase(object)
    RemoveTooltipEntry(object,"price")
end

-- handles players talking to vendors
function Vendor.HandleCommand(playerObj, command)

    if ( Var.Temp.Has(playerObj, "VendorAwaitingResponse") ) then
        local vendor = Var.Temp.Get(playerObj, "VendorAwaitingResponse")
        -- so we only 'eat' at most one message per response
        Var.Temp.Del(playerObj, "VendorAwaitingResponse")
        -- send the response back to the vendor
        vendor:SendMessage("Response", command)
        -- return false as to prevent any overhead chat
        return true
    end

    -- TODO: Buy/sell commands

    return false
end

-- player vendor only functions
Vendor.Player = {}

function Vendor.Player.HasControl(playerObj, vendorObj)
    return false
end

function Vendor.Player.SetPrice(vendor, object, price)
    local price_list = Vendor.GetPriceList(vendor)
    price_list[object] = price
    Var.Set(vendor, "PriceList", price_list)
end

function Vendor.Player.SetObjectPrice(vendor, object, price)
    local price_list = Vendor.GetPriceList(vendor)
    price_list[object] = price
    Var.Set(vendor, "PriceList", price_list)
end

function Vendor.Player.RemoveObjectPrice(vendor, object)
    local price_list = Vendor.GetPriceList(vendor)
    if ( price_list[object] ) then
        price_list[object] = nil
        Var.Set(vendor, "PriceList", price_list)
    end
end

function Vendor.Player.SetTemplatePrice(vendor, template, price)
    local price_list = Vendor.GetPriceList(vendor)
    price_list[template] = price
    Var.Set(vendor, "PriceList", price_list)
end