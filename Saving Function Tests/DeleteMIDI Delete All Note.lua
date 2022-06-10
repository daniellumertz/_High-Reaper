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
    for i = #midi_table-1, 1, -1 do
        if midi_table[i] and (midi_table[i].msg.type == 9 or midi_table[i].msg.type == 8) then
            DeleteMIDI(midi_table,i)
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
