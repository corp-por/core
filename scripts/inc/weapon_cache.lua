-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- caching some weapon information to local memory space since this only changes when weapons are changed, 
--- but the data is read from a lot.
m_weapon = {
	Object = nil,
	TemplateId = nil,
    IsRanged = false,
    IsStaff = false,
    Range = Weapon.GetRange(nil),
    Speed = Weapon.GetSpeed(nil),
    DamageType = Weapon.GetDamageType(nil)
}

m_offhand = {
	Object = nil,
	TemplateId = nil,
	Speed = nil,
	IsShield = false,
}

m_swingOffhand = false


-- function to update the cached weapon
function UpdateWeapon(weaponObj, offhand)
	if ( offhand ) then
		m_offhand.Object = weaponObj
		m_offhand.TemplateId = Object.TemplateId(weaponObj)
		m_offhand.Speed = Weapon.GetSpeed(m_offhand.TemplateId)
		m_offhand.IsShield = Weapon.IsShield(m_offhand.TemplateId)
		m_offhand.DamageType = Weapon.GetDamageType(m_offhand.TemplateId)
	else
		m_weapon.Object = weaponObj
		m_weapon.TemplateId = Object.TemplateId(weaponObj)
		m_weapon.IsRanged = Weapon.IsRanged(m_weapon.TemplateId)
		m_weapon.IsStaff = not m_weapon.IsRanged and Weapon.IsStaff(m_weapon.TemplateId)
		m_weapon.Range = Weapon.GetRange(m_weapon.TemplateId)
		m_weapon.Speed = Weapon.GetSpeed(m_weapon.TemplateId)
		m_weapon.IsTwoHanded = Weapon.IsTwoHanded(m_weapon.TemplateId)
		m_weapon.DamageType = Weapon.GetDamageType(m_weapon.TemplateId)
	end
    
	m_swingOffhand = false
	_left = false
	
    if ( m_offhand.Object ~= nil ) then
        -- if there's an object in left hand, and it's not a shield
        m_swingOffhand = not m_offhand.IsShield
    else
        -- swing offhand if we are unarmed/two handed
        m_swingOffhand = ( m_weapon.Object == nil or m_weapon.IsTwoHanded )
	end
end

--- cache some info on our weapons since they get used a lot.
UpdateWeapon(Weapon.GetPrimary(this))
UpdateWeapon(Weapon.GetOffhand(this), true)