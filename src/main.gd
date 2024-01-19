extends Node

## -- || Nodes || --
@onready var midi_player : MidiPlayer = $MidiPlayer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var video_player : VideoStreamPlayer = $VideoLayer/AspectRatioContainer/VideoStreamPlayer
@onready var song_delay = $SongDelay
@onready var end_game_delay = $MainMenu/EndGameDelay

### Menu
@onready var player = $Player
@onready var spawner = $Spawner
@onready var menu_bullet_timer = $MainMenu/MenuBulletTimer

var is_fullscreen := false


func _ready():
	SignalManager.start_game.connect(start_game)

func start_game():
	menu_bullet_timer.one_shot = true
	menu_bullet_timer.stop()
	midi_player.play()
	song_delay.start()
	video_player.play()

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


# --- || Signals || ---

func _on_song_delay_timeout():
	audio_player.play()

func _on_menu_bullet_timer_timeout():
	spawner.menu_prepare_shot(player.grid_position)

func _on_midi_player_finished():
	end_game_delay.start()

func _on_end_game_delay_timeout():
	end_game()
