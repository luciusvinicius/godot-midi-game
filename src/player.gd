extends Node2D

@onready var path_ref : PathFollow2D = $Path2D/PathFollow2D

@export var speed := 20
@export var acceleration := 100
@export var friction := 50

var directional_input := Vector2.ZERO
var curve_progress := Vector2.ZERO


func _physics_process(delta):
	directional_input.x = Input.get_action_strength("move_Right") - Input.get_action_strength("move_Left")

	if directional_input.x != 0:
		curve_progress = curve_progress.move_toward(directional_input * speed, acceleration * delta)
	else:
		curve_progress = curve_progress.move_toward(Vector2.ZERO, friction * delta)
	
	path_ref.progress = path_ref.progress + curve_progress.x
