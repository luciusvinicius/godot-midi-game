extends Node2D

const CIRCLE_LENGTH = 390
const BASE_SCORE = 100
const BASE_SPEED = 800
const INITIAL_SPEED_RATE = 0.75 # % of final speed (0.75 looks good)
var max_speed : float # Defined on the time of animation, on NoteSpawner scene.
@onready var score_audio = $ScoreAudio
@onready var sprite_ref : Sprite2D = $Sprite

var give_points := false

# Cosine movement (rads)
#@onready var initial_speed = INITIAL_SPEED_RATE * BASE_SPEED * max_speed
#@onready var acceleration = _calculate_acceleration(initial_speed, BASE_SPEED * max_speed)
var acceleration := 0.0
const ACCELERATION_MULTIPLIER = 1.25
var initial_speed := 100.0
#@onready var speed := initial_speed



# 230 speed ~= 383 midi duration
# 460 speed ~= 192 midi duration
var test_speed
var bpm = 190.0

func setup(duration):
	var new_duration = 1.2 #duration/bpm #(duration * 1/8) - 80 # Magic shenanigans
	acceleration = _get_acceleration(new_duration)
	max_speed = _get_max_speed(new_duration)
	print(acceleration)

func calculate_speed(duration: int):
	test_speed = (-1.204 * duration) + 660

#func _process(delta):
	#speed += acceleration * delta
	#position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	#


func _process(delta):
	test_speed += acceleration * delta
	position += Vector2.UP * test_speed * delta # Direction has rotation of parent node in consideration
	
	# When cross the line
	if position.y < -CIRCLE_LENGTH and acceleration == 0:
		acceleration = -_calculate_acceleration(test_speed)
		#queue_free()
	
	# Convert to a point before starting to go back
	elif test_speed < 0 and not give_points: turn_into_point()
	
	# Projectile hit the center --> ban
	elif position.y > -100 and acceleration != 0: queue_free()
	

func _calculate_acceleration(speed):
	return speed # Have no idea why this works perfectly, but we take those

""" func _process(delta):
	speed += acceleration * delta
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	
	# Invert when passed center
	if speed > max_speed * BASE_SPEED:
		acceleration *= -ACCELERATION_MULTIPLIER
	
	# Convert to a point before starting to go back
	elif speed < 0 and not give_points: turn_into_point()
	
	# Projectile hit the center --> ban
	elif speed < -BASE_SPEED * max_speed * ACCELERATION_MULTIPLIER: queue_free() """


# --- || Formulas || ---

func _get_acceleration(time, distance:=250.0):
	# Using formula from accelerated movement a = 2(S - Vot) / t², if So == 0:
	return 2 * (distance - initial_speed*time) / time**2

func _get_max_speed(time):
	# Using V = Vo + at
	return initial_speed + acceleration * time

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
	
