extends Node2D

@export var speed = 200
var direction : Vector2
var teste

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += Vector2.UP * speed * delta # Direction has rotation of parent node in consideration


func _on_visibility_screen_exited():
	# Clean object if not on screen
	queue_free()
