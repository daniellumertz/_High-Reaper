function table_copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[table_copy(k, s)] = table_copy(v, s) end
    return res
end

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
local abc = {type = 50, 6, {90,{{{{{{100}}}}}}}}


local start = os.clock()
for i = 1, 10^5 do
    local def = table_copy(abc)
end
print('table_copy')
print(os.clock() - start)

local start = os.clock()
for i = 1, 10^5 do
    def = table_copy_regressive(abc)
end
print('table_copy_regressive')
print(os.clock() - start)


