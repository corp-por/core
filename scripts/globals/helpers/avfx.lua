-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- audio visual effects

    
--- Does the graphic/sound of an arrow flying from one mobile to another
-- @param from mobileObj
-- @param to mobileObj
-- @param weapon gameObj
function PerformClientArrowShot(from, to, weapon)
	PlayAttackAnimation(from)
	from:PlayProjectileEffectTo("Arrow", to, 0.33)
	PlayWeaponSound(from, "Shoot", weapon)
end

--- Plays the attack animation for mobileObj
-- @param mobile mobileObj
function PlayAttackAnimation(mobile, animationOverride)
	if ( mobile ) then mobile:PlayAnimation(animationOverride or "attack") end
end

function PlayImpactSound(target, soundParameterName, soundParameterValue, attacker)
	local soundParameters = {}
	soundParameters[soundParameterName] = soundParameterValue
	local weapon = Weapon.GetPrimary(attacker)
	local weaponSFX = EquipmentStats.BaseWeaponStats[Weapon.GetType(weapon)].SFXDir
	if weapon~=nil then
		target:PlayObjectSoundWithParameter("event:/weapons/"..weaponSFX.."/"..weaponSFX.."_impact", soundParameters, false)
	else
		target:PlayObjectSoundWithParameter("event:/weapons/general/general_impact", soundParameters, false)
	end
end

function PlayWeaponSound(target, audioId, weapon, soundParameterName, soundParameterValue)
	if ( weapon == nil ) then
		weapon = Weapon.GetPrimary(target)
	end
	if ( weapon ~= nil ) then
		if ( soundParameterName ~= nil and soundParameterValue ~= nil ) then
			local soundParameters = {}
			soundParameters[soundParameterName] = soundParameterValue

			weapon:PlayObjectSoundWithParameter(audioId, soundParameters, true)
		else
			weapon:PlayObjectSound(audioId, true)
		end
	else
		local soundPrefix = "event:/weapons/general/general_"
		if ( soundParameterName ~= nil and soundParameterValue ~= nil ) then
			local soundParameters = {}
			soundParameters[soundParameterName] = soundParameterValue
						
			target:PlayObjectSoundWithParameter(soundPrefix..audioId, soundParameters, false)
		else
			target:PlayObjectSound(soundPrefix..audioId, false)
		end
	end
end

function PlayAttackSound(attacker)
    attacker:PlayObjectSound("Attack", true)
    local attackerWeapon = Weapon.GetPrimary(attacker)
    if ( attackerWeapon ~= nil ) then
        attackerWeapon:PlayObjectSound("Attack", true)
    end
end