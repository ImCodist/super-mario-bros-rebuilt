extends CanvasLayer


@onready var world_value_label = $MainControl/WorldValueLabel
@onready var time_value_label = $MainControl/TimeValueLabel
@onready var player_label = $MainControl/PlayerLabel
@onready var score_value_label = $MainControl/ScoreLabel
@onready var coin_value_label = $MainControl/CoinLabel


func _ready():
	if Settings.mario_behind_hud:
		layer = 10


func _process(_delta):
	$MainControl/CoinHud.frame = Sprites.flash_frame
