class_name ScreenShake

extends CanvasLayer

# -- || Nodes || --
@onready var color_rect = $ColorRect

# -- || Vars || --
var strength := 0.0
var decrease_ratio := 0.0
var INTENSITY := 0.2
var TIME := 0.5


func shake(intensity:=INTENSITY, time:=TIME): # time in seconds
	strength = intensity
	decrease_ratio = intensity / time

func _process(delta):
	strength = max(strength - delta * decrease_ratio, 0); # - delta * NUMBER --> ratio of shake to stop
	#if(Input.is_action_just_pressed("mov_left")):
		#shake()
	color_rect.material.set_shader_parameter("ShakeStrength", max(strength,0))
