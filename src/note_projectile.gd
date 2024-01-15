extends Node2D

const CIRCLE_LENGTH = 390
const BASE_SCORE = 100
var SPAWN_OFFSET
@onready var sprite : Sprite2D = $Sprite
@onready var trail_particles = $TrailParticles
@onready var explode_audio = $ExplodeAudio
var acceleration := 0.0
# 230 speed ~= 383 midi duration
# 460 speed ~= 192 midi duration
var speed

# -- || Points Vars || --
var give_points := false
const trail_point_texture = preload("res://assets/imgs/small_bullet-points.png")
@onready var point_particles = $PointParticles
@onready var explosion_particles = $ExplosionParticles
@onready var score_audio = $ScoreAudio


func calculate_speed(duration: int):
	speed = (-1.204 * duration) + 691.204

func _process(delta):
	speed += acceleration * delta
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	
	# When cross the line
	if position.y < -CIRCLE_LENGTH and acceleration == 0:
		acceleration = -_calculate_acceleration(speed)
	
	# Convert to a point before starting to go back
	elif speed < 0 and not give_points: turn_into_point()
	
	# Projectile hit the center --> ban
	elif position.y > -SPAWN_OFFSET and acceleration != 0: queue_free()

# Top 10 funções foda
func _calculate_acceleration(speed):
	return speed # Have no idea why this works perfectly, but we take those lmao


# --- || Points || ---

func turn_into_point():
	give_points = true
	sprite.modulate.r = 0.0;
	trail_particles.set_emitting(false)
	
	# Cannot just change texture, previously emitted particles are updated as well
	if sprite.visible: # Case for bullet that collided previously
		point_particles.set_emitting(true) 


func give_point():
	SignalManager.gained_points.emit(BASE_SCORE)
	score_audio.play()
	sprite.hide()
	point_particles.set_emitting(false)

func damage_player():
	SignalManager.hit_player.emit()
	explosion_particles.set_emitting(true)
	explode_audio.play()
	sprite.hide()
	trail_particles.set_emitting(false)
	# Stop the bullet
	#speed = 0.0
	#acceleration = 0.0
	

func _on_area_area_entered(area):
	var player = area.owner
	if player.name != "Player" or not sprite.visible: return
	
	if give_points:
		give_point()
	else:
		damage_player()
	
