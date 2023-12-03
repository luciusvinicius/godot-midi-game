extends Node2D

@onready var outer_circle = $OuterCircle
var note_spawners


func _ready():
	SignalManager.note_on.connect(Shoot)
	note_spawners = outer_circle.get_children()


func Shoot(channel, _event, note, _velocity):
	if channel.number in [0, 1]:
		note_spawners[note%12].Shoot()
		
