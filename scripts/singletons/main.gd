extends Node


const EMU_HUD = preload("res://scenes/other/emu_hud/emu_hud.tscn")

const SFX_PAUSE = preload("res://assets/sounds/pause.wav")


var og_title = ProjectSettings.get_setting("application/config/name", "")

var emu_hud_enabled = true
var emu_hud: CanvasLayer

var turbo_toggle = false

var pause_sound_playing := false
var pause_music_was_playing := true


var game_paused := false


func _ready():
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if emu_hud_enabled:
		emu_hud = EMU_HUD.instantiate()
		add_child(emu_hud)


func _unhandled_input(event):
	if pause_sound_playing:
		return
	
	var can_pause = true
	for level in get_tree().get_nodes_in_group("levels"):
		can_pause = level.can_pause
	
	if not can_pause:
		return
	
	if event.is_action_pressed("start"):
		get_tree().paused = not get_tree().paused
		Audio.play_sfx(SFX_PAUSE, true)
		
		if not get_tree().paused:
			pause_music_was_playing = Audio.music_is_playing()
			Audio.stop_music()
		
		pause_sound_playing = true
		await Audio.sfx_player.finished
		pause_sound_playing = false
		
		if not get_tree().paused and pause_music_was_playing:
			Audio.resume_music()

func _physics_process(_delta):
	var title = og_title + " FPS: %s" % Engine.get_frames_per_second()
	get_window().title = title
	
	turbo_toggle = not turbo_toggle
	_do_turbo_action("turbo_a", "a")
	_do_turbo_action("turbo_b", "b")


func get_level() -> Level:
	if not is_inside_tree():
		return null
	
	for level in get_tree().get_nodes_in_group("levels"):
		return level
	
	return null


func _do_turbo_action(action, turbo_action):
	if Input.is_action_pressed(action):
		if turbo_toggle:
			Input.action_press(turbo_action)
		else:
			Input.action_release(turbo_action)
	
	if Input.is_action_just_released(action):
		Input.action_release(turbo_action)

