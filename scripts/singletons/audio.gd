extends Node


const MUSIC_PATH = "res://assets/music/"
const MUSIC_PLAYERS = 2


var mus_players: Array[AudioStreamPlayer] = []
var sfx_player := AudioStreamPlayer.new()


var _step_crochet: float
var _current_step: float

var song: String
var song_speed: float
var song_position: float

var stopped_position: float

var _unmute_queued = false
var _sound_forced = false


func _ready():
	sfx_player.bus = "SFX"
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)
	
	for i in MUSIC_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		
		mus_players.append(player)
	
	sfx_player.finished.connect(_on_sfx_finished)
	
func _process(_delta):
	if len(mus_players) > 0:
		var main_mus_stream = mus_players[0]
		song_position = main_mus_stream.get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
	
	_update_step()


func play_music(music_name: String, speed: float = 1.0, position: float = 0.0):
	var music_path = MUSIC_PATH + music_name + "/music_" + music_name
	song_position = 0.0
	
	var i = 0
	for player in mus_players:
		song = music_name
		song_speed = speed
		
		player.stream = load(music_path + "_%s.ogg" % (i + 1))
		player.pitch_scale = speed
		player.play(position)
		
		if i == 0:
			_update_bpm(player.stream.get_bpm())
		
		i += 1

func stop_music():
	stopped_position = song_position
	
	for player in mus_players:
		player.stop()

func resume_music():
	for player in mus_players:
		if player.playing:
			return
	
	if song == "":
		return
	
	play_music(song, song_speed, stopped_position)


func play_sfx(audio: AudioStream, force := false):
	if _sound_forced:
		return
	
	sfx_player.stream = audio
	sfx_player.play()
	
	if force:
		_sound_forced = true
	
	if Settings.mute_music_channel_on_sfx:
		_toggle_music_channels(false)


func _toggle_music_channels(enabled: bool):
	var skipped_first = false
	for player in mus_players:
		if not skipped_first:
			skipped_first = true
			continue
		
		var volume = -80
		if enabled:
			volume = 0
		
		player.volume_db = volume


func _update_bpm(bpm: int):
	var crochet = (60.0 / bpm) * 1000.0
	_step_crochet = crochet / 4

func _update_step():
	if _step_crochet == 0:
		return
	
	var last_step = _current_step
	_current_step = floor((song_position * 1000) / _step_crochet)
	
	if last_step != _current_step:
		_on_step_changed()


func _on_sfx_finished():
	_unmute_queued = true
	_sound_forced = false

func _on_step_changed():
	if _unmute_queued:
		_toggle_music_channels(true)
		_unmute_queued = false
