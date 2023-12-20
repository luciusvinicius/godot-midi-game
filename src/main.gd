extends Node

@onready var midi_player : MidiPlayer = $MidiPlayer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

var is_fullscreen := false

# Test
var strength = 0.5;
var curStrength = 0;
@onready var screen_shake = $ScreenShake


func _ready():
	audio_player.play()
	await get_tree().create_timer(1.185).timeout
	midi_player.play()


func _process(delta):
	# Probably this should be in a function in another scene
	curStrength = max(curStrength - delta * 2, 0); # - delta * NUMBER --> ratio of shake to stop
	if(Input.is_action_just_pressed("Move_Left")):
		curStrength = strength;
	
	#screen_shake.get_child(0).material.set_shader_parameter("ShakeStrength", max(curStrength,0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			is_fullscreen = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			is_fullscreen = true
