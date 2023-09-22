@tool
class_name OnScreenNotifier
extends Node2D


signal screen_entered
signal screen_exited


@export var rect: Rect2:
	set = _set_rect


var camera: Camera2D:
	get = _get_camera

var on_screen: bool = false


func _process(_delta):
	if Engine.is_editor_hint():
		return
	
	var full_rect = Rect2(rect)
	full_rect.position += global_position
	
	var inside = _get_camera_rect().intersects(full_rect, true)
	if inside and not on_screen:
		on_screen = true
		screen_entered.emit()
	if not inside and on_screen:
		on_screen = false
		screen_exited.emit()

func _draw():
	if not Engine.is_editor_hint():
		return
	
	var color_out = Color.RED
	color_out.a = 0.5
	
	var color_in = color_out.lightened(0.2)
	color_in.a = 0.2
	
	draw_rect(rect, color_in, true)
	draw_rect(rect, color_out, false, 0.1)


func _set_rect(new_rect: Rect2):
	rect = new_rect
	
	queue_redraw()


func _get_camera():
	var viewport = get_viewport()
	if viewport == null:
		return null
	
	return viewport.get_camera_2d()

func _get_camera_rect():
	if camera == null:
		return
	
	return Rect2(
		camera.get_screen_center_position() - (Main.SCREEN_SIZE / 2),
		Main.SCREEN_SIZE
	)
