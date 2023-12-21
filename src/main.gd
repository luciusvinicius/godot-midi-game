extends Node

@onready var midi_player : MidiPlayer = $MidiPlayer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer
var is_fullscreen := false

# TestShake
var strength = 0.5;
var curStrength = 0;
@onready var screen_shake = $ScreenShake

# TestVideo
var mask_radius := 0.0
var my_tween
@onready var background_sprite : Sprite2D = $Background


func _ready():
	audio_player.play()
	await get_tree().create_timer(1.185).timeout
	midi_player.play()


func _process(delta):
	# Probably this should be in a function in another scene
	curStrength = max(curStrength - delta * 2, 0); # - delta * NUMBER --> ratio of shake to stop
	if(Input.is_action_just_pressed("move_Left")):
		curStrength = strength;
	
	#screen_shake.get_child(0).material.set_shader_parameter("ShakeStrength", max(curStrength,0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			is_fullscreen = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			is_fullscreen = true

	if event.is_action_pressed("more_radius"):
		handle_mask_radius(true)

	if event.is_action_pressed("less_radius"):
		handle_mask_radius(false)


func handle_mask_radius(increase: bool):

	var modifier := 1.0
	if !increase:
		modifier = -1.0

	var cache_radius := mask_radius
	mask_radius += 0.1 * modifier 
	mask_radius = clamp(mask_radius, 0.001, 0.3)

	var my_tween2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	my_tween2.tween_method(set_mask_radius.bind(background_sprite), cache_radius, mask_radius, 1.0)

	if my_tween == null:
		pass
		#my_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		pass
		#print("Stuff")
		#var my_tween2 = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		#my_tween2.tween_method(set_mask_radius.bind(background_sprite), cache_radius, mask_radius, 1.0)


func set_mask_radius(new_radius: float, sprite: Sprite2D):
	sprite.material.set_shader_parameter("MULTIPLIER", new_radius)
