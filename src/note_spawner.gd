extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
@onready var indicator_spawn : Node2D = $Sprite/IndicatorSpawn

var note_scene = preload("res://src/NoteProjectile.tscn")
var indicator_scene = preload("res://src/Indicator.tscn")

const SPAWN_OFFSET = 100


func spawn_indicator(new_duration: int, new_color: Color):
	var indicator = indicator_scene.instantiate()
	indicator_spawn.add_child(indicator)
	indicator.set_vars(self, new_duration, new_color)


# Called on Indicator animation_finish
func shoot(new_duration: int, new_color: Color):
	var note = note_scene.instantiate()
	note.init_vars(SPAWN_OFFSET, new_duration, new_color)
	add_child(note)

	anim_player.play("Shoot")
