extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
var note_scene = preload("res://src/Note.tscn")

const SPAWN_OFFSET = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func Shoot():
	anim_player.play("Shoot")
	
	# Create note
	var note = note_scene.instantiate()
	note.position = position + Vector2.UP * SPAWN_OFFSET
	add_child(note)

