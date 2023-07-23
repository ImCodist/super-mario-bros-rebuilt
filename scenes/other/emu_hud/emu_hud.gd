extends CanvasLayer


func _ready():
	visible = false


func _process(_delta):
	if Input.is_action_pressed("select") and Input.is_action_just_pressed("a"):
		visible = not visible
