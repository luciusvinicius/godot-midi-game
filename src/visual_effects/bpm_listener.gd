extends Node

# -- || Exports || --
@export var screen_shake:ScreenShake 

# -- || Consts || --
const COMPASS_SHAKE_MULTIPLIER = 2.5

# -- || Vars || --
var has_started := false
var bpm := 0.0
var time := 0.0
var beats_per_shake := 2
var n_shakes := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalManager.set_bpm.connect(set_bpm)

func set_bpm(val:float):
	bpm = round(val) # Val is slightly not precise, round is enough

func shake():
	var shake_intensity
	if n_shakes%beats_per_shake == 0: # Compass shake has different intensity
		shake_intensity = screen_shake.INTENSITY * COMPASS_SHAKE_MULTIPLIER
	else:
		shake_intensity = screen_shake.INTENSITY
	screen_shake.shake(shake_intensity)
	n_shakes += 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if bpm == 0.0 or not has_started: return
	
	# Convert to BPS and then make the amount of Beats / Second
	var bps = bpm / 60.0
	var beat_time = (1 / bps) * (4.0 / beats_per_shake) 
	time += delta
	if time > beat_time :
		shake()
		time -= beat_time

func _on_song_delay_timeout():
	shake() # Initial shake
	has_started = true
