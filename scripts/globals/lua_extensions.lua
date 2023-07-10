-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright © 2023 Corp Por LTD

--- Extensions to the Lua scripting language
-- @module globals.lua.extensions

--- Create a class table
-- @param base class table
-- @param init function
-- @return class table
function class(base, init)
  local instance = {}
  instance.__index = instance

  if not init and type(base) == 'function' then
    init = base
	base = nil
  elseif type(base) == 'table' then
    for i,v in pairs(base) do
	  instance[i] = v
	end

	instance._base = base
  end

  instance.init = init
  instance.is_a = function(self, class_name)
    local m = getmetatable(self)
	while m do
	  if (m == class_name) then return true end
	  m = m._base
	end

	return false
  end

  setmetatable(instance, {
    __call = function(t, ...)
      local o = {}
	  setmetatable(o, instance)

	  if (init) then 
	    init(o, ...)
	  elseif base and base.init then
	    base.init(o, ...)
	  end

	  return o
	end
  })

  return instance
end

function extends(child,parent)
  setmetatable(child,{__index=parent})
end

--- Make a table read only
-- Tables created as readonlytable cannot have their field assignments altered.
-- Note that the content of the assigned fields (such as table.field.content)
-- can be altered. The read-only pattern is only pseudo-read-only and only
-- prevents unintentional assignments to a read-only table.
-- http://lua-users.org/wiki/ReadOnlyTables
-- @param table the table definition 
function readonlytable(table)
  return setmetatable({}, {
    __index = table,
    __newindex = function(table, k, v)
                   error("@warning attempted to modify a read-only table")
                 end,
    __metatable = false
  });
end

--- Check if file exists
-- @param file path
-- @return true if exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

--- Create a shallow copy of a table (not recursive)
-- @param table to copy
-- @return copied table
-- REPRO: lu.assertNotEquals(shallowCopy(LoadExternalModule('mime')), LoadExternalModule('mime')) 
function shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- Create a deep copy of a table (recursive)
-- @param table to copy
-- @return copied table
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- Search for the value of an element in a table
-- @param table to search
-- @param element to search for
-- @param comparison function (required)
-- @return element value, nil if not found
function searchTable(tableRef,element,compFunc) 
  if( compFunc == nil ) then 
    return nil
  end
  
  for key, value in pairs(tableRef) do
    if( compFunc(value,element) ) then
      return value
    end
  end

  return nil
end

--- Return all the of keys in a table as an array
-- NOTE: Returned keys are not ordered, ex. { 2, 3, 1, 4, 5 }
-- @param table to get keys for
-- @return array of keys
function getTableKeys(table)
  local keyset={}
  local n=0

  for k,v in pairs(table) do
    n=n+1
    keyset[n]=k
  end

  return keyset
end

--- Create a custom 128 bit unique id string. This is a virtually guaranteed unique identifier
-- @return uuid
function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--- clamp a value v in the range [min, max] (inclusive)
-- @param v value to clamp
-- @param min minimum value
-- @param max maximum value
math.clamp = function(v, min, max)
  -- swap min/max if min greater than max
  if (min > max) then min, max = max, min end
  
  -- cap the value at the min or max if out of range
  if v < min then return min end
  if v > max then return max end
  
  -- return the original value if in range
  return v
end

--- Round a number to a specific decimal place
-- @param v double value to round
-- @param place double(optional) defaults to 0
-- @return rounded number
math.round = function(v, place)
  local shift = 10 ^ ( place or 0 )
  return math.floor( v * shift + 0.5 ) / shift
end

--- Get a random number between two values
-- @param min value
-- @param max value
function GetRandomInRange(min, max)
  return min + (math.random() * (max - min))
end

--- Load an external module (usually a .NET or C++ dll)
-- NOTE: Plugins are placed in the luatools directory in Build/base
-- @param module name
function LoadExternalModule(moduleName)
  if(GetLuaExtensionsEnabled()) then
    shards_require = require
    require = lua_require
    local moduleData = require(moduleName) 
    require = shards_require

    return moduleData
  end

  return nil
end

--- Splits a string into an array using the specified separator
-- @warning Fails on splitting with trailing tokens
-- @param input string
-- @param separator string
-- @return array of words
function StringSplit(str,sep)
  if not(str) then return nil end
  if(str == "") then return {} end

  sep = sep or '%s+'
  local st, g = 1, str:gmatch("()("..sep..")")
  local function getter(segs, seps, sep, cap1, ...)
    st = sep and seps + #sep
    return str:sub(segs, (seps or 0) - 1), cap1 or sep, ...
  end
  local function iterFunc() if st then return getter(st, g()) end end

  local items = {}
  for i in iterFunc do
    items[#items + 1] = i
  end

  return items
end

--- Combine multiple arguments into a single string
-- NOTE: This is useful when parsing commands from the client since spaces
-- are used as separators for arguments
-- @param argument list of strings
-- @return combined string
function CombineArgs(...)
  local arg = table.pack(...)
  if(#arg > 0) then
    return CombineString(arg," ")
  end
end

--- Combine an array of strings into a single string
-- @warning Doesn't handle non-arrays cleanly
-- @param array of strings
-- @param separator to put in between strings
function CombineString(array,separator)
  local line = ""
  for i = 1,#array do 
    if(i==#array) then
      separator = ""
    end
    line = line .. tostring(array[i]) .. separator 
  end

  return line
end

--- Trim leading and trailing spaces and newlines off string
-- @param str to trim
-- @return trimmed string
function StringTrim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

--- Removes the newline at the end if it exists
-- @warning Doesn't handle multiple newline characters
-- @param input string
-- @return output string
function StripTrailingNewline(inputStr) 
  if( string.sub(inputStr,#inputStr,-1) == "\n" ) then
    return string.sub(inputStr,1,#inputStr-1)
  else
    return inputStr
  end
end

--- Removes the comma at the end if it exists
-- @warning Doesn't handle multiple trailing commas
-- @param input string
-- @return output string
function StripTrailingComma(inputStr) 
  if(string.sub(inputStr,#inputStr-1,#inputStr) == ", " ) then
    return string.sub(inputStr,1,#inputStr-2)
  elseif( string.sub(inputStr,#inputStr,-1) == "," ) then
    return string.sub(inputStr,1,#inputStr-1)
  else
    return inputStr
  end
end

--- returns two tables combined
-- @warning Doesn't handle non-tables cleanly
-- @param input table 1
-- @param input table 2
-- @output combined table
function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

--- remove an item from a table by value
-- @warning Doesn't handle non-tables cleanly
-- @param input table
-- @param item to search for (using ==)
-- @output true if item was found
function RemoveFromArray(tableName, item)
    for i,v in pairs(tableName) do
        if( v == item) then
            table.remove(tableName,i)
            return true
        end
    end
    return false
end

--- Checks if a value exists in an array
-- @warning Doesn't handle non-tables cleanly
-- @param input table
-- @param item to search for (using ==)
-- @return true if item exists
function IsInTableArray (tableName, item)
    for i,v in pairs(tableName) do
        if( v == item) then
            return true
        end
    end
    return false
end

--- Search for the index of an element in an array
-- @param array to search
-- @param element to search for
-- @param comparison function (simple == by default)
-- @return index of element, nil if not found
function IndexOf(tableName,item)
    for i=1,#array do
        if( compFunc ~= nil and compFunc(array[i],element) ) then
            return i
        elseif( compFunc == nil and array[i] == element ) then
            return i
        end
    end
end

--- Count the number of elements in a table
-- @param input table
-- @param item (optional) to search for
-- @warning Doesn't handle non-tables cleanly
function CountTable(T,item)
    local count = 0
    for k,v in pairs(T) do 
        if(item == nil or item == v) then 
          count = count + 1 
      end 
    end
    return count
end

--- Check if table is empty
-- @param input table
-- @return true if table is empty
-- @todo Refactor with next()
-- @warning non-boolean return on error
function IsTableEmpty(T)
    if not(T) then
      LuaDebugCallStack("ERROR: IsTableEmpty received nil reference")
      return
    end

    for _ in pairs(T) do return false end
    return true
end

--- An extended version of the lua type function
-- Attempts to resolve userdata types into a more specific type
-- @param value to check
-- @return type of value
function GetValueType(dataVal)
  if(dataVal == nil) then
    return ""
  end

  local luaType = type(dataVal)
  if(luaType == "userdata") then
    return GetUserdataType(dataVal)
  end

  return luaType
end

--- Convert unix time to a date time object
-- @param unix time value
-- @return date time value
function UnixTimeToDateTime(unixTime)
    local epoch = DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)
    return epoch:AddSeconds(unixTime);
end

--- Separate the color and the string data
-- @param colored string
-- @return white string
-- @return color code
function StripColorFromString(inputStr)
  local color = string.match(inputStr,"%[......%]")
  local outStr = string.gsub(inputStr,"%[......%]","")
  local outStr = string.gsub(outStr,"%[%-%]","")
  return outStr, color
end

--- Given a percent based chance (between 0 and 1) returns a true/false successful roll.
-- @param chance double Percent based between 0 and 1
-- @return true if successful
function Success(chance)
  return chance >= 1 or chance > (math.random(0, 99999) / 100000)
end