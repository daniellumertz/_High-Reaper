--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')

local start = reaper.time_precise()
local tTimeFromTick, tTickFromTime = CreateTickTable()

--local cnt = 0

local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstr = reaper.MIDI_GetAllEvts(take)
    local midi_table = CreateMIDITable(MIDIstr)
    local new_midi_table = {}
--[[     for i = 1, #midi_table  do
        if (midi_table[i].msg.type == 9 or midi_table[i].msg.type == 8) then
            local new_ppq = SnapToGridPPQ(take,midi_table[i].offset_count)
            InsertMIDI(new_midi_table,new_ppq,midi_table[i].msg,midi_table[i].flags)
        else 
            InsertMIDI(new_midi_table,midi_table[i].offset_count,midi_table[i].msg,midi_table[i].flags)
        end

    end ]]
    local midi_packed = PackMIDITable(midi_table)
    reaper.MIDI_SetAllEvts(take, midi_packed)
end


print(reaper.time_precise() - start)
print('----------------')
print('-------END------')
print('----------------')
