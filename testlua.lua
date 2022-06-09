---Perform a binary searach on the midi_table to find the message that comes before on in time with ppq argument.Return the last value: 0 if is before the first value, 1 if val1<=ppq<val2, 2 val<=ppq<val3. Insert the Midi message at index result+1.
---@param midi_table any
---@param ppq any
---@return number
function BinarySearchInMidiTable(midi_table,ppq)
    local floor = 1
    local ceil = #midi_table
    local i = math.floor(ceil/2)
    -- Try to get in the edges after the max value and before the min value
    if midi_table[#midi_table].offset_count <= ppq then return #midi_table end -- check if it is after the last midi_table value 
    if midi_table[1].offset_count > ppq then return 0 end --check if is before the first value. return 0 if it is
    -- Try to find in between values
    while true do
        -- check if is between midi_table and midi_table[i+1]
        if midi_table[i+1] and midi_table[i].offset_count <= ppq and ppq < midi_table[i+1].offset_count then return i end -- check if it is in between two values

        -- change the i (this is not the correct answer)
        if midi_table[i].offset_count > ppq then
            i = ((i - floor) / 2) + floor
            i = math.floor(i)
            ceil = i
        elseif midi_table[i].offset_count < ppq then
            i = ((ceil - i) / 2) + floor
            i = math.ceil(i)
            floor = i
        end    
    end
end

---Calculate the ppq diference from ppq and midi_table[last_idx] and 
---@param midi_table any
---@param last_idx any
---@param ppq any
---@return number
---@return number
function CalculatePPQDifPrevNextEvntOld(midi_table,last_idx,ppq)
    local dif_prev, dif_next
    if last_idx > 0 then -- calculate the difference of the previous message. check if there is a previous element
        dif_prev = ppq - midi_table[last_idx].offset_count
    else 
        dif_prev = ppq --return ppq as is the offset from the item start
    end

    if last_idx < #midi_table then --calculate the difference to the next message. check if there is a next element.
        dif_next = midi_table[last_idx+1].offset_count - ppq
    else
        dif_next = 0
    end
    return dif_prev, dif_next
end

---Calculate the ppq diference from ppq and midi_table[last_idx] and 
---@param midi_table any
---@param last_idx any
---@param ppq any
---@return number
---@return number
function CalculatePPQDifPrevNextEvnt(midi_table,last_idx,ppq)
    local dif_prev, dif_next
    if last_idx > 0 then -- calculate the difference of the previous message. check if there is a previous element
        dif_prev = ppq - midi_table[last_idx].offset_count
    else 
        dif_prev = ppq --return ppq as is the offset from the item start
    end

    if last_idx < #midi_table then --calculate the difference to the next message. check if there is a next element.
        dif_next = midi_table[last_idx+1].offset_count - ppq
    else
        dif_next = 0
    end
    return dif_prev, dif_next
end

local midi = {
    {offset_count = 960,offset = 960},
    {offset_count = 1560,offset = 600},
    {offset_count = 7890,offset = 6330},
    {offset_count = 10000,offset = 2110}
}

local ppq = 1001-41
local last = BinarySearchInMidiTable(midi,ppq)
local dif_prev, dif_next = CalculatePPQDifPrevNextEvnt(midi,last,ppq)

print(dif_prev, dif_next)