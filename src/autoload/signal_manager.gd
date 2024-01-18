extends Node

signal note_on(channel, note, time)
signal set_bpm(bpm)
signal start_game

# -- || In-Game || --
signal gained_points(quantity)
signal hit_player(damage)
signal tick_played(is_main_tick)
