extends CharacterBody2D


const EFFECT_SCENE = preload("res://scenes/effects/fireball_particle/fireball_particle.tscn")

const SFX_BUMP = preload("res://assets/sounds/bump.wav")


const SPEED = 230
const HOP_SPEED = 180
const GRAVITY = 1500
const TERMINAL_VELOCITY = 200

const SPRITE_SPEED := 0.1


var direction := 1

var sprite_frame_timer := 0.0


@onready var sprite = $Sprite


func _ready():
	velocity.y = TERMINAL_VELOCITY
	add_to_group("fireballs")


func _physics_process(delta):
	if Main.game_paused:
		return
	
	sprite_frame_timer += delta
	
	if sprite_frame_timer >= SPRITE_SPEED:
		sprite.frame += 1
		
		if sprite.frame >= (sprite.hframes * sprite.vframes) - 1:
			sprite.frame = 0
		
		sprite_frame_timer = 0.0
		
	velocity.x = SPEED * direction
	
	velocity.y += GRAVITY * delta
	if velocity.y >= TERMINAL_VELOCITY:
		velocity.y = TERMINAL_VELOCITY
	
	if is_on_floor():
		velocity.y = -HOP_SPEED
	if is_on_wall():
		Audio.play_sfx(SFX_BUMP)
		_destroy()
	
	$OnScreenNotifier.position.x = 8 * direction
	
	move_and_slide()

func _destroy():
	_spawn_particle()
	queue_free()


func _spawn_particle():
	var scene = EFFECT_SCENE.instantiate()
	scene.position = position
	get_parent().add_child(scene)


func _on_on_screen_notifier_screen_exited():
	queue_free()


func _on_hit_box_body_entered(_body):
	pass

func _on_hit_box_area_entered(area):
	var body = area.get_parent()
	if body is Enemy:
		body.direction = direction
		body.die()
		
		_destroy()
