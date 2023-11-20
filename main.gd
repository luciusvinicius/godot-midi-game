extends Node

@onready var player : MidiPlayer = $MidiPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_midi_player_midi_event(channel, event):
	print(event)
	print(channel)
