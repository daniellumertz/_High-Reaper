--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')

local midi_editor  = reaper.MIDIEditor_GetActive()

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

---comment
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param miditype table Filter messages MIDI by message type. Table with multiple types or just a number. (Midi type values are defined in the firt 4 bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; Something = 15. 
---@param ch table Filter messages MIDI by chnnale. Table with multiple channel or just a number.
---@param selected boolean Filter messages MIDI if they are selected in MIDI editor. true = only selected; false = only not selected; nil = either. 
---@param muted boolean Filter messages MIDI if they are muted in MIDI editor. true = only muted; false = only not muted; nil = either. 
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@param start any
---@param backwards any
---@param step any
---@return function
function IterateMIDI(MIDIstring,miditype,ch,selected,muted,filter_midiend,start,backwards,step) -- Should it iterate the last midi 123 ? it just say when the item ends 
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    local iteration_stringPos = 1
    return function ()
        while iteration_stringPos < MIDIlen do 
            local offset, flags, ms, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            
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

            if true then -- hm I cant just put return in the middle of a function. But I decided to use goto as lua dont have continue. and if it is here it is allright. so if true then return end  
                return  offset, flags, ms, stringPos
            end

            ::continue::
        end 
        return nil -- Ends the iteration
    end    
end


for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    for offset, flags, ms, stringPos in IterateMIDI(MIDIstring,nil,{4,2,1},nil,nil,true) do
        print('offset    :   '..offset)
        print('flags    :   '..flags)
        print('    ')
    end
end
print('----------------')
print('----------------')
print('----------------')
print('----------------')