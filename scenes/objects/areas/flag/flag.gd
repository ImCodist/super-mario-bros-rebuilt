extends Area2D


const FLAG_DOWN_SPEED = 140
const PLAYER_DOWN_SPEED = 120

const TOP_OFFSET = 16

const BOTTOM_PLAYER_OFFSET = 9
const SIDE_PLAYER_OFFSET = 6

const FLAG_DOWN_RELEASE_TIME := 1.0

const SFX_FLAG_DOWN = preload("res://assets/sounds/flag_down.wav")
const SFX_LEVEL_COMPLETE = preload("res://assets/sounds/level_complete.wav")


enum FlagStates {
	IDLE,
	DOWN,
	FLAG_DOWN,
	EXIT
}


var players := []

var state := FlagStates.IDLE


var release_timer := 0.0


@onready var collision = $Collision
@onready var flag_sprite = $SpriteFlag


func _ready():
	_set_flag_position()

func _physics_process(delta):
	match state:
		FlagStates.DOWN:
			var flag_position = -22
			if flag_sprite.position.y < flag_position:
				flag_sprite.position.y += FLAG_DOWN_SPEED * delta
			
			if flag_sprite.position.y >= flag_position:
				flag_sprite.position.y = flag_position
				state = FlagStates.FLAG_DOWN
			
			var flag_position_offset = position.y - BOTTOM_PLAYER_OFFSET
			for player in players:
				if player.position.y < flag_position_offset:
					player.position.y += PLAYER_DOWN_SPEED * delta
					
				if player.position.y >= flag_position_offset:
					player.position.y = flag_position_offset
					player.sprite.frame = 0
		FlagStates.FLAG_DOWN:
			release_timer += delta
			if release_timer >= FLAG_DOWN_RELEASE_TIME:
				_on_exit_state()
				
				state = FlagStates.EXIT
				release_timer = 0.0
			
			for player in players:
				player.position.x = position.x + SIDE_PLAYER_OFFSET
				
				player.sprite.flip_h = true
				player.sprite.frame = 0


func _set_flag_position():
	flag_sprite.position.y = -collision.shape.size.y + TOP_OFFSET

func _on_exit_state():
	Audio.play_sfx(SFX_LEVEL_COMPLETE, true)
	
	for player in players:
		player.disabled = false


func _on_body_entered(body):
	if body.is_in_group("players"):
		body.velocity = Vector2.ZERO
		body.position.x = position.x - SIDE_PLAYER_OFFSET
		body.disabled = true
		
		var sprite = body.sprite
		sprite.speed_scale = 1.0
		sprite.flip_h = false
		sprite.play("climb", 1)
		
		_set_flag_position()
		
		state = FlagStates.DOWN
		players.append(body)
		
		Audio.stop_music()
		Audio.play_sfx(SFX_FLAG_DOWN, true)
