extends Control

@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalManager.gained_points.connect(gain_points)


func gain_points(quantity):
	Global.score += quantity
	label.text = "Score: %d" % Global.score
