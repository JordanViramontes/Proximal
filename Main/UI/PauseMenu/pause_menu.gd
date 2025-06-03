extends Control
@onready var pause = $"."
@onready var animation_player = $AnimationPlayer
var pause_flag = false
	
func pauseMenu():
	if pause_flag:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		self.hide()
		get_tree().paused = false
		animation_player.play_backwards("blur")
		pause_flag = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		self.show()
		get_tree().paused = true
		animation_player.play("blur")
		pause_flag = true
	
func testEsc():
	if Input.is_action_just_pressed("escape"):
		pauseMenu()
		
func _unhandled_input(event: InputEvent) -> void:
	testEsc()
