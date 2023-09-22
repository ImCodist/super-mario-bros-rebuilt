@tool
@icon("res://assets/editor/icons/sprite_label.png")
class_name SpriteLabel
extends Control


@export_multiline var text := "":
	set = _set_text


@export var sprite_font: SpriteFont


func _draw():
	if sprite_font == null:
		return
	
	if sprite_font.texture == null:
		return
	
	var pos_i = 0
	var pos_y_i = 0
	for character in text:
		if character == "\n":
			pos_i = 0
			pos_y_i += 1
			continue
		
		var rect_region = sprite_font.get_char_rect(character)
		if rect_region != null:
			var rect_draw = Rect2(rect_region.size.x * pos_i, rect_region.size.y * pos_y_i, rect_region.size.x, rect_region.size.x)
			draw_texture_rect_region(sprite_font.texture, rect_draw, rect_region)
		
		pos_i += 1


func _set_text(value):
	text = value
	queue_redraw()
