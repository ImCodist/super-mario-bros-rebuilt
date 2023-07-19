@tool
@icon("res://assets/editor/icons/levelmap.png")
extends TileMap
class_name LevelMap


const BASE_TILESET = preload("res://assets/resources/tilesets/base.tres")

const TILESET_SCENES = {
	Vector2i(2, 0): preload("res://scenes/objects/blocks/question_block/question_block.tscn"),
	Vector2i(3, 0): preload("res://scenes/objects/blocks/brick/brick.tscn"),
}


func _ready():
	if Engine.is_editor_hint():
		return
	
	generate_level()

func _get(property):
	match property:
		"tile_set":
			tile_set = BASE_TILESET


func generate_level():
	for layer in get_layers_count():
		for cell in get_used_cells(layer):
			var atlas_coords := get_cell_atlas_coords(layer, cell)
			if TILESET_SCENES.has(atlas_coords):
				erase_cell(layer, cell)
				
				var value = TILESET_SCENES[atlas_coords]
				if value is PackedScene:
					var scene = value.instantiate()
					scene.position = (cell * cell_quadrant_size) + (Vector2i(cell_quadrant_size, cell_quadrant_size) / 2)
					add_child(scene)
