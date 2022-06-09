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
    for i = 1, 10 do
        -- Create a MIDI Note ON message:
        local msg =  PackMIDIMessage(9,i,60+i,math.random(127)) -- note on, channel i, pitch 60+i, vel random 
        -- Insert it on the table at i*960 ppq
        InsertMIDI(midi_table,i*960,msg,1)

        -- Create a MIDI Note OFF message:
        local msg = PackMIDIMessage(8,i,60+i,127) -- note off, channel i, pitch 60+i, vel 127 
        -- Insert it on the table at i+1*960 ppq
        InsertMIDI(midi_table,(i+1)*960,msg,1)
    end
    --Pack the table for SetAllEvts
    local str = PackMIDITable(midi_table)
    reaper.MIDI_SetAllEvts(take, str)
end

print('----------------')
print('-------END------')
print('----------------')
