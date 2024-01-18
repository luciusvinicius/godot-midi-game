extends Control

## -- || Nodes || --
@onready var animation : AnimationPlayer = $Animation
@onready var start = $Start
@onready var quit = $Quit

func _on_start_area_entered(area):
	if not area.owner.sprite.visible: return
	animation.play("start_game")
	await animation.animation_finished
	start.hide()
	quit.hide()
	SignalManager.start_game.emit()

func _on_quit_area_entered(area):
	if not area.owner.sprite.visible: return
	animation.play("quit_game")
	await animation.animation_finished
	get_tree().quit()


func _on_end_game_delay_timeout():
	start.show()
	quit.show()
	animation.play("reappear")
