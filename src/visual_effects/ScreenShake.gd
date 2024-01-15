class_name ScreenShake

extends CanvasLayer

# -- || Nodes || --
@onready var color_rect = $ColorRect

# -- || Vars || --
var strength := 0.0
var decrease_ratio := 0.0
var INTENSITY := 0.15
var TIME := 0.5
var PLAYER_HIT_INTENSITY_MULTIPLIER := 7.5

func _ready():
	SignalManager.hit_player.connect(receive_player_damage)

func shake(intensity:=INTENSITY, time:=TIME): # time in seconds
	strength = intensity
	decrease_ratio = intensity / time

func receive_player_damage():
	shake(INTENSITY*PLAYER_HIT_INTENSITY_MULTIPLIER)

func _process(delta):
	strength = max(strength - delta * decrease_ratio, 0); # - delta * NUMBER --> ratio of shake to stop
	color_rect.material.set_shader_parameter("ShakeStrength", max(strength,0))
