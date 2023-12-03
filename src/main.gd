extends Node

@onready var player : MidiPlayer = $MidiPlayer
@onready var audio = $AudioStreamPlayer2D

var is_fullscreen := false

func _ready():
	player.play()
	audio.play()

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
