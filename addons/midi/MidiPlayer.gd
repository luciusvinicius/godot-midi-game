class_name MidiPlayer

extends Node

const ADSR = preload( "ADSR.tscn" )

# -------------------------------------------------------

const max_track:int = 16
const max_channel:int = 16
const max_note_number:int = 128
const max_program_number:int = 128
const drum_track_channel:int = 0x09

const midi_master_bus_name:String = "arlez80_GMP_MASTER_BUS"
const midi_channel_bus_name:String = "arlez80_GMP_CHANNEL_BUS%d"

# -----------------------------------------------------------------------------

class GodotMIDIPlayerChannelAudioEffect:
	var ae_panner:AudioEffectPanner = null
	var ae_reverb:AudioEffectReverb = null
	var ae_chorus:AudioEffectChorus = null

class GodotMIDIPlayerSysEx:
	var gs_reset:bool
	var gm_system_on:bool
	var xg_system_on:bool

	func _init():
		self.initialize( )

	func initialize( ) -> void:
		self.gs_reset = false
		self.gm_system_on = false
		self.xg_system_on = false

class GodotMIDIPlayerTrackStatus:
	var events:Array[SMF.MIDIEventChunk] = []
	var event_pointer:int = 0

class GodotMIDIPlayerChannelStatus:
	var number:int
	var track_name:String
	var instrument_name:String
	var note_on:Dictionary
	var mute:bool

	var bank:int
	var program:int
	var pitch_bend:float

	var volume:float
	var expression:float
	var reverb:float
	var tremolo:float
	var chorus:float
	var celeste:float
	var phaser:float
	var modulation:float
	var hold:bool
	var portamento:float
	var sostenuto:float
	var freeze:bool
	var pan:float

	var drum_track:bool

	var rpn:GodotMIDIPlayerChannelStatusRPN

	func _init(_number:int,_bank:int = 0,_drum_track:bool = false):
		self.number = _number
		self.track_name = "Track %d" % _number
		self.instrument_name = "Track %d" % _number
		self.mute = false
		self.bank = _bank
		self.drum_track = _drum_track
		self.rpn = GodotMIDIPlayerChannelStatusRPN.new( )
		self.initialize( )

	func _notification( what:int ):
		if what == NOTIFICATION_PREDELETE:
			self.note_on.clear( )

	func initialize( ) -> void:
		self.note_on = {}
		self.program = 0

		self.pitch_bend = 0.0
		self.volume = 100.0 / 127.0
		self.expression = 1.0
		self.reverb = 0.0
		self.tremolo = 0.0
		self.chorus = 0.0
		self.celeste = 0.0
		self.phaser = 0.0
		self.modulation = 0.0
		self.hold = false
		self.portamento = 0.0
		self.sostenuto = 0.0
		self.freeze = false
		self.pan = 0.5

		self.rpn.initialize( )

class GodotMIDIPlayerChannelStatusRPN:
	var selected_msb:int
	var selected_lsb:int
	
	var pitch_bend_sensitivity:float
	var pitch_bend_sensitivity_msb:float
	var pitch_bend_sensitivity_lsb:float
	
	var modulation_sensitivity:float
	var modulation_sensitivity_msb:float
	var modulation_sensitivity_lsb:float

	func _init():
		self.initialize( )

	func initialize( ) -> void:
		self.selected_msb = 0
		self.selected_lsb = 0
		
		self.pitch_bend_sensitivity = 2.0
		self.pitch_bend_sensitivity_msb = 2.0
		self.pitch_bend_sensitivity_lsb = 0.0
		
		self.modulation_sensitivity = 0.25
		self.modulation_sensitivity_msb = 0.25
		self.modulation_sensitivity_lsb = 0.0

# -----------------------------------------------------------------------------

@export_range (0, 256) var max_polyphony:int = 96 : set = set_max_polyphony
@export_file ("*.mid") var file:String = "" : set = set_file
@export var playing:bool = false
@export_range (0.0, 100.0) var play_speed:float = 1.0
@export_range (-80.0, 0.0) var volume_db:float = -20.0 : set = set_volume_db
@export var key_shift:int = 0
@export var loop:bool = false
@export var loop_start:float = 0.0
@export var load_all_voices_from_soundfont:bool = true
@export_file ("*.sf2") var soundfont:String = "res://assets/sound_fonts/ff4sf2.sf2" : set = set_soundfont
@export var mix_target:AudioStreamPlayer.MixTarget = AudioStreamPlayer.MIX_TARGET_STEREO
@export var bus:StringName = &"Master"
@export_range (10, 480) var sequence_per_seconds:int = 120

# -----------------------------------------------------------------------------

var thread:Thread = null
var mutex:Mutex = Mutex.new()
var thread_delete:bool = false
var no_thread_mode:bool = false

var smf_data:SMF.SMFData = null : set = set_smf_data
@onready var track_status:GodotMIDIPlayerTrackStatus = GodotMIDIPlayerTrackStatus.new( )
var tempo:float = 120.0 : set = set_tempo
var seconds_to_timebase:float = 2.3
var timebase_to_seconds:float = 1.0 / seconds_to_timebase
var position:float = 0.0
var last_position:int = 0
var channel_status:Array[GodotMIDIPlayerChannelStatus]
var bank:Bank = null
var audio_stream_players:Array[AudioStreamPlayerADSR] = []
var drum_assign_groups:Dictionary = {
	# Hi-Hats
	42: 42,	# Closed Hi-Hat
	44: 42,	# Pedal Hi-Hat
	46: 42,	# Pedal Hi-Hat
	# Whistle
	71: 71,	# Short Whistle
	72: 71,	# Long Whistle
	# Guiro
	73: 73,	# Short Guiro
	74: 73,	# Long Guiro
	# Cuica
	78: 78,	# Mute Cuica
	79: 78,	# Open Cuica
}
@onready var sys_ex:GodotMIDIPlayerSysEx = GodotMIDIPlayerSysEx.new( )

var _midi_channel_prefix:int = 0
var _used_program_numbers:Array[int] = []
var channel_audio_effects:Array[GodotMIDIPlayerChannelAudioEffect] = []
var pan_power:float = 1.0
var reverb_power:float = 0.5
var chorus_power:float = 0.7
var prepared_to_play:bool = false
var is_audio_server_inited:bool = false
var _previous_time:float

# -----------------------------------------------------------------------------

signal changed_tempo( tempo )
signal appeared_text_event( text )
signal appeared_copyright( copyright )
signal appeared_track_name( channel_number, name )
signal appeared_instrument_name( channel_number, name )
signal appeared_lyric( lyric )
signal appeared_marker( marker )
signal appeared_cue_point( cue_point )
signal appeared_gm_system_on
signal appeared_gs_reset
signal appeared_xg_system_on
signal midi_event( channel, event )
signal note_on(channel, event, note, velocity)
signal looped
signal finished


func _ready( ):

	if OS.get_name( ) == "HTML5" or OS.is_debug_build( ):
		self.no_thread_mode = true

	if AudioServer.get_bus_index( self.midi_master_bus_name ) == -1:
		AudioServer.add_bus( -1 )
		var midi_master_bus_idx:int = AudioServer.get_bus_count( ) - 1
		AudioServer.set_bus_name( midi_master_bus_idx, self.midi_master_bus_name )
		AudioServer.set_bus_send( midi_master_bus_idx, self.bus )
		AudioServer.set_bus_volume_db( AudioServer.get_bus_index( self.midi_master_bus_name ), self.volume_db )

		for i in range( 0, 16 ):
			AudioServer.add_bus( -1 )
			var midi_channel_bus_idx:int = AudioServer.get_bus_count( ) - 1
			AudioServer.set_bus_name( midi_channel_bus_idx, self.midi_channel_bus_name % i )
			AudioServer.set_bus_send( midi_channel_bus_idx, self.midi_master_bus_name )
			AudioServer.set_bus_volume_db( midi_channel_bus_idx, 0.0 )

			var cae: = GodotMIDIPlayerChannelAudioEffect.new( )
			cae.ae_panner = AudioEffectPanner.new( )
			cae.ae_reverb = AudioEffectReverb.new( )
			cae.ae_reverb.wet = 0.03
			cae.ae_chorus = AudioEffectChorus.new( )
			cae.ae_chorus.wet = 0.0
			AudioServer.add_bus_effect( midi_channel_bus_idx, cae.ae_chorus )
			AudioServer.add_bus_effect( midi_channel_bus_idx, cae.ae_panner )
			AudioServer.add_bus_effect( midi_channel_bus_idx, cae.ae_reverb )
			self.channel_audio_effects.append( cae )
	else:
		for i in range( 0, 16 ):
			var midi_channel_bus_idx:int = 0
			for k in range( AudioServer.get_bus_count( ) ):
				if AudioServer.get_bus_name( k ) == self.midi_channel_bus_name % i:
					midi_channel_bus_idx = k
					break

			var cae: = GodotMIDIPlayerChannelAudioEffect.new( )
			for k in range( AudioServer.get_bus_effect_count( midi_channel_bus_idx ) ):
				var ae: = AudioServer.get_bus_effect( midi_channel_bus_idx, k )
				if ae is AudioEffectPanner:
					cae.ae_panner = ae
				elif ae is AudioEffectReverb:
					cae.ae_reverb = ae
				elif ae is AudioEffectChorus:
					cae.ae_chorus = ae
			self.channel_audio_effects.append( cae )
	self.is_audio_server_inited = true

	self.channel_status = []
	for i in range( max_channel ):
		var drum_track:bool = ( i == drum_track_channel )
		var _bank:int = 0
		if drum_track:
			_bank = Bank.drum_track_bank
		self.channel_status.append( GodotMIDIPlayerChannelStatus.new( i, _bank, drum_track ) )

	self.set_max_polyphony( self.max_polyphony )
	self.set_volume_db( self.volume_db )

	if self.playing:
		self.play( )


func _notification( what:int ):
	# 破棄時
	if what == NOTIFICATION_PREDELETE:
		self.thread_delete = true
		if self.thread != null:
			self.thread.wait_to_finish( )
			self.thread = null
		#再利用するので削除しないことにした
		#AudioServer.remove_bus( AudioServer.get_bus_index( self.midi_master_bus_name ) )
		#for i in range( 0, 16 ):
		#	AudioServer.remove_bus( AudioServer.get_bus_index( self.midi_channel_bus_name % i ) )


## Mutex Lock デバッグ用途
func _lock( callee:String ) -> void:
	# print( "locked by %s" % callee )
	self.mutex.lock( )


## Mutex Unlock (for debug purpose)
func _unlock( callee:String ) -> void:
	# print( "unlocked by %s" % callee )
	self.mutex.unlock( )


func _prepare_to_play( ) -> bool:
	self._lock( "prepare_to_play" )

	# ファイル読み込み
	if self.smf_data == null:
		var smf_reader: = SMF.new( )
		var result: = smf_reader.read_file( self.file )
		if result.error == OK:
			self.smf_data = result.data
			self.playing = true
		else:
			self.smf_data = null
			self.playing = false
			self._unlock( "prepare_to_play" )
			return false

	self.sys_ex.initialize( )
	self._init_track( )
	self._analyse_smf( )
	self._init_channel( )

	self._unlock( "prepare_to_play" )

	# サウンドフォントの再読み込みをさせる
	if not self.load_all_voices_from_soundfont:
		print("OOIS")
		self.set_soundfont( self.soundfont )

	return true


func _init_track( ) -> void:
	var track_status_events:Array[SMF.MIDIEventChunk] = []

	if len( self.smf_data.tracks ) == 1:
		track_status_events = self.smf_data.tracks[0].events
	else:
		# Mix multiple tracks to single track
		var tracks:Array[Dictionary] = []
		var track_id:int = 0
		for track in self.smf_data.tracks:
			tracks.append({"track_id": track_id, "pointer":0, "events":track.events, "length": len( track.events )})
			track_id += 1

		var time:int = 0
		var finished:bool = false
		while not finished:
			finished = true

			var next_time:int = 0x7fffffff
			for track in tracks:
				var p = track.pointer
				if track.length <= p: continue
				finished = false
				
				var e:SMF.MIDIEventChunk = track.events[p]
				var e_time:int = e.time
				if e_time == time:
					track_status_events.append( e )
					track.pointer += 1
					next_time = e_time
				elif e_time < next_time:
					next_time = e_time
			time = next_time

	self.last_position = track_status_events[len(track_status_events)-1].time
	self.track_status.events = track_status_events
	self.track_status.event_pointer = 0


func _analyse_smf( ) -> void:
	var channels:Array[Dictionary] = []
	for i in range( max_channel ):
		channels.append({ "number": i, "bank": 0, })
	self.loop_start = 0.0
	self._used_program_numbers = [0, Bank.drum_track_bank << 7]	# GrandPiano and Standard Kit

	for event_chunk in self.track_status.events:
		var channel_number:int = event_chunk.channel_number
		var channel = channels[channel_number]
		var event = event_chunk.event

		match event.type:
			SMF.MIDIEventType.program_change:
				var program_number:int = event.number | ( channel.bank << 7 )
				if not( event.number in self._used_program_numbers ):
					self._used_program_numbers.append( event.number )
				if not( program_number in self._used_program_numbers ):
					self._used_program_numbers.append( program_number )
			SMF.MIDIEventType.control_change:
				match event.number:
					SMF.control_number_bank_select_msb:
						if channel.number == drum_track_channel:
							channel.bank = Bank.drum_track_bank
						else:
							channel.bank = ( channel.bank & 0x7F ) | ( event.value << 7 )
					SMF.control_number_bank_select_lsb:
						if channel.number == drum_track_channel:
							channel.bank = Bank.drum_track_bank
						else:
							channel.bank = ( channel.bank & 0x3F80 ) | ( event.value & 0x7F )
					SMF.control_number_tkool_loop_point:
						self.loop_start = float( event_chunk.time )
			_:
				pass


func _init_channel( ) -> void:
	for channel in self.channel_status:
		channel.initialize( )


func play( from_position:float = 0.0 ) -> void:
	self._previous_time = 0.0
	if not self._prepare_to_play( ):
		self.playing = false
		return
	self.playing = true
	#Prologger code
	Global.initialize_playback_durations()
	if from_position == 0.0:
		self.position = 0.0
		self.track_status.event_pointer = 0
	else:
		self.seek( from_position )


func seek( to_position:float ) -> void:
	self._lock( "seek" )
	self._previous_time = 0.0
	self._stop_all_notes( )
	self.position = to_position

	var pointer:int = 0
	var new_position:int = int( floor( self.position ) )
	var length:int = len( self.track_status.events )
	for event_chunk in self.track_status.events:
		if new_position <= event_chunk.time:
			break

		var channel:GodotMIDIPlayerChannelStatus = self.channel_status[event_chunk.channel_number]
		var event:SMF.MIDIEvent = event_chunk.event

		match event.type:
			SMF.MIDIEventType.program_change:
				channel.program = ( event as SMF.MIDIEventProgramChange ).number
			SMF.MIDIEventType.control_change:
				var event_control_change:SMF.MIDIEventControlChange = event as SMF.MIDIEventControlChange
				self._process_track_event_control_change( channel, event_control_change.number, event_control_change.value )
			SMF.MIDIEventType.pitch_bend:
				self._process_pitch_bend( channel, ( event as SMF.MIDIEventPitchBend ).value )
			SMF.MIDIEventType.system_event:
				self._process_track_system_event( channel, event as SMF.MIDIEventSystemEvent )
			_:
				# 無視
				pass
		pointer += 1
	self.track_status.event_pointer = pointer
	self._unlock( "seek" )


func stop( ) -> void:
	self._lock( "stop" )

	self._previous_time = 0.0
	self._stop_all_notes( )
	self.playing = false

	self._unlock( "stop" )


func send_reset( ) -> void:
	self._process_track_sys_ex_reset_all_channels( )


func set_file( path:String ) -> void:
	file = path
	self.stop( )
	self.smf_data = null


func set_max_polyphony( mp:int ) -> void:
	self._lock( "set_max_polyphony" )

	max_polyphony = mp

	# 削除
	for asp in self.audio_stream_players:
		self.remove_child( asp )

	# 再作成
	self.audio_stream_players = []
	for i in range( max_polyphony ):
		var audio_stream_player:AudioStreamPlayerADSR = ADSR.instantiate( )
		audio_stream_player.mix_target = self.mix_target
		audio_stream_player.bus = self.bus
		self.add_child( audio_stream_player )
		self.audio_stream_players.append( audio_stream_player )

	self._unlock( "set_max_polyphony" )


func set_soundfont( path:String ) -> void:
	self._lock( "set_soundfont" )

	soundfont = path

	if path == null or path == "":
		self.bank = null
		self._unlock( "set_soundfont" )
		return

	var sf_reader: = SoundFont.new( )
	var result: = sf_reader.read_file( soundfont )

	if result.error == OK:
		self.bank = Bank.new( )
		if self.load_all_voices_from_soundfont:
			self.bank.read_soundfont( result.data )
		else:
			self.bank.read_soundfont( result.data, self._used_program_numbers )

	self._unlock( "set_soundfont" )


func set_smf_data( sd:SMF.SMFData ) -> void:
	smf_data = sd
	self.stop( )


func set_tempo( bpm:float ) -> void:
	tempo = bpm
	SignalManager.set_bpm.emit(bpm)
	self.seconds_to_timebase = tempo / 60.0
	self.timebase_to_seconds = 60.0 / tempo
	self.emit_signal( "changed_tempo", bpm )


func set_volume_db( vdb:float ) -> void:
	volume_db = vdb
	if not self.is_audio_server_inited:
		return

	self._lock( "set_volume_db" )
	AudioServer.set_bus_volume_db( AudioServer.get_bus_index( self.midi_master_bus_name ), self.volume_db )
	self._unlock( "set_volume_db" )


func _stop_all_notes( ) -> void:
	for audio_stream_player in self.audio_stream_players:
		audio_stream_player.hold = false
		audio_stream_player.note_stop( )

	for channel in self.channel_status:
		channel.note_on.clear( )


func _process( delta:float ) -> void:
	if self.no_thread_mode:
		self._sequence( delta )
	else:
		if self.thread == null or ( not self.thread.is_alive( ) ):
			self._lock( "_process" )
			if self.thread != null:
				self.thread.wait_to_finish( )
			self.thread = Thread.new( )
			self.thread.start(Callable(self,"_thread_process"))
			self._unlock( "_process" )


func _thread_process( ) -> void:
	var last_time:int = Time.get_ticks_usec( )

	while not self.thread_delete:
		self._lock( "_thread_process" )

		var current_time:int = Time.get_ticks_usec( )
		var delta:float = ( current_time - last_time ) / 1000000.0
		self._sequence( delta )

		self._unlock( "_thread_process" )

		last_time = current_time
		var msec:int = int( 1000 / self.sequence_per_seconds )
		OS.delay_msec( msec )


func _sequence( delta:float ) -> void:
	if delta <= 0.0:
		return

	if self.smf_data != null:
		if self.playing:
			self.position += float( self.smf_data.timebase ) * delta * self.seconds_to_timebase * self.play_speed
			self._process_track( )

	#for asp in self.audio_stream_players:
	#	asp._update_adsr( delta )



# TODO: where the magic happens

func _process_track( ) -> int:
	var track:GodotMIDIPlayerTrackStatus = self.track_status
	if track.events == null:
		return 0

	var length:int = len( track.events )

	if length <= track.event_pointer:
		if self.loop:
			var diff:float = self.position - track.events[len( track.events ) - 1].time
			self.seek( self.loop_start )
			self.emit_signal( "looped" )
			self.position += diff
		else:
			self.playing = false
			self.emit_signal( "finished" )
			return 0

	var execute_event_count:int = 0
	var current_position:int = int( ceil( self.position ) )

	while track.event_pointer < length:
		var event_chunk:SMF.MIDIEventChunk = track.events[track.event_pointer]
		if current_position <= event_chunk.time:
			break
		track.event_pointer += 1
		execute_event_count += 1

		var channel:GodotMIDIPlayerChannelStatus = self.channel_status[event_chunk.channel_number]
		var event:SMF.MIDIEvent = event_chunk.event

		self.emit_signal( "midi_event", channel, event )

		match event.type:
			SMF.MIDIEventType.note_off:
				self._process_track_event_note_off( channel, ( event as SMF.MIDIEventNoteOff ).note )
			SMF.MIDIEventType.note_on:
				var event_note_on:SMF.MIDIEventNoteOn = event as SMF.MIDIEventNoteOn
				self._process_track_event_note_on( channel, event_note_on.note, event_note_on.velocity )
				#Custom prologger signal
				SignalManager.note_on.emit(channel.number, event_note_on.note, event_chunk.time)
			SMF.MIDIEventType.program_change:
				channel.program = ( event as SMF.MIDIEventProgramChange ).number
			SMF.MIDIEventType.control_change:
				var event_control_change:SMF.MIDIEventControlChange = event as SMF.MIDIEventControlChange
				self._process_track_event_control_change( channel, event_control_change.number, event_control_change.value )
			SMF.MIDIEventType.pitch_bend:
				self._process_pitch_bend( channel, ( event as SMF.MIDIEventPitchBend ).value )
			SMF.MIDIEventType.system_event:
				self._process_track_system_event( channel, event as SMF.MIDIEventSystemEvent )
			_:
				# 無視
				pass

	return execute_event_count


func receive_raw_midi_message( input_event:InputEventMIDI ) -> void:
	var channel:GodotMIDIPlayerChannelStatus = self.channel_status[input_event.channel]

	match input_event.message:
		MIDI_MESSAGE_NOTE_OFF:
			self._process_track_event_note_off( channel, input_event.pitch )
		MIDI_MESSAGE_NOTE_ON:
			self._process_track_event_note_on( channel, input_event.pitch, input_event.velocity )
		MIDI_MESSAGE_AFTERTOUCH:
			# polyphonic key pressure プレイヤー自体が未実装
			pass
		MIDI_MESSAGE_CONTROL_CHANGE:
			self._process_track_event_control_change( channel, input_event.controller_number, input_event.controller_value )
		MIDI_MESSAGE_PROGRAM_CHANGE:
			channel.program = input_event.instrument
		MIDI_MESSAGE_CHANNEL_PRESSURE:
			# channel pressure プレイヤー自体が未実装
			pass
		MIDI_MESSAGE_PITCH_BEND:
			var fixed_pitch:int = input_event.pitch
			self._process_pitch_bend( channel, fixed_pitch )
		0x0F:
			# InputEventMIDIはMIDI System Eventを飛ばしてこない！
			pass
		_:
			print( "unknown message %x" % input_event.message )
			breakpoint


func _process_pitch_bend( channel:GodotMIDIPlayerChannelStatus, value:int ) -> void:
	var pb:float = float( value ) / 8192.0 - 1.0
	var pbs:float = channel.rpn.pitch_bend_sensitivity
	channel.pitch_bend = pb

	self._apply_channel_pitch_bend( channel )


func _process_track_event_note_off( channel:GodotMIDIPlayerChannelStatus, note:int, force_disable_hold:bool = false ) -> void:
	var track_key_shift:int = self.key_shift if not channel.drum_track else 0
	var key_number:int = note + track_key_shift
	if channel.note_on.erase( key_number ):
		pass

	if channel.drum_track: return

	for asp in self.audio_stream_players:
		if asp.channel_number == channel.number and asp.key_number == key_number:
			if force_disable_hold: asp.hold = false
			asp.start_release( )


func _process_track_event_note_on( channel:GodotMIDIPlayerChannelStatus, note:int, velocity:int ) -> void:
	if channel.mute: return
	if self.bank == null: return

	var track_key_shift:int = self.key_shift if not channel.drum_track else 0
	var key_number:int = note + track_key_shift
	var preset:Bank.Preset = self.bank.get_preset( channel.program, channel.bank )
	if preset.instruments[key_number] == null:
		return
	var instruments:Array = preset.instruments[key_number]	# Array[Bank.Instrument]

	var assign_group:int = key_number
	if channel.drum_track:
		if key_number in self.drum_assign_groups:
			assign_group = self.drum_assign_groups[key_number]

	if channel.note_on.has( assign_group ):
		self._process_track_event_note_off( channel, note, true )

	var polyphony_count:int = 0
	for instrument in instruments:
		if instrument.vel_range_min <= velocity and velocity <= instrument.vel_range_max:
			polyphony_count += 1

	for instrument in instruments:
		if instrument.vel_range_min <= velocity and velocity <= instrument.vel_range_max:
			var note_player:AudioStreamPlayerADSR = self._get_idle_player( )
			if note_player != null:
				note_player.channel_number = channel.number
				note_player.key_number = key_number
				note_player.bus = self.midi_channel_bus_name % channel.number
				note_player.velocity = velocity
				note_player.pitch_bend = channel.pitch_bend
				note_player.pitch_bend_sensitivity = channel.rpn.pitch_bend_sensitivity
				note_player.modulation = channel.modulation
				note_player.modulation_sensitivity = channel.rpn.modulation_sensitivity
				note_player.polyphony_count = float( polyphony_count )
				note_player.note_stop( )
				note_player.set_instrument( instrument )
				note_player.hold = channel.hold
				note_player.note_play( 0.0 )

	channel.note_on[ assign_group ] = true


func _process_track_event_control_change( channel:GodotMIDIPlayerChannelStatus, number:int, value:int ) -> void:
	match number:
		SMF.control_number_volume:
			channel.volume = float( value ) / 127.0
			self._apply_channel_volume( channel )
		SMF.control_number_modulation:
			channel.modulation = float( value ) / 127.0
			self._apply_channel_modulation( channel )
		SMF.control_number_expression:
			channel.expression = float( value ) / 127.0
			self._apply_channel_volume( channel )
		SMF.control_number_reverb_send_level:
			channel.reverb = float( value ) / 127.0
			self._apply_channel_reverb( channel )
		SMF.control_number_tremolo_depth:
			channel.tremolo = float( value ) / 127.0
		SMF.control_number_chorus_send_level:
			channel.chorus = float( value ) / 127.0
			self._apply_channel_chorus( channel )
		SMF.control_number_celeste_depth:
			channel.celeste = float( value ) / 127.0
		SMF.control_number_phaser_depth:
			channel.phaser = float( value ) / 127.0
		SMF.control_number_pan:
			channel.pan = float( value ) / 127.0
			self._apply_channel_pan( channel )
		SMF.control_number_hold:
			channel.hold = 64 <= value
			self._apply_channel_hold( channel )
		SMF.control_number_portamento:
			channel.portamento = float( value ) / 127.0
		SMF.control_number_sostenuto:
			channel.sostenuto = float( value ) / 127.0
		SMF.control_number_freeze:
			channel.freeze = float( value ) / 127.0
		SMF.control_number_bank_select_msb:
			if channel.drum_track:
				channel.bank = Bank.drum_track_bank
			else:
				if value == 1:
					# SoundFont的にMSB = 1はドラムトラックになっているので避ける
					value = 0
				channel.bank = ( channel.bank & 0x7F ) | ( value << 7 )
		SMF.control_number_bank_select_lsb:
			if channel.drum_track:
				channel.bank = Bank.drum_track_bank
			else:
				channel.bank = ( channel.bank & 0x3F80 ) | ( value & 0x7F )
		SMF.control_number_rpn_lsb:
			channel.rpn.selected_lsb = value
		SMF.control_number_rpn_msb:
			channel.rpn.selected_msb = value
		SMF.control_number_data_entry_msb:
			self._process_track_event_control_change_rpn_data_entry_msb( channel, value )
		SMF.control_number_data_entry_lsb:
			self._process_track_event_control_change_rpn_data_entry_lsb( channel, value )
		SMF.control_number_all_sound_off:
			self._stop_all_notes( )
		SMF.control_number_all_note_off:
			for asp in self.audio_stream_players:
				if asp.channel_number == channel.number:
					asp.hold = false
					asp.start_release( )
					if channel.note_on.erase( asp.key_number ):
						pass
		_:
			# 無視
			pass


func update_channel_status( channel:GodotMIDIPlayerChannelStatus ) -> void:
	self._apply_channel_volume( channel )
	self._apply_channel_pitch_bend( channel )
	self._apply_channel_modulation( channel )
	self._apply_channel_hold( channel )
	self._apply_channel_reverb( channel )
	self._apply_channel_chorus( channel )
	self._apply_channel_pan( channel )


func _apply_channel_volume( channel:GodotMIDIPlayerChannelStatus ) -> void:
	AudioServer.set_bus_volume_db( AudioServer.get_bus_index( self.midi_channel_bus_name % channel.number ), linear_to_db( channel.volume * channel.expression ) )


func _apply_channel_pitch_bend( channel:GodotMIDIPlayerChannelStatus ) -> void:
	var pbs:float = channel.rpn.pitch_bend_sensitivity
	var pb:float = channel.pitch_bend
	for asp in self.audio_stream_players:
		if asp.channel_number == channel.number and ( not asp.request_release ):
			asp.pitch_bend_sensitivity = pbs
			asp.pitch_bend = pb


func _apply_channel_reverb( channel:GodotMIDIPlayerChannelStatus ) -> void:
	self.channel_audio_effects[channel.number].ae_reverb.wet = channel.reverb * self.reverb_power


func _apply_channel_chorus( channel:GodotMIDIPlayerChannelStatus ) -> void:
	self.channel_audio_effects[channel.number].ae_chorus.wet = channel.chorus * self.chorus_power


func _apply_channel_pan( channel:GodotMIDIPlayerChannelStatus ):
	self.channel_audio_effects[channel.number].ae_panner.pan = ( ( channel.pan * 2 ) - 1.0 ) * self.pan_power


func _apply_channel_modulation( channel:GodotMIDIPlayerChannelStatus ) -> void:
	var ms:float = channel.rpn.modulation_sensitivity
	var m:float = channel.modulation
	for asp in self.audio_stream_players:
		if asp.channel_number == channel.number and ( not asp.request_release ):
			asp.modulation_sensitivity = ms
			asp.modulation = m


func _apply_channel_hold( channel:GodotMIDIPlayerChannelStatus ) -> void:
	var hold:bool = channel.hold
	for asp in self.audio_stream_players:
		if asp.channel_number == channel.number:
			asp.hold = hold and ( not asp.request_release )


func _process_track_event_control_change_rpn_data_entry_msb( channel:GodotMIDIPlayerChannelStatus, value:int ) -> void:
	match channel.rpn.selected_msb:
		0:
			match channel.rpn.selected_lsb:
				SMF.rpn_control_number_pitch_bend_sensitivity:
					channel.rpn.pitch_bend_sensitivity_msb = float( value )
					if 12 < channel.rpn.pitch_bend_sensitivity_msb: channel.rpn.pitch_bend_sensitivity_msb = 12
					channel.rpn.pitch_bend_sensitivity = channel.rpn.pitch_bend_sensitivity_msb + channel.rpn.pitch_bend_sensitivity_lsb / 100.0
				SMF.rpn_control_number_modulation_sensitivity:
					channel.rpn.modulation_sensitivity_msb = float( value )
					channel.rpn.modulation_sensitivity = channel.rpn.modulation_sensitivity_msb + channel.rpn.modulation_sensitivity_lsb / 100.0
				_:
					pass
		_:
			pass


func _process_track_event_control_change_rpn_data_entry_lsb( channel:GodotMIDIPlayerChannelStatus, value:int ) -> void:
	match channel.rpn.selected_msb:
		0:
			match channel.rpn.selected_lsb:
				SMF.rpn_control_number_pitch_bend_sensitivity:
					channel.rpn.pitch_bend_sensitivity_lsb = float( value )
					channel.rpn.pitch_bend_sensitivity = channel.rpn.pitch_bend_sensitivity_msb + channel.rpn.pitch_bend_sensitivity_lsb / 100.0
				SMF.rpn_control_number_modulation_sensitivity:
					channel.rpn.modulation_sensitivity_lsb = float( value )
					channel.rpn.modulation_sensitivity = channel.rpn.modulation_sensitivity_msb + channel.rpn.modulation_sensitivity_lsb / 100.0
				_:
					pass
		_:
			pass


func _process_track_system_event( channel:GodotMIDIPlayerChannelStatus, event:SMF.MIDIEventSystemEvent ) -> void:
	match event.args.type:
		SMF.MIDISystemEventType.set_tempo:
			self.tempo = 60000000.0 / float( event.args.bpm )
		SMF.MIDISystemEventType.text_event:
			self.emit_signal( "appeared_text_event", event.args.text )
		SMF.MIDISystemEventType.copyright:
			self.emit_signal( "appeared_copyright", event.args.text )
		SMF.MIDISystemEventType.track_name:
			self.emit_signal( "appeared_track_name", self._midi_channel_prefix, event.args.text )
			self.channel_status[self._midi_channel_prefix].track_name = event.args.text
		SMF.MIDISystemEventType.instrument_name:
			self.emit_signal( "appeared_instrument_name", self._midi_channel_prefix, event.args.text )
			self.channel_status[self._midi_channel_prefix].instrument_name = event.args.text
		SMF.MIDISystemEventType.lyric:
			self.emit_signal( "appeared_lyric", event.args.text )
		SMF.MIDISystemEventType.marker:
			self.emit_signal( "appeared_marker", event.args.text )
		SMF.MIDISystemEventType.cue_point:
			self.emit_signal( "appeared_cue_point", event.args.text )
		SMF.MIDISystemEventType.midi_channel_prefix:
			self._midi_channel_prefix = event.args.channel
		SMF.MIDISystemEventType.sys_ex:
			self._process_track_sys_ex( channel, event.args )
		SMF.MIDISystemEventType.divided_sys_ex:
			self._process_track_sys_ex( channel, event.args )
		_:
			# 無視
			pass


func _process_track_sys_ex( channel:GodotMIDIPlayerChannelStatus, event_args ) -> void:
	# ==で比較するために変換しておく
	var event_data: = Array( event_args.data )
	var event_data_without_first_data: = event_data.slice( 1, len( event_args.data ) )

	match event_args.manifacture_id:
		SMF.manufacture_id_universal_nopn_realtime_sys_ex:
			if event_data == [0x7f,0x09,0x01,0xf7]:
				self.sys_ex.gm_system_on = true
				self.emit_signal( "appeared_gm_system_on" )
				self._process_track_sys_ex_reset_all_channels( )
		SMF.manufacture_id_roland_corporation:
			if event_data_without_first_data == [0x42,0x12,0x40,0x00,0x7f,0x00,0x41,0xf7]:
				self.sys_ex.gs_reset = true
				self.emit_signal( "appeared_gs_reset" )
				self._process_track_sys_ex_reset_all_channels( )
		SMF.manufacture_id_yamaha_corporation:
			if event_data_without_first_data == [0x4c,0x00,0x00,0x7E,0x00,0xf7]:
				self.sys_ex.xg_system_on = true
				self.emit_signal( "appeared_xg_system_on" )
				self._process_track_sys_ex_reset_all_channels( )


func _process_track_sys_ex_reset_all_channels( ) -> void:
	for audio_stream_player in self.audio_stream_players:
		audio_stream_player.hold = false
		audio_stream_player.start_release( )

	for channel in self.channel_status:
		channel.initialize( )

		AudioServer.set_bus_volume_db( AudioServer.get_bus_index( self.midi_channel_bus_name % channel.number ), linear_to_db( float( channel.volume * channel.expression ) ) )
		self.channel_audio_effects[channel.number].ae_reverb.wet = channel.reverb * self.reverb_power
		self.channel_audio_effects[channel.number].ae_chorus.wet = channel.chorus * self.chorus_power
		self.channel_audio_effects[channel.number].ae_panner.pan = ( ( channel.pan * 2 ) - 1.0 ) * self.pan_power


func _get_idle_player( ) -> AudioStreamPlayerADSR:
	var released_audio_stream_player:AudioStreamPlayerADSR = null
	var minimum_volume_db:float = -80.0
	# var releasing_audio_stream_player:AudioStreamPlayerADSR = null
	var oldest_audio_stream_player:AudioStreamPlayerADSR = null
	var oldest:float = -1.0

	for audio_stream_player in self.audio_stream_players:
		if not audio_stream_player.playing:
			return audio_stream_player
		if audio_stream_player.releasing and audio_stream_player.volume_db < minimum_volume_db:
			released_audio_stream_player = audio_stream_player
			minimum_volume_db = audio_stream_player.volume_db
		if oldest < audio_stream_player.using_timer:
			oldest_audio_stream_player = audio_stream_player
			oldest = audio_stream_player.using_timer

	if released_audio_stream_player != null:
		return released_audio_stream_player

	return oldest_audio_stream_player


func get_now_playing_polyphony( ) -> int:
	var polyphony:int = 0
	for audio_stream_player in self.audio_stream_players:
		if audio_stream_player.playing:
			polyphony += 1
	return polyphony
