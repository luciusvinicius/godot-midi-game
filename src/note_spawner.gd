extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
@onready var timer : Timer = $Timer

var note_scene = preload("res://src/Note.tscn")

const SPAWN_OFFSET = 100
const DEFAULT_WAIT_TIME = 2 # seconds

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func prepare_shot(note_duration: int):
	var animation_speed = Global.BIGGEST_DURATION/note_duration
	timer.wait_time = DEFAULT_WAIT_TIME * (1 - 1.0/animation_speed)
	#timer.start()
	#await timer.timeout
	anim_player.play("LongShoot", -1, animation_speed)

func shoot():
	# Create note
	var note = note_scene.instantiate()
	note.position = position + Vector2.UP * SPAWN_OFFSET
	add_child(note)

