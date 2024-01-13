extends Node2D

const BASE_SCORE = 100
const BASE_SPEED = 800
const INITIAL_SPEED_RATE = 0.75 # % of final speed (0.75 looks good)
var max_speed : float # Defined on the time of animation, on NoteSpawner scene.
@onready var score_audio = $ScoreAudio


# Cosine movement (rads)
@onready var initial_speed = INITIAL_SPEED_RATE * BASE_SPEED * max_speed
@onready var acceleration = _calculate_acceleration(initial_speed, BASE_SPEED * max_speed)
@onready var speed = initial_speed
const ACCELERATION_MULTIPLIER = 1.25

# Point System
const POINT_SPRITE = preload("res://assets/imgs/bullet2.png")
var give_points := false
@onready var sprite = $Sprite

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	speed += acceleration * delta
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	
	# Invert when passed center
	if speed > max_speed * BASE_SPEED:
		acceleration *= -ACCELERATION_MULTIPLIER
	
	# Convert to a point before starting to go back
	elif speed < 0 and not give_points: turn_into_point()
	
	# Projectile hit the center --> ban
	elif speed < -BASE_SPEED * max_speed * ACCELERATION_MULTIPLIER: queue_free()
	

func turn_into_point():
	give_points = true
	sprite.texture = POINT_SPRITE

func give_point():
	score_audio.play()
	sprite.hide()
	SignalManager.gained_points.emit(BASE_SCORE)



func _calculate_acceleration(initial_speed, max_speed, distance:= 250):
	# Calculate the acceleration based on Torricelli's formula
	return (max_speed**2 - initial_speed**2) / (2.0 * distance)

func _on_area_area_entered(area):
	var player = area.owner
	if player.name != "Player": return
	
	if give_points and sprite.visible:
		give_point()
	elif not give_points:
		print("You should kill yourself now.")
	
