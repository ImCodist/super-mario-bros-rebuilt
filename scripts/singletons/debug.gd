extends Node


# The levels of debug log's used to filter important data.
enum LogLevel {
	NONE,
	USEFUL,
	ALL,
}


# Whether or not to enable debug features.
# Debug will always be on in Debug exports, but can also be forced on.
const DEBUG_ENABLED := false


# The prefix to display before each debug log.
const DEBUG_LOG_PREFIX := "[[color=yellow]DEBUG[/color]] "


# The speed to move at while noclipping.
const NOCLIP_SPEED := 100.0


# Resources.
const SELECT_SFX := preload("res://assets/sounds/select.wav")


var noclip_enabled := false:
	set = _set_noclip_enabled

var current_log_level: LogLevel = LogLevel.ALL


var enabled := true


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build() and not DEBUG_ENABLED:
		enabled = false
		return
	
	log_text("Debug mode is enabled.", LogLevel.USEFUL)

func _unhandled_input(event):
	if not enabled:
		return
	
	if event is InputEventKey:
		_debug_keys(event)

func _process(delta):
	if not enabled:
		return
	
	if noclip_enabled:
		var level := Main.get_level()
		
		var move = Vector2(
			Input.get_axis("left", "right"),
			Input.get_axis("up", "down")
		)
		
		var first_player := true
		for player in get_tree().get_nodes_in_group("players"):
			var speed = NOCLIP_SPEED
			if Input.is_action_pressed("b"):
				speed *= 2.0
			if Input.is_action_pressed("a"):
				speed *= 2.0
			
			player.position += (move.normalized() * speed) * delta
			player.velocity = Vector2.ZERO
			
			player.sprite.play("jump")
			player.modulate.a = 0.5 - (sin(get_tree().get_frame() / 10.0) / 5.0)
			player.set_physics_process(false)
			
			if first_player:
				if level != null:
					level.camera.position.x = lerp(level.camera.position.x, player.position.x, delta * 20)
				
				first_player = false


func _debug_keys(event: InputEventKey):
	if event.is_pressed():
		match event.keycode:
			KEY_F1:
				noclip_enabled = not noclip_enabled
			KEY_F7:
				get_tree().reload_current_scene()
				log_text("Reloaded current scene.")
			KEY_F9:
				Engine.time_scale -= 0.05
				log_text("Set engine time scale to %s." % Engine.time_scale)
			KEY_F10:
				Engine.time_scale += 0.05
				log_text("Set engine time scale to %s." % Engine.time_scale)
			KEY_F11:
				Engine.time_scale = 1.0
				await get_tree().process_frame
				Engine.time_scale = 0.0
				log_text("Paused on frame %s." % get_tree().get_frame())
			KEY_F12:
				Engine.time_scale = 1.0
				log_text("Reset engine time scale to %s." % Engine.time_scale)


func _set_noclip_enabled(new_enabled):
	noclip_enabled = new_enabled
	
	if not enabled:
		return
	
	log_text("Noclip set to %s." % noclip_enabled)
	
	for player in get_tree().get_nodes_in_group("players"):
		if not noclip_enabled:
			player.modulate.a = 1.0
			player.set_physics_process(true)
	
	Audio.play_sfx(SELECT_SFX)


func log_text(text: String, log_level: LogLevel = LogLevel.USEFUL):
	if current_log_level < log_level:
		return
	
	print_rich(DEBUG_LOG_PREFIX + text)
