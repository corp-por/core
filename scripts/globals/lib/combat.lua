-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Combat = {}

--- Determine if an attacker can attack/damage a victim
-- @param attack mobileObj, the mobile doing the targeting.
-- @param victim mobileObj, the mobile being targeted.
-- @return true if valid combat target
function Combat.ValidTarget(attacker, victim, silent)
	-- validate our attacker and victim
    if ( attacker == nil or victim == nil ) then return false end
    if ( attacker == victim ) then return false end
    if ( not attacker:IsValid() or not victim:IsValid() ) then return false end
    if ( Var.Has(victim, "InvalidTarget") ) then return false end
    
    return victim:IsMobile() and not Death.Active(victim)
end

--- Determine if an attacker is within range of a defender given a weaponType.
function Combat.WithinWeaponRange(attacker, defender, weaponType)
    return Interaction.WithinRange(attacker, defender, GetCombatWeaponRange(attacker, defender, weaponType))
end

--- Determine if an attacker is within range of a defender given a range.
function Combat.WithinRange(attacker, defender, range)
    return Interaction.WithinRange(attacker, defender, Combat.GetRange(attacker, defender, range))
end

--- Get the distance attacker must be from defender for combat.
-- @param attacker mobileObj
-- @param defender mobileObj
-- @param range double, weapon range or barehand range if not provided
-- @return distance to consider attacker close enough to defender for combat
function Combat.GetRange(attacker, defender, range)
	return ( range or Weapon.GetRange(nil) ) + GetBodySize(attacker) + GetBodySize(defender)
end

--- Convenience function that does what Combat.GetRange does, but instead takes a weaponType as last parameter
-- @param attacker mobileObj (for body size/weapon range)
-- @param defender mobileObj (for body size)
-- @param weaponTemplate(optional) string Defaults to nil (bare hands)
-- @return distance to consider attacker close enough to defender for combat
function Combat.GetWeaponRange(attacker, defender, weaponTemplate)
	weaponTemplate = weaponType or Object.TemplateId(Weapon.GetPrimary(attacker))
	return Combat.GetRange(attacker, defender, Weapon.GetRange(weaponTemplate))
end