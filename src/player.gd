extends Node2D

# -- || Nodes || --
@onready var path : PathFollow2D = $Path2D/PathFollow2D
@onready var trail_particles : GPUParticles2D = $Path2D/PathFollow2D/Sprite2D/TrailParticles
@onready var timer_ref : Timer = $RegenTimer

# -- || Vars || --
@export var speed := 1
@export var regen_ammount := 0.3
@export var max_health := 30.0
@onready var health := max_health:
	set(val):
		health = clamp(val, 0, max_health)

		# Map mask to health
		mask_radius = (max_mask * health) / max_health
		mask_radius = clamp(mask_radius, min_mask, max_mask)

		if health <= 0:
			print("EndGame")
		elif health < max_health:
			timer_ref.start()
		elif health >= max_health:
			timer_ref.stop()

# -- || Video Vars || --
@export var max_mask := 0.3
@export var min_mask := 0.001 # Cannot be exactlly 0 due to shader logic
@onready var mask_radius := min_mask
var background_ref : Sprite2D

# -- || Grid Vars || --
const GRID_POSITIONS := 12
var grid_position := 6 # Value between 0 and GRID_POSITIONS
var direction_input := 0
@onready var goal_position := float(grid_position) / GRID_POSITIONS
@onready var curve_progress := goal_position * Vector2.RIGHT # Vector with only x value. Used due to move_toward method


func _ready():
	SignalManager.hit_player.connect(receive_player_damage)
	background_ref = get_parent().find_child("Background")

	var my_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	my_tween.tween_method(set_mask_radius.bind(background_ref), mask_radius, max_mask, 1.0)


func _physics_process(delta):
	
	if is_equal_approx(curve_progress.x, goal_position):
		# Cannot hold input
		direction_input = int(Input.is_action_just_pressed("mov_left")) - int(Input.is_action_just_pressed("mov_right"))
		grid_position += direction_input % GRID_POSITIONS
		goal_position = float(grid_position) / GRID_POSITIONS
		trail_particles.set_emitting(false)
	else:
		trail_particles.set_emitting(true)
	
	curve_progress = curve_progress.move_toward(goal_position * Vector2.RIGHT, delta * speed) 
	path.progress_ratio = curve_progress.x


# --- || Video Reveal Shader || ---
	
func set_mask_radius(new_radius: float, sprite_ref: Sprite2D):
	sprite_ref.material.set_shader_parameter("MULTIPLIER", new_radius)


# -- || Signal Callback || --

func receive_player_damage(damage : int):
	health -= damage


func _on_regen_timer_timeout():
	health += regen_ammount
	set_mask_radius(mask_radius, background_ref)
