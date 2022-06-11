--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()

local start = reaper.time_precise()
local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumSelectedMIDITakes(midi_editor, true) do
    local new_table = {}
    local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )
    for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(MIDIstr) do
        --Unpack MIDI
        local msg_type = msg:byte(1)>>4 -- look UnpackMIDIMessage
        local val1 = msg:byte(2) -- look UnpackMIDIMessage

        if msg_type == 11 and val1 == 64 then
            InsertPlaceHolder(new_table,offset,offset_count)
        else
            new_table[#new_table+1] = {offset = offset ,msg = msg, flags = flags,  offset_count = offset_count} -- new_offset = offset + delta. new  difference from last midi message
        end 
    end

    local new_MIDIstr = PackPackedMIDITable(new_table)
    reaper.MIDI_SetAllEvts(take, new_MIDIstr)
    reaper.MIDI_Sort(take)

end
print(reaper.time_precise() - start)

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, 'script test', -1)