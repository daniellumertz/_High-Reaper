---------------------
----------------- Print
---------------------

function print(...) 
    local t = {}
    for i, v in ipairs( { ... } ) do
      t[i] = tostring( v )
    end
    reaper.ShowConsoleMsg( table.concat( t, "\n" ) .. "\n" )
end

function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
      formatting = string.rep("  ", indent) .. tostring(k) .. ": "
      if type(v) == "table" then
        print(formatting)
        tprint(v, indent+1)
      elseif type(v) == 'boolean' then
        print(formatting .. tostring(v))      
      else
        print(formatting .. tostring(v))
      end
    end
end

---------------------
----------------- Table
---------------------

---It uses ipairs if want to use in a table with strings as keys change to pairs
---@param tab table table iterate to check values
---@param val any value to be checked
---@return boolean
function TableHaveValue(tab, val) -- Check if table have val in the values. (Uses) 
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

---Simple Table Copy. Very Fast!. Dont return string keys ! Return Tables within tables! Dont return recursive tables. Dont know what it does with metatables
---@param t table
---@return table
function TableCopy(t) -- From http://lua-users.org/wiki/CopyTable
  return {table.unpack(t)}
end

---Create a copy of the tablee with all children tables new as well. 
---@param thing any
---@return table
function table_copy_regressive(thing)
  if type(thing) == 'table' then
      local new_table = {}
      for k , v in pairs(thing) do
          local new_v = table_copy_regressive(v)
          local new_k = table_copy_regressive(k)
          new_table[new_k] = new_v
      end
      return new_table
  else 
      return thing
  end
end
---------------------
----------------- Bit
---------------------

---transofrms num (a decimal number) as string.
---@param num number
---@param reverse boolean if false 2 = 01 if true 2 = 10. False = little endian (lsb comes first from left to right)
---@return string
function ToBits(num,reverse)
    local t={}
    while num>0 do
        local rest=math.floor(num%2)
        table.insert(t,rest)
        num=(num-rest)/2
    end 
    if #t == 0 then table.insert(t,0) end
    local binary_string = table.concat(t)
    if reverse then binary_string = binary_string:reverse() end
    return binary_string
end


function BitTabtoStr2(t, len) -- transform an BitTab in a String 
    local s = ""
    local i = 1;
    while i <= len do
      s = (tostring(t[i] or "0"))..s
      i = i + 1
    end
    return s
end

