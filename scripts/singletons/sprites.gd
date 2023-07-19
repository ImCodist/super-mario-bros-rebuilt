extends Node


const FLASH_WAIT_TIMER = 0.75
const FLASH_INTERVAL = 0.12


var flash_frame: int


var _flash_wait_timer: float
var _flash_timer: float
var _flash_back: bool = false
var _do_flash: bool = false


func _process(_delta):
	_flash_wait_timer += _delta
	
	if _flash_wait_timer >= FLASH_WAIT_TIMER:
		flash_frame = 0
		_flash_back = false
		
		_do_flash = true
		_flash_wait_timer = 0.0
	
	if _do_flash:
		_flash_timer += _delta
		
		if _flash_timer >= FLASH_INTERVAL:
			var change = 1
			if _flash_back:
				change = -1
			
			flash_frame += change
			if _flash_back and flash_frame == 0:
				_do_flash = false
			
			if flash_frame >= 2 or flash_frame <= 0:
				_flash_back = not _flash_back
			
			_flash_timer = 0
