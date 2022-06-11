--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()



--local cnt = 0
local packing = 0
local inserting = 0
local unpacking = 0
local snapping = 0

local start = reaper.time_precise()
local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumSelectedMIDITakes(midi_editor, true) do
    local new_table = {}
    local note_on = {} -- midi_table store note ons delta ppq. [pitch] = delta

    local tTimeFromTick, tTickFromTime  = CreateTickTable()
    local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )
    for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(MIDIstr) do
        --Unpack MIDI
        local msg_type = msg:byte(1)>>4 -- look UnpackMIDIMessage
        local val1 = msg:byte(2) -- look UnpackMIDIMessage

        if msg_type == 9 then
            -- get closest grid
            local offset_count_time = tTimeFromTick[take][offset_count] -- convert note start to seconds
            local closest_grid = reaper.SnapToGrid(0, offset_count_time) -- get closest grid (this function relies on visible grid)
            local new_ppq = math.floor(tTickFromTime[take][closest_grid]) -- convert closest grid to PPQ
            -- calculate delta
            local delta = new_ppq - offset_count
            local new_offset = offset + delta 
            note_on[val1] = delta
            TableInsertWithPlaceHolder(new_table,new_offset,nil,delta,msg,flags,nil)
        elseif msg_type == 8 and note_on[val1] then
            local delta = note_on[val1]
            note_on[val1] = nil
            local new_offset = offset + delta

            TableInsertWithPlaceHolder(new_table,new_offset,nil,delta,msg,flags,nil)
        else
            new_table[#new_table+1] = {offset = offset ,msg = msg, flags = flags} -- new_offset = offset + delta. new  difference from last midi message
        end 
    end

    local new_MIDIstr = PackPackedMIDITable(new_table)
    reaper.MIDI_SetAllEvts(take, new_MIDIstr)
end
print(reaper.time_precise() - start)

reaper.UpdateArrange()


print('unpacking    '..unpacking)
print('inserting    '..inserting)
print('packing      '..packing)
print('snapping      '..snapping)
print('----------------')
print('-------END------')
print('----------------')


reaper.Undo_EndBlock2(0, 'script test', -1)


--- or 



--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()

local start = reaper.time_precise()
local midi_editor  = reaper.MIDIEditor_GetActive()
for take in enumSelectedMIDITakes(midi_editor, true) do
    local new_table = {}
    local note_on = {} -- midi_table store note ons delta ppq. [pitch] = delta

    local tTimeFromTick, tTickFromTime  = CreateTickTable()
    local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )
    for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(MIDIstr) do
        --Unpack MIDI
        local msg_type = msg:byte(1)>>4 -- look UnpackMIDIMessage
        local val1 = msg:byte(2) -- look UnpackMIDIMessage

        if msg_type == 9 then
            -- get closest grid
            local offset_count_time = tTimeFromTick[take][offset_count] -- convert note start to seconds
            local closest_grid = reaper.SnapToGrid(0, offset_count_time) -- get closest grid (this function relies on visible grid)
            local new_ppq = math.floor(tTickFromTime[take][closest_grid]) -- convert closest grid to PPQ
            -- calculate delta
            local delta = new_ppq - offset_count
            note_on[val1] = delta
            -- Insert MIDI at new_ppq
            SetMIDIUnsorted(new_table,new_ppq,offset_count,msg,flags)
            --InsertMIDIUnsorted(new_table,new_ppq,msg,flags)
        elseif msg_type == 8 and note_on[val1] then
            local delta = note_on[val1]
            note_on[val1] = nil
            local new_offset_count = offset_count + delta

            SetMIDIUnsorted(new_table,new_offset_count,offset_count,msg,flags)
        else
            new_table[#new_table+1] = {offset = offset ,msg = msg, flags = flags,  offset_count = offset_count} -- new_offset = offset + delta. new  difference from last midi message
        end 
    end

    local new_MIDIstr = PackPackedMIDITable(new_table)
    reaper.MIDI_SetAllEvts(take, new_MIDIstr)
    reaper.MIDI_Sort(take)

end
print(reaper.time_precise() - start)

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, 'script test', -1)