@tool
@icon("res://assets/editor/icons/theme.png")
class_name LevelTheme
extends Resource


@export var music := ""

@export var background_color := Color("9494ff")

@export var tileset: TileSet

@export_dir var assets_dir := ""

@export var powerup_colors := [
	[],
	[Color("0c9300"), Color("fffeff"), Color("ea9e22")],
	[Color("b53120"), Color("fffeff"), Color("ea9e22")],
	[Color("000000"), Color("feccc5"), Color("994e00")],
]
