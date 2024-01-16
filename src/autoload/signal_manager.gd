extends Node

signal note_on(channel, note, time)
signal set_bpm(bpm)

# -- || In-Game || --
signal gained_points(quantity)
signal hit_player
signal tick_played(is_main_tick)
