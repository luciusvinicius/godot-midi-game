extends Node

# -- || Vars || --
var has_started := false
var bpm := 0.0
var time := 0.0
#var beats_per_shake := 2
var n_ticks := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalManager.set_bpm.connect(set_bpm)

func set_bpm(val:float):
	bpm = round(val) # Val is slightly not precise, round is enough
	Global.bpm = bpm

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if bpm == 0.0 or not has_started: return
	
	# Convert to BPS and then make the amount of Beats / Second
	var bps = bpm / 60.0
	var beat_time = (1 / bps) * (4.0 / Global.TICKS_PER_BEAT) 
	time += delta
	if time > beat_time:
		n_ticks += 1
		var is_main_tick = n_ticks % Global.TICKS_PER_BEAT == 0
		SignalManager.tick_played.emit(is_main_tick)
		time -= beat_time

func _on_song_delay_timeout():
	has_started = true
	SignalManager.tick_played.emit(true) # When it starts, it emits the first tick
