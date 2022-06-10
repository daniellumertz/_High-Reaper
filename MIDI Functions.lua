---------------------
----------------- Iterate
---------------------

---Iterate this function it will return the takes open in midi_editor window. editable_only == get only the editables 
---@param midi_editor midi_editor midi_editor window
---@param editable_only boolean If true get only takes that are editable in midi_editor 
---@return function iterate takes
function enumMIDITakes(midi_editor, editable_only)
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
function IterateAllMIDI(MIDIstring,filter_midiend)
    -- Should it iterate the last midi 123 ? it just say when the item ends 
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    local iteration_stringPos = 1
    local offset_count = 0

    return function ()
        if iteration_stringPos < MIDIlen then 
            local offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            offset_count = offset + offset_count

            return  offset, offset_count, flags, msg, stringPos
        else -- Ends the iteration
            return nil 
        end 
    end    
end

---Iterate the MIDI messages inside the string out of  reaper.MIDI_GetAllEvts. Returns offset, flags, msg, offset_count, stringPos. offset is offset from last midi event. flags is midi message reaper option like muted, selected.... msg is the midi message. offset_count is the offset in ppq from the start of the iteration (the start of the MIDI item or at start.stringPos(start.ppq and start.event_n dont affect this count)). event_count is the event nº between all MIDI events. stringPos the position in the string for the next event. 
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param miditype table Filter messages MIDI by message type. Table with multiple types or just a number. (Midi type values are defined in the firt 4 bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15. 
---@param ch table Filter messages MIDI by chnnale. Table with multiple channel or just a number.
---@param selected boolean Filter messages MIDI if they are selected in MIDI editor. true = only selected; false = only not selected; nil = either. 
---@param muted boolean Filter messages MIDI if they are muted in MIDI editor. true = only muted; false = only not muted; nil = either. 
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@param start table start is a table that determine where to start iterating in the midi evnts. The key determine the options: 'ppq','event_n','stringPos' the value determine the value to start. For exemple {ppq=960} will start at events that happen at and after 960 midi ticks after the start of the item. {event_n=5} will start at the fifth midi message (just count messages that pass the filters). {stringPos = 13} will start at the midi message in the 13 byte on the packed string.
---@param step number will only return every number of step midi message (will only count messages that passes the filters). 
---@return function -- offset, offset_count, flags, msg, event_count, stringPos
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
            local offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos -- set iteration_stringPos for next iteration
            offset_count = offset_count + offset -- this returns the distance in ppq from each message from the start of the midi item or the first stringPos used
            event_count = event_count +1

            -- Start ppq filters: 
            if start and start.ppq and offset_count < start.ppq   then -- events earlier than start.ppq
                goto continue
            end
            
            -- check midi type .
            if miditype then 
                local msg_type = msg:byte(1)>>4 -- moves last 4 bit into void. Rest only the first 4 bits that define midi type
                if type(miditype) == "table" then -- if miditype is a table with all types to get
                    if not TableHaveValue(miditype, msg_type) then goto continue end 
                else -- if is just a value
                    if not (msg_type == miditype) then goto continue end 
                end
            end
            
            -- check channel.
            if ch then  
                local msg_ch = msg:byte(1)&0x0F -- 0x0F = 0000 1111 in binary . msg is string. & is an and bitwise operation "have to have 1 in both to be 1". Will return channel as a decimal number. 0 based
                msg_ch = msg_ch + 1 -- makes it 1 based
                if type(ch) == "table" then -- if ch is a table with all ch to get
                    if not TableHaveValue(ch, msg_ch) then goto continue end 
                else -- if is just a value
                    if not (msg_ch == ch) then goto continue end 
                end
            end

            local msg_sel, msg_mute, msg_curve_shape
            if (selected ~= nil) or (muted ~= nil) or (msg_curve_shape ~= nil) then -- Only unpack if gonna use, and do it only once!
                msg_sel, msg_mute, msg_curve_shape = UnpackFlags(flags)
            end
            
            -- check selected
            if selected ~= nil and not (msg_sel == selected) then
                goto continue
            end

            -- check muted
            if muted ~= nil and not (msg_mute == muted) then
                goto continue
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
                return  offset, offset_count, flags, msg, event_count, stringPos
            end

            ::continue::
        end 
        return nil -- Ends the iteration
    end    
end

function IterateMIDIBackwards(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step)
    local t = {}
    for offset, offset_count, flags, msg, event_count, stringPos in IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step) do
        t[#t+1] = {}
        t[#t].offset = offset
        t[#t].flags = flags
        t[#t].msg = msg
        t[#t].offset_count = offset_count
        t[#t].event_count = event_count
        t[#t].stringPos = stringPos
    end
    local i = #t+1
    return function ()
        i = i - 1
        if i == 0 then return nil end
        return t[i].offset,t[i].offset_count,t[i].flags,t[i].msg,t[i].event_count,t[i].stringPos
    end
end

---------------------
----------------- MIDI Table 
---------------------

-- Receives MIDIstring and returns a table user use to insert, set, delete, modify events. 
-- Table structure:
-- .offset = offset from last event (dont try to change this directly! use insert, delete, set). When packing to set all events it will use this info to build the output MIDI
-- .offset_Count = offset from item start (dont try to change this directly! use insert, delete, set). Just for reference and using in insert midi, wont be used to build the outputed MIDI.
-- .flags = table with flags options unpacked 
    -- flags.selected is selected
    -- flags.muted is muted
    -- flags.curve_shape which curve shape  0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
-- .msg = table with midi message unpacked 
    -- msg.type = midi message type 
    -- msg.ch = midi message channel
    -- msg.val1 = midi message databyte 1
    -- msg.val2 = midi message databyte 2
    -- msg.text = midi text
-- .stringPos
---@param MIDIstring any
---@return table
function CreateMIDITable(MIDIstring)
    local t = { }
    for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(MIDIstring,false) do -- should I remove the last val? NO! User should avoid it. If remove when I pack back it would be missing, unless I always add the message there
        local type, ch, val1, val2, text = UnpackMIDIMessage(msg)
        local selected, muted, curve_shape = UnpackFlags(flags)
        t[#t+1] = {}
        t[#t].offset = offset 
        t[#t].offset_count = offset_count -- 
        t[#t].flags = {
            selected = selected,
            muted = muted,
            curve_shape = curve_shape
        }
        t[#t].msg = {
            type = type,
            ch = ch,
            val1 = val1,
            val2 = val2,
            text = text
        }
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
        local packed_midi = PackMIDIMessage(midi_table[i].msg.type, midi_table[i].msg.ch, midi_table[i].msg.val1, midi_table[i].msg.val2,midi_table[i].msg.text) -- Pack MIDI not text
        local packed_flags = PackFlags(midi_table[i].flags.selected, midi_table[i].flags.muted, midi_table[i].flags.curve_shape)
        packed_table[#packed_table+1] = string.pack("i4Bs4", midi_table[i].offset, packed_flags, packed_midi) 
    end
    return table.concat(packed_table) -- I didnt remove the last val at CreateMIDITable so everything should be here! If remove add it here, calculating offset.
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

---Calculate the ppq diference from ppq and midi_table[last_idx] and midi_table[last_idx+1] 
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

---------------------
----------------- MIDI Table Handling 
---------------------

---Insert a midi midi_msg at ppq in the midi_table
---@param midi_table table table with all midi events
---@param pqp number when in ppq insert the message
---@param midi_msg string midi message packed. 
function InsertMIDI(midi_table,ppq,midi_msg,flags)
    --Get idx of prev event
    local last_idx, dif_prev, dif_next
    if #midi_table > 0 then
        last_idx = BinarySearchInMidiTable(midi_table,ppq)
        -- calculate dif of prev event and next evt 
        dif_prev, dif_next = CalculatePPQDifPrevNextEvnt(midi_table,last_idx,ppq)
    else
        dif_prev, dif_next = ppq, 0
        last_idx = 0
    end
    local insert_idx = last_idx + 1

    --create the midi midi_msg table
    if type(midi_msg) == 'string' then -- If put midi msg packed. but please dont! 
        local midi_type, ch, val1, val2, text = UnpackMIDIMessage(midi_msg)
        midi_msg = {
            type = midi_type,
            ch = ch,
            val1 = val1,
            val2 = val2,
            text = text
        }
    end
    --create the midi midi_msg table
    if type(flags) == 'number' then -- If put flag packed. but please dont! 
        local selected, muted, curve_shape = UnpackFlags(flags)
        flags = {
            selected = selected,
            muted = muted,
            curve_shape = curve_shape
        }
    end

    --create the msg table
    local msg_table = {
        offset = dif_prev,
        offset_count = ppq,
        flags = table_copy_regressive(flags),
        msg  = table_copy_regressive(midi_msg)
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
    if midi_table[event_n+1] then
        midi_table[event_n+1].offset = midi_table[event_n].offset + midi_table[event_n+1].offset 
    end
    table.remove(midi_table,event_n)
end

function SetMIDI(midi_table,event_n,ppq,flags,midi_msg)
    if flags then
        for key, value in pairs(flags) do
            midi_table[event_n].flags[key] = value
        end
    end
    if midi_msg then
        for key, value in pairs(midi_msg) do
            midi_table[event_n].msg[key] = value
        end
    end

    if ppq then
        local midi_msg = table_copy_regressive(midi_table[event_n].msg)
        local flags = table_copy_regressive(midi_table[event_n].flags)
        DeleteMIDI(midi_table,event_n)
        InsertMIDI(midi_table,ppq,midi_msg,flags)
    end
end

---------------------
----------------- MIDI Message Pack 
---------------------

---Unpack a packed string MIDI message in different values
---@param msg string midi as packed string
---@return number msg_type midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15. 
---@return number msg_ch midi message channel
---@return number data2 databyte1 -- like note pitch, cc num
---@return number data3 databyte2 -- like note velocity, cc val. Some midi messages dont have databyte2 and this will return nill. For getting the value of the pitchbend do databyte1 + databyte2
---@return string text if message is a text return the text
---@return table allbytes all bytes in a table in order, starting with statusbyte. usefull for longer midi messages like text
function UnpackMIDIMessage(msg)
    local msg_len = msg:len()
    local pattern = string.rep('B',msg_len)
    local t = {string.unpack(pattern,msg)}
    table.remove(t) -- remove last element (it is just concerned with the last character in string.unpack)

    local msg_type = msg:byte(1)>>4
    local msg_ch = (msg:byte(1)&0x0F)+1 --msg:byte(1)&0x0F -- 0x0F = 0000 1111 in binary. this is a bitmask. +1 to be 1 based

    local text
    if msg_type == 15 then
        text = msg:sub(3)
    end

    local val1 = t[2]
    local val2 = (msg_type ~= 15) and t[3] -- return nil if is text
    return msg_type,msg_ch,val1,val2,text,t
end

---Receives numbers(0-255). or strings. and return them in a string as bytes
---@param ... number
---@return string
function PackMessage(...)
    local t = {...}
    local msg = ''
    for i, v in ipairs( { ... } ) do
        local new_val
        if type(v) == 'number' then 
            new_val = string.pack('B',v)
        elseif type(v) == 'string' then -- In case it is a string (useful for midi text where each byte is a character)
            new_val = v
        elseif not v then -- in case some of the messages is nil. No problem! This is useful as PackMIDITable will send .val2 and .text. not all midi have val2 and not all midi have .text
            new_val = ''
        end
        msg = msg..new_val
    end
    return msg
end

---Pack a midi message in a string form. Each character is a midi byte. Can receive as many data bytes needed. Just join midi_type and midi_ch in the status bytes and thow it in PackMessage. 
---@param midi_type number midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
---@param midi_ch number midi ch 1-16 (1 based.)
---@param ... number sequence of data bytes can be number (will be converted to string(a character with the equivalent byte)) or can be a string that will be added to the message (useful for midi text where each byte is a character).
function PackMIDIMessage(midi_type,midi_ch,...)
    local midi_ch = midi_ch - 1 -- make it 0 based
    local status_byte = (midi_type*16)+midi_ch -- where is your bitwise operation god now?
    return PackMessage(status_byte,...)
end

---Unpack flags into selected, muted, curve_shape
---@param flag number
---@return boolean selected is selected
---@return boolean muted is muted
---@return integer curve_shape curve type 0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
function UnpackFlags(flag)
    local selected =  flag&1 == 1   -- AND operation with  1 (1 in binary) (return the first bit val)
    local muted =  flag&2 == 2      -- AND operation with 10 (2 in binary) (return the second bit val + 1 bit as 0 I could also move it to the void)
    -- cc_string
    local curve_shape = flag>>4 -- Void the first 4 bits as they dont matter for cc curve and get the value. If is flags from something without curve shape like notes will just return 0, as square
        
    return selected, muted, curve_shape
end

---Pack options into flags
---@param selected boolean is selected
---@param muted boolean is muted
---@param curve_shape number curve type 0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
---@return integer flags flags number
function PackFlags(selected, muted, curve_shape)
    local flags = curve_shape<<4
    flags = flags|(muted and 2 or 0)|(selected and 1 or 0) -- if selected or muted are true return number. this is a OR operation flags|2or0|1or0 (2 = 10 ; 1 = 1)
    return flags
end


---------------------
----------------- MIDI Ticks Table
---------------------

-- From JS

function CreateTickTable()
    -- After creating use like print(tTimeFromTick[take][960]) if it dont already have the value it will create and return. 
    local tTimeFromTick = {} 
    local tTickFromTime = {}
    setmetatable(tTimeFromTick, {__index = function(t, take) t[take] = setmetatable({}, {__index = function(tt, tick) 
                                                                                                    local time = reaper.MIDI_GetProjTimeFromPPQPos(take, tick + 0) -- TODO Make it work with Start in source (Start offset) Originally this 0 did the trick
                                                                                                    tt[tick] = time
                                                                                                    tTickFromTime[take][time] = tick
                                                                                                    return time 
                                                                                                end
                                                                                        }) return t[take] end})
                                                                                        
    setmetatable(tTickFromTime, {__index = function(t, take) t[take] = setmetatable({}, {__index = function(tt, time) 
                                                                                                    local tick = reaper.MIDI_GetPPQPosFromProjTime(take, time) - 0 -- TODO Make it work with Start in source (Start offset) Originally this 0 did the trick
                                                                                                    tt[time] = tick
                                                                                                    tTimeFromTick[take][tick] = time
                                                                                                    return tick 
                                                                                                end
                                                                                        }) return t[take] end})

    return tTimeFromTick, tTickFromTime -- Return related to project time
end
