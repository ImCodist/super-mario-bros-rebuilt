extends Area2D


signal frame_rule_check


enum FlagState {
	NONE,
	GRABBED,
	GROUNDED,
	WALK,
	SCORE,
	CASTLE,
	FIREWORKS,
	FINISHED,
}

const FLAG_DOWN_SPEED := 110


const LEVEL_COMPLETE_MUSIC := preload("res://assets/sounds/level_complete.wav")

const FLAG_DOWN_SFX := preload("res://assets/sounds/flag_down.wav")
const SCORE_SFX := preload("res://assets/sounds/flag_score.wav")
const FIREWORK_SFX := preload("res://assets/sounds/explosion.wav")

const POINTS_SCENE := preload("res://scenes/effects/points_effect/points_effect.tscn")
const FIREWORK_PARTICLE_SCENE := preload("res://scenes/effects/fireball_particle/fireball_particle.tscn")


var player

var state = FlagState.NONE


var points_scene


var timer_timer := 0.0
var timer_og := 0

var fireworks_number := 0

var skip_flag_wait := false


var frame_rule := 0.0


@export var height: int = 8

@export_node_path("Sprite2D") var castle_flag_path = NodePath("CastleFlag")


@onready var sprite := $SpriteFlag

@onready var castle_flag_sprite := get_node_or_null(castle_flag_path)


func _ready():
	setup_sprite()
	
	if castle_flag_sprite != null:
		castle_flag_sprite.visible = false

func _process(_delta):
	if Settings.flag_frame_rule:
		frame_rule += _delta
		if frame_rule >= 0.35:
			frame_rule_check.emit()
			frame_rule = 0.0
	
	match state:
		FlagState.GRABBED:
			player.sprite.play("climb")
			
			var bot = position.y - 10
			if player.position.y < bot:
				player.sprite.speed_scale = 1.0
				player.position.y += FLAG_DOWN_SPEED * _delta
			if player.position.y >= bot:
				player.sprite.frame = 0
				player.sprite.speed_scale = 0.0
				
				player.position.y = bot
			
			if points_scene != null:
				points_scene.position.y -= FLAG_DOWN_SPEED * _delta
			
			bot = -20
			if sprite.position.y < bot:
				sprite.position.y += FLAG_DOWN_SPEED * _delta
			if sprite.position.y >= bot:
				sprite.position.y = bot
				grounded_flag()
		FlagState.SCORE:
			if Settings.skip_flag and Input.is_action_just_pressed("a"):
				Main.get_level().score += Main.get_level().timer * 100
				Main.get_level().timer = 0
				
				Audio.stop_music()
			
			if Main.get_level().timer > 0:
				timer_timer += _delta
				if timer_timer >= 0.1:
					Main.get_level().score += 100
					Main.get_level().timer -= 1
					
					Audio.play_sfx(SCORE_SFX)
			else:
				castle_flag()
		FlagState.CASTLE, FlagState.FIREWORKS, FlagState.FINISHED:
			if Settings.skip_flag and Input.is_action_just_pressed("a"):
				finished_flag(true)


func setup_sprite():
	sprite.position.y = -((height + 1) * 16) + 1


func grab_flag(body: CharacterBody2D):
	state = FlagState.GRABBED
	
	player = body
	
	player.sprite.flip_h = false
	
	player.velocity = Vector2.ZERO
	player.position.x = position.x - 6
	
	player.disabled = true
	player.allow_input = false
	
	Audio.song = ""
	Audio.stop_music()
	
	Audio.play_sfx(FLAG_DOWN_SFX)
	
	var points = get_point_value(player.position.y)
	Main.get_level().force_timer_stop = true
	Main.get_level().score += points
	
	timer_og = Main.get_level().timer
	
	points_scene = POINTS_SCENE.instantiate()
	points_scene.move = false
	points_scene.destroy = false
	points_scene.position = Vector2(12, -18)
	points_scene.points = points # gotta make this based on height
	add_child(points_scene)

func grounded_flag():
	state = FlagState.GROUNDED
	
	player.sprite.flip_h = true
	player.sprite.speed_scale = 0.0
	
	player.position.x = position.x + 6
	
	await get_tree().create_timer(1.0, false).timeout
	
	walk_flag()

func walk_flag():
	state = FlagState.WALK
	
	Audio.play_music_stream(LEVEL_COMPLETE_MUSIC)
	
	player.velocity.x = 50
	player.position.x = position.x + 8
	
	player.sprite.play("walk")
	
	player.disabled = false
	player.force_move = 1
	
	await get_tree().create_timer(1.05, false).timeout
	
	score_flag()

func score_flag():
	state = FlagState.SCORE
	
	player.visible = false
	player.disabled = true
	player.velocity.x = 0

func castle_flag():
	state = FlagState.CASTLE
	
	if Audio.music_is_playing():
		await Audio.mus_players[0].finished
	
	await get_tree().create_timer(1.0, false).timeout
	
	castle_flag_sprite.visible = true
	castle_flag_sprite.z_index = -5
	castle_flag_sprite.offset.y = 16
	
	var flag_tween = get_tree().create_tween().bind_node(self)
	flag_tween.tween_property(castle_flag_sprite, "offset:y", 0, 0.2)
	
	await flag_tween.finished
	
	if len(str(timer_og)) >= 1:
		var timer_number = str(timer_og)[-1]
		match timer_number:
			"1":
				fireworks_number = 1
			"3":
				fireworks_number = 3
			"6":
				fireworks_number = 6
	
	if castle_flag_sprite == null:
		fireworks_number = 0
	
	if fireworks_number <= 0:
		finished_flag()
	else:
		fireworks_flag()

func fireworks_flag():
	state = FlagState.FIREWORKS
	
	for i in fireworks_number:
		var random_range = 48
		
		var firework = FIREWORK_PARTICLE_SCENE.instantiate()
		firework.speed_scale = 0.4
		firework.position = castle_flag_sprite.position + Vector2(
			randi_range(-random_range, random_range),
			randi_range(-random_range / 2.0, random_range / 2.0) - 32
		)
		add_child(firework)
		
		Audio.play_sfx(FIREWORK_SFX)
		
		Main.get_level().score += 500
		
		await firework.animation_finished
		await get_tree().create_timer(0.1, false).timeout
	
	finished_flag()

func finished_flag(force_skip := false):
	state = FlagState.FINISHED
	
	if not force_skip:
		await get_tree().create_timer(2.0, false).timeout
		
		if Settings.flag_frame_rule:
			await frame_rule_check
	
	Main.change_level("res://scenes/levels/test_level/test_level.tscn")


func get_point_value(y_pos: int):
	var true_pos = (position.y - y_pos) - 9
	var perc = true_pos / ((height + 1) * 16)
	
	var pot_points = [100, 400, 800, 2000, 4000, 5000]
	var pot_percent = 1.0 / len(pot_points)

	for i in len(pot_points):
		if perc <= pot_percent * (i + 1):
			return pot_points[i]
	
	return pot_points[-1]


func _on_body_entered(body):
	if state != FlagState.NONE:
		return
	
	if body.is_in_group("players"):
		grab_flag(body)
