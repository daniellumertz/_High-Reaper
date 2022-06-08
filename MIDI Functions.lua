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
    return function ()
        if iteration_stringPos < MIDIlen then 
            local offset, flags, ms, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            return  offset, flags, ms, stringPos
        else -- Ends the iteration
            return nil 
        end 
    end    
end

---Iterate the MIDI messages inside the string out of  reaper.MIDI_GetAllEvts. Returns offset, flags, ms, offset_count, stringPos. offset is offset from last midi event. flags is midi message reaper option like muted, selected.... ms is the midi message. offset_count is the offset in ppq from the start of the iteration (the start of the MIDI item or at start.stringPos(start.ppq and start.event_n dont affect this count)).  stringPos the position in the string for the next event. 
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param miditype table Filter messages MIDI by message type. Table with multiple types or just a number. (Midi type values are defined in the firt 4 bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; Something = 15. 
---@param ch table Filter messages MIDI by chnnale. Table with multiple channel or just a number.
---@param selected boolean Filter messages MIDI if they are selected in MIDI editor. true = only selected; false = only not selected; nil = either. 
---@param muted boolean Filter messages MIDI if they are muted in MIDI editor. true = only muted; false = only not muted; nil = either. 
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@param start table start is a table that determine where to start iterating in the midi evnts. The key determine the options: 'ppq','event_n','stringPos' the value determine the value to start. For exemple {ppq=960} will start at events that happen at and after 960 midi ticks after the start of the item. {event_n=5} will start at the fifth midi message (just count messages that pass the filters). {stringPos = 13} will start at the midi message in the 13 byte on the packed string.
---@param step number will only return every number of step midi message (will only count messages that passes the filters). 
---@return function 
function IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step) -- Should it iterate the last midi 123 ? it just say when the item ends 
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    -- start filter settings
    local iteration_stringPos = start and start.stringPos or 1 -- the same as if start and start.stringPos then iteration_stringPos = start.stringPos else iteration_stringPos = 1 end
    local event_n = 0 -- if start.event_n will count every message that passes all filters and will only start returning at event start.event_n 
    local offset_count = 0
    ----
    local step_count = -1 -- only for using step
    return function ()
        while iteration_stringPos < MIDIlen do 
            local offset, flags, ms, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos -- set iteration_stringPos for next iteration
            offset_count = offset_count + offset -- this returns the distance in ppq from each message from the start of the midi item or the first stringPos used

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
                local msg_ch = ms:byte(1)&0x0F -- 0x0F = 0000 1111 in binary . ms is decimal. & is an and bitwise operation "have to have 1 in both to be 1". Will return channel as a decimal number. 0 based
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
                return  offset, flags, ms, offset_count, stringPos
            end

            ::continue::
        end 
        return nil -- Ends the iteration
    end    
end

function IterateMIDIBackwards(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step)
    local t = {}
    for offset, flags, ms, offset_count, stringPos in IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,step) do
        t[#t+1] = {}
        t[#t].offset = offset
        t[#t].flags = flags
        t[#t].ms = ms
        t[#t].offset_count = offset_count
        t[#t].stringPos = stringPos
    end
    local i = #t+1
    return function ()
        i = i - 1
        if i == 0 then return nil end
        return t[i].offset,t[i].flags,t[i].ms,t[i].offset_count,t[i].stringPos
    end
end
