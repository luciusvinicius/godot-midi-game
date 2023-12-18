extends Node

@onready var player : MidiPlayer = $MidiPlayer
@onready var audio = $AudioStreamPlayer

var is_fullscreen := false

# Test
var strength = 0.5;
var curStrength = 0;
@onready var screen_shake = $ScreenShake

func _ready():
	player.play()
	audio.play()


func _process(delta):
	# Probably this should be in a function in another scene
	curStrength = max(curStrength - delta * 2, 0); # - delta * NUMBER --> ratio of shake to stop
	if(Input.is_action_just_pressed("Move_Left")):
		curStrength = strength;
	
	screen_shake.get_child(0).material.set_shader_parameter("ShakeStrength", max(curStrength,0))

""" func _physics_process(_delta: float) -> void:
	var move_direction = Vector2(
		Input.get_action_strength("mov_right") - Input.get_action_strength("mov_left"),
		Input.get_action_strength("mov_down") - Input.get_action_strength("mov_up")
	).normalized() """



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			is_fullscreen = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			is_fullscreen = true
