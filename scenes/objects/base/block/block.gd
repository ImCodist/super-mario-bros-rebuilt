class_name Block
extends StaticBody2D


const EMPTY_BLOCK_TEXTURE = preload("res://assets/sprites/themes/overworld/hit_block.png")

const JUMP_SPEED = 140
const GRAVITY = 1200


@export var item: PackedScene = preload("res://scenes/effects/coin_block/coin_block.tscn")
@export var item_secondary: PackedScene

@export var item_count := 1

@export var invisible := false


var sprite_velocity := Vector2.ZERO

var queue_item_spawn := false
var is_empty := false

var last_hit_body: PhysicsBody2D

@onready var sprite := $Sprite
@onready var collision := $Collision
@onready var sprite_start_position = sprite.position


func _ready():
	if invisible:
		sprite.visible = false
		collision.one_way_collision = true
		collision.rotation_degrees = 180
		

func _process(delta):
	if sprite.position.y < sprite_start_position.y or sprite_velocity.y < 0:
		sprite_velocity.y += GRAVITY * delta
		sprite.position += sprite_velocity * delta
	elif sprite.position >= sprite_start_position and sprite_velocity.y >= 0:
		sprite.position = sprite_start_position
		sprite_velocity.y = 0
		
		landed()


func hit():
	if not is_empty:
		if invisible:
			sprite.visible = true
			collision.set_deferred("one_way_collision", false)
			collision.rotation_degrees = 0
		
		sprite_velocity.y = -JUMP_SPEED
		sprite.frame = 1
	
	if item_count > 0:
		item_count -= 1
		
		if not item.instantiate() is Item:
			spawn_item()
		else:
			queue_item_spawn = true
		
		if item_count <= 0:
			is_empty = true
			
			sprite.texture = EMPTY_BLOCK_TEXTURE
			sprite.hframes = 2

func landed():
	if item_count <= 0:
		sprite.frame = 0
	
	if queue_item_spawn:
		spawn_item()
		queue_item_spawn = false


func spawn_item():
	var scene_to_use = item
	if item_secondary != null and last_hit_body != null and last_hit_body.powerup != null:
		if last_hit_body.powerup.powerup_level <= 0:
			scene_to_use = item_secondary
	
	var item_scene = scene_to_use.instantiate()
	item_scene.position = position
	item_scene.z_index = -4
	
	if item_scene is Item:
		item_scene.from_block = true
	
	get_parent().call_deferred("add_child", item_scene)


func _on_player_detection_body_entered(body):
	if is_empty:
		return
	
	if body.is_in_group("players"):
		if body.is_on_floor():
			return
		
		if invisible and body.position.y <= position.y + 16:
			return
		
		if body.hit_block:
			return
		
		body.hit_block = true
		last_hit_body = body
		hit()
