extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim
@onready var indicator_spawn : Node2D = $Sprite/IndicatorSpawn

var note_scene = preload("res://src/NoteProjectile.tscn")
var indicator_scene = preload("res://src/Indicator.tscn")

const SPAWN_OFFSET = 100


func spawn_indicator(new_duration: int, channel: int, menu_bullet:=false):
	var indicator = indicator_scene.instantiate()
	indicator_spawn.add_child(indicator)
	indicator.set_vars(self, new_duration, channel, menu_bullet)


# Called on Indicator animation_finish
func shoot(new_duration: int, channel: int, menu_bullet: bool):
	var note = note_scene.instantiate()
	note.init_vars(SPAWN_OFFSET, new_duration, channel, menu_bullet)
	add_child(note)

	anim_player.play("Shoot")
