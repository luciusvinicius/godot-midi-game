extends Node

# Duration for each note detected in the MIDI. It has the following structure:
# All: { "1": channel1, "2": channel2, ...} --> It is not an array bc the MIDI don't read in order.
# Channel: [note1, note2]
# Note: {"value": 87, "duration": 40}
var note_durations := {}
const BIGGEST_DURATION = 384.0

func get_note_duration(specific_note: int, channel: int, delete_note := true, reversed := false) -> Dictionary:
	var channel_notes : Array = note_durations[channel]
	# Get notes with correct value
	var possible_notes : Array = channel_notes.filter(func(note): return note.value == specific_note)
	
	if possible_notes.size() == 0: 
		push_error("Note %d not existent in channel %d." % [specific_note, channel])
		return {}
	var ret
	
	if reversed: ret = possible_notes[-1]
	else: ret = possible_notes[0]
	
	# Delete note from possible_notes if wanted
	if delete_note:
		var note_idx = channel_notes.find(ret)
		channel_notes.remove_at(note_idx)
	return ret
	


# Game information
var score := 0
