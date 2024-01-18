extends Control

@onready var label = $Label
const BEAT_SCALE := 1.1

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalManager.gained_points.connect(gain_points)
	SignalManager.tick_played.connect(scale_on_beat)


func gain_points(quantity):
	Global.score += quantity
	label.text = "Score: %d" % Global.score

func scale_on_beat(_is_main_tick):
	var scale_tween = create_tween()
	var tick_time = Global.get_tick_time()
	scale_tween.tween_property(label, "scale", Vector2.ONE \
	, tick_time / 2).set_trans(Tween.TRANS_EXPO)
	scale_tween.tween_property(label, "scale", Vector2.ONE \
	* BEAT_SCALE, tick_time / 2).set_trans(Tween.TRANS_EXPO)
