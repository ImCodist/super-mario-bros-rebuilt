extends Control


func _process(_delta):
	$Inputs/UPInput.visible = Input.is_action_pressed("up")
	$Inputs/DOWNInput.visible = Input.is_action_pressed("down")
	$Inputs/LEFTInput.visible = Input.is_action_pressed("left")
	$Inputs/RIGHTInput.visible = Input.is_action_pressed("right")
	
	$Inputs/SELECTInput.visible = Input.is_action_pressed("select")
	$Inputs/STARTInput.visible = Input.is_action_pressed("start")
	
	$Inputs/AInput.visible = Input.is_action_pressed("a")
	$Inputs/BInput.visible = Input.is_action_pressed("b")
