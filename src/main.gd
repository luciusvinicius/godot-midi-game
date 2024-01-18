extends Node


@onready var midi_player : MidiPlayer = $MidiPlayer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var song_delay = $SongDelay

var is_fullscreen := false


func _ready():
	midi_player.play()


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
