function ToBits(num,reverse)
    local t={}
    while num>0 do
        local rest=math.floor(num%2)
        table.insert(t,rest)
        num=(num-rest)/2
    end 
    if #t == 0 then table.insert(t,0) end
    local binary_string = table.concat(t)
    if reverse then binary_string:reverse() end
    return binary_string
end

for i =0 , 20 do 
    print(i,ToBits(i))
end