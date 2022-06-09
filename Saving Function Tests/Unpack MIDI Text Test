--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')

local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstring = reaper.MIDI_GetAllEvts(take, "")

    -- Create a midi table to modify the events.
    local midi_table = CreateMIDITable(MIDIstring)
    for i = #midi_table, 1, - 1 do
        -- Get text
        local midi = midi_table[i].msg
        local type, ch, v1,v2,text,all= UnpackMIDIMessage(midi)
        if type == 15 then
            print(text)
        end
    end
    --Pack the table for SetAllEvts
    local str = PackMIDITable(midi_table)
    reaper.MIDI_SetAllEvts(take, str)
end

print('----------------')
print('-------END------')
print('----------------')
