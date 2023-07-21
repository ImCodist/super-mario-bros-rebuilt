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

const SCREEN_SIZE = Vector2(256, 224)


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
@export var camera_type := CameraTypes.RIGHT_ONLY
@export var kill_on_fall := true


var hud: CanvasLayer
var score_canvas: CanvasLayer

var camera: Camera2D
var camera_collision: CollisionShape2D

var background: ColorRect


var score := 0
var coins := 0


var time_warning_happened := false

var timer_timer := 0.0


func _ready():
	# Add to the levels group.
	add_to_group("levels")
	
	# Create important nodes. eg. background / hud
	_create_nodes()
	
	# Play the stages song.
	if level_theme.music != "":
		Audio.play_music(level_theme.music)
	
	if underwater:
		for player in get_tree().get_nodes_in_group("players"):
			player.swimming = true
	
	# Set the tilesets for the level maps.
	for child in get_children():
		if child is LevelMap:
			child.tile_set = level_theme.tileset
			child.z_index = -2

func _process(delta):
	if get_tree().paused:
		return
	
	if not Main.game_paused:
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
			if player.position.y >= SCREEN_SIZE.y + 32:
				player.die(false)
				Audio.stop_music()
			
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
	camera.position = SCREEN_SIZE / 2
	camera.limit_bottom = int(SCREEN_SIZE.y)
	add_child(camera)
	
	if camera_type == CameraTypes.LEFT_ONLY:
		for player in get_tree().get_nodes_in_group("players"):
			camera.position.x = player.position.x
			break
	
	var camera_body = StaticBody2D.new()
	camera_body.set_collision_layer_value(1, false)
	camera_body.set_collision_layer_value(2, true)
	camera_body.set_collision_mask_value(1, false)
	camera.add_child(camera_body)
	
	camera_collision = CollisionShape2D.new()
	var collision_shape = RectangleShape2D.new()
	collision_shape.size = Vector2(16, SCREEN_SIZE.y * 4)
	camera_collision.shape = collision_shape
	camera_body.add_child(camera_collision)

func _update_camera(delta):
	if Main.game_paused:
		return
	
	if camera == null:
		return
	
	if camera_type != CameraTypes.STATIC:
		for player in get_tree().get_nodes_in_group("players"):
			var camera_first_offset = SCREEN_SIZE.x / 6
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
	match camera_type:
		CameraTypes.LEFT_ONLY:
			camera_collision.position.x = (SCREEN_SIZE.x / 2) + 8
		_:
			camera_collision.position.x = -(SCREEN_SIZE.x / 2) - 8
	
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
	if use_timer:
		hud.time_value_label.text = " %03d" % timer
	else:
		hud.time_value_label.text = ""
		
	for player in get_tree().get_nodes_in_group("players"):
		if player.character != null:
			hud.player_label.text = player.character.name
	
	hud.world_value_label.text = "%2d-%s" % [world, level]
	hud.score_value_label.text = "%06d" % [score]
	hud.coin_value_label.text = "*%02d" % [coins]
