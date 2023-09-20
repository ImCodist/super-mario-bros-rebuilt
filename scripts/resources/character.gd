@tool
@icon("res://assets/editor/icons/character.png")
class_name Character
extends Resource


@export var name := ""

@export var powerups: Array[CharacterPowerup] = []

@export var default_palette: Array[Color]


func get_char_powerup(powerup_id: String) -> CharacterPowerup:
	var char_powerup: CharacterPowerup = null
	for powerup in powerups:
		if powerup.powerup_id == powerup_id:
			char_powerup = powerup
			return char_powerup
	
	return null

func get_powerup_sprites(powerup_id: String) -> SpriteFrames:
	var char_powerup := get_char_powerup(powerup_id)
	if char_powerup == null:
		return null
	
	return char_powerup.sprite_frames
