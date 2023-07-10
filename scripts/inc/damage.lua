-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD


-- locally keep track in memory how much damage to be absorbed
local _AbsorbDamageLeft = 0
RegisterEventHandler(EventType.Message, "SetDamageAbsorbAmount", function(amount)
    _AbsorbDamageLeft = _AbsorbDamageLeft + amount
end)

function OnDamageReceived(from, amount, damageType)
    if ( Death.Active(this) or amount == nil ) then return end

    damageType = damageType or "Bashing"
	
	local typeData = Damage.Type[damageType]
	-- not a real combat damage type, stop here.
	if not( typeData ) then
		LuaDebugCallStack("[HandleApplyDamage] invalid type: "..damageType)
		return
	end

	if ( Var.Has(this, "Invulnerable") ) then
		this:NpcSpeech("[C0C0C0]Invulnerable[-]", "combat")
		return
    end
    
    Action.Taken(this, "Damage", "Hit")

	if ( typeData.Elemental ) then
        amount = Modify.Apply(this, "ElementalFrom", amount)
	end

    if ( typeData.Physical ) then
        amount = Modify.Apply(this, "PhysicalFrom", amount)
    end

    amount = Modify.Apply(this, string.format("%sFrom", damageType), amount)
	
    amount = math.round(amount)
    
    if ( _AbsorbDamageLeft and _AbsorbDamageLeft > 0 ) then
        if ( _AbsorbDamageLeft >= amount ) then
            _AbsorbDamageLeft = _AbsorbDamageLeft - amount
            this:NpcSpeech("[ffffff]Absorb "..amount.."[-]", "combat")
            return
        else
            local amt = _AbsorbDamageLeft
            amount = amount - _AbsorbDamageLeft
            _AbsorbDamageLeft = 0
            this:SendMessage("AllAbsorbed")
            this:NpcSpeech("[ffffff]Absorb "..amt.."[-]", "combat")
        end
    end

	-- to account for more absorbing then damage and prevent 0 damage done (or NaN or Infinity)
	if ( amount < 0.5 or amount ~= amount or amount > 9999999999 ) then
		amount = 1
	end

    if ( typeData.Physical or typeData.Elemental ) then
        -- do spell pushback
        if ( m_CurrentAbilityPushback ~= nil and m_CurrentAbilityPushback < 5 ) then
            if ( Ability.Cast.TryPushback(this, 0.75) ) then
                m_CurrentAbilityPushback = m_CurrentAbilityPushback + 1
            end
        end
    end
    
    local currentHealth = Stat.Health.Get(this) or 1
    if ( amount > currentHealth ) then amount = currentHealth end

    this:NpcSpeech("[FFFFFF]"..amount.."[-]", "combat")

	local newHealth = currentHealth - amount
    if ( newHealth <= 0 ) then
        Death.Start(this)
    else
        Action.Taken(this, "Damage", "Apply")

        Stat.Health.Set(this, newHealth)

        if ( amount >= 0 ) then
            this:PlayAnimation("was_hit")
            --this:PlayEffect("FX_Slash_01")
            
            local damagePercent = newHealth / currentHealth

			if ( damagePercent >= 0.03 and math.random(1,2) == 1 ) then
				this:PlayObjectSound("Pain", true)
            end
            
			if ( damagePercent >= 0.10 ) then
				this:PlayEffect("BloodSplat")
			end			
		end
	end

	return newHealth
end

RegisterEventHandler(EventType.Message, "Damage", function(...) OnDamageReceived(...) end)