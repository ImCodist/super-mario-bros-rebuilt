@icon("res://assets/editor/icons/level.png")
class_name Level
extends Node2D


enum CameraTypes {
	RIGHT_ONLY,
	LEFT_ONLY,
	FREE,
	STATIC
}


const HUD_SCENE = preload("res://scenes/game/hud/hud.tscn")
const POINTS_SCENE = preload("res://scenes/effects/points_effect/points_effect.tscn")

const SFX_TIME_WARNING = preload("res://assets/sounds/time_warning.wav")


@export_group("Level Data")
@export var world := 1
@export var level := 1
@export var substage := false
@export var underwater := false
@export var timer := 400
@export var use_timer := true

@export_group("Level Display")
@export var level_theme: LevelTheme = preload("res://assets/resources/themes/overworld.tres")

@export_group("Other")
@export var can_pause := true
@export var camera_type := CameraTypes.RIGHT_ONLY:
	set = _set_camera_type
@export var kill_on_fall := true


var hud: CanvasLayer
var score_canvas: CanvasLayer

var camera: Camera2D
var camera_collision: CollisionShape2D

var background: ColorRect


var score := 0
var coins := 0
var lives := 3


var time_warning_happened := false

var force_timer_stop := false

var timer_timer := 0.0

var screen_size := Main.SCREEN_SIZE


func _ready():
	# Add to the levels group.
	add_to_group("levels")
	
	# Create important nodes. eg. background / hud
	_create_nodes()
	
	# Play the stages song.
	if level_theme.music != "":
		Audio.play_music(level_theme.music)
	
	# Update players.
	for player in get_tree().get_nodes_in_group("players"):
		if underwater:
			player.swimming = true
		
		player.powerup_colors = level_theme.powerup_colors
	
	# Update objects.
	_set_camera_type(camera_type)
	
	# Set the tilesets for the level maps.
	for child in get_children():
		if child is LevelMap:
			child.tile_set = level_theme.tileset
			child.z_index = -2
	
	get_tree().call_group("_sprite_themed", "update_sprite")

func _process(delta):
	if get_tree().paused:
		return
	
	if not Main.game_paused and not force_timer_stop:
		timer_timer += delta
		
		if timer_timer >= 0.5 and timer > 0:
			timer -= 1
			timer_timer = 0
			
			if timer <= 99 and not time_warning_happened:
				_start_time_warning()
			if timer <= 0:
				for player in get_tree().get_nodes_in_group("players"):
					player.die()
				
				Audio.stop_music()
	
	if kill_on_fall:
		for player in get_tree().get_nodes_in_group("players"):
			if player.position.y >= screen_size.y + 32:
				player.die(false)
			
	_update_camera(delta)
	_update_hud()


func add_points(points: int, spawn_hud := false, spawn_position := Vector2.ZERO):
	score += points
	
	if spawn_hud:
		spawn_points(spawn_position, points)

func spawn_points(spawn_position: Vector2, points: int):
	var points_scene = POINTS_SCENE.instantiate()
	
	var offset = (camera.position - (get_viewport_rect().size / 2))
	if offset.x < 0:
		offset.x = 0
	
	offset.y *= 2
	
	points_scene.position = spawn_position - offset
	points_scene.points = points
	
	score_canvas.add_child(points_scene)


func _create_nodes():
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	
	score_canvas = CanvasLayer.new()
	score_canvas.layer = 1
	add_child(score_canvas)
	
	var background_canvas = CanvasLayer.new()
	background_canvas.layer = -15
	add_child(background_canvas)
	
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_canvas.add_child(background)
	
	_create_camera()
	
	_set_background_color(level_theme.background_color)


func _start_time_warning():
	var previous_position = Audio.song_position
	
	Audio.stop_music()
	Audio.play_sfx(SFX_TIME_WARNING, true)
	
	time_warning_happened = true
	
	await Audio.sfx_player.finished
	
	if level_theme.music != "":
		Audio.play_music(level_theme.music, 1.5, previous_position)


func _set_background_color(value: Color):
	background.color = value


func _create_camera():
	camera = Camera2D.new()
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.position = screen_size / 2
	camera.limit_bottom = int(screen_size.y)
	add_child(camera)
	
	for player in get_tree().get_nodes_in_group("players"):
		var offset = 0
		if camera_type == CameraTypes.RIGHT_ONLY:
			offset = 16
		elif camera_type == CameraTypes.LEFT_ONLY:
			offset = -16
		
		camera.position.x = player.position.x + offset
		break
	
	var camera_body := StaticBody2D.new()
	camera_body.set_collision_layer_value(1, false)
	camera_body.set_collision_layer_value(2, true)
	camera_body.set_collision_mask_value(1, false)
	camera.add_child(camera_body)
	
	camera_collision = CollisionShape2D.new()
	var collision_shape := RectangleShape2D.new()
	collision_shape.size = Vector2(16, screen_size.y * 4)
	camera_collision.shape = collision_shape
	camera_body.add_child(camera_collision)

func _update_camera(delta):
	if camera == null:
		return
	
	if Main.game_paused:
		return
	
	if camera_type != CameraTypes.STATIC:
		for player in get_tree().get_nodes_in_group("players"):
			var camera_first_offset = screen_size.x / 6
			var camera_second_offset = 8
			
			# Right Only Movement
			if camera_type == CameraTypes.RIGHT_ONLY and camera.position.x - camera_first_offset <= player.position.x:
				if player.velocity.x > 0:
					if camera.position.x - camera_second_offset >= player.position.x:
						camera.position.x += (player.velocity.x * delta) / 2
					else:
						camera.position.x += player.velocity.x * delta
			
			# Left Only Movement
			if camera_type == CameraTypes.LEFT_ONLY and camera.position.x + camera_first_offset >= player.position.x:
				if player.velocity.x < 0:
					if camera.position.x - camera_second_offset <= player.position.x:
						camera.position.x += (player.velocity.x * delta) / 2
					else:
						camera.position.x += player.velocity.x * delta
			
			# Free Camera Movement
			if camera_type == CameraTypes.FREE:
				var threshold = 20
				var vertical_threshold = 35
				
				if camera.position.x - threshold >= player.position.x:
					camera.position.x = player.position.x + threshold
				elif camera.position.x + threshold <= player.position.x:
					camera.position.x = player.position.x - threshold
				
				if camera.position.y - vertical_threshold >= player.position.y:
					camera.position.y = player.position.y + vertical_threshold
				elif camera.position.y + vertical_threshold <= player.position.y:
					camera.position.y = player.position.y - vertical_threshold
	
	# Collision position.
	#var viewport_size := get_viewport_rect().size
	match camera_type:
		CameraTypes.LEFT_ONLY:
			camera_collision.position.x = (screen_size.x / 2) + 8
		_:
			camera_collision.position.x = -(screen_size.x / 2) - 8
			if camera.position.x < (screen_size.x / 2):
				camera_collision.position.x += (screen_size.x / 2) - camera.position.x
	
	# Disable the collision if not needed.
	camera_collision.disabled = (
		camera_type != CameraTypes.RIGHT_ONLY 
		and camera_type != CameraTypes.LEFT_ONLY
	)
	
	# Change the left limit.
	if camera_type != CameraTypes.LEFT_ONLY:
		camera.limit_left = 0
	else:
		camera.limit_left = -1000000000
	
	# Round the cameras position to prevent weird graphic fuck ups.
	#camera.offset = camera.position.round() - camera.position


func _update_hud():
	for player in get_tree().get_nodes_in_group("players"):
		if player.character != null:
			hud.player_label.text = player.character.name
	
	hud.set_timer_text(timer, use_timer)
	hud.set_world_text(world, level)
	hud.set_score_text(score)
	hud.set_coin_text(coins)


func _set_camera_type(new_camera_type):
	camera_type = new_camera_type
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		match camera_type:
			CameraTypes.RIGHT_ONLY:
				enemy.delete_direction = -1
			CameraTypes.LEFT_ONLY:
				enemy.delete_direction = 1


func from_previous_level(level_scene: Level):
	score = level_scene.score
	coins = level_scene.coins
	lives = level_scene.lives
