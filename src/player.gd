extends Node2D

# -- || Nodes || --
@onready var path : PathFollow2D = $Path2D/PathFollow2D
@onready var trail_particles : GPUParticles2D = $Path2D/PathFollow2D/Sprite2D/TrailParticles
@onready var animation : AnimationPlayer = $Path2D/PathFollow2D/Sprite2D/Animation

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

# -- || Damage Vars || --
var is_invencible := false
var is_stunned := false
const POINT_PENALTY := 500

func _ready():
	SignalManager.hit_player.connect(take_damage)

func _physics_process(delta):
	
	# Disable input while moving
	if is_equal_approx(curve_progress.x, goal_position) and not is_stunned:
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

func take_damage():
	SignalManager.gained_points.emit(-POINT_PENALTY)
	animation.play("take_damage")

func set_invencibility(val:bool):
	is_invencible = val

func set_stun(val:bool):
	is_stunned = val
