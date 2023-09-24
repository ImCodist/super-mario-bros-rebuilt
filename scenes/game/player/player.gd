@tool
extends CharacterBody2D


# Scenes
const DEATH_SCENE = preload("res://scenes/effects/player_dead/player_dead.tscn")
const BUBBLE_SCENE = preload("res://scenes/effects/bubble/bubble.tscn")
const FIREBALL_SCENE = preload("res://scenes/objects/other/fireball/fireball.tscn")

# Sounds
const SFX_JUMP_SMALL = preload("res://assets/sounds/jump_small.wav")
const SFX_JUMP_BIG = preload("res://assets/sounds/jump_big.wav")
const SFX_SWIM = preload("res://assets/sounds/stomp.wav")
const SFX_BUMP = preload("res://assets/sounds/bump.wav")
const SFX_DEATH = preload("res://assets/sounds/die.wav")
const SFX_DEATH_SEQUEL = preload("res://assets/sounds/die2.wav")
const SFX_FIREBALL = preload("res://assets/sounds/fireball.wav")

# Powerups for hits.
const POWERUP_SMALL := preload("res://assets/resources/powerups/small.tres")
const POWERUP_BIG := preload("res://assets/resources/powerups/big.tres")


# Values taken from https://web.archive.org/web/20130807122227if_/http://i276.photobucket.com/albums/kk21/jdaster64/smb_playerphysics.png.
const JUMP_SPEED = 240.0
const ADDED_JUMP_SPEED = 300.0

const GRAVITY = 1575.0
const ADDED_GRAVITY_1 = 1350.0
const ADDED_GRAVITY_2 = 2025.0

const GRAVITY_UP = 450.0
const ADDED_GRAVITY_UP_1 = 421.875
const ADDED_GRAVITY_UP_2 = 562.5

const DEFAULT_GRAVITY = 562.5

const TERMINAL_VELOCITY = 270.0

const MINIMUM_WALK_SPEED = 4.453125
const WALK_SPEED = 93.75
const RUN_SPEED = 153.75

const WALK_ACCELERATION = 133.593749856
const RUN_ACCELERATION = 200.390624928
const RELEASE_DECELERATION = 182.8125
const SKID_DECELERATION = 365.625

const BASE_FORWARD_MOMENTUM = 133.593749856
const ADDED_FORWARD_MOMENTUM = 200.390624928
const BASE_BACK_MOMENTUM = 200.390624928
const ADDED_BACK_MOMENTUM = 182.8125
const ADDED_BACK_MOMENTUM_2 = 133.593749856

const AIR_MOMENTUM_THRESHOLD = 93.75
const AIR_MOMENTUM_JUMPED_AT_THRESHOLD = 108.75
const RUN_SPEED_DELAY = 0.10
const SKID_TURNAROUND_X_SPEED = 33.75

const JUMP_X_SPEED_MIN = 60.0
const JUMP_X_SPEED_MAX = 138.75

const SWIM_JUMP_SPEED = 90.0
const SWIM_WHIRLPOOL_JUMP_SPEED = 60.0

const SWIM_GRAVITY_UP = 140.625
const SWIM_WHIRLPOOL_GRAVITY_UP = 56.25

const SWIM_GRAVITY = 182.8125
const SWIM_WHIRLPOOL_GRAVITY = 126.5625

const WHIRLPOOL_SPEED_CAP = 90.0
const WHIRLPOOL_GRAVITY_INCREASE = 225.0

const CEILING_HIT_SPEED = 60.0
const COLLECT_ANIM_TIME = 1.0
const FIRE_ANIM_TIME = 0.1


@export var character: Character = preload("res://assets/resources/characters/mario.tres"):
	set = _set_character

@export var powerup: Powerup = preload("res://assets/resources/powerups/small.tres"):
	set = _set_powerup


var previous_powerup: Powerup

var powerup_colors := []


var did_jump = false
var skidding = false
var running = false
var swimming = false: set = _set_swimming
var in_whirlpool = false: set = _set_in_whirlpool

var disabled = false
var allow_input = true
var force_unpause = false

var force_move = null

var can_crouch = false
var crouching = false

var run_timer = 0.0
var jumped_speed = 0.0
var jumped_move_speed = WALK_SPEED

var bubble_timer = 0.0
var bubble_counter = 0
var swim_anim_timer = 0.0
var swim_anim = 1

var collect_anim_timer := 0.0
var collect_anim_grow_timer := 0.0
var collect_anim_grow_frame := 0

var fire_anim_timer := 0.0

var can_bug_jump := false

var current_up_gravity = DEFAULT_GRAVITY
var current_fall_gravity = DEFAULT_GRAVITY

var hit_blocks := []


var starman_enabled := true:
	set = _set_starman_enabled
var starman_timer := 0.0

var invulnerability_timer := 0.0


var default_palette: Array[Color]:
	set = _set_default_palette
var current_palette: Array[Color]:
	set = _set_current_palette


@onready var sprite := $Sprite


func _ready():
	# Add to the players group.
	add_to_group("players")
	
	# Play the first frame of the walk when spawning mid-air.
	if not check_on_floor():
		sprite.play("walk", 0)
		
	# Update the powerup and gravity values.
	_set_character(character)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	if disabled:
		return
	
	if not Main.game_paused or force_unpause:
		# Gravity
		_do_gravity(delta)
		
		# Vertical movement
		_do_vertical_movement()
		
		# Crouch
		if can_crouch:
			_do_crouch()
		
		# Horizontal movement
		_do_horizontal_movement(delta)
		
		# Do animation
		_do_animation(delta)
		
		# Does powerup stuff.
		_do_powerup_actions(delta)
		
		# Other stuffs
		_do_other()
	
		# Move the player
		move_and_slide()
		
		# Other stuffs post physics.
		_do_other_post()
	
	# Do other unpaused.
	_do_other_unpaused(delta)


func _do_gravity(delta):
	var gravity = current_fall_gravity
	var terminal_velocity = TERMINAL_VELOCITY
	if did_jump and velocity.y < 0:
		gravity = current_up_gravity
	
	if swimming:
		if in_whirlpool:
			if velocity.y < 0:
				gravity += WHIRLPOOL_GRAVITY_INCREASE
			else:
				gravity += WHIRLPOOL_GRAVITY_INCREASE * 2
			
			terminal_velocity = WHIRLPOOL_SPEED_CAP
	
	if not check_on_floor():
		velocity.y += gravity * delta
		if velocity.y > terminal_velocity:
			velocity.y = terminal_velocity
			
func _do_crouch():
	var previous_crouch = crouching
	if Input.is_action_pressed("down") and not crouching and check_on_floor() and allow_input:
		crouching = true
	if not Input.is_action_pressed("down") and check_on_floor() and allow_input and _can_uncrouch():
		crouching = false
	if swimming and not check_on_floor() and _can_uncrouch():
		crouching = false
	
	if previous_crouch != crouching:
		_update_collision()

func _do_horizontal_movement(delta):
	var move = _get_move()
	
	if crouching and check_on_floor():
		move = 0
	
	var move_speed = WALK_SPEED
	var accel = WALK_ACCELERATION
	var decel = RELEASE_DECELERATION
	
	if Input.is_action_pressed("b") and allow_input and not swimming:
		running = true
	elif running:
		if run_timer < 0:
			run_timer = RUN_SPEED_DELAY
		else:
			run_timer -= delta
			if run_timer <= 0 or move == 0 or skidding:
				run_timer = -1
				running = false
		
	if running:
		move_speed = RUN_SPEED
		accel = RUN_ACCELERATION
	
	if sign(velocity.x) == -move and abs(velocity.x) >= SKID_TURNAROUND_X_SPEED:
		skidding = true
	if skidding and sign(velocity.x) == move:
		skidding = false
	if not check_on_floor():
		skidding = false
	
	if move != 0 or not check_on_floor():
		var speed = accel
		if skidding:
			speed = SKID_DECELERATION
		
		if not check_on_floor():
			if move == 0:
				return
				
			move_speed = jumped_move_speed
			
			var jump_direction = sign(jumped_speed)
			if jump_direction == 0:
				if sprite.flip_h:
					jump_direction = -1
				else:
					jump_direction = 1
				
			if jump_direction == move:
				# moving forward
				speed = BASE_FORWARD_MOMENTUM
				if abs(velocity.x) >= AIR_MOMENTUM_THRESHOLD:
					speed = ADDED_FORWARD_MOMENTUM
			else:
				# moving backward
				speed = ADDED_BACK_MOMENTUM_2
				if abs(velocity.x) >= AIR_MOMENTUM_THRESHOLD:
					speed = BASE_BACK_MOMENTUM
				elif abs(jumped_speed) >= AIR_MOMENTUM_JUMPED_AT_THRESHOLD:
					speed = ADDED_BACK_MOMENTUM
		
		if abs(velocity.x) < MINIMUM_WALK_SPEED:
			velocity.x = MINIMUM_WALK_SPEED * move
		
		velocity.x = move_toward(velocity.x, move_speed * move, speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)

func _do_vertical_movement():
	if check_on_floor():
		jumped_speed = 0.0
	
	if is_on_ceiling() and not check_on_floor():
		_bump()
	
	if Input.is_action_just_pressed("a") and allow_input:
		if check_on_floor() or swimming or can_bug_jump:
			jump()
	
	if did_jump and not Input.is_action_pressed("a") and allow_input and not check_on_floor():
		did_jump = false

func _do_powerup_actions(_delta):
	if powerup.powerup_id == "fire" and len(get_tree().get_nodes_in_group("fireballs")) < Settings.max_fireballs and not crouching:
		if Input.is_action_just_pressed("b") and allow_input:
			fire_anim_timer = FIRE_ANIM_TIME
			
			var fireball = FIREBALL_SCENE.instantiate()
			if sprite.flip_h:
				fireball.direction = -1
			
			fireball.position = position + Vector2(8 * fireball.direction, -22)
			fireball.z_index = -1
			
			Audio.play_sfx(SFX_FIREBALL)
			get_parent().add_child(fireball)


func _do_other():
	if not hit_blocks.is_empty() and check_on_floor():
		hit_blocks = []

func _do_other_post():
	# stupid fucking bug
	# sometimes you would get stuck to the side of a wall
	# this is a very temp and very bad solution to the problem
	if is_on_wall() and is_on_floor() and not $FloorRaycast.is_colliding():
		var last_collision := get_last_slide_collision()
		if last_collision != null:
			var move = _get_move()
			var movement = 0.2
			if move == -1 and last_collision.get_position() <= position:
				position.x += movement
			if move == 1 and last_collision.get_position() >= position:
				position.x -= movement

func _do_other_unpaused(delta):
	if can_bug_jump:
		can_bug_jump = false
	
	if invulnerability_timer > 0.0:
		if not Main.game_paused:
			invulnerability_timer -= delta
		
		sprite.visible = fmod((invulnerability_timer * 60.0), 4.0) <= 1
		
		if invulnerability_timer <= 0.0:
			sprite.visible = true
	
	_do_powerup_animations(delta)


func _do_animation(delta):
	var move = _get_move()
	
	var anim = ""
	var anim_speed = 1
	var anim_frame = null
	var anim_frame_progress = 0.0
	var do_flip = true
	
	if swimming:
		swim_anim_timer += delta * 10
		if swim_anim_timer >= 1:
			if swim_anim == 1:
				swim_anim = 2
			else:
				swim_anim = 1
			
			anim_frame = sprite.frame
			anim_frame_progress = sprite.frame_progress
			swim_anim_timer = 0
	
		bubble_timer -= delta
		if bubble_timer <= 0:
			var offset = Vector2(5, -18)
			if sprite.flip_h:
				offset.x *= -1
			
			var bubble = BUBBLE_SCENE.instantiate()
			bubble.position = position + offset
			bubble.z_index = -1
			get_parent().add_child(bubble)
			
			bubble_counter += 1
			if bubble_counter >= 3:
				bubble_timer = 1.6
				bubble_counter = 0
			else:
				bubble_timer = 1
	
	if check_on_floor():
		anim = "idle"
		if velocity.x != 0:
			anim = "walk"
		
		if skidding:
			anim = "skid"
	else:
		if not swimming:
			if velocity.y < 0:
				anim = "jump"
			else:
				if sprite.sprite_frames.has_animation("fall"):
					anim = "fall"
				
			anim_speed = 0
			do_flip = false
		else:
			anim = "swim%s" % swim_anim
			
			if velocity.y >= 0:
				if sprite.frame == 0:
					anim_frame = 0
					anim_speed = 0
		
	if crouching:
		anim = "crouch"
		do_flip = false
		
	if anim == "walk":
		anim_speed = (abs(velocity.x) / RUN_SPEED) * 5
		
		if is_on_wall():
			anim_speed = 1.7
	
	if fire_anim_timer > 0:
		fire_anim_timer -= delta
		
		if anim == "walk":
			anim_frame = sprite.frame
			anim_frame_progress = sprite.frame_progress
		else:
			anim_frame = 0
		
		anim = "fire"
		if not check_on_floor() and fire_anim_timer <= 0:
			anim = "jump"
	
	if move != 0 and do_flip:
		sprite.flip_h = move != 1
		
	# secret
	if Settings.gamer_style:
		if Input.is_key_pressed(KEY_ALT):
			sprite.flip_h = false
			anim_speed = 3
			anim = "gagng"
			
			if not $SecretSong.playing:
				$SecretSong.play()
				Audio.stop_music()
		elif $SecretSong.playing:
			$SecretSong.stop()
			Audio.resume_music()

	sprite.speed_scale = anim_speed
	if anim != "" and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
		
		if anim_frame != null:
			sprite.frame = anim_frame
			sprite.frame_progress = anim_frame_progress


func _do_powerup_animations(delta):
	if collect_anim_timer > 0:
		collect_anim_timer -= delta
		
		collect_anim_grow_timer += delta
		if collect_anim_grow_timer >= 0.07:
			collect_anim_grow_frame += 1
			collect_anim_grow_timer = 0
		
		if powerup.powerup_level == 1:
			var current_powerup_sprites = character.get_powerup_sprites(powerup.powerup_id)
			var small_powerup = character.powerups.front()
			if small_powerup != null and current_powerup_sprites != null:
				if collect_anim_grow_frame % 2 == 0:
					sprite.sprite_frames = small_powerup.sprite_frames
					sprite.play("idle")
				else:
					if collect_anim_grow_frame < 6:
						sprite.sprite_frames = small_powerup.sprite_frames
						sprite.play("grow")
					else:
						sprite.sprite_frames = current_powerup_sprites
						sprite.play("idle")
		if powerup.powerup_level >= 2:
			var colors = powerup_colors.duplicate(true)
			colors.reverse()
		
			var palette = colors[fmod(collect_anim_timer * 20.0, len(colors))]
			if palette.is_empty():
				palette = current_palette
			
			_update_current_palette(palette)
		
		if collect_anim_timer <= 0:
			_set_powerup(powerup)
			if not check_on_floor():
				sprite.play("walk")
			
			Main.game_paused = false
			
			if Settings.powerup_jump_bug:
				can_bug_jump = true
			
			collect_anim_timer = 0.0
			collect_anim_grow_timer = 0.0
			collect_anim_grow_frame = 0
	
	if starman_enabled:
		var l = 1
		starman_timer -= delta
		
		var speed = 20.0
		if starman_timer <= l:
			speed /= 2
		
		var colors = powerup_colors.duplicate(true)
		colors.reverse()
		
		if len(colors) > 0:
			var palette: Array = colors[fmod((starman_timer * speed), len(colors))]
			if palette.is_empty():
				palette = current_palette
				
			_update_current_palette(palette)
		
		if starman_timer <= 0:
			starman_enabled = false
			starman_timer = 0.0
			
			_update_current_palette(current_palette)
			
		if starman_timer <= l:
			if Audio.song == "invincible":
				if Audio.previous_song != "":
					Audio.play_music(Audio.previous_song, Audio.song_speed)
				else:
					Audio.stop_music()


func _can_uncrouch():
	var crouch_raycast := $CrouchRaycast
	return not crouch_raycast.is_colliding()

func _update_collision():
	var collision := get_node_or_null("Collision")
	var collision_top := get_node_or_null("CollisionTop")
	var crouch_raycast := get_node_or_null("CrouchRaycast")
	var floor_raycast := get_node_or_null("FloorRaycast")
	
	if collision != null:
		var h_size = 14.9
		var height = powerup.hitbox_height
		if crouching:
			height = 15
		
		collision.shape.size.x = h_size
		collision.shape.size.y = height
		
		if collision_top != null:
			var slope_size = 5.0
			var inward_size = 2.9
			
			var new_polygon = PackedVector2Array()
			
			new_polygon.append(Vector2(-h_size / 2.0, 0))
			new_polygon.append(Vector2(h_size / 2.0, 0))
			new_polygon.append(Vector2(h_size / 2.0 - inward_size, -slope_size))
			new_polygon.append(Vector2(-(h_size / 2.0) + inward_size, -slope_size))
			
			collision_top.set_deferred("polygon", new_polygon)
			
			collision_top.position.y = (-height) + slope_size
			collision.shape.size.y -= slope_size
		
		collision.position.y = -(collision.shape.size.y / 2.0)
	
		if crouch_raycast != null:
			crouch_raycast.target_position.y = -16
		if floor_raycast != null:
			floor_raycast.target_position.x = h_size - 0.5
			floor_raycast.position.x = -floor_raycast.target_position.x / 2

func _update_gravity_values():
	if not swimming:
		current_fall_gravity = GRAVITY
		current_up_gravity = GRAVITY_UP
	else:
		if not in_whirlpool:
			current_fall_gravity = SWIM_GRAVITY
			current_up_gravity = SWIM_GRAVITY_UP
		else:
			current_fall_gravity = SWIM_WHIRLPOOL_GRAVITY
			current_up_gravity = SWIM_WHIRLPOOL_GRAVITY_UP

func _get_move():
	if force_move != null:
		return force_move
	
	if not allow_input:
		return 0
	
	return sign(Input.get_axis("left", "right"))


func jump():
	var jump_speed = JUMP_SPEED
	current_fall_gravity = GRAVITY
	current_up_gravity = GRAVITY_UP
	
	if not swimming:
		if abs(velocity.x) >= JUMP_X_SPEED_MAX:
			jump_speed = ADDED_JUMP_SPEED
			current_fall_gravity = ADDED_GRAVITY_2
			current_up_gravity = ADDED_GRAVITY_UP_2
		elif abs(velocity.x) > JUMP_X_SPEED_MIN:
			current_fall_gravity = ADDED_GRAVITY_1
			current_up_gravity = ADDED_GRAVITY_UP_1
	if swimming:
		jump_speed = SWIM_JUMP_SPEED
			
		_update_gravity_values()
	
	jumped_speed = velocity.x
	
	jumped_move_speed = WALK_SPEED
	if Input.is_action_pressed("b") and allow_input and not swimming:
		jumped_move_speed = RUN_SPEED
	
	velocity.y = -jump_speed
	
	if not swimming:
		if powerup.powerup_level == 0:
			Audio.play_sfx(SFX_JUMP_SMALL)
		else:
			Audio.play_sfx(SFX_JUMP_BIG)
	else:
		Audio.play_sfx(SFX_SWIM)
	
	did_jump = true

func hit():
	print("hit")
	
	if powerup.powerup_level <= 0:
		die()
	else:
		if powerup.powerup_level == 1:
			powerup = POWERUP_SMALL
		else:
			powerup = POWERUP_BIG
		
		collect_anim_timer = COLLECT_ANIM_TIME
		Main.game_paused = true
		
		invulnerability_timer = 3.0

func die(spawn_effect := true, stop_music := true):
	if not visible:
		return
	
	if spawn_effect:
		var sprite_frames = sprite.sprite_frames
		
		var small_powerup = character.powerups.front()
		if small_powerup != null:
			sprite_frames = small_powerup.sprite_frames
		
		var scene = DEATH_SCENE.instantiate()
		scene.position = position
		scene.sprite_frames = sprite_frames
		
		get_parent().add_child(scene)
	
	if stop_music:
		Audio.stop_music()
	
	Audio.play_sfx(SFX_DEATH)
	if Settings.programmer_death_sound and randi_range(0, 200) == 21:
		Audio.play_sfx(SFX_DEATH_SEQUEL)
	
	Main.game_paused = true
	visible = false
	
	await get_tree().create_timer(4.0, false).timeout
	
	Main.game_paused = false
	get_tree().reload_current_scene()


func check_on_floor():
	return is_on_floor()

func is_invulnerable():
	return invulnerability_timer > 0.0


func _bump():
	Audio.play_sfx(SFX_BUMP)
	velocity.y = CEILING_HIT_SPEED

func _update_default_palette(palette):
	if sprite == null:
		return
	
	var i = 0
	for color in palette:
		sprite.material.set_shader_parameter("original_%s" % i, color)
		i += 1

func _update_current_palette(palette):
	if sprite == null:
		return
	
	if palette.is_empty():
		palette = default_palette
	
	var i = 0
	for color in palette:
		sprite.material.set_shader_parameter("replace_%s" % i, color)
		i += 1


func _set_character(value: Character):
	character = value
	
	default_palette = character.default_palette
	_set_powerup(powerup)

func _set_powerup(value: Powerup):
	previous_powerup = powerup
	powerup = value
	
	if sprite != null and character != null:
		var character_powerup = character.get_char_powerup(powerup.powerup_id)
		
		if character_powerup != null:
			var sprite_frames = character_powerup.sprite_frames
			if sprite_frames != null:
				sprite.sprite_frames = sprite_frames
			
			current_palette = character_powerup.palette
	
	can_crouch = powerup.powerup_level != 0
	_update_collision()


func _set_swimming(value: bool):
	swimming = value
	
	if not check_on_floor():
		sprite.play("walk", 0)
	
	_update_gravity_values()

func _set_in_whirlpool(value: bool):
	in_whirlpool = value


func _set_starman_enabled(enabled: bool):
	starman_enabled = enabled
	
	if starman_enabled:
		starman_timer = 10.6
		Audio.play_music("invincible", Audio.song_speed)


func _set_default_palette(palette: Array[Color]):
	default_palette = palette
	_update_default_palette(palette)

func _set_current_palette(palette: Array[Color]):
	current_palette = palette
	_update_current_palette(palette)
