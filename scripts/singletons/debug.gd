extends Node


# Whether or not to enable debug features.
# Debug will always be on in Debug exports, but can also be forced on.
const DEBUG_ENABLED := false

# The prefix to display before each debug log.
const DEBUG_PREFIX := "DEBUG: "


# The speed to move at while noclipping.
const NOCLIP_SPEED := 100.0


# SFX
const SELECT_SFX := preload("res://assets/sounds/select.wav")


var noclip_enabled := false:
	set = _set_noclip_enabled


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build() and not DEBUG_ENABLED:
		queue_free()
		return
	
	print(DEBUG_PREFIX + "Debug mode is enabled.")

func _unhandled_input(event):
	if event is InputEventKey:
		_debug_keys(event)

func _process(delta):
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
			KEY_F9:
				Engine.time_scale -= 0.1
				print(DEBUG_PREFIX + "Set engine time scale to %s." % Engine.time_scale)
			KEY_F10:
				Engine.time_scale += 0.1
				print(DEBUG_PREFIX + "Set engine time scale to %s." % Engine.time_scale)
			KEY_F6:
				get_tree().reload_current_scene()
				print(DEBUG_PREFIX + "Reloaded current scene.")


func _set_noclip_enabled(enabled):
	noclip_enabled = enabled
	
	print(DEBUG_PREFIX + "Noclip set to %s." % noclip_enabled)
	
	for player in get_tree().get_nodes_in_group("players"):
		if not noclip_enabled:
			player.set_physics_process(true)
	
	Audio.play_sfx(SELECT_SFX)
