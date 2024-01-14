extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
@onready var timer : Timer = $Timer

var note_scene = preload("res://src/NoteProjectile.tscn")

const SPAWN_OFFSET = 100
const DEFAULT_WAIT_TIME = 2 # seconds (equal to timer on Main scene)

# TEST ONLY!!! I'M TIRED SO I'M DOING THIS SHIT, BUT BEFORE I NEED TO UNDERSTAND
# ON WHAT TO DO WHEN THE ANIMATION IS PLAYING SOMETHING WHEN A NOTE APPEAR!!!
var note_speed


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
	note_speed = animation_time
	anim_player.play("LongShoot", -1, 1/animation_time)

func shoot():
	# Called on the "SpawnerAnim" AnimatonPlayer
	# Create note
	var note = note_scene.instantiate()
	note.position = position + Vector2.UP * SPAWN_OFFSET
	note.max_speed = note_speed
	add_child(note)

