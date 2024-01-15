extends Node2D

const CIRCLE_LENGTH = 390
const BASE_SCORE = 100
var SPAWN_OFFSET
@onready var score_audio = $ScoreAudio
@onready var sprite_ref : Sprite2D = $Sprite
var acceleration := 0.0
# 230 speed ~= 383 midi duration
# 460 speed ~= 192 midi duration
var speed

var give_points := false


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
	sprite_ref.modulate.r = 0.0;


func give_point():
	score_audio.play()
	sprite_ref.hide()
	SignalManager.gained_points.emit(BASE_SCORE)


func _on_area_area_entered(area):
	var player = area.owner
	if player.name != "Player": return
	
	if give_points and sprite_ref.visible:
		give_point()
	elif not give_points:
		print("You should kill yourself now.")
	
