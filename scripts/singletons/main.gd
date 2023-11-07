extends Node


const SCREEN_SIZE = Vector2(256, 224)

const SFX_PAUSE = preload("res://assets/sounds/pause.wav")

const LEVEL_INTRO_SCENE := preload("res://scenes/other/level_intro/level_intro.tscn")


var og_title = ProjectSettings.get_setting("application/config/name", "")

var turbo_toggle = false

var pause_sound_playing := false
var pause_music_was_playing := true


var game_paused := false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()

func _unhandled_input(event):
	_pause_logic(event)

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

func _pause_logic(event: InputEvent):
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


func change_scene(scene):
	var final_scene = scene
	if final_scene is String:
		final_scene = load(scene)
	if final_scene is PackedScene:
		final_scene = final_scene.instantiate()
	
	if get_tree().current_scene != null:
		get_tree().current_scene.queue_free()
		await get_tree().current_scene.tree_exited
	
	get_tree().root.add_child(final_scene)
	get_tree().set_current_scene(final_scene)

func change_level(scene, inherit_previous_level = true, no_level_intro = false):
	var level_scene = scene
	if level_scene is String:
		level_scene = load(scene)
	if level_scene is PackedScene:
		level_scene = level_scene.instantiate()
	if not level_scene is Level:
		print("Level scene is not of type Level.")
		return
	
	var previous_level = get_tree().current_scene
	if not previous_level is Level:
		previous_level = null
	if not inherit_previous_level:
		previous_level = null
	
	if previous_level != null:
		level_scene.from_previous_level(previous_level)
	
	if no_level_intro:
		change_scene(level_scene)
	else:
		var level_intro = LEVEL_INTRO_SCENE.instantiate()
		level_intro.level_scene = level_scene
		change_scene(level_intro)
