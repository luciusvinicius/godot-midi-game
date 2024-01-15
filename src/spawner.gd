extends Node2D

@onready var outer_circle = $OuterCircle
var note_spawners
var midi_channels_to_process = [0,1]


func _ready():
	SignalManager.note_on.connect(prepare_shot)
	note_spawners = outer_circle.get_children()


func prepare_shot(channel, note, time):
	var note_duration = Global.get_note_duration(channel, note, time)
	if channel in midi_channels_to_process:
		note_spawners[note%12].insta_shoot(note_duration)
