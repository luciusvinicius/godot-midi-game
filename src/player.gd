extends Node2D

# -- || Nodes || --
@onready var path : PathFollow2D = $Path2D/PathFollow2D
@onready var trail_particles : GPUParticles2D = $Path2D/PathFollow2D/Sprite2D/TrailParticles

# -- || Vars || --
@export var speed := 1
@export var acceleration := 100
@export var friction := 50

# -- || Grid Vars || --
const GRID_POSITIONS := 12
var grid_position := 6 # Value between 0 and GRID_POSITIONS
var direction := 0
@onready var goal_position := float(grid_position) / GRID_POSITIONS
@onready var curve_progress := goal_position * Vector2.RIGHT


func _physics_process(delta):
	
	# Disable input while moving
	if is_equal_approx(curve_progress.x, goal_position):
		# Cannot hold input
		direction = int(Input.is_action_just_pressed("mov_left")) - int(Input.is_action_just_pressed("mov_right"))
		grid_position += direction % GRID_POSITIONS
		goal_position = float(grid_position) / GRID_POSITIONS
		trail_particles.set_emitting(false)
	else:
		trail_particles.set_emitting(true)
	
	curve_progress = curve_progress.move_toward(goal_position * Vector2.RIGHT \
	, delta * speed) 
	
	path.progress_ratio = curve_progress.x


