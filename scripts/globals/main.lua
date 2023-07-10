-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

-- globals

-- engine functions (called directly from the engine)
require 'globals.engine_callbacks'
-- extensions to the lua standard library
require 'globals.lua_extensions'

-- configurable server settings
require 'globals.server_settings._main'
-- behaviors (modulated logic for specific uses)
require 'globals.behavior._main'
-- stats (health/mana/etc)
require 'globals.stats._main'
-- static data tables
require 'globals.static_data._main'
-- user interface logic
require 'globals.ui._main'
-- global library functions
require 'globals.lib._main'
-- effects
require 'globals.effects._main'
-- global helper functions
require 'globals.helpers._main'
-- auto fixes for existing backup data
require 'globals.autofix._main'
-- ai
require 'globals.ai._main'