extends Node2D

@onready var outer_circle = $OuterCircle
var note_spawners

#TestVar
var process_all_channels = true


func _ready():
	SignalManager.note_on.connect(Shoot)
	note_spawners = outer_circle.get_children()


func Shoot(channel, _event, note, _velocity):

	if process_all_channels:
		if channel.number in [0, 1, 2]:
			note_spawners[note%12].Shoot()
			if channel.number == 0:
				process_all_channels = false
	else:
		if channel.number == 0:
			note_spawners[note%12].Shoot()
		
