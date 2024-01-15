extends Node

# Duration for each note detected in the MIDI. It has the following structure:
# All: { "1": channel1, "2": channel2, ...} --> It is not an array bc the MIDI don't read in order.
# Channel: [note1, note2]
# Note: {"value": 87, "duration": 40}

var early_note_durations := {} # struct that keeps note_ons
var note_durations := {} # final struct after MIDI is parsed, already with note durations
var playback_note_durations := {} # copy of durations to be managed during MIDI play
const BIGGEST_DURATION = 384.0

# Game information
var score := 0


# --- || Struct Management || ---

func get_notes_from_struct(struct, channel, note):
	# Get notes that match channel
	var channel_notes : Array
	if !struct.has(channel):
		push_error("Trying to access MIDI channel that does not exist!")
		return []

	channel_notes  = struct[channel]

	# Get notes that match value
	var possible_notes : Array = channel_notes.filter(func(i): return i["value"] == note)
	if possible_notes.size() == 0: 
		push_error("No notes found on this MIDI channel!")
		return []
	
	return possible_notes
	

func add_note_start(new_note, channel):
	if !early_note_durations.has(channel):
		early_note_durations[channel] = [new_note]
	else:
		early_note_durations[channel].append(new_note)


func add_note_end(new_note, channel):
	# Get notes that match value
	var possible_notes = get_notes_from_struct(early_note_durations, channel, new_note["value"])

	#Compare with first available note and calculate duration
	var first_available_note = possible_notes[0]
	var duration = new_note["time"] - first_available_note["time"]
	var final_note = {"value": first_available_note["value"], "start": first_available_note["time"], "duration": duration}
	
	#Set final data structure
	if !note_durations.has(channel):
		note_durations[channel] = [final_note]
	else:
		note_durations[channel].append(final_note)

	#Erase used note from early_note_durations
	var note_idx = early_note_durations[channel].find(first_available_note)
	early_note_durations[channel].remove_at(note_idx)


func initialize_playback_durations():
	# Deep copy so that they can function separately 
	playback_note_durations = note_durations.duplicate(true);


# --- || Playback Access || ---

func get_note_duration(channel: int, note : int, time: int):
	var possible_notes = get_notes_from_struct(playback_note_durations, channel, note)

	# Get notes that match time
	var possible_notes_time : Array = possible_notes.filter(func(i): return i["start"] == time)
	if possible_notes_time.size() == 0: 
		push_error("No notes found with this value and start time!")
		return -1

	#Get duration
	var duration = possible_notes_time[0]["duration"]

	#Erase used note from playback struct
	var note_idx = playback_note_durations[channel].find(possible_notes_time[0])
	playback_note_durations[channel].remove_at(note_idx)

	return duration


""" func get_note_duration(specific_note: int, channel: int, delete_note := true, reversed := false) -> Dictionary:
	var channel_notes : Array = note_durations[channel]

	# Get notes with correct value
	var possible_notes : Array = channel_notes.filter(func(note): return note.value == specific_note)
	
	if possible_notes.size() == 0: 
		push_error("Note %d not existent in channel %d." % [specific_note, channel])
		return {}
	var ret
	
	if reversed: 
		ret = possible_notes[-1]
	else: 
		ret = possible_notes[0]
	
	# Delete note from possible_notes if wanted
	if delete_note:
		var note_idx = channel_notes.find(ret)
		channel_notes.remove_at(note_idx)
	return ret """
	


