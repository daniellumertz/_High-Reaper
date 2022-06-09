--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')


function PackMIDIMessage(...)
    local t = {...}
    local ms = ''
    local pattern = string.rep('B',#t)
    for i, v in ipairs( { ... } ) do
      string.pack('B',v)
      ms = ms..new_val
    end
    return ms
end

local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local retval, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    for offset, offset_count, flags, ms, event_count, stringPos in IterateMIDI(MIDIstring,15) do

        local t,ch,pitch,vel,all = UnpackMIDIMessage(ms)
        tprint(all)


    end
end

print('----------------')
print('-------END------')
print('----------------')
