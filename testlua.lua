---Receives numbers(0-255) and return them in a string as bytes
---@param ... number
---@return string
function PackMessage(...)
    local t = {...}
    local ms = ''
    for i, v in ipairs( { ... } ) do
       local new_val = string.pack('B',v)
      ms = ms..new_val
    end
    return ms
end

---Pack a midi message in a string form. Each character is a midi byte. Can receive as many data bytes needed. Just join midi_type and midi_ch in the status bytes and thow it in PackMessage. 
---@param midi_type number midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
---@param midi_ch number midi ch 1-16 (1 based.)
---@param ... number sequence of data bytes 
function PackMIDIMessage(midi_type,midi_ch,...)
    local midi_ch = midi_ch - 1 -- make it 0 based
    local status_byte = (midi_type*16)+midi_ch -- where is your bitwise operation god now?
    return PackMessage(status_byte,...)
end

print(PackMIDIMessage(9,1,60,100,100,100,100,127))