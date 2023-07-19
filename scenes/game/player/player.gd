@tool
extends CharacterBody2D


# Scenes
const DEATH_SCENE = preload("res://scenes/effects/player_dead/player_dead.tscn")
const BUBBLE_SCENE = preload("res://scenes/effects/bubble/bubble.tscn")

# Sounds
const SFX_JUMP_SMALL = preload("res://assets/sounds/jump_small.wav")
const SFX_JUMP_BIG = preload("res://assets/sounds/jump_big.wav")
const SFX_SWIM = preload("res://assets/sounds/stomp.wav")
const SFX_BUMP = preload("res://assets/sounds/bump.wav")
const SFX_DEATH = preload("res://assets/sounds/die.wav")
const SFX_DEATH_SEQUEL = preload("res://assets/sounds/die2.wav")


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


@export var character: Character = preload("res://assets/resources/characters/mario.tres"):
	set = _set_character

@export var powerup: Powerup = preload("res://assets/resources/powerups/small.tres"):
	set = _set_powerup


var previous_powerup: Powerup


var did_jump = false
var skidding = false
var running = false
var swimming = false: set = _set_swimming
var in_whirlpool = false: set = _set_in_whirlpool

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

var can_bug_jump := false

var current_up_gravity = DEFAULT_GRAVITY
var current_fall_gravity = DEFAULT_GRAVITY

var hit_block := false


@onready var sprite := $Sprite


func _ready():
	# Add to the players group.
	add_to_group("players")
	
	# Play the first frame of the walk when spawning mid-air.
	if not is_on_floor():
		sprite.play("walk", 0)
		
	# Update the powerup and gravity values.
	_set_powerup(powerup)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	if not Main.game_paused:
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
		
		# Other stuffs
		_do_other()
	
		# Move the player
		move_and_slide()
	
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
	
	velocity.y += gravity * delta
	if velocity.y > terminal_velocity:
		velocity.y = terminal_velocity
			
func _do_crouch():
	var previous_crouch = crouching
	if not crouching and is_on_floor() and Input.is_action_pressed("down"):
		crouching = true
	if is_on_floor() and not Input.is_action_pressed("down") and _can_uncrouch():
		crouching = false
	if swimming and not is_on_floor() and _can_uncrouch():
		crouching = false
	
	if previous_crouch != crouching:
		_update_collision()

func _do_horizontal_movement(delta):
	var move = _get_move()
	
	if crouching and is_on_floor():
		move = 0
	
	var move_speed = WALK_SPEED
	var accel = WALK_ACCELERATION
	var decel = RELEASE_DECELERATION
	
	if Input.is_action_pressed("b") and not swimming:
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
	if not is_on_floor():
		skidding = false
	
	if move != 0 or not is_on_floor():
		var speed = accel
		if skidding:
			speed = SKID_DECELERATION
		
		if not is_on_floor():
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
	if is_on_floor():
		jumped_speed = 0.0
	
	if is_on_ceiling() and not is_on_floor():
		Audio.play_sfx(SFX_BUMP)
		
		velocity.y = CEILING_HIT_SPEED
	
	if Input.is_action_just_pressed("a"):
		if is_on_floor() or swimming or can_bug_jump:
			jump()
	
	if did_jump and not Input.is_action_pressed("a") and not is_on_floor():
		did_jump = false


func _do_other():
	if hit_block and is_on_floor():
		hit_block = false

func _do_other_unpaused(delta):
	if can_bug_jump:
		can_bug_jump = false
	
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
	
	if is_on_floor():
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
	
	if move != 0 and do_flip:
		sprite.flip_h = move != 1
		
	# secret
	if Settings.gamer_style and powerup.powerup_level == 1:
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
	if anim != "":
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
		
		if previous_powerup.powerup_level == 0:
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
		else:
			var current_powerup_sprites = character.get_powerup_sprites(powerup.powerup_id)
			var previous_powerup_sprites = character.get_powerup_sprites(previous_powerup.powerup_id)
			
			if current_powerup_sprites != null and previous_powerup_sprites != null:
				if collect_anim_grow_frame % 2 == 0:
					sprite.sprite_frames = current_powerup_sprites
				else:
					sprite.sprite_frames = previous_powerup_sprites
		
		if collect_anim_timer <= 0:
			_set_powerup(powerup)
			if not is_on_floor():
				sprite.play("walk")
			
			Main.game_paused = false
			
			if Settings.powerup_jump_bug:
				can_bug_jump = true
			
			collect_anim_timer = 0.0
			collect_anim_grow_timer = 0.0
			collect_anim_grow_frame = 0


func _can_uncrouch():
	var crouch_raycast := $CrouchRaycast
	return not crouch_raycast.is_colliding()

func _update_collision():
	var collision := get_node_or_null("Collision")
	var crouch_raycast := get_node_or_null("CrouchRaycast")
	
	if collision != null:
		var h_size = 6
		var height = powerup.hitbox_height
		if crouching:
			height = 15
		
		collision.set_deferred("polygon", [
			Vector2(-h_size, 0),
			Vector2(h_size, 0),
			Vector2(h_size, -height + 1),
			Vector2(-h_size, -height + 1),
		])
	
		if crouch_raycast != null:
			crouch_raycast.target_position.y = -16

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
	if Input.is_action_pressed("b") and not swimming:
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
	

func die(spawn_effect := true):
	if spawn_effect:
		var sprite_frames = sprite.sprite_frames
		
		var small_powerup = character.powerups.front()
		if small_powerup != null:
			sprite_frames = small_powerup.sprite_frames
		
		var scene = DEATH_SCENE.instantiate()
		scene.position = position
		scene.sprite_frames = sprite_frames
		
		get_parent().add_child(scene)
	
	Audio.play_sfx(SFX_DEATH)
	if Settings.programmer_death_sound and randi_range(0, 200) == 21:
		Audio.play_sfx(SFX_DEATH_SEQUEL)
	
	Main.game_paused = true
	
	queue_free()


func _set_character(value: Character):
	character = value
	_set_powerup(powerup)

func _set_powerup(value: Powerup):
	previous_powerup = powerup
	powerup = value
	
	if sprite != null and character != null:
		var sprite_frames = character.get_powerup_sprites(powerup.powerup_id)
		
		if sprite_frames != null:
			sprite.sprite_frames = sprite_frames
	
	can_crouch = powerup.powerup_level != 0
	_update_collision()


func _set_swimming(value: bool):
	swimming = value
	
	if not is_on_floor():
		sprite.play("walk", 0)
	
	_update_gravity_values()


func _set_in_whirlpool(value: bool):
	in_whirlpool = value
	
	
