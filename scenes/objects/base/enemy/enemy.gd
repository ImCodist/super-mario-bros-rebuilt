class_name Enemy
extends CharacterBody2D


const SFX_STOMP = preload("res://assets/sounds/stomp.wav")
const SFX_KICK = preload("res://assets/sounds/kick.wav")


enum MovementType {
	STATIC,
	HORIZONTAL,
}


const GRAVITY = 1000
const SPEED = 30
const KILLED_SPEED = 200


var direction := -1

var been_stomped := false
var stomped_timer := 0.0

var been_killed := false

var bodies_inside := []


var delete_direction := 0


@export var movement_type := MovementType.HORIZONTAL

@export var can_stomp := true

@export var points := 100


@onready var sprite := $Sprite
@onready var collision := $Collision
@onready var hitbox := $Hitbox
@onready var on_screen_notifier := $OnScreenNotifier


func _ready():
	set_process(false)
	set_physics_process(false)
	
	collision.disabled = true
	
	add_to_group("enemies")

func _physics_process(delta):
	_check_collisions()
	
	if Main.game_paused:
		return
	
	var x_spd = SPEED
	
	if been_killed:
		collision.disabled = true
		hitbox.monitorable = false
		x_spd *= 2
	
	if been_stomped:
		stomped_timer += delta
		
		if stomped_timer >= 0.466667:
			finished_stomp()
		
		return
	
	if is_on_wall():
		direction = -direction
	
	velocity.y += GRAVITY * delta
	velocity.x = x_spd * direction
	
	move_and_slide()


func pre_stomped():
	been_stomped = true
	
	collision.set_deferred("disabled", true)
	_spawn_points()
	
	Audio.play_sfx(SFX_STOMP)

func stomped():
	pass

func finished_stomp():
	queue_free()


func die():
	Audio.play_sfx(SFX_KICK)
	
	been_killed = true
	
	velocity.y = -KILLED_SPEED
	
	sprite.flip_v = true
	
	_spawn_points()


func _check_collisions():
	if been_stomped:
		return
	if been_killed:
		return
	
	for body in hitbox.get_overlapping_bodies():
		_check_collision(body)
		
		if not body in bodies_inside:
			bodies_inside.append(body)

func _check_collision(body):
	if not body.is_in_group("players"):
		return
	
	var is_stomped = body.velocity.y > 10
	
	if body.starman_enabled:
		direction = sign(body.velocity.x)
		die()
		return
	
	if can_stomp and is_stomped:
		if not body in bodies_inside:
			body.did_jump = false
			body.velocity.y = -body.JUMP_SPEED
			
			pre_stomped()
			stomped()
	else:
		if body.is_invulnerable():
			return
		
		body.hit()


func _spawn_points():
	if points == 0:
		return
	
	var level := Main.get_level()
	if level != null:
		level.add_points(points, true, position - Vector2(4, 0))


func _on_on_screen_notifier_screen_entered():
	set_process(true)
	set_physics_process(true)
	
	collision.disabled = false

func _on_on_screen_notifier_screen_exited():
	match delete_direction:
		-1:
			if on_screen_notifier.camera.position.x > position.x:
				queue_free()
		1:
			if on_screen_notifier.camera.position.x < position.x:
				queue_free()
		_:
			pass


func _on_hitbox_body_exited(body):
	if body in bodies_inside:
		bodies_inside.erase(body)
