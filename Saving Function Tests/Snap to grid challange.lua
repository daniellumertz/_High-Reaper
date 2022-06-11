--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

dofile(script_path..'General Lua Functions.lua')
dofile(script_path..'MIDI Functions.lua')
dofile(script_path..'Arrange Functions.lua')

reaper.Undo_BeginBlock()

local function QunatizeMethod1(take) --1.934sec
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
    reaper.MIDI_Sort(take)
end


local function QuantizeMethod2(take) -- 2.0 Little slower but looks a little nicer
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

local function QuantizeMethod3(take) -- Using SetNote. 6sec

    -- normal method

    local _, notes_count, _, _ = reaper.MIDI_CountEvts(take) -- count notes and save amount to notes_count

    reaper.MIDI_DisableSort(take) -- disabling sorting improves execution speed

    for n = 0, notes_count - 1 do -- loop through all notes
        local _, _, _, note_start_pos_ppq, note_end_pos_ppq, _, _, _ = reaper.MIDI_GetNote(take, n) -- get selection status and positions

        local note_start = reaper.MIDI_GetProjTimeFromPPQPos(take, note_start_pos_ppq) -- convert note start to seconds
        local closest_grid = reaper.SnapToGrid(0, note_start) -- get closest grid (this function relies on visible grid)
        local closest_grid_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, closest_grid) -- convert closest grid to PPQ

        if closest_grid_ppq ~= note_start_pos_ppq then -- if notes are not on the grid
            reaper.MIDI_SetNote(take, n, nil, nil, closest_grid_ppq, closest_grid_ppq+note_end_pos_ppq-note_start_pos_ppq, nil, nil, nil, nil) -- quantize all notes
        end
    end
    reaper.MIDI_Sort(take)
end

local function QuantizeMethod4(take) --Stevie method 1.9sec

    local item = reaper.GetMediaItemTake_Item(take)

    local table_notes = {} -- create table for seperating notes from the MIDI stream
	local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION") -- get start of item
    local item_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, item_start) -- convert item_start_ppq to PPQ
	
	local got_all_ok, midi_string = reaper.MIDI_GetAllEvts(take, "") -- write MIDI events to midi_string, get all events okay
	if not got_all_ok then reaper.ShowMessageBox("Error while loading MIDI", "Error", 0) return(false) end -- if getting the MIDI data failed
	
	local midi_len = #midi_string -- get string length
	
	local string_pos = 1 -- position in midi_string while parsing through events
	local sum_offset = 0 -- initialize sum_offset (adds all offsets to get the position of every event in ticks)
	

	-- collect note-on and offs and write to table_notes

	while string_pos < midi_len-12 do -- parse through all events in the MIDI string, one-by-one, excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message
		offset, flags, msg, string_pos = string.unpack("i4Bs4", midi_string, string_pos) -- unpack MIDI-string on string_pos
		sum_offset = sum_offset+offset -- add all event offsets to get next start position of event on each iteration
        event_start = item_start_ppq+sum_offset -- calculate event start position based on item start position
        
        if #msg == 3 then
			if msg:byte(1)>>4 == 9 then -- note-on?
				table_notes[#table_notes+1] = {
				pitch_note_on = msg:byte(2), -- 
				channel_note_on = msg:byte(1)&0x0F, 
				ppq_pos_note_on = event_start, 
				string_pos = string_pos,
			}

			elseif msg:byte(1)>>4 == 8 then -- note-off?
				table_notes[#table_notes+1] = { 
				pitch_note_off = msg:byte(2), -- 
				channel_note_off = msg:byte(1)&0x0F, 
				ppq_pos_note_off = event_start, 
				string_pos = string_pos,
			}
			end
		end
	end

    
    for n = 1, #table_notes do -- note-on iterator
        
        if table_notes[n].ppq_pos_note_on ~= nil then -- only consider note-on table elements
            for o = n+1, #table_notes do -- note-off iterator, don't iterate from start of table but start from current note-on index
                
                if table_notes[n].pitch_note_on == table_notes[o].pitch_note_off -- if pitches are the same
                and table_notes[n].channel_note_on == table_notes[o].channel_note_off -- and channels are the same
                
                then -- note pair found! check if note-on sits already on the grid
                    
                    local note_start = reaper.MIDI_GetProjTimeFromPPQPos(take, table_notes[n].ppq_pos_note_on) -- convert note start to seconds
                    local closest_grid = reaper.SnapToGrid(0, note_start) -- get closest grid (this function relies on visible grid)
                    local closest_grid_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, closest_grid) -- convert closest grid to PPQ
                        
                    if table_notes[n].ppq_pos_note_on ~= note_start then -- note-on not on grid? quantize = calculate offset
                        
                        table_notes[n].new_offset = closest_grid_ppq - table_notes[n].ppq_pos_note_on -- note-on offset
                        table_notes[o].new_offset = table_notes[n].new_offset -- note-on offset is the same for note-off!
                        
                    break -- if corresponding note-off has been found, break the loop, to move to the next note-on
                    end
                end
            end
		end
	end

	-- finally, change the MIDI string and dump data back to take

	string_pos = 1 -- position in midi_string while parsing through events 
	local table_events = {} -- initialize table, MIDI events will temporarily be stored in this table until they are concatenated into a string again
	local n = 1
	
	while string_pos < midi_len-12 do -- parse through all events in the MIDI string, one-by-one, excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message
	offset, flags, msg, string_pos = string.unpack("i4Bs4", midi_string, string_pos) -- unpack MIDI-string on string_pos
	
		-- insert all events back to table_events
		if string_pos == table_notes[n].string_pos and n < #table_notes then -- if string position is either note-on or note-off
            -- if table_notes[n].new_offset ~= nil then
                table.insert(table_events, string.pack("i4Bs4", offset+table_notes[n].new_offset, flags, msg))
                table.insert(table_events, string.pack("i4Bs4", -table_notes[n].new_offset, 0, ""))
                n = n + 1 -- if value (string position) has been used, increment position by 1

            -- end
		else 
            table.insert(table_events, string.pack("i4Bs4", offset, flags, msg)) -- unselect everything else
		end
	end

	-- dump the MIDI stream back to the take
	reaper.MIDI_SetAllEvts(take, table.concat(table_events) .. midi_string:sub(-12)) 
	reaper.MIDI_Sort(take)
end
------------ START

local start = reaper.time_precise()

for take in enumSelectedMIDITakes() do
    --QunatizeMethod1(take)
    --uantizeMethod2(take)
    --QuantizeMethod3(take)
    QuantizeMethod4(take)
end

print(reaper.time_precise() - start)

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, 'script test', -1)
