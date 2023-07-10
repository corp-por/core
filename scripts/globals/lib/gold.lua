-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Gold = {}

function Gold.Init(mobileObj)
    mobileObj:SetStatValue("Gold", 0)
end

function Gold.Get(mobileObj)
    return mobileObj:GetStatValue("Gold") or 0
end

function Gold.Has(mobileObj, amount)
    return Gold.Get(mobileObj) >= amount
end

function Gold.Transfer(from, to, amount)
    amount = amount or 0
    if ( amount < 1 ) then return false end
    if not( from and from:IsValid() ) then return false end
    if not( to and to:IsValid() ) then return false end
    amount = math.floor(amount + 0.5) -- round to nearest full number
    local fromTotal = Gold.Get(from)
    if ( amount > fromTotal ) then return false end
    local toTotal = Gold.Get(to)
    from:SetStatValue("Gold", fromTotal - amount)
    to:SetStatValue("Gold", toTotal + amount)
    --DebugMessage(amount, "gold was transferred from", from, "to", to)
    return true
end

function Gold.Create(mobileObj, amount)
    amount = amount or 0
    if ( amount < 1 ) then return false end
    if not( mobileObj and mobileObj:IsValid() ) then return false end
    amount = math.floor(amount + 0.5) -- round to nearest full number
    local total = Gold.Get(mobileObj)
    mobileObj:SetStatValue("Gold", total + amount)
    --DebugMessage(amount, "gold was created on", mobileObj)
    return true
end