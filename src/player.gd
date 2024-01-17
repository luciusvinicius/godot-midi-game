extends Node2D

# -- || Nodes || --
@onready var path : PathFollow2D = $Path2D/PathFollow2D
@onready var trail_particles : GPUParticles2D = $Path2D/PathFollow2D/Sprite2D/TrailParticles

# -- || Vars || --
@export var speed := 1
@export var acceleration := 100
@export var friction := 50

var directional_input := Vector2.ZERO
var curve_progress := Vector2.ZERO

# -- || Grid Vars || --
const GRID_POSITIONS := 12
var grid_position := 0 # Value between 0 and GRID_POSITIONS
var goal_position := 0.0
var direction := 0

func _physics_process(delta):
	
	# Disable input while moving
	if is_equal_approx(curve_progress.x, goal_position):
		# Cannot hold input
		direction = int(Input.is_action_just_pressed("mov_right")) - int(Input.is_action_just_pressed("mov_left"))
		grid_position += direction % GRID_POSITIONS
		goal_position = float(grid_position) / GRID_POSITIONS
		trail_particles.set_emitting(false)
	else:
		trail_particles.set_emitting(true)
	
	curve_progress = curve_progress.move_toward(goal_position * Vector2.RIGHT \
	, delta * speed) 
	
	path.progress_ratio = curve_progress.x


func _physics_process2(delta):
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
	
	path.progress = path.progress + curve_progress.x
