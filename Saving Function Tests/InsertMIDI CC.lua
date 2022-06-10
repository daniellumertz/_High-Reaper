--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')

start = reaper.time_precise()

--local cnt = 0

local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstr = reaper.MIDI_GetAllEvts(take)
    local midi_table = CreateMIDITable(MIDIstr)
    for i = 1, 1000000 do
        InsertMIDI(midi_table,150*i,{type = 11, ch = 1, val1 = 14, val2 = i%127 },{selected = false, muted = (i%2==1), curve_shape = 1})
    end

    print(0)
    local midi_packed = PackMIDITable(midi_table)
    reaper.MIDI_SetAllEvts(take, midi_packed)
end
--print(cnt)



print(reaper.time_precise() - start)
print('----------------')
print('-------END------')
print('----------------')
