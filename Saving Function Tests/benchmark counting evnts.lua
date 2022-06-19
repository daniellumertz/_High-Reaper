------ Native functions are way faster! Even in long items

--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()

function m1() --0.03
    local cnt = 0

    for take in enumSelectedMIDITakes() do
        local new_table = {}

        local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )
        for offset, offset_count, flags, msg, stringPos in IterateMIDI(MIDIstr,9) do
            cnt = cnt + 1
        end
    end

    print(cnt)
end

function m2() --0.01
    local cnt = 0

    for take in enumSelectedMIDITakes() do
        local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
        cnt = cnt + notecnt
    end

    print(cnt)
end

function m1sel() --0.3
    local cnt = 0

    for take in enumSelectedMIDITakes() do
        local new_table = {}

        local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )
        for offset, offset_count, flags, msg, stringPos in IterateMIDI(MIDIstr,9,nil,true) do
            cnt = cnt + 1
        end
    end

    print(cnt)
end

function m2sel() --0.2
    local cnt = 0

    for take in enumSelectedMIDITakes() do
        local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
        for i = 0, notecnt - 1 do 
            retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
            if selected then
                cnt = cnt + 1
            end
        end
    end

    print(cnt)
end
------------ START

local start = reaper.time_precise()

m2sel()
print(reaper.time_precise() - start)

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, 'script test', -1)
