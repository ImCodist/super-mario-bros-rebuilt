extends Warp


enum PipeDirection {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

const PIPE_SOUND := preload("res://assets/sounds/pipe.wav")

@export var pipe_direction: PipeDirection = PipeDirection.DOWN
@export_file("*.tscn") var pipe_scene: String


var down_players := []

var start_pipe := false
var pipe_timer := 0.0


@onready var pipe_area := $PipeArea


func _ready():
	add_to_group("_warps")

func _process(_delta):
	var players = pipe_area.get_overlapping_bodies()
	
	if start_pipe:
		pipe_timer += _delta
		
		if pipe_timer >= 1.5:
			start_pipe = false
			
			Audio.stop_music()
			Main.change_level(pipe_scene)
	
	var on_ground_only := true
	
	if Input.is_action_just_pressed("down"):
		for player in players:
			if player.disabled:
				return
			if on_ground_only:
				if not player.is_on_floor():
					return
			#if abs(player.velocity.x) >= 80:
				#return
			
			player.velocity = Vector2.ZERO
			player.disabled = true
			player.z_index = -5
			
			var offset = player.position.x - position.x
			player.position.x -= (abs(offset) / 2.0) * sign(offset)
			
			down_players.append([player, player.position])
			
			Audio.play_sfx(PIPE_SOUND)
			
			start_pipe = true

	if len(down_players) > 0:
		for player_data in down_players:
			var player = player_data[0]
			var player_start = player_data[1]
			
			if player_start.y + 48 > player.position.y:
				player.position.y += 40 * _delta
