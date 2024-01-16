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

# -- || BPM Vars || --
const COMPASS_SHAKE_MULTIPLIER = 2.5

func _ready():
	SignalManager.hit_player.connect(receive_player_damage)
	SignalManager.tick_played.connect(bpm_shake)

func shake(intensity:=INTENSITY, time:=TIME): # time in seconds
	strength = intensity
	decrease_ratio = intensity / time

func bpm_shake(is_main_tick:bool):
	var shake_intensity
	if is_main_tick: # Compass shake has different intensity
		shake_intensity = INTENSITY * COMPASS_SHAKE_MULTIPLIER
	else:
		shake_intensity = INTENSITY
	# shake(shake_intensity) <-- Annoying

func receive_player_damage():
	shake(INTENSITY*PLAYER_HIT_INTENSITY_MULTIPLIER)

func _process(delta):
	strength = max(strength - delta * decrease_ratio, 0); # - delta * NUMBER --> ratio of shake to stop
	color_rect.material.set_shader_parameter("ShakeStrength", max(strength,0))
