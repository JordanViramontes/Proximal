extends Control

# play button should send user to game scene
func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# options button should allow to change ui elements, key binds, etc.
func _on_options_pressed():
	pass
	
func _on_quit_pressed():
	get_tree().quit()
