extends Node2D

@export var tween_duration := 2
@export var rot_angle := 10
@export var mov_offset := Vector2(0, 1000)

func _ready():
	pass
	#rot_1(0)


func rot_1(idx:int):
	var rot_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	rot_tween.tween_property(self, "rotation_degrees", rot_angle, tween_duration)
	rot_tween.parallel().tween_property(self, "position", -mov_offset, tween_duration).as_relative()
	rot_tween.step_finished.connect(rot_2)

	

func rot_2(idx:int):
	var rot_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	rot_tween.tween_property(self, "rotation_degrees", -rot_angle, tween_duration)
	rot_tween.parallel().tween_property(self, "position", mov_offset, tween_duration).as_relative()
	rot_tween.step_finished.connect(rot_1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
