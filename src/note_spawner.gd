extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
@onready var timer : Timer = $Timer

var note_scene = preload("res://src/Note.tscn")

const SPAWN_OFFSET = 100
const DEFAULT_WAIT_TIME = 2 # seconds

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# TODO: What to do if more than one note spawns while other's animation is happening
func prepare_shot(note_duration: int):
	
	# TODO: do something fr, this is just for my sanity
	if anim_player.is_playing() or timer.time_left != 0: 
		return
	
	var animation_time = note_duration/Global.BIGGEST_DURATION
	var wait_time = DEFAULT_WAIT_TIME - (DEFAULT_WAIT_TIME * animation_time)

	if wait_time > 0:
		timer.wait_time = wait_time
		timer.start()
		await timer.timeout
	anim_player.play("LongShoot", -1, 1/animation_time)

func shoot():
	# Create note
	var note = note_scene.instantiate()
	note.position = position + Vector2.UP * SPAWN_OFFSET
	add_child(note)

