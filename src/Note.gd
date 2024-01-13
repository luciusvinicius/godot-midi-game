extends Node2D

const BASE_SPEED = 800
const INITIAL_SPEED_RATE = 0.75 # % of final speed
@export var max_speed : float # Defined on the time of animation, on NoteSpawner scene.

# Cosine movement (rads)
@onready var base_position = position
@onready var initial_speed = INITIAL_SPEED_RATE * BASE_SPEED * max_speed
@onready var acceleration = _calculate_acceleration(initial_speed, BASE_SPEED * max_speed)
@onready var speed = initial_speed



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#var time = timer.time_left - initial_time / 2 # Keep in the interval of [-1, 1] to help calculations
	#var speed_modifier = max(sin(PI/1.0 * time), sin(3*PI/(1.0 * 2))) # The bullet shouldn't go foward after
	speed += acceleration * delta
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration
	if speed > max_speed * BASE_SPEED:
		acceleration *= -1
	pass


func _on_visibility_screen_exited():
	# Clean object if not on screen
	queue_free()

func _calculate_acceleration(initial_speed, max_speed, distance:= 200):
	# Calculate the acceleration based on Torricelli's formula
	return (max_speed**2 - initial_speed**2) / (2.0 * distance)
	
