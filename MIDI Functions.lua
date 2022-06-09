---Iterate this function it will return the takes open in midi_editor window. editable_only == get only the editables 
---@param midi_editor midi_editor midi_editor window
---@param editable_only boolean If true get only takes that are editable in midi_editor 
---@return function iterate takes
function enumMIDITakes(midi_editor, editable_only) -- Thanks CF
    local i = -1
    return function()
        i = i + 1
        return reaper.MIDIEditor_EnumTakes(midi_editor, i, editable_only)
    end
end

--- This is the simple version that haves no filter besides the last event. Easy to understand and if you want to check the difference in performance with my IterateMIDI function. Or if you want to filter yourself. 
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@return function
function IterateAllMIDI(MIDIstring,filter_midiend) -- Should it iterate the last midi 123 ? it just say when the item ends 
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    local iteration_stringPos = 1
    local offset_count = 0

    return function ()
        if iteration_stringPos < MIDIlen then 
            local offset, flags, ms, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            offset_count = offset + offset_count

            return  offset, offset_count, flags, ms, stringPos
        else -- Ends the iteration
            return nil 
        end 
    end    
end

---Iterate the MIDI messages inside the string out of  reaper.MIDI_GetAllEvts. Returns offset, flags, ms, offset_count, stringPos. offset is offset from last midi event. flags is midi message reaper option like muted, selected.... ms is the midi message. offset_count is the offset in ppq from the start of the iteration (the start of the MIDI item or at start.stringPos(start.ppq and start.event_n dont affect this count)). event_count is the event nº between all MIDI events. stringPos the position in the string for the next event. 
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param miditype table Filter messages MIDI by message type. Table with multiple types or just a number. (Midi type values are defined in the firt 4 bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15. 
---@param ch table Filter messages MIDI by chnnale. Table with multiple channel or just a number.
---@param selected boolean Filter messages MIDI if they are selected in MIDI editor. true = only selected; false = only not selected; nil = either. 
---@param muted boolean Filter messages MIDI if they are muted in MIDI editor. true = only muted; false = only not muted; nil = either. 
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@param start table start is a table that determine where to start iterating in the midi evnts. The key determine the options: 'ppq','event_n','stringPos' the value determine the value to start. For exemple {ppq=960} will start at events that happen at and after 960 midi ticks after the start of the item. {event_n=5} will start at the fifth midi message (just count messages that pass the filters). {stringPos = 13} will start at the midi message in the 13 byte on the packed string.
---@param step number will only return every number of step midi message (will only count messages that passes the filters). 
---@return function -- offset, offset_count, flags, ms, event_count, stringPos
function IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step)
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    -- start filter settings
    local iteration_stringPos = start and start.stringPos or 1 -- the same as if start and start.stringPos then iteration_stringPos = start.stringPos else iteration_stringPos = 1 end
    local event_n = 0 -- if start.event_n will count every message that passes all filters and will only start returning at event start.event_n
    local event_count = 0 -- event count will return the event count nº between all midi events
    local offset_count = 0
    ----
    local step_count = -1 -- only for using step
    return function ()
        while iteration_stringPos < MIDIlen do 
            local offset, flags, ms, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos -- set iteration_stringPos for next iteration
            offset_count = offset_count + offset -- this returns the distance in ppq from each message from the start of the midi item or the first stringPos used
            event_count = event_count +1

            -- Start ppq filters: 
            if start and start.ppq and offset_count < start.ppq   then -- events earlier than start.ppq
                goto continue
            end
            
            -- check midi type .
            if miditype then 
                local msg_type = ms:byte(1)>>4 -- moves last 4 bit into void. Rest only the first 4 bits that define midi type
                if type(miditype) == "table" then -- if miditype is a table with all types to get
                    if not TableHaveValue(miditype, msg_type) then goto continue end 
                else -- if is just a value
                    if not (msg_type == miditype) then goto continue end 
                end
            end
            
            -- check channel.
            if ch then  
                local msg_ch = ms:byte(1)&0x0F -- 0x0F = 0000 1111 in binary . ms is string. & is an and bitwise operation "have to have 1 in both to be 1". Will return channel as a decimal number. 0 based
                msg_ch = msg_ch + 1 -- makes it 1 based
                if type(ch) == "table" then -- if ch is a table with all ch to get
                    if not TableHaveValue(ch, msg_ch) then goto continue end 
                else -- if is just a value
                    if not (msg_ch == ch) then goto continue end 
                end
            end

            -- check selected
            if selected ~= nil then
                local msg_sel = tonumber(ToBits(flags):sub(1,1)) == 1 -- ToBits(flags) return flags as a binary number. Each option is a number from left to right: selected, mute. EX: selected not muted = 10 selected and muted = 11. :sub(1,1) get only one of those values.tonumber() == 1 transforms in boolean.  
                if not (msg_sel == selected) then goto continue end
            end

            -- check muted
            if muted ~= nil then
                local msg_mute = tonumber(ToBits(flags):sub(2,2)) == 1 -- ToBits(flags) return flags as a binary number. Each option is a number from left to right: selected, mute. EX: selected not muted = 10 selected and muted = 11. :sub(1,1) get only one of those values.tonumber() == 1 transforms in boolean.  
                if not (msg_mute == muted) then goto continue end
            end

            -- Start event n filter: --- it is at the end so will only count message that passed all other filters
            if start and start.event_n then 
                event_n = event_n + 1
                if event_n < start.event_n then goto continue end -- if the event_n count is smaller than the desired event to start returning just continue to next
            end

            -- Step filter
            if step then 
                step_count = step_count + 1                
                if step_count%step ~= 0 then goto continue end 
            end

            -- Passed All filters congrats!

            if true then -- hm I cant just put return in the middle of a function. But I decided to use goto as lua dont have continue. and if it is here it is allright. so if true then return end 
                return  offset, offset_count, flags, ms, event_count, stringPos
            end

            ::continue::
        end 
        return nil -- Ends the iteration
    end    
end

function IterateMIDIBackwards(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step)
    local t = {}
    for offset, offset_count, flags, ms, event_count, stringPos in IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step) do
        t[#t+1] = {}
        t[#t].offset = offset
        t[#t].flags = flags
        t[#t].ms = ms
        t[#t].offset_count = offset_count
        t[#t].event_count = event_count
        t[#t].stringPos = stringPos
    end
    local i = #t+1
    return function ()
        i = i - 1
        if i == 0 then return nil end
        return t[i].offset,t[i].offset_count,t[i].flags,t[i].ms,t[i].event_count,t[i].stringPos
    end
end

---Receives MIDIstring and returns a table user use to insert, set, delete, modify events. Each key is corresponds to a midi message they are in a table with .offset .offset_Count . flags . ms. After done pack each message and concat the table and MIDI_SetAllEvts. 
---@param MIDIstring any
---@return table
function CreateMIDITable(MIDIstring)
    local t = { }
    for offset, offset_count, flags, ms, stringPos in IterateAllMIDI(MIDIstring,false) do -- should I remove the last val?
        t[#t+1] = {}
        t[#t].offset = offset
        t[#t].offset_count = offset_count
        t[#t].flags = flags
        t[#t].ms = ms
        t[#t].stringPos = stringPos -- just for the sake of it (probably wont going to use)
    end
    return t
end

---This function get the midi_table and return it to string packed formated to be feeded at MIDI_SetAllEvts
---@param midi_table any
---@return string
function PackMIDITable(midi_table)
    local packed_table = {}
    for i, value in pairs(midi_table) do
        packed_table[#packed_table+1] = string.pack("i4Bs4", midi_table[i].offset, midi_table[i].flags, midi_table[i].ms) 
    end
    return table.concat(packed_table) -- I didnt remove the last val at CreateMIDITable so everything should be here! If remove add it here, calculating offset.
end

---Unpack a packed string MIDI message in different values
---@param ms string midi as packed string
---@return number msg_type midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15. 
---@return number msg_ch midi message channel
---@return number data2 databyte1 -- like note pitch, cc num
---@return number data3 databyte2 -- like note velocity, cc val. Some midi messages dont have databyte2 and this will return nill. For getting the value of the pitchbend do databyte1 + databyte2
---@return table allbytes all bytes in a table in order, starting with statusbyte. usefull for longer midi messages like text
function UnpackMIDIMessage(ms)
    local ms_len = ms:len()
    local pattern = string.rep('B',ms_len)
    local t = {string.unpack(pattern,ms)}
    table.remove(t) -- remove last element (it is just concerned with the last character in string.unpack)

    local msg_type = ms:byte(1)>>4
    local msg_ch = (ms:byte(1)&0x0F)+1 --ms:byte(1)&0x0F -- 0x0F = 0000 1111 in binary. this is a bitmask. +1 to be 1 based

    return msg_type,msg_ch,t[2],t[3],t
end

---Receives numbers(0-255) and return them in a string as bytes
---@param ... number
---@return string
function PackMessage(...)
    local t = {...}
    local ms = ''
    for i, v in ipairs( { ... } ) do
       local new_val = string.pack('B',v)
      ms = ms..new_val
    end
    return ms
end

---Pack a midi message in a string form. Each character is a midi byte. Can receive as many data bytes needed. Just join midi_type and midi_ch in the status bytes and thow it in PackMessage. 
---@param midi_type number midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
---@param midi_ch number midi ch 1-16 (1 based.)
---@param ... number sequence of data bytes 
function PackMIDIMessage(midi_type,midi_ch,...)
    local midi_ch = midi_ch - 1 -- make it 0 based
    local status_byte = (midi_type*16)+midi_ch -- where is your bitwise operation god now?
    return PackMessage(status_byte,...)
end


---Insert a midi msg at ppq in the midi_table
---@param midi_table table table with all midi events
---@param pqp number when in ppq insert the message
---@param msg string midi message packed. 
function InsertMIDI(midi_table,ppq,msg,flags)
    --Get idx of prev event
    local last_idx = BinarySearchInMidiTable(midi_table,ppq)
    local insert_idx = last_idx + 1
    -- calculate dif of prev event and next evt 
    local dif_prev, dif_next = CalculatePPQDifPrevNextEvnt(midi_table,last_idx,ppq)
    --create the midi msg table
    local msg_table = {
        offset = dif_prev,
        offset_count = ppq,
        flags = flags,
        ms  = msg
    }
    --adjust next midi message offset
    if midi_table[last_idx+1] then
        midi_table[last_idx+1].offset = dif_next
    end
    --insert it 
    table.insert(midi_table,insert_idx,msg_table) -- dont need to return as it is using the same table 
end

---comment
---@param midi_table  table table with all midi events
---@param event_n number event number
function DeleteMIDI(midi_table,event_n)
    local dif_prev, dif_next = CalculatePPQDifPrevNextEvnt(midi_table,event_n - 1 , event_n.offset_count)
    if midi_table[event_n+1] then
        midi_table[event_n+1].offset = dif_prev + dif_next
    end
    table.remove(midi_table,event_n)
end

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
        if midi_table[i+1] and midi_table[i].offset_count <= ppq and ppq <= midi_table[i+1].offset_count then return i end -- check if it is in between two values

        -- change the i (this is not the correct answer)
        if midi_table[i].offset_count > ppq then
            ceil = i
            i = ((i - floor) / 2) + floor
            i = math.floor(i)
        elseif midi_table[i].offset_count < ppq then
            floor = i
            i = ((ceil - i) / 2) + floor
            i = math.ceil(i)
        end    
    end
end

---Calculate the ppq diference from ppq and midi_table[last_idx] and 
---@param midi_table table
---@param last_idx number
---@param ppq number
---@return number
---@return number
function CalculatePPQDifPrevNextEvnt(midi_table,last_idx,ppq)
    local dif_prev, dif_next
    if last_idx > 0 then -- calculate the difference of the previous message. check if there is a previous element
        dif_prev = ppq - midi_table[last_idx].offset_count -- alternative is to calculate using just offset of the next message - dif prev message. this way is faster
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