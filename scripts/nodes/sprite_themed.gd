@icon("res://assets/editor/icons/sprite_theme.png")
class_name SpriteThemed
extends Sprite2D


@export var texture_name := "":
	set = _set_texture_name


func _ready():
	add_to_group("_sprite_themed")


func update_sprite():
	var level = Main.get_level()
	if level == null:
		return
	
	var theme = level.level_theme
	if theme == null:
		return
	if theme.theme_assets_dir == "":
		return
	
	var file_path = theme.theme_assets_dir.path_join("%s.png" % texture_name)
	texture = load(file_path)


func _set_texture_name(value):
	texture_name = value
	update_sprite()
