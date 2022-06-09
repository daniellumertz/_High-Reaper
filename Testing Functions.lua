--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')


local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    reaper.MIDI_DisableSort( take )
    local retval, MIDIstring = reaper.MIDI_GetAllEvts(take, "")

    local midi_table = CreateMIDITable(MIDIstring)
    for i = 1, 10 do
        local msg =  PackMIDIMessage(9,i,60+i,127) -- type ch data1 data2
        InsertMIDI(midi_table,i*960,msg,1)

    
        local msg = PackMIDIMessage(8,i,60+i,127)
        InsertMIDI(midi_table,(i+1)*960,msg,1)
    end
    local str = PackMIDITable(midi_table)
    print(0)
    reaper.MIDI_SetAllEvts(take, str)
    --reaper.MIDI_Sort(take)
end

print('----------------')
print('-------END------')
print('----------------')
