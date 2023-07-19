@tool
@icon("res://assets/editor/icons/sprite_font.png")
class_name SpriteFont
extends Resource


@export var texture: Texture2D

@export var hframes: int = 1
@export var vframes: int = 1


@export_multiline var char_string := ""


func get_char_size():
	return texture.get_size() / Vector2(hframes, vframes)


func get_char_rect(character: String):
	var char_size = get_char_size()
	var char_pos = char_string.find(character)
	
	if char_pos == -1:
		return null
	
	return Rect2(Vector2((char_pos % hframes) * char_size.x, 0), char_size)
