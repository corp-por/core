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

--- Sort and return a table using custom sorting
-- @param t, table to sort
-- @param order, optional ordering function
-- @return table ordered by default or custom function
function sortpairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys 
  if order then
      table.sort(keys, function(a,b) return order(t, a, b) end)
  else
      table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
      i = i + 1
      if keys[i] then
          return keys[i], t[keys[i]]
      end
  end
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
  if ( v == nil ) then return 0 end
  local shift = 10 ^ ( place or 0 )
  return math.floor( v * shift + 0.5 ) / shift
end

math.randomfloat = function(lower, greater, roundPlace)
    if ( roundPlace ) then
        return math.round(
            lower + math.random()  * (greater - lower),
            roundPlace
        )
    else
        return lower + math.random()  * (greater - lower);
    end
end

math.roundtonearest = function(v, nearest)
  if ( v == nil ) then 
    return 0 
  end

  --DebugMessage("IN: "..v.." OUT: "..math.floor(v / nearest) * nearest)
  return math.floor(v / nearest) * nearest  
end

RoundLocToNearest = function(loc, nearestX, nearestZ)
  if not(nearestZ) then
    nearestZ = nearestX
  end
  return Loc(math.roundtonearest(loc.X,nearestX),loc.Y,math.roundtonearest(loc.Z,nearestZ))
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
function StringSplit(inputstr,sep)
  if not(inputstr) then return nil end
  if(inputstr == "") then return {} end

  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t
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
function StripTrailingComma(inputStr,character) 
  local character = character or ","

  if(string.sub(inputStr,#inputStr-1,#inputStr) == (character.." ") ) then
    return string.sub(inputStr,1,#inputStr-2)
  elseif( string.sub(inputStr,#inputStr,-1) == character ) then
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

--- Returns the number of times the item is in the array
-- @warning Doesn't handle non-tables cleanly
-- @param input table
-- @param item to search for (using ==)
-- @return true if item exists
function CountOccurrencesInTableArray (tableName, item)
    local count = 0
    for i,v in pairs(tableName) do
        if( v == item) then
            count = count + 1
        end
    end
    return count
end

--- Search for the index of an element in an array
-- @param array to search
-- @param element to search for
-- @param comparison function (simple == by default)
-- @return index of element, nil if not found
function IndexOf(array,item,compFunc)
    for i=1,#array do
        if( compFunc ~= nil and compFunc(array[i],item) ) then
            return i
        elseif( compFunc == nil and array[i] == item ) then
            return i
        end
    end
end

--- Count the number of elements in a table
-- @param input table
-- @param item (optional) to search for
-- @warning Doesn't handle non-tables cleanly
function CountTable(T,item)
    if not(T) then
      return 0
    end

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

-- TODO: BUG: Doesn't handle non-iterators
function BuildArray(...)
  local arr = {}
  for v in ... do
    arr[#arr + 1] = v
  end
  return arr
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
-- @return strippedString, colorCode
function StripColorFromString(inputStr)
	if not(inputStr) then return nil end
  local color = string.match(inputStr,"%[......%]")
  local outStr = string.gsub(inputStr,"%[......%]","")
  local outStr = string.gsub(outStr,"%[%-%]","")
  return outStr, color
end

function StripStackCountFromString(inputStr)
	if not(inputStr) then return nil end
  local outStr = string.gsub(inputStr,"[0-9]+ ","")
  return outStr
end

--- Given a percent based chance (between 0 and 1) returns a true/false successful roll.
-- @param chance double Percent based between 0 and 1
-- @return true if successful
function Success(chance)
  return chance >= 1.0 or chance > (math.random(0.0, 99999.0) / 100000.0)
end

-- TODO: BUG: CRASH: DumpTable() will hang if attempting to read a complex table such as a loaded module
-- REPRO: DumpTable(LoadExternalModule('mime'))
-- REPLACE: Consider https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
function DumpTable(tableName,indent)
  if(tableName == nil) then
    return "Invalid Table"
  end

  if(indent == nil) then indent = "" end

  local outStr = ""
  for mKs, mVs in pairs(tableName) do
    if(type(mVs) == "table") then
      outStr = outStr .. indent .. " --> (table) " .. tostring(mKs) .."\n"
      outStr = outStr .. DumpTable(mVs,indent .. "  ")
    else
      outStr = outStr .. indent .. " --> " .. tostring(mKs) .. " : " ..tostring(mVs) .. "\n"
    end
  end

  return outStr
end

function randomGaussian(mean,deviation)
  local randStdNormal = math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random()) / 2
  return mean + (deviation * randStdNormal)
end

--- Get a weighted random number between min and max by picking the closest candidate to the specified weight.
-- @param min(number)
-- @param max(number)
-- @param weight(number)
-- @param candidates(number)(optional) Number of candidates to choose from, defaults to 3
function WeightedRandom(min, max, weight, candidates)
  if ( candidates == nil ) then candidates = 3 end
  local math = math -- local variables are faster to index than global
  local rolls, roll = {}, nil
	local closest = 99999
	-- establish all candidates
	for i=1,candidates do
		-- create the full table with max as a placeholder for difference
		roll = {math.random(min,max), max}
		-- establish the real difference
		roll[2] = math.abs(weight - roll[1])
		-- decide if this difference is closer than any previous differences
		if ( roll[2] < closest ) then
			closest = roll[2]
		end
		-- add the roll to the table
    	rolls[#rolls+1] = roll
	end
	-- to account for rolling a 30 30 50 and a weight of 40, for example,
	-- we do another roll between all candidates that match the closest
	local fin = {}
	for i=1,candidates do
        if ( rolls[i][2] == closest ) then
            fin[#fin+1] = rolls[i][1]
		end
	end
	return fin[math.random(1,#fin)]
end

--- Get a spiral location by distance from origin
-- @param (number)index - Distance from origin
-- @param (Loc)center (optional)
-- @param (number) size (optional) - The size of the 'grid' the spiral follows
-- @return Loc
function GetSpiralLoc(index, center, size)
  if ( index < 1 ) then return center or Loc(0,0,0) end
  local math = math
  local shell = math.floor((math.sqrt(index)+1)/2);
  local leg = math.floor( ( index - math.pow( 2 * shell - 1, 2 ) ) / ( 2 * shell ) );
  local element = (index - math.pow(2 * shell -1, 2 )) - 2 * shell * leg - shell + 1;
  
  if ( leg == 0 ) then
      x, z = shell, element
  elseif ( leg == 1 ) then
      x, z = -element, shell
  elseif ( leg == 2 ) then
      x, z = -shell, -element
  else
      x, z = element, -shell
  end

  if ( size ) then
    x, z = x*size, z*size
  end

  if ( center ) then
    x, z = x+center.X, z+center.Z
  end

  local loc = Loc(x, 50, z)
  loc:FixY()
  return loc
end

--- A squared plus B squared equals C squared.
-- @param a (number)
-- @param b (number)
-- @return c (number)
function CalculateHypotenuse(a, b)
  return math.sqrt((a*a)+(b*b))
end

local romanNumbers = { 1, 5, 10, 50, 100, 500, 1000 }
local romanChars = { "I", "V", "X", "L", "C", "D", "M" }
function ToRomanNumerals(s)
  --s = tostring(s)
  s = tonumber(s)
  if not s or s ~= s then return "" end
  if s == math.huge then return "" end
  s = math.floor(s)
  if s <= 0 then return s end
  local ret = ""
        for i = #romanNumbers, 1, -1 do
        local num = romanNumbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. romanChars[i]
            s = s - num
        end
        --for j = i - 1, 1, -1 do
        for j = 1, i - 1 do
            local n2 = romanNumbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. romanChars[j] .. romanChars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end


local _wait = TimeSpan.FromMilliseconds(1)
function OnNextFrame(cb)
  if ( cb ) then
    CallFunctionDelayed(_wait, cb)
  end
end

function EnglishPossessive(str)
	-- put proper ownership text to the string.
	if ( string.sub(str, -1, -1) == "s" ) then
		str = str .. "'"
	else
		str = str .. "'s"
  end
  return str
end