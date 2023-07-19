extends Block


func _process(delta):
	if not is_empty:
		$Sprite.frame = Sprites.flash_frame
	
	super(delta)
