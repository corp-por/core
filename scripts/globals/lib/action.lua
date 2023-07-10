-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

Action = {}

--- This is a simple function to aidin readability and serve as a general hook for 'actions' taken
---- These actions generally end invisibility or similar but can also be listened to anywhere to break other actions
-- @param by gameObject (usually a mobileObject) that is taking the action
-- @param type What type of action is being taken
-- @param id Optionally provide an identifier that allows you to pick between specific types of actions
function Action.Taken(by, type, id)
    by:SendMessage("ActionTaken", type, id)
end