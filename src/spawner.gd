extends Node2D

@onready var outer_circle = $OuterCircle
var note_spawners
var midi_channels_to_process = [0,1]
var channels_colors = [Color.WHITE, Color.RED, Color.DODGER_BLUE]

# -- || Test || --
#var MAX_NOTES = 1
#var notes = 0


func _ready():
	SignalManager.note_on.connect(prepare_shot)
	note_spawners = outer_circle.get_children()


func prepare_shot(channel, note, time):
	#if notes >= MAX_NOTES: return
	var note_duration = Global.get_note_duration(channel, note, time)
	
	if channel in midi_channels_to_process:
		var channel_color = channels_colors[channel % channels_colors.size()]
		note_spawners[note%12].spawn_indicator(note_duration, channel_color)
		#notes += 1

func menu_prepare_shot(player_pos):
	var channel_color = channels_colors.pick_random()
	note_spawners[player_pos%12].spawn_indicator(Global.BIGGEST_DURATION / 2, channel_color, true)
