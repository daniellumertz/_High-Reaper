--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')

start = reaper.time_precise()

local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstr = reaper.MIDI_GetAllEvts(take)
    local midi_table = CreateMIDITable(MIDIstr)
    for offset, offset_count, flags, msg, event_count, stringPos in IterateMIDI(MIDIstr,9,ch_,selected_,muted_,true) do
        local selected, muted, curve_shape = UnpackFlags(flags, true)
        print('muted    '..tostring(muted))
        local flags2 = PackFlags(selected, muted, curve_shape)
        print(flags == flags2 )
    end
    --local midi_packed = PackMIDITable(midi_table)
    --reaper.MIDI_SetAllEvts(take, midi_packed)
end



print(reaper.time_precise() - start)
print('----------------')
print('-------END------')
print('----------------')
