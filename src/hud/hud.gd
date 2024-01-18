extends Control

## -- || Nodes || --
@onready var animation : AnimationPlayer = $Animation
@onready var start = $Start
@onready var quit = $Quit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_area_entered(area):
	animation.play("start_game")
	await animation.animation_finished
	start.hide()
	quit.hide()
	SignalManager.start_game.emit()
func _on_quit_area_entered(area):
	pass # Replace with function body.
