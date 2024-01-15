extends Node2D

# -- || Nodes || --
@onready var path_ref : PathFollow2D = $Path2D/PathFollow2D
@onready var trail_particles : GPUParticles2D = $Path2D/PathFollow2D/Sprite2D/TrailParticles

# -- || Vars || --
@export var speed := 20
@export var acceleration := 100
@export var friction := 50

var directional_input := Vector2.ZERO
var curve_progress := Vector2.ZERO


func _physics_process(delta):
	directional_input.x = Input.get_action_strength("mov_right") - Input.get_action_strength("mov_left")

	if directional_input.x != 0:
		curve_progress = curve_progress.move_toward(directional_input * speed, acceleration * delta)
		trail_particles.set_emitting(true)
	else:
		curve_progress = curve_progress.move_toward(Vector2.ZERO, friction * delta)
	
	# Trail Particles
	if curve_progress == Vector2.ZERO:
		trail_particles.set_emitting(false)
	else:
		trail_particles.set_emitting(true)
	
	path_ref.progress = path_ref.progress + curve_progress.x
