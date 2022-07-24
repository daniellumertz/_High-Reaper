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


function literalize(str)
  return str:gsub(
    "[%(%)%.%%%+%-%*%?%[%]%^%$]",
    function(c)
      return "%" .. c
    end
  )
end


---------------------
----------------- Strings 
---------------------
function table.subs(tbl, val) -- Insert something at the end of the table and remove the smalest index
  table.remove(tbl,1)
  table.insert(tbl,#tbl+1,val)
end


function SubString(big_string,sub) -- Iterator function that return matches of sub in big_string. More less like gmatch but allow soberpossed macheses like in "ababc" trying to get "ab." will retunr "aba","abc"
  local start_char = 1
  return function ()
      while true do
          local s, e =string.find(big_string,sub,start_char) -- Check if there is a match after start_char
          if s then
              start_char = start_char + s
              return string.sub(big_string, s, e)
          else -- No more matches
              break
          end
      end
      start_char = 1
      return nil -- break for loop        
  end
end

---------------------
----------------- Tables
---------------------

function TableValuesCompareAtLeastOne(table1,table2) -- At least one in common
  for key, item in pairs(table1) do
      for key2, item2 in pairs(table2) do
          if item == item2 then return true end
      end 
  end
  return false
end

function TableValuesCompareCount(table1,table2) --Count values that are equal in both tables, wihtout order. Each repeated value is only considered once lie {2,6,4,6} and {6,6,6} will result in 1
  local used_keys = {}
  local cnt = 0
  for key, item in pairs(table1) do
      for key2, item2 in pairs(table2) do
          if not used_keys[key2] and (item == item2 or tostring(item) == tostring(item2) ) then
              used_keys[key2] = true
              cnt = cnt + 1
              break
          end
      end 
  end
  return cnt
end

---It uses ipairs if want to use in a table with strings as keys change to pairs
---@param tab table table iterate to check values
---@param val any value to be checked
---@return boolean, any
function TableHaveValue(tab, val) -- Check if table have val in the values. (Uses) 
    for index, value in ipairs(tab) do
        if value == val then
            return true, index
        end
    end
    return false, false
end

function TableValuesCompareNoOrder(table1,table2) --  Check if both tables haves the same values. 
  if #table1 ~= #table2 then return false end
  local used_keys = {}
  for key, item in pairs(table1) do
      local bol = false -- if one item isnt found then break
      for key2, item2 in pairs(table2) do
          if not used_keys[key2] and (item == item2 or tostring(item) == tostring(item2) )then
              used_keys[key2] = true
              bol = true
              break
          end
      end 
      if not bol then return false end
  end
  if #used_keys == #table1 then return true else return false end
end

function TableLen(table)
  local c = 0
  for k,v in pairs(table) do 
      c = c + 1 
  end
  return c
end

function TablesCombineKeys(table1,table2) -- Presume the values inside keys are tables so I add them. If not I Convert to a table and add them 
  for key, value in pairs(table1) do
      if table2[key] then
          if type(table2[key]) ~= "table" then 
              local temp_value = table2[key] 
              table2[key] = {}
              table.insert(table2[key],temp_value)
          end
          if type(value) ~= 'table' then
              table.insert(table2[key],value)
          else
              table2[key] = TablesCombine(value,table2[key])
          end
      else
          table2[key] = value
      end  
  end
  return table2
end

function TablesCombine(table1,table2)
  for key, value in pairs(table1) do
      table.insert(table2,value)
  end
  return table2
end

function TableCopy(t)
  local t2 = {}
  for k,v in pairs(t) do
      t2[k] = v
  end
  return t2
end

function TableHaveAnything(t)
  for k,v in pairs(t) do
      return true
  end
  return false
end

--function to get randomly from a table
function GetFromTableRandom(t)
  local n = #t
  local r = math.random(n)
  return t[r]
end

-- lua remove repeated in a table
function TableRemoveRepeated(table)
  local new_table = {}
  for index, value in ipairs(table) do
      if not TableHaveValue(new_table, value) then
          new_table[#new_table+1] = value
      end
  end
  return new_table
end

---------------------
----------------- MISC
---------------------

function open_url(url)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end

---------------------
----------------- Numbers
---------------------

---Limit a number between min and max
---@param number number number to be limited
---@param min number minimum number
---@param max number maximum number
---@return number
function LimitNumber(number,min,max)
if min and number < min then return min end
if max and number > max then return max end
return number
end


