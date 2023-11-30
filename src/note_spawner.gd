extends Node2D

@onready var anim_player : AnimationPlayer = $Sprite/SpawnerAnim


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func Shoot():
	anim_player.play("Shoot")