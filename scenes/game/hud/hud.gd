extends CanvasLayer


@onready var world_value_label = $MainControl/WorldValueLabel
@onready var time_value_label = $MainControl/TimeValueLabel
@onready var player_label = $MainControl/PlayerLabel
@onready var score_value_label = $MainControl/ScoreLabel
@onready var coin_value_label = $MainControl/CoinLabel


@export var is_level_intro := false


func _ready():
	if Settings.mario_behind_hud:
		layer = 10


func _process(_delta):
	if not is_level_intro:
		$MainControl/CoinHud.frame = Sprites.flash_frame


func set_timer_text(timer: int, use_timer: bool = true):
	if use_timer:
		time_value_label.text = " %03d" % timer
	else:
		time_value_label.text = ""

func set_world_text(world, level):
	world_value_label.text = "%2d-%s" % [world, level]

func set_score_text(score: int):
	score_value_label.text = "%06d" % [score]

func set_coin_text(coins: int):
	coin_value_label.text = "*%02d" % [coins]
