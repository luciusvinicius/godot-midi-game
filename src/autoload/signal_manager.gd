extends Node

# -- || Setup MIDI || --
signal note_on(channel, _event, note, _velocity)
signal set_bpm(bpm)

# -- || In-Game || --
signal gained_points(quantity)
signal hit_player
