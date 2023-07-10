-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

require 'globals.ai.aiproperty'
require 'globals.ai.fsm'

States = {}
require 'globals.ai.states.basic.aggro'
require 'globals.ai.states.basic.attack'
require 'globals.ai.states.basic.chargetolocation'
require 'globals.ai.states.basic.death'
require 'globals.ai.states.basic.empty'
require 'globals.ai.states.basic.emptyfalse'
require 'globals.ai.states.basic.fight'
require 'globals.ai.states.basic.fightadvanced'
require 'globals.ai.states.basic.flee'
require 'globals.ai.states.basic.followpath'
require 'globals.ai.states.basic.leash'
require 'globals.ai.states.basic.pause'
require 'globals.ai.states.basic.respawn'
require 'globals.ai.states.basic.walk'
require 'globals.ai.states.basic.wander'

require 'globals.ai.states.summon.summon_follow'