class_name Block
extends StaticBody2D


const JUMP_SPEED = 140
const GRAVITY = 1200


@export var item: PackedScene = preload("res://scenes/objects/items/coin_block/coin_block.tscn")
@export var item_secondary: PackedScene

@export var item_count := 1

@export var use_timer := false
@export var timer_end := 3.8

@export var invisible := false


var sprite_velocity := Vector2.ZERO

var queue_item_spawn := false
var is_empty := false

var last_hit_body: PhysicsBody2D

var started_timer := false
var timer := 0.0


@onready var sprite := $Sprite
@onready var collision := $Collision
@onready var player_detection = $PlayerDetection
@onready var player_detection_collision = $PlayerDetection/Collision
@onready var sprite_start_position = sprite.position


func _ready():
	if invisible:
		sprite.visible = false
		collision.one_way_collision = true
		collision.rotation_degrees = 180
		
		player_detection_collision.one_way_collision = true
		player_detection_collision.rotation_degrees = 180
		
func _process(delta):
	player_detection.priority = item_count
	
	if sprite.position.y < sprite_start_position.y or sprite_velocity.y < 0:
		sprite_velocity.y += GRAVITY * delta
		sprite.position += sprite_velocity * delta
	elif sprite.position >= sprite_start_position and sprite_velocity.y >= 0:
		sprite.position = sprite_start_position
		
		if sprite_velocity.y != 0:
			landed()
		sprite_velocity.y = 0
	
	if started_timer and timer < timer_end:
		timer += delta


func hit():
	if not is_empty:
		if invisible:
			sprite.visible = true
			collision.set_deferred("one_way_collision", false)
			collision.rotation_degrees = 0
		
		sprite_velocity.y = -JUMP_SPEED
		sprite.frame = 1
		
		_do_top_action()
	
	if item_count > 0:
		started_timer = true
		if not use_timer or timer >= timer_end:
			item_count -= 1
		
		if not item.instantiate() is Item:
			spawn_item()
		else:
			queue_item_spawn = true
		
		if item_count <= 0:
			is_empty = true
			
			sprite.texture_name = "hit_block"
			sprite.hframes = 2

func landed():
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

func _do_top_action():
	var top_detection = $TopDetection
	
	# areas
	if top_detection.has_overlapping_areas():
		for area in top_detection.get_overlapping_areas():
			if area.is_in_group("coins"):
				area.collect()
	
	# bodies
	if top_detection.has_overlapping_bodies():
		for body in top_detection.get_overlapping_bodies():
			if body is Item:
				body.velocity.y = -200
				body.direction = -body.direction


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
