extends Line2D
class_name Line

var time : float
var is_vert : bool 
var index : float 
var move_direction := 0.0

var sin_speed := 2
var sin_amplifier := 0.8
var sin_vert_offset := 2
var sin_horiz_offset := 0.0

var acceleration := 0.3




func _ready():
	pass


func set_properties(ix:int, vert:bool):
	index = ix
	sin_horiz_offset = 6 / index
	is_vert = vert

	if ix % 2 == 0:
		#move_direction = -move_direction
		sin_vert_offset+= 1


func _process(delta):
	time += delta

	if is_vert:
		position += Vector2(move_direction, 0)
		#position += Vector2(get_sine(), 0)
	else:
		position += Vector2(0, move_direction)
		#position += Vector2(0, get_sine())
		
	move_direction += randf_range(-acceleration, acceleration)
	var max_vel = acceleration * 10
	move_direction = clamp(move_direction, -max_vel, max_vel)

	if position.x < 0 || position.y < 0 || position.x > Global.screen_size.x * Global.screen_size_multiplier || position.y > Global.screen_size.y * Global.screen_size_multiplier:
		move_direction = -move_direction


func get_sine() -> float:
	return (sin((time + sin_horiz_offset) * sin_speed) + sin_vert_offset) * sin_amplifier * move_direction