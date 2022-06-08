---Iterate this function it will return the takes open in midi_editor window. editable_only == get only the editables 
---@param midi_editor midi_editor midi_editor window
---@param editable_only boolean If true get only takes that are editable in midi_editor 
---@return function iterate takes
function enumMIDITakes(midi_editor, editable_only) -- Thanks CF
    local i = -1
    return function()
        i = i + 1
        return reaper.MIDIEditor_EnumTakes(midi_editor, i, editable_only)
    end
end

