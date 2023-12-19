extends Node2D

@onready var outer_circle = $OuterCircle
@onready var timer : Timer = $Timer
var note_spawners


func _ready():
	SignalManager.note_on.connect(prepare_shot)
	note_spawners = outer_circle.get_children()


func prepare_shot(channel, _event, note, _velocity):
	var note_duration = Global.get_note_duration(note, channel.number)
	if channel.number in [0]:
		note_spawners[note%12].prepare_shot(note_duration.duration)
