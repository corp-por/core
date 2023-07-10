-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Weapon = {}

function Weapon.GetPrimary(mobileObj)
	if ( mobileObj ~= nil ) then
		return mobileObj:GetEquippedObject("RightHand")
	end
	return nil
end

function Weapon.GetOffhand(mobileObj)
	if ( mobileObj ~= nil ) then
		return mobileObj:GetEquippedObject("LeftHand")
	end
	return nil
end

function Weapon.GetSpeed(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Speed ~= nil ) then
        return table[template].Speed
    end
    return 1.0
end

function Weapon.GetDamageType(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].DamageType ~= nil ) then
        return table[template].DamageType
    end
	return "Bashing"
end

function Weapon.GetRange(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Range ~= nil ) then
        return table[template].Range
    end
	return 0.625
end

function Weapon.GetDamage(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Damage ~= nil ) then
        return table[template].Damage
    end
	return 1
end

function Weapon.GetDPS(template, table)
	return Weapon.GetDamage(template, table) / Weapon.GetSpeed(template, table)
end

function Weapon.IsRanged(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Ranged == true ) then
        return true
    end
	return false
end

function Weapon.IsStaff(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Staff == true ) then
        return true
    end
	return false
end

function Weapon.IsShield(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Shield == true ) then
        return true
    end
	return false
end

function Weapon.IsTwoHanded(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].TwoHanded == true ) then
        return true
    end
	return false
end

function Weapon.CanBeEquippedWithTwoHandedWeapon(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].CanBeEquippedWithTwoHandedWeapon == true ) then
        return true
    end
	return false
end

function Weapon.GetImpactSound(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil and table[template].Damage ~= nil ) then
        return table[template].ImpactSound
    end
	return "hand"
end

--- Since a weapon can have a Min/Max damage (via a table) this will 'observe' the damage by
---- doing a random between min/max.
-- @param template WeaponTemplate
function Weapon.ObserveDamage(template, table)
    if ( table == nil ) then table = ItemProperties end
    if ( template == nil ) then template = "fists" end
    if ( table[template] ~= nil ) then
        if ( type(table[template].Damage) == "table" ) then
            return math.random(table[template].Damage[1], table[template].Damage[2])
        else
            return table[template].Damage
        end
    end
    return math.random(1, 2)
end