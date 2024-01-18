extends Node2D

const CIRCLE_LENGTH = 400
const BASE_SCORE = 100

@onready var sprite : Sprite2D = $Sprite
@onready var trail_particles = $TrailParticles
@onready var explode_audio = $ExplodeAudio

var color_ref : Color = Color.WHITE

# 230 speed ~= 383 midi duration
# 460 speed ~= 192 midi duration
var speed

# -- || Points Vars || --
var is_point := false
const trail_point_texture = preload("res://assets/imgs/small_bullet-points.png")
@onready var point_particles : GPUParticles2D = $PointParticles
@onready var explosion_particles : GPUParticles2D = $ExplosionParticles
@onready var score_audio = $ScoreAudio

# -- || Animation || --
const COLOR_CHANGE_DURATION := 0.5
const NUMBER_BEATS_ALIVE := 4
var beat_scale := 0.0 * Vector2.ONE
var number_beats := 0
var angle := 0.0
const ANGLE_RATE := 0.2
@onready var angle_direction = [-1, 1].pick_random()

const PARTICLE_ANGLE_OFFSET := 90

# -- || Menu Vars || --
var is_menu := false

func _ready():
	SignalManager.tick_played.connect(process_tick)
	sprite.modulate = color_ref


func init_vars(spawn_offset: int, new_duration: int, new_color: Color, menu_bullet: bool):
	position = position + Vector2.UP * spawn_offset
	color_ref = new_color
	speed = (-1.204 * new_duration) + 691.204
	is_menu = menu_bullet


func _process(delta):
	if is_point: 
		_point_process(delta)
		return
	
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	
	# When cross the line
	if position.y < -CIRCLE_LENGTH and not is_menu:
		position.y = -CIRCLE_LENGTH
		turn_into_point()
	

func _point_process(delta):
	angle += ANGLE_RATE * delta * angle_direction
	sprite.rotation = angle
	
	# Particle angle
	var particle_angle = -angle + PARTICLE_ANGLE_OFFSET
	point_particles.process_material.angle_min = rad_to_deg(particle_angle)
	point_particles.process_material.angle_max = rad_to_deg(particle_angle)
	
	position = ang2pos(angle)


# --- || Points || ---

func turn_into_point():
	is_point = true
	trail_particles.set_emitting(false)
	speed = 0
	
	# Cannot just change texture, previously emitted particles are updated as well
	var tick_time = 2 / (Global.bpm / 60) # Wrong time apparently, calculate correctly
	point_particles.set_lifetime(tick_time)

	# Tween animation to change color and flutuation
	var color_tween:Tween = create_tween()
	color_tween.tween_property(sprite, "modulate", Color.AQUA, COLOR_CHANGE_DURATION)

func give_point():
	SignalManager.gained_points.emit(BASE_SCORE)
	score_audio.play()
	sprite.hide()
	point_particles.set_emitting(false)
	

func process_tick(_is_main_tick):
	if not is_point or not sprite.visible: return
	point_particles.set_emitting(true) 
	var tick_time = Global.get_tick_time()
	
	# Check if note is long enough to make it disappear
	number_beats += 1
	if number_beats >= NUMBER_BEATS_ALIVE:
		var hide_tween:Tween = create_tween()
		hide_tween.tween_property(self, "modulate", Color.TRANSPARENT, \
		tick_time).set_trans(Tween.TRANS_CUBIC)
		hide_tween.tween_callback(queue_free) # Kill object at the end of animation
		return




# -- || Damage || --

func damage_player(menu_hit:=false):
	if not menu_hit:
		SignalManager.hit_player.emit()
	explosion_particles.set_emitting(true)
	explode_audio.play()
	sprite.hide()
	trail_particles.set_emitting(false)
	
	# Stop the bullet
	#speed = 0.0
	#acceleration = 0.0
	


# -- || Others || --

func ang2pos(ang:float):
	return Vector2(CIRCLE_LENGTH * sin(ang), -CIRCLE_LENGTH * cos(ang))

func _on_area_area_entered(area):
	var player = area.owner
	if player.name != "Player" or not sprite.visible or player.is_stunned: return
	
	if is_point or player.is_invencible:
		# Invencible player get the point instead
		give_point()
	else:
		damage_player(is_menu)
	
