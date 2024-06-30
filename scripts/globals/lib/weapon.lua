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

function Weapon.GetSpeed(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Speed ~= nil ) then
        return table[templateid].Speed
    end
    return 1.0
end

function Weapon.GetDamageType(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].DamageType ~= nil ) then
        return table[templateid].DamageType
    end
	return "Bashing"
end

function Weapon.GetRange(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Range ~= nil ) then
        return table[templateid].Range
    end
	return 0.625
end

function Weapon.GetDamage(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Damage ~= nil ) then
        return table[templateid].Damage
    end
	return 1
end

function Weapon.GetDPS(templateid, table)
	return Weapon.GetDamage(templateid, table) / Weapon.GetSpeed(templateid, table)
end

function Weapon.IsRanged(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Ranged == true ) then
        return true
    end
	return false
end

function Weapon.IsStaff(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Staff == true ) then
        return true
    end
	return false
end

function Weapon.IsShield(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Shield == true ) then
        return true
    end
	return false
end

function Weapon.IsTwoHanded(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].TwoHanded == true ) then
        return true
    end
	return false
end

function Weapon.CanBeEquippedWithTwoHandedWeapon(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].CanBeEquippedWithTwoHandedWeapon == true ) then
        return true
    end
	return false
end

function Weapon.GetImpactSound(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil and table[templateid].Damage ~= nil ) then
        return table[templateid].ImpactSound
    end
	return "hand"
end

--- Since a weapon can have a Min/Max damage (via a table) this will 'observe' the damage by
---- doing a random between min/max.
-- @param templateid WeaponTemplate
function Weapon.ObserveDamage(templateid, table)
    if ( table == nil ) then table = Template end
    if ( templateid == nil ) then templateid = "weapon_fists" end
    if ( table[templateid] ~= nil ) then
        if ( type(table[templateid].Damage) == "table" ) then
            return math.random(table[templateid].Damage[1], table[templateid].Damage[2])
        else
            return table[templateid].Damage
        end
    end
    return math.random(1, 2)
end