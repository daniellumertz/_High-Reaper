--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')


local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    for offset, flags, ms, offset_count, stringPos in IterateMIDI(MIDIstring,{8,9},{1,3},true,false,true,{ppq = 420}) do -- Get all notes on and off on channel 1 and 3 if they are selected not muted and after ppq 420. Filter last midi CC123 event (would filter anyway as I am getting just notes on/off).  
        print('MIDI NOTE :  '..ms:byte(2))
        print('ppq from item start :  '..offset_count)
    end
end

print('----------------')
print('-------END------')
print('----------------')
