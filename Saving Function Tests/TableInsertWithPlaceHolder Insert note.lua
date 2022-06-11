dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()

local start = reaper.time_precise()
for take in enumSelectedMIDITakes() do
    local new_table = {}
    local retval, MIDIstr = reaper.MIDI_GetAllEvts( take )

    -- Create table
    local new_table = CreatePackedMIDITable(MIDIstr)



    --------------------------------DEMO INSERT after 1 element at every note. Slower to demonstrate TableInsertWithPlaceHolder with pos! Correct would be do that in the first iteration dont need to create a table! 
    -- But this is not very good just to demonstrate! 
--[[     local i = 1 -- which midi to get from the table
    while true do
        if new_table[i].msg ~= '' then -- If is not Place holders
            local type = UnpackMIDIMessage(new_table[i].msg)
            if type == 9 then 
                --Insert note at 960 1beat len
                local msg = PackMIDIMessage(11,1,21,127) -- CC 21
                local flags =  PackFlags(true,false)

                local new_offset = 10 -- insert 960 ppq after new_table[1].offset_count
                TableInsertWithPlaceHolder(new_table,new_offset,nil,new_offset,msg,flags,i+1)
                i = i + 2 -- Jump next i (this message and place holder) 

            end
        end
        i = i + 1
        if #new_table < i then break end 
    end ]]
    -------------------------------
    


    --------------------------------DEMO INSERT NOTE AT THE END OF THE TABLE GIVING THE desired ppq_position. This is way faster inserting at the end of the table with offsets

    -- Create the note
    local msg = PackMIDIMessage(9,1,60,127) -- Note on
    local flags =  PackFlags(true,false)

    --Insert note at 960 1beat len
    local ppq_position = 960
    InsertMIDIUnsorted(new_table,ppq_position,msg,flags)

    local msg_off = PackMIDIMessage(8,1,60,0) -- note off
    local ppq_position = 960+960
    InsertMIDIUnsorted(new_table,ppq_position,msg_off,flags)

    -------------------------------

    local new_MIDIstr = PackPackedMIDITable(new_table)
    reaper.MIDI_SetAllEvts(take, new_MIDIstr)
    reaper.MIDI_Sort(take) --- NEED TO SORT!

end
print(reaper.time_precise() - start)

reaper.UpdateArrange()

print('----------------')
print('-------END------')
print('----------------')


reaper.Undo_EndBlock2(0, 'script test', -1)