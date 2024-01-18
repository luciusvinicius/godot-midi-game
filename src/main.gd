extends Node

## -- || Nodes || --
@onready var midi_player : MidiPlayer = $MidiPlayer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var song_delay = $SongDelay
@onready var end_game_delay = $MainMenu/EndGameDelay

### Menu
@onready var player = $Player
@onready var spawner = $Spawner
@onready var menu_bullet_timer = $MainMenu/MenuBulletTimer

var is_fullscreen := false

# TestVideo
var mask_radius := 0.0
var my_tween
@onready var background_sprite : Sprite2D = $Background


func _ready():
	SignalManager.start_game.connect(start_game)
	#start()

func start_game():
	menu_bullet_timer.one_shot = true
	menu_bullet_timer.stop()
	midi_player.play()
	song_delay.start()

func end_game():
	menu_bullet_timer.start()
	menu_bullet_timer.one_shot = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
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


# --- || Video Reveal Shader || ---

func handle_mask_radius(increase: bool):
	var modifier := 1.0
	if !increase:
		modifier = -1.0

	var cache_radius := mask_radius
	mask_radius += 0.1 * modifier 
	mask_radius = clamp(mask_radius, 0.001, 0.3)

	var my_tween2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	my_tween2.tween_method(set_mask_radius.bind(background_sprite), cache_radius, mask_radius, 1.0)


func set_mask_radius(new_radius: float, sprite: Sprite2D):
	sprite.material.set_shader_parameter("MULTIPLIER", new_radius)


# --- || Signals || ---

func _on_song_delay_timeout():
	audio_player.play()

func _on_menu_bullet_timer_timeout():
	spawner.menu_prepare_shot(player.grid_position)

func _on_midi_player_finished():
	end_game_delay.start()

func _on_end_game_delay_timeout():
	end_game()
