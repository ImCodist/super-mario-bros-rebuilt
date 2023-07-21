class_name Item
extends CharacterBody2D


const SFX_ITEM_APPEAR = preload("res://assets/sounds/item_appear.wav")
const SFX_ITEM_COLLECT = preload("res://assets/sounds/powerup.wav")

const ITEM_BOX_SPEED = 20

const GRAVITY = 1000
const SPEED = 50


var direction := 1

var from_block := false


@export var powerup: Powerup = preload("res://assets/resources/powerups/big.tres")

@export var move_horizontally := true


@onready var original_position := position


func _ready():
	if Settings.only_allow_one_powerup:
		for item in get_tree().get_nodes_in_group("items"):
			item.queue_free()
		
	add_to_group("items")
	
	if from_block:
		Audio.play_sfx(SFX_ITEM_APPEAR)


func _physics_process(delta):
	if Main.game_paused:
		return
	
	if from_block:
		position.y -= ITEM_BOX_SPEED * delta
		
		if position.y <= original_position.y - 15:
			from_block = false
			z_index = 0
	else:
		if is_on_wall():
			direction = -direction
		
		velocity.y += GRAVITY * delta
		
		if move_horizontally:
			velocity.x = SPEED * direction
		
		move_and_slide()


func collected(player):
	if powerup != null:
		if player.powerup.powerup_level < powerup.powerup_level:
			player.powerup = powerup
			player.collect_anim_timer = player.COLLECT_ANIM_TIME
			Main.game_paused = true
	
		var level := Main.get_level()
		if level != null:
			level.add_points(powerup.points, true, position)
		
	Audio.play_sfx(SFX_ITEM_COLLECT)


func _on_collect_area_body_entered(body):
	if body.is_in_group("players"):
		queue_free()
		collected(body)


func _on_visible_on_screen_screen_exited():
	queue_free()
