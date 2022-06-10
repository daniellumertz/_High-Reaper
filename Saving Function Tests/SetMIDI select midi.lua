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
    for i = 1, #midi_table do
        if not midi_table[i].flags.selected then
            SetMIDI(midi_table,i,nil,{selected = true},nil)
        end
    end
    local midi_packed = PackMIDITable(midi_table)
    reaper.MIDI_SetAllEvts(take, midi_packed)
end
--print(cnt)



print(reaper.time_precise() - start)
print('----------------')
print('-------END------')
print('----------------')
