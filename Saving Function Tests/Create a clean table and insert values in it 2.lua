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
    local cnt = 0
    local new_midi_table = {}
    for i = 1, #midi_table  do
        if midi_table[i].flags.selected and midi_table[i].msg.val1 ~= 123 then
            InsertMIDI(new_midi_table,960*cnt,midi_table[i].msg,midi_table[i].flags)
            cnt = cnt + 1 
        else 
            InsertMIDI(new_midi_table,midi_table[i].offset_count,midi_table[i].msg,midi_table[i].flags)
        end

    end
    local midi_packed = PackMIDITable(new_midi_table)
    reaper.MIDI_SetAllEvts(take, midi_packed)
end


print(reaper.time_precise() - start)
print('----------------')
print('-------END------')
print('----------------')
